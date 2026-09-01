# Phase 3.2: Presence Awareness - Testing Checklist

## 🎯 Quick Testing Guide (15 minutes)

**Status**: ✅ Backend RUNNING | ✅ Frontend RUNNING

---

## Prerequisites ✅

- ✅ Backend running on http://localhost:5000
- ✅ Frontend running in Chrome
- ✅ PostgreSQL database running
- ✅ Redis running

---

## Test 1: Basic Cursor Visibility (3 minutes) ⭐ PRIORITY

**Objective**: Verify cursor appears in second window

### Steps:
1. **Window 1**: Already open (your current browser)
2. **Window 2**: Open Chrome Incognito (`Ctrl+Shift+N`)
3. **Window 2**: Navigate to http://localhost:PORT (Flutter app URL)
4. **Window 2**: Login (same or different user)
5. **Both Windows**: Open the SAME page
6. **Window 1**: Move your mouse cursor around the canvas slowly
7. **Window 2**: Look for a colored dot with username

### Expected Results:
- ✅ Colored cursor dot appears in Window 2
- ✅ Cursor follows Window 1's mouse movements
- ✅ Latency < 200ms (feels instant)
- ✅ Username label appears next to cursor
- ✅ Cursor animates smoothly (no jumping)

### Pass Criteria:
- Cursor visible: YES / NO
- Latency acceptable: YES / NO
- Smooth animation: YES / NO

---

## Test 2: Active Users Sidebar (2 minutes)

**Objective**: Verify active users list works

### Steps:
1. Both windows on same page
2. Check top-right app bar for user count icon
3. Look for sidebar on right side (or toggle with button)
4. Verify both users appear in the list

### Expected Results:
- ✅ Active users count shows "2" in app bar
- ✅ Sidebar shows both users
- ✅ Each user has avatar/initials
- ✅ Each user has colored indicator
- ✅ Permission badges visible (owner/edit/view)
- ✅ Toggle button shows/hides sidebar

### Pass Criteria:
- Users visible: YES / NO
- Correct count: YES / NO
- Toggle works: YES / NO

---

## Test 3: Cursor Disappears on Leave (1 minute)

**Objective**: Verify cursor cleanup

### Steps:
1. Both windows on same page
2. Window 2 shows Window 1's cursor
3. **Window 1**: Navigate away or close tab
4. **Window 2**: Wait 1-2 seconds

### Expected Results:
- ✅ Cursor disappears immediately
- ✅ User removed from active users list
- ✅ User count decrements

### Pass Criteria:
- Cursor removed: YES / NO
- User removed from list: YES / NO

---

## Test 4: Multiple Cursors (3 minutes)

**Objective**: Test with 3+ users

### Steps:
1. Open a 3rd browser window (or use different browser)
2. All 3 windows join same page
3. Move cursors around in all windows

### Expected Results:
- ✅ All cursors visible with different colors
- ✅ Each cursor has correct username
- ✅ No performance issues
- ✅ All users in active users list

### Pass Criteria:
- Multiple cursors work: YES / NO
- Different colors: YES / NO
- No lag: YES / NO

---

## Test 5: Backend Logs Check (2 minutes)

**Objective**: Verify backend working correctly

### Steps:
1. Open backend terminal
2. Join page in browser
3. Move cursor
4. Leave page

### Expected Backend Logs:
```
📄 User <userId> requesting to join page <pageId>
✅ User <userId> joined page <pageId> (owner)
   [User color assigned]

[Cursor updates - minimal logging]

📤 User <userId> leaving page <pageId>
✅ User <userId> left page <pageId>
```

### Pass Criteria:
- Join logs present: YES / NO
- No error messages: YES / NO
- Leave logs present: YES / NO

---

## Test 6: Browser Console Check (1 minute)

**Objective**: Verify no frontend errors

### Steps:
1. Press F12 to open DevTools
2. Go to Console tab
3. Join page and move cursor
4. Check for errors (red text)

### Expected Results:
- ✅ No errors in console
- ✅ Maybe some print statements (normal in dev)
- ✅ WebSocket connection successful

### Pass Criteria:
- No errors: YES / NO
- WebSocket connected: YES / NO

---

## Test 7: Cursor Throttling Check (2 minutes)

**Objective**: Verify updates aren't flooding

### Steps:
1. Open browser DevTools (F12)
2. Go to Network tab → Filter "WS" (WebSocket)
3. Click on WebSocket connection
4. Go to "Messages" tab
5. Move cursor rapidly
6. Observe message frequency

