#!/usr/bin/env python3
"""A local stand-in for the Noo sync relay, for the test playground.

Speaks the v2 REST API the client expects (docs/P2P_SYNC.md, §3 and §4) well
enough to run real clients against it offline. It is deliberately *not* a
reimplementation of the production relay: no real JWTs, no rate limiting, no
multi-tenancy beyond a username column. What it does reproduce faithfully are
the invariants the client's correctness depends on, because a relay that is
lax about them makes the playground prove nothing:

  * per-origin-device counters are contiguous — a gap is 409, a re-sent slot
    holding identical bytes is 200 rather than an error (§3.3);
  * a packet declaring a blob the relay does not hold is refused with 409, so
    "a stored packet's blobs are stored" holds here too (§3.5);
  * a snapshot's coverage declaration prunes what it supersedes, and blobs no
    surviving packet declares are collected with it (§4.3).

Blob reads honour `Range`, so the client's chunked/resumable transfer path is
actually exercised rather than silently falling back to whole-blob reads.

State lives in one SQLite file so it survives a restart and can be inspected
while clients are running:

    relay.py serve --db <file> --port 8080
    relay.py inspect --db <file>            # what the server is holding
"""

import argparse
import base64
import hashlib
import json
import os
import re
import secrets
import sqlite3
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

SCHEMA = """
CREATE TABLE IF NOT EXISTS users (
  username TEXT PRIMARY KEY,
  password TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS devices (
  username    TEXT NOT NULL,
  device_id   TEXT NOT NULL,
  device_name TEXT NOT NULL DEFAULT '',
  platform    TEXT NOT NULL DEFAULT '',
  last_seen   TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (username, device_id)
);
CREATE TABLE IF NOT EXISTS tokens (
  token    TEXT PRIMARY KEY,
  username TEXT NOT NULL,
  kind     TEXT NOT NULL          -- 'access' | 'refresh'
);
CREATE TABLE IF NOT EXISTS packets (
  username   TEXT NOT NULL,
  device_id  TEXT NOT NULL,
  counter    INTEGER NOT NULL,
  payload    BLOB NOT NULL,
  payload_sha TEXT NOT NULL,
  blob_ids   TEXT NOT NULL DEFAULT '',   -- comma separated
  is_snapshot INTEGER NOT NULL DEFAULT 0,
  stored_at  TEXT NOT NULL,
  PRIMARY KEY (username, device_id, counter)
);
-- Highest counter ever accepted per device, kept across pruning so a stream
-- emptied by compaction continues where it left off instead of re-issuing
-- identities (§4.3, safety rule 4).
CREATE TABLE IF NOT EXISTS marks (
  username  TEXT NOT NULL,
  device_id TEXT NOT NULL,
  mark      INTEGER NOT NULL,
  PRIMARY KEY (username, device_id)
);
CREATE TABLE IF NOT EXISTS blobs (
  username TEXT NOT NULL,
  blob_id  TEXT NOT NULL,
  bytes    BLOB NOT NULL,
  PRIMARY KEY (username, blob_id)
);
"""

_BLOB_ID = re.compile(r"^[0-9a-f]{64}$")
_RANGE = re.compile(r"^bytes=(\d+)-(\d*)$")


def now_iso():
    import datetime

    return datetime.datetime.now(datetime.timezone.utc).isoformat()


