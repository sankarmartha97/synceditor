# SyncEditor — Architecture & Scaling Discussion

A saved record of a working session covering: how SyncEditor works end-to-end, how Postgres/Redis relate, why full-JSON saves are a scaling risk, a SaaS-oriented target architecture, how the current save mechanism actually works (including two real gaps found in the live code), what breaks at 100MB, and how to redesign the editing pipeline to avoid it.

Companion files produced during this session:
- `SYNCEDITOR_FLOW_GUIDE.html` — single-file, self-contained architecture + animated flow trace (open directly in a browser).
- `ARCHITECTURE.md` — pre-existing backend architecture doc (describes the unused `backend/src` TypeScript scaffold, not the live `src-js`).

---

## 1. What is this project, and what's the complete application flow?

SyncEditor is a real-time collaborative canvas/page editor (Figma/Miro-style) — Flutter frontend, Node.js/TypeScript-and-JS backend, built for multiple users to co-edit visual layouts with widgets simultaneously.

### Stack
- **Backend**: Express + TypeScript/JS, Socket.IO for real-time sync, PostgreSQL (persistent data, JSONB page documents), Redis (presence/active users), JWT auth, Zod validation.
- **Frontend**: Flutter with `flutter_bloc`, `dio` for HTTP, `socket_io_client`, `hive` for local storage.

### Important structural note
There are **two parallel implementations on both sides**, and only one of each is actually live:
- **Backend**: `backend/src` (TypeScript) is a simpler, legacy scaffold — not run by default. `backend/src-js` (plain JS) is what `npm run dev`/`start` actually boots (`package.json` → `main: "src-js/server.js"`). `src-js` has the real feature set: JSON-Patch sync, OT, undo/redo, comments/mentions, follow mode. `ARCHITECTURE.md` documents the `src` version, so it's already slightly out of date against what's running.
- **Frontend**: the `features/canvas/*` module (canvas_bloc, canvas_service, sync_service, plain `websocket_client.dart`) is an older widget-based editor. `main.dart` never wires up `CanvasBloc` — only `AuthBloc` and `PageBloc` are provided, and the app boots straight into `PageDashboard`. So `canvas/*` is effectively dead code; the live path is entirely `features/page/*`.

### 1. App boot (Flutter)
`main.dart` initializes Hive (local DB) and registers adapters for `User`, `PageModel`, `PageWidget`, etc., then renders based on `AuthBloc`:
- `AppStarted` → `AuthService.loadSavedAuth()` checks Hive/storage for a saved JWT.
- Authenticated → `PageDashboard`. Otherwise → `LoginScreen`.

### 2. Auth
- Login/register hits `POST /api/auth/login` or `/register` (`auth.controller.js`) — bcrypt password check, JWT issued (`{userId, email}`), returned to client.
- `AuthService` stores the token (Hive) and sets it on `ApiClient` (dio) for the `Authorization: Bearer` header on every future REST call.
- The same JWT is later handed to Socket.IO as `handshake.auth.token` for the realtime connection.

