# Noo Sync Protocol v2 — Per-Device Streams and LAN Peer Sync

This document specifies **sync protocol version 2**: the replacement of the
relay's global sequence with per-device packet streams and version vectors,
and the new **LAN peer protocol** that lets Noo devices sync directly with
each other on the local network — with or without a relay.

Protocol **version 1** — now retired — is specified in `RELAY_PROTOCOL.md`;
sections of that document that v2 keeps unchanged are referenced rather than
repeated.

Status: **implemented**. Client: `client/lib/data/services/` (`sync_service.dart`,
`sync_api_client.dart`, `sync_crypto.dart`, `sync_change_packager.dart`,
`peer_sync_server.dart`, `peer_api_client.dart`, `peer_discovery.dart`,
`lan_sync_coordinator.dart`); server: `app/` in the `noo-relay`
repository. Deliberate deviations
from the original draft are marked *[impl]* inline.

---

## 1. Design overview

### 1.1 What v2 keeps from v1

The entire **merge model** is unchanged (see `RELAY_PROTOCOL.md` §6.2, §8):

- Field-level changes carrying **full current values, not diffs**.
- Deterministic, symmetric **field-level Last-Writer-Wins** on origin
  timestamps, applied identically on every device.
- `is_creation` materialization, parent resolution, soft deletes, and
  `parentId` cycle detection.
- The **cryptographic envelope**: AES-256-GCM over a gzipped JSON packet, key
  derived via HKDF-SHA256 from the database password (§4 below; only the info
  string and AAD change).

### 1.2 What v2 replaces

V1's transport is built around one **server-assigned global sequence** per
user. That requires a single sequencer, which a LAN swarm does not have, and
makes mixed relay+LAN delivery paths need cross-path deduplication.

V2 replaces it with **per-device streams**:

- Every packet is identified by `(origin_device_id, counter)`, where `counter`
  is a **client-assigned** monotonic integer, contiguous per device, stamped
  at packaging time.
- Every node's sync state is a **version vector**:
  `{device_id → highest counter held}`.
- The sync exchange, against *any* node, is:
  **"here is my vector → give me everything you hold that I don't."**

### 1.3 Everything is a peer

Under v2 there is one kind of sync node. Clients and the relay all:

- **store** encrypted packets verbatim, keyed by `(origin_device_id, counter)`;
- **answer** vector queries and serve missing packets;
- **carry** packets for other devices ("gossip", §7).

The relay is just a peer that is always on, reachable off-LAN, and never
originates packets. Consequences:

- **Dedup is free.** A packet arriving via both a LAN peer and the relay has
  the same identity; the second copy is a no-op.
- **Any connectivity path converges.** A laptop can pick up the phone's
  packets over LAN and later upload them to the relay on the phone's behalf.
- **Bootstrap works without a relay.** A new device with an empty vector can
  replay the full history from any single peer.
- **Replay is structurally harmless**: a packet can only ever occupy its own
  `(device, counter)` slot (bound by AAD, §4.2), and a slot is applied once.

### 1.4 Scope constraints

- **Peer sync is LAN-only.** No NAT traversal, no WAN P2P, no relay-assisted
  hole punching. Off-LAN devices converge through the relay.
- **Mixed operation is the norm**: LAN peer sync and relay sync run
  concurrently against the same local packet store, with no coordination
  between them (none is needed — that is the point of the vector model).
- Single-user deployment is assumed for migration (§11); the protocol itself
  remains multi-user-safe on the relay side.

## 2. Terminology

| Term | Meaning |
|------|---------|
| **Node** | Anything that stores and exchanges packets: a client device or the relay. |
| **Peer** | Another node of the *same user* reachable on the LAN. |
| **Packet** | One encrypted blob = one `SyncPacket` (v2): a batch of field-level changes from one origin device. The unit of storage, identity, and transfer. |
| **Origin device** | The device that packaged a packet. Fixed forever; carried outside the ciphertext and bound by AAD. |
| **Counter** | Per-origin-device monotonic integer, assigned by the origin at packaging time. Contiguous (1, 2, 3, …) in the origin's own store. |
| **Version vector** | `{device_id → highest counter held}`. Because transfer order is ascending per device (§6.3), holdings are always contiguous prefixes and one integer per device suffices — no gap tracking. |
| **Packet store** | Local table of all packets a node holds, own and foreign, as received ciphertext (§5). |
| **Carrying / gossip** | Serving or uploading packets whose origin is another device (§7). |
| **Orphan** | A change skipped because its target entity does not exist yet (§8.2); kept for bounded retry. |

## 3. Packet identity and the SyncPacket v2 format

### 3.1 Identity

A packet is globally identified by `(origin_device_id, counter)`:

- `origin_device_id` — the existing client-generated device UUID.
- `counter` — assigned by the origin as `max(own counter in the packet
  store) + 1`, computed and inserted in the same transaction. *[impl: the
  draft called for a separate persisted `sync_packet_counter` property; the
  store-derived counter is strictly stronger — it cannot desynchronize from
  the store.]* Counters are never reused and never assigned out of order.

Identity travels **in plaintext** alongside the blob (upload metadata, pull
responses, store keys) so that nodes — including the relay, which cannot
decrypt — can index and exchange packets. Integrity of the binding is
enforced by AAD (§4.2).

### 3.2 SyncPacket JSON (plaintext payload)

Identical to v1 (`RELAY_PROTOCOL.md` §6.2) except:

```json
{
  "version": 3,
  "device_id": "<origin device UUID>",
  "counter": 17,
  "timestamp": "<ISO-8601 UTC, packet creation time>",
  "changes": [ ...unchanged from v1, except file.content (§3.5)... ]
}
```

