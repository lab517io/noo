#!/usr/bin/env python3
"""
Build the Android APK published on GitHub the way F-Droid builds it, then sign
it with our own key.

F-Droid builds Noo from source. With `Binaries:` and `AllowedAPKSigningKeys:`
in its recipe it then downloads our APK from the GitHub release, and only if its
own build is identical to ours apart from the signature does it publish *ours*
-- so the F-Droid copy and the GitHub copy are one file, signed by one key, and
a user can move between them without reinstalling. A release whose APK does not
match is not published on F-Droid at all. See docs/FDROID.md.

Identical means byte for byte, and our native libraries and the compiled Dart
code embed the paths they were built at. So this script does not imitate
F-Droid's build: it runs F-Droid's own -- fdroidserver at the commit
fdroiddata's CI pins, in F-Droid's buildserver image, from the recipe in
fdroid/io.lab517.noo.yml, at the paths F-Droid uses (/home/vagrant/build/...).

What it builds is the committed tree at --ref, never the working copy: F-Droid
builds a tag, and uncommitted edits would be one more way for the two to differ.

Usage:
    python build_android_reproducible.py                # HEAD, signed
    python build_android_reproducible.py --ref v1.2.17
    python build_android_reproducible.py --no-sign      # unsigned only

Output:
    build/noo-<version>-android.apk           signed with client/android/key.properties
    scripts/releases/noo-<version>-android.apk  (the copy publish_release.py uploads)
    build/noo-<version>-android-unsigned.apk  what F-Droid will compare against

Needs docker (the image is ~700 MB, pulled on first use), network access (the
build fetches fdroidserver, Flutter, the NDK, Gradle and pub packages), and on
the host apksigner from the Android SDK build-tools.
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml

SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_ROOT = SCRIPT_DIR.parent
RECIPE = PROJECT_ROOT / "fdroid" / "io.lab517.noo.yml"
KEY_PROPERTIES = PROJECT_ROOT / "client" / "android" / "key.properties"
BUILD_DIR = PROJECT_ROOT / "build"
RELEASES_DIR = SCRIPT_DIR / "releases"

APP_ID = "io.lab517.noo"

# The build environment of fdroiddata's "fdroid build" CI job
# (.gitlab-ci.yml there). Move these together with it: a different
# fdroidserver or image is a different build, and the APKs stop matching.
IMAGE = "registry.gitlab.com/fdroid/fdroidserver:buildserver-trixie"
FDROIDSERVER_COMMIT = "a35fdfddd9c66823987a410566a6101186e39c84"
FDROIDSERVER_SHALLOW_SINCE = "2026-07-13"

# Gradle's download cache, kept between runs. It holds artifacts, not outputs,
# so reusing it does not change what is built.
GRADLE_CACHE = Path.home() / ".cache" / "noo-fdroid-gradle"

# Runs as root inside the container, mirroring the CI job's script.
INNER = r"""
set -euo pipefail
# Whatever happens, leave nothing on the host the caller cannot delete.
trap 'chown -R __UID__:__GID__ /work' EXIT
source /etc/profile.d/bsenv.sh
H=$home_vagrant
export ANDROID_HOME=/opt/android-sdk

apt-get update -qq
apt-get install -qq -y sudo git > /dev/null

git clone -q --shallow-since=__SINCE__ https://gitlab.com/fdroid/fdroidserver.git $fdroidserver
git -C $fdroidserver checkout -q __COMMIT__

mkdir -p $H/metadata $H/srclibs $H/build $H/tmp $H/unsigned $H/logs
cp /work/metadata/__APPID__.yml $H/metadata/
printf 'RepoType: git\nRepo: https://github.com/flutter/flutter.git\n' > $H/srclibs/flutter.yml
ln -s /work/gradle $H/.gradle
git config --system --add safe.directory '*'
chown -R vagrant $H /work/src.git /work/gradle

cd $H
fdroid="sudo --preserve-env --user vagrant env PATH=$fdroidserver:$PATH \
  PYTHONPATH=$fdroidserver:$fdroidserver/examples PYTHONUNBUFFERED=true \
  HOME=$H GRADLE_USER_HOME=$H/.gradle fdroid"
