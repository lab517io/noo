# One playground client: the real Linux build, its own X server, D-Bus session
# and keyring, in its own network namespace.
#
# The namespace is the point. Peer discovery broadcasts to 255.255.255.255, and
# Linux does not deliver that to other sockets on the sending host — so clients
# sharing a host never see each other however long they probe. Containers on a
# user-defined bridge are a real L2 segment, and the broadcast arrives.
#
# The app bundle is mounted rather than copied, so a rebuild does not mean an
# image rebuild.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      libgtk-3-0 libglib2.0-0 libstdc++6 libgcc-s1 \
      libegl1 libgl1 libglu1-mesa libepoxy0 \
      libsecret-1-0 libjsoncpp25 libayatana-appindicator3-1 \
      libasound2t64 libpulse0 \
      libgstreamer1.0-0 libgstreamer-plugins-base1.0-0 \
      gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
      xvfb x11-utils openbox xdotool \
      dbus-x11 gnome-keyring libsecret-tools \
      python3 procps ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
