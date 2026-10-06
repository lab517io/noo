#!/usr/bin/env python3
"""
Build script to produce a macOS .app bundle (and a DMG) for the Noo Flutter application.

No Apple Developer certificate is required: the resulting bundle is ad-hoc signed
(codesign --sign -), which is enough to run the app on the same machine it was built on.

When you copy the app to another Mac, Gatekeeper will still quarantine it because it
is not notarized. To open it there, either right-click the app and choose "Open", or
strip the quarantine attribute manually:
    xattr -dr com.apple.quarantine /Applications/Noo.app

Usage:
    python build_macos.py [--release|--debug] [--skip-build] [--clean] [--no-dmg]

Options:
    --release     Build in release mode (default)
    --debug       Build in debug mode
    --skip-build  Skip Flutter build, only package from existing build
    --clean       Clean build artifacts before building
    --no-dmg      Do not create a DMG, only produce the .app bundle (zipped)
"""

import argparse
import platform
import re
import shutil
import subprocess
import sys
import time
import zipfile
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
# Flutter names the bundle after PRODUCT_NAME in macos/Runner/Configs/AppInfo.xcconfig.
APP_BUNDLE_NAME = f"{APP_NAME}.app"
BUILD_DIR = PROJECT_ROOT / "build"
MACOS_BUILD_DIR = BUILD_DIR / "macos_dist"
RELEASES_DIR = SCRIPT_DIR / "releases"


