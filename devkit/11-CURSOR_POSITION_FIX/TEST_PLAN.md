# Cursor Position Fix - Test Plan

## Overview
This document provides a comprehensive test plan for verifying the cursor position synchronization fix.

---

## ✅ Implementation Status

**Status:** COMPLETE  
**Date:** September 1, 2026

### Files Modified:
1. `frontend/lib/features/page/views/page_canvas_view.dart`
2. `frontend/lib/features/page/views/page_editor_screen.dart`
3. `frontend/lib/features/page/managers/cursor_manager.dart`

---

## 🧪 Test Scenarios

### Test 1: Basic Cursor Positioning (No Zoom/Pan)
**Objective:** Verify cursors appear at correct positions without transformations

**Steps:**
1. Open the same page in two browser windows (User A and User B)
2. Both users at default zoom (1.0) and no pan
3. User A moves cursor to center of canvas
4. User B should see User A's cursor at exact center

**Expected Result:**
- ✅ Cursor appears at same relative position for both users
- ✅ No offset or misalignment

**Pass Criteria:**
- Cursor position matches within 5px tolerance

---

### Test 2: Cursor Positioning with Zoom In
**Objective:** Verify cursors stay accurate when users zoom in

**Steps:**
1. User A zooms canvas to 2.0x (zoom in)
2. User A moves cursor around canvas
3. User B observes at default 1.0x zoom

**Expected Result:**
- ✅ User A sees own cursor at mouse position
- ✅ User B sees User A's cursor at correct canvas location
- ✅ Cursor position stays synchronized despite different zoom levels

**Test Matrix:**
| User A Zoom | User B Zoom | Expected |
|-------------|-------------|----------|
| 2.0x        | 1.0x        | ✅ Synced |
| 3.0x        | 1.0x        | ✅ Synced |
| 1.0x        | 2.0x        | ✅ Synced |
| 2.0x        | 2.0x        | ✅ Synced |

**Pass Criteria:**
- Cursor appears at same canvas coordinates regardless of zoom

---

### Test 3: Cursor Positioning with Zoom Out
**Objective:** Verify cursors stay accurate when users zoom out

**Steps:**
1. User A zooms canvas to 0.5x (zoom out)
2. User A moves cursor around canvas
3. User B observes at default 1.0x zoom

**Expected Result:**
- ✅ Cursor position correctly transformed
- ✅ No drift or offset when zooming out

**Test Matrix:**
| User A Zoom | User B Zoom | Expected |
|-------------|-------------|----------|
| 0.5x        | 1.0x        | ✅ Synced |
| 0.3x        | 1.0x        | ✅ Synced |
| 1.0x        | 0.5x        | ✅ Synced |
| 0.5x        | 0.5x        | ✅ Synced |

**Pass Criteria:**
- Cursor maintains correct position at all zoom levels

---

### Test 4: Cursor Positioning with Pan
**Objective:** Verify cursors stay accurate when canvas is panned

**Steps:**
1. User A pans canvas right and down (offset +200, +150)
2. User A moves cursor to specific widget
3. User B observes at default pan (0, 0)

**Expected Result:**
- ✅ User B sees cursor at correct widget
- ✅ Pan offset doesn't cause cursor misalignment

**Test Cases:**
- Pan left: ✅
- Pan right: ✅
- Pan up: ✅
- Pan down: ✅
- Pan diagonal: ✅

**Pass Criteria:**
- Cursor always points to same canvas element

---

### Test 5: Cursor Positioning with Combined Zoom + Pan
**Objective:** Verify cursors work with both zoom and pan active

**Steps:**
1. User A: Zoom to 2.0x and pan (+100, +100)
2. User B: Zoom to 1.5x and pan (-50, +75)
3. User A moves cursor to widget center
4. User B should see cursor at same widget center

**Expected Result:**
- ✅ Cursor appears at correct position despite different transformations
- ✅ No cumulative error from combined transforms

**Pass Criteria:**
- Cursor accurately synchronized with complex transformations

---

### Test 6: Rapid Zoom Changes
**Objective:** Verify cursor tracking during rapid zoom changes

**Steps:**
1. User A rapidly zooms in and out (scroll wheel)
2. User A moves cursor while zooming
3. User B observes cursor behavior

**Expected Result:**
- ✅ Cursor smoothly updates position
- ✅ No lag or stuttering
- ✅ Position remains accurate throughout

**Pass Criteria:**
- Smooth cursor updates during zoom
- Position accuracy maintained

---

### Test 7: Rapid Pan Changes
**Objective:** Verify cursor tracking during rapid pan movements

**Steps:**
1. User A rapidly pans canvas in all directions
2. User A moves cursor while panning
3. User B observes cursor behavior

**Expected Result:**
- ✅ Cursor updates smoothly
- ✅ No position jumps or glitches

**Pass Criteria:**
- Fluid cursor movement during pan
- Accurate position maintained

---

### Test 8: Multiple Users with Different Transformations
**Objective:** Verify system handles 3+ users with different zoom/pan states

**Setup:**
- User A: Zoom 2.0x, Pan (+100, +50)
- User B: Zoom 1.0x, Pan (0, 0)
- User C: Zoom 0.5x, Pan (-150, +200)

**Steps:**
1. All users move cursors simultaneously
2. Each user observes other users' cursors

