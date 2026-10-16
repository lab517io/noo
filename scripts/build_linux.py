#!/usr/bin/env python3
"""
Build script to produce an AppImage for the Noo Flutter application.

Usage:
    python build_linux.py [--release|--debug] [--skip-build] [--clean]

Options:
    --release     Build in release mode (default)
    --debug       Build in debug mode
    --skip-build  Skip Flutter build, only create AppImage from existing build
    --clean       Clean build artifacts before building
"""

import argparse
import os
import platform
import re
import shutil
import stat
import subprocess
import sys
import urllib.request
from pathlib import Path

# Paths (relative to script location)
SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_ROOT = SCRIPT_DIR.parent
CLIENT_DIR = PROJECT_ROOT / "client"


def get_version_from_pubspec() -> str:
    """Read version from pubspec.yaml."""
    pubspec_path = CLIENT_DIR / "pubspec.yaml"
    if not pubspec_path.exists():
        print(f"Warning: pubspec.yaml not found at {pubspec_path}, using default version")
        return "0.0.0"

    content = pubspec_path.read_text()
    match = re.search(r'^version:\s*(\S+)', content, re.MULTILINE)
    if match:
        version = match.group(1)
        # Handle version+build format (e.g., "1.0.0+1" -> "1.0.0")
        if '+' in version:
            version = version.split('+')[0]
        return version

    print("Warning: version not found in pubspec.yaml, using default version")
    return "0.0.0"


# Configuration
APP_NAME = "noo"
APP_DISPLAY_NAME = "Noo"
APP_DESCRIPTION = "Tiny outliner with time tracking"
APP_VERSION = get_version_from_pubspec()
APP_CATEGORIES = "Utility;Office;ProjectManagement;"
APP_ICON_NAME = "noo"
BUILD_DIR = PROJECT_ROOT / "build"
APPIMAGE_BUILD_DIR = BUILD_DIR / "appimage"
APPDIR = APPIMAGE_BUILD_DIR / f"{APP_NAME}.AppDir"
RELEASES_DIR = SCRIPT_DIR / "releases"

# AppImageTool configuration
APPIMAGETOOL_URL = "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
APPIMAGETOOL_PATH = BUILD_DIR / "appimagetool-x86_64.AppImage"

# GStreamer plugins bundled for attachment audio playback. audioplayers_linux
# drives a playbin, which resolves everything it needs from the plugin registry
# at runtime — so the decoders have to travel with the AppImage or playback
# fails on a machine that only has gstreamer1.0-plugins-base installed.
GST_PLUGINS = [
    # playbin and its scaffolding
    "coreelements", "playback", "typefindfunctions", "autodetect",
    # audio conversion / parsing
    "audioconvert", "audioresample", "audioparsers", "volume",
    # output sinks
    "alsa", "pulseaudio",
    # containers and tags
    "id3demux", "isomp4", "ogg", "wavparse",
    # network source. Attachments are served over loopback HTTP by
    # AttachmentMediaServer, so without souphttpsrc playbin has no handler for
    # the only URI scheme this app ever hands it.
    "soup",
    # codecs. faad covers AAC/m4a; libav would cover it too but drags in the
    # whole FFmpeg stack (video encoders, Vulkan, OpenCL) — 208 MB against 14.
    "mpg123", "vorbis", "opus", "flac", "faad",
]

# apt packages providing the plugins above, for the diagnostic when one is
# missing on the build machine.
GST_PLUGIN_PACKAGES = {
    "faad": "gstreamer1.0-plugins-bad",
    "mpg123": "gstreamer1.0-plugins-ugly",
}
GST_PLUGIN_PACKAGE_DEFAULT = "gstreamer1.0-plugins-base / -good"

# Libraries a plugin dlopen()s instead of linking, so `ldd` never names them and
# the dependency walk below cannot find them on its own. libgstsoup picks its
# libsoup at runtime — 3.0 first, 2.4 as the fallback — and registers nothing at
# all when neither can be loaded, which surfaces as playbin failing with
# "No URI handler implemented for http". Only the first name found is bundled.
GST_PLUGIN_DLOPEN_LIBS = {
    "soup": ["libsoup-3.0.so.0", "libsoup-2.4.so.1"],
}

