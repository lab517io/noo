#!/usr/bin/env python3
"""
Build script to produce an AppImage for the Noo Flutter application.

Usage:
    python build_linux.py [--release|--debug] [--skip-build] [--clean] [--container]

Options:
    --release     Build in release mode (default)
    --debug       Build in debug mode
    --skip-build  Skip Flutter build, only create AppImage from existing build
    --clean       Clean build artifacts before building
    --container   Build inside Ubuntu 22.04 (docker), so the AppImage runs on
                  glibc 2.35 and newer instead of only on the build machine's
                  glibc. Use it for every AppImage that is published.
"""

import argparse
import datetime
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
# One main category (Office): a second one, such as Utility, lists the app
# twice in some menus, and desktop-file-validate says so.
APP_CATEGORIES = "Office;ProjectManagement;"
# The AppStream id. The desktop file, the icon and the metainfo are all named
# after it, as the app's own launcher registration (app_registration.dart)
# names them, so a catalogue can tie the three together.
APP_ID = "io.lab517.noo"
APP_ICON_NAME = APP_ID
METAINFO_SRC = CLIENT_DIR / "linux" / f"{APP_ID}.metainfo.xml"
CHANGELOG_DIR = PROJECT_ROOT / "fastlane" / "metadata" / "android" / "en-US" / "changelogs"
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
    # Packaged on their own on Ubuntu 22.04, inside -base/-good later.
    "alsa": "gstreamer1.0-alsa",
    "pulseaudio": "gstreamer1.0-pulseaudio",
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
    # On AppImage's excludelist (pkg2appimage): present on every desktop, and
    # a bundled copy older than the host's breaks the host's own libraries.
    "libcom_err.", "libgpg-error.", "libuuid.", "libfribidi.",
    # package:jni's libdartjni links the JVM. It is only ever loaded on
    # Android; on the desktop it would bundle the build machine's 26 MB
    # libjvm.so without the JDK it belongs to.
    "libjvm.",
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


def needed_sonames(path: Path) -> set[str]:
    """The libraries `path` itself names in DT_NEEDED — not what they pull in."""
    result = subprocess.run(["readelf", "-d", str(path)], capture_output=True, text=True)
    return set(re.findall(r"\(NEEDED\)\s+Shared library: \[([^\]]+)\]", result.stdout))


def shared_lib_deps(path: Path, env: dict[str, str] | None = None) -> list[tuple[str, str]]:
    """Return (soname, resolved path or "not found") for each library `path`
    links *directly*.

    `ldd` alone answers with the whole transitive closure, so walking it from
    the app reached through the host's GTK and bundled GTK's own private
    libraries (pixman, xkbcommon, atspi, thai, graphite2…) — old copies that a
    newer host GTK or cairo would then be loaded against. Following DT_NEEDED
    one level at a time stops the walk at every host library.
    """
    result = subprocess.run(["ldd", str(path)], capture_output=True, text=True, env=env)
    if result.returncode != 0:
        return []

    direct = needed_sonames(path)
    deps = []
    for line in result.stdout.splitlines():
        soname, sep, target = line.strip().partition("=>")
        soname = soname.strip()
        if not sep or soname not in direct:
            continue
        target = target.strip().split(" (")[0]
        if target != "not found" and not target.startswith("/"):
            continue
        deps.append((soname, target))
    return deps


def bundle_library(src: Path | str, lib_dir: Path, seen: set[str]) -> None:
    """Copy `src` and everything it links (minus host libraries) into lib_dir."""
    if str(src) == "not found":
        # Left for verify_bundle_self_contained to report with its context.
        return
    src = Path(src)
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


