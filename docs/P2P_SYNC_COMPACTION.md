# Noo Sync Protocol v2.1 — Log Compaction

> Companion to [P2P_SYNC.md](P2P_SYNC.md). Section numbers are referenced
> from code comments on both the client and the relay, so they are kept
> stable. This document describes what is implemented; where the client and
> relay sources are cited, they are the authority.

The v2 packet log (`P2P_SYNC.md` §5) is append-only: every node keeps every
packet it has seen above the last snapshot, and the relay keeps every packet
anyone uploaded. Storage therefore grows with the number of *edits*, forever,
even when the outline itself does not. Compaction is the one exception to
append-only: a device publishes a **full-state snapshot** of its current
database and declares which packets that snapshot supersedes; the relay
deletes those, and every other device drops its own copies as it applies the
snapshot. Current state is untouched — what is discarded is the record of
individual past edits below the snapshot.

---

## 1. Design overview

- **A snapshot is an ordinary packet.** It travels, is stored, is verified
  and is applied by the same rules as every other packet (`P2P_SYNC.md`
  §3–§8). It is the v2 *full-state re-package* (§11.2) with `full_state:
  true`, carrying creation changes for every task, attachment and time
  record (soft-removed ones included, so deletions propagate) at their
  **existing latest history timestamps**, so ordinary LWW resolves exactly as
  it would have without it.
- **Coverage is declared, not inferred.** The uploading client tells the
  relay which `(device, counter)` ranges the snapshot makes redundant, in the
  `X-Noo-Snapshot-Covers` header. The relay cannot read the payload, so it
  trusts the declaration — a client can already corrupt its own account by
  lying about counters — and bounds its blast radius (§4.3).
- **Pruning never lowers "what comes next".** Both the relay and every device
  keep a per-device **high-water mark** independently of the packets they
  store, so a stream emptied by pruning continues at its old counter instead
  of restarting at 1 and forking itself (§4.1, §4.3, rule 4).
- **Nothing compacts on its own.** The trigger is the user pressing
  **Preferences → Sync → Server storage → Compact data on server**
  (`sync_settings_form.dart`). The same panel reports what the account
  occupies on the relay per origin device (`GET changes/usage`).
- **The relay is the only thing that prunes on declaration.** A device drops
  packets only after it has *applied* the snapshot that covers them (§4.1).

---

## 2. Terminology

| Term | Meaning |
|---|---|
| **snapshot** | A packet with `full_state: true`; its changes are the sender's whole current database |
| **coverage** | `{device_id → counter}`: the packets the snapshot supersedes — everything of each device at or below that counter |
| **baseline** | On a device: the coverage it has adopted, kept in the `sync_v2_baseline` property (`NooDatabase.getSyncBaselineVector`) |
| **mark** | On the relay: `stream_marks.high_water`, the highest counter ever accepted for a device, kept whether or not the packet is still stored (`store.StreamMark`) |
| **vector** | A node's `{device → highest counter known}` = `max(stored, baseline)` on a device (`NooDatabase.getSyncVector`), `max(stored, mark)` on the relay (`store.UserVector`) |
| **prune** | Deleting the packets a coverage declaration names |
| **adopt** | A device raising its baseline to a snapshot's coverage after applying it |

---

## 3. The snapshot packet

The packet is built by `SyncChangePackager.buildFullStateChanges` and
packaged by `SyncService._packageLocalChanges` when the
`sync_v2_repackage_needed` property is set. Three things set it: the v1→v2
migration, `recoverFromFork` (§3.4 of `P2P_SYNC.md`), and `compactRelay`.
Only the last declares coverage; the first two publish the same packet as an
ordinary addition to the stream.

What the snapshot carries:

- **Every entity, every field, as a creation change**, timestamped with the
  field's latest history row (falling back to the row's own timestamp).
  Receivers apply it under LWW like any other packet; a value they already
  hold at an equal or newer time is a no-op.
- **The sender's applied vector** (`SyncPacket.vector`): what it had applied
  when it packaged. This is what coverage is derived from (§4.3).
- **Attachment content as `blob:<sha256>` references** (`P2P_SYNC.md` §3.5),
  never bytes. A snapshot is the database *minus* attachments. A soft-deleted
  attachment whose bytes this device has collected is published without a
  `content` change at all (`_canPublishContent`): the deletion is what has to
  propagate, and a reference the sender cannot serve would be refused.
