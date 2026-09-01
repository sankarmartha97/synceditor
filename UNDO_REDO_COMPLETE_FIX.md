# Undo/Redo Complete Fix Documentation

## Problems Fixed

### ✅ Problem 1: Continuous "Undo stack is empty" Errors
**Root Cause:** Duplicate keyboard listeners in both canvas_view.dart and page_editor_screen.dart were both handling Ctrl+Z/Ctrl+Y, causing undo/redo to be triggered **twice** - once without guards.

**Solution Applied:**
- Modified `canvas_view.dart` to check undo/redo history before triggering
- Added return `KeyEventResult.ignored` to allow page editor to handle it if canvas doesn't have history
- Added Shift key check to prevent conflicts between Undo (Ctrl+Z) and Redo (Ctrl+Shift+Z)

### ✅ Problem 2: Undo/Redo State Persists Across Page Refresh
**Current Implementation:** The system **ALREADY** persists undo/redo state:
1. **Database** stores per-user undo/redo stacks in `user_undo_stacks` table
2. **Backend** sends `canUndo`/`canRedo` state on page join
3. **Frontend** properly receives and displays this state

**Verification:**
- Backend: Lines 107-111 in `page.handler.js` send initial state
- Frontend: Lines 130-133 in `page_bloc.dart` receive state updates
- State updates correctly on every operation

### ✅ Problem 3: Per-User Undo/Redo Isolation
**Current Implementation:** The system **ALREADY** isolates undo/redo per user:
1. Each user has their own `undo_stack` and `redo_stack` in database
2. Operations are only added to the user who performed them
3. Undo only affects that user's own changes

**Database Schema:**
```sql
user_undo_stacks:
├── page_id (FK)
├── user_id (FK)           -- Unique per user
├── undo_stack (UUID[])    -- User's own operations
├── redo_stack (UUID[])    -- User's own operations
└── PRIMARY KEY (page_id, user_id)
```

## Additional Improvements Needed

### 1. Add Rate Limiting to Backend (Prevent Spam)

The backend should rate-limit undo/redo requests to prevent accidental spam or malicious behavior.

**File:** `backend/src-js/websocket/page.handler.js`

Add this near the top of the file:

```javascript
// Rate limiting for undo/redo (per user)
const undoRedoRateLimits = new Map();

function checkRateLimit(userId, action) {
  const key = `${userId}:${action}`;
  const now = Date.now();
  const lastCall = undoRedoRateLimits.get(key) || 0;
  
  // Allow 1 undo/redo per 200ms per user
  if (now - lastCall < 200) {
    return false; // Rate limited
  }
  
  undoRedoRateLimits.set(key, now);
  return true;
}
```

Then add rate limiting check in undo/redo handlers:

```javascript
socket.on(CLIENT_EVENTS.PAGE_UNDO, async (data) => {
  try {
    const { pageId } = data;
    
    // Rate limiting
    if (!checkRateLimit(socket.userId, 'undo')) {
      console.log(`⚠️ Rate limit: User ${socket.userId} undo too fast`);
      return; // Silently ignore
    }
    
    // ... rest of undo logic
```

### 2. Add Logging to Detect Spam Sources

Add debug logging to track who's sending undo/redo requests:

```javascript
console.log(`🔍 UNDO REQUEST from user ${socket.userId} on page ${pageId}`);
console.log(`   - Current time: ${new Date().toISOString()}`);
console.log(`   - Socket ID: ${socket.id}`);
console.log(`   - Permission: ${socket.pagePermission}`);
```

### 3. Frontend: Prevent Rapid Fire

Debounce undo/redo in the frontend to prevent accidental rapid clicks:

**File:** `frontend/lib/features/page/views/page_editor_screen.dart`

```dart
DateTime? _lastUndoTime;
DateTime? _lastRedoTime;

// In the undo callback:
onInvoke: (UndoIntent intent) {
  final now = DateTime.now();
  if (_lastUndoTime != null && 
      now.difference(_lastUndoTime!) < const Duration(milliseconds: 300)) {
    print('⚠️ Undo too fast, ignoring');
    return null;
  }
  _lastUndoTime = now;
  
  if (canEdit && state.canUndo && !state.isUndoing) {
    context.read<PageBloc>().add(UndoRequested(page.id));
  }
  return null;
},
```