### Expected Results:
- ✅ Messages sent ~10 times per second (not 100+)
- ✅ Each message includes: pageId, position {x, y}
- ✅ No flooding of messages

### Pass Criteria:
- Throttled (not flooding): YES / NO
- ~10 msgs/sec: YES / NO

---

## Quick Troubleshooting

### Issue: Cursor doesn't appear
**Check**:
- ✅ Both windows on SAME page?
- ✅ Backend WebSocket running?
- ✅ Console shows WebSocket connected?
- ✅ Moving cursor on CANVAS (not on sidebar)?

**Fix**: Refresh both windows, rejoin page

### Issue: Active users list empty
**Check**:
- ✅ Backend page:joined event working?
- ✅ PageBloc receiving activeUsers?
- ✅ Sidebar toggle button turned on?

**Fix**: Check backend logs for user join events

### Issue: Cursor jumps/stutters
**Check**:
- ✅ Backend under load?
- ✅ Network latency high?
- ✅ Too many users (10+)?

**Fix**: Normal with network issues, acceptable if rare

### Issue: Cursor doesn't disappear
**Check**:
- ✅ Backend disconnect event firing?
- ✅ Redis cleanup working?
- ✅ Frontend listening to user:left event?

**Fix**: Wait 30s (TTL cleanup), or refresh page

---

## Test Results Summary

Date: _______________  
Tester: _______________

| Test | Pass | Fail | Notes |
|------|------|------|-------|
| 1. Basic Cursor Visibility | ☐ | ☐ | |
| 2. Active Users Sidebar | ☐ | ☐ | |
| 3. Cursor Disappears | ☐ | ☐ | |
| 4. Multiple Cursors | ☐ | ☐ | |
| 5. Backend Logs | ☐ | ☐ | |
| 6. Browser Console | ☐ | ☐ | |
| 7. Cursor Throttling | ☐ | ☐ | |

**Tests Passed**: _____ / 7

**Overall Status**: 
- ✅ All Pass (7/7) → Ready for production
- ⚠️ Mostly Pass (5-6/7) → Minor fixes needed
- ❌ Many Fail (< 5/7) → Needs investigation

---

## Known Limitations (Expected Behavior)

These are NOT bugs:

1. **Cursor doesn't show userName/userColor from backend**
   - Using placeholders currently
   - Backend has data but not sending in cursor event yet
   - **Expected**: Will show "User" and blue color for all

2. **Active users list might be empty**
   - activeUsers from page:joined event not fully integrated
   - **Expected**: Sidebar may not populate on first load

3. **Current user not highlighted**
   - No "You" indicator yet (need auth service)
   - **Expected**: All users look the same

4. **Cursor only works on canvas**
   - MouseRegion only wraps canvas area
   - **Expected**: Cursor doesn't track on sidebar/panels

These will be fixed in future iterations.

---

## Next Steps Based on Results

### If All Tests Pass (7/7): ✅
1. Document test results
2. Mark Phase 3.2 as production-ready
3. Move to Phase 3.3 (Comments) or Phase 3.1 (Undo/Redo)
4. Consider demo video

### If Most Tests Pass (5-6/7): ⚠️
1. Document failed tests
2. Create issues for failures
3. Quick fixes (< 30 min)
4. Retest failed tests
5. Then move to next phase

### If Many Tests Fail (< 5/7): ❌
1. Document all failures with screenshots
2. Check backend/frontend logs
3. Review WebSocket connection
4. Debug systematically
5. Fix critical issues
6. Full retest

---

## Performance Benchmarks

If testing with 5+ users, measure:

| Metric | Target | Actual |
|--------|--------|--------|
| Cursor latency | < 200ms | _____ ms |
| CPU usage | < 10% | _____ % |
| Memory usage | < 100MB | _____ MB |
| Network (per user) | < 10KB/s | _____ KB/s |
| FPS on canvas | 60fps | _____ fps |

---

## Testing Complete! 🎉

**Tested By**: _______________  
**Date**: _______________  
**Result**: ✅ Pass / ⚠️ Partial / ❌ Fail

**Notes**:
_________________________________________
_________________________________________
_________________________________________

**Recommendation**:
☐ Ready for production  
☐ Needs minor fixes  
☐ Needs major rework

---

**Happy Testing!** 🚀

For detailed implementation info, see: `PHASE_3.2_COMPLETE.md`
