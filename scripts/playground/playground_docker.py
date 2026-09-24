#!/usr/bin/env python3
"""The playground, with each client in its own container.

Same fleet as `playground.py`, same relay, same scenarios — the difference is
that every client gets its own network namespace, joined to one user-defined
bridge. That is what makes LAN sync testable: peer discovery broadcasts to
255.255.255.255, which Linux never delivers to another socket on the *sending*
host, so co-located clients cannot find each other however long they probe. On
a bridge the broadcast is flooded to the other ports and arrives.

    playground_docker.py run      # build if needed, start, run scenarios, stop
    playground_docker.py up
    playground_docker.py scenario
    playground_docker.py status
    playground_docker.py down

Everything else is deliberately shared with the host-mode script: the sandbox
layout, the seeding, the relay and the scenarios all come from playground.py,
so the two modes cannot drift apart.
"""

import argparse
import importlib.util
import json
import os
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location("pg_host", HERE / "playground.py")
pg_host = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(pg_host)

Client = pg_host.Client
Playground = pg_host.Playground
Mcp = pg_host.Mcp
log = pg_host.log
wait_for = pg_host.wait_for
scenarios = pg_host.scenarios

IMAGE = "noo-playground:latest"
NETWORK = "noo-playground"
CONTAINER_PREFIX = "noopg-"
RELAY_CONTAINER = "noopg-relay"


def docker(*args, check=False, capture=True):
    return subprocess.run(
        ["sudo", "docker", *args],
        capture_output=capture,
        text=True,
        check=check,
    )


class DockerMcp(Mcp):
    """The app binds its MCP server to loopback, which inside a container is
    the container's own loopback — unreachable from here even with a published
    port. So the request is made from inside, where 127.0.0.1 means what the
    app meant."""

    def __init__(self, client):
        super().__init__(client)
        self.container = CONTAINER_PREFIX + client.name

    def _call(self, method, params=None, timeout=10):
        self._id += 1
        payload = {"jsonrpc": "2.0", "id": self._id, "method": method}
        if params is not None:
            payload["params"] = params
        script = (
            "import json,sys,urllib.request\n"
            f"p={json.dumps(payload)}\n"
            "r=urllib.request.Request("
            f"'http://127.0.0.1:{self.client.mcp_port}/mcp',"
            "data=json.dumps(p).encode(),"
            "headers={'Content-Type':'application/json',"
            f"'Authorization':'Bearer {self.client.mcp_token}'}},"
            "method='POST')\n"
            f"sys.stdout.write(urllib.request.urlopen(r,timeout={timeout})"
            ".read().decode())\n"
        )
        result = docker("exec", self.container, "python3", "-c", script)
        if result.returncode != 0 or not result.stdout.strip():
            raise RuntimeError(
                f"{self.client.name}: MCP call failed: "
                f"{result.stderr.strip()[:200]}"
            )
        body = json.loads(result.stdout)
        if "error" in body:
            raise RuntimeError(f"{self.client.name}: MCP error {body['error']}")
        return body.get("result")


