#!/usr/bin/env python3
"""
Build script to produce a ZIP archive and an NSIS installer for the Noo
Flutter application on Windows.

Usage:
    python build_windows.py [--release|--debug] [--skip-build] [--no-clean] [--no-installer]

Options:
    --release       Build in release mode (default)
    --debug         Build in debug mode
    --skip-build    Skip Flutter build, only package an existing build
    --no-clean      Skip cleaning build artifacts before building (clean is the default)
    --no-installer  Only produce the ZIP, not the setup.exe

The setup.exe is built from installer/windows/noo.nsi when makensis is found
(on PATH, in Program Files, or in C:\\Tools\\NSIS); without it the ZIP is still
produced and a warning says why the installer is missing.
"""

import argparse
import os
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
OPENSSL_INCLUDE_DIR="C:/tools/vcpkg/installed/x64-windows/include"
OPENSSL_CRYPTO_LIBRARY="C:/tools/vcpkg/installed/x64-windows/lib"
OPENSSL_ROOT_DIR="C:/tools/vcpkg/installed/x64-windows"

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
BUILD_DIR = PROJECT_ROOT / "build"
WINDOWS_BUILD_DIR = BUILD_DIR / "windows_dist"
RELEASES_DIR = SCRIPT_DIR / "releases"
INSTALLER_SCRIPT = PROJECT_ROOT / "installer" / "windows" / "noo.nsi"
INSTALLER_WORK_DIR = BUILD_DIR / "windows_installer"

# The MSVC runtime every plugin DLL imports (MSVCP140, VCRUNTIME140,
# VCRUNTIME140_1). Flutter's bundle does not include it, so on a machine that
# never installed the VC++ Redistributable the app would not start. It is
# shipped app-local instead, which Microsoft permits for these files; the UCRT
# (api-ms-win-crt-*) is part of Windows 10 and needs nothing.
CRT_DLLS = ["msvcp140.dll", "msvcp140_1.dll", "msvcp140_2.dll",
            "vcruntime140.dll", "vcruntime140_1.dll"]


def run_command(cmd: list[str], cwd: Path | None = None, check: bool = True) -> subprocess.CompletedProcess:
    """Run a command and return the result."""
    print(f"  Running: {' '.join(cmd)}")
    
    if not Path(OPENSSL_ROOT_DIR).exists():
        raise RuntimeError(f'OpenSSL root dir is not found at {OPENSSL_ROOT_DIR}')

    #if not Path(OPENSSL_INCLUDE_DIR).exists():
    #    raise RuntimeError(f'OpenSSL include dir is not found at {OPENSSL_INCLUDE_DIR}')
    #if not Path(OPENSSL_CRYPTO_LIBRARY).exists():
    #    raise RuntimeError(f'OpenSSL crypto library directory is not found at {OPENSSL_CRYPTO_LIBRARY}')
    
    myenv = os.environ.copy()
    myenv['OPENSSL_ROOT_DIR'] = OPENSSL_ROOT_DIR
    #myenv['OPENSSL_INCLUDE_DIR'] = OPENSSL_INCLUDE_DIR
    #myenv['OPENSSL_CRYPTO_LIBRARY'] = OPENSSL_CRYPTO_LIBRARY

    result = subprocess.run(cmd, cwd=cwd, capture_output=False, text=True, env=myenv)
    if check and result.returncode != 0:
        print(f"Error: Command failed with return code {result.returncode}")
        sys.exit(1)
    return result


def check_dependencies() -> bool:
    """Check if required dependencies are installed."""
    print("Checking dependencies...")

    missing = []

    # Check for Flutter
    flutter_cmd = "flutter.bat" if platform.system() == "Windows" else "flutter"
    if shutil.which(flutter_cmd) is None and shutil.which("flutter") is None:
        missing.append("flutter")

    if missing:
        print(f"Error: Missing required dependencies: {', '.join(missing)}")
        print("Please install them before running this script.")
        return False

    print("  All dependencies satisfied.")
    return True


def clean_build() -> None:
    """Clean build artifacts."""
    print("Cleaning build artifacts...")

    if WINDOWS_BUILD_DIR.exists():
        shutil.rmtree(WINDOWS_BUILD_DIR)
        print(f"  Removed {WINDOWS_BUILD_DIR}")

    flutter_build = CLIENT_DIR / "build" / "windows"
    if flutter_build.exists():
        shutil.rmtree(flutter_build)
        print(f"  Removed {flutter_build}")


def build_flutter(release: bool = True) -> Path:
    """Build the Flutter Windows application."""
    mode = "release" if release else "debug"
    print(f"Building Flutter application in {mode} mode...")

    flutter_cmd = "flutter.bat" if platform.system() == "Windows" else "flutter"
    if shutil.which(flutter_cmd) is None:
        flutter_cmd = "flutter"

    cmd = [flutter_cmd, "build", "windows", f"--{mode}"]
    run_command(cmd, cwd=CLIENT_DIR)

    # Determine build output path
    # Windows builds go to: build/windows/x64/runner/Release (or Debug)
    mode_dir = "Release" if release else "Debug"
    bundle_dir = CLIENT_DIR / "build" / "windows" / "x64" / "runner" / mode_dir

    if not bundle_dir.exists():
        print(f"Error: Build output not found at {bundle_dir}")
        sys.exit(1)

    print(f"  Build completed: {bundle_dir}")
    return bundle_dir