def bundle_app_dependencies(usr_bin: Path) -> None:
    """Bundle what the app and its Flutter plugins link, minus host libraries.

    Flutter copies the plugins' own .so files but not what *they* link:
    audioplayers needs libgstapp, flutter_secure_storage libsecret and
    libjsoncpp. A desktop that has them hides the gap — 1.2.19's AppImage did
    not start on a system without gstreamer1.0-plugins-base, which is what
    AppImageHub's test runs on.
    """
    lib_dir = usr_bin / "lib"
    seen = {p.name for p in lib_dir.rglob("*.so*")}
    before = len(seen)
    for binary in [usr_bin / APP_NAME, *sorted(lib_dir.glob("*.so"))]:
        for soname, dep_path in shared_lib_deps(binary):
            if soname.startswith(HOST_LIB_PREFIXES):
                continue
            bundle_library(dep_path, lib_dir, seen)
    print(f"  Bundled {len(seen) - before} libraries the app and its plugins link")


def verify_bundle_self_contained(usr_bin: Path) -> None:
    """Stop the build if anything bundled still links a library from the host.

    A half-bundled library set is worse than none: 1.2.19 shipped GStreamer's
    core but not libgstapp, so a host with a newer GStreamer loaded *its*
    libgstapp against the bundled, older core and the app died with
    "undefined symbol: gst_vec_deque_free". Resolve every dependency the way
    AppRun will (LD_LIBRARY_PATH on the bundle) and refuse any that lands
    outside it, unless it is on the host-library list.
    """
    lib_dir = usr_bin / "lib"
    env = {**os.environ, "LD_LIBRARY_PATH": str(lib_dir)}
    binaries = [usr_bin / APP_NAME, *sorted(lib_dir.rglob("*.so*"))]
    leaks: set[str] = set()
    for binary in binaries:
        if binary.is_symlink() or not binary.is_file():
            continue
        for soname, target in shared_lib_deps(binary, env):
            if soname.startswith(HOST_LIB_PREFIXES):
                continue
            if not target.startswith(str(usr_bin)):
                leaks.add(f"{binary.relative_to(usr_bin)}: {soname} -> {target}")
    if leaks:
        print("Error: bundled libraries still resolve these from the host:")
        for leak in sorted(leaks):
            print(f"    {leak}")
        print("  Bundle them, or add them to HOST_LIB_PREFIXES if the host must provide them.")
        sys.exit(1)
    print(f"  Checked {len(binaries)} binaries: every dependency is bundled or a host library")


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


def _release_date(version: str, changelog: Path) -> str:
    """When <version> was released: the date of its tag; for a version never
    tagged (or not tagged yet), the last commit that touched its changelog;
    failing both, today."""
    for args in (["log", "-1", "--format=%cs", f"v{version}", "--"],
                 ["log", "-1", "--format=%cs", "--", str(changelog)]):
        result = subprocess.run(["git", "-C", str(PROJECT_ROOT), *args],
                                capture_output=True, text=True)
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    return datetime.date.today().isoformat()


def create_metainfo(max_releases: int = 10) -> str:
    """client/linux/<id>.metainfo.xml with <releases> filled in.

    Release notes are written once, as the F-Droid changelogs
    (changelogs/<versionCode>.txt, versionCode = X*10000 + Y*100 + Z), and
    every catalogue reads them from here. Only releases up to the version
    being built are listed.
    """
    from xml.sax.saxutils import escape

    def version_of(code: int) -> str:
        return f"{code // 10000}.{code // 100 % 100}.{code % 100}"

    major, minor, patch = (int(x) for x in APP_VERSION.split(".")[:3])
    current = major * 10000 + minor * 100 + patch
    codes = sorted((int(f.stem) for f in CHANGELOG_DIR.glob("*.txt")
                    if f.stem.isdigit() and int(f.stem) <= current), reverse=True)
    entries = []
    for code in codes[:max_releases]:
        version = version_of(code)
        changelog = CHANGELOG_DIR / f"{code}.txt"
        notes = changelog.read_text().strip()
        entries.append(
            f'    <release version="{version}" date="{_release_date(version, changelog)}">\n'
            f"      <description>\n        <p>{escape(notes)}</p>\n      </description>\n"
            f'      <url type="details">https://github.com/lab517io/noo/releases/tag/v{version}</url>\n'
            f"    </release>")
    releases = "<releases>\n" + "\n".join(entries) + "\n  </releases>"
    template = METAINFO_SRC.read_text()
    if "<releases/>" not in template:
        sys.exit(f"error: {METAINFO_SRC} must hold an empty <releases/> for the build to fill")
    return template.replace("<releases/>", releases)