class DockerPlayground(Playground):
    """A Playground whose clients are containers. Only the bits that touch the
    process — starting, stopping, pressing keys, reaching MCP — differ."""

    def __init__(self, root, count, relay_port, display, image=IMAGE):
        super().__init__(root, count, relay_port, display)
        self.image = image
        self.gateway = None

    # ------------------------------------------------------------------ image

    def ensure_image(self):
        found = docker("image", "inspect", self.image)
        if found.returncode == 0:
            return
        log(f"building {self.image} (first run)")
        build = docker(
            "build", "-t", self.image, str(HERE), capture=False
        )
        if build.returncode != 0:
            sys.exit("image build failed")

    def ensure_network(self):
        found = docker("network", "inspect", NETWORK, "--format", "{{json .IPAM.Config}}")
        if found.returncode != 0:
            created = docker("network", "create", NETWORK)
            if created.returncode != 0:
                sys.exit(f"could not create network: {created.stderr.strip()}")
            found = docker(
                "network", "inspect", NETWORK, "--format", "{{json .IPAM.Config}}"
            )
        config = json.loads(found.stdout.strip() or "[]")
        self.gateway = config[0]["Gateway"] if config else None
        if not self.gateway:
            sys.exit("could not determine the bridge gateway address")
        log(f"network {NETWORK}, gateway {self.gateway}")

    # ------------------------------------------------------------------ setup

    def setup(self, fresh=True):
        # The relay runs on the host; from inside a container it is reachable
        # at the bridge gateway, so the address has to be known before the
        # per-client preferences are written.
        self.ensure_network()
        for c in self.clients:
            # By container name: Docker's embedded DNS resolves it on this
            # network. Reaching the host across the bridge instead would put
            # the fleet at the mercy of the host's firewall, which on this
            # machine drops it.
            c.relay_host = RELAY_CONTAINER
        super().setup(fresh=fresh)

    # ------------------------------------------------------------------ relay

    def start_relay(self):
        """The relay is a container on the same network, with its port also
        published to the host so `inspect` and the scenarios can reach it."""
        state = docker(
            "inspect", RELAY_CONTAINER, "--format", "{{.State.Status}}"
        )
        if state.returncode == 0:
            if state.stdout.strip() != "running":
                docker("start", RELAY_CONTAINER)
        else:
            self.relay_db.parent.mkdir(parents=True, exist_ok=True)
            run = docker(
                "run", "-d",
                "--name", RELAY_CONTAINER,
                "--network", NETWORK,
                "--user", f"{os.getuid()}:{os.getgid()}",
                "-v", "/etc/passwd:/etc/passwd:ro",
                "-p", f"127.0.0.1:{self.relay_port}:{self.relay_port}",
                "-v", f"{HERE}:{HERE}:ro",
                "-v", f"{self.relay_db.parent}:{self.relay_db.parent}",
                "--entrypoint", "python3",
                self.image,
                str(HERE / "relay.py"), "serve",
                "--db", str(self.relay_db),
                "--host", "0.0.0.0",
                "--port", str(self.relay_port),
                "--verbose",
            )
            if run.returncode != 0:
                sys.exit(f"relay container failed: {run.stderr.strip()}")
        if not wait_for(self._relay_health, timeout=30, interval=1):
            sys.exit(f"relay did not answer; sudo docker logs {RELAY_CONTAINER}")
        self._register_account()
        log(f"relay container on http://127.0.0.1:{self.relay_port}")

    def stop_relay(self):
        docker("stop", RELAY_CONTAINER)
        log("relay: stopped")

    # --------------------------------------------------------------- clients

    def container_of(self, c):
        return CONTAINER_PREFIX + c.name

    def _container_state(self, c):
        result = docker(
            "inspect", self.container_of(c), "--format", "{{.State.Status}}"
        )
        return result.stdout.strip() if result.returncode == 0 else None

    def start_clients(self):
        app = self.app_binary()
        bundle = app.parent
        for c in self.clients:
            name = self.container_of(c)
            if self._container_state(c) == "running":
                log(f"{c.name}: already running")
                continue
            docker("rm", "-f", name)
            run = docker(
                "run",
                "-d",
                "--name", name,
                "--hostname", c.name,
                "--network", NETWORK,
                "--user", f"{os.getuid()}:{os.getgid()}",
                # Without a passwd entry for the mapped uid, dbus-daemon
                # cannot resolve the user and drops every connection — which
                # libsecret reports as "the connection is closed" and the app
                # sees as a keyring that will not answer.
                "-v", "/etc/passwd:/etc/passwd:ro",
                "-v", "/etc/group:/etc/group:ro",
                # Same paths inside as out, so the seeded preferences (which
                # name the database by absolute path) mean the same thing.
                "-v", f"{c.dir}:{c.dir}",
                "-v", f"{bundle}:{bundle}:ro",
                "-e", f"NOO_APP={app}",
                "-e", f"NOO_HOME={c.home}",
                "-e", f"NOO_SECRETS={c.dir / 'secrets.json'}",
                "-e", f"NOO_SECRET_LABEL={pg_host.SECRET_LABEL}",
                "-e", f"NOO_SECRET_SCHEMA={pg_host.SECRET_SCHEMA}",
                "-e", f"NOO_SECRET_ACCOUNT={pg_host.SECRET_ACCOUNT}",
                "-e", f"NOO_KEYRING_PW={pg_host.KEYRING_PASSWORD}",
                self.image,
            )
            if run.returncode != 0:
                sys.exit(f"{c.name}: docker run failed: {run.stderr.strip()}")
            log(f"{c.name}: container {name} started (mcp {c.mcp_port})")

        for c in self.clients:
            if wait_for(lambda c=c: DockerMcp(c).ping(), timeout=120, interval=2):
                log(f"{c.name}: MCP ready")
            else:
                log(f"{c.name}: MCP not up yet — {self.logs_hint(c)}")

    def all_mcp_ready(self):
        return all(DockerMcp(c).ping() for c in self.clients)

    def logs_hint(self, c):
        return f"sudo docker logs {self.container_of(c)}"

    def stop_clients(self):
        for c in self.clients:
            if self._container_state(c) is not None:
                docker("rm", "-f", self.container_of(c))
                log(f"{c.name}: container removed")

    def start_xvfb(self):
        pass  # each container runs its own

    def start_wm(self):
        pass  # ditto

    def bring_up(self):
        self.ensure_image()
        self.start_relay()
        self.start_clients()
        return self.all_mcp_ready()

    def down(self):
        self.stop_clients()
        docker("rm", "-f", RELAY_CONTAINER)
        log("relay: removed")

    # ----------------------------------------------------------------- input

    def press_sync(self, c, nearby=False):
        """Same idea as host mode, but xdotool runs inside the container,
        against that container's own X server. Sync P2P is left open, as in
        host mode — see `close_dialogs`."""
        xdo = self._xdo_in(c)
        if not self._activate(c, xdo):
            return False
        if nearby:
            # Shift+F5 arrives at the app as a bare F5 — the modifier does not
            # survive xdotool here, so it runs a *relay* sync instead. The
            # menu item is unambiguous. "Sync P2P..." is always the sixth
            # entry of the File menu; "Sync Details..." appears after it, so
            # the offset does not move.
            xdo("mousemove", "79", "105", "click", "1")
            time.sleep(1.2)
            xdo("mousemove", "160", "356", "click", "1")
            return True
        xdo("key", "F5")
        time.sleep(3.0)
        self._dismiss(xdo)
        return True

    def close_dialogs(self, c):
        """Close whatever modal the client has open — for Sync P2P, that ends
        its session."""
        xdo = self._xdo_in(c)
        if not self._activate(c, xdo):
            return False
        self._dismiss(xdo)
        return True

    def _xdo_in(self, c):
        container = self.container_of(c)

        # `docker exec` starts a bare environment: without DISPLAY, xdotool
        # cannot reach the X server the entrypoint started.
        def xdo(*args):
            return docker("exec", "-e", "DISPLAY=:0", container, "xdotool", *args)

        return xdo

    def _activate(self, c, xdo):
        # Matching "<name>.noo" directly does not work here — the title is
        # "Noo — <name>.noo" and the em-dash defeats xdotool's search in this
        # image. Search broadly, then read each title back and pick ours.
        find = xdo("search", "--name", "Noo")
        window = None
        for candidate in find.stdout.split():
            title = xdo("getwindowname", candidate).stdout.strip()
            if f"{c.name}.noo" in title:
                window = candidate
                break
        if window is None:
            return False
        xdo("windowactivate", "--sync", window)
        time.sleep(0.6)
        return True

    @staticmethod
    def _dismiss(xdo):
        # A failed sync has Retry/Close buttons that Escape does not reach.
        # Left open a dialog swallows the next keystroke, so it is clicked
        # away: dialogs are centred, and the rightmost button sits here on
        # this screen size.
        for _ in range(3):
            xdo("mousemove", "975", "610", "click", "1")
            time.sleep(0.4)
            xdo("key", "Escape")
            time.sleep(0.2)

    # ---------------------------------------------------------------- status

    def status(self):
        log(f"root      {self.root}")
        relay_state = docker(
            "inspect", RELAY_CONTAINER, "--format", "{{.State.Status}}"
        ).stdout.strip() or "absent"
        log("relay     %-8s http://%s:%d (containers), 127.0.0.1:%d (host)"
            % (relay_state, RELAY_CONTAINER, self.relay_port, self.relay_port))
        for c in self.clients:
            state = self._container_state(c) or "absent"
            ip = docker(
                "inspect", self.container_of(c), "--format",
                "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}",
            ).stdout.strip()
            log(
                "%-9s %-8s ip=%-12s device=%-20s mcp=%s"
                % (c.name, state, ip or "-", c.device_id,
                   "up" if DockerMcp(c).ping() else "down")
            )


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--dir", default="/tmp/noo-playground-docker")
    parser.add_argument("--clients", type=int, default=3, choices=[2, 3, 4])
    parser.add_argument("--relay-port", type=int, default=8080)
    parser.add_argument("--sync-timeout", type=int, default=120)
    parser.add_argument("--image", default=IMAGE)
    sub = parser.add_subparsers(dest="cmd", required=True)
    for name in ("setup", "up", "down", "status", "scenario", "run"):
        sub.add_parser(name)
    args = parser.parse_args()

    pg = DockerPlayground(
        args.dir, args.clients, args.relay_port, ":0", image=args.image
    )

    if args.cmd == "setup":
        pg.ensure_image()
        pg.setup()
    elif args.cmd == "up":
        pg.ensure_image()
        pg.setup(fresh=not (pg.root / "seed-spec.json").exists())
        pg.bring_up()
        pg.status()
    elif args.cmd == "down":
        pg.down()
    elif args.cmd == "status":
        pg.ensure_network()
        pg.status()
    elif args.cmd == "scenario":
        pg.ensure_network()
        sys.exit(
            0 if scenarios(pg, args.sync_timeout, mcp_factory=DockerMcp) else 1
        )
    elif args.cmd == "run":
        pg.ensure_image()
        pg.setup()
        if not pg.bring_up():
            pg.status()
            pg.down()
            sys.exit("not every client came up; see " + str(pg.root))
        pg.status()
        try:
            ok = scenarios(pg, args.sync_timeout, mcp_factory=DockerMcp)
        finally:
            pg.down()
        sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
