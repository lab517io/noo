#!/usr/bin/env python3
"""
Build script to produce Android artifacts for the Noo Flutter application.

Builds an AAB (Play Store upload format) by default; --apk additionally
builds a universal APK for sideloading.

Release signing: create client/android/key.properties pointing at your
upload keystore (see docs/PLAY_RELEASE.md). Without it, release builds are
signed with the debug key — fine for local testing, rejected by Play. The
script prints which key signed the output so this can't go unnoticed.

Usage:
    python build_android.py [--release|--debug] [--apk] [--clean]

Options:
    --release     Build in release mode (default)
    --debug       Build in debug mode
    --apk         Also build a universal APK alongside the AAB
    --clean       Clean Android build artifacts before building
"""

import argparse
import os
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
    """Read the major.minor.patch version from pubspec.yaml.

    Versioning is plain semver with no +build suffix; the Android versionCode is
    derived from these three numbers in android/app/build.gradle.kts. Any legacy
    +N is stripped so old pubspecs still name artifacts sensibly.
    """
    pubspec_path = CLIENT_DIR / "pubspec.yaml"
    if not pubspec_path.exists():
        print(f"Warning: pubspec.yaml not found at {pubspec_path}, using default version")
        return "0.0.0"

    content = pubspec_path.read_text()
    match = re.search(r'^version:\s*(\S+)', content, re.MULTILINE)
    if match:
        return match.group(1).split('+')[0]

    print("Warning: version not found in pubspec.yaml, using default version")
    return "0.0.0"


# Configuration
APP_NAME = "noo"
APP_DISPLAY_NAME = "Noo"
APP_VERSION = get_version_from_pubspec()
BUILD_DIR = PROJECT_ROOT / "build"
RELEASES_DIR = SCRIPT_DIR / "releases"

# This machine's global ~/.gradle/gradle.properties carries a stale proxy;
# builds work with the isolated Gradle home. Harmless elsewhere: the
# directory is simply created on first use.
GRADLE_USER_HOME = os.environ.get(
    "GRADLE_USER_HOME", str(Path.home() / ".gradle-noo"))


def run_command(cmd: list[str], cwd: Path | None = None, check: bool = True) -> subprocess.CompletedProcess:
    """Run a command and return the result."""
    print(f"  Running: {' '.join(cmd)}")
    env = dict(os.environ, GRADLE_USER_HOME=GRADLE_USER_HOME)
    result = subprocess.run(cmd, cwd=cwd, capture_output=False, text=True, env=env)
    if check and result.returncode != 0:
        print(f"Error: Command failed with return code {result.returncode}")
        sys.exit(1)
    return result


def check_dependencies() -> bool:
    """Check if required dependencies are installed."""
    print("Checking dependencies...")
    if shutil.which("flutter") is None:
        print("Error: flutter not found on PATH.")
        return False
    print("  All dependencies satisfied.")
    return True


def clean_build() -> None:
    """Clean Android build artifacts."""
    print("Cleaning Android build artifacts...")
    flutter_build = CLIENT_DIR / "build" / "app"
    if flutter_build.exists():
        shutil.rmtree(flutter_build)
        print(f"  Removed {flutter_build}")


def signing_identity(artifact: Path) -> str:
    """Best-effort description of the certificate that signed the artifact.

    AABs and APKs are both zip containers with the signature block under
    META-INF; extracting the signer CN is enough to tell a debug key
    (CN=Android Debug) from a real upload key.
    """
    try:
        with zipfile.ZipFile(artifact) as zf:
            sig = next(
                (n for n in zf.namelist()
                 if n.startswith("META-INF/") and n.endswith((".RSA", ".DSA", ".EC"))),
                None,
            )
            if sig is None:
                # APKs signed only with v2+ schemes have no META-INF entry.
                return "no v1 signature entry (v2+ scheme only) — check with apksigner"
            data = zf.read(sig)
        proc = subprocess.run(
            ["openssl", "pkcs7", "-inform", "DER", "-print_certs", "-noout"],
            input=data, capture_output=True)
        text = proc.stdout.decode(errors="replace")
        match = re.search(r"subject=.*", text)
        return match.group(0) if match else "unknown (could not parse certificate)"
    except Exception as e:  # noqa: BLE001 - purely informational
        return f"unknown ({e})"


def build_flutter(target: str, release: bool) -> Path:
    """Build the Flutter Android artifact ('appbundle' or 'apk')."""
    mode = "release" if release else "debug"
    print(f"Building Flutter {target} in {mode} mode...")
    run_command(["flutter", "build", target, f"--{mode}", "-t", "lib/main.dart"],
                cwd=CLIENT_DIR)

    if target == "appbundle":
        out = CLIENT_DIR / "build" / "app" / "outputs" / "bundle" / mode / f"app-{mode}.aab"
    else:
        out = CLIENT_DIR / "build" / "app" / "outputs" / "flutter-apk" / f"app-{mode}.apk"

    if not out.exists():
        print(f"Error: Build output not found at {out}")
        sys.exit(1)
    print(f"  Build completed: {out}")
    return out


def publish(artifact: Path, suffix: str) -> Path:
    """Copy the artifact to build/ and scripts/releases/ under a versioned name."""
    output_name = f"{APP_NAME}-{APP_VERSION}-android{suffix}"
    output_path = BUILD_DIR / output_name
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copy2(artifact, output_path)

    RELEASES_DIR.mkdir(parents=True, exist_ok=True)
    release_path = RELEASES_DIR / output_name
    shutil.copy2(artifact, release_path)

    print(f"  {output_path}  ({output_path.stat().st_size / (1024 * 1024):.2f} MB)")
    print(f"  {release_path}")
    return output_path


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Build Noo Flutter application for Android",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__)
    parser.add_argument("--release", action="store_true", default=True,
                        help="Build in release mode (default)")
    parser.add_argument("--debug", action="store_true",
                        help="Build in debug mode")
    parser.add_argument("--apk", action="store_true",
                        help="Also build a universal APK alongside the AAB")
    parser.add_argument("--clean", action="store_true",
                        help="Clean Android build artifacts before building")
    args = parser.parse_args()

    release = not args.debug
    mode = "release" if release else "debug"

    print(f"=== Building {APP_DISPLAY_NAME} for Android ({mode} mode) ===")
    print(f"Project root: {PROJECT_ROOT}")

    key_properties = CLIENT_DIR / "android" / "key.properties"
    if release and not key_properties.exists():
        print()
        print("NOTE: no client/android/key.properties — the release build will "
              "be signed with the DEBUG key and cannot be uploaded to Play. "
              "See docs/PLAY_RELEASE.md.")
    print()

    if not check_dependencies():
        sys.exit(1)
    if args.clean:
        clean_build()

    aab = build_flutter("appbundle", release)
    print("Publishing AAB...")
    published = publish(aab, ".aab")
    print(f"  Signed by: {signing_identity(published)}")

    if args.apk:
        apk = build_flutter("apk", release)
        print("Publishing APK...")
        published_apk = publish(apk, ".apk")
        print(f"  Signed by: {signing_identity(published_apk)}")

    print()
    print("=== Build Complete ===")


if __name__ == "__main__":
    main()