### 3. Dashboard → opening a page
`PageDashboard` calls `PageBloc` → `LoadPages` → `GET /api/pages` (REST, permission-filtered by `page_permissions`). Selecting a page triggers `LoadPage`, which:
1. Fetches the page (currently a plain network call — see the "save mechanism" section below for why the caching layer isn't actually active) — `GET /api/pages/:id` returns the full `page_data` JSONB blob (widgets, metadata).
2. Navigates to `PageEditorScreen`, which connects the WebSocket (`PageWebSocketClient.connect()`, authenticated with the JWT) and emits `page:join`.

### 4. Joining the page (realtime)
Server-side, `page.handler.js` `PAGE_JOIN`:
1. Verifies access (`pages` + `page_permissions`, owner or explicit grant).
2. `socket.join('page:<id>')`, records the socket's `pagePermission` (owner/edit/comment/view).
3. Upserts a row in `active_editors` (Postgres) and writes presence info + a deterministic per-user color (`getUserColor`) into Redis (`page:<id>:users`).
4. Replies `page:joined` with the current `page_data`, `version`, permission, and the active-user list; also sends initial undo/redo availability (`page:undo:state`).
5. Broadcasts `page:user:joined` to everyone else in the room.

### 5. Editing a widget (the core sync loop)
This is JSON-Patch based with server-side Operational Transformation, not per-widget websocket events:
1. User drags/resizes/edits a widget.
2. `PageBloc` mutates local `pageData` optimistically, then `PatchService.generatePatch(oldData, newData)` diffs old vs new state into RFC-6902 JSON Patch ops.
3. `_sendPatchAndClearSync` emits `page:patch` with `{pageId, patches, clientVersion}`.
4. Server (`PAGE_PATCH` handler):
   - Checks `pagePermission` is `owner`/`edit` (read-only users get `page:patch:error`).
   - Loads current `page_data`/`version` from Postgres.
   - If `clientVersion !== serverVersion` (someone else edited meanwhile), it fetches the intervening patches and runs `otService.transformPatch(...)` to rebase the incoming patch against them.
   - Applies the (possibly transformed) patch, writes new `page_data` + incremented `version` back to `pages`, and logs patch history.
   - Computes an inverse patch (`undoRedoService.generateInverse`) and saves it to an operation history table, pushing it onto that user's per-page undo stack.
   - Emits `page:patch:applied` back to the sender and `page:patch:received` to everyone else in the room, who apply the patch to their local copy.

### 6. Undo/Redo
`page:undo`/`page:redo` pop the user's operation-history stack, transform the inverse operation against any operations that happened concurrently since (via OT again), apply it, bump the version, and push a corresponding entry onto the redo/undo stack — then broadcast like a normal patch (flagged `isUndo`/`isRedo`).

### 7. Presence: cursors & selection
- Mouse movement → `page:cursor` → server stores position in Redis (`page:<id>:cursors`, 30s TTL) and rebroadcasts `page:cursor:updated` with the user's name/color to everyone else.
- Widget selection → `page:selection` → broadcast as `page:selection:updated` so others see a name label on the selected widget.

### 8. Follow mode (Figma-style)
- `page:follow:start {targetUserId}` stores the follow relation in Redis (`page:<id>:follows`, 1h TTL), rejects self-follow and mutual-follow, and returns the target's last known viewport.
- The followed user's client periodically emits `page:viewport:update`; the server looks up who's following them and pushes `page:viewport:updated` only to those followers' sockets.
- On the frontend, `state.isFollowing` flips the whole editor into read-only mode: widget library hidden, drag/select/drop disabled (`canEdit && !state.isFollowing` gate).

### 9. Comments & mentions
`comment:create/update/delete/resolve` events go through `commentsService`, persist to a comments table, broadcast to the page room, and separately push a `comment:mention` event directly to any `@mentioned` user's socket(s) if they're online.

### 10. Leaving / disconnect
`page:leave` or a raw socket `disconnect` removes the `active_editors` row and Redis presence/cursor entries, leaves the Socket.IO room, and broadcasts `page:user:left`.

### 11. Persistence summary
- **Postgres**: `pages` (JSONB `page_data` + `version`), `page_permissions`, patch/version history, `active_editors`, operation-history table for undo/redo, comments, users. Legacy `canvases`/`widgets`/`widget_versions` tables still exist for the deprecated relational model.
- **Redis**: ephemeral only — active users per page, cursors (30s TTL), follow relationships (1h TTL), viewports (30s TTL). Nothing here is a source of truth.
- **Hive (frontend)**: local cache of pages/users for instant load and offline access, intended to be driven by `PageCacheService`/`OfflineQueueService`/`DraftAutoSaveService` — though see the save-mechanism section below for why these aren't actually wired up yet.

### Worked example (Alice & Bob)
An 11-step traced example — Alice opens the page, joins, Bob joins, Alice edits a widget (patch + version bump), Bob follows Alice, Alice's viewport syncs to Bob, live cursor, Alice undoes, Bob unfollows, Bob comments and @mentions Alice, Alice disconnects — was built as an animated, playable simulation with real event names and payload shapes taken directly from `page.handler.js` and `page_bloc.dart`. See `SYNCEDITOR_FLOW_GUIDE.html` (section "Watch it happen") for the interactive version.

---

## 2. "I don't understand how Postgres and Redis are connected"

**Short answer: they aren't connected to each other at all.**

Postgres and Redis are two completely separate, independent connections that both terminate at the Node.js server:
- `database.js` opens a `pg` connection pool to Postgres on port 5432.
- `redis.js` opens a separate `ioredis` client to Redis on port 6379.

They never call each other, reference each other, or sync data between themselves. There's no replication, no shared driver, no pipe between them. The only thing that talks to both is the server code — it's the one place that decides "this piece of data goes to Postgres" or "this piece of data goes to Redis," based on one rule: **does this need to survive / be queryable later, or is it just "right now" state?**

| Goes to Postgres | Goes to Redis |
|---|---|
| `page_data` (the actual widgets/layout) | who's currently viewing the page |
| `page_permissions` (who owns/can edit) | live cursor positions (expire in 30s) |
| patch/undo history | who's following whom (expires in 1h) |
| comments | last known viewport per user (expires in 30s) |

In the `PAGE_PATCH` handler, one function does both, one after the other, with no interaction between the two calls:

```js
// 1. Write to Postgres — durable, permanent
await pool.query(`UPDATE pages SET page_data = $1, version = $2 WHERE id = $3`, ...);

// 2. Separately, elsewhere, write to Redis — temporary, auto-expiring
await redis.hset(`page:${pageId}:users`, socket.userId, JSON.stringify(userData));
```

If Redis crashed right now, nobody would lose their page content — you'd just lose the "who's currently online" list, and it'd rebuild itself as people rejoin. If Postgres crashed, Redis has nothing that could recover it — presence data isn't a backup of anything.

**Mental model**: not "Postgres and Redis sync with each other" but "the server picks one of two mailboxes for each piece of data, and never cross-checks them."

---

## 3. "Then whenever I change anything, does the full page data update every time — I mean the full JSON?"

**Yes — every single edit rewrites the entire `page_data` JSON blob in Postgres, not just the changed field.**

**What's small:** what travels over the wire from the Flutter client. `PatchService.generatePatch` diffs old vs. new local state and produces a tiny JSON Patch like:
```json
[{ "op": "replace", "path": "/widgets/3/position", "value": {"x": 180, "y": 96} }]
```

**What's full:** what happens on the server when that patch arrives:
```js
const clonedData = JSON.parse(JSON.stringify(data));   // clone the ENTIRE page_data
const result = applyPatch(clonedData, patches);         // apply the tiny patch to the clone
// result.newDocument is now the FULL page object, patched

await pool.query(
  `UPDATE pages SET page_data = $1, version = $2 WHERE id = $3`,
  [JSON.stringify(result.data), newVersion, pageId]      // writes the WHOLE JSON back
);
```

So the write is `UPDATE pages SET page_data = $1` — a plain column overwrite of the entire JSONB value, not a targeted `jsonb_set(page_data, '{widgets,3,position}', ...)` that would touch only that one key. Every widget, every property, the whole document gets re-serialized and rewritten on every single patch, even if you only nudged one rectangle by one pixel.

Separately, the *tiny* patch (not the full doc) also gets inserted as its own row into a `page_patches` table — that's what OT and undo/redo replay against later, and it's genuinely incremental.

**Practically this means:**
- Network traffic: cheap (only diffs travel over the socket).
- Database writes: expensive-ish — a page with 200 widgets gets its entire 200-widget JSON rewritten for a single-pixel move.
- No row-level locking/contention advantage from JSONB partial updates — Postgres still has to write the whole value and bump `updated_at`/`version` on the full row each time.

---

## 4. Options for the JSON growing over time (before "SaaS" framing)

Ordered by effort vs. payoff:

### Option 1 — Cheapest fix: targeted `jsonb_set` instead of full overwrite
```sql
UPDATE pages
SET page_data = jsonb_set(page_data, '{widgets,3,position}', $1::jsonb),
    version = version + 1
WHERE id = $2
```
**Honest caveat:** Postgres still writes a whole new row version under the hood (MVCC). What this actually saves is the Node-side full-document `JSON.stringify`/`JSON.parse`/clone on every edit, and payload size sent to Postgres. Worth doing, but not the real fix for "the document keeps growing."

### Option 2 — Batch/debounce rapid edits
A drag can fire a patch per animation frame. Buffer patches per page for ~200–400ms server-side and coalesce them into one write instead of N.

### Option 3 — The real fix: split widgets out of the blob
```sql
widgets (id, page_id, type, position, size, properties, parent_id, updated_at)
```
Moving one widget becomes `UPDATE widgets SET position = $1 WHERE id = $2` — a tiny, constant-cost write regardless of page size. `pages.page_data` shrinks to just page-level metadata.

**This schema already exists in the codebase** — it's the "legacy" `canvases`/`widgets` tables. The old model was per-row widgets; the newer "Pages" architecture regressed to one JSONB blob per page. This is reverting a design decision that already existed, not inventing a new one.

### Option 4 — Event-sourced writes
`page_patches` is already an append-only log. Stop writing `page_data` synchronously on every patch — append to `page_patches` only (cheap), and materialize `pages.page_data` as a periodically-refreshed snapshot (timer-based or on next stale read), similar to how `DraftAutoSaveService` already debounces saves conceptually on the frontend.

### Option 5 — Full CRDT (Yjs)
Already listed in `ARCHITECTURE.md`'s Future Improvements. Same idea Figma/Linear/Notion use — state as a CRDT, edits as tiny binary deltas, persistence as periodic snapshots. Subsumes OT entirely but is a genuine rewrite of the sync layer.

**Recommendation at the time:** do #2 first (quick, low-risk), then #3 (matches a pattern already proven in the legacy schema). Save #4/#5 unless real scale problems demand them.

---

## 5. "It's a SaaS product, think accordingly, and give me the suggestion"

Reframing: for a SaaS, the cost isn't "one page's JSON is big" — it's **(bytes written) × (edits per minute) × (number of tenants), forever.** Revised, SaaS-prioritized list:

### 1. Normalize widgets out of the JSONB blob — before there's real customer data to migrate
Foundational: cost-per-edit must stay flat as pages and tenants grow. Do this before it's a live migration against real data.

### 2. Fix a horizontal-scaling bug already in the code
`page.handler.js` delivers `comment:mention` and `page:viewport:updated` by scanning `io.sockets.sockets.values()` — every socket connected to **this one Node process**. On a single instance this works. The moment more than one backend instance runs (needed for rolling deploys/uptime/scale), a mentioned or followed user on a different instance simply never gets the message — silently, no error.

**Fix:** add the Socket.IO Redis adapter (`@socket.io/redis-adapter`) — Redis is already running, this is additive.

### 3. Wire up the rate limiter that's already written but never called
`checkRateLimit()` is defined at the top of `page.handler.js` — there's even a standalone `RATE_LIMIT_CODE_TO_ADD.js` file describing exactly this — but it's **never invoked** anywhere. Right now any user (or a scripted abuse case) can spam `page:undo`/`page:redo` with zero throttling, each one triggering a DB read, an OT transform, and a full-document write.

### 4. Debounce/batch writes per page
Same idea as before, but the SaaS angle is: fewer writes = lower managed-Postgres bill (compute/IOPS-billed) and slower WAL/backup growth across *all* tenants.

### 5. Add retention on the append-only history tables
`page_patches` and the undo/redo operation history grow forever, per page, per tenant, with no pruning. Widget normalization doesn't fix this — it's a separate unbounded growth line. Policy needed up front: e.g. keep full patch history 30–90 days, compact into a snapshot, drop/archive the rest.

### 6. Connection pool sizing
`max: 20` in `database.js` is fixed per process. Fine for one instance; N instances behind a load balancer means N×20 connections hitting Postgres. Put PgBouncer (or the managed provider's pooler) in front before scaling instance count.

**Picked for "this sprint":** #2 and #3 (small, contained, real correctness/abuse gaps today). #1 scheduled next, specifically before meaningful customer data exists, since it's a one-way migration that only gets harder later.

---

## 6. Solution Architect blueprint

### Guiding principles
1. Cost-per-edit must not scale with page size.
2. Every stateful component must run behind N horizontally-scaled instances.
3. Redis is ephemeral, never authoritative — losing it should cost convenience, never data.
4. Every unbounded log gets a retention policy before real customer data hits it.
5. Tenancy is a first-class schema dimension, not bolted on later.
6. Observability ships before the scale problem does.

### 1. Target data architecture
```
pages            — id, workspace_id, name, owner_id, metadata{width,height,bg,grid}, version
                   (small, rarely rewritten)

widgets          — id, page_id, parent_id, type, position, size, properties, z_index, updated_at
                   (one row per widget — the legacy canvas/widgets shape, revived)

page_patches     — id, page_id, user_id, patch, from_version, to_version, created_at
                   (append-only op log — already exists, becomes the primary write path)

page_snapshots   — id, page_id, version, full_state, created_at
                   (periodic materialized full-document view, rebuilt from patches)

workspaces       — id, plan, quotas, created_at
                   (the tenant boundary — currently implicit/absent)
```
**Why:** identity (rarely changes), content (changes constantly, small units), and history (append-only, unbounded) each get a storage strategy suited to their behavior, instead of one blob absorbing all three costs.

### 2. Target write path
```
Client → page:patch {path, value, baseVersion}
  → server resolves target widget(s) from patch path
  → OT/conflict check against page_patches (now naturally finer-grained: most edits
    touch one widget, so conflicts are rarer and cheaper to reason about)
  → UPDATE widgets SET position=..., updated_at=now() WHERE id=$1   ← small, constant-cost
  → INSERT into page_patches (small row, append-only)
  → debounce: coalesce a drag's 30 patches/sec into ~1 write per 250ms per widget
  → broadcast to room via Redis-backed Socket.IO adapter
  → background job periodically folds page_patches into a page_snapshot
```
Every step is O(1) with respect to page size.

### 3. Real-time / horizontal scaling
- Socket.IO Redis adapter fixes the `io.sockets.sockets.values()` cross-instance bug.
- App servers become stateless behind a load balancer once the adapter is in place.
- Postgres: primary for writes, read replica for list-type reads once traffic justifies it; PgBouncer (transaction mode) before multiplying `max: 20` pools by N instances.
- Rate limiting: wire up existing `checkRateLimit()`; add a general per-connection token bucket for high-frequency events (`page:cursor`, `page:patch`).

### 4. Multi-tenancy
- Introduce `workspaces` as a real entity; every page, membership, and quota scoped to it.
- Enforce plan-based quotas server-side (max pages, max widgets/page, max collaborators, socket event rate).
- Meter usage per tenant (patches/sec, storage bytes, active collaborators) — falls out almost free once `page_patches` is authoritative.
- Postgres RLS keyed on `workspace_id` as defense-in-depth under app-layer permission checks.

### 5. Retention & lifecycle
- `page_patches`: rolling window (30–90 days or last M versions), fold into snapshot, archive/drop the rest.
- `page_snapshots`: keep latest + a few rolling checkpoints.
- Soft-deleted pages: hard-delete after a grace period (GDPR erasure obligations).

### 6. Observability & security
- Structured logs with a correlation ID spanning REST → socket → DB write (replace `console.log`/emoji logging).
- Metrics: patch throughput per tenant, OT conflict rate, undo/redo rate, connection count per instance, write latency.
- Extend `/health` to check DB/Redis reachability for orchestrated rollouts.
- Immediate flags (not roadmap): `backend/.env` is a real file sitting in the repo (secrets belong in a secrets manager); no rate limiting on `/api/auth/login` — brute-force protection is currently absent.

### 7. Phased rollout

| Phase | Scope | Risk |
|---|---|---|
| 0 | Wire up existing rate limiter, add Socket.IO Redis adapter, add write debouncing, move secrets out of `.env` | Low — no schema change |
| 1 | Add `widgets` table, dual-write (old blob + new table), backfill existing pages from `page_data` | Medium — additive only |
| 2 | Cut reads over to `widgets`; keep dual-write briefly as a safety net; verify parity | Medium — reversible |
| 3 | Stop writing widgets into the blob; `page_data` becomes metadata-only; add snapshots + retention jobs | Low once Phase 2 is verified |
| 4 | Workspaces, quotas, RLS, metering | New surface area, not a migration |
| 5 | Load-test with N instances + adapter; confirm mentions/follow/broadcast correctness cross-instance | Validation, not new code |

### What NOT to do yet
- Don't jump to full CRDT (Yjs) — widget normalization + existing OT gets the needed cost characteristics with far less risk. Revisit only if true offline-first multi-writer merges are needed beyond versioned OT.
- Don't build multi-region before there are multi-region customers — get single-region horizontal scaling (Phase 5) provably correct first.

---

## 7. "How is the current save mechanism working?"

There's no "Save" button — every edit is fire-and-forget over the socket.

1. Drag a widget → `PageBloc` mutates local state optimistically.
2. `_patchService.generatePatch(oldData, newData)` diffs old vs. new state into a JSON Patch.
3. `_sendPatchAndClearSync()` emits `page:patch` over the socket, sets `isSyncing: true`.
4. Server persists to Postgres (full-blob rewrite) and emits `page:patch:applied`.
5. `_onConfirmPatchApplied` receives the ack, updates the local version number, clears `isSyncing`.

So the "real" confirmation path exists and works. **But** there's a leftover workaround right next to it:

```dart
// Backend doesn't send patch:applied confirmation yet
// Clear syncing after delay as workaround
_syncTimeoutTimer = Timer(const Duration(milliseconds: 800), () {
  if (!isClosed && state.isSyncing) {
    emit(state.copyWith(isSyncing: false));
  }
});
```

That comment is stale — the backend does send `page:patch:applied` now. But this 800ms timer still unconditionally force-clears the "Saving…" indicator whether or not the real ack has arrived. On a slow connection the UI can say "saved" before the server has actually confirmed it.

**The real gap:** what happens if you edit while disconnected. In `page_websocket_client.dart`:

```dart
void sendPatch({...}) {
  if (_socket?.connected != true) {
    print('⚠️ Cannot send patch: Socket not connected');
    return;   // ← the patch is just dropped. Nothing else happens.
  }
  ...
}
```

If the socket isn't connected at the moment of an edit, the patch is silently discarded — no retry, no queue, no error shown. The local UI already shows the edit (optimistic update) and `isSyncing` gets force-cleared by the 800ms timer regardless, so the UI looks saved. **The edit only exists in that tab's memory and is gone on refresh.**

The infrastructure to fix this already exists and is fully written — `OfflineQueueService`, `DraftAutoSaveService`, `PageCacheService` in `core/services/` — but **none of them are ever instantiated or called anywhere outside their own files.** Verified via search: zero references from `PageBloc` or anywhere else. Dead code, same pattern as the backend rate limiter.

| Question | Current answer |
|---|---|
| Is there a manual save action? | No — every mutation auto-saves immediately via `page:patch` |
| What confirms a save succeeded? | `page:patch:applied` ack — works, but a stale 800ms timer also clears the "saving" UI regardless |
| What if the socket is down when you edit? | The edit is dropped silently. No queue, no retry, no local backup |
| Is there offline support? | Code exists for it but is never wired up |
| What about `PATCH /api/pages/:id`? | Only used for page-level metadata/rename — not part of the widget-editing save path |

---

## 8. "Is there a problem if the JSON grows to 100MB — frontend, backend, socket, Hive?"

Yes — and it breaks in **stages, long before 100MB**:

| Size reached | What breaks | Why |
|---|---|---|
| **~1MB** | Socket.IO sync stops working | `new Server(httpServer, {...})` never sets `maxHttpBufferSize` — Socket.IO's default is 1,000,000 bytes. Any single message over that gets rejected, connection can be closed, in either direction. |
| **10MB** | REST calls fail with 413 | `express.json({ limit: '10mb' })`. Any POST/PATCH body over 10MB throws `PayloadTooLargeError` before the route handler runs. |
| **~10–100MB** | Every edit starts freezing the whole server | `patch.service.js` does `JSON.parse(JSON.stringify(data))` to clone the full document on every patch application. Node is single-threaded — this is synchronous and blocks the event loop for its duration, freezing *every other page/tenant/socket on that instance*, not just the one being edited. |
| **100MB** | Frontend freezes/OOMs | `jsonDecode`/`PageModel.fromJson` runs on Flutter's main isolate by default — same blocking problem, except it freezes the UI thread. A 100MB JSON typically expands 3–5x in Dart object memory, risking a crash on mid-range phones even if fine on desktop/web. |

**Direct match to a past experience:** "POST API gives payload too large" is exactly `express.json({ limit: ... })` rejecting the body. This project has the identical middleware with the identical shape of limit (10mb, hardcoded) — the same error would reproduce here for the same reason.

**Hive, surprisingly, isn't currently a factor** — `PageBloc` never calls Hive/`StorageService` directly today; the services meant to cache full pages locally are dead code (see section 7). If that caching code is ever wired up later, a 100MB single Hive box entry would have its own read/write/compaction jank, on the same main isolate — same class of problem.

**The trap:** don't just raise the limits. Bumping `10mb` → `200mb` and `maxHttpBufferSize` up removes the fast, loud failure and replaces it with the actual bottleneck (synchronous parse/clone freezing the whole process) with no safety net — trading "fails fast" for "occasionally freezes the entire server for every tenant."

The real fix is the same one from the blueprint: if a widget lives in its own row, no single edit ever touches more than a few KB, regardless of whether the page has 20 widgets or 20,000 — the 100MB number becomes irrelevant because no single operation ever sees the full 100MB at once.

---

## 9. "How do I do the editing part with little saves and no frontend lag?"

Goal: no single edit touches, copies, diffs, or serializes anything bigger than the one widget that changed, at any layer.

### 1. Stop diffing the whole page to make a patch
Current (`page_bloc.dart`), for every edit:
```dart
final updatedWidgets = state.currentPage!.pageData.widgets.map((w) =>
  w.id == event.widgetId ? event.updatedWidget : w).toList();          // O(n) copy
final updatedPageData = state.currentPage!.pageData.copyWith(widgets: updatedWidgets);
final patches = _patchService.generatePatch(oldData, updatedPageData); // O(n) deep diff
```
You already know exactly what changed. Construct the patch directly instead of rebuilding a list and deep-diffing two whole trees:
```dart
final patch = [{'op': 'replace', 'path': '/widgets/$widgetId/position', 'value': newPos}];
```

### 2. Normalize the in-memory state, not just the database
Switch `pageData.widgets` from a `List` to a `Map<String, Widget>` keyed by widget id. Updating one widget becomes `widgets[id] = updated` — O(1) — and pairs naturally with per-widget backend rows.

### 3. Throttle what goes over the socket during continuous gestures
Update local state every frame (smooth 60fps); emit to the socket on a throttle (~100–150ms) or at drag-end + periodic checkpoints — same idea as the existing cursor-position throttle, applied to patches too.

### 4. Backend: write the row, not the document
```sql
UPDATE widgets SET position = $1, updated_at = now() WHERE id = $2   -- one small row
INSERT INTO page_patches (...)                                        -- one small append
```
No full-document clone, no full-document `UPDATE pages SET page_data = ...`.

### 5. Never put big data (images, base64) inside the JSON
Upload to blob storage, store only the URL string in `properties`. Keeps every widget row small and bounded regardless of what gets dropped onto the canvas.

### 6. Render only what's on screen
Virtualize by viewport — only build widgets whose bounding box intersects the visible canvas area (+ margin), same principle as `ListView.builder` not building offscreen items. This is the actual fix for frontend lag on large pages, separate from the data-size fixes above.

### 7. Load large pages incrementally
Once widgets are individual rows, fetch metadata + widgets in/near the current viewport first, lazy-load the rest as the user pans (spatial/bounding-box query against the `widgets` table).

### 8. Offload unavoidably heavy work off the main thread
Undo/redo snapshotting, full-page export, or anything that genuinely needs the whole document: Dart's `compute()` (a separate isolate) on the frontend, Node's `worker_threads` on the backend.

**The mental shift:** today the unit of work is "the page." After this, the unit of work is "the widget." Diffing, state update, network payload, DB write, and render all operate on one widget's worth of data, so editing cost stays flat whether the page has 20 widgets or 20,000.

**Suggested order:** #1 and #2 first (frontend-only, no schema change, immediate lag fix), then the widgets-table migration from the blueprint to unlock #4 and #7.

---

## 10. "How are Figma/Linear/Notion doing this — I saw no lag issue?"

Each solved this with a specific, deliberate architecture — not magic, and not free.

### Figma
- The document isn't JSON internally — it's an in-memory object graph where every shape/node has an ID and its own independent properties. Edits are per-property ops (`node.x = 180`), not whole-document diffs.
- The multiplayer sync server is deliberately "dumb" — it mostly relays small ops and persists them; most conflict resolution is simple last-write-wins *per property*, which works because the data model is designed so two people rarely touch the exact same field at the same instant.
- Rendering is custom (their own C++/WebGL pipeline), not "one UI-framework widget per shape." A file with 50,000 shapes still pans smoothly because only visible pixels get drawn — closer to a game engine's renderer than a widget tree.
- Persistence is an operation log + periodic snapshots, not "rewrite the whole file on every edit."

### Notion
- A page is not one JSON blob — it's a **table of blocks**, each block its own row with its own id, content, and a parent/ordering reference. Editing one paragraph touches one block record, nothing else on the page.
- Ordering uses fractional/lexicographic keys instead of array indices, specifically so reordering one block never requires touching or renumbering its siblings.

### Linear
- Built a genuine **local-first sync engine**. Every read and write happens against a local, in-browser store (IndexedDB) — the UI never waits on the network for anything. Changes queue up and sync to the server in the background; incoming remote changes stream in as small deltas and merge into the local store. This is why Linear feels instant even on a bad connection — the network is not in the critical path of "did my click register."

### The common thread — mapped onto what we already recommended for SyncEditor

| Pattern all three use | What we already recommended for SyncEditor |
|---|---|
| One row/object per item, never one big document blob | The `widgets` table (blueprint §1) |
| Tiny per-field ops, not whole-document diffs | Construct the patch directly instead of `generatePatch(oldData, newData)` (editing pipeline §1) |
| Render only what's visible, decoupled from item count | Viewport virtualization (editing pipeline §6) |
| Append-only op log + periodic snapshot, not synchronous full rewrite | `page_patches` becoming primary + snapshot job (blueprint §2, §4) |
| Local store is authoritative for the UI; network reconciles in background | The one gap SyncEditor still has — see below |

### The one gap: SyncEditor isn't local-first yet
Figma/Notion/Linear all treat the local copy as real, continuously-synced state, not a one-time fetch. SyncEditor already does optimistic local edits (good — same principle), but `LoadPage` does a plain network fetch every time a page opens, and the Hive caching layer that should make that instant (`PageCacheService`) is written but never wired up (see section 7). Wiring that up — load from local cache instantly, reconcile with server in the background, same idea as Linear's approach — is the next lever after the widgets-table migration for that specific "feels instant" quality.

**Honest caveat:** none of these are lag-free by accident. Figma shows a loading percentage on huge files. Notion visibly slows down on pages with thousands of blocks. Linear's local-first engine was a dedicated team project, not a quick patch. This is the result of real, specific engineering investment in exactly the three things already outlined for SyncEditor above — not a trick they have that SyncEditor is missing, just further along the same path.