- `version` is `3` *[impl]*; receivers accept `2` and `3`. The two differ in
  exactly one field: in v3 a `file.content` value is a **blob reference**
  (§3.5) rather than the inline base64 bytes. Receivers MUST reject (skip and
  log) packets whose decrypted `version`/`device_id`/`counter` disagree with
  the envelope metadata they were fetched under, and packets of a version
  they do not accept — a v2-only client therefore skips every v3 packet and
  its vector moves past them, so a fleet updates together (the condition
  compaction already imposes).
- The `changes` array, entity types, fields, and all semantics are exactly
  v1 §6.2.
- Two **optional** keys (absent in older packets; parsers that predate them
  ignore unknown keys, so neither bumps `version`):
  - `"vector"` — the sender's applied vector (§6.1) at packaging time:
    what the sender had *seen* when it made these changes. Consumed by the
    conflict-copy check (§8.3).
  - `"full_state": true` — marks a full re-package (§11.2: migration, fork
    recovery): the packet echoes the sender's entire current state rather
    than fresh edits. Receivers suppress conflict copies for such packets.

### 3.3 Fork detection (restored-backup fork)

If a device is restored from a backup, its persisted `sync_packet_counter`
may regress, and it would re-issue existing `(device, counter)` identities
with different content — silent divergence. Two guards, one on the counter
and one on the content:

**Counter regression.**

- Whenever a node learns (from any vector exchange) that a peer or the relay
  holds a counter for **this device's own `device_id`** that is *higher* than
  the local store's own-stream maximum, the device MUST stop packaging. The
  check runs **before** packaging in every exchange, since packaging would
  close the detectable gap.
- *[impl]* What that difference **means** is decided by the content check
  below, which therefore runs first:
  - **Overlap verified identical** → this database has published nothing that
    disagrees with the fleet. It is not forked; it has *lost history* a restore
    rolled back, and the fleet still holds it. The run **packages nothing** and
    pulls the missing packets back instead; the next run resumes the stream
    above them. No error, no user action — the common restore-from-backup case
    heals itself.
  - **Overlap unverifiable** (a node too old to answer, or a range this node
    has pruned) → lost history and re-issued history are indistinguishable, so
    this stays a refusal: `SyncForkException`.
- Nodes MUST ignore an incoming packet for an already-occupied slot (§5.2),
  so even an undetected fork cannot overwrite history — it can only be
  shadowed until detection.

**Content divergence** *[impl]*. The counter test only sees a device that is
still *behind* what it already published. A restored device that packages a
few edits before its next sync has caught its own counter back up: the
vectors agree exactly, the counter test passes, and every packet re-issued
along the way wears an identity that already belongs to different content.
Every node therefore stores a packet's **content hash** — `sha256` of the wire
blob, lowercase hex — alongside the blob, and:

- Every node answers a **stream-hash query**: `{counter → hash}` for one
  origin device over an inclusive counter range (relay `GET
  /api/v2/changes/hashes`, peer `GET /peer/v2/hashes`, both §9). Answers cover
  only *stored* packets — a pruned or never-fetched counter is **absent**,
  which reads as "cannot say", never as a mismatch. Ranges are capped at 500
  counters and clamped rather than rejected.
- At the start of every exchange, after the counter test, a device verifies
  the remote's copy of **its own** stream over the newest 25 counters both
  sides claim. A mismatch throws `SyncStreamDivergedException` naming the
  **lowest** differing counter — where the streams parted — rather than the
  vague "somewhere behind". Only the device's own stream: a fork is something
  a device does to itself, so it is the one stream it is the authority on, and
  another device's divergence is that device's to detect on its next sync.
- The check is **strictly additional safety**. A remote that cannot answer (an
  older relay: 404), a dropped connection or a malformed reply leaves the
  exchange exactly as safe as it was before the check existed. Only a genuine
  mismatch stops anything — otherwise deploying a client ahead of its relay
  would wedge every device. "Could not tell" is reported as such and never as
  agreement, which is what keeps the counter guard above conservative.
- Hashes are computed over the **stored ciphertext**, which every node holds
  verbatim, so all nodes hash identical bytes and the relay can verify a
  stream it cannot decrypt. They disclose nothing the exchange does not:
  hashes of ciphertext the caller may already pull, scoped to its own account.

### 3.4 Fork recovery: re-identity *[impl]*

A confirmed divergence (§3.3) is recovered by **taking a fresh device
identity**, not by repairing the old stream. A fork cannot be retracted: by the
time it is found, a LAN peer may already hold the re-issued packets, and no
message takes them back. Repair would also have to decide *which* copy of a
contested identity is the real one — a question with no answer, since both are
genuinely this device's.

A new identity makes the question moot. `SyncService.recoverFromFork`:

1. **Discards this device's packets from the divergence counter up.** They wear
   identities that belong to other content elsewhere; serving them on is how
   one device's fork becomes everybody's. Packets below it are shared history
   and stay. The applied vector is rewound to the counter below, so the fleet's
   version of those identities is pulled back and applied — its copy is the one
   that stands. (This is the only place the applied vector moves backwards.)
2. **Clears `sync_push_log`.** Counters restart at 1 under the new identity, so
   rows keyed by the old stream's counters would answer §8.3's causal test
   about unrelated packets.
3. **Sets `sync_v2_repackage_needed`**, so the next packaging is a `full_state`
   snapshot (§11.2) of the whole current database under the new identity. It
   carries each entity's existing latest history timestamps, so ordinary LWW
   (§8) converges the fleet whichever version of the old packets a node holds.
4. **Persists the new `device_id` last.** Storing it rebuilds the sync
   configuration and this service, so anything done afterwards would race a
   fresh instance over the same database. Every step above is idempotent, so a
   failed persist leaves a store that is safe as it stands — its worst case is
   a full-state packet published under the *old* identity at a fresh counter,
   which re-uses nothing — and that a retry completes cleanly.