class Store:
    """All relay state. One lock: the playground's traffic is tiny and a
    single writer removes a whole class of confusing test flakes."""

    def __init__(self, path):
        self.path = path
        self._lock = threading.Lock()
        self._db = sqlite3.connect(path, check_same_thread=False)
        self._db.executescript(SCHEMA)
        self._db.commit()

    def __enter__(self):
        self._lock.acquire()
        return self._db

    def __exit__(self, *exc):
        self._db.commit()
        self._lock.release()


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    store: Store = None
    verbose = False

    # ---------------------------------------------------------------- plumbing

    def log_message(self, fmt, *args):
        if Handler.verbose:
            sys.stderr.write("relay: %s\n" % (fmt % args))

    def _body(self):
        length = int(self.headers.get("Content-Length") or 0)
        return self.rfile.read(length) if length else b""

    def _send(self, code, body=b"", ctype="application/json", extra=None):
        if isinstance(body, str):
            body = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        for k, v in (extra or {}).items():
            self.send_header(k, v)
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def _json(self, code, obj):
        self._send(code, json.dumps(obj))

    def _error(self, code, message):
        self._json(code, {"error": message})

    def _user(self):
        """The username behind the bearer token, or None (401 already sent)."""
        auth = self.headers.get("Authorization") or ""
        if not auth.startswith("Bearer "):
            self._error(401, "missing bearer token")
            return None
        token = auth[len("Bearer "):]
        with Handler.store as db:
            row = db.execute(
                "SELECT username FROM tokens WHERE token = ? AND kind = 'access'",
                (token,),
            ).fetchone()
        if not row:
            self._error(401, "bad token")
            return None
        return row[0]

    # ------------------------------------------------------------------ routes

    def do_GET(self):
        path = urlparse(self.path).path
        query = parse_qs(urlparse(self.path).query)
        if path == "/health":
            return self._json(200, {"status": "ok"})
        if path == "/api/v2/changes/vector":
            return self._vector()
        if path == "/api/v2/changes/":
            return self._changes(query)
        if path == "/api/v2/changes/usage":
            return self._usage()
        if path == "/api/v2/changes/hashes":
            return self._hashes(query)
        if path == "/api/v2/devices/":
            return self._devices()
        if path.startswith("/api/v2/blobs/"):
            return self._get_blob(path.rsplit("/", 1)[-1])
        return self._error(404, "no such endpoint")

    def do_HEAD(self):
        path = urlparse(self.path).path
        if path.startswith("/api/v2/blobs/"):
            return self._head_blob(path.rsplit("/", 1)[-1])
        return self._error(404, "no such endpoint")

    def do_POST(self):
        path = urlparse(self.path).path
        if path == "/api/v2/auth/register/":
            return self._register()
        if path == "/api/v2/auth/login/":
            return self._login()
        if path == "/api/v2/auth/refresh/":
            return self._refresh()
        if path == "/api/v2/changes/":
            return self._upload()
        return self._error(404, "no such endpoint")

    def do_PUT(self):
        path = urlparse(self.path).path
        if path.startswith("/api/v2/blobs/"):
            return self._put_blob(path.rsplit("/", 1)[-1])
        return self._error(404, "no such endpoint")

    def do_DELETE(self):
        path = urlparse(self.path).path
        if path.startswith("/api/v2/devices/"):
            return self._delete_device(path.rsplit("/", 1)[-1])
        return self._error(404, "no such endpoint")

    # -------------------------------------------------------------------- auth

    def _register(self):
        body = json.loads(self._body() or b"{}")
        username, password = body.get("username"), body.get("password")
        if not username or not password:
            return self._error(400, "username and password required")
        with Handler.store as db:
            row = db.execute(
                "SELECT password FROM users WHERE username = ?", (username,)
            ).fetchone()
            if row:
                # Re-registering with the same credentials is how a second
                # playground client joins an existing account; a mismatch is a
                # genuine conflict.
                if row[0] != password:
                    return self._error(409, "username taken")
                return self._json(200, {"status": "exists"})
            db.execute(
                "INSERT INTO users (username, password) VALUES (?, ?)",
                (username, password),
            )
        return self._json(201, {"status": "created"})

    def _login(self):
        body = json.loads(self._body() or b"{}")
        username, password = body.get("username"), body.get("password")
        with Handler.store as db:
            row = db.execute(
                "SELECT password FROM users WHERE username = ?", (username,)
            ).fetchone()
            if not row or row[0] != password:
                return self._error(401, "bad credentials")
            if body.get("device_id"):
                db.execute(
                    "INSERT OR REPLACE INTO devices "
                    "(username, device_id, device_name, platform, last_seen) "
                    "VALUES (?, ?, ?, ?, ?)",
                    (
                        username,
                        body["device_id"],
                        body.get("device_name") or "",
                        body.get("platform") or "",
                        now_iso(),
                    ),
                )
            access, refresh = secrets.token_hex(16), secrets.token_hex(16)
            db.executemany(
                "INSERT INTO tokens (token, username, kind) VALUES (?, ?, ?)",
                [(access, username, "access"), (refresh, username, "refresh")],
            )
        return self._json(200, {"access_token": access, "refresh_token": refresh})

    def _refresh(self):
        body = json.loads(self._body() or b"{}")
        token = body.get("refresh_token")
        with Handler.store as db:
            row = db.execute(
                "SELECT username FROM tokens WHERE token = ? AND kind = 'refresh'",
                (token,),
            ).fetchone()
            if not row:
                return self._error(401, "bad refresh token")
            access = secrets.token_hex(16)
            db.execute(
                "INSERT INTO tokens (token, username, kind) VALUES (?, ?, 'access')",
                (access, row[0]),
            )
        return self._json(200, {"access_token": access})

    # ----------------------------------------------------------------- packets

    def _vector(self):
        user = self._user()
        if user is None:
            return
        with Handler.store as db:
            rows = db.execute(
                "SELECT device_id, MAX(counter) FROM packets WHERE username = ? "
                "GROUP BY device_id",
                (user,),
            ).fetchall()
        return self._json(200, {"vectors": {d: c for d, c in rows}})

    def _upload(self):
        user = self._user()
        if user is None:
            return
        device = self.headers.get("X-Noo-Origin-Device")
        counter = self.headers.get("X-Noo-Counter")
        if not device or not counter:
            return self._error(400, "origin device and counter required")
        counter = int(counter)
        payload = self._body()
        sha = hashlib.sha256(payload).hexdigest()
        covers = self.headers.get("X-Noo-Snapshot-Covers")
        blob_header = self.headers.get("X-Noo-Blobs") or ""
        blob_ids = [b for b in blob_header.split(",") if b]

        with Handler.store as db:
            # The invariant everything else rests on: a stored packet's blobs
            # are stored (§3.5). Refusing here is what makes a pulled
            # reference always resolvable.
            held_blobs = {
                r[0]
                for r in db.execute(
                    "SELECT blob_id FROM blobs WHERE username = ?", (user,)
                )
            }
            missing = [b for b in blob_ids if b not in held_blobs]
            if missing:
                return self._error(409, "missing blobs: %s" % ",".join(missing))

            mark = db.execute(
                "SELECT mark FROM marks WHERE username = ? AND device_id = ?",
                (user, device),
            ).fetchone()
            mark = mark[0] if mark else 0

            if counter > mark + 1:
                return self._error(
                    409, "non-contiguous counter %d (held %d)" % (counter, mark)
                )
            if counter <= mark:
                existing = db.execute(
                    "SELECT payload_sha FROM packets "
                    "WHERE username = ? AND device_id = ? AND counter = ?",
                    (user, device, counter),
                ).fetchone()
                # Same bytes: a duplicate delivered by another path. Different
                # bytes in an occupied slot is a forked stream — the client
                # detects that from the hashes endpoint, so answer plainly.
                if existing and existing[0] != sha:
                    return self._error(409, "slot holds different bytes")
                return self._json(200, {"status": "already_held"})

            db.execute(
                "INSERT INTO packets (username, device_id, counter, payload, "
                "payload_sha, blob_ids, is_snapshot, stored_at) "
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                (
                    user,
                    device,
                    counter,
                    payload,
                    sha,
                    ",".join(blob_ids),
                    1 if covers else 0,
                    now_iso(),
                ),
            )
            db.execute(
                "INSERT OR REPLACE INTO marks (username, device_id, mark) "
                "VALUES (?, ?, ?)",
                (user, device, counter),
            )

            pruned = None
            if covers:
                pruned = self._prune(db, user, device, counter, json.loads(covers))

        body = {"status": "stored"}
        if pruned is not None:
            body["pruned"] = pruned
        return self._json(201, body)

    def _prune(self, db, user, snapshot_device, snapshot_counter, covers):
        """Drop what the snapshot supersedes, then collect orphaned blobs."""
        packets = bytes_freed = 0
        for device, upto in covers.items():
            rows = db.execute(
                "SELECT counter, LENGTH(payload) FROM packets "
                "WHERE username = ? AND device_id = ? AND counter <= ? "
                "AND NOT (device_id = ? AND counter = ?)",
                (user, device, int(upto), snapshot_device, snapshot_counter),
            ).fetchall()
            for counter, size in rows:
                packets += 1
                bytes_freed += size
            db.execute(
                "DELETE FROM packets WHERE username = ? AND device_id = ? "
                "AND counter <= ? AND NOT (device_id = ? AND counter = ?)",
                (user, device, int(upto), snapshot_device, snapshot_counter),
            )

        # A blob no surviving packet declares is unreachable; the relay is the
        # only node that collects these automatically (§3.5).
        alive = set()
        for (ids,) in db.execute(
            "SELECT blob_ids FROM packets WHERE username = ?", (user,)
        ):
            alive.update(b for b in ids.split(",") if b)
        dead = [
            r[0]
            for r in db.execute(
                "SELECT blob_id FROM blobs WHERE username = ?", (user,)
            )
            if r[0] not in alive
        ]
        blob_bytes = 0
        for blob_id in dead:
            row = db.execute(
                "SELECT LENGTH(bytes) FROM blobs WHERE username = ? AND blob_id = ?",
                (user, blob_id),
            ).fetchone()
            blob_bytes += row[0] if row else 0
            db.execute(
                "DELETE FROM blobs WHERE username = ? AND blob_id = ?",
                (user, blob_id),
            )
        return {
            "pruned_packets": packets,
            "pruned_bytes": bytes_freed,
            "pruned_blobs": len(dead),
            "pruned_blob_bytes": blob_bytes,
        }

    def _changes(self, query):
        user = self._user()
        if user is None:
            return
        have = json.loads(query.get("have", ["{}"])[0])
        limit = int(query.get("limit", ["100"])[0])
        with Handler.store as db:
            rows = db.execute(
                "SELECT device_id, counter, payload, stored_at FROM packets "
                "WHERE username = ? ORDER BY device_id, counter",
                (user,),
            ).fetchall()
        wanted = [r for r in rows if r[1] > int(have.get(r[0], 0))]
        page, has_more = wanted[:limit], len(wanted) > limit
        return self._json(
            200,
            {
                "changes": [
                    {
                        "origin_device_id": d,
                        "counter": c,
                        "payload": base64.b64encode(p).decode(),
                        "stored_at": t,
                    }
                    for d, c, p, t in page
                ],
                "has_more": has_more,
            },
        )

    def _hashes(self, query):
        user = self._user()
        if user is None:
            return
        device = query.get("device", [""])[0]
        lo = int(query.get("from", ["0"])[0])
        hi = int(query.get("to", ["0"])[0])
        with Handler.store as db:
            rows = db.execute(
                "SELECT counter, payload_sha FROM packets WHERE username = ? "
                "AND device_id = ? AND counter BETWEEN ? AND ?",
                (user, device, lo, hi),
            ).fetchall()
        return self._json(200, {"hashes": {str(c): h for c, h in rows}})

    def _usage(self):
        user = self._user()
        if user is None:
            return
        with Handler.store as db:
            devices = db.execute(
                "SELECT p.device_id, COUNT(*), SUM(LENGTH(p.payload)), "
                "MIN(p.counter), MAX(p.counter), SUM(p.is_snapshot) "
                "FROM packets p WHERE p.username = ? GROUP BY p.device_id",
                (user,),
            ).fetchall()
            names = dict(
                db.execute(
                    "SELECT device_id, device_name FROM devices WHERE username = ?",
                    (user,),
                ).fetchall()
            )
            blobs = db.execute(
                "SELECT COUNT(*), COALESCE(SUM(LENGTH(bytes)), 0) FROM blobs "
                "WHERE username = ?",
                (user,),
            ).fetchone()
        entries = [
            {
                "device_id": d,
                "device_name": names.get(d, ""),
                "packets": n,
                "bytes": size or 0,
                "first_counter": lo,
                "last_counter": hi,
                "snapshots": snaps or 0,
            }
            for d, n, size, lo, hi, snaps in devices
        ]
        entries.sort(key=lambda e: e["bytes"], reverse=True)
        return self._json(
            200,
            {
                "packets": sum(e["packets"] for e in entries),
                "bytes": sum(e["bytes"] for e in entries),
                "devices": entries,
                "blobs": blobs[0],
                "blob_bytes": blobs[1],
            },
        )

    def _devices(self):
        user = self._user()
        if user is None:
            return
        with Handler.store as db:
            rows = db.execute(
                "SELECT device_id, device_name, platform, last_seen FROM devices "
                "WHERE username = ?",
                (user,),
            ).fetchall()
        return self._json(
            200,
            [
                {
                    "device_id": d,
                    "device_name": n,
                    "platform": p,
                    "last_seen": s,
                }
                for d, n, p, s in rows
            ],
        )

    def _delete_device(self, device_id):
        user = self._user()
        if user is None:
            return
        with Handler.store as db:
            db.execute(
                "DELETE FROM devices WHERE username = ? AND device_id = ?",
                (user, device_id),
            )
        return self._json(200, {"status": "deleted"})

    # ------------------------------------------------------------------- blobs

    def _blob_bytes(self, user, blob_id):
        with Handler.store as db:
            row = db.execute(
                "SELECT bytes FROM blobs WHERE username = ? AND blob_id = ?",
                (user, blob_id),
            ).fetchone()
        return row[0] if row else None

    def _head_blob(self, blob_id):
        user = self._user()
        if user is None:
            return
        data = self._blob_bytes(user, blob_id)
        if data is None:
            return self._error(404, "not held")
        return self._send(200, b"", "application/octet-stream")

    def _put_blob(self, blob_id):
        user = self._user()
        if user is None:
            return
        if not _BLOB_ID.match(blob_id):
            return self._error(400, "invalid blob id")
        data = self._body()
        with Handler.store as db:
            # Idempotent: a blob already held keeps the bytes it has. Two
            # devices encrypting the same file produce different ciphertexts
            # and either decrypts to the content the id names.
            db.execute(
                "INSERT OR IGNORE INTO blobs (username, blob_id, bytes) "
                "VALUES (?, ?, ?)",
                (user, blob_id, data),
            )
        return self._json(200, {"status": "stored"})

    def _get_blob(self, blob_id):
        user = self._user()
        if user is None:
            return
        data = self._blob_bytes(user, blob_id)
        if data is None:
            return self._error(404, "not held")

        rng = _RANGE.match((self.headers.get("Range") or "").strip().lower())
        if not rng:
            return self._send(200, data, "application/octet-stream")
        start = int(rng.group(1))
        if start >= len(data):
            # The requester's partial is not a prefix of what we hold; it
            # restarts the transfer rather than resuming into a mismatch.
            return self._send(
                416,
                b"",
                "application/octet-stream",
                {"Content-Range": "bytes */%d" % len(data)},
            )
        end = min(int(rng.group(2)), len(data) - 1) if rng.group(2) else len(data) - 1
        return self._send(
            206,
            data[start : end + 1],
            "application/octet-stream",
            {"Content-Range": "bytes %d-%d/%d" % (start, end, len(data))},
        )