$fdroid fetchsrclibs __APPID__:__CODE__ --verbose
# --on-server uninstalls sudo when it is done, as on the real buildserver.
$fdroid build --verbose --test --refresh-scanner --on-server --no-tarball __APPID__:__CODE__

cp $H/tmp/__APPID_____CODE__.apk /work/out/unsigned.apk
"""


def run(cmd, **kw):
    print("+ " + " ".join(str(c) for c in cmd), flush=True)
    return subprocess.run(cmd, check=True, **kw)


def git(*args, cwd=PROJECT_ROOT) -> str:
    return subprocess.run(["git", "-C", str(cwd), *args], check=True,
                          capture_output=True, text=True).stdout.strip()


def versions_at(ref: str) -> tuple[str, int]:
    """versionName and versionCode as client/pubspec.yaml states them at [ref]."""
    pubspec = git("show", f"{ref}:client/pubspec.yaml")
    name = re.search(r"^version:\s*(\d+\.\d+\.\d+)\s*$", pubspec, re.M)
    code = re.search(r"^# fdroid-version-code: (\d+)$", pubspec, re.M)
    if not name or not code:
        sys.exit("error: client/pubspec.yaml needs 'version: X.Y.Z' and "
                 "'# fdroid-version-code: N'")
    major, minor, patch = map(int, name.group(1).split("."))
    if int(code.group(1)) != major * 10000 + minor * 100 + patch:
        sys.exit(f"error: fdroid-version-code {code.group(1)} does not match "
                 f"version {name.group(1)}")
    return name.group(1), int(code.group(1))


def export_tree(ref: str, repo: Path) -> str:
    """A one-commit repository holding [ref]'s tree; returns the commit id.

    One commit, like the snapshot publish_public.py pushes: F-Droid checks out
    the public tag, whose tree is master's -- only files that no build reads
    are withheld from it.
    """
    work = repo.parent / "src"
    work.mkdir()
    archive = subprocess.run(["git", "-C", str(PROJECT_ROOT), "archive", ref],
                             check=True, capture_output=True).stdout
    subprocess.run(["tar", "-x", "-C", str(work)], input=archive, check=True)
    env = {**os.environ, "GIT_AUTHOR_NAME": "noo", "GIT_AUTHOR_EMAIL": "noo@localhost",
           "GIT_COMMITTER_NAME": "noo", "GIT_COMMITTER_EMAIL": "noo@localhost"}
    for args in (["init", "-q", "-b", "main"], ["add", "-A"],
                 ["commit", "-q", "-m", f"noo {ref}"]):
        subprocess.run(["git", "-C", str(work), *args], check=True, env=env)
    run(["git", "clone", "-q", "--bare", str(work), str(repo)])
    shutil.rmtree(work)
    return git("rev-parse", "HEAD", cwd=repo)


def write_metadata(path: Path, version: str, code: int, commit: str) -> None:
    """The recipe, with its last build entry pointed at the exported commit."""
    recipe = yaml.safe_load(RECIPE.read_text())
    build = dict(recipe["Builds"][-1])
    build.update(versionName=version, versionCode=code, commit=commit)
    recipe.update(Repo="/work/src.git", Builds=[build],
                  CurrentVersion=version, CurrentVersionCode=code)
    # Verification is what F-Droid does after this build; here it is circular.
    for key in ("Binaries", "AllowedAPKSigningKeys"):
        recipe.pop(key, None)
    path.write_text(yaml.safe_dump(recipe, sort_keys=False, allow_unicode=True))


def build_in_container(work: Path, code: int) -> Path:
    GRADLE_CACHE.mkdir(parents=True, exist_ok=True)
    (work / "out").mkdir()
    script = (INNER.replace("__SINCE__", FDROIDSERVER_SHALLOW_SINCE)
              .replace("__COMMIT__", FDROIDSERVER_COMMIT)
              .replace("__APPID__", APP_ID).replace("__CODE__", str(code))
              .replace("__UID__", str(os.getuid())).replace("__GID__", str(os.getgid())))
    run(["docker", "run", "--rm",
         "-v", f"{work}:/work", "-v", f"{GRADLE_CACHE}:/work/gradle",
         IMAGE, "bash", "-c", script])
    unsigned = work / "out" / "unsigned.apk"
    if not unsigned.exists():
        sys.exit("error: the F-Droid build produced no APK")
    return unsigned


def apksigner() -> str:
    sdk = Path(os.environ.get("ANDROID_HOME") or Path.home() / "Android" / "Sdk")
    found = sorted((sdk / "build-tools").glob("*/apksigner"))
    if not found:
        sys.exit(f"error: no apksigner under {sdk}/build-tools")
    return str(found[-1])


def sign(unsigned: Path, signed: Path) -> None:
    """Sign as Gradle signs our release builds: APK Signature Scheme v2 only.

    --alignment-preserved: by default apksigner re-aligns every entry while
    signing, which moves them -- and F-Droid verifies by copying our signature
    onto *its* unsigned build, so the signed file must be that build plus a
    signature block and nothing else. The build is already aligned by Gradle.
    """
    if not KEY_PROPERTIES.exists():
        sys.exit(f"error: {KEY_PROPERTIES} not found (or use --no-sign)")
    props = dict(line.split("=", 1) for line in KEY_PROPERTIES.read_text().splitlines()
                 if "=" in line and not line.lstrip().startswith("#"))
    store = (KEY_PROPERTIES.parent / props["storeFile"].strip()).resolve()
    env = {**os.environ, "NOO_KS_PASS": props["storePassword"].strip(),
           "NOO_KEY_PASS": props["keyPassword"].strip()}
    tool = apksigner()
    run([tool, "sign", "--ks", str(store), "--ks-key-alias", props["keyAlias"].strip(),
         "--ks-pass", "env:NOO_KS_PASS", "--key-pass", "env:NOO_KEY_PASS",
         "--v1-signing-enabled", "false", "--v2-signing-enabled", "true",
         "--v3-signing-enabled", "false", "--v4-signing-enabled", "false",
         "--alignment-preserved", "true",
         "--out", str(signed), str(unsigned)], env=env)
    run([tool, "verify", "--print-certs", str(signed)])


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--ref", default="HEAD", help="commit or tag to build (default HEAD)")
    parser.add_argument("--no-sign", action="store_true", help="stop at the unsigned APK")
    parser.add_argument("--keep-work", action="store_true",
                        help="keep the temporary work directory")
    args = parser.parse_args()

    if git("status", "--porcelain") and args.ref == "HEAD":
        print("note: the working copy has uncommitted changes; they are not built")
    version, code = versions_at(args.ref)
    name = f"noo-{version}-android"
    print(f"Building {APP_ID} {version} ({code}) from {args.ref} in F-Droid's buildserver")

    work = Path(tempfile.mkdtemp(prefix="noo-fdroid-"))
    # mkdtemp makes it private to us; the build runs as the image's vagrant.
    work.chmod(0o755)
    try:
        commit = export_tree(args.ref, work / "src.git")
        (work / "metadata").mkdir()
        write_metadata(work / "metadata" / f"{APP_ID}.yml", version, code, commit)
        unsigned = build_in_container(work, code)

        BUILD_DIR.mkdir(parents=True, exist_ok=True)
        unsigned_out = BUILD_DIR / f"{name}-unsigned.apk"
        shutil.copy2(unsigned, unsigned_out)
        print(f"\n  {unsigned_out}")
        if args.no_sign:
            return
        signed = BUILD_DIR / f"{name}.apk"
        sign(unsigned_out, signed)
        RELEASES_DIR.mkdir(parents=True, exist_ok=True)
        shutil.copy2(signed, RELEASES_DIR / signed.name)
        print(f"\n  {signed}\n  {RELEASES_DIR / signed.name}")
    finally:
        if args.keep_work:
            print(f"  work directory kept: {work}")
        else:
            shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    main()
