# Testing Guide - Follow Mode & Read-Only Features

## ✅ **Currently Running Services:**

| Service | URL | Status |
|---------|-----|--------|
| Backend | `http://localhost:5000` | ✅ Running |
| Frontend (User A) | `http://localhost:3000` | ✅ Running |
| Frontend (User B) | `http://localhost:3001` | ✅ Running |

---

## 🧪 **Test Follow Mode Features:**

### **Test 1: Read-Only Mode** ❌🔒

1. **Open Browser Windows:**
   - Window 1: `http://localhost:3000` (User A)
   - Window 2: `http://localhost:3001` (User B)

2. **Login:**
   - User A: Login with one account
   - User B: Login with a different account

3. **Open Same Page:**
   - Both users navigate to the same page

4. **User B Follows User A:**
   - User B clicks the "Follow" button next to User A's name in the Active Users list

5. **Verify Read-Only Mode for User B:**
   - ❌ Widget library panel should be hidden
   - ❌ Cannot click widgets to select them
   - ❌ Cannot drag widgets
   - ❌ Cannot drop widgets into containers
   - ❌ Mouse cursor is normal (not move cursor)
   - ✅ Banner shows: "Following [User A]" + "🔒 View Only - No Editing"

6. **User B Clicks "Stop":**
   - Editing should be re-enabled
   - Widget library should reappear
   - Can click/drag widgets again

---

### **Test 2: Viewport Synchronization** 📍✨

1. **Setup:**
   - User B is following User A (from Test 1)

2. **User A Actions - User B Should Follow:**
   - ✅ **Scroll Left/Right:** User B's viewport pans horizontally
   - ✅ **Scroll Up/Down:** User B's viewport pans vertically
   - ✅ **Zoom In:** User B's zoom level increases
   - ✅ **Zoom Out:** User B's zoom level decreases
   - ✅ **Pan + Zoom Combo:** User B follows both transformations

3. **Check Smoothness:**
   - ✅ Animation should be smooth (200ms)
   - ✅ No jumping or jittery movement
   - ✅ Minimal lag (50ms throttle)

4. **Check Console Logs:**
   - Look for: `📍 Syncing viewport: zoom=X, scrollX=Y, scrollY=Z`
   - Look for: `✅ Viewport sync complete`

---

### **Test 3: Exit Follow Mode** 🚪

**Method 1: Click "Stop" Button**
1. User B clicks "Stop" in the follow banner
2. ✅ Follow mode should exit
3. ✅ Banner disappears
4. ✅ Editing re-enabled

**Method 2: User Interaction (Zoom/Pan)**
1. User B tries to zoom or pan
2. ✅ Follow mode should exit automatically
3. ✅ Banner disappears
4. ✅ Editing re-enabled

---

### **Test 4: Mutual Follow Prevention** 🚫↔️

1. **User B is following User A**

2. **User A tries to follow User B:**
   - Click "Follow" button next to User B's name

3. **Expected Result:**
   - ❌ Should show error: "Cannot follow - [User B] is already following you"
   - ❌ User A should NOT enter follow mode

---

### **Test 5: Active Users List** 👥

1. **Open Page:**
   - User A opens a page

2. **Check Active Users List:**
   - ✅ Should show User A (but not in the list for User A)
   - ✅ When User B joins, should show User B

3. **User B Joins:**
   - ✅ Active users list updates in real-time
   - ✅ Shows user name and avatar

4. **User B Leaves:**
   - ✅ Active users list updates
   - ✅ User B removed from list

---

## 🐛 **Debugging:**

### **If Follow Mode Doesn't Work:**

1. **Check Browser Console:**
   ```
   F12 → Console Tab
   ```
   - Look for errors
   - Look for follow-related logs

2. **Check Backend Logs:**
   - Look for: `📡 Follow started`
   - Look for: `🔍 Viewport update`
   - Look for errors

3. **Check WebSocket Connection:**
   ```
   F12 → Network Tab → WS (WebSocket)
   ```
   - Should show active connection
   - Should show `page:follow:started` events
   - Should show `page:viewport:updated` events

4. **Check Redis:**
   ```bash
   # In Redis CLI:
   KEYS page:*:following:*
   KEYS page:*:viewport:*
   ```

---

### **If Viewport Sync Doesn't Work:**

1. **Check Console Logs:**
   - Look for: `📍 Syncing viewport: ...`
   - Check zoom, scrollX, scrollY values

2. **Check if Viewport Data is Sent:**
   - User A scrolls → Backend should log viewport update
   - Backend should broadcast to User B

3. **Check Animation:**
   - Should complete in ~200ms
   - Should be smooth (not jumpy)

---

## 📊 **Performance Metrics:**

| Metric | Expected Value |
|--------|---------------|
| Viewport update throttle | 50ms |
| Animation duration | 200ms |
| Animation curve | easeOutCubic |
| WebSocket latency | < 100ms |
| Follow mode activation | Instant |

---

## 🎯 **Success Criteria:**

### **Follow Mode:**
- ✅ User can follow another user's viewport
- ✅ Mutual follow is prevented
- ✅ User can exit follow mode

### **Read-Only Mode:**
- ✅ Widget library hidden when following
- ✅ Cannot select widgets when following
- ✅ Cannot drag widgets when following
- ✅ Cannot drop widgets when following
- ✅ Banner shows "View Only" indicator

### **Viewport Sync:**
- ✅ Scroll position syncs smoothly
- ✅ Zoom level syncs accurately
- ✅ Combined transformations work
- ✅ Minimal lag and smooth animation

### **Active Users:**
- ✅ Real-time join/leave updates
- ✅ Current user filtered out
- ✅ Shows user names and avatars

---

## 🎉 **Ready to Test!**

Open both URLs and start testing:
- **User A:** http://localhost:3000
- **User B:** http://localhost:3001

Have fun testing the collaborative features! 🚀