def find_crt_dir() -> Path | None:
    """Locate Visual Studio's x64 CRT redistributable folder."""
    program_files_x86 = os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)")
    vswhere = Path(program_files_x86) / "Microsoft Visual Studio" / "Installer" / "vswhere.exe"
    if not vswhere.exists():
        return None
    result = subprocess.run(
        [str(vswhere), "-latest", "-products", "*", "-property", "installationPath"],
        capture_output=True, text=True)
    vs_path = result.stdout.strip()
    if result.returncode != 0 or not vs_path:
        return None
    redist = Path(vs_path) / "VC" / "Redist" / "MSVC"
    # Newest toolset first; each holds x64/Microsoft.VC<nnn>.CRT.
    for version_dir in sorted(redist.glob("14.*"), reverse=True):
        for crt in sorted((version_dir / "x64").glob("Microsoft.VC*.CRT"), reverse=True):
            if all((crt / dll).exists() for dll in CRT_DLLS):
                return crt
    return None


def copy_crt(dist_dir: Path) -> None:
    """Copy the MSVC runtime next to the executable."""
    crt_dir = find_crt_dir()
    if crt_dir is None:
        print("  Warning: Visual Studio CRT redistributable not found; the package")
        print("           will need the VC++ Redistributable installed to run.")
        return
    for dll in CRT_DLLS:
        shutil.copy2(crt_dir / dll, dist_dir / dll)
    print(f"    Copied {len(CRT_DLLS)} MSVC runtime DLLs from {crt_dir}")


def create_dist_dir(bundle_dir: Path) -> Path:
    """Create the distribution directory structure."""
    print("Creating distribution directory...")

    # Clean and create dist directory
    dist_dir = WINDOWS_BUILD_DIR / APP_NAME
    if dist_dir.exists():
        shutil.rmtree(dist_dir)
    dist_dir.mkdir(parents=True)

    # Copy the entire bundle contents
    print("  Copying application files...")

    # Copy executable
    src_executable = bundle_dir / f"{APP_NAME}.exe"
    if not src_executable.exists():
        print(f"Error: Executable not found at {src_executable}")
        sys.exit(1)
    shutil.copy2(src_executable, dist_dir / f"{APP_NAME}.exe")
    print(f"    Copied {APP_NAME}.exe")

    # Copy all DLL files
    dll_count = 0
    for dll_file in bundle_dir.glob("*.dll"):
        shutil.copy2(dll_file, dist_dir / dll_file.name)
        dll_count += 1
    print(f"    Copied {dll_count} DLL files")

    copy_crt(dist_dir)

    # Copy data directory (Flutter assets)
    src_data = bundle_dir / "data"
    if src_data.exists():
        shutil.copytree(src_data, dist_dir / "data", dirs_exist_ok=True)
        print("    Copied data directory (Flutter assets)")
    else:
        print("  Warning: data directory not found")

    print(f"  Distribution directory created at {dist_dir}")
    return dist_dir


def create_zip_archive(dist_dir: Path) -> Path:
    """Create a ZIP archive from the distribution directory."""
    print("Creating ZIP archive...")

    # Determine output filename
    arch = "x64"  # Flutter Windows currently builds for x64
    output_name = f"{APP_NAME}-{APP_VERSION}-windows-{arch}.zip"
    output_path = BUILD_DIR / output_name

    # Remove existing archive if present
    if output_path.exists():
        output_path.unlink()

    # Create ZIP archive
    with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as zipf:
        for file_path in dist_dir.rglob("*"):
            if file_path.is_file():
                arcname = file_path.relative_to(dist_dir.parent)
                zipf.write(file_path, arcname)

    if output_path.exists():
        print(f"  ZIP archive created: {output_path}")
        print(f"  Size: {output_path.stat().st_size / (1024 * 1024):.2f} MB")
        return output_path
    else:
        print("Error: Failed to create ZIP archive")
        sys.exit(1)


def find_makensis() -> Path | None:
    """Locate makensis.exe."""
    found = shutil.which("makensis")
    if found:
        return Path(found)
    candidates = [
        Path(os.environ.get("ProgramFiles", r"C:\Program Files")) / "NSIS",
        Path(os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)")) / "NSIS",
        Path(r"C:\Tools\NSIS"),
    ]
    for directory in candidates:
        exe = directory / "makensis.exe"
        if exe.exists():
            return exe
    return None


