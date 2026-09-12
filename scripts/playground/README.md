# Client playground

Runs several **real** Noo clients side by side on one machine, against a local
stand-in for the sync relay, and drives them the way a test agent would — over
each client's own MCP server. This is ToDo item 5, and the seam items 6-7 need.

There are two modes. **Use the Docker one** unless you have a reason not to:
it is the only one where LAN sync works, because each client gets its own
network namespace (see "LAN sync" below).

```bash
cd <repo>
python3 scripts/playground/playground_docker.py run    # containers: all 5 scenarios pass
python3 scripts/playground/playground_docker.py up     # leave it running to poke at
python3 scripts/playground/playground_docker.py scenario
python3 scripts/playground/playground_docker.py status
python3 scripts/playground/playground_docker.py down

python3 scripts/playground/playground.py run           # same fleet, straight on the host
```

Host mode needs no Docker and starts faster, but its clients share the host's
network, so scenario 3 (P2P) cannot pass there.

`--clients 2|3|4` picks the fleet size (default 3), `--dir` the sandbox root
(default `/tmp/noo-playground`), `--relay-port`, `--display`.

Requires a built client (`cd client && flutter build linux --release`) and, on
a bare server, `Xvfb`, `openbox`, `xdotool`, `gnome-keyring`, `libsecret-tools`.

## What it puts together

| Piece | Where |
| --- | --- |
| Local relay (v2 REST API) | `relay.py` |
| Orchestrator, sandboxes, scenarios | `playground.py` |
| The same, one container per client | `playground_docker.py`, `Dockerfile`, `entrypoint.sh` |
| Database seeding, using the app's own schema | `client/test/playground/seed_playground_test.dart` |

Docker mode subclasses host mode rather than copying it: the sandbox layout,
the seeding, the relay and the scenarios are shared, so the two cannot drift.
Only what touches the process differs — starting clients, reaching MCP (the
app binds it to loopback, so calls go in through `docker exec`), and pressing
keys.

Each client gets its own `HOME` and XDG directories, so its SharedPreferences,
its database and its keyring are its own — isolation by environment, with no
change to the app. Every client has a distinct device id (`playground-alpha`,
`-bravo`, …), its own MCP port from 47811 up, and its own window.

The whole fleet shares one **database password**: the sync key is HKDF'd from
it, so devices that do not share it cannot read each other's packets
(`docs/P2P_SYNC.md` §5.1). Every client is also pre-trusted by every other in
the `lan_trusted_peers` property, so a LAN exchange never stops on the pairing
prompt.

## The relay

`relay.py` is a test double, not a reimplementation of the production relay: no
real JWTs, no rate limiting, no multi-tenancy beyond a username column. What it
*does* reproduce are the invariants the client's correctness rests on, because
a lax relay makes the playground prove nothing:

- per-origin-device counters are contiguous — a gap is 409, a re-sent slot with
  identical bytes is 200, and a slot holding *different* bytes is 409 (§3.3);
- a packet declaring a blob the relay does not hold is refused with 409, so
  "a stored packet's blobs are stored" holds here too (§3.5);
- a snapshot's coverage declaration prunes what it supersedes, and blobs no
  surviving packet declares are collected with it (§4.3);
- blob reads honour `Range`, so the client's chunked/resumable transfer path is
  exercised rather than silently falling back to whole-blob reads.

State is one SQLite file, inspectable while clients are running:

```bash
python3 scripts/playground/relay.py inspect --db /tmp/noo-playground/relay/relay.sqlite --packets
```

