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

    cmd = [
        "hdiutil", "create",
        "-volname", APP_DISPLAY_NAME,
        "-srcfolder", str(dmg_src),
        "-ov",
        "-format", "UDZO",
        str(output_path),
    ]
    result = run_command(cmd, check=False)
    shutil.rmtree(dmg_src)

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