- **Its own counter is `max own counter + 1`**, like any packet. Compaction
  does not restart the stream.

Receivers suppress conflict copies while applying a snapshot
(`_applyingFullState`): a stale value echoed back by a re-announce is not a
concurrent edit.

---

## 4. Protocol

### 4.1 Adoption (devices)

`SyncService.adoptSnapshotCoverage(packet)`, called from
`_applyPacketBlob` **after** the snapshot has been applied — never on a
declaration alone. It:

1. Takes the packet's `vector` as the coverage, and raises the sender's own
   entry to `counter − 1`: a device's snapshot always supersedes its own
   earlier packets, whatever its vector says.
2. **Caps this device's own entry at what it actually stores**
   (`maxStoredSyncCounterFor`). Taking a sender's word for our own counters
   would mask a fork (`P2P_SYNC.md` §3.3): a restored backup must still be
   caught by `_checkForFork` rather than quietly resuming above its own lost
   history.
3. Merges the result into the baseline (`mergeSyncBaselineVector` — never
   lowering an entry, so re-applying the same snapshot is free).
4. Advances the **applied vector** to the coverage for every device in it:
   coverage implies the state is applied, whether or not this node ever held
   the packets. Otherwise `applyBacklog` would hunt for packets that are gone.
5. Deletes the covered packets from the local store (§4.4).

The baseline is what makes a pruned stream *known* rather than *held*: a
device's vector is `max(stored, baseline)` (`getSyncVector`,
`maxSyncCounterFor`), its insertion rule (`storeSyncPacket`) accepts a packet
as "next" relative to that, and a slot below the baseline is a **duplicate**
— a pruned packet is exactly one the node chose not to be able to compare,
so it has no hash and raises no conflict (`P2P_SYNC.md` §5.2).

A device that has adopted coverage for a stream it never held any of will
accept that stream from the first counter above the coverage. This is how a
fresh device bootstraps from a compacted relay, and how a device that was
offline through a compaction catches up (§8.2).

### 4.2 Pull ordering

A snapshot is self-sufficient: it is applied where it lands, and its
coverage then admits the rest of every covered stream. A packet *above* a
pruned range, on the other hand, is a gap to a device that has not adopted
the coverage yet, and the insertion rule refuses it. So the order a page is
served in matters:

