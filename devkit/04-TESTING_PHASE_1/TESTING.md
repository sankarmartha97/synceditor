# Testing Real-Time Collaboration

## Currently Running Instances

### Backend
- **URL**: http://localhost:5000
- **Status**: ✅ Running
- **Health Check**: http://localhost:5000/health

### Frontend Instance 1 (Alice)
- **URL**: http://localhost:3000
- **Email**: alice@test.com
- **Password**: test123456
- **Status**: ✅ Running

### Frontend Instance 2 (Bob)
- **URL**: http://localhost:3001
- **Email**: bob@test.com
- **Password**: test123456
- **Status**: ✅ Running

---

## How to Start Testing

### 1. Open Both Browser Windows

**Window 1 (Alice):**
1. Navigate to: http://localhost:3000
2. Login with:
   - Email: `alice@test.com`
   - Password: `test123456`

**Window 2 (Bob):**
1. Navigate to: http://localhost:3001
2. Login with:
   - Email: `bob@test.com`
   - Password: `test123456`

### 2. Create or Open a Page

- In Alice's window, create a new page or open an existing one
- In Bob's window, open the **same page**
- You should see "Bob" appear in Alice's active users list

---

## Test Scenarios

### ✅ Test 1: Design Persistence (FIXED!)
**What was broken:** Widgets would appear temporarily but disappear after refresh

**Test Steps:**
1. In Alice's browser, drag and drop a Container widget
2. Refresh Alice's browser (F5)
3. **Expected:** Widget should still be there ✅
4. Open Bob's browser and navigate to the same page
5. **Expected:** Bob should see Alice's widget ✅

**Why it was broken:** Frontend was sending patches with incremented version (v2) but server had v1, causing version conflict and patch rejection.

**The Fix:** Modified `page_bloc.dart` to send patches with the current version (before incrementing).

---

### ✅ Test 2: Real-Time Sync
**Test Steps:**
1. Both Alice and Bob open the same page
2. In Alice's browser, drop a widget (Container, Text, Button, etc.)
3. **Expected:** Widget appears instantly in Bob's browser ✅
4. In Alice's browser, drag the widget to move it
5. **Expected:** Bob sees the widget moving in real-time ✅
6. In Alice's browser, open properties panel and change background color
7. **Expected:** Bob sees color change instantly ✅

---

### ✅ Test 3: Undo/Redo (FIXED!)
**What was broken:** Undo would fail with error: "Unexpected token 'o', "[object Obj"... is not valid JSON"

**Test Steps:**
1. In Alice's browser, drop a widget
2. Press **Ctrl+Z** or click Undo button
3. **Expected:** Widget disappears ✅
4. **Expected:** Bob sees the widget disappear ✅
5. Press **Ctrl+Y** or click Redo button
6. **Expected:** Widget reappears ✅
7. **Expected:** Bob sees the widget reappear ✅

**Why it was broken:** Backend was trying to `JSON.parse()` JSONB fields that were already JavaScript objects.

**The Fix:** Modified `operationHistory.service.js` to check type before parsing:
```javascript
operation: typeof row.operation === 'string' ? JSON.parse(row.operation) : row.operation
```

---

### ✅ Test 4: Multi-User Editing
**Test Steps:**
1. Alice drops a Container widget
2. Bob drops a Text widget
3. Alice moves her Container
4. Bob changes Text widget color
5. **Expected:** Both users see all changes in real-time ✅
6. **Expected:** No conflicts or lost updates ✅

---

### ✅ Test 5: User Presence
**Test Steps:**
1. Alice opens a page
2. Bob opens the same page
3. **Expected:** Alice sees "Bob" in the active users list ✅
4. **Expected:** Bob sees "Alice" in the active users list ✅
5. Alice moves her cursor around the canvas
6. **Expected:** Bob sees Alice's cursor moving (if cursor sync is enabled) ✅
7. Bob closes his browser
8. **Expected:** "Bob" disappears from Alice's active users list ✅

---

## Commands to Start Instances

### Start Backend
```bash
cd backend
npm run dev
```

### Start Frontend Instance 1 (Port 3000)
```bash
cd frontend
flutter run -d chrome --web-hostname=localhost --web-port=3000
```

### Start Frontend Instance 2 (Port 3001)
```bash
# Open a NEW terminal window
cd frontend
flutter run -d chrome --web-hostname=localhost --web-port=3001
```

---

## Stopping Instances

### Stop All
Press `q` in each terminal running Flutter, or use Ctrl+C

### Stop Specific Instance
Navigate to the terminal and press `q`

---

## Troubleshooting

### Port Already in Use
```bash
# Windows - Kill process on port 3000
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Or kill all Node/Flutter processes
taskkill /F /IM node.exe
taskkill /F /IM flutter.exe
```

### Backend Not Responding
```bash
# Check if backend is running
curl http://localhost:5000/health

# Restart backend
cd backend
npm run dev
```

### WebSocket Not Connecting
1. Check backend logs for errors
2. Verify backend is running on port 5000
3. Check browser console for connection errors
4. Ensure CORS is configured correctly in backend

---

## Recent Fixes Applied

### 1. Design Persistence Fix (2024-08-28)
**File:** `frontend/lib/features/page/bloc/page_bloc.dart`

**Changes:**
- Added `currentVersion` variable to capture version before incrementing
- Send patches with original version instead of incremented version
- Applied to: `_onAddWidgetToPage`, `_onUpdateWidgetInPage`, `_onRemoveWidgetFromPage`

**Impact:** Widgets now persist correctly to database and survive page refreshes

---

### 2. Undo/Redo Fix (2024-08-28)
**File:** `backend/src-js/services/operationHistory.service.js`

**Changes:**
- Modified `getOperationsSinceVersion()` to check type before JSON.parse
- Handle both string and object types for JSONB fields

**Impact:** Undo/Redo now works without JSON parsing errors

---

## Next Steps

After testing, you may want to:
1. Test with 3+ users simultaneously
2. Test edge cases (network disconnect/reconnect)
3. Test performance with many widgets (100+)
4. Test on different browsers (Chrome, Firefox, Safari)
5. Test undo/redo with concurrent edits

---

**All systems ready for testing! 🚀**