# Directories GStreamer plugins are installed to, in probe order. Only used as a
# fallback: pkg-config knows the answer whenever the -dev package is present.
GST_PLUGIN_DIR_FALLBACKS = [
    Path("/usr/lib/x86_64-linux-gnu/gstreamer-1.0"),
    Path("/usr/lib64/gstreamer-1.0"),
    Path("/usr/lib/gstreamer-1.0"),
]

# Libraries that must come from the host, never the AppImage. Bundling the GTK,
# GL, glib or audio-server stack is the classic way to make an AppImage crash on
# every distro but the one it was built on: those libraries are already loaded
# from the host by the Flutter shell, and a second copy clashes with it.
HOST_LIB_PREFIXES = (
    "ld-linux", "libc.", "libm.", "libpthread.", "libdl.", "librt.", "libnsl.",
    "libresolv.", "libstdc++.", "libgcc_s.",
    "libglib-2.0.", "libgobject-2.0.", "libgio-2.0.", "libgmodule-2.0.",
    "libgthread-2.0.",
    "libgtk-3.", "libgdk-3.", "libgdk_pixbuf-2.0.", "libpango", "libcairo",
    "libatk", "libepoxy.",
    "libX", "libxcb", "libwayland", "libGL", "libEGL", "libGLX", "libGLdispatch",
    "libdrm", "libgbm.",
    "libasound.", "libpulse", "libjack", "libpipewire", "libdbus-1.",
    "libsystemd.", "libselinux.", "libudev.", "libcap.", "libmount.",
    "libblkid.", "libpcre",
    "libz.", "libbz2.", "liblzma.", "libzstd.", "libffi.", "libexpat.",
    "libssl.", "libcrypto.",
    "libfontconfig.", "libfreetype.", "libharfbuzz", "libpng16.", "libjpeg.",
)