- **The relay puts snapshot-bearing streams first** (`store.Pull`): `ORDER BY
  MAX(is_snapshot) OVER (PARTITION BY origin_device_id) DESC,
  origin_device_id, counter`. The hoist is per *stream*, not per row —
  sorting rows by `is_snapshot` would lift a snapshot above the lower
  counters of its own device and break the ascending-per-device order the
  pull promises (`P2P_SYNC.md` §6.3). After a prune a snapshot is already its
  stream's lowest stored counter, so `counter ASC` puts it first on its own.
  `is_snapshot` is set from the coverage header on upload, and raised on an
  already-held slot when a later upload declares it (a carrier delivers a
  snapshot without the declaration; the origin's later upload still counts).
- **A LAN peer does not hoist.** `NooDatabase.getSyncPacketsAboveVector`
  serves streams in store order with one cross-device limit, and the client
  stores no snapshot flag. The pull side compensates instead:
- **Within a page**, `SyncService.pullFromSource` keeps the packets the store
  refused for contiguity and retries them once the page is through, as a
  snapshot elsewhere in the page may have admitted them. A snapshot that
  arrives as a gap is decoded, applied and adopted first, then stored
  (`_ingestPacketInner`).
- **Across pages**, a page that stored nothing is not the end of the
  exchange. If the source reports more, the requester asks past everything
  that page offered (a separate *ask* vector that runs ahead of its real
  one) and keeps paging; as soon as a page does store something — a
  snapshot, typically — it asks again from what it actually holds, so the
  packets it had to leave behind are re-offered and now accepted. A page
  that stores nothing with nothing beyond it is a genuine gap, left for the
  next exchange. The loop terminates because every round either stores
  something or asks strictly further ahead. The cost is re-fetching the
  deferred pages once per snapshot found, over the LAN.

So the invariant is: **a device converges within one exchange whichever
order the source serves**, and the relay's hoist is an optimisation that
makes the common case cost one page.

### 4.3 Upload and prune (relay)

`SyncApiClient.uploadPacket(snapshotCovers: …)` sends the snapshot like any
packet (`POST /api/v2/changes/`, `X-Noo-Origin-Device`, `X-Noo-Counter`,
`X-Noo-Blobs`) plus `X-Noo-Snapshot-Covers: {"<device_id>": <counter>, …}`.
The relay (`uploadPacket` in `changes_handlers.go`, `store.InsertPacket`,
`store.PruneCovered`):

1. Rejects a header that is present but not a JSON object (a literal `null`
   included) — a declaration that says nothing is a bug, not a no-op.
2. Refuses the packet if any **declared** blob is missing (409 `Missing
   blobs`), before anything else: the prune below releases the covered
   packets' blob declarations, and only the snapshot's own declaration keeps
   the live blobs alive.
3. Applies the storage limits (`checkPacketStorage`), counting the bytes the
   prune will free (`store.CoveredBytes`) against the user's quota, so a
   snapshot is never refused for space it is about to return.
4. Inserts the packet under the ordinary contiguity rule, flagged
   `is_snapshot`. An already-held slot is a no-op *that still prunes*, so a
   client whose 201 was lost in transit reclaims the space on retry.
5. **Prunes**: for each `(device, upTo)` declared — clamped to `counter − 1`
   for the uploading device (the snapshot itself is never pruned), to the
   stream's mark (nothing above what it holds), and skipped entirely for a
   device it has never held anything for (a claim about an unknown device
   must not seed a mark) — it **re-asserts the mark first**, then deletes
   `packets` and `packet_blobs` at or below `upTo`, then collects every blob
   no stored packet declares any more (`collectBlobs`).
6. Answers `{"stored": true|false, "pruned": {"pruned_packets", "pruned_bytes",
   "pruned_blobs", "pruned_blob_bytes"}}`. A relay too old to know the header
   stores the packet and says nothing about pruning; the client reports the
   compaction as unsupported rather than failed (`CompactionResult.relaySupported`).

**Marks.** `stream_marks.high_water` is raised on every accepted packet and
re-asserted before every prune, and is never lowered. The relay's vector
(`UserVector`) and its contiguity check (`StreamMark`) both read it, so a
stream pruned to nothing still expects its old counter + 1. This is rule 4
of §7 and what the test-suite's fake relay calls "(§4.3, safety rule 4)".

### 4.4 Local prune (devices)

`NooDatabase.deleteSyncPacketsUpTo(device, upTo)` deletes a device's packets
at or below `upTo`, and is called only from `adoptSnapshotCoverage` after the
baseline has been raised (§4.1). The compacting device runs the same adoption
over its own snapshot (`_compact` → `adoptSnapshotCoverage`), so it reclaims
its own store too. Neither path touches the snapshot packet itself.

`deleteSyncPacketsFrom` is the opposite end of the stream for the opposite
reason — fork recovery discards packets whose *identity* belongs to other
content — and is not part of compaction.

---

## 5. The client-side operation

`SyncService.compactRelay`:

1. **Syncs first** (`performSync`). A snapshot must be packaged from a fully
   applied state (§7, rule 3), and a failed sync fails the compaction.
2. **Checks the blockers** (`_compactionBlocker`, §8.1) — before anything is
   packaged, because a snapshot that is packaged and then cannot be uploaded
   would sit in the own stream ahead of every later packet.
3. **Packages** by setting `sync_v2_repackage_needed` and calling
   `packageLocalChanges`. Packaging is serialised under a lock; if a LAN peer
   pulling from this device packaged first and took the re-package with it,
   the packet handed back is not a snapshot and the compaction stops
   ("Another sync packaged first") — declaring coverage for a delta packet
   would authorise deleting state nothing else carries.
4. **Derives coverage** from the packet's vector, with the own stream set to
   `counter − 1` and zero entries dropped.
5. **Puts the snapshot's blobs on the relay** (`_ensureBlobsOnRelay`,
   `HEAD` then `PUT`) and declares in `X-Noo-Blobs` exactly those it could
   put there (§8.3 for the ones it could not).
6. **Uploads** with `X-Noo-Snapshot-Covers`.
7. **Adopts its own coverage** (§4.1, §4.4) and reads the relay's usage for
   the report (`CompactionResult`: snapshot counter, changes, bytes; relay
   and local packets/bytes freed; `relaySupported`).

The whole operation is logged as one `compaction` run in the sync log.

---

## 6. What is lost

