# The AppImage's build machine: the oldest Ubuntu LTS still in standard
# support. An AppImage runs on the glibc it was linked against *or newer*, so
# building here is what lets one file start on Ubuntu 22.04, Debian 12 and
# RHEL 9 as well as on current releases — and AppImageHub tests on exactly
# this release. Move it on (to 24.04) only when 22.04 leaves standard support.
#
# Flutter, the pub cache and the source tree are not in the image: build_linux.py
# --container mounts the host's, at the host's paths, so the container builds
# with the same Flutter the developer uses and nothing is downloaded twice.
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git unzip xz-utils file binutils python3 \
        clang cmake ninja-build pkg-config libstdc++-12-dev \
        libgtk-3-dev liblzma-dev libsecret-1-dev libjsoncpp-dev \
        libasound2-dev libpulse-dev \
        libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
        gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
        gstreamer1.0-alsa gstreamer1.0-pulseaudio \
        desktop-file-utils appstream \
    && rm -rf /var/lib/apt/lists/*

# The build runs as the caller's uid, which has no entry here; git refuses
# repositories owned by "someone else" without this.
RUN git config --system --add safe.directory '*'