**Expected Result:**
- ✅ Each user sees all other cursors at correct positions
- ✅ No cross-talk or interference
- ✅ All transformations independent

**Pass Criteria:**
- All cursors correctly positioned for all users

---

### Test 9: Edge Cases

#### Test 9a: Min Zoom (0.1x)
- Zoom to minimum (0.1x)
- Move cursor
- Verify position accuracy

#### Test 9b: Max Zoom (5.0x)
- Zoom to maximum (5.0x)
- Move cursor
- Verify position accuracy

#### Test 9c: Extreme Pan
- Pan to canvas edge/corner
- Move cursor
- Verify position accuracy

#### Test 9d: Canvas Boundaries
- Move cursor to canvas edges
- Verify cursor doesn't clip incorrectly

**Pass Criteria:**
- Cursors work correctly at all extremes

---

### Test 10: Transformation Controller Lifecycle

#### Test 10a: Before Controller Ready
- Move cursor immediately after joining page
- Verify fallback behavior works

#### Test 10b: After Controller Ready
- Wait for controller initialization
- Verify transformations apply correctly

**Expected Result:**
- ✅ Graceful handling before controller ready
- ✅ Seamless transition when controller becomes available

**Pass Criteria:**
- No crashes or errors
- Smooth cursor behavior throughout lifecycle

---

## 🔍 Visual Verification Tests

### Test 11: Widget Selection Synchronization
**Objective:** Verify cursor points to correct widgets

**Steps:**
1. User A hovers over specific widget
2. User B should see cursor over same widget
3. Test with nested widgets

**Pass Criteria:**
- Cursor hovers over intended widget
- Works for all widget types

---

### Test 12: Cursor on Drag Operations
**Objective:** Verify cursor accuracy during drag and drop

**Steps:**
1. User A drags widget
2. User B observes drag cursor
3. Verify cursor follows dragged widget

**Pass Criteria:**
- Cursor tracks dragged element accurately

---

## 🐛 Bug Regression Tests

### Test 13: Original Bug Verification
**Objective:** Confirm the original bug is fixed

**Original Issue:**
- Users with different screen sizes saw cursors at wrong positions
- Middle cursor appeared as middle-right

**Steps:**
1. Open on different screen sizes (1920x1080, 1366x768)
2. User A moves cursor to canvas center
3. User B verifies cursor is at center

**Expected Result:**
- ✅ Bug no longer reproducible
- ✅ Cursor appears at correct position

---

## 📊 Performance Tests

### Test 14: Cursor Update Performance
**Objective:** Verify cursor updates don't cause lag

**Steps:**
1. Rapidly move cursor across canvas
2. Monitor frame rate and responsiveness
3. Check with 5+ concurrent users

**Expected Result:**
- ✅ Smooth cursor movement
- ✅ No frame drops
- ✅ No perceptible lag

**Pass Criteria:**
- Maintains 60 FPS
- Cursor update latency < 50ms

---

### Test 15: Memory Leak Test
**Objective:** Ensure transformation calculations don't leak memory

**Steps:**
1. Continuously move cursor for 10 minutes
2. Zoom/pan repeatedly
3. Monitor memory usage

**Expected Result:**
- ✅ Stable memory usage
- ✅ No memory growth over time

**Pass Criteria:**
- Memory stays below 100MB increase

---

## ✅ Test Results Template

```markdown
## Test Execution Results

**Date:** [Date]
**Tester:** [Name]
**Environment:** [Browser/OS]

| Test # | Test Name | Status | Notes |
|--------|-----------|--------|-------|
| 1 | Basic Positioning | ⬜ | |
| 2 | Zoom In | ⬜ | |
| 3 | Zoom Out | ⬜ | |
| 4 | Pan | ⬜ | |
| 5 | Zoom + Pan | ⬜ | |
| 6 | Rapid Zoom | ⬜ | |
| 7 | Rapid Pan | ⬜ | |
| 8 | Multiple Users | ⬜ | |
| 9 | Edge Cases | ⬜ | |
| 10 | Lifecycle | ⬜ | |
| 11 | Widget Selection | ⬜ | |
| 12 | Drag Operations | ⬜ | |
| 13 | Bug Regression | ⬜ | |
| 14 | Performance | ⬜ | |
| 15 | Memory Leak | ⬜ | |

**Legend:**
- ✅ Pass
- ❌ Fail
- ⚠️ Partial Pass
- ⬜ Not Tested
```

---

## 🚀 How to Run Tests

### Setup
1. Start backend server: `cd backend && npm start`
2. Start frontend: `cd frontend && flutter run -d chrome`
3. Open multiple browser windows/tabs

### Testing Process
1. Follow test steps exactly
2. Document any deviations
3. Take screenshots of failures
4. Note browser/OS versions

### Reporting Issues
If tests fail, provide:
- Test number and name
- Expected vs actual behavior
- Screenshots/videos
- Browser and OS details
- Console errors

---

## 📝 Notes

### Known Limitations
- Transformation applies to cursors only (not other elements yet)
- Fallback to untransformed coordinates if controller not ready
- Minor precision loss at extreme zoom levels (acceptable)

### Future Improvements
- Add transformation to selection boxes
- Add transformation to comments/annotations
- Optimize matrix calculations for better performance

---

**Test Plan Version:** 1.0  
**Last Updated:** September 1, 2026  
**Status:** Ready for Testing