- **Edit history below the snapshot**, on the relay and on every device that
  adopts it: intermediate values, and who changed what when. Local
  `history_*` tables are not touched — they are what the device's own
  packaging reads — only the ciphertext log is.
- **A conflict copy that the covered packets would have raised**
  (`P2P_SYNC.md` §8.3). A device that was offline through the compaction
  applies the snapshot instead of the individual packets, and a snapshot's
  values are applied as full-state re-announces, with conflict copies
  suppressed. An edit made offline that a covered packet would have collided
  with is resolved by plain LWW instead.
- **Nothing of current state.** Every value a covered packet carried is in
  the snapshot at the same or a newer timestamp, or was superseded by one.

---

## 7. Safety rules

1. **A snapshot carries original timestamps**, never `now()`, so LWW across
   devices resolves as it would have without it.
2. **Coverage never exceeds what the packager had applied.** It is derived
   from the packet's own applied vector, and the own stream from its counter.
3. **A snapshot is packaged only from a fully applied state**: no stored or
   relay-held packet this device has not applied, no packet it had to skip,
   no local edit it has not packaged (§8.1). Otherwise it would declare
   coverage of packets it never merged — authorising their deletion while
   carrying nothing of them.
4. **Marks are never lowered.** A prune re-asserts the stream's mark before
   deleting, and the next counter of every stream is derived from the mark
   (relay) or from `max(stored, baseline)` (device), never from `MAX(counter)`
   over what happens to be stored.
5. **The snapshot itself is never pruned**, nothing above the declared
   coverage is touched, and nothing above what the relay actually holds.
6. **A snapshot can supply every blob it declares.** The prune releases the
   covered packets' declarations; the snapshot's own declaration is what keeps
   the live blobs on the relay. A device still waiting for an attachment is
   refused compaction (§8.1); a blob the relay has refused is referenced but
   not declared (§8.3).
7. **Own-stream coverage is capped at what is stored locally** when adopted
   from another device's snapshot, so a restored backup is still detected as
   a fork rather than resuming above history it lost.
8. **Pruning on a device follows applying**, never a declaration alone.

---

## 8. Failure modes

### 8.1 Compaction blockers

`_compactionBlocker` refuses, in this order, when:

- this device has **skipped packets** this session (undecryptable, unparseable,
  or a slot held by different bytes — `P2P_SYNC.md` §5.2): its state is
  demonstrably not the merge of everything in the log;
- it has **unsynced local edits** (`hasPendingLocalChanges`);
- it is **missing attachment bytes** (`missingBlobHashes` — references
  applied whose blobs have not arrived; collected, soft-deleted rows do not
  count). Its snapshot could not supply them, and the prune would collect
  them on the relay (rule 6);
- its **applied vector is behind** its own store's vector or the relay's for
  any device: packets exist it has not merged (rule 3).