def run_command(cmd: list[str], cwd: Path | None = None, check: bool = True) -> subprocess.CompletedProcess:
    """Run a command and return the result."""
    print(f"  Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd=cwd, capture_output=False, text=True)
    if check and result.returncode != 0:
        print(f"Error: Command failed with return code {result.returncode}")
        sys.exit(1)
    return result


# Native libraries the Flutter plugins link against, as pkg-config module names.
# GStreamer comes in via audioplayers_linux (attachment audio playback); without
# the -dev packages CMake fails deep inside the plugin's CMakeLists with a
# FindPkgConfig trace that says nothing about which apt package to install.
PKG_CONFIG_DEPS = {
    "gtk+-3.0": "libgtk-3-dev",
    "gstreamer-1.0": "libgstreamer1.0-dev",
    "gstreamer-app-1.0": "libgstreamer-plugins-base1.0-dev",
    "gstreamer-audio-1.0": "libgstreamer-plugins-base1.0-dev",
}


def check_dependencies() -> bool:
    """Check if required dependencies are installed."""
    print("Checking dependencies...")

    missing = []

    # Check for Flutter
    if shutil.which("flutter") is None:
        missing.append("flutter")

    # Check for fuse (required for AppImageTool)
    if not Path("/dev/fuse").exists():
        print("Warning: FUSE not available. Will try to extract AppImageTool.")

    if missing:
        print(f"Error: Missing required dependencies: {', '.join(missing)}")
        print("Please install them before running this script.")
        return False

    if not check_native_libraries():
        return False

    print("  All dependencies satisfied.")
    return True


def check_native_libraries() -> bool:
    """Check the native libraries the Flutter plugins link against."""
    if shutil.which("pkg-config") is None:
        print("Warning: pkg-config not found, skipping native library check.")
        return True

    packages = []
    for module, apt_package in PKG_CONFIG_DEPS.items():
        found = subprocess.run(
            ["pkg-config", "--exists", module],
            capture_output=True,
        ).returncode == 0
        if not found and apt_package not in packages:
            packages.append(apt_package)

    if packages:
        print("Error: Missing native development libraries.")
        print("Install them with:")
        print(f"  sudo apt install {' '.join(packages)}")
        return False

    return True


def find_gst_plugin_dir() -> Path | None:
    """Locate the GStreamer plugin directory."""
    result = subprocess.run(
        ["pkg-config", "--variable=pluginsdir", "gstreamer-1.0"],
        capture_output=True, text=True,
    )
    if result.returncode == 0 and result.stdout.strip():
        candidate = Path(result.stdout.strip())
        if candidate.is_dir():
            return candidate

    for candidate in GST_PLUGIN_DIR_FALLBACKS:
        if candidate.is_dir():
            return candidate

    return None


def find_shared_library(soname: str) -> Path | None:
    """Locate a shared library by soname, the way the runtime loader would."""
    result = subprocess.run(["ldconfig", "-p"], capture_output=True, text=True)
    if result.returncode == 0:
        fallback = None
        for line in result.stdout.splitlines():
            head, sep, target = line.strip().partition("=>")
            if not sep or not head.startswith(soname + " "):
                continue
            candidate = Path(target.strip())
            if not candidate.exists():
                continue
            if "x86-64" in head:
                return candidate
            fallback = fallback or candidate
        if fallback is not None:
            return fallback

    for directory in ("/usr/lib/x86_64-linux-gnu", "/usr/lib64", "/usr/lib"):
        candidate = Path(directory) / soname
        if candidate.exists():
            return candidate

    return None


def shared_lib_deps(path: Path) -> list[tuple[str, Path]]:
    """Return (soname, resolved path) for each shared library `path` links."""
    result = subprocess.run(["ldd", str(path)], capture_output=True, text=True)
    if result.returncode != 0:
        return []

    deps = []
    for line in result.stdout.splitlines():
        soname, sep, target = line.strip().partition("=>")
        if not sep:
            continue
        target = target.strip().split(" (")[0]
        if not target.startswith("/"):
            continue
        deps.append((soname.strip(), Path(target)))
    return deps


def bundle_library(src: Path, lib_dir: Path, seen: set[str]) -> None:
    """Copy `src` and everything it links (minus host libraries) into lib_dir."""
    if src.name in seen:
        return
    seen.add(src.name)

    # Copy the symlink target under the soname the loader will ask for.
    shutil.copy2(src.resolve(), lib_dir / src.name)

    for soname, dep_path in shared_lib_deps(src):
        if soname.startswith(HOST_LIB_PREFIXES):
            continue
        bundle_library(dep_path, lib_dir, seen)


def bundle_gstreamer(usr_bin: Path) -> None:
    """Bundle the GStreamer plugins and libraries needed for audio playback."""
    print("  Bundling GStreamer runtime...")

    plugin_src_dir = find_gst_plugin_dir()
    if plugin_src_dir is None:
        print("  Warning: GStreamer plugin directory not found — audio playback")
        print("           will depend on the host having GStreamer installed.")
        return

    lib_dir = usr_bin / "lib"
    plugin_dir = lib_dir / "gstreamer-1.0"
    plugin_dir.mkdir(parents=True, exist_ok=True)

    # Flutter's own libraries are already in place; leave them untouched.
    seen = {p.name for p in lib_dir.glob("*.so*")}

    bundled, missing = 0, []
    for name in GST_PLUGINS:
        plugin = plugin_src_dir / f"libgst{name}.so"
        if not plugin.exists():
            missing.append(name)
            continue
        shutil.copy2(plugin, plugin_dir / plugin.name)
        for soname, dep_path in shared_lib_deps(plugin):
            if soname.startswith(HOST_LIB_PREFIXES):
                continue
            bundle_library(dep_path, lib_dir, seen)
        for dlopen_soname in GST_PLUGIN_DLOPEN_LIBS.get(name, []):
            dlopen_path = find_shared_library(dlopen_soname)
            if dlopen_path is None:
                continue
            bundle_library(dlopen_path, lib_dir, seen)
            break
        else:
            if name in GST_PLUGIN_DLOPEN_LIBS:
                names = " / ".join(GST_PLUGIN_DLOPEN_LIBS[name])
                print(f"  Warning: none of {names} found — the {name} plugin")
                print("           will not register on a host that lacks them.")
        bundled += 1

    # playbin spawns the scanner as a helper process to build the registry.
    scanner = plugin_src_dir.parent / "gstreamer1.0" / "gstreamer-1.0" / "gst-plugin-scanner"
    if not scanner.exists():
        scanner = plugin_src_dir.parent / "gstreamer1.0" / "gst-plugin-scanner"
    if scanner.exists():
        dest = plugin_dir / "gst-plugin-scanner"
        shutil.copy2(scanner, dest)
        dest.chmod(dest.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
        for soname, dep_path in shared_lib_deps(scanner):
            if soname.startswith(HOST_LIB_PREFIXES):
                continue
            bundle_library(dep_path, lib_dir, seen)
    else:
        print("  Warning: gst-plugin-scanner not found, registry build may be slow.")

    if missing:
        print(f"  Warning: plugins not installed on this machine: {', '.join(missing)}")
        print("           Those formats will not play. Install and rebuild:")
        packages = sorted({
            GST_PLUGIN_PACKAGES.get(name, GST_PLUGIN_PACKAGE_DEFAULT)
            for name in missing
        })
        print(f"             sudo apt install {' '.join(packages)}")

    size_mb = sum(f.stat().st_size for f in plugin_dir.rglob("*")) / (1024 * 1024)
    print(f"  Bundled {bundled} GStreamer plugins ({size_mb:.1f} MB) + dependencies")


def download_appimagetool() -> Path:
    """Download appimagetool if not present."""
    if APPIMAGETOOL_PATH.exists():
        print(f"  Using existing appimagetool at {APPIMAGETOOL_PATH}")
        return APPIMAGETOOL_PATH

    print(f"Downloading appimagetool from {APPIMAGETOOL_URL}...")
    BUILD_DIR.mkdir(parents=True, exist_ok=True)

    try:
        urllib.request.urlretrieve(APPIMAGETOOL_URL, APPIMAGETOOL_PATH)
        # Make executable
        APPIMAGETOOL_PATH.chmod(APPIMAGETOOL_PATH.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
        print(f"  Downloaded to {APPIMAGETOOL_PATH}")
    except Exception as e:
        print(f"Error downloading appimagetool: {e}")
        sys.exit(1)

    return APPIMAGETOOL_PATH


def clean_build() -> None:
    """Clean build artifacts."""
    print("Cleaning build artifacts...")

    if APPIMAGE_BUILD_DIR.exists():
        shutil.rmtree(APPIMAGE_BUILD_DIR)
        print(f"  Removed {APPIMAGE_BUILD_DIR}")

    flutter_build = CLIENT_DIR / "build" / "linux"
    if flutter_build.exists():
        shutil.rmtree(flutter_build)
        print(f"  Removed {flutter_build}")


def build_flutter(release: bool = True) -> Path:
    """Build the Flutter Linux application."""
    mode = "release" if release else "debug"
    print(f"Building Flutter application in {mode} mode...")

    cmd = ["flutter", "build", "linux", f"--{mode}"]
    run_command(cmd, cwd=CLIENT_DIR)

    # Determine build output path
    arch = "x64"  # Flutter Linux currently only supports x64
    bundle_dir = CLIENT_DIR / "build" / "linux" / arch / mode / "bundle"

    if not bundle_dir.exists():
        print(f"Error: Build output not found at {bundle_dir}")
        sys.exit(1)

    print(f"  Build completed: {bundle_dir}")
    return bundle_dir


def create_desktop_file() -> str:
    """Create the .desktop file content."""
    return f"""[Desktop Entry]
Type=Application
Name={APP_DISPLAY_NAME}
Comment={APP_DESCRIPTION}
Exec={APP_NAME}
Icon={APP_ICON_NAME}
Categories={APP_CATEGORIES}
Terminal=false
StartupNotify=true
StartupWMClass={APP_NAME}
"""


def create_apprun() -> str:
    """Create the AppRun script content."""
    return f"""#!/bin/bash
set -e

# Get the directory where the AppImage is mounted
APPDIR="$(dirname "$(readlink -f "$0")")"

# Set up library paths (lib is next to executable in usr/bin/lib)
export LD_LIBRARY_PATH="$APPDIR/usr/bin/lib:$LD_LIBRARY_PATH"

# Point GStreamer at the bundled plugins so audio attachments play without the
# host having gstreamer1.0-plugins-* installed. The registry has to live in a
# writable place — the AppImage mount is read-only.
GST_DIR="$APPDIR/usr/bin/lib/gstreamer-1.0"
if [ -d "$GST_DIR" ]; then
    export GST_PLUGIN_SYSTEM_PATH_1_0="$GST_DIR"
    export GST_PLUGIN_PATH_1_0="$GST_DIR"
    export GST_PLUGIN_SCANNER_1_0="$GST_DIR/gst-plugin-scanner"
    GST_CACHE_DIR="${{XDG_CACHE_HOME:-$HOME/.cache}}/{APP_NAME}"
    mkdir -p "$GST_CACHE_DIR"
    export GST_REGISTRY_1_0="$GST_CACHE_DIR/gst-registry.bin"
fi

# Audio attachments are played from a loopback HTTP server, and GStreamer's
# souphttpsrc asks GIO to resolve a proxy for that URL. GIO on Ubuntu resolves
# through libproxy, which hands back the desktop's proxy even for 127.0.0.1 —
# the "ignore hosts" list is not consulted — and the memo is then fetched from a
# proxy that has no idea what to do with a port on the user's own machine.
# GLib's no-op resolver answers "direct://" for everything; nothing in this app
# reaches the network through GIO. Set here as well as in main() so it is in
# place before GLib has any chance to cache its choice. An explicit value from
# the environment wins.
export GIO_USE_PROXY_RESOLVER="${{GIO_USE_PROXY_RESOLVER:-dummy}}"

# Set up XDG paths for proper icon/theme resolution
export XDG_DATA_DIRS="$APPDIR/usr/share:${{XDG_DATA_DIRS:-/usr/local/share:/usr/share}}"

# GTK/GDK settings for better compatibility
export GDK_BACKEND="${{GDK_BACKEND:-x11}}"

# Run the application
exec "$APPDIR/usr/bin/{APP_NAME}" "$@"
"""


def create_appdir(bundle_dir: Path) -> Path:
    """Create the AppDir structure."""
    print("Creating AppDir structure...")

    # Clean and create AppDir
    if APPDIR.exists():
        shutil.rmtree(APPDIR)
    APPDIR.mkdir(parents=True)

    # Create directory structure
    usr_bin = APPDIR / "usr" / "bin"
    usr_lib = APPDIR / "usr" / "lib"
    usr_share_icons = APPDIR / "usr" / "share" / "icons" / "hicolor" / "256x256" / "apps"
    usr_share_applications = APPDIR / "usr" / "share" / "applications"

    for d in [usr_bin, usr_lib, usr_share_icons, usr_share_applications]:
        d.mkdir(parents=True, exist_ok=True)

    # Copy the entire bundle contents
    print("  Copying application files...")

    # Copy executable
    src_executable = bundle_dir / APP_NAME
    if not src_executable.exists():
        print(f"Error: Executable not found at {src_executable}")
        sys.exit(1)
    shutil.copy2(src_executable, usr_bin / APP_NAME)

    # Copy lib directory - MUST be relative to executable (Flutter looks for lib/libapp.so)
    src_lib = bundle_dir / "lib"
    if src_lib.exists():
        shutil.copytree(src_lib, usr_bin / "lib", dirs_exist_ok=True)

    # Copy data directory (Flutter assets)
    src_data = bundle_dir / "data"
    if src_data.exists():
        shutil.copytree(src_data, usr_bin / "data", dirs_exist_ok=True)

    # Bundle GStreamer (audioplayers_linux depends on it at runtime)
    bundle_gstreamer(usr_bin)

    # Create AppRun script
    print("  Creating AppRun script...")
    apprun_path = APPDIR / "AppRun"
    apprun_path.write_text(create_apprun())
    apprun_path.chmod(apprun_path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    # Create .desktop file
    print("  Creating .desktop file...")
    desktop_path = APPDIR / f"{APP_NAME}.desktop"
    desktop_path.write_text(create_desktop_file())
    # Also copy to usr/share/applications
    shutil.copy2(desktop_path, usr_share_applications / f"{APP_NAME}.desktop")

    # Copy icon
    print("  Copying application icon...")
    icon_src = CLIENT_DIR / "assets" / "icons" / "app_icon.png"
    if icon_src.exists():
        # Copy to AppDir root (required by AppImage)
        shutil.copy2(icon_src, APPDIR / f"{APP_ICON_NAME}.png")
        # Copy to hicolor theme directory
        shutil.copy2(icon_src, usr_share_icons / f"{APP_ICON_NAME}.png")
    else:
        print(f"  Warning: Icon not found at {icon_src}, AppImage will have no icon")

    print(f"  AppDir created at {APPDIR}")
    return APPDIR


def create_appimage(appdir: Path) -> Path:
    """Create the AppImage from the AppDir."""
    print("Creating AppImage...")

    # Ensure appimagetool is available
    appimagetool = download_appimagetool()

    # Determine output filename
    arch = platform.machine()
    output_name = f"{APP_NAME}-{APP_VERSION}-{arch}.AppImage"
    output_path = BUILD_DIR / output_name

    # Remove existing AppImage if present
    if output_path.exists():
        output_path.unlink()

    # Try running appimagetool directly first
    try:
        run_command([str(appimagetool), str(appdir), str(output_path)], cwd=BUILD_DIR)
    except Exception:
        # If FUSE is not available, try extracting and running
        print("  Direct execution failed, trying with --appimage-extract-and-run...")
        run_command(
            [str(appimagetool), "--appimage-extract-and-run", str(appdir), str(output_path)],
            cwd=BUILD_DIR
        )

    if output_path.exists():
        # Make executable
        output_path.chmod(output_path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
        print(f"  AppImage created: {output_path}")
        print(f"  Size: {output_path.stat().st_size / (1024 * 1024):.2f} MB")
        return output_path
    else:
        print("Error: Failed to create AppImage")
        sys.exit(1)


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Build Noo Flutter application as AppImage",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument(
        "--release",
        action="store_true",
        default=True,
        help="Build in release mode (default)"
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Build in debug mode"
    )
    parser.add_argument(
        "--skip-build",
        action="store_true",
        help="Skip Flutter build, use existing build output"
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help="Clean build artifacts before building"
    )

    args = parser.parse_args()

    # Determine build mode
    release = not args.debug
    mode = "release" if release else "debug"

    print(f"=== Building {APP_DISPLAY_NAME} AppImage ({mode} mode) ===")
    print(f"Project root: {PROJECT_ROOT}")
    print(f"Client directory: {CLIENT_DIR}")
    print()

    # Check dependencies
    if not check_dependencies():
        sys.exit(1)

    # Clean if requested
    if args.clean:
        clean_build()

    # Build Flutter app or use existing build
    if args.skip_build:
        arch = "x64"
        bundle_dir = CLIENT_DIR / "build" / "linux" / arch / mode / "bundle"
        if not bundle_dir.exists():
            print(f"Error: No existing build found at {bundle_dir}")
            print("Run without --skip-build to create a new build.")
            sys.exit(1)
        print(f"Using existing build at {bundle_dir}")
    else:
        bundle_dir = build_flutter(release=release)

    # Create AppDir
    appdir = create_appdir(bundle_dir)

    # Create AppImage
    appimage_path = create_appimage(appdir)

    # Copy to releases directory
    print("Copying to releases directory...")
    RELEASES_DIR.mkdir(parents=True, exist_ok=True)
    release_path = RELEASES_DIR / appimage_path.name
    # Unlink first: overwriting the file in place fails with "Text file busy"
    # whenever the previous build of the same version is still running, which is
    # exactly what happens when a bug is being chased. Replacing the inode
    # leaves that process on the old image and lets the copy through.
    release_path.unlink(missing_ok=True)
    shutil.copy2(appimage_path, release_path)
    print(f"  Copied to {release_path}")

    print()
    print("=== Build Complete ===")
    print(f"AppImage: {appimage_path}")
    print(f"Release:  {release_path}")
    print()
    print("To run the AppImage:")
    print(f"  {appimage_path}")


if __name__ == "__main__":
    main()
