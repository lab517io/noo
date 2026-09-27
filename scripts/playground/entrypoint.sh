#!/bin/bash
# Start one playground client inside its container: an X server for it to draw
# on, a window manager so xdotool can focus windows, and a D-Bus session with
# an unlocked keyring holding its secrets — then the app itself.
#
# Expects, from the environment:
#   NOO_APP            path to the built bundle's `noo` binary (mounted)
#   NOO_HOME           this client's HOME (mounted; holds prefs and keyring)
#   NOO_SECRETS        path to the JSON blob to put in the keyring
#   NOO_SECRET_LABEL   keyring item label
#   NOO_SECRET_SCHEMA  the xdg:schema the app really looks items up by
#   NOO_SECRET_ACCOUNT keyring item `account` attribute
#   NOO_KEYRING_PW     password for the sandbox keyring
set -u

export HOME="$NOO_HOME"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_RUNTIME_DIR="$HOME/run"
export DISPLAY=":0"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null || true

Xvfb :0 -screen 0 1400x900x24 -nolisten tcp >/dev/null 2>&1 &
for _ in $(seq 1 50); do
  xdpyinfo >/dev/null 2>&1 && break
  sleep 0.2
done

openbox --sm-disable >/dev/null 2>&1 &
sleep 1

exec dbus-run-session -- bash -c '
set -u
# A fresh sandbox has no login keyring; --unlock creates and opens one.
eval "$(printf "%s" "$NOO_KEYRING_PW" \
  | gnome-keyring-daemon --unlock --components=secrets 2>/dev/null)"
export GNOME_KEYRING_CONTROL

# The secret service takes a moment to own its bus name after starting.
for _ in $(seq 1 40); do
  if secret-tool store --label="$NOO_SECRET_LABEL" \
       "xdg:schema" "$NOO_SECRET_SCHEMA" \
       account "$NOO_SECRET_ACCOUNT" < "$NOO_SECRETS" 2>/dev/null; then
    break
  fi
  sleep 0.25
done

exec "$NOO_APP"
'