def validate_metadata(desktop: Path, metainfo: Path) -> None:
    """What AppImageHub's test runs on them, when the tools are installed.

    An error stops the build: an AppImage the catalogue would reject is not
    one to publish. appstreamcli's warnings and hints are shown but do not
    stop it — they move with its version (22.04's 0.15 does not know
    `<developer id>`, which current ones ask for), so failing on them would
    make the build depend on which validator happened to be installed. A
    missing tool only warns, so a machine without them can still build.
    """
    if shutil.which("desktop-file-validate") is None:
        print(f"  Warning: desktop-file-validate not found, {desktop.name} not validated")
    else:
        result = subprocess.run(["desktop-file-validate", str(desktop)],
                                capture_output=True, text=True)
        if result.returncode != 0:
            print(result.stdout + result.stderr)
            sys.exit(f"error: desktop-file-validate rejected {desktop.name}")
        print(f"  desktop-file-validate: {desktop.name} OK")

    if shutil.which("appstreamcli") is None:
        print(f"  Warning: appstreamcli not found, {metainfo.name} not validated")
        return
    result = subprocess.run(["appstreamcli", "validate", "--no-net", "--pedantic",
                             str(metainfo)], capture_output=True, text=True)
    issues = [line for line in (result.stdout + result.stderr).splitlines()
              if re.match(r"^[EWIP]: ", line)]
    for line in issues:
        print(f"    {line}")
    if any(line.startswith("E: ") for line in issues):
        sys.exit(f"error: appstreamcli rejected {metainfo.name}")
    print(f"  appstreamcli: {metainfo.name} OK"
          + (f" ({len(issues)} notes)" if issues else ""))


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
    bundle_app_dependencies(usr_bin)
    verify_bundle_self_contained(usr_bin)

    # Create AppRun script
    print("  Creating AppRun script...")
    apprun_path = APPDIR / "AppRun"
    apprun_path.write_text(create_apprun())
    apprun_path.chmod(apprun_path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    # Create .desktop file
    print("  Creating .desktop file...")
    desktop_path = APPDIR / f"{APP_ID}.desktop"
    desktop_path.write_text(create_desktop_file())
    # Also copy to usr/share/applications
    shutil.copy2(desktop_path, usr_share_applications / f"{APP_ID}.desktop")

    # AppStream metadata, for AppImageHub and software centres. Named
    # *.appdata.xml rather than *.metainfo.xml because AppImageHub's
    # appdir-lint.sh looks for that suffix only; AppStream reads both.
    print("  Writing AppStream metainfo...")
    metainfo_dir = APPDIR / "usr" / "share" / "metainfo"
    metainfo_dir.mkdir(parents=True, exist_ok=True)
    metainfo_path = metainfo_dir / f"{APP_ID}.appdata.xml"
    metainfo_path.write_text(create_metainfo())
    validate_metadata(desktop_path, metainfo_path)

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

    # Try running appimagetool directly first. check=False: run_command exits
    # the script on failure, which no `except` here would ever see.
    result = run_command([str(appimagetool), str(appdir), str(output_path)],
                         cwd=BUILD_DIR, check=False)
    if result.returncode != 0:
        # No FUSE (a container, a minimal system): unpack appimagetool and
        # run it from there instead of mounting it.
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


# The newest glibc an AppImage we publish may ask for: Ubuntu 22.04's, the
# oldest LTS in standard support and the release AppImageHub tests on.
GLIBC_TARGET = (2, 35)


def required_glibc(appdir: Path) -> tuple[int, int]:
    """The newest GLIBC_x.y symbol version any ELF file in [appdir] needs."""
    newest = (0, 0)
    for path in appdir.rglob("*"):
        if not path.is_file() or path.is_symlink():
            continue
        with path.open("rb") as f:
            if f.read(4) != b"\x7fELF":
                continue
        out = subprocess.run(["objdump", "-T", str(path)], capture_output=True,
                             text=True).stdout
        for major, minor in re.findall(r"GLIBC_(\d+)\.(\d+)", out):
            newest = max(newest, (int(major), int(minor)))
    return newest


CONTAINER_IMAGE = "noo-appimage-build:ubuntu22.04"
CONTAINER_DOCKERFILE = SCRIPT_DIR / "docker" / "appimage-ubuntu2204.Dockerfile"


def build_in_container(args: argparse.Namespace) -> None:
    """Run this script again inside the Ubuntu 22.04 image.

    An AppImage needs the glibc it was linked against or newer, and every
    native library here (the plugins, sqlite3mc, whisper, the bundled
    GStreamer) is linked on the build machine — so one built on 24.04 asks for
    glibc 2.38 and will not start on 22.04, Debian 12 or RHEL 9.

    The source tree, the Flutter SDK and the pub cache are mounted at their
    host paths, so the build uses the same Flutter and nothing is downloaded
    twice; it runs as the caller's uid so what it writes stays the caller's.
    client/build/linux is always rebuilt: a CMake cache configured on the host
    names the host's compilers and libraries.
    """
    if shutil.which("docker") is None:
        sys.exit("error: --container needs docker")
    flutter = shutil.which("flutter")
    if flutter is None:
        sys.exit("error: flutter not found on PATH")
    flutter_root = Path(flutter).resolve().parent.parent
    pub_cache = Path(os.environ.get("PUB_CACHE") or Path.home() / ".pub-cache")
    pub_cache.mkdir(parents=True, exist_ok=True)

    run_command(["docker", "build", "-t", CONTAINER_IMAGE,
                 "-f", str(CONTAINER_DOCKERFILE), str(CONTAINER_DOCKERFILE.parent)])

    inner = ["python3", str(Path(__file__).resolve()), "--clean"]
    if args.debug:
        inner.append("--debug")
    home = APPIMAGE_BUILD_DIR.parent / "container-home"
    home.mkdir(parents=True, exist_ok=True)
    run_command([
        "docker", "run", "--rm",
        "--user", f"{os.getuid()}:{os.getgid()}",
        "-v", f"{PROJECT_ROOT}:{PROJECT_ROOT}",
        "-v", f"{flutter_root}:{flutter_root}",
        "-v", f"{pub_cache}:{pub_cache}",
        "-e", f"HOME={home}",
        "-e", f"PUB_CACHE={pub_cache}",
        "-e", f"PATH={flutter_root / 'bin'}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        "-e", "NOO_IN_BUILD_CONTAINER=1",
        "-w", str(PROJECT_ROOT),
        CONTAINER_IMAGE, *inner,
    ])


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
    parser.add_argument(
        "--container",
        action="store_true",
        help="Build inside Ubuntu 22.04 (docker) so the AppImage runs on glibc 2.35+"
    )

    args = parser.parse_args()

    if args.container:
        if args.skip_build:
            sys.exit("error: --container always builds; drop --skip-build")
        build_in_container(args)
        return

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

    # The glibc floor, said out loud: an AppImage built on a newer distro
    # starts on nothing older, and nothing else about it says so.
    glibc = required_glibc(appdir) if shutil.which("objdump") else None
    if glibc:
        print(f"  Requires glibc {glibc[0]}.{glibc[1]} or newer")
        if glibc > GLIBC_TARGET:
            print(f"  Warning: newer than {GLIBC_TARGET[0]}.{GLIBC_TARGET[1]} (Ubuntu 22.04);"
                  " it will not start there. Build with --container to publish it.")

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