def serve(args):
    Handler.store = Store(args.db)
    Handler.verbose = args.verbose
    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print("relay listening on http://%s:%d (state: %s)" % (args.host, args.port, args.db),
          flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


def inspect(args):
    """What the relay is holding — the 'see the syncing database at the
    server' view, usable while clients are running."""
    if not os.path.exists(args.db):
        print("no relay state at %s" % args.db)
        return 1
    db = sqlite3.connect("file:%s?mode=ro" % args.db, uri=True)
    users = [r[0] for r in db.execute("SELECT username FROM users")]
    if not users:
        print("no accounts yet")
    for user in users:
        print("account %s" % user)
        devices = db.execute(
            "SELECT device_id, device_name, platform FROM devices WHERE username = ?",
            (user,),
        ).fetchall()
        for did, name, platform in devices:
            print("  device %-22s %-16s %s" % (did, name or "-", platform or "-"))
        rows = db.execute(
            "SELECT device_id, COUNT(*), COALESCE(SUM(LENGTH(payload)), 0), "
            "MIN(counter), MAX(counter), SUM(is_snapshot) "
            "FROM packets WHERE username = ? GROUP BY device_id",
            (user,),
        ).fetchall()
        if not rows:
            print("  (no packets)")
        for did, n, size, lo, hi, snaps in rows:
            print(
                "  stream %-22s %3d packets  %7d B  counters %d..%d  %d snapshot(s)"
                % (did, n, size, lo, hi, snaps or 0)
            )
        blobs = db.execute(
            "SELECT COUNT(*), COALESCE(SUM(LENGTH(bytes)), 0) FROM blobs "
            "WHERE username = ?",
            (user,),
        ).fetchone()
        print("  blobs  %d holding %d B" % blobs)
        if args.packets:
            for did, counter, size, ids, snap, at in db.execute(
                "SELECT device_id, counter, LENGTH(payload), blob_ids, is_snapshot, "
                "stored_at FROM packets WHERE username = ? "
                "ORDER BY device_id, counter",
                (user,),
            ):
                print(
                    "    %-22s #%-4d %6d B %s%s  %s"
                    % (
                        did,
                        counter,
                        size,
                        "SNAPSHOT " if snap else "",
                        ("blobs=" + ids) if ids else "",
                        at,
                    )
                )
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("serve", help="run the relay")
    s.add_argument("--db", required=True)
    s.add_argument("--host", default="127.0.0.1")
    s.add_argument("--port", type=int, default=8080)
    s.add_argument("--verbose", action="store_true")
    s.set_defaults(func=serve)

    i = sub.add_parser("inspect", help="print what the relay holds")
    i.add_argument("--db", required=True)
    i.add_argument("--packets", action="store_true", help="list every packet")
    i.set_defaults(func=inspect)

    args = parser.parse_args()
    sys.exit(args.func(args) or 0)


if __name__ == "__main__":
    main()