## Testing Checklist

### ✅ Test 1: Single User Undo/Redo
1. User A creates/edits widgets
2. User A clicks Undo → Should undo their changes
3. User A clicks Redo → Should redo their changes
4. Refresh page
5. Undo/Redo state should persist

### ✅ Test 2: Multi-User Isolation
1. User A edits widget X
2. User B edits widget Y
3. User A clicks Undo → Should only undo widget X
4. User B clicks Undo → Should only undo widget Y
5. Users should NOT undo each other's changes

### ✅ Test 3: No More Error Spam
1. Open page
2. Wait 10 seconds
3. Should NOT see "Undo stack is empty" errors every 2 seconds
4. Only see errors when user explicitly clicks Undo with nothing to undo

### ✅ Test 4: Keyboard Shortcuts
1. Press Ctrl+Z → Should undo (if available)
2. Press Ctrl+Y → Should redo (if available)
3. Press Ctrl+Shift+Z → Should redo (if available)
4. Should NOT trigger multiple times

### ✅ Test 5: Permissions
1. User with 'view' permission → Cannot undo/redo
2. User with 'edit' permission → Can undo/redo their changes
3. User with 'owner' permission → Can undo/redo their changes

## Code Changes Summary

### ✅ Changed Files

1. **frontend/lib/features/canvas/views/canvas_view.dart**
   - Added guards to check undo/redo history before triggering
   - Added return `KeyEventResult.ignored` for proper event propagation
   - Added Shift key check to prevent conflicts

### 🔜 Recommended Changes

2. **backend/src-js/websocket/page.handler.js**
   - Add rate limiting (200ms per undo/redo)
   - Add debug logging for spam detection

3. **frontend/lib/features/page/views/page_editor_screen.dart**
   - Add debouncing (300ms) to prevent rapid clicks
   - Add state tracking for last undo/redo time

## Architecture Clarification

### How Undo/Redo Works (Per-User)

```
User A performs edit:
1. Operation saved to operation_history table
2. Operation ID pushed to User A's undo_stack
3. User A's redo_stack is cleared

User A clicks Undo:
1. Pop from User A's undo_stack
2. Get operation from operation_history
3. Apply inverse operation
4. Push to User A's redo_stack
5. Broadcast patch to other users

User B is NOT affected:
- User B's undo_stack remains unchanged
- User B only receives the patch broadcast
- User B cannot undo User A's changes
```

### Database Tables

```sql
operation_history:
├── id (UUID)              -- Operation identifier
├── page_id (UUID)         -- Which page
├── user_id (UUID)         -- WHO performed the operation
├── operation (JSONB[])    -- Forward patch
├── inverse_operation (JSONB[])  -- Reverse patch
├── from_version (INT)     -- Version before
├── to_version (INT)       -- Version after
└── created_at (TIMESTAMP)

user_undo_stacks:
├── page_id (UUID)         -- Which page
├── user_id (UUID)         -- Which user
├── undo_stack (UUID[])    -- User's undo operations
├── redo_stack (UUID[])    -- User's redo operations
└── PRIMARY KEY (page_id, user_id)  -- One stack per user per page
```

## Monitoring

To monitor undo/redo health:

```bash
# Check for users with large undo stacks (may need trimming)
SELECT 
  page_id, 
  user_id, 
  array_length(undo_stack, 1) as undo_count,
  array_length(redo_stack, 1) as redo_count
FROM user_undo_stacks
WHERE array_length(undo_stack, 1) > 50
ORDER BY undo_count DESC;

# Check recent undo/redo operations
SELECT 
  page_id,
  user_id,
  operation_type,
  created_at
FROM operation_history
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 20;
```

## Conclusion

### What Was Broken
- Duplicate keyboard listeners causing undo/redo to trigger twice
- No guards in canvas_view.dart undo/redo handlers

### What Was Already Working
- Per-user undo/redo isolation ✅
- State persistence across page refresh ✅
- Backend sending undo/redo state on join ✅
- Frontend receiving and displaying state ✅

### What Got Fixed
- Added guards to canvas_view.dart ✅
- Added proper event propagation ✅
- Added Shift key check for Redo ✅

### What Should Be Added (Recommended)
- Backend rate limiting for undo/redo (prevent spam)
- Frontend debouncing for rapid clicks
- Enhanced logging for debugging

