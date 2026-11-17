#!/usr/bin/env python3
"""A playground of several real Noo clients on one machine.

Brings up N genuine client processes — not stubs, not a test harness driving
the sync classes directly — each with its own database, device id and window,
plus a local relay (`relay.py`). They discover each other over the LAN peer
protocol and talk to the relay, so both transports are exercised by the same
fleet. Each client also runs its MCP server, which is how the driver creates
and reads notes: that is the seam a test agent uses, so whatever works here
works for an agent (ToDo items 5-7).

    playground.py run                 # setup, start, run the scenarios, stop
    playground.py up                  # leave it running to poke at
    playground.py scenario            # run scenarios against a running fleet
    playground.py status
    playground.py down

Isolation is by environment, not by any change to the app: each client gets
its own HOME and XDG directories, so its SharedPreferences, its database and
its keyring are its own. The two things the app would otherwise ask a person
for are pre-seeded:

  * the database password — into a per-sandbox gnome-keyring, in the single
    JSON item flutter_secure_storage keeps on Linux, so startup opens the
    database without the password dialog;
  * the database itself — built by the app's own schema and migrations, via
    `test/playground/seed_playground_test.dart`;

All clients share one database password on purpose: the sync key is HKDF'd
from it, so a fleet that does not share it cannot decrypt each other's packets
(docs/P2P_SYNC.md §5.1).
"""

import argparse
import json
import os
import shutil
import signal
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CLIENT = REPO / "client"
APP_ID = "io.lab517.noo"
SECRET_LABEL = f"{APP_ID}/FlutterSecureStorage"
SECRET_ACCOUNT = f"{APP_ID}.secureStorage"

# The schema name the app actually writes and looks items up by — which is not
# SECRET_LABEL. flutter_secure_storage_linux 3.0.2 captures
# `the_schema.name = label.c_str()` while `label` is still the default
# "default" (short enough to live in the std::string's inline buffer), then
# setLabel() assigns the real 34-byte label. libstdc++ moves the characters to
# the heap and reuses that inline buffer to hold _M_allocated_capacity, so the
# schema name now reads those bytes: capacity (34) little-endian, i.e. the
# single byte 0x22 — '"'. Deterministic, not random, and derived from the
# label's length, so it is computable here. See README.md.
SECRET_SCHEMA = chr(len(SECRET_LABEL))

# One password for the whole fleet: the sync key is derived from it.
DB_PASSWORD = "playground-db-pw-1234"
RELAY_USER = "playground"
RELAY_PASSWORD = "playground-relay-pw"
KEYRING_PASSWORD = "playground-keyring"

DEFAULT_ROOT = Path("/tmp/noo-playground")
DEFAULT_DISPLAY = ":99"
DEFAULT_RELAY_PORT = 8080
FIRST_MCP_PORT = 47811
NAMES = ["alpha", "bravo", "charlie", "delta"]


# ------------------------------------------------------------------ utilities


def log(msg):
    print(msg, flush=True)


def port_free(port, host="127.0.0.1"):
    with socket.socket() as s:
        s.settimeout(0.3)
        return s.connect_ex((host, port)) != 0


