# Undo/Redo Issues and Fixes

## Problems Identified

### Problem 1: Continuous "Undo stack is empty" Errors
**Root Cause:** The error messages appearing every 2 seconds indicate that something is automatically triggering undo/redo operations, likely from:
- A keyboard shortcut listener that's continuously firing
- An event listener that's not properly checking if undo is available before sending the request
- Multiple event listeners being registered

### Problem 2: Undo/Redo State Not Persisting After Page Refresh
**Root Cause:** The undo/redo stacks are stored in the database (`user_undo_stacks` table), but they are NOT being loaded when a user rejoins a page after refresh. The backend only sends the initial `canUndo`/`canRedo` state on join, but the frontend doesn't have a way to restore the full undo/redo history.

### Problem 3: Users Can Undo Other Users' Changes
**Root Cause:** While the database tracks per-user undo stacks correctly, the architecture needs clarification that:
- Each user's undo stack should ONLY contain their own operations
- The current implementation DOES support this in the database, but we need to ensure it's working correctly

## Solutions

### Fix 1: Stop Continuous Undo Error Messages

The issue is likely from keyboard shortcuts or event listeners. We need to:

1. **Add guard checks before sending undo/redo**
2. **Prevent duplicate keyboard listeners**
3. **Only trigger undo/redo when user explicitly requests it**

### Fix 2: Persist Undo/Redo State Across Page Refresh

The undo/redo stacks ARE persistent in the database, but we need to:

1. **Ensure the backend sends undo/redo state on page join**
2. **Frontend should properly handle and display this state**
3. **Keep the state synchronized**

### Fix 3: Per-User Undo/Redo Isolation

The database schema already supports this, but we need to verify:

1. **Each user has their own undo_stack and redo_stack**
2. **Operations are only added to the user who performed them**
3. **Undo only affects that user's own changes**

## Implementation Plan

### Backend Changes

1. **Add logging to detect the source of continuous undo calls**
2. **Verify undo/redo state is sent on page join**
3. **Add rate limiting to prevent spam**

### Frontend Changes

1. **Add guards to prevent undo/redo when not available**
2. **Check for duplicate keyboard listeners**
3. **Properly handle undo/redo state updates**

