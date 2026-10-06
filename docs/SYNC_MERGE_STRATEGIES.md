# Sync merge strategies: what Noo does and why

When two devices edit the same note before they have seen each other's change,
something has to decide what the note says afterwards. This document records
the options that were weighed in October 2026, what Noo chose, and how that
compares with other well-known systems. The protocol itself is specified in
[P2P_SYNC.md](P2P_SYNC.md) (§8.3 conflict copies, §8.4 merging); this is the
reasoning behind it.

## 1. What a packet carries: full values, not diffs

A sync packet carries the **full current value** of every changed field
(`SyncChange.value`), resolved per field by last-writer-wins (LWW). Diffs exist
only in local history storage and never cross a device boundary.

The alternative is operation-based sync, where a packet carries a diff.

### What full values give

- **Every packet stands alone.** It needs no earlier packet to be applied, so
  it can arrive late, out of order, twice, or forwarded by a third device, with
  the same result. Per-device streams, LAN forwarding and the relay all rely on
  this.
- **Convergence is simple.** LWW on (timestamp, value) is a total order, so
  every device ends at the same value whatever order it applied things in.
- **Compaction is trivial.** A snapshot is just the current values; dropping
  the packets below it loses history, never state
  ([P2P_SYNC_COMPACTION.md](P2P_SYNC_COMPACTION.md)).
- **Backup restores are recoverable.** *Reset device identity* republishes
  current values and everyone merges them by ordinary LWW (§3.4).
- **Errors don't spread.** A bad value is overwritten by the next good one. A
  bad diff would damage every version built on top of it, on every device.
- **Coalescing works.** Ten edits since the last sync become one value.
- **The relay stays dumb.** It stores opaque blobs and never validates a chain.

### What full values cost

- **Size grows with the note, not with the edit.** One character changed in a
  40 KB note sends 40 KB. Gzip, coalescing, and keeping images and attachments
  out of `content` (they are blob references) keep this small in practice.
- **Concurrent edits to one note don't merge by themselves.** With LWW alone
  one side wins outright. This was the real problem, not the bandwidth.

### What diffs would give, and what they would cost

Diffs would give small packets and the *possibility* of merging. They would
cost:

- **Each diff needs its exact base.** That requires causal, gap-free delivery,
  which a multi-path, forwarding, compacting protocol does not guarantee.
- **Order-dependent results.** diff-match-patch applies patches fuzzily, and
  two concurrent patches applied in different orders can silently produce
  different text on different devices. Guaranteed convergence needs OT or a
  CRDT (§3), not plain patches.
- **Text-diffing Delta JSON can produce invalid JSON.** A safe merge has to work
  on Quill Delta operations, not on the stored string.
- **Compaction, fork detection and conflict copies would all need redesigning.**
- **A fallback to full values is needed anyway** for a patch that fails to
  apply, so both paths would exist.

**Decision:** keep full values as the foundation, and add merging *on top* of
them only where a concurrent edit is detected. Packets stay self-contained and
LWW stays the safety net.

## 2. What Noo does (1.2.13)

Three measures, each covering what the one before cannot:

| # | Measure | Where | What it handles |
|---|---------|-------|-----------------|
| 1 | **Sync while editing**: sync ~10 s after local edits stop, and on opening a note or the app returning, at most every 30 s; 2 min backoff after a failure. Relay only, on by default | `QuickSyncScheduler` (`presentation/providers/quick_sync.dart`) | Makes concurrent edits *rarer*: most come from changes sitting unsynced on two devices for minutes |
| 2 | **Editor merge**: the editor's save three-way merges its unsaved text with a change that landed while it was typing | `NooDatabase.saveEditedContent` | A sync or an MCP agent rewriting the note that is open on this device |
| 3 | **Sync-time merge**: the device holding the winning value merges the losing concurrent edit instead of keeping it as a conflict copy | `SyncService._mergeConcurrentContent`, P2P_SYNC.md §8.4 | Two devices editing the same note offline |

Both merges use `mergeContent` (`core/utils/content_merge.dart`). It diffs
base→local and base→remote as Quill Deltas, applies the remote change and
transforms the local one over it (`Delta.diff` / `transform` / `compose`).
Quill's own OT is reused here as a three-way merge rather than a live operation
stream. It **refuses**, and the old conflict copy is made instead, when:

- the two edits touch overlapping text;
- one side inserts where the other replaced text;
- both insert at the same point mid-sentence;
- any side is not Delta JSON (legacy HTML rows).

Two additions at the end of one line are put on separate lines.

For the sync-time merge, each content change carries an optional `base`: a hash
of the content its sender last exchanged (table `sync_content_bases`, schema
v15). The receiver looks for that base in its own history and merges only if
its value is that base plus edits made locally. Nothing is ever worse than
before: whenever a merge is not provably sound, the result is the §8.3 conflict
copy.

What is unchanged: titles, delete-vs-edit and full-state packets still resolve
by LWW plus a conflict copy, and all non-text fields by plain LWW.

## 3. The landscape: known approaches and implementations

From general knowledge as of October 2026. Check a project's own documentation
before relying on a detail.

### CRDTs: conflict-free by construction

Every character (or element) has a unique identity, so concurrent edits always
merge, with no base and no conflicts. The costs are per-element metadata that
grows the stored document, and a storage format of their own.

- **Yjs** (JavaScript): the most widely used. It has editor bindings including
  Quill (`y-quill`), ProseMirror, CodeMirror and Monaco. **Yrs** is its Rust port.
- **Automerge** (Rust core, JavaScript and other bindings): a JSON-like document
  model with full history.
- **Loro** (Rust): newer, with rich-text support and a focus on performance.
- **Diamond Types** (Rust): a fast text CRDT.
- **Apple Notes** syncs notes over iCloud with a CRDT.
- **Dart**: `crdt` / `sql_crdt` exist but provide LWW maps and tables, not text.
  No mature Dart text CRDT is known; using one would mean binding Yrs or Loro
  over FFI.

### Operational transformation (OT)

Operations are transformed against concurrent ones so they can be applied in any
order. This usually needs a central server to order operations.

- **Google Docs**: OT through a central server.
- **ShareDB** (Node.js): OT with a server, often paired with Quill.
- **Quill Delta** (`compose` / `transform` / `diff`): an OT toolkit. Noo's
  `mergeContent` is built on it.

### Three-way merge from a common base

Diff base→ours and base→theirs, combine them, and report a conflict where they
overlap.

- **git** and `diff3`.
- **Obsidian Sync** is understood to merge Markdown three-way with
  diff-match-patch. It is the closest note-app equivalent to Noo's approach, but
  the details are unverified.

### Full values with LWW and conflict copies

Keep one side, and save the other where the user can find it.

- **Joplin** and **Standard Notes**: a separate "conflicted copy" note.
- **Dropbox**: "conflicted copy" files.
- **CouchDB / PouchDB**: keep every conflicting revision and let the
  application choose.
- **Figma**: per-property LWW through a central server, a design it has
  described as inspired by CRDTs.

### Where Noo sits

Noo combines the last two families. Packets carry full values with LWW as the
safety net, as Joplin-style systems do, and a three-way merge built on Quill's
OT runs only when a concurrent edit is detected, as git and Obsidian Sync do.
The CRDT libraries are the "never conflicts" end of the range.

## 4. Why not a CRDT, and when to reconsider

Not now, because:

- it would replace the storage format of `tasks.content` and the history,
  search and export paths built on it;
- per-character metadata grows the database and every snapshot;
- there is no mature Dart implementation, so it would need an FFI binding to a
  Rust library on every platform;
- it would break compatibility with the Qt client;
- compaction ([P2P_SYNC_COMPACTION.md](P2P_SYNC_COMPACTION.md)) would have to understand CRDT history.

Reconsider if real-time co-editing (two people typing in one note at once) or
sharing between users becomes a goal. The three-way merge suits one person on
several devices; it is not built for keystroke-level collaboration.

## 5. Known limits and possible next steps

- **The losing device briefly shows the other version.** Only the winner's
  device merges, so the device whose edit lost LWW shows the winning version
  until the merge arrives on a later sync. Possible fix: make the merge a pure
  function of (base, A, B, device priority) and run it on both devices; they
  then write identical values, which never conflict.
- **A base from a third device may not be found.** If the sender's base is a
  value the receiver never held, the receiver falls back to a copy.
- **Titles are not merged.** They are short and usually rewritten whole, so LWW
  plus a copy is kept on purpose.
- **Sibling order** (`orderId`) is still plain LWW. Fractional indexes would
  remove concurrent-insert conflicts if they become a problem.
