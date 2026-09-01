# PHASE 2: Incremental Sync System

**Goal:** Enable real-time collaborative editing with delta updates (JSON Patch) instead of full document replacements.

**Status:** 🔵 In Progress  
**Tasks:** 6/17 (35%)

---

## Overview

Phase 2 transforms the page editing experience from "save full document" to "sync incremental changes" - enabling true real-time collaboration where multiple users can edit simultaneously with minimal conflicts.

---

## Architecture

```
User A Editor          Backend              User B Editor
     |                    |                      |
     |-- patch event ---->|                      |
     |                    |-- broadcast patch -->|
     |                    |-- save to DB ------->|
     |<-- confirmation ---|                      |
     |                    |<-- patch event ------|
     |<-- broadcast patch-|                      |
```

**Key Concepts:**
1. **JSON Patch (RFC 6902)** - Standard format for describing changes
2. **Operational Transformation** - Conflict resolution algorithm
3. **Optimistic Updates** - Apply changes immediately, sync later
4. **Version Vectors** - Track concurrent edits

---

## 2.1 JSON Patch Implementation (4 tasks)

### Task 2.1.1: Install and configure JSON Patch library
- [x] Backend: Install `fast-json-patch` (JavaScript) ✅
- [x] Frontend: Add `json_patch` package to pubspec.yaml ✅
- [x] Create utility wrappers for both ✅

### Task 2.1.2: Create diff generation service
- [x] Backend: `patch.service.js` - generate patches ✅
- [x] Frontend: `patch_service.dart` - generate patches ✅
- [x] Support all JSON Patch operations (add, remove, replace, move, copy, test) ✅

### Task 2.1.3: Create patch application service
- [x] Backend: Apply patches with validation ✅
- [x] Frontend: Apply patches to local state ✅
- [x] Handle edge cases (missing paths, type mismatches) ✅

### Task 2.1.4: Add patch validation
- [x] Validate patch structure ✅
- [x] Validate target paths exist ✅
- [x] Test operation verification ✅
- [x] Atomic application (all or nothing) ✅

---

## 2.2 WebSocket Sync Events (5 tasks)

### Task 2.2.1: Extend WebSocket events
- [x] Add `page:join` event (join page room) ✅
- [x] Add `page:leave` event ✅
- [x] Add `page:patch` event (send/receive patches) ✅
- [x] Add `page:cursor` event (cursor position) ✅
- [x] Add `page:conflict` event (notify conflicts) ✅

### Task 2.2.2: Implement patch broadcasting
- [x] Backend: Broadcast patches to all editors except sender ✅
- [x] Include metadata (userId, timestamp, version) ✅
- [ ] Queue patches during disconnection
- [x] Implement acknowledgment system ✅

### Task 2.2.3: Add optimistic updates
- [ ] Frontend: Apply changes immediately to local state
- [ ] Show "syncing" indicator
- [ ] Rollback on server rejection
- [ ] Retry logic for failed patches

### Task 2.2.4: Implement sync queue
- [ ] Frontend: Queue patches during offline
- [ ] Backend: Process patches in order
- [ ] Handle batch operations
- [ ] Deduplicate redundant patches

### Task 2.2.5: Add presence system
- [ ] Track active editors per page
- [ ] Show user cursors/selections
- [ ] Display "who's editing" indicators
- [ ] Handle disconnections gracefully

---

## 2.3 Conflict Resolution (4 tasks)

### Task 2.3.1: Implement Operational Transformation (OT)
- [ ] Transform concurrent patches
- [ ] Handle path conflicts (same widget edited)
- [ ] Preserve user intent
- [ ] Implement transformation functions

### Task 2.3.2: Add conflict detection
- [ ] Detect overlapping edits
- [ ] Compare version vectors
- [ ] Identify conflicting paths
- [ ] Log conflicts for debugging

### Task 2.3.3: Create merge strategies
- [ ] **Last-Write-Wins (LWW)** - Default strategy
- [ ] **First-Write-Wins** - For critical operations
- [ ] **Manual Resolution** - Prompt user for conflicts
- [ ] **Custom Rules** - Per-widget conflict handling