def wait_for(predicate, timeout, interval=0.5, what="condition"):
    """Poll until true. Returns whether it became true in time."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            if predicate():
                return True
        except Exception:
            pass
        time.sleep(interval)
    return False


def sha256_hex(text):
    import hashlib

    return hashlib.sha256(text.encode()).hexdigest()


# -------------------------------------------------------------------- layout


class Client:
    def __init__(self, root, index, name, relay_port):
        self.index = index
        self.name = name
        self.device_id = f"playground-{name}"
        self.device_name = name.capitalize()
        self.dir = root / "clients" / name
        self.home = self.dir / "home"
        self.data_home = self.home / ".local" / "share"
        self.db = self.dir / "data" / f"{name}.noo"
        self.log = self.dir / "client.log"
        self.pidfile = self.dir / "client.pid"
        self.mcp_port = FIRST_MCP_PORT + index
        self.mcp_token = f"playground-token-{name}"
        self.relay_port = relay_port
        # Overridden in docker mode: from inside a container the relay is not
        # on loopback but on the bridge gateway.
        self.relay_host = "127.0.0.1"

    @property
    def prefs_file(self):
        return self.data_home / APP_ID / "shared_preferences.json"

    def prefs(self):
        """Exactly what the app would have written itself, had a person set it
        up through Preferences. Keys carry SharedPreferences' `flutter.`
        prefix; the password and MCP token are absent because those live in
        the keyring."""
        return {
            "flutter.last_database_path": str(self.db),
            # Without this the startup screen never consults the keyring and
            # stops on the password dialog, however well seeded the keyring is.
            "flutter.remember_password": True,
            "flutter.biometric_unlock": False,
            "flutter.sync_enabled": True,
            "flutter.sync_server_url": f"http://{self.relay_host}:{self.relay_port}",
            "flutter.sync_username": RELAY_USER,
            "flutter.sync_device_id": self.device_id,
            "flutter.sync_device_name": self.device_name,
            # Off. The scenarios press the app's own sync shortcuts, so the
            # fleet syncs when asked and not otherwise — a background sync
            # that fails (the relay is stopped on purpose in one scenario)
            # raises a modal the next keystroke would go to instead of the
            # app.
            "flutter.sync_auto_interval": 0,
            "flutter.sync_on_start": True,
            "flutter.sync_on_exit": False,
            "flutter.mcp_enabled": True,
            "flutter.mcp_port": self.mcp_port,
            "flutter.mcp_read_only": False,
            # A playground window should not restore a position from some
            # other run, and single-instance would stop the second client dead.
            "flutter.single_instance": False,
        }

    def secrets(self):
        """The one JSON item flutter_secure_storage keeps on Linux."""
        return {
            f"database_password:{sha256_hex(str(self.db))}": DB_PASSWORD,
            "sync_server_password": RELAY_PASSWORD,
            "mcp_token": self.mcp_token,
        }

    def env(self):
        return {
            "HOME": str(self.home),
            "XDG_DATA_HOME": str(self.data_home),
            "XDG_CONFIG_HOME": str(self.home / ".config"),
            "XDG_CACHE_HOME": str(self.home / ".cache"),
            "XDG_RUNTIME_DIR": str(self.home / "run"),
        }

    def pid(self):
        try:
            return int(self.pidfile.read_text().strip())
        except Exception:
            return None

    def running(self):
        pid = self.pid()
        if pid is None:
            return False
        try:
            os.kill(pid, 0)
            return True
        except OSError:
            return False


class Playground:
    def __init__(self, root, count, relay_port, display):
        self.root = Path(root)
        self.relay_port = relay_port
        self.display = display
        self.clients = [
            Client(self.root, i, NAMES[i], relay_port) for i in range(count)
        ]
        self.relay_db = self.root / "relay" / "relay.sqlite"
        self.relay_pidfile = self.root / "relay" / "relay.pid"
        self.relay_log = self.root / "relay" / "relay.log"
        self.xvfb_pidfile = self.root / "xvfb.pid"
        self.wm_pidfile = self.root / "wm.pid"
        # Containers reach the relay across the bridge, so docker mode widens
        # this; on the host loopback is enough and keeps it off the network.
        self.relay_bind = "127.0.0.1"

    # ------------------------------------------------------------------ setup

    def app_binary(self):
        release = CLIENT / "build/linux/x64/release/bundle/noo"
        debug = CLIENT / "build/linux/x64/debug/bundle/noo"
        for candidate in (release, debug):
            if candidate.exists():
                return candidate
        sys.exit(
            "No built client found. Run:\n"
            "  cd client && flutter build linux --release"
        )

    def setup(self, fresh=True):
        app = self.app_binary()
        if fresh and self.root.exists():
            shutil.rmtree(self.root)
        for c in self.clients:
            for d in (
                c.home,
                c.data_home / APP_ID,
                c.home / ".config",
                c.home / ".cache",
                c.home / "run",
                c.db.parent,
            ):
                d.mkdir(parents=True, exist_ok=True)
            os.chmod(c.home / "run", 0o700)
            c.prefs_file.write_text(json.dumps(c.prefs(), indent=2))
            (c.dir / "secrets.json").write_text(json.dumps(c.secrets()))
        self.relay_db.parent.mkdir(parents=True, exist_ok=True)

        self._seed_databases()
        self._write_launchers(app)
        log(f"playground ready in {self.root} ({len(self.clients)} clients)")

    def _seed_databases(self):
        """Build each database with the app's own schema."""
        spec = {
            "clients": [
                {
                    "db": str(c.db),
                    "password": DB_PASSWORD,
                    "deviceId": c.device_id,
                }
                for c in self.clients
            ]
        }
        spec_file = self.root / "seed-spec.json"
        spec_file.write_text(json.dumps(spec, indent=2))

        env = dict(os.environ, NOO_PLAYGROUND_SPEC=str(spec_file))
        result = subprocess.run(
            ["flutter", "test", "test/playground/seed_playground_test.dart"],
            cwd=CLIENT,
            env=env,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            sys.exit(
                "seeding the databases failed:\n"
                + result.stdout[-4000:]
                + result.stderr[-2000:]
            )
        log("databases seeded")

    def _write_launchers(self, app):
        """One script per client. The keyring has to be unlocked and seeded
        inside the same D-Bus session the app will use, so it is done here
        rather than from Python."""
        for c in self.clients:
            inner = c.dir / "inner.sh"
            inner.write_text(
                f"""#!/bin/bash
set -u
# A fresh sandbox has no login keyring; --unlock creates and opens one, and
# prints the environment the rest of the session needs.
eval "$(printf '%s' '{KEYRING_PASSWORD}' \\
  | gnome-keyring-daemon --unlock --components=secrets 2>/dev/null)"
export GNOME_KEYRING_CONTROL

# The secret service takes a moment to own its bus name after starting.
for _ in $(seq 1 40); do
  if secret-tool store --label='{SECRET_LABEL}' \\
       'xdg:schema' '{SECRET_SCHEMA}' \\
       account '{SECRET_ACCOUNT}' < '{c.dir / "secrets.json"}' 2>/dev/null; then
    break
  fi
  sleep 0.25
done

exec '{app}' >> '{c.log}' 2>&1
"""
            )
            inner.chmod(0o755)

            launcher = c.dir / "launch.sh"
            exports = "\n".join(
                f"export {k}='{v}'" for k, v in sorted(c.env().items())
            )
            launcher.write_text(
                f"""#!/bin/bash
set -u
{exports}
export DISPLAY='{self.display}'
exec dbus-run-session -- bash '{inner}'
"""
            )
            launcher.chmod(0o755)

    # ------------------------------------------------------------------- start

    def start_xvfb(self):
        if self._alive(self.xvfb_pidfile):
            return
        proc = subprocess.Popen(
            ["Xvfb", self.display, "-screen", "0", "1400x900x24", "-nolisten", "tcp"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        self.xvfb_pidfile.write_text(str(proc.pid))
        time.sleep(1.0)
        log(f"Xvfb on {self.display}")

    def start_relay(self):
        if self._alive(self.relay_pidfile):
            log("relay already running")
            return
        if not port_free(self.relay_port):
            sys.exit(f"port {self.relay_port} is busy; is another relay running?")
        self.relay_log.parent.mkdir(parents=True, exist_ok=True)
        handle = open(self.relay_log, "ab")
        proc = subprocess.Popen(
            [
                sys.executable,
                str(Path(__file__).parent / "relay.py"),
                "serve",
                "--db",
                str(self.relay_db),
                "--port",
                str(self.relay_port),
                "--host",
                self.relay_bind,
                "--verbose",
            ],
            stdout=handle,
            stderr=handle,
        )
        self.relay_pidfile.write_text(str(proc.pid))
        ok = wait_for(
            lambda: self._relay_health(), timeout=15, what="relay"
        )
        if not ok:
            sys.exit(f"relay did not come up; see {self.relay_log}")
        self._register_account()
        log(f"relay on http://127.0.0.1:{self.relay_port}")

    def _register_account(self):
        """The clients only ever log in; nothing in the app creates the
        account, so the playground does it once for the whole fleet."""
        request = urllib.request.Request(
            f"http://127.0.0.1:{self.relay_port}/api/v2/auth/register/",
            data=json.dumps(
                {"username": RELAY_USER, "password": RELAY_PASSWORD}
            ).encode(),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=5) as response:
                log(f"relay account '{RELAY_USER}': {response.status}")
        except urllib.error.HTTPError as e:
            log(f"relay account '{RELAY_USER}': {e.code}")

    def _relay_health(self):
        with urllib.request.urlopen(
            f"http://127.0.0.1:{self.relay_port}/health", timeout=2
        ) as r:
            return r.status == 200

    def stop_relay(self):
        self._kill(self.relay_pidfile, "relay")

    def start_clients(self):
        for c in self.clients:
            if c.running():
                log(f"{c.name}: already running")
                continue
            proc = subprocess.Popen(
                ["bash", str(c.dir / "launch.sh")],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
            c.pidfile.write_text(str(proc.pid))
            log(f"{c.name}: started (pid {proc.pid}, mcp {c.mcp_port})")

        # Not fatal: on a fresh sandbox the MCP token is not in the keyring
        # yet, so MCP stays down until bootstrap() has run.
        for c in self.clients:
            if wait_for(lambda c=c: Mcp(c).ping(), timeout=90, interval=1.0):
                log(f"{c.name}: MCP ready")
            else:
                log(f"{c.name}: MCP not up yet on {c.mcp_port}")

    def all_mcp_ready(self):
        return all(Mcp(c).ping() for c in self.clients)

    def start_wm(self):
        """xdotool's windowactivate needs a window manager, and without one
        every client window lands stacked at the same spot."""
        if self._alive(self.wm_pidfile):
            return
        proc = subprocess.Popen(
            ["openbox", "--sm-disable"],
            env=dict(os.environ, DISPLAY=self.display),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        self.wm_pidfile.write_text(str(proc.pid))
        time.sleep(1.5)
        log("openbox started")

    def bring_up(self):
        self.start_xvfb()
        self.start_wm()
        self.start_relay()
        self.start_clients()
        if not self.all_mcp_ready():
            log("\nbootstrapping (first run on this sandbox)")
            self.bootstrap()
        return self.all_mcp_ready()

    def stop_clients(self):
        for c in self.clients:
            self._kill(c.pidfile, c.name, group=True)

    def down(self):
        self.stop_clients()
        self.stop_relay()
        self._kill(self.wm_pidfile, "openbox")
        self._kill(self.xvfb_pidfile, "Xvfb")

    def _alive(self, pidfile):
        try:
            pid = int(Path(pidfile).read_text().strip())
            os.kill(pid, 0)
            return True
        except Exception:
            return False

    def _kill(self, pidfile, label, group=False):
        pidfile = Path(pidfile)
        if not self._alive(pidfile):
            pidfile.unlink(missing_ok=True)
            return
        pid = int(pidfile.read_text().strip())
        try:
            os.killpg(os.getpgid(pid), signal.SIGTERM) if group else os.kill(
                pid, signal.SIGTERM
            )
        except OSError:
            pass
        for _ in range(40):
            if not self._alive(pidfile):
                break
            time.sleep(0.25)
        else:
            try:
                os.killpg(os.getpgid(pid), signal.SIGKILL) if group else os.kill(
                    pid, signal.SIGKILL
                )
            except OSError:
                pass
        pidfile.unlink(missing_ok=True)
        log(f"{label}: stopped")

    # --------------------------------------------------------------- bootstrap

    # flutter_secure_storage_linux 3.0.2 captures `the_schema.name` from a
    # std::string that setLabel() then reassigns, so every keyring item the app
    # writes carries a garbage `xdg:schema` attribute instead of
    # "<app id>/FlutterSecureStorage" (see README.md). It is stable enough that
    # the app reads back its own writes, but an item seeded with the *correct*
    # schema is invisible to it — so the app has to write the first item
    # itself, and everything else we need goes into that same item afterwards.

    def bootstrap(self):
        """Type each database password once, then add the MCP token to the
        item the app just wrote. Only needed on a fresh sandbox."""
        self._type_passwords()
        merged = False
        for c in self.clients:
            merged |= self._merge_secrets(c)
        if merged:
            log("bootstrap: restarting clients so they pick up the MCP token")
            self.stop_clients()
            self.start_clients()

    def _type_passwords(self):
        for c in self.clients:
            if self._password_saved(c):
                log(f"{c.name}: password already saved")
                continue
            window = self._window_for(c)
            if window is None:
                log(f"{c.name}: no window to type into")
                continue
            self._xdo(["windowactivate", "--sync", window])
            time.sleep(1.0)
            self._xdo(["type", "--delay", "40", DB_PASSWORD])
            time.sleep(0.5)
            self._xdo(["key", "Return"])
            if wait_for(lambda c=c: self._password_saved(c), timeout=40, interval=1):
                log(f"{c.name}: database unlocked, password saved")
            else:
                log(f"{c.name}: password did not take")

    def press_sync(self, c, nearby=False):
        """Press the client's own sync command — F5 for the relay, File →
        Sync P2P... for nearby devices. LAN sync has no timer behind it: it
        happens because someone asks for it, so the playground asks the same
        way a person would.

        A relay sync's report is dismissed straight away. Sync P2P is left
        open: its peer server and discovery only live while the dialog does,
        so every client has to have it open at once — call `close_dialogs`
        once the exchange has landed."""
        window = self._window_for(c)
        if window is None:
            return False
        self._xdo(["windowactivate", "--sync", window])
        time.sleep(0.6)
        if nearby:
            # Shift+F5 is the documented shortcut, but the modifier does not
            # survive xdotool here and the app sees a bare F5 — a *relay*
            # sync. The menu item is unambiguous: "Sync P2P..." is always the
            # sixth entry of the File menu ("Sync Details..." appears after
            # it, so the offset does not move).
            self._xdo(["mousemove", "79", "105", "click", "1"])
            time.sleep(1.2)
            self._xdo(["mousemove", "160", "356", "click", "1"])
            return True
        self._xdo(["key", "F5"])
        time.sleep(3.0)
        self._dismiss()
        return True

    def close_dialogs(self, c):
        """Close whatever modal the client has open — for Sync P2P, that ends
        its session."""
        window = self._window_for(c)
        if window is None:
            return False
        self._xdo(["windowactivate", "--sync", window])
        time.sleep(0.6)
        self._dismiss()
        return True

    def _dismiss(self):
        # A failed sync has Retry/Close buttons that Escape does not reach.
        # Left open a dialog swallows the next keystroke, so it is clicked
        # away — dialogs are centred and the rightmost button sits here on
        # this screen size.
        for _ in range(3):
            self._xdo(["mousemove", "975", "610", "click", "1"])
            time.sleep(0.4)
            self._xdo(["key", "Escape"])
            time.sleep(0.2)

    def _xdo(self, args):
        subprocess.run(
            ["xdotool"] + args,
            env=dict(os.environ, DISPLAY=self.display),
            capture_output=True,
            check=False,
        )

    def _window_for(self, c):
        result = subprocess.run(
            ["xdotool", "search", "--name", f"{c.name}.noo"],
            env=dict(os.environ, DISPLAY=self.display),
            capture_output=True,
            text=True,
        )
        ids = [line for line in result.stdout.split() if line.strip()]
        return ids[0] if ids else None

    def _bus_of(self, c):
        """The D-Bus address of the session this client runs in, read out of
        its own process environment."""
        for entry in Path("/proc").glob("[0-9]*"):
            try:
                raw = (entry / "environ").read_bytes().decode("utf-8", "replace")
            except Exception:
                continue
            # Matching on the sandbox path alone: the app's environment does
            # not necessarily carry the binary path, only its HOME.
            if str(c.dir) not in raw:
                continue
            for var in raw.split("\0"):
                if not var.startswith("DBUS_SESSION_BUS_ADDRESS="):
                    continue
                address = var.split("=", 1)[1]
                # dbus-run-session puts its bus in /tmp; anything else is the
                # host's own session bus, which some unrelated process
                # mentioning this path (a shell, the launcher) would hand us.
                if "/tmp/dbus-" in address:
                    return address
        return None

    def _secret_env(self, c):
        bus = self._bus_of(c)
        return None if bus is None else dict(os.environ, DBUS_SESSION_BUS_ADDRESS=bus)

    def _items(self, c):
        """Every secure-storage item in this client's keyring, as
        (schema, secret)."""
        env = self._secret_env(c)
        if env is None:
            return []
        result = subprocess.run(
            ["secret-tool", "search", "--all", "account", SECRET_ACCOUNT],
            env=env,
            capture_output=True,
            text=True,
        )
        items, schema, secret = [], None, None
        for line in result.stdout.splitlines():
            line = line.strip()
            if line.startswith("[") and schema is not None:
                items.append((schema, secret))
                schema, secret = None, None
            elif line.startswith("schema = "):
                schema = line[len("schema = "):]
            elif line.startswith("secret = "):
                secret = line[len("secret = "):]
        if schema is not None:
            items.append((schema, secret))
        return items

    def _app_item(self, c):
        """The item the app itself wrote — the one holding the password."""
        for schema, secret in self._items(c):
            if secret and "database_password" in secret and schema != SECRET_LABEL:
                return schema, secret
        return None, None

    def _password_saved(self, c):
        return self._app_item(c)[0] is not None

    def _merge_secrets(self, c):
        """Add the MCP token and relay password to the app's own item, under
        the app's own schema, so the app can actually read them."""
        schema, secret = self._app_item(c)
        if schema is None:
            log(f"{c.name}: no app-written keyring item to merge into")
            return False
        try:
            data = json.loads(secret)
        except Exception:
            log(f"{c.name}: keyring item is not JSON, leaving it alone")
            return False
        if data.get("mcp_token") == c.mcp_token:
            return False
        data.update(c.secrets())
        subprocess.run(
            [
                "secret-tool", "store", "--label", SECRET_LABEL,
                "xdg:schema", schema, "account", SECRET_ACCOUNT,
            ],
            env=self._secret_env(c),
            input=json.dumps(data),
            text=True,
            capture_output=True,
            check=False,
        )
        log(f"{c.name}: MCP token added to the keyring")
        return True

    # ------------------------------------------------------------------ status

    def status(self):
        log(f"root      {self.root}")
        log(
            "relay     %s  (%s)"
            % (
                "running" if self._alive(self.relay_pidfile) else "stopped",
                f"http://127.0.0.1:{self.relay_port}",
            )
        )
        log("Xvfb      %s  %s" % (
            "running" if self._alive(self.xvfb_pidfile) else "stopped", self.display))
        for c in self.clients:
            mcp = "up" if Mcp(c).ping() else "down"
            log(
                "%-9s %-8s device=%-20s mcp=%-6s(%s) db=%s"
                % (
                    c.name,
                    "running" if c.running() else "stopped",
                    c.device_id,
                    c.mcp_port,
                    mcp,
                    c.db,
                )
            )


# ---------------------------------------------------------------- MCP client


class Mcp:
    """The client's own MCP server — the seam a test agent drives it through."""

    def __init__(self, client):
        self.client = client
        self.url = f"http://127.0.0.1:{client.mcp_port}/mcp"
        self._id = 0

    def _call(self, method, params=None, timeout=10):
        self._id += 1
        payload = {"jsonrpc": "2.0", "id": self._id, "method": method}
        if params is not None:
            payload["params"] = params
        request = urllib.request.Request(
            self.url,
            data=json.dumps(payload).encode(),
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.client.mcp_token}",
            },
            method="POST",
        )
        with urllib.request.urlopen(request, timeout=timeout) as response:
            body = json.loads(response.read().decode())
        if "error" in body:
            raise RuntimeError(f"{self.client.name}: MCP error {body['error']}")
        return body.get("result")

    def ping(self):
        try:
            self._call(
                "initialize",
                {
                    "protocolVersion": "2025-06-18",
                    "capabilities": {},
                    "clientInfo": {"name": "playground", "version": "1"},
                },
                timeout=3,
            )
            return True
        except Exception:
            return False

    def tool(self, name, arguments):
        result = self._call("tools/call", {"name": name, "arguments": arguments})
        if result.get("isError"):
            raise RuntimeError(
                f"{self.client.name}: tool {name} failed: {result.get('content')}"
            )
        text = "".join(
            part.get("text", "")
            for part in result.get("content", [])
            if part.get("type") == "text"
        )
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            return text

    def create_task(self, title, content=None):
        args = {"title": title}
        if content is not None:
            args["content"] = content
        return self.tool("noo_create_task", args)

    def update_task(self, world_id, **fields):
        return self.tool("noo_update_task", {"id": world_id, **fields})

    def search(self, query, limit=20):
        """Matching tasks as [{id, title, ...}]; ids are worldIds."""
        return self.tool(
            "noo_search_tasks", {"query": query, "limit": limit}
        ).get("results", [])

    def titles(self):
        """Every title in the outline, at any depth."""
        tree = self.tool("noo_get_tree", {"depth": 8}).get("tree", [])
        out = []

        def walk(nodes):
            for node in nodes:
                out.append(node.get("title", ""))
                walk(node.get("children") or [])

        walk(tree)
        return sorted(out)

    def has_title(self, title):
        return title in self.titles()


# ------------------------------------------------------------------ scenarios


class ScenarioFailure(Exception):
    pass


def scenarios(pg, sync_timeout, mcp_factory=None):
    """Exercise both transports and report what actually happened."""
    results = []

    def record(name, ok, detail=""):
        results.append((name, ok, detail))
        log(("  PASS  " if ok else "  FAIL  ") + name + (f" — {detail}" if detail else ""))

    clients = pg.clients
    make = mcp_factory or Mcp
    mcps = {c.name: make(c) for c in clients}
    stamp = time.strftime("%H%M%S")

    def converge(targets, predicate, nearby=False, rounds=3):
        """Ask each client to sync the way a person would, then wait. Repeated
        a few times because one exchange only moves what the other side had
        when it was asked."""
        for _ in range(rounds):
            for c in clients:
                pg.press_sync(c, nearby=nearby)
                time.sleep(1.0)
            # Sync P2P stays open on every client until the data has moved:
            # a device is only discoverable while its dialog is showing.
            arrived = wait_for(predicate, timeout=sync_timeout // rounds, interval=2)
            if nearby:
                for c in clients:
                    pg.close_dialogs(c)
            if arrived:
                return True
        return predicate()

    log("\nscenario 1 — a note created on one client reaches the others via the relay")
    title = f"relay note {stamp}"
    mcps[clients[0].name].create_task(title)
    others = clients[1:]
    ok = converge(
        others, lambda: all(mcps[c.name].has_title(title) for c in others)
    )
    missing = [c.name for c in others if not mcps[c.name].has_title(title)]
    record(
        "relay: %s -> %s" % (clients[0].name, ", ".join(c.name for c in others)),
        ok,
        "" if ok else f"never arrived on {', '.join(missing)}",
    )

    log("\nscenario 2 — an edit on a second client converges back")
    edit_title = f"edited on {clients[1].name} {stamp}"
    items = mcps[clients[1].name].search(title, limit=5)
    if not items:
        record("relay: edit converges", False, "the note was not there to edit")
    else:
        mcps[clients[1].name].update_task(items[0]["id"], title=edit_title)
        ok = converge(
            [clients[0]], lambda: mcps[clients[0].name].has_title(edit_title)
        )
        record(f"relay: {clients[1].name} edit -> {clients[0].name}", ok)

    log("\nscenario 3 — with the relay stopped, a note still travels over the LAN")
    pg.stop_relay()
    time.sleep(2)
    p2p_title = f"p2p note {stamp}"
    mcps[clients[-1].name].create_task(p2p_title)
    peers = clients[:-1]
    ok = converge(
        peers,
        lambda: any(mcps[c.name].has_title(p2p_title) for c in peers),
        nearby=True,
    )
    reached = [c.name for c in peers if mcps[c.name].has_title(p2p_title)]
    record(
        "p2p: %s -> %s (relay down)"
        % (clients[-1].name, ", ".join(c.name for c in peers)),
        ok,
        f"reached {reached}"
        if ok
        else "no peer received it — peer discovery broadcasts to "
        "255.255.255.255, which this host does not deliver back to its own "
        "sockets, so co-located clients never see each other (README.md)",
    )

    log("\nscenario 4 — the relay catches up on what it missed once it is back")
    pg.start_relay()
    ok = converge(clients, lambda: relay_holds_all(pg))
    record("relay: accepts the streams it missed", ok)

    log("\nscenario 5 — the note that travelled over the LAN reaches the relay too")
    ok = converge(clients, lambda: all(
        mcps[c.name].has_title(p2p_title) for c in clients))
    have = [c.name for c in clients if mcps[c.name].has_title(p2p_title)]
    record("p2p note reaches the whole fleet", ok, f"held by {have}")

    log("")
    passed = sum(1 for _, ok, _ in results if ok)
    log(f"{passed}/{len(results)} scenarios passed")
    return passed == len(results)


def relay_holds_all(pg):
    """Every client's own stream has reached the relay."""
    token = relay_token(pg)
    if token is None:
        return False
    request = urllib.request.Request(
        f"http://127.0.0.1:{pg.relay_port}/api/v2/changes/vector",
        headers={"Authorization": f"Bearer {token}"},
    )
    with urllib.request.urlopen(request, timeout=5) as response:
        vectors = json.loads(response.read().decode())["vectors"]
    return all(vectors.get(c.device_id, 0) > 0 for c in pg.clients)


def relay_token(pg):
    try:
        request = urllib.request.Request(
            f"http://127.0.0.1:{pg.relay_port}/api/v2/auth/login/",
            data=json.dumps(
                {"username": RELAY_USER, "password": RELAY_PASSWORD}
            ).encode(),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(request, timeout=5) as response:
            return json.loads(response.read().decode())["access_token"]
    except Exception:
        return None


# ---------------------------------------------------------------------- main


def build(args):
    return Playground(args.dir, args.clients, args.relay_port, args.display)


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--dir", default=str(DEFAULT_ROOT))
    parser.add_argument("--clients", type=int, default=3, choices=[2, 3, 4])
    parser.add_argument("--relay-port", type=int, default=DEFAULT_RELAY_PORT)
    parser.add_argument("--display", default=DEFAULT_DISPLAY)
    parser.add_argument(
        "--sync-timeout",
        type=int,
        default=180,
        help="how long a scenario waits for convergence (the app's smallest "
        "auto-sync cadence is one minute)",
    )
    sub = parser.add_subparsers(dest="cmd", required=True)
    for name in ("setup", "up", "down", "status", "scenario", "run", "bootstrap"):
        sub.add_parser(name)

    args = parser.parse_args()
    pg = build(args)

    if args.cmd == "setup":
        pg.setup()
    elif args.cmd == "up":
        pg.setup(fresh=not (pg.root / "seed-spec.json").exists())
        pg.bring_up()
        pg.status()
    elif args.cmd == "down":
        pg.down()
    elif args.cmd == "bootstrap":
        pg.bootstrap()
        pg.status()
    elif args.cmd == "status":
        pg.status()
    elif args.cmd == "scenario":
        sys.exit(0 if scenarios(pg, args.sync_timeout) else 1)
    elif args.cmd == "run":
        pg.setup()
        if not pg.bring_up():
            pg.status()
            pg.down()
            sys.exit("not every client came up; see the logs under " + str(pg.root))
        pg.status()
        try:
            ok = scenarios(pg, args.sync_timeout)
        finally:
            pg.down()
        sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