Offered as **Preferences → Sync → Reset device identity** rather than run
automatically: it is visible to the whole fleet (a new device appears in the
relay's storage list, and the old one's packets linger until someone compacts),
so it is the user's call. The divergence counter from the last
`SyncStreamDivergedException` is remembered for the session and passed
automatically; after a restart it is unknown and the reset discards nothing,
which is still safe — the fresh identity alone is what stops the fork, and the
stale packets are inert once nothing adds to that stream.

### 3.5 Attachment blobs: content out of the log *[impl]*

Under v2 a `file.content` change carried the whole attachment, base64, inside
the packet. Every voice memo and image therefore lived in the log — on the
relay and on every device, once per packet that mentioned it, forever until
compaction — and the log grew with the *size* of what was attached, not with
the number of edits. Version 3 moves the bytes out:

- A `file.content` value is `blob:<sha256 hex>` — a **reference** to the
  bytes by their content. The id is the SHA-256 of the plaintext. Unkeyed on
  purpose: it is computable at write time with no key in hand and survives a
  password change; the trade is that a relay can confirm a *guess* ("does
  this account hold this exact well-known file?"), the standard property of
  content-addressed storage. An HMAC under the sync key would close that at
  the price of re-hashing everything whenever the password changes.
- The bytes travel and are stored separately as a **blob**: AES-256-GCM
  under `key_sync`, AAD `"blob:" + id` (so a blob served under another id
  fails authentication), plaintext verified against the id after decryption.
  Two devices encrypting the same file produce different ciphertexts (fresh
  nonces); either decrypts to the bytes the id names, so the first to reach a
  node is as good as any and a second copy is discarded.
- **Every node's blob store is its `file` table**, read by hash: any row
  holding that content can serve it. A row with a hash and **null content**
  is a reference this node has applied but not fetched yet.

**Applying** a reference: if the bytes are already local — this device
attached the same file elsewhere, or originated it — they resolve without a
fetch. Otherwise the change is recorded at its origin timestamp (LWW sees it
as any other change) and the row waits. **After every exchange**, a node asks
the node it just exchanged with for the blobs it is waiting on; a blob that
node lacks, or that fails to decrypt or verify, stays missing and is asked for
again on the next exchange with anyone. Nothing here can fail a sync — only
leave an attachment for later, which the UI reports as *not downloaded yet*.

**Fetching** is chunked, resumable and bounded:

- A blob is pulled with HTTP `Range` reads, default 512 KB at a time. A node
  that does not implement ranges answers 200 with the whole blob, which the
  requester takes as the complete answer — so there is nothing to negotiate
  and nothing to fall back from. The embedded peer server does implement
  them, holding one ciphertext per blob for the length of a transfer: every
  encryption draws a fresh nonce, so slices of two encryptions would not join.
- A blob is one AES-256-GCM box and can only be verified whole, so chunks
  accumulate as ciphertext in `blob_fetches` and are decrypted once at the
  end. Persisting rather than buffering is what makes a transfer resumable
  across exchanges *and* restarts. A join that does not decrypt means the
  pieces did not come from one ciphertext; the partial is discarded and the
  blob retried once from the start.
- Each exchange spends at most an **attachment budget** (32 MB by default)
  before leaving the rest for later — a phone joining a large notebook is no
  longer held up downloading every attachment in it before the sync reports
  done. A transfer already under way finishes rather than being abandoned, so
  a single attachment larger than the whole budget still arrives.
- **Opening** an attachment that has not arrived fetches it there and then,
  ignoring the budget, from the relay. That is the other half of the bound:
  what you ask for comes now, what you have not asked for comes eventually.

**Uploading**: a packet that references blobs is uploaded only after the
blobs are (`HEAD` first, so a blob is sent once, not once per packet naming
it), and declares them in `X-Noo-Blobs`. The relay **refuses** (409) a packet
whose declared blobs it does not hold. That refusal is the invariant
everything else rests on: *a stored packet's blobs are stored*, so a pulled
reference always resolves at the relay, and a blob no stored packet declares
is safe to collect. A carrier that lacks a carried packet's blob stops
carrying that stream at that packet (contiguity forbids skipping); the origin,
or a carrier with the bytes, delivers it instead.

**Compaction** publishes the snapshot's references the same way, so the blobs
of current attachments survive the prune and the blobs only superseded
packets referenced go with them — the relay collects unreferenced blobs after
every prune and reports them in `pruned_blobs`. A device still missing
attachments cannot compact: its snapshot would declare blobs it cannot
supply. A snapshot does not declare the content of an attachment whose bytes
this device has collected (below): the deletion is what has to propagate, and
declaring a blob we cannot serve is precisely what the relay refuses.

**Collecting, on a device.** A device's blob store is its `file` table, and
compaction is where it releases one: the bytes of a soft-deleted attachment
are dropped and the `blob:<hash>` reference kept, leaving the row in the same
shape as a reference that has not been fetched yet — so restoring the
attachment simply makes it missing again and the next exchange refetches it.
Two rows are spared: one with no hash, whose bytes nothing could name
afterwards, and one whose hash a live attachment still shares.

Because the bytes only come back from another node, a device refuses to
collect unless everything it has to say is already on the relay — no history
above the push watermarks, and no stored packet above the relay's vector.
Past both, the 409 invariant runs the other way: our packets are all up
there, so their blobs are too, and every collected blob is refetchable for as
long as those packets live. A LAN-only device collects nothing, having no
node that carries that guarantee.

**What changes in size.** A packet is now a few KB regardless of what is
attached; a full-state snapshot is the database *minus* attachments; the
relay and every device store each distinct attachment once, not once per
packet; and re-attaching or re-sending an existing file costs a 64-character
reference. Local storage drops from three copies of every attachment
(`file.content`, its packet's ciphertext, its `history_file` row) to two —
the history row still carries the base64 bytes, a separate item.

## 4. Cryptographic envelope

As v1 (`RELAY_PROTOCOL.md` §5) with two changes.

### 4.1 Key derivation

Two keys, both derived fresh per sync cycle from the database password:

```
key_sync = HKDF-SHA256(ikm=utf8(db_password), salt=utf8(username), info="noo-sync-v2", len=32)
key_peer = HKDF-SHA256(ikm=utf8(db_password), salt=utf8(username), info="noo-p2p-v2",  len=32)
```

- `key_sync` encrypts packets (as v1). The new info string makes v2 a new
  crypto epoch: v1 blobs are not decryptable with v2 keys and vice versa
  (see migration, §11).
- `key_peer` is used **only** for peer discovery fingerprints and peer
  authentication (§9.3, §9.4). It never encrypts content, so a break of the
  peer-auth usage cannot expose packet keys.

### 4.2 Blob format and AAD

```
wire blob = nonce (12) || AES-256-GCM ciphertext || tag (16)
plaintext = gzip(utf8(SyncPacket v2 JSON))
aad       = utf8(origin_device_id + ":" + counter)
```

V1 bound only the origin device; v2 binds the **full identity**. A blob
re-served under any other `(device, counter)` fails authentication. Combined
with slot-once application (§5.2), this closes v1's known replay limitation
(`RELAY_PROTOCOL.md` §10): stale blobs can no longer be re-applied at all,
rather than merely being harmless under LWW.

## 5. The packet store (every node)

### 5.1 Schema

Clients add a table to the local (SQLCipher) database; the relay reshapes its
`changes` table. Logically identical on both:

```
sync_packets(
  origin_device_id TEXT,
  counter          INTEGER,
  payload          BLOB,     -- wire blob, verbatim as received/created
  payload_hash     TEXT,     -- sha256(payload), lowercase hex (§3.3)
  stored_at        TEXT,     -- local receive/creation time, UTC (informational)
  PRIMARY KEY (origin_device_id, counter)
)
```

- Payloads are stored **verbatim ciphertext** — never re-encrypted — so any
  copy on any node is byte-identical and AAD-verifiable. On clients the
  database file itself is SQLCipher-encrypted, as all local data already is.
- A node's **version vector is derived state**: `max(counter)` per
  `origin_device_id`, raised by any snapshot coverage the node has adopted
  (`P2P_SYNC_COMPACTION.md` §4.1) — a pruned range is *known*, not held.
- The store is append-only under the protocol, with one exception: a node may
  discard packets a full-state snapshot covers (v2.1 compaction, see
  `P2P_SYNC_COMPACTION.md`). It replaces v1's server-only history; the cost is
  that **every node holds the ciphertext log above the last snapshot**
  (this is what enables relay-free bootstrap and gossip).

### 5.2 Insertion rule (all nodes)

An incoming packet `(d, n)` is stored iff:

1. the slot `(d, n)` is not already occupied, and
2. `n == vector[d] + 1` (with `vector[d] = 0` when unknown) — i.e. packets
   are accepted **in order per origin device**, keeping holdings contiguous.
   Out-of-order arrivals are rejected; the sender violated §6.3 and the gap
   will be re-fetched next exchange.

An occupied slot is not one outcome but two, told apart by the stored hash
(§3.3) *[impl]*:

- **same bytes → duplicate**, a silent no-op; the same packet arriving by
  more than one path is expected and is what the slot rule is written for;
- **different bytes → conflict**, the origin device has forked its own
  stream. What is already stored stands (neither copy can be preferred from
  here), and the collision is recorded as a skipped packet — which also
  blocks compaction, since this node's state is demonstrably not the merge of
  everything in the log. It is *not* thrown: the fork belongs to the origin
  device, which detects it itself on its next sync, and refusing the exchange
  would spread one device's problem to the whole fleet.
- A slot known only through a snapshot's **coverage** has no row and no hash.
  Unknown stays a duplicate: a pruned packet is exactly one this node chose
  not to be able to compare.

The relay does **not** validate payload contents (it cannot); clients
validate at apply time (§8).

## 6. The exchange protocol (node-agnostic semantics)

The same three-step exchange runs against the relay (§9.1) and LAN peers
(§9.2); only transport framing differs.

### 6.1 Vector query

Requester fetches the responder's version vector:
`{device_id → highest counter}` for the authenticated user.

### 6.2 Pull

Requester sends its own vector (`have`) and receives packets the responder
holds above it, i.e. for every device `d` in the responder's store:
all `(d, n)` with `n > have[d]`.

### 6.3 Ordering and paging

- Within one response, packets MUST be ascending by counter **per origin
  device** (interleaving across devices is free). This preserves same-device
  causality at apply time and keeps stores contiguous (§5.2).
- Responses are paged (`limit`, `has_more` as in v1). The requester persists
  its vector **after each packet** (applied or skipped), so interruption
  resumes exactly where it stopped — the v1 per-blob cursor rule, per device.

### 6.4 Push (relay only)

The relay cannot dial clients, so clients additionally **upload**: fetch the
relay's vector (§6.1), then send every local packet the relay lacks — own
*and carried* (§7). Between LAN peers no push exists; the exchange is
pull-only and symmetric (each side pulls from the other).

## 7. Gossip rules

- A node serves and uploads **all** packets in its store, regardless of
  origin. Verbatim payloads + AAD make carried packets tamper-evident;
  a carrier cannot forge or alter another device's stream, only deliver it.
- Client uploads of carried packets let the relay converge even if the
  origin device never reaches it directly.
- No epidemic scheduling, TTLs, or rumor state: gossip is a side effect of
  the vector exchange, and the contiguity rule (§5.2) bounds what can be
  offered.

## 8. Applying packets (clients only)

### 8.1 Unchanged core

Decrypt (AAD = identity from envelope metadata) → gunzip → parse → verify
§3.2 consistency → apply each change under field-level LWW exactly as v1
(`RELAY_PROTOCOL.md` §8). Applied remote values keep origin timestamps and
are marked remote (never re-packaged). Undecryptable/corrupt packets are
skipped and logged; the vector still advances past them (v1 §7.3 rule).

Application is idempotent, so "stored" and "applied" need no separate
bookkeeping: the vector tracks both. A packet is applied when first stored;
a node that crashed between storing and applying re-applies on next sync
by comparing the persisted **applied-vector** (the `sync_applied_v2` JSON
property *[impl: one JSON map rather than the draft's per-device
properties]*) against the store (`SyncService.applyBacklog`).

### 8.2 Orphan retry (the one semantic delta from v1)

V1's global sequence guaranteed that an entity's creation appeared in the
stream before any other device's edits to it. Per-device streams do not
order across devices, so an edit can arrive before its entity's creation
(e.g. one peer transfer interrupted, the other completed).

V1 §8.2 already *skips* updates to unknown entities safely; v2 adds bounded
retry so they are not lost:

```
sync_orphans(
  entity_type, world_id, field, value, timestamp,
  is_creation, parent_world_id,
  first_seen TEXT,
  PRIMARY KEY (entity_type, world_id, field)
)
```

*[impl: the draft also carried `origin_device_id, counter` provenance columns;
dropped — the change content is self-sufficient for retry and the provenance
was purely diagnostic.]*

- A change skipped for a missing entity (or missing required owner — files,
  timeline) is upserted here, keeping the **newest** timestamp per
  entity+field.
- After every sync exchange, all orphans are re-applied through the normal
  LWW path; successes are deleted.
- Orphans older than **30 days** (`first_seen`) are dropped — by then the
  missing creation is presumed permanently lost, and v1 semantics (skip)
  apply.

Same-device causality needs no orphan handling: §6.3 ordering guarantees a
device's own creation precedes its own edits.

### 8.3 Conflict copies (LWW + conflict copy)

Field-level LWW silently discards the losing side of a concurrent edit.
When the loss is user-written text — a task's `title` or `content` — the
losing value is preserved as a **conflict copy**: a new sibling task named
`<title> (conflict <local date/time>)`, created as an ordinary local task so
it records history and syncs everywhere by the normal path. Structural
fields (`parentId`, `orderId`, `flags`) and file/timeline fields still
resolve by plain LWW.

A copy is made only for a *concurrent* edit — the sender must not have seen
the value being discarded. A newer edit made on top of an already-synced
value never produces a copy. The causal test:

- Each packet carries the sender's applied `vector` (§3.2).
- Each device keeps a **push log**: for each own packet counter, the highest
  task-history row id it packaged (`sync_push_log(counter,
  task_history_id)`).
- The sender of an incoming packet had seen local history row `r` iff
  `r ≤ push_log[max counter ≤ vector[me]]`. `vector[me] = 0` means the
  sender saw nothing of ours. A packet with no vector (pre-upgrade sender),
  or a vector pointing below the oldest push-log entry, falls back to the
  conservative test "was `r` packaged before this cycle began" — which still
  catches the common offline-edit case and never fires on long-synced
  values.

Exactly **one** device in the fleet creates each copy, so convergence
cannot duplicate it:

- **edit-vs-edit** — created on the device owning the *winning* value, when
  the losing change arrives and loses LWW to a history row that is
  local-origin and sender-unseen (only on the winner's origin device is the
  winning row local-origin). The copy preserves the losing **remote**
  value; identical values never trigger. On the losing edit's own device
  the winning change simply overwrites (no copy there — the winner's device
  makes it), and everywhere else the winning row is remote-origin.
- **delete-vs-edit** — created on the device owning the unseen local edit,
  when a winning remote `removed=1` arrives (only there are the edit's
  history rows local-origin). The deletion still applies; the copy carries
  the local `title`/`content` (soft delete keeps the row readable). The
  copy is placed under the original's parent, or at root when the parent
  was deleted with it.

Copies are queued per entity while a packet applies (so `title` and
`content` losses in one packet fold into one copy) and materialized inside
the packet's transaction. Reapplying a packet cannot re-create a copy: after
the first application the conflicted field's latest history row is
remote-origin, so the trigger no longer matches. `full_state` packets
(§3.2) never produce copies — a stale echoed value losing LWW is not a
concurrent edit.

## 9. Transports

### 9.1 Relay API v2

Auth endpoints (`/auth/register`, `/auth/login`, `/auth/refresh`), JWT
handling, and device registration are unchanged from v1 (`RELAY_PROTOCOL.md`
§3). Change endpoints are replaced (base path `{serverUrl}/api/v2/`):

| Method | Path | Body / params | Success | Notes |
|--------|------|---------------|---------|-------|
| GET | `/changes/vector` | — | 200 `{vectors: {device_id: counter, ...}}` | The relay's vector for the user |
| GET | `/changes/` | `have=<url-encoded JSON vector>`, `limit` (1–1000, default 100) | 200 `{changes: [...], has_more}` | Ascending per origin device (§6.3) |
| POST | `/changes/` | raw blob; headers `X-Noo-Origin-Device`, `X-Noo-Counter` | 201 stored / 200 already-held | 409 on §5.2 order violation; 413 over size limit |
| GET | `/changes/hashes` | `device`, `from`, `to` | 200 `{hashes: {"<counter>": "<sha256 hex>"}}` | *[impl]* Stream verification, §3.3. Stored counters only; range capped at 500 and clamped, not rejected |
| PUT | `/blobs/{id}` | raw encrypted blob | 201 stored / 200 already-held | *[impl]* §3.5. Idempotent; 413 over `NOO_MAX_BLOB_SIZE` (default 64 MB) |
| HEAD | `/blobs/{id}` | — | 200 / 404 | *[impl]* "Do you hold this?" before uploading |
| GET | `/blobs/{id}` | — | 200 raw bytes / 404 | *[impl]* Scoped to the caller's account |

`POST /changes/` additionally takes `X-Noo-Blobs: <id>,<id>,…` — the blobs the
packet references; 409 when any is not held (§3.5). Pull responses are
unchanged: a puller learns a packet's references by decrypting it.

Pull response element:

```json
{
  "origin_device_id": "<uuid>",
  "counter": 17,
  "payload": "<base64 wire blob>",
  "stored_at": "2026-08-01T12:00:00Z"
}
```

Server data model: `users` (drop `next_sequence`), `devices` unchanged,
`changes` reshaped per §5.1 (plus `user_id`), `device_cursors` dropped —
the admin dashboard reads per-device vectors instead.

Removed v1 semantics: global `sequence`, "exclude own uploads" (the vector
makes it structural: a device's `have` already covers its own stream), and
server-side cursors.

### 9.2 Peer API (LAN)

Each client embeds a minimal HTTP server (`PeerSyncServer`, plain `dart:io`
*[impl: no `shelf` dependency needed]*), bound on an ephemeral port, serving:

| Method | Path | Params | Success | Notes |
|--------|------|--------|---------|-------|
| POST | `/peer/v2/auth/start` | `{device_id, nonce_a}` | 200 `{device_id, nonce_b, proof_b}` | Server proves itself first, §9.4 |
| POST | `/peer/v2/auth/complete` | `{device_id, nonce_a, proof_a}` | 200 `{session}` | Caller proves itself, gets a token |
| GET | `/peer/v2/vector` | — | 200 `{vectors: {...}}` | Requires session |
| GET | `/peer/v2/changes` | `have`, `limit` | 200 `{changes, has_more}` | Same shape and rules as relay pull |
| GET | `/peer/v2/hashes` | `device`, `from`, `to` | 200 `{hashes: {...}}` | *[impl]* Same shape and rules as the relay's, §3.3 |
| GET | `/peer/v2/blobs/{id}` | — | 200 raw encrypted bytes / 404 | *[impl]* §3.5. Served from the peer's `file` table, encrypted for the wire on the way out |
| POST | `/peer/v2/sync-request` | `{port}` | 202 `{status}` | *[impl]* Asks the peer to pull from us in turn, §9.5 |

- Pull-only and symmetric: on contact, each side runs the §6 exchange as
  requester against the other. No peer push endpoint.
- Plain HTTP is acceptable: payloads are ciphertext end-to-end; what leaks
  on the LAN (vectors, sizes, timing, device ids) is the same metadata class
  the relay already sees. TLS may be added later without protocol changes.

### 9.3 Discovery

*[impl: UDP broadcast is the implemented mechanism (`PeerDiscovery`); mDNS is
future work — the `nsd` package lacks Linux support, and broadcast covers the
current desktop targets with zero dependencies.]*

- **UDP broadcast** on port **46630**: broadcast probes
  `NOO2P|<fp>|<device_id>|<tcp_port>`, answered unicast with
  `NOO2A|<fp>|<device_id>|<tcp_port>` (announces are never answered — that
  would loop). *[impl: discovery runs only during a Sync P2P session
  (§10.1), so probes repeat every 2 s and peers age out after 10 s unheard —
  someone is watching the device list fill in.]*
  If the well-known port is taken (another Noo instance on the same host),
  the instance binds an ephemeral port instead: it still probes the
  well-known port and learns peers from unicast replies, while the
  well-known listener learns *it* from the probe's source address.
- `fp = hex(HMAC-SHA256(key_peer, "noo-fp"))[:16]` — devices sharing
  username **and** database password compute the same fingerprint, so peers
  of other accounts (or wrong-password devices, which could not sync anyway)
  are filtered before any connection, and neither username nor any key
  material is broadcast.
- **mDNS** (`_noo-sync._tcp.local`, TXT `did`/`fp`/`pv=2`): planned addition
  for networks where broadcast is filtered.
- Discovery is advisory only — every discovered peer must still pass mutual
  authentication (§9.4).

### 9.4 Peer authentication

Mutual challenge-response over `key_peer` (§4.1); the database password
never leaves the device, and possession of `key_peer` is the pairing — no
ceremony, no additional secrets:

```
A → B : device_id_A, nonce_a (16 random bytes)          POST /auth/start
B → A : device_id_B, nonce_b (16 random bytes),
        proof_b = HMAC(key_peer, "resp" | nonce_a | nonce_b | device_id_B)
A → B : proof_a = HMAC(key_peer, "init" | nonce_a | nonce_b | device_id_A),
        device_name_A (advisory, for B's device list)   POST /auth/complete
B → A : session (opaque token, 10 min TTL)
```

A verifies `proof_b` (and that `device_id_B` matches what discovery claimed)
**before** sending its own proof — a rogue host that answered discovery
learns nothing but a random nonce. Subsequent requests carry
`Authorization: Noo-Session <session>`; an expired session gets one
transparent re-auth and retry. Distinct `"init"`/`"resp"` labels prevent
reflecting a proof back to its author; proof comparison on the server is
constant-time. A failed proof terminates the exchange; the peer is retried
no sooner than the next discovery cycle.

### 9.5 Reciprocal sync request *[impl]*

LAN exchanges are pull-only (§9.2), so a device that pulls from its peer ends
up holding the peer's data while the peer still lacks its own. With automatic
exchange that self-corrects on the next cycle; with **user-initiated sync only**
(§10.1) there is no next cycle, and one exchange would converge only one side.

`POST /peer/v2/sync-request {port}` closes the loop: after pulling, the
initiating device asks its peer to pull back.

```
A → B : pull (§6 exchange, A now holds B's packets)
A → B : {port: <A's peer server port>}        POST /peer/v2/sync-request
B → A : 202 accepted                          (answered immediately)
B → A : pull (§6 exchange, B now holds A's packets)
```

- **Requires a session**, like any other data endpoint; the session is bound
  to the device that proved itself for it, so the receiver knows who asked.
  `port` is carried explicitly so B can reach A even if discovery has not
  seen A yet; the address is taken from the connection, never from the body.
- **Answered before the exchange runs.** The response means "accepted", not
  "done" — A must not block on B's pull.
- **Never chains**: an exchange performed *because of* a sync-request does
  not send one back. That single rule is what keeps two devices from
  ping-ponging requests forever.
- It carries no data and grants no new access: it asks the peer to do what
  it could already do at any moment with the key it already holds.

### 9.6 Consent *[impl]*

Holding `key_peer` proves a device is ours. It does not establish that the
person in front of *this* device wants to sync right now — so neither device
syncs unless its own user asked: the peer server and discovery exist only
while that user has **Sync P2P** open (§10.1). A device outside a session
neither broadcasts, answers probes, nor accepts connections, so there is
nothing to confirm: a peer that authenticates with us can only do so because
both users opened the dialog.

*[Superseded: an earlier implementation ran discovery and the peer server
continuously, had the receiving device's user confirm every inbound handshake
(Allow/Deny, 403 on deny, 45 s timeout) and offered "Always allow" backed by a
`lan_trusted_peers` property. With on-demand sessions the prompt asked a
question both users had already answered, and all of it was removed. A stale
`lan_trusted_peers` property in an old database is ignored.]*

`device_name` from `/auth/complete` labels the peer in the Sync P2P device
list, falling back to the device id. It is advisory — outside the proof — but
only a device already holding the key ever gets to state one.

## 10. Client sync cycle (v2)

Packaging is **decoupled from transmission** — v1's "one blob per cycle,
watermarks advance on upload success" becomes "package locally, then
gossip":

1. **Package** (local, no network): collect history rows above the v1
   per-table watermarks, coalesce per entity+field, resolve full values
   (v1 §7.2 rules unchanged) → build one SyncPacket v2 → assign
   `counter = ++sync_packet_counter` (persist counter first) → encrypt →
   insert into own packet store. Watermarks advance **here** — the packet is
   durably stored locally, so transmission failure can no longer lose or
   duplicate changes. Packaging runs at the start of every sync trigger
   (relay timer, manual relay sync, a Sync P2P exchange); an empty history
   delta packages nothing.
2. **Exchange with relay** (when reachable): pull (§6.2) → apply (§8) →
   push (§6.4).
3. **Exchange with each authenticated LAN peer**: pull → apply, then ask the
   peer to pull from us (§9.5). *[impl: the reciprocal request replaces "the
   peer pulls from us on its own cycle" — with manual-only LAN sync there is
   no such cycle.]*
4. **Orphan retry** (§8.2), then sync-log/UI summary as v1 §7.4.

Relay and peer exchanges are independent and may interleave across cycles;
the store's insertion rule and vector state make any interleaving safe.
Non-reentrancy per remote node is kept (one exchange per node at a time).

### 10.1 Mixed-mode policy

- **LAN**: ~~opportunistic and aggressive — sync on peer appearance and on a
  short timer (default 30 s) while any peer is visible. It is free and fast.~~
  *[impl: **user-initiated only**, working like the relay's manual sync.
  Nothing on the LAN runs until the user opens **Tools → Sync P2P...**
  (Shift+F5). That dialog is the session: it starts the peer server and
  discovery (`LanSyncCoordinator.startSession`), and closing it stops both.
  Every device found during the session is synced with automatically — the
  other device is only findable because its user opened Sync P2P too, which is
  the consent (§9.6). Each exchange pulls and then asks the peer to pull back
  (§9.5). To keep both sides from starting at once, the device with the lower
  id leads; the other waits 4 s for the leader's sync-request and starts its
  own exchange only if none arrived (covering a broadcast that reached one
  side only). The dialog lists each device with its state (found, syncing,
  synced with N changes, failed) and offers *Sync Again* for edits made while
  it stays open. Carrying a phone into the same room as a desktop moves no
  data and exposes no socket — being on the same network is not consent, and
  neither is holding the key.]*
- **Relay**: existing auto-sync timer and manual sync, unchanged. The relay
  remains the durability anchor and the only off-LAN path.
- No preference logic between paths: whichever delivers a packet first wins
  the no-op race; the other is deduplicated by §5.2.

*[impl: the two paths now differ in autonomy on purpose — the relay is a
service the user configured and pointed at, while a LAN peer is whatever
happens to be in range. The relay's auto-sync interval is still honoured; it
never triggers a LAN exchange.]*

### 10.2 Sync log *[impl]*

Every run is recorded in two local tables, `sync_log_runs` and
`sync_log_events` (schema v14), shown in the **Sync Log** window (File menu,
or *Show Full Log* in Sync Details). The log is diagnostics only: never
synced, never history-tracked, and writing it can never fail a sync.

- **Runs**: one per relay sync, LAN exchange (`lan`, or `lan-return` when a
  peer asked for it), peer session served by this device (`lan-serve`),
  compaction, identity reset, on-demand attachment fetch and standalone
  packaging. Each run records both vectors at the start, its outcome, and
  counts. A run still `running` when the process ends is marked
  `interrupted` at the next start.
- **Events** carry the packet identity `(origin device, counter)` and the
  ciphertext hash (§3.3), so the same packet can be followed from `packaged`
  and `pushed` / `packet-served` on one device to `packet-stored` on another.
  Change events carry entity, field, both timestamps and a value fingerprint
  (first 16 hex digits of the SHA-256 of the value) plus a short preview.
  Attachment content is shown only as a blob reference or a size.
- **Decisions** are logged per change: `applied`, `created`, `lww-lost`,
  **`lww-tie`** (warning; see §8.1 in `RELAY_PROTOCOL.md`), `orphaned`,
  `orphan-expired`, `conflict-copy`, `cycle-to-root`, `parent-missing`,
  `ignored`, `unknown-field`, `blob-pending`. Packet-level problems are logged
  too: `decode-failed`, `apply-failed`, `packet-diverged`, fork and
  stream-hash results.
- **Full-state packets** only count their routine changes (`applied`,
  `created`, `lww-lost`, `blob-pending`, `change-out`); anything else is
  still logged one event at a time.
- **Rollback**: events are buffered and written after each packet commits. A
  packet whose transaction rolls back drops its change events and leaves a
  single `apply-failed` event.
- **Retention**: 30 days or 200 runs, whichever limit is reached first,
  pruned when a run starts.

## 11. Migration from v1

Single-user deployment makes this a clean epoch break — no dual-protocol
compatibility layer. *[impl: client side runs automatically via the schema
v5→v6 migration, which creates the new tables, deletes v1 sync properties,
and sets `sync_v2_repackage_needed`; the next sync performs step 3. Server
side, `init_db` drops the v1 `changes`/`device_cursors` tables on first v2
start.]*

1. **Relay**: deploy v2 server; drop v1 `changes`/`device_cursors` and
   `users.next_sequence` (destructive — v1 history is not carried over; the
   full current state is re-packaged in step 3). Auth tables survive.
2. **Clients**: update to v2; on first v2 run, reset `sync_last_sequence`
   and v1 watermarks, initialize `sync_packet_counter = 0`, create the
   packet store.
3. **Full re-package**: each device packages its entire current database as
   creation changes carrying the entities' **existing latest history
   timestamps** (not `now()`), so LWW across devices resolves exactly as it
   would have under v1. All devices re-packaging is safe: same values →
   convergent no-op merges; different values → normal LWW.
4. Old v1 blobs (if any survive anywhere) are undecryptable under
   `noo-sync-v2` and are skipped by the standard corrupt-blob rule.

The full re-package operation is written once and kept: it is also the
recovery path for counter-regression forks (§3.3) and the packet v2.1
compaction publishes as its snapshot (`P2P_SYNC_COMPACTION.md`).

## 12. Known limitations and future work

- **Packet-log growth is bounded only when someone compacts.** v2.1 adds
  snapshot packets and pruning (`P2P_SYNC_COMPACTION.md`), but the trigger is
  a user pressing *Compact data on server* — nothing compacts on its own, and
  a fleet that never does still grows without bound. Since §3.5 it grows with
  edits only, not with attachments, which removes the largest term.
- **Blob fetch depends on the relay for ranges.** Chunking, resumption and
  the per-exchange budget are in (§3.5), and the embedded peer server serves
  `Range`; whether the *relay* does is up to the relay, and one that does not
  still answers with the whole blob — correct, but a large attachment over a
  bad connection then has no partial to resume from.
- **A restored attachment can outlive its blob.** Device-side collection
  (§3.5) drops the bytes of a deleted attachment and keeps the reference,
  betting the relay still holds the blob. Undelete after the relay has pruned
  it leaves an attachment that is *not downloaded yet* and never will be.
- **Compaction discards edit history below the snapshot**, on every node, and
  can lose a conflict copy that the covered packets would have raised
  (`P2P_SYNC_COMPACTION.md` §6).
- **LWW still trusts device clocks** (v1 §10 unchanged).
- **HKDF from the raw password remains unstretched** (v1 §10 unchanged);
  key strength is password strength.
- **Peer metadata leaks on the LAN**: fingerprints, device ids, vectors,
  packet sizes/timing — the LAN-local analogue of what the relay sees.
- **No peer-to-peer bandwidth control**: a fresh device bootstrapping a
  large history over LAN pulls it in one paged exchange.
- **Fork recovery is one button, not automatic** (§3.4): the mechanism is
  implemented end to end, but a confirmed divergence still waits for the user
  to press *Reset device identity*, because the recovery is visible to the
  whole fleet. The far commoner case — a restore that lost history without
  re-issuing anything — needs no button and heals on the next sync.
- **The old stream is never reclaimed.** After a re-identity the retired
  device's packets stay on the relay and on every node until someone compacts,
  and its name stays in the storage list.
- **LAN sync requires full sync configuration** (including relay settings) —
  relay-less LAN-only operation is a wiring change in the providers, not a
  protocol limitation.
- Battery/lifecycle policy for the embedded peer server on mobile
  (Android port, `ANDROID_PORT.md`) is deliberately unspecified here.

## 13. Versioning

- `SyncPacket.version = 2`; HKDF info `noo-sync-v2` (packets) and
  `noo-p2p-v2` (peer auth/discovery); relay base path `/api/v2/`; peer base
  path `/peer/v2/`; discovery TXT `pv=2`. These move together.
- Any future format change bumps all of the above; v2 receivers gate on
  `version` (unlike v1 parsers) and skip-and-log unknown versions.
- The stream-hash query (§3.3) is **additive and unversioned**: it changes no
  packet, envelope or vector, and a node that does not implement it answers
  404, which callers read as "cannot verify". Client and relay can therefore
  be deployed in either order.
- Attachment blobs (§3.5) bump only `SyncPacket.version` (2 → 3); the HKDF
  info strings, envelope, AAD scheme and base paths are unchanged. **Deploy
  the relay first**: a v3 client uploading to a relay without `/blobs/` cannot
  push any packet that references one. Clients then update together, since a
  v2 client skips v3 packets.