### Task 2.3.4: Add user notifications
- [ ] Show conflict alerts
- [ ] Display merge results
- [ ] Offer undo/redo options
- [ ] Log conflict history

---

## 2.4 Frontend Integration (4 tasks)

### Task 2.4.1: Update PageBloc for incremental sync
- [ ] Generate patches on widget add/update/delete
- [ ] Emit patches via WebSocket
- [ ] Apply incoming patches to state
- [ ] Handle patch failures

### Task 2.4.2: Implement patch generation
- [ ] Detect widget position changes
- [ ] Detect property changes
- [ ] Generate minimal patches
- [ ] Batch rapid changes

### Task 2.4.3: Add real-time patch listener
- [ ] Listen to `page:patch` events
- [ ] Apply patches to PageState
- [ ] Update UI reactively
- [ ] Show remote user actions

### Task 2.4.4: Update UI for sync status
- [ ] Add sync indicator (syncing/synced/error)
- [ ] Show conflict warnings
- [ ] Display remote cursors
- [ ] Add connection status

---

## Technical Stack

### Backend Dependencies (JavaScript)
```json
{
  "fast-json-patch": "^3.1.1",  // JSON Patch operations
  "socket.io": "^4.5.4"          // Already installed
}
```

### Frontend Dependencies (Dart)
```yaml
dependencies:
  json_patch: ^2.0.0           # JSON Patch for Dart
  socket_io_client: ^2.0.3+1   # Already installed
```

---

## Data Structures

### JSON Patch Format (RFC 6902)
```json
[
  {
    "op": "add",
    "path": "/widgets/-",
    "value": {"id": "uuid", "type": "rectangle", ...}
  },
  {
    "op": "replace",
    "path": "/widgets/2/position/x",
    "value": 150
  },
  {
    "op": "remove",
    "path": "/widgets/3"
  }
]
```

### Patch Event Structure
```json
{
  "pageId": "uuid",
  "userId": "uuid",
  "userName": "John Doe",
  "patches": [...],
  "version": 5,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Version Vector
```json
{
  "pageVersion": 10,
  "userVersions": {
    "user-1": 7,
    "user-2": 3
  }
}
```

---

## Implementation Priority

### High Priority (Week 1)
1. ✅ JSON Patch library integration
2. ✅ Basic patch generation/application
3. ✅ WebSocket `page:patch` event
4. ✅ Frontend patch application

### Medium Priority (Week 2)
5. ⏳ Optimistic updates
6. ⏳ Conflict detection
7. ⏳ Last-Write-Wins strategy
8. ⏳ Sync status UI

### Low Priority (Week 3)
9. ⏳ Advanced OT algorithms
10. ⏳ Manual conflict resolution
11. ⏳ Offline queue
12. ⏳ Performance optimization

---

## Success Criteria

✅ **Phase 2 Complete When:**
1. Users can edit simultaneously without overwriting
2. Changes sync in < 100ms
3. Conflicts are detected and resolved automatically
4. No data loss during concurrent edits
5. UI shows sync status and remote actions
6. System handles network interruptions gracefully

---

## Testing Strategy

### Unit Tests
- Patch generation logic
- Patch application
- Transformation functions
- Conflict detection

### Integration Tests
- Multi-user editing scenarios
- Network failure simulation
- Concurrent patch application
- Version synchronization

### E2E Tests
- Two users edit same widget
- Rapid consecutive edits
- Offline → Online sync
- Conflict resolution flows

---

## Performance Targets

| Metric | Target | Current |
|--------|--------|---------|
| Patch Generation | < 5ms | TBD |
| Patch Application | < 10ms | TBD |
| Network Latency | < 100ms | TBD |
| Conflict Resolution | < 50ms | TBD |
| Memory Usage | < 50MB | TBD |

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Data loss during conflicts | Implement version history, rollback capability |
| Network partitions | Queue patches, implement eventual consistency |
| Patch ordering issues | Use version vectors, timestamp ordering |
| Performance degradation | Batch patches, debounce rapid changes |
| Complex OT bugs | Start with simple LWW, add OT gradually |

---

## Next Steps

**Starting with Task 2.1.1:** Install JSON Patch libraries and create utility wrappers.

---

**Progress:** 0/17 tasks (0%)  
**ETA:** 3-4 sessions