Each is reported in `CompactionResult.error` with what to do ("Sync again,
then compact", "Sync until every attachment has downloaded").

### 8.2 A device offline during compaction

It holds packets the relay has since pruned, and its vector is below the
snapshot. On its next sync:

- its **own stream** is unaffected: it holds all of its own packets, the
  relay's mark for it is unchanged, and it pushes from the mark (§6.4).
- it **pulls the snapshot first** (the relay hoists it, §4.2), applies it as
  a gap packet (`_ingestPacketInner` → `_applyDecodedPacket` →
  `adoptSnapshotCoverage`), drops its own copies of the covered packets, and
  then accepts the rest of every covered stream above the coverage.
- edits it made while offline were packaged into its own stream before the
  pull (`performSync` packages, then pushes, then pulls), so they are not
  covered by the snapshot — its own entry in the coverage is whatever the
  compacting device had applied, which is below them — and they reach the
  fleet as ordinary packets, resolved by LWW against the snapshot's values.

A device running a client **older than v2.1** cannot adopt coverage and
cannot accept a stream that no longer starts at the counter it expects; it
sees a permanent gap. This is why the compaction dialog asks the user to
update every device first, and why nothing compacts automatically.

### 8.3 Attachments the relay refuses

A blob over the relay's size limit is refused with 413 and will never be
there. Under the original rule — a packet is uploaded only once every blob it
references is — that packet, and every later packet of the same stream
(contiguity), could never go up, including the `removed` change that deleted
the attachment, which sat *behind* the packet that wedged the stream. And a
compaction snapshot, or an identity reset, re-declared the same blob and
wedged the new stream the same way.

The rule now (`_ensureBlobsOnRelay`): the relay refuses only a packet whose
**declared** blobs it lacks — it cannot read payloads, so an undeclared
reference is simply one it does not know. A refused blob is therefore **left
out of `X-Noo-Blobs` and the packet goes up without it**; the reference stays
in the payload. Receivers already treat a reference they cannot resolve as
*not downloaded yet* and ask every node they exchange with (`P2P_SYNC.md`
§3.5), so the bytes still reach other devices over Sync P2P, whose peer blob
endpoint has no limit. The run reports it (`SyncResult.warning`, naming the
attachment and the relay's limit; the sync status shows it as an error so it
is not read as "synced"), the blob is not re-sent during the session, and a
carried packet with the same blob is uploaded the same way.

What is weakened: "a stored packet's blobs are stored" holds for *declared*
blobs only. A device that fetches the reference from the relay gets a 404
and retries on every exchange (one `HEAD`/`GET` per missing blob per
exchange). Device-side collection (`collectRemovedBlobs`) still assumes the
relay holds every blob of every uploaded packet; after deleting a refused
attachment and collecting, no node may hold its bytes any more — the
"restored attachment can outlive its blob" limitation of `P2P_SYNC.md` §12.

A blob **missing on this device** — a carried packet whose attachment has
not reached us, or an own full-state packet forwarding a reference whose
bytes have not arrived — still stops that stream at that packet for the run
(null from `_ensureBlobsOnRelay`): the origin, or a carrier with the bytes,
delivers it. In the own stream that is reported as a block
(`SyncResult.ownStreamBlocked`, with the attachment named), and it clears
itself once the bytes arrive from another node.

### 8.4 A stream the relay cannot continue (409)

The relay answers `409 Non-contiguous counter N; next expected M` when an
upload's counter is above its mark + 1. After compaction a device holds a
stream only from the snapshot (or from above adopted coverage) up; if the
relay's mark for that stream is then *below* that — the relay was restored
from a backup taken before the compaction, or re-created — nothing the device
holds can bridge the gap, and every later upload of that stream would be
refused the same way. `pushToRelay` recognises it (`SyncApiException
.isNonContiguous`), both from the vector before uploading and from the
relay's answer, and:

- for a **carried** stream, logs it, stops carrying that stream for the run
  and continues with the next; the pull is unaffected. The origin device, or
  a carrier that still holds the range, delivers it.
- for this device's **own** stream, throws `SyncStreamGapException` — the
  same class of error as a fork (`P2P_SYNC.md` §3.3–§3.4), with the same way
  out: **Preferences → Sync → Reset device identity**, which republishes the
  whole database as one snapshot under a fresh identity. The run fails, so
  the user sees it.

### 8.5 What the relay cannot verify

The relay trusts the coverage declaration. A client that declares coverage
for packets its snapshot does not actually contain destroys that history for
its own account — the same trust the protocol already places in a client's
counters and payloads. Rule 2 and rule 3 are enforced on the client, which is
the only place they can be.

---

## 9. What shipped

- **Client**: `SyncService.compactRelay`, `_compact`, `_compactionBlocker`,
  `adoptSnapshotCoverage`, `pullFromSource` (deferral within and across
  pages), `pushToRelay` (gapped streams, undeclared refused blobs);
  `NooDatabase.getSyncBaselineVector`, `mergeSyncBaselineVector`,
  `getSyncVector`, `maxSyncCounterFor`, `maxStoredSyncCounterFor`,
  `deleteSyncPacketsUpTo`, `syncPacketStorage`; `SyncApiClient.uploadPacket`
  (`snapshotCovers`), `getUsage`; UI in `sync_settings_form.dart` (Server
  storage, Compact data on server) and the compaction run in the sync log.
- **Relay**: `packets.is_snapshot`, `stream_marks`, `packet_blobs`;
  `store.InsertPacket`, `PruneCovered`, `CoveredBytes`, `Pull` ordering,
  `UserVector`/`StreamMark`; `X-Noo-Snapshot-Covers` on `POST
  /api/v2/changes/`, `pruned` in its response, `GET /api/v2/changes/usage`.
- **Tests**: `client/test/data/sync_service_test.dart`, group `compaction`
  (publish/prune, pruned stream continues, out-of-order and multi-page
  snapshots, blockers, 409 handling), and group `attachment blob store`
  (snapshot declarations, collected devices, refused blobs).
