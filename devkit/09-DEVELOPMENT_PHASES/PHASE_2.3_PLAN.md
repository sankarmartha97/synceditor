# Phase 2.3: Conflict Resolution - Implementation Plan

## Overview

**Goal**: Handle concurrent edits from multiple users without manual conflict resolution

**Problem**: Currently, when two users edit the same page simultaneously:
- Both send patches with version N
- First patch wins, second gets rejected (409 Conflict)
- User must manually reload

**Solution**: Operational Transformation (OT)
- Transform patches to account for concurrent operations
- Maintain convergence (all users eventually see same state)
- No manual intervention required

---

## Conflict Scenarios

### Scenario 1: Concurrent Widget Addition
```
Initial State: []
User A: Add widget at index 0
User B: Add widget at index 0
```

**Current Behavior**: User B gets conflict  
**Desired Behavior**: Both widgets added at different indices

### Scenario 2: Concurrent Widget Update
```
Initial State: [widget1]
User A: Update widget1 position to (100, 100)
User B: Update widget1 color to blue
```

**Current Behavior**: Last write wins, one update lost  
**Desired Behavior**: Both updates applied

### Scenario 3: Update vs Delete
```
Initial State: [widget1]
User A: Update widget1 text
User B: Delete widget1
```

**Current Behavior**: Conflict  
**Desired Behavior**: Delete wins (widget removed, update discarded)

### Scenario 4: Array Index Conflicts
```
Initial State: [w1, w2, w3]
User A: Remove w2 (index 1)
User B: Update w3 (index 2)
```

**Current Behavior**: Index mismatch  
**Desired Behavior**: B's update adjusted to index 1

---

## Implementation Strategy

### Approach: Operational Transformation (OT)

**Core Principle**: Transform operations so they can be applied in any order and still converge

**Transform Function**: `T(op1, op2) -> op1'`
- Takes two concurrent operations
- Returns transformed version of op1
- Ensures: `apply(apply(S, op1), T(op2, op1)) = apply(apply(S, op2), T(op1, op2))`

### OT Algorithm

```javascript
function transformPatch(clientPatch, serverPatch) {
  const transformed = [];
  
  for (const clientOp of clientPatch) {
    let transformedOp = clientOp;
    
    for (const serverOp of serverPatch) {
      transformedOp = transformOperation(transformedOp, serverOp);
    }
    
    if (transformedOp) {
      transformed.push(transformedOp);
    }
  }
  
  return transformed;
}

function transformOperation(op1, op2) {
  const path1 = op1.path;
  const path2 = op2.path;
  
  // If paths don't overlap, no transformation needed
  if (!pathsOverlap(path1, path2)) {
    return op1;
  }
  
  // Handle specific transformation rules
  if (op1.op === 'add' && op2.op === 'add') {
    return transformAddAdd(op1, op2);
  }
  
  if (op1.op === 'remove' && op2.op === 'remove') {
    return null; // Both removing same thing
  }
  
  if (op1.op === 'replace' && op2.op === 'remove') {
    return null; // Can't update deleted item
  }
  
  // ... more rules
}
```

---

## Transformation Rules

### Rule 1: Add + Add (Same Path)
```
op1: add /widgets/0 {widgetA}
op2: add /widgets/0 {widgetB}

Transform op1:
  → add /widgets/1 {widgetA}
  
Reason: op2 inserted at 0, so op1 shifts to 1
```

### Rule 2: Add + Remove
```
op1: add /widgets/2 {widgetA}
op2: remove /widgets/1

Transform op1:
  → add /widgets/1 {widgetA}
  
Reason: op2 removed index 1, so op1 shifts down
```

### Rule 3: Remove + Update (Same Widget)
```
op1: remove /widgets/1
op2: replace /widgets/1/position {x: 100}

Transform op2:
  → null (discard)
  
Reason: Widget deleted, update is meaningless
```

### Rule 4: Update + Update (Same Widget, Different Properties)
```
op1: replace /widgets/0/position {x: 100}
op2: replace /widgets/0/color "blue"

Transform: No change needed
Reason: Different properties, both apply
```

### Rule 5: Update + Update (Same Property)
```
op1: replace /widgets/0/position {x: 100}
op2: replace /widgets/0/position {x: 200}

Transform: Last-Write-Wins
Result: op2 wins (x: 200)
```

---

## Implementation Plan

### Backend Changes

#### 1. Create OT Service (`backend/src-js/services/ot.service.js`)

```javascript
class OTService {
  // Transform client patch against server patches
  transformPatch(clientPatch, serverPatches, clientVersion, serverVersion)
  
  // Transform single operation against another
  transformOperation(op1, op2)
  
  // Check if paths overlap
  pathsOverlap(path1, path2)
  
  // Extract array index from path
  getPathIndex(path)
  
  // Adjust path index
  adjustPathIndex(path, delta)
}
```

**Key Methods**:
- `transformPatch()` - Main entry point
- `transformOperation()` - Transform one op against another
- `transformAddAdd()`, `transformAddRemove()`, etc. - Specific rules

#### 2. Update Page Handler (`backend/src-js/websocket/page.handler.js`)

**Current**:
```javascript
if (clientVersion !== currentVersion) {
  return socket.emit('page:conflict', {
    clientVersion,
    serverVersion: currentVersion
  });
}
```

**New**:
```javascript
if (clientVersion !== currentVersion) {
  // Get patches between clientVersion and currentVersion
  const serverPatches = await getPatches(pageId, clientVersion, currentVersion);
  
  // Transform client patches
  const transformedPatches = otService.transformPatch(
    clientPatches,
    serverPatches,
    clientVersion,
    currentVersion
  );
  
  // Apply transformed patches
  await applyPatches(pageId, transformedPatches);
}
```

