# Manual Testing Guide - Phase 2 Real-Time Collaboration

## 🎯 Testing Objective

Validate that the real-time collaborative editing system works correctly with:
- Real-time synchronization
- Conflict resolution via Operational Transformation (OT)
- Multi-user collaboration
- Optimistic updates

---

## 🛠️ Prerequisites

### Backend Running:
```bash
cd backend
npm run dev
```
**Expected**: Server on http://localhost:5000

### Frontend Running:
```bash
cd frontend
flutter run -d chrome
```
**Expected**: Chrome browser opens with app

### Database:
```bash
docker-compose up
```
**Expected**: PostgreSQL on localhost:5432

---

## 📋 Test Scenarios

### **Test 1: Basic Widget Addition (Single User)** ⏱️ 5 minutes

**Purpose**: Verify basic patch generation and sync

**Steps**:
1. Open browser, login as User A
2. Create a new page or open existing page
3. Wait for "✅ Synced" indicator
4. Add a widget (button, text, image, etc.)
5. Observe sync indicator: "🔵 ⟳ Syncing..." → "✅ Synced"

**Expected Behavior**:
- Widget appears immediately (optimistic update)
- Sync indicator shows syncing → synced
- Backend logs show: "✅ Patch applied: page X v1 → v2"
- No errors in console

**Backend Logs to Check**:
```
📄 User <userId> requesting to join page <pageId>
✅ User <userId> joined page <pageId> (owner)
🔄 User <userId> sending patch to page <pageId>
   Patches: 1 operations
✅ Patch applied: page <pageId> v1 → v2
```

**Success Criteria**: ✅
- Widget added successfully
- Version incremented
- Sync indicator works
- No errors

---

### **Test 2: Real-Time Sync Between Two Users** ⏱️ 10 minutes

**Purpose**: Verify real-time broadcasting works

**Steps**:
1. Open two browser windows (or use Incognito)
2. Window 1: Login as User A
3. Window 2: Login as User B (or same user, different session)
4. Both: Open the same page
5. User A: Add a widget
6. User B: Observe the change

**Expected Behavior**:
- User A adds widget → appears immediately
- User B sees widget appear within 200ms
- Both users see "✅ Synced"
- Version numbers match

**Backend Logs to Check**:
```
📄 User A requesting to join page <pageId>
📄 User B requesting to join page <pageId>
✅ User A joined page <pageId>
✅ User B joined page <pageId>
🔄 User A sending patch to page <pageId>
✅ Patch applied: page <pageId> v5 → v6
[Broadcast to User B]
```

**Success Criteria**: ✅
- Widget appears in both windows
- < 200ms latency
- No version conflicts
- Both users see same state

---

### **Test 3: Concurrent Widget Addition (OT Test)** ⏱️ 15 minutes

**Purpose**: Verify Operational Transformation resolves conflicts

**Setup**:
1. Open two browser windows (User A, User B)
2. Both open same page with 2 existing widgets
3. Note current version (e.g., v10)