That doubles as a start on ToDo item 3 ("console utility to see the content of
the syncing database at the server").

## Two things that had to be worked around

**1. Secure storage looks items up by a schema name that is not the label.**

`flutter_secure_storage_linux` 3.0.2 builds its `SecretSchema` in the
constructor from `label.c_str()` while `label` is still the default
`"default"` — short enough to live in the `std::string`'s inline buffer — and
then `setLabel()` assigns the real 34-byte
`io.lab517.noo/FlutterSecureStorage`. libstdc++ moves the characters to the
heap and reuses that inline buffer to hold `_M_allocated_capacity`, so
`the_schema.name` now reads *those* bytes: the capacity, 34, little-endian —
the single byte `0x22`, `"`.

So every keyring item the app writes carries `xdg:schema = "` rather than the
label. That is **deterministic, not random**: it is the label's length. Which
means the playground can seed the keyring directly, and does:

```python
SECRET_SCHEMA = chr(len(SECRET_LABEL))   # playground.py
```

With that, a fresh sandbox starts with the database already unlocked and the
MCP token already readable — no dialog, no UI automation.

Two consequences beyond the playground, both worth a look:

- nothing outside the app can provision its secrets by the documented schema;
- the byte is derived from the label's *length*, so changing `APPLICATION_ID`
  (or the plugin's label) would silently orphan every saved password and MCP
  token — users would be asked for a password they had told the app to
  remember. The bug is invisible today and would surface as data loss on a
  rename.

The fix upstream is one line — have `setLabel()` re-point `the_schema.name` at
the string it just assigned — and there is no released version with it (3.0.2
is current). Pinning a patched copy via `dependency_overrides` is the obvious
local remedy if you want the app itself to stop depending on this accident.

**2. LAN sync needs a real network segment, and a real request.**

- `LanSyncCoordinator` only exchanges when someone asks: the menu's *Sync with
  Nearby Devices*, or a peer's sync request. The auto-sync interval drives the
  relay only. The scenarios therefore drive the app's own UI — **F5** for the
  relay, the menu item for nearby devices. (`Shift+F5` is the documented
  shortcut for the latter, but the modifier does not survive `xdotool` here and
  the app sees a bare F5, i.e. a relay sync. The menu item is unambiguous.)
- Discovery broadcasts to `255.255.255.255:46630`, and Linux does **not**
  deliver that to another socket on the sending host — it leaves via the
  default interface and never comes back. Clients sharing a host therefore
  never see each other, which is why host mode cannot pass scenario 3.

Docker fixes exactly that: containers on a user-defined bridge are a real L2
segment, the broadcast is flooded to the other ports, and each client sees the
other two (the status bar shows the peer count). Verified directly — a probe
sent from one container arrives at another, and the clients exchange
`NOO2P`/`NOO2A` datagrams among themselves.

The relay runs as a container on the same network rather than on the host,
because this host's firewall drops traffic from the bridge to the host.

## Scenarios

1. a note created on one client reaches the others via the relay
2. an edit on a second client converges back
3. with the relay stopped, a note still travels over the LAN
4. the relay accepts the streams it missed once it is back
5. the note that travelled over the LAN reaches the whole fleet

Docker mode: **5 of 5 pass**, from a clean `run`.\nHost mode: 4 of 5 — scenario 3 cannot pass there, for the reason above.

## Layout

```
/tmp/noo-playground/
  relay/relay.sqlite, relay.log      relay state and request log
  seed-spec.json                     what the seeder was told to build
  clients/<name>/
    home/…                           HOME + XDG (prefs, keyring) for this client
    data/<name>.noo                  its database
    launch.sh, inner.sh              sandbox env, keyring, then the app
    client.log                       its stdout/stderr
    client.pid
```

In Docker mode the same tree lives under `/tmp/noo-playground-docker` and is
bind-mounted into each container **at the same path**, so the seeded
preferences — which name the database by absolute path — mean the same thing
inside and out. Client output goes to `sudo docker logs noopg-<name>`.

To look at a container's screen while debugging:

```bash
sudo docker exec -u 0 noopg-alpha apt-get install -y imagemagick
sudo docker exec -e DISPLAY=:0 noopg-alpha import -window root /tmp/s.png
sudo docker cp noopg-alpha:/tmp/s.png .
```
