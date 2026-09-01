# Selection Sync Debugging Guide

## Current Status
Selection events are being received and processed, but the orange border is not showing up in the UI.

## What's Working ✅
1. **Backend:** Sending/receiving selection events
2. **Frontend WebSocket:** Receiving `page:selection:updated` events  
3. **Frontend Bloc:** Processing selection events and updating state
4. **State Update:** `otherUsersSelections` map is being updated

## What's Not Working ❌
1. **UI Rendering:** Orange border not appearing
2. **Widget Rebuild:** Widgets not re-rendering with new selection data

## Debug Logs Observed

### Tab 1 (User: Test User - 13a979dd...)
```
✨ Updated selection for user b60b5da3...: 99231547-e06f-4f65-9e02-22ef39a82992
✨ Updated selection for user b60b5da3...: e2997186-036f-4d81-a05c-76a42f467b91
```
**Status:** Receiving other user's selections ✅

### Tab 2 (User: Admin - b60b5da3...)
```
✨ Updated selection for user 13a979dd...: 99231547-e06f-4f65-9e02-22ef39a82992
🎯 Widget tapped: Container - 99231547...
```
**Status:** Receiving other user's selections ✅

## Missing Debug Logs ❌
These logs should appear but don't:
```
🔍 Other users selections: {userId: widgetId}
🟠 Widget X selected by Y other user(s)
🎨 Showing ORANGE border for widget X
```

## Root Cause Analysis

### Theory 1: State Not Triggering Rebuild
**Issue:** `otherUsersSelections` changes but `BlocBuilder` doesn't rebuild

**Evidence:**
- Selection events logged: ✅
- State update logged: ✅  
- Canvas rebuild logged: ❌
- Widget border logic logged: ❌

**Solution:** Verify Equatable props include `otherUsersSelections`

### Theory 2: Nested Children Not Rebuilding
**Issue:** Only root widgets rebuild, children use stale state

**Evidence:**
- Root widgets build correctly
- Child widgets might not receive updated state

**Solution:** Ensure state is passed down to all widget levels

### Theory 3: Map Reference Not Changing
**Issue:** Mutating existing map instead of creating new one

**Evidence:**
- Check if `Map.from()` is used in `copyWith`

**Current Code:**
```dart
final updatedSelections = Map<String, String?>.from(state.otherUsersSelections);
if (selectionEvent.widgetId == null) {
  updatedSelections.remove(selectionEvent.userId);
} else {
  updatedSelections[selectionEvent.userId] = selectionEvent.widgetId;
}
emit(state.copyWith(otherUsersSelections: updatedSelections));
```

**Status:** Looks correct ✅

## Debugging Steps Added

### Step 1: Canvas Build Logging
Added to `page_canvas_view.dart`:
```dart
if (state.otherUsersSelections.isNotEmpty) {
  print('🔍 Other users selections: ${state.otherUsersSelections}');
}
```

### Step 2: Widget Selection Logging  
Added to `_buildWidget`:
```dart
if (selectedByOthers.isNotEmpty) {
  print('🟠 Widget ${widget.id} selected by ${selectedByOthers.length} other user(s)');
}
```

### Step 3: Border Rendering Logging
Added to `_buildContainerOrWidget`:
```dart
if (hasOtherUserSelection) {
  print('🎨 Showing ORANGE border for widget ${widget.id}');
}
```

## Next Steps

### If Logs Show Map is Empty
**Problem:** State update isn't working
**Fix:** Check `_onUpdateRemoteSelection` in page_bloc.dart

### If Logs Show Map is Populated
**Problem:** UI not rebuilding or render logic issue
**Fix:** Check BlocBuilder or widget tree structure

### If Logs Show Border Logic Reached
**Problem:** Border styling issue
**Fix:** Check Container decoration or widget stacking

## Test Procedure

1. Open http://localhost:3000 (Admin)
2. Open http://localhost:3001 (Test User)  
3. In Tab 1: Click a widget
4. In Tab 2: Check for orange border
5. Look for these logs in Tab 2:
   - `🔍 Other users selections: ...` (should appear on every rebuild)
   - `🟠 Widget X selected by...` (should appear when building that widget)
   - `🎨 Showing ORANGE border...` (should appear when rendering border)

## Expected vs Actual

### Expected Flow:
1. User A selects widget → ✅ Working
2. Backend broadcasts selection → ✅ Working  
3. User B receives event → ✅ Working
4. PageBloc updates `otherUsersSelections` → ✅ Working
5. Canvas rebuilds with new state → ❓ Checking
6. Widget checks `selectedByOthers` → ❓ Checking
7. Orange border renders → ❌ Not working

### Actual Flow:
Steps 1-4 confirmed working.
Steps 5-7 not confirmed - no debug output.

## Files Modified for Debugging

1. `frontend/lib/features/page/views/page_canvas_view.dart`
   - Added logging in `build()`, `_buildWidget()`, `_buildContainerOrWidget()`

2. `frontend/lib/features/page/bloc/page_bloc.dart`  
   - Already has logging for selection events

3. `frontend/lib/features/page/bloc/page_state.dart`
   - Contains `otherUsersSelections` field
   - Included in Equatable props

## Potential Issues

### Issue 1: BlocBuilder Not Rebuilding
**Symptom:** No `🔍 Other users selections` log
**Cause:** Equatable not detecting change or BlocBuilder issue
**Fix:** Force rebuild or check Equatable implementation

### Issue 2: Children Not Getting State
**Symptom:** Root widgets show logs, children don't
**Cause:** Nested children use old state reference  
**Fix:** Pass state explicitly to all child builders

### Issue 3: Widget Keys Causing Issues
**Symptom:** Widgets not rebuilding despite state change
**Cause:** Flutter widget tree optimization
**Fix:** Add explicit keys or force rebuild

## Success Criteria

When working correctly, you should see:
```
// In Tab 2 when Tab 1 selects widget ABC:
🔍 Other users selections: {user-id-from-tab-1: ABC}
🟠 Widget ABC selected by 1 other user(s)
   User: user-id-from-tab-1
🎨 Showing ORANGE border for widget ABC
```

## Current Debug Session

**Date:** 2026-08-31
**Servers:**
- Backend: port 5000 (term_1788214907381_rr3an5zl2ab)
- Frontend 3000: (term_1788215588510_lznd1k5qlec) - starting
- Frontend 3001: (term_1788215589000_53n81y7am9w) - starting

**Status:** Restarting with additional debug logging
**Next:** Monitor logs for selection events and UI rebuilds
