# Implementation Checklist — Scaling & Collaboration

**Status:** Planning
**Created:** 2026-09-27

This plan fixes three things found while reviewing the current architecture: every edit rewrites the entire page's JSON instead of just what changed, concurrent edits from two people can silently overwrite one another with no safety check, and there's no Projects layer above Pages yet. It's organized into six tracks below — Track B (normalizing widgets) is the critical path everything else improves on; Tracks D and E can run in parallel with it.

---

## Track A — Quick Wins (do first, no schema change)

- [ ] Wire the existing `checkRateLimit()` into `page:undo`/`page:redo` in `page.handler.js` — it's written but never called
- [ ] Add rate limiting on `/api/auth/login` and `/api/auth/register` — no brute-force protection today
- [ ] Add the Socket.IO Redis adapter (`@socket.io/redis-adapter`) and replace the `io.sockets.sockets.values()` lookups in `comment:mention` / `page:viewport:updated` — these only work on a single process and silently fail across multiple instances
- [ ] Move secrets out of `backend/.env`, which is currently checked into the repo
- [ ] Fix the stale `_syncTimeoutTimer` in `page_bloc.dart` — it force-clears "Saving…" after a flat 800ms regardless of whether the real server ack (`page:patch:applied`) has arrived

---

## Track B — Normalize Widgets (the critical path)

### B1 — Schema + dual-write

- [ ] Create a `widgets` table: `id, page_id, parent_id, order_key, type, position, size, properties, z_index, updated_at, updated_by`
- [ ] On every `page:patch`, write to both the old `page_data` JSONB blob and the new `widgets` table
- [ ] Write a backfill script: read each existing page's `page_data.widgets` array, insert matching rows, derive `order_key` from array order
- [ ] Verify parity on a sample of pages (reconstructed-from-widgets vs. stored blob)

### B2 — Cut over reads and the sync engine

- [ ] `GET /api/pages/:id` builds its response from `widgets`, not `page_data`
- [ ] Patch handler resolves the target widget from the patch path and applies OT/merge at the row level, reusing the existing `ot.service.js` scoped down instead of rewritten
- [ ] Writes become `UPDATE widgets SET ... WHERE id = $1 AND version = $expected` — this optimistic per-row check is what actually closes the "two people edit the same widget" race, no locking needed
- [ ] Frontend: `PageBloc`'s widget list becomes a `Map<String, PageWidget>` normalized store instead of a `List`
- [ ] Frontend: build patches directly from the known changed field instead of `PatchService.generatePatch(oldData, newData)` diffing the whole tree
- [ ] Frontend: throttle patch emission during drags/resizes, same pattern as the existing cursor throttle
- [ ] Keep dual-write running as a safety net through a burn-in period

### B3 — Retire the blob

- [ ] Stop writing widgets into `page_data`; it becomes metadata-only (width, height, backgroundColor, gridSize)
- [ ] Remove the dual-write path
- [ ] Add a `page_snapshots` table plus a background job that periodically materializes a full snapshot from `page_patches`
- [ ] Add a retention policy on `page_patches` (e.g. 30–90 days, fold into a snapshot then archive)
- [ ] Decide the fate of the currently unused `page_versions` table — build real version history on it, or drop it

---

## Track C — Collaboration Correctness (no locking)

- [ ] Confirm the per-row optimistic version check from B2 is in place — this is the actual fix, not locking
- [ ] Optional: broadcast a lightweight, purely visual "this widget is being edited by X" indicator, reusing the existing selection-broadcast/presence pattern — awareness only, never an enforced block
- [ ] Frontend: viewport virtualization — only build/render widgets whose bounding box intersects the visible canvas area, the real fix for rendering lag on large pages

---

## Track D — Frontend Resilience

- [ ] Wire up the already-written `PageCacheService` so opening a page reads from Hive first (instant) and reconciles with the server in the background, instead of today's plain network-only fetch
- [ ] Wire up the already-written `OfflineQueueService` so a dropped socket connection queues patches instead of silently discarding them — today `sendPatch` just logs a warning and drops the edit
- [ ] Decide the fate of `DraftAutoSaveService` — wire it in for real offline drafting, or drop it if the offline queue already covers the need

---

## Track E — Projects Layer

- [ ] Add a `projects` table: `id, name, owner_id, created_at`
- [ ] Add a `project_id` foreign key on `pages`
- [ ] Add a `project_permissions` table — project access grants all its pages by default, with `page_permissions` entries acting as page-level overrides
- [ ] Frontend: add a projects list screen above the current page dashboard; page creation and loading become project-scoped
- [ ] Decide and implement cascade behavior: deleting a project soft-deletes its pages, consistent with how pages already use `deleted_at`
- [ ] Later, optionally: introduce a `workspaces` table above projects for full multi-tenant plan/quota support and Postgres row-level security keyed on `workspace_id`

---

## Track F — Scale-Out Validation

- [ ] Review connection pool sizing / add PgBouncer once running more than one backend instance (today's pool max is a fixed 20 per process)
- [ ] Load test with multiple backend instances plus the Track A Redis adapter — confirm mentions, follow mode, and broadcasts route correctly across instances
- [ ] Add structured logging with correlation IDs spanning REST, socket, and DB writes, replacing today's console.log/emoji-prefixed logs
- [ ] Add basic metrics: patch throughput per page/tenant, OT conflict rate, undo/redo rate, socket connection count per instance, DB write latency
- [ ] Extend `/health` to also check DB and Redis reachability so orchestrated rollouts don't route traffic to a half-healthy instance

---

## Suggested Execution Order

**Now:** Track A — all quick, independent, immediately valuable, no schema change.

**Next, as the main sequential effort:** Track B1 → B2 → B3, in that order — each sub-phase depends on the previous one landing correctly. Track C hangs off Track B2 specifically.

**In parallel with Track B, whenever convenient:** Track D and Track E — neither touches the `widgets` table, so neither blocks nor is blocked by the migration.

**Last:** Track F, once Track A's Redis adapter and Track B's per-row optimistic writes are both in place — this is where the horizontal-scaling story actually gets proven, rather than accidentally working because only one instance has ever been run.