def run_command(cmd: list[str], cwd: Path | None = None, check: bool = True) -> subprocess.CompletedProcess:
    """Run a command and return the result."""
    print(f"  Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd=cwd, capture_output=False, text=True)
    if check and result.returncode != 0:
        print(f"Error: Command failed with return code {result.returncode}")
        sys.exit(1)
    return result


def check_dependencies() -> bool:
    """Check if required dependencies are installed."""
    print("Checking dependencies...")

    if platform.system() != "Darwin":
        print("Error: macOS builds can only be produced on macOS.")
        return False

    missing = []

    # Check for Flutter
    if shutil.which("flutter") is None:
        missing.append("flutter")

    # codesign / hdiutil ship with macOS but check anyway for a clear error.
    if shutil.which("codesign") is None:
        missing.append("codesign (Xcode command line tools)")

    if missing:
        print(f"Error: Missing required dependencies: {', '.join(missing)}")
        print("Please install them before running this script.")
        return False

    print("  All dependencies satisfied.")
    return True


def clean_build() -> None:
    """Clean build artifacts."""
    print("Cleaning build artifacts...")

    if MACOS_BUILD_DIR.exists():
        shutil.rmtree(MACOS_BUILD_DIR)
        print(f"  Removed {MACOS_BUILD_DIR}")

    flutter_build = CLIENT_DIR / "build" / "macos"
    if flutter_build.exists():
        shutil.rmtree(flutter_build)
        print(f"  Removed {flutter_build}")


def build_flutter(release: bool = True) -> Path:
    """Build the Flutter macOS application."""
    mode = "release" if release else "debug"
    print(f"Building Flutter application in {mode} mode...")

    # The macOS platform folder is created lazily by `flutter create`; make sure it
    # exists so a fresh checkout can build without a manual step.
    if not (CLIENT_DIR / "macos").exists():
        print("  macOS platform folder missing, generating it...")
        run_command(["flutter", "create", "--platforms=macos", f"--project-name={APP_NAME}", "."],
                    cwd=CLIENT_DIR)

    cmd = ["flutter", "build", "macos", f"--{mode}"]
    run_command(cmd, cwd=CLIENT_DIR)

    # macOS builds go to: build/macos/Build/Products/{Release,Debug}/<name>.app
    mode_dir = "Release" if release else "Debug"
    products_dir = CLIENT_DIR / "build" / "macos" / "Build" / "Products" / mode_dir
    app_bundle = products_dir / APP_BUNDLE_NAME

    if not app_bundle.exists():
        # Fall back to whatever .app got produced (in case PRODUCT_NAME differs).
        candidates = list(products_dir.glob("*.app"))
        if candidates:
            app_bundle = candidates[0]
        else:
            print(f"Error: Build output not found at {app_bundle}")
            sys.exit(1)

    print(f"  Build completed: {app_bundle}")
    return app_bundle


def adhoc_sign(app_bundle: Path) -> None:
    """Ad-hoc sign the app so it runs locally without a developer certificate."""
    print("Ad-hoc signing the app bundle...")

    entitlements = CLIENT_DIR / "macos" / "Runner" / "Release.entitlements"
    cmd = ["codesign", "--force", "--deep", "--sign", "-"]
    if entitlements.exists():
        cmd += ["--entitlements", str(entitlements)]
    cmd.append(str(app_bundle))

    # Signing failures should not abort the build: the app still runs, it just may
    # prompt on first launch. Warn instead of exiting.
    result = run_command(cmd, check=False)
    if result.returncode != 0:
        print("  Warning: ad-hoc signing failed; the app may need a right-click > Open on first launch.")
    else:
        print("  Ad-hoc signing complete.")


def stage_app(app_bundle: Path) -> Path:
    """Copy the built .app into a clean staging directory."""
    print("Staging app bundle...")

    if MACOS_BUILD_DIR.exists():
        shutil.rmtree(MACOS_BUILD_DIR)
    MACOS_BUILD_DIR.mkdir(parents=True)

    staged_app = MACOS_BUILD_DIR / app_bundle.name
    shutil.copytree(app_bundle, staged_app, symlinks=True)
    print(f"  Staged at {staged_app}")
    return staged_app


# Layout of the mounted disk image, in points. The same numbers are drawn into
# scripts/assets/dmg/background.svg (the two card outlines); change them here and
# the artwork no longer lines up with the icons.
#
# The window is 20pt taller than the 640x380 background because Finder measures a
# window's bounds over its title bar. It is deliberately not taller still: anything
# past the image would show as a bare strip of window, whereas coming up short only
# eats into the band of plain gradient the artwork keeps free at the bottom -- which
# is also what happens to anyone who has Finder's path bar switched on.
DMG_WINDOW_ORIGIN = (360, 160)
DMG_WINDOW_SIZE = (640, 400)
DMG_ICON_SIZE = 128
DMG_APP_POS = (170, 191)
DMG_LINK_POS = (470, 191)

DMG_ASSETS_DIR = SCRIPT_DIR / "assets" / "dmg"
APPICON_DIR = CLIENT_DIR / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"


def stage_dmg_background(dmg_src: Path) -> str | None:
    """Put the window background inside the image; return its name under .background."""
    one_x = DMG_ASSETS_DIR / "background.png"
    two_x = DMG_ASSETS_DIR / "background@2x.png"
    if not one_x.exists():
        print(f"  Warning: {one_x} missing, the disk image gets a plain window.")
        return None

    bg_dir = dmg_src / ".background"
    bg_dir.mkdir(parents=True, exist_ok=True)

    # Finder scales a background to its pixel size, so a lone @2x image would come
    # out twice as large as the window. The Retina rendition has to travel as a
    # second representation inside one TIFF instead.
    if two_x.exists() and shutil.which("tiffutil") is not None:
        tiff = bg_dir / "background.tiff"
        result = subprocess.run(
            ["tiffutil", "-cathidpicheck", str(one_x), str(two_x), "-out", str(tiff)],
            capture_output=True, text=True)
        if result.returncode == 0 and tiff.exists():
            return tiff.name
        print("  Warning: tiffutil failed, falling back to the non-Retina background.")

    shutil.copy2(one_x, bg_dir / one_x.name)
    return one_x.name


def apply_volume_icon(mount_point: Path) -> bool:
    """Give the mounted volume the app's icon, so it is not a generic disk in the Finder."""
    if shutil.which("iconutil") is None or shutil.which("SetFile") is None:
        return False
    if not APPICON_DIR.exists():
        return False

    # iconutil wants its own file names; the appiconset has one PNG per pixel size,
    # and several of those serve as both the 1x of one slot and the 2x of the next.
    wanted = {
        16: ["icon_16x16.png"],
        32: ["icon_16x16@2x.png", "icon_32x32.png"],
        64: ["icon_32x32@2x.png"],
        128: ["icon_128x128.png"],
        256: ["icon_128x128@2x.png", "icon_256x256.png"],
        512: ["icon_256x256@2x.png", "icon_512x512.png"],
        1024: ["icon_512x512@2x.png"],
    }

    iconset = MACOS_BUILD_DIR / "volume.iconset"
    if iconset.exists():
        shutil.rmtree(iconset)
    iconset.mkdir(parents=True)

    for px, names in wanted.items():
        source = APPICON_DIR / f"app_icon_{px}.png"
        if not source.exists():
            continue
        for name in names:
            shutil.copy2(source, iconset / name)

    icns = mount_point / ".VolumeIcon.icns"
    result = subprocess.run(["iconutil", "-c", "icns", str(iconset), "-o", str(icns)],
                            capture_output=True, text=True)
    shutil.rmtree(iconset)

    if result.returncode != 0 or not icns.exists():
        print("  Warning: could not build the volume icon.")
        return False

    # The type code is what marks the file as the volume's icon; the attribute on the
    # volume itself is what makes the Finder look for it.
    subprocess.run(["SetFile", "-c", "icnC", str(icns)], capture_output=True, text=True)
    subprocess.run(["SetFile", "-a", "C", str(mount_point)], capture_output=True, text=True)
    return True


def arrange_dmg_window(volume_name: str, app_name: str, background: str | None) -> None:
    """Have Finder write the window's geometry, icon positions and background into .DS_Store."""
    picture = ""
    if background is not None:
        picture = f'set background picture of opts to file ".background:{background}"'

    left, top = DMG_WINDOW_ORIGIN
    width, height = DMG_WINDOW_SIZE
    script = f'''
    tell application "Finder"
      tell disk "{volume_name}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {{{left}, {top}, {left + width}, {top + height}}}
        set opts to the icon view options of container window
        set arrangement of opts to not arranged
        set icon size of opts to {DMG_ICON_SIZE}
        set text size of opts to 12
        set label position of opts to bottom
        set shows item info of opts to false
        {picture}
        set position of item "{app_name}" of container window to {{{DMG_APP_POS[0]}, {DMG_APP_POS[1]}}}
        set position of item "Applications" of container window to {{{DMG_LINK_POS[0]}, {DMG_LINK_POS[1]}}}
        update without registering applications
        close
      end tell
    end tell
    '''

    # Finder is not always there to talk to -- a build over SSH, or an automation
    # permission the machine has never been asked for. A disk image with a default
    # window is worth more than a failed build, so this only warns.
    try:
        result = subprocess.run(["osascript", "-e", script],
                                capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        print("  Warning: Finder did not answer, the window layout was not applied.")
        return
    if result.returncode != 0:
        print(f"  Warning: window layout failed: {result.stderr.strip()}")


def detach_volume(mount_point: str) -> None:
    """Unmount, retrying: Finder can still hold the volume for a moment after closing it."""
    for _ in range(5):
        result = subprocess.run(["hdiutil", "detach", mount_point, "-quiet"],
                                capture_output=True, text=True)
        if result.returncode == 0:
            return
        time.sleep(2)
    subprocess.run(["hdiutil", "detach", mount_point, "-force", "-quiet"],
                   capture_output=True, text=True)


def create_dmg(staged_app: Path) -> Path | None:
    """Create a DMG containing the app and an /Applications shortcut."""
    print("Creating DMG...")

    if shutil.which("hdiutil") is None:
        print("  Warning: hdiutil not found, skipping DMG creation.")
        return None

    output_name = f"{APP_NAME}-{APP_VERSION}-macos.dmg"
    output_path = BUILD_DIR / output_name
    if output_path.exists():
        output_path.unlink()

    # Build the DMG contents in a temporary staging folder: the app plus a symlink
    # to /Applications so the user can drag-and-drop to install.
    dmg_src = MACOS_BUILD_DIR / "dmg_src"
    if dmg_src.exists():
        shutil.rmtree(dmg_src)
    dmg_src.mkdir(parents=True)

    shutil.copytree(staged_app, dmg_src / staged_app.name, symlinks=True)
    (dmg_src / "Applications").symlink_to("/Applications")
    background = stage_dmg_background(dmg_src)

    # A read-write image first: Finder has to open the volume and write a .DS_Store
    # into it before the image can be compressed and shipped. Room is left over the
    # payload for that and for the filesystem's own overhead.
    used_kb = int(subprocess.run(["du", "-sk", str(dmg_src)],
                                 capture_output=True, text=True).stdout.split()[0])
    size_kb = used_kb + 40 * 1024

    rw_dmg = MACOS_BUILD_DIR / "rw.dmg"
    if rw_dmg.exists():
        rw_dmg.unlink()

    result = run_command([
        "hdiutil", "create",
        "-volname", APP_DISPLAY_NAME,
        "-srcfolder", str(dmg_src),
        "-fs", "HFS+",
        "-format", "UDRW",
        "-size", f"{size_kb}k",
        "-ov", "-quiet",
        str(rw_dmg),
    ], check=False)
    shutil.rmtree(dmg_src)

    if result.returncode != 0 or not rw_dmg.exists():
        print("  Warning: DMG creation failed.")
        return None

    attach = subprocess.run(
        ["hdiutil", "attach", str(rw_dmg), "-readwrite", "-noverify", "-noautoopen"],
        capture_output=True, text=True)
    mount_point = ""
    for line in attach.stdout.splitlines():
        if "/Volumes/" in line:
            mount_point = "/Volumes/" + line.split("/Volumes/", 1)[1].strip()
            break

    if attach.returncode == 0 and mount_point:
        # The volume may not be called what we asked for: a stale volume of the same
        # name makes the mounter append a number, and Finder is addressed by name.
        volume_name = Path(mount_point).name
        arrange_dmg_window(volume_name, staged_app.name, background)
        # After Finder, never before: opening the volume deletes a .VolumeIcon.icns
        # that is already sitting there, and clears the bit that would have used it.
        apply_volume_icon(Path(mount_point))
        subprocess.run(["sync"], capture_output=True)
        detach_volume(mount_point)
    else:
        print("  Warning: could not mount the image, shipping it without a window layout.")

    result = run_command([
        "hdiutil", "convert", str(rw_dmg),
        "-format", "UDZO",
        "-imagekey", "zlib-level=9",
        "-o", str(output_path),
        "-ov", "-quiet",
    ], check=False)
    rw_dmg.unlink(missing_ok=True)

    if result.returncode != 0 or not output_path.exists():
        print("  Warning: DMG creation failed.")
        return None

    print(f"  DMG created: {output_path}")
    print(f"  Size: {output_path.stat().st_size / (1024 * 1024):.2f} MB")
    return output_path


def create_zip_archive(staged_app: Path) -> Path:
    """Create a ZIP archive of the .app bundle (preserving symlinks and permissions)."""
    print("Creating ZIP archive...")

    output_name = f"{APP_NAME}-{APP_VERSION}-macos.zip"
    output_path = BUILD_DIR / output_name
    if output_path.exists():
        output_path.unlink()

    # Use `ditto` when available: it preserves the bundle's symlinks, resource
    # forks and executable bits, which Python's zipfile does not.
    if shutil.which("ditto") is not None:
        run_command(["ditto", "-c", "-k", "--sequesterRsrc", "--keepParent",
                     str(staged_app), str(output_path)])
    else:
        with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as zipf:
            for file_path in staged_app.rglob("*"):
                if file_path.is_file():
                    arcname = file_path.relative_to(staged_app.parent)
                    zipf.write(file_path, arcname)

    if output_path.exists():
        print(f"  ZIP archive created: {output_path}")
        print(f"  Size: {output_path.stat().st_size / (1024 * 1024):.2f} MB")
        return output_path

    print("Error: Failed to create ZIP archive")
    sys.exit(1)


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Build Noo Flutter application as a macOS .app bundle / DMG",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument("--release", action="store_true", default=True,
                        help="Build in release mode (default)")
    parser.add_argument("--debug", action="store_true", help="Build in debug mode")
    parser.add_argument("--skip-build", action="store_true",
                        help="Skip Flutter build, use existing build output")
    parser.add_argument("--clean", action="store_true",
                        help="Clean build artifacts before building")
    parser.add_argument("--no-dmg", action="store_true",
                        help="Do not create a DMG, only the zipped .app bundle")

    args = parser.parse_args()

    release = not args.debug
    mode = "release" if release else "debug"
    mode_dir = "Release" if release else "Debug"

    print(f"=== Building {APP_DISPLAY_NAME} macOS app ({mode} mode) ===")
    print(f"Project root: {PROJECT_ROOT}")
    print(f"Client directory: {CLIENT_DIR}")
    print()

    if not check_dependencies():
        sys.exit(1)

    if args.clean:
        clean_build()

    # Build Flutter app or use existing build
    if args.skip_build:
        products_dir = CLIENT_DIR / "build" / "macos" / "Build" / "Products" / mode_dir
        app_bundle = products_dir / APP_BUNDLE_NAME
        if not app_bundle.exists():
            candidates = list(products_dir.glob("*.app")) if products_dir.exists() else []
            if candidates:
                app_bundle = candidates[0]
            else:
                print(f"Error: No existing build found at {app_bundle}")
                print("Run without --skip-build to create a new build.")
                sys.exit(1)
        print(f"Using existing build at {app_bundle}")
    else:
        app_bundle = build_flutter(release=release)

    # Ad-hoc sign so it runs locally without a developer certificate.
    adhoc_sign(app_bundle)

    # Stage a clean copy for packaging.
    staged_app = stage_app(app_bundle)

    # Package: DMG (default) and/or ZIP.
    artifacts: list[Path] = []
    if not args.no_dmg:
        dmg_path = create_dmg(staged_app)
        if dmg_path is not None:
            artifacts.append(dmg_path)
    zip_path = create_zip_archive(staged_app)
    artifacts.append(zip_path)

    # Copy artifacts to releases directory
    print("Copying to releases directory...")
    RELEASES_DIR.mkdir(parents=True, exist_ok=True)
    release_paths = []
    for artifact in artifacts:
        release_path = RELEASES_DIR / artifact.name
        shutil.copy2(artifact, release_path)
        release_paths.append(release_path)
        print(f"  Copied to {release_path}")

    print()
    print("=== Build Complete ===")
    print(f"App bundle: {staged_app}")
    for artifact, release_path in zip(artifacts, release_paths):
        print(f"Artifact:   {artifact}")
        print(f"Release:    {release_path}")
    print()
    print("To run the app locally:")
    print(f"  open {staged_app}")
    print()
    print("Note: this build is ad-hoc signed and not notarized. On another Mac,")
    print("clear the quarantine flag after copying it:")
    print(f"  xattr -dr com.apple.quarantine /Applications/{APP_BUNDLE_NAME}")


if __name__ == "__main__":
    main()