**Steps**:
1. User A: Add widget at position 0 (beginning)
2. User B: **Immediately** add widget at position 0 (before A's sync completes)
3. Observe both windows

**Expected Behavior**:
- User A: Widget appears at position 0
- User B: Widget appears at position 0
- **After sync**: Both widgets present
  - One at position 0
  - One at position 1
  - Order determined by who sent first
- No data loss
- Both users see same final state

**Backend Logs to Check** (CRITICAL):
```
🔄 User A sending patch to page <pageId>
   Patches: 1 operations
✅ Patch applied: page <pageId> v10 → v11

🔄 User B sending patch to page <pageId>
   Patches: 1 operations
🔀 Version conflict detected: client=10, server=11
   Applying Operational Transformation...
   Found 1 server patches to transform against
   ✅ Transformed 1 → 1 operations
✅ Patch applied: page <pageId> v11 → v12
   🔀 Patches were transformed by OT
```

**Success Criteria**: ✅
- Both widgets added (no data loss)
- OT transformation occurred
- Array indices adjusted correctly
- Users converge to same state
- Backend logs show "🔀 Patches were transformed by OT"

---

### **Test 4: Update vs Delete Conflict** ⏱️ 10 minutes

**Purpose**: Verify OT handles update-delete conflicts correctly

**Setup**:
1. Two browser windows (User A, User B)
2. Same page with widget at index 1 (widget ID: X)
3. Current version: v15

**Steps**:
1. User A: Delete widget at index 1
2. User B: **Immediately** update widget at index 1 (change color, size, etc.)
3. Observe behavior

**Expected Behavior**:
- User A: Widget disappears
- User B: Update appears locally (optimistic)
- **After sync**: Widget is deleted (delete wins)
- User B's update is cancelled by OT
- Both users see widget deleted

**Backend Logs to Check**:
```
🔄 User A sending patch (remove operation)
✅ Patch applied: page <pageId> v15 → v16

🔄 User B sending patch (replace operation)
🔀 Version conflict detected: client=15, server=16
   Applying Operational Transformation...
   Found 1 server patches to transform against
   ✅ Transformed 1 → 0 operations
   ⚠️ All operations cancelled by OT
```

**Success Criteria**: ✅
- Widget deleted
- Update operation cancelled
- No error messages
- Both users converge

---

### **Test 5: Rapid Concurrent Operations** ⏱️ 10 minutes

**Purpose**: Stress test OT with multiple rapid operations

**Setup**:
1. Two browser windows
2. Same page with 5 widgets

**Steps**:
1. User A: Rapidly add 3 widgets (one after another)
2. User B: **Simultaneously** delete 2 widgets
3. Observe final state

**Expected Behavior**:
- All operations eventually apply
- OT resolves all conflicts
- No crashes or errors
- Both users see same final state
- Version numbers increment correctly

**Backend Logs to Check**:
```
🔄 Multiple patches from User A
🔄 Multiple patches from User B
🔀 Multiple OT transformations
✅ All patches applied
```

**Success Criteria**: ✅
- All operations complete
- No data corruption
- Performance acceptable (< 500ms per operation)
- Convergence achieved

---

### **Test 6: Cursor Position Sync** ⏱️ 5 minutes

**Purpose**: Verify cursor positions broadcast correctly

**Steps**:
1. Two browser windows
2. User A: Move cursor/selection around page
3. User B: Should see User A's cursor position

**Expected Behavior**:
- Cursor position broadcasts to other users
- < 100ms latency
- Smooth cursor updates

**Backend Logs**:
```
[Cursor updates - minimal logging]
```

**Success Criteria**: ✅
- Cursor position visible
- Real-time updates
- No lag

---

### **Test 7: Widget Selection Sync** ⏱️ 5 minutes

**Purpose**: Verify widget selection broadcasts

**Steps**:
1. Two browser windows
2. User A: Select a widget
3. User B: Should see widget highlighted/locked

**Expected Behavior**:
- Selection broadcasts immediately
- Visual indicator on User B's screen
- Prevents concurrent editing of same widget

**Success Criteria**: ✅
- Selection visible
- Real-time sync
- No conflicts

---

### **Test 8: Page Leave/Rejoin** ⏱️ 5 minutes

**Purpose**: Verify cleanup on disconnect/reconnect

**Steps**:
1. User A: Join page
2. User B: Join page
3. User A: Leave page (close tab or navigate away)
4. User B: Should see "User A left"
5. User A: Rejoin page

**Expected Behavior**:
- User A removed from active users
- User B notified
- Rejoin works seamlessly
- Version stays consistent

**Backend Logs**:
```
✅ User A joined page <pageId>
✅ User B joined page <pageId>
📤 User A leaving page <pageId>
🔌 User A disconnected
✅ User A joined page <pageId> [rejoin]
```

**Success Criteria**: ✅
- Leave notification works
- Rejoin works
- No orphaned sessions

---

### **Test 9: Permission-Based Editing** ⏱️ 5 minutes

**Purpose**: Verify read-only users can't edit

**Setup**:
1. Create page as User A (owner)
2. Share with User B (read-only permission)

**Steps**:
1. User B: Try to add/edit/delete widget
2. Observe error

**Expected Behavior**:
- User B can view page
- Edit operations rejected
- Error message: "Permission denied: read-only access"

**Backend Logs**:
```
🔄 User B sending patch to page <pageId>
❌ Permission denied: read-only access
```

**Success Criteria**: ✅
- Read-only enforced
- Clear error message
- No unauthorized changes

---

### **Test 10: Network Latency Simulation** ⏱️ 10 minutes

**Purpose**: Test behavior under poor network conditions

**Setup**:
1. Chrome DevTools → Network tab → Throttling: "Slow 3G"
2. Two browser windows

**Steps**:
1. User A: Add widget with throttling enabled
2. Observe delayed sync
3. User B: Add widget concurrently

**Expected Behavior**:
- Operations queue correctly
- OT resolves conflicts despite latency
- No lost operations
- Eventually consistent

**Success Criteria**: ✅
- Works under latency
- No lost data
- Queue processed correctly

---

## 🔍 Key Metrics to Track

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Sync Latency | < 200ms | Time between action and remote update |
| OT Transformation Time | < 10ms | Backend log timestamps |
| Conflict Resolution Rate | 100% | All conflicts resolved without error |
| Data Loss | 0% | All operations applied |
| Version Consistency | 100% | All users on same version after sync |
| Error Rate | < 1% | Errors / total operations |

---

## 🐛 Common Issues & Troubleshooting

### Issue 1: "Version conflict" error
**Cause**: OT not applying correctly  
**Check**: Backend logs for "🔀 Applying OT..." message  
**Fix**: Ensure `ot.service.js` is loaded

### Issue 2: Widget doesn't appear on other user's screen
**Cause**: WebSocket broadcast issue  
**Check**: Both users in same room (`page:<pageId>`)  
**Fix**: Verify `socket.join()` and `socket.to()` calls

### Issue 3: Sync indicator stuck on "Syncing..."
**Cause**: WebSocket event not received  
**Check**: Browser console for `page:patch:applied` event  
**Fix**: Verify event names match frontend/backend

### Issue 4: Wrong widget order after conflict
**Cause**: OT array transformation bug  
**Check**: Backend logs for transformation details  
**Fix**: Review `ot.service.js` array index logic

### Issue 5: Performance degradation with many operations
**Cause**: Too many patches, no optimization  
**Check**: Patch history table size  
**Fix**: Implement patch compaction/cleanup

---

## 📊 Test Results Template

Copy this template to document test results:

```markdown
## Test Results - Phase 2 E2E Testing

**Date**: [DATE]
**Tester**: [NAME]
**Backend Version**: [COMMIT/VERSION]
**Frontend Version**: [COMMIT/VERSION]

### Test 1: Basic Widget Addition
- Status: ✅ Pass / ❌ Fail
- Notes: 
- Issues:

### Test 2: Real-Time Sync
- Status: ✅ Pass / ❌ Fail
- Latency: [X]ms
- Notes:
- Issues:

### Test 3: Concurrent Addition (OT)
- Status: ✅ Pass / ❌ Fail
- OT Triggered: Yes / No
- Backend Logs: [paste logs]
- Notes:
- Issues:

### Test 4: Update vs Delete
- Status: ✅ Pass / ❌ Fail
- OT Behavior: Correct / Incorrect
- Notes:
- Issues:

### Test 5: Rapid Operations
- Status: ✅ Pass / ❌ Fail
- Performance: [X]ms average
- Notes:
- Issues:

### Test 6: Cursor Sync
- Status: ✅ Pass / ❌ Fail
- Notes:
- Issues:

### Test 7: Selection Sync
- Status: ✅ Pass / ❌ Fail
- Notes:
- Issues:

### Test 8: Leave/Rejoin
- Status: ✅ Pass / ❌ Fail
- Notes:
- Issues:

### Test 9: Permissions
- Status: ✅ Pass / ❌ Fail
- Notes:
- Issues:

### Test 10: Network Latency
- Status: ✅ Pass / ❌ Fail
- Notes:
- Issues:

### Overall Summary
- Tests Passed: [X] / 10
- Critical Issues: [COUNT]
- Minor Issues: [COUNT]
- Recommendation: Ready for Phase 3 / Needs fixes
```

---

## 🎬 Next Steps After Testing

### If All Tests Pass ✅:
1. Document results in `TEST_RESULTS_PHASE_2.md`
2. Create demo video
3. Move to Phase 3 development
4. Consider production deployment

### If Tests Fail ❌:
1. Document failures with logs
2. Create bug report with reproduction steps
3. Fix issues
4. Retest
5. Repeat until all pass

---

## 📞 Support

**Backend Logs**: `backend/` terminal output  
**Frontend Logs**: Browser console (F12)  
**Database Logs**: Docker logs (`docker-compose logs postgres`)  
**WebSocket Events**: Browser DevTools → Network → WS tab

---

## 🎯 Success Criteria

Phase 2 E2E testing is **COMPLETE** when:

- ✅ All 10 test scenarios pass
- ✅ OT transformations verified in logs
- ✅ No data loss in any scenario
- ✅ Performance meets targets (< 200ms sync)
- ✅ No critical bugs found
- ✅ Documentation complete

**Estimated Time**: 1.5 - 2 hours for complete testing

Good luck! 🚀