def write_file_list(dist_dir: Path, out: Path) -> None:
    """Generate the install/uninstall macros for exactly the files in dist_dir.

    The uninstaller deletes this list rather than a wildcard, because the user
    may have pointed the install at a directory that holds other things.
    """
    files = sorted((p for p in dist_dir.rglob("*") if p.is_file()),
                   key=lambda p: str(p).lower())
    dirs = sorted({p.parent for p in files}, key=lambda d: str(d).lower())
    for path in files:
        if '"' in str(path) or "$" in str(path):
            raise RuntimeError(f"Unsupported character in path: {path}")

    def inst(rel: Path) -> str:
        return "$INSTDIR" if rel == Path(".") else f"$INSTDIR\\{rel}"

    lines = ["; Generated by scripts/build_windows.py - do not edit.", "",
             "!macro NOO_INSTALL_FILES"]
    for d in dirs:
        lines.append(f'  SetOutPath "{inst(d.relative_to(dist_dir))}"')
        lines += [f'  File "{f}"' for f in files if f.parent == d]
    lines += ["!macroend", "", "!macro NOO_UNINSTALL_FILES"]
    lines += [f'  Delete "{inst(f.relative_to(dist_dir))}"' for f in files]
    # Deepest first, so each directory is empty by the time it is removed.
    for d in sorted(dirs, key=lambda d: len(d.parts), reverse=True):
        if d != dist_dir:
            lines.append(f'  RMDir "{inst(d.relative_to(dist_dir))}"')
    lines += ["!macroend", ""]
    out.write_text("\n".join(lines), encoding="utf-8-sig")


def create_installer(dist_dir: Path) -> Path | None:
    """Build the NSIS setup.exe from the distribution directory."""
    print("Creating installer...")
    makensis = find_makensis()
    if makensis is None:
        print("  Warning: makensis not found (install NSIS 3); skipping installer.")
        return None

    INSTALLER_WORK_DIR.mkdir(parents=True, exist_ok=True)
    files_nsh = INSTALLER_WORK_DIR / "files.nsh"
    write_file_list(dist_dir, files_nsh)

    output_path = BUILD_DIR / f"{APP_NAME}-{APP_VERSION}-windows-x64-setup.exe"
    if output_path.exists():
        output_path.unlink()

    cmd = [
        str(makensis), "/V2",
        f"/DVERSION={APP_VERSION}",
        f"/DSOURCE_DIR={dist_dir}",
        f"/DFILES_NSH={files_nsh}",
        f"/DOUTFILE={output_path}",
        str(INSTALLER_SCRIPT),
    ]
    print(f"  Running: {' '.join(cmd)}")
    result = subprocess.run(cmd)
    if result.returncode != 0 or not output_path.exists():
        print(f"Error: makensis failed with return code {result.returncode}")
        sys.exit(1)

    print(f"  Installer created: {output_path}")
    print(f"  Size: {output_path.stat().st_size / (1024 * 1024):.2f} MB")
    return output_path


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Build Noo Flutter application as Windows ZIP archive",
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
        "--no-clean",
        action="store_true",
        help="Skip cleaning build artifacts before building"
    )
    parser.add_argument(
        "--no-installer",
        action="store_true",
        help="Only produce the ZIP, not the NSIS setup.exe"
    )

    args = parser.parse_args()

    # Determine build mode
    release = not args.debug
    mode = "release" if release else "debug"
    mode_dir = "Release" if release else "Debug"

    print(f"=== Building {APP_DISPLAY_NAME} Windows ZIP ({mode} mode) ===")
    print(f"Project root: {PROJECT_ROOT}")
    print(f"Client directory: {CLIENT_DIR}")
    print()

    # Check dependencies
    if not check_dependencies():
        sys.exit(1)

    # Always clean before building unless skipping build or explicitly opted out.
    # A stale client/build/windows/x64/CMakeCache.txt can pin CMAKE_INSTALL_PREFIX
    # to "C:/Program Files/noo", which makes the INSTALL step fail without admin
    # rights. Cleaning forces CMake to re-run its first-configure init logic.
    if not args.skip_build and not args.no_clean:
        clean_build()

    # Build Flutter app or use existing build
    if args.skip_build:
        bundle_dir = CLIENT_DIR / "build" / "windows" / "x64" / "runner" / mode_dir
        if not bundle_dir.exists():
            print(f"Error: No existing build found at {bundle_dir}")
            print("Run without --skip-build to create a new build.")
            sys.exit(1)
        print(f"Using existing build at {bundle_dir}")
    else:
        bundle_dir = build_flutter(release=release)

    # Create distribution directory
    dist_dir = create_dist_dir(bundle_dir)

    # Create ZIP archive
    zip_path = create_zip_archive(dist_dir)

    installer_path = None if args.no_installer else create_installer(dist_dir)

    # Copy to releases directory
    print("Copying to releases directory...")
    RELEASES_DIR.mkdir(parents=True, exist_ok=True)
    for artifact in (zip_path, installer_path):
        if artifact is not None:
            shutil.copy2(artifact, RELEASES_DIR / artifact.name)
            print(f"  Copied to {RELEASES_DIR / artifact.name}")

    print()
    print("=== Build Complete ===")
    print(f"ZIP Archive: {zip_path}")
    if installer_path is not None:
        print(f"Installer:   {installer_path}")
    print(f"Releases:    {RELEASES_DIR}")
    print()
    print("To install, extract the ZIP archive and run:")
    print(f"  {APP_NAME}\\{APP_NAME}.exe")


if __name__ == "__main__":
    main()