#### 3. Track Patch History

**Database**: `page_patches` table already exists ✅
```sql
CREATE TABLE page_patches (
  id UUID PRIMARY KEY,
  page_id UUID REFERENCES pages(id),
  patches JSONB,
  version INTEGER,
  user_id UUID,
  created_at TIMESTAMP
);
```

**Query patches between versions**:
```javascript
async function getPatches(pageId, fromVersion, toVersion) {
  const result = await pool.query(`
    SELECT patches
    FROM page_patches
    WHERE page_id = $1
      AND version > $2
      AND version <= $3
    ORDER BY version ASC
  `, [pageId, fromVersion, toVersion]);
  
  return result.rows.flatMap(r => r.patches);
}
```

---

### Frontend Changes

#### 1. Handle Conflict Resolution (`page_bloc.dart`)

**Current**:
```dart
void _onHandlePatchConflict(...) {
  emit(state.copyWith(
    error: 'Version conflict. Please reload.',
  ));
}
```

**New**:
```dart
void _onHandlePatchConflict(...) {
  // Server will auto-resolve
  // Just wait for transformed patch
  print('🔀 Server resolving conflict...');
}
```

#### 2. Queue Pending Patches

**Problem**: If conflict resolution takes time, new edits might come in

**Solution**: Queue patches
```dart
class PageBloc {
  final Queue<List<Map<String, dynamic>>> _pendingPatches = Queue();
  bool _isResolving = false;
  
  void _sendPatch(patches) {
    if (_isResolving) {
      _pendingPatches.add(patches);
    } else {
      _wsClient.sendPatch(patches);
    }
  }
  
  void _onConflictResolved() {
    _isResolving = false;
    if (_pendingPatches.isNotEmpty) {
      _sendPatch(_pendingPatches.removeFirst());
    }
  }
}
```

---

## Testing Strategy

### Unit Tests (Backend OT Service)

```javascript
describe('OT Service', () => {
  test('Add + Add: Adjust index', () => {
    const op1 = {op: 'add', path: '/widgets/0', value: {id: 'A'}};
    const op2 = {op: 'add', path: '/widgets/0', value: {id: 'B'}};
    
    const result = transformOperation(op1, op2);
    
    expect(result.path).toBe('/widgets/1');
  });
  
  test('Remove + Update: Discard update', () => {
    const op1 = {op: 'remove', path: '/widgets/1'};
    const op2 = {op: 'replace', path: '/widgets/1/position', value: {x: 100}};
    
    const result = transformOperation(op2, op1);
    
    expect(result).toBeNull();
  });
  
  // ... 20+ more tests
});
```

### Integration Tests

```javascript
test('Concurrent widget addition', async () => {
  // User A adds widget at index 0
  const patchA = [{op: 'add', path: '/widgets/0', value: widgetA}];
  
  // User B adds widget at index 0 (concurrent)
  const patchB = [{op: 'add', path: '/widgets/0', value: widgetB}];
  
  // Send both
  await Promise.all([
    sendPatch(pageId, patchA, version),
    sendPatch(pageId, patchB, version)
  ]);
  
  // Check final state
  const page = await getPage(pageId);
  expect(page.widgets).toHaveLength(2);
  expect(page.widgets[0].id).toBe(widgetB.id); // Last write at index 0
  expect(page.widgets[1].id).toBe(widgetA.id); // Transformed to index 1
});
```

---

## Complexity & Trade-offs

### Pros ✅
- No manual conflict resolution
- Seamless collaboration
- Better UX
- Maintains convergence

### Cons ⚠️
- More complex code
- Harder to debug
- Edge cases tricky
- Performance overhead

### Alternatives Considered

#### 1. Last-Write-Wins (LWW)
**Pros**: Simple, fast  
**Cons**: Data loss, poor UX  
**Decision**: ❌ Not suitable for collaboration

#### 2. Manual Conflict Resolution
**Pros**: User decides  
**Cons**: Interrupts workflow, requires UI  
**Decision**: ❌ Too disruptive

#### 3. CRDT (Conflict-free Replicated Data Types)
**Pros**: Mathematically proven convergence  
**Cons**: Complex, large payload, overkill  
**Decision**: ❌ Too complex for MVP

#### 4. Operational Transformation (OT)
**Pros**: Industry standard, proven, reasonable complexity  
**Cons**: Requires careful implementation  
**Decision**: ✅ **SELECTED**

---

## Implementation Timeline

### Step 1: OT Service (Backend) - 30 minutes
- Create `ot.service.js`
- Implement transformation rules
- Unit tests

### Step 2: Page Handler Integration - 20 minutes
- Update conflict handling
- Query patch history
- Apply transformed patches

### Step 3: Frontend Updates - 15 minutes
- Update conflict handler
- Add patch queue
- Handle resolution events

### Step 4: Testing - 20 minutes
- Run unit tests
- Integration tests
- Manual testing

**Total Estimated Time**: 85 minutes (~1.5 hours)

---

## Success Criteria

### Must Have ✅
- [ ] Concurrent widget addition works
- [ ] Concurrent updates don't conflict
- [ ] Delete beats update
- [ ] Array indices adjusted correctly
- [ ] Convergence maintained
- [ ] No data loss

### Nice to Have ⭐
- [ ] Visual conflict indicators
- [ ] Undo/redo with OT
- [ ] Offline support
- [ ] Merge complex conflicts

---

## Next Steps

1. **Create OT Service** (backend)
2. **Write transformation rules**
3. **Update page handler**
4. **Test transformations**
5. **Update frontend**
6. **End-to-end testing**
7. **Document behavior**

---

**Ready to implement Phase 2.3?** Let's start with the OT Service! 🚀
