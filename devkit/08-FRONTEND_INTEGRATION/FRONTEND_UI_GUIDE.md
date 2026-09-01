# 🎨 Canvas Editor - Frontend UI Guide

**🌐 Open the app**: http://127.0.0.1:56153

---

## 📱 What You'll See - Screen by Screen

### 🔐 SCREEN 1: Login Page (Initial View)

```
┌─────────────────────────────────────────────────┐
│                                                 │
│                    [Draw Icon]                  │
│                                                 │
│                  Canvas Editor                  │
│           Collaborative Design Platform         │
│                                                 │
│              ┌──────────────────┐               │
│              │ 📧 Email        │               │
│              └──────────────────┘               │
│                                                 │
│              ┌──────────────────┐               │
│              │ 🔒 Password     │               │
│              └──────────────────┘               │
│                                                 │
│              ┌──────────────────┐               │
│              │      Login       │               │
│              └──────────────────┘               │
│                                                 │
│         Don't have an account? Register         │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Actions to Try:**
1. ✅ Click **"Register"** link to create new account
2. ✅ Enter email and password to login
3. ✅ Click eye icon to show/hide password

---

### 📝 SCREEN 2: Register Page

```
┌─────────────────────────────────────────────────┐
│                                                 │
│                    [Draw Icon]                  │
│                                                 │
│               Create Account                    │
│           Join Canvas Editor Today              │
│                                                 │
│              ┌──────────────────┐               │
│              │ 👤 Name         │               │
│              └──────────────────┘               │
│                                                 │
│              ┌──────────────────┐               │
│              │ 📧 Email        │               │
│              └──────────────────┘               │
│                                                 │
│              ┌──────────────────┐               │
│              │ 🔒 Password     │               │
│              └──────────────────┘               │
│                                                 │
│              ┌──────────────────┐               │
│              │     Register     │               │
│              └──────────────────┘               │
│                                                 │
│          Already have an account? Login         │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Test Registration:**
```
Name:     Test User
Email:    mytest@example.com
Password: password123
```

Click **"Register"** → Should redirect to Canvas Editor

---

### 🎨 SCREEN 3: Canvas Editor (Main Application)

```
┌──────────────────────────────────────────────────────────────────────┐
│ Canvas Editor          [↶ Undo] [↷ Redo]    [🔷 X widgets]          │
├──────────────────────────────────────────────────────────────────────┤
│          │                                      │                    │
│          │                                      │                    │
│ Widget   │         Canvas Area                  │   Properties       │
│ Library  │      (Gray background)               │   Panel            │
│          │                                      │  (Only when        │
│ - Text   │    [Place widgets here]              │   widget           │
│ - Box    │                                      │   selected)        │
│ - Circle │                                      │                    │
│ - Image  │                                      │   • Position       │
│ - Line   │                                      │   • Size           │
│          │                                      │   • Color          │
│ (280px)  │         (Expandable)                 │   • Properties     │
│          │                                      │   (300px)          │
│          │                                      │                    │
└──────────────────────────────────────────────────────────────────────┘
```

**Layout:**
- **Left Panel (280px)**: Widget Library - drag widgets from here
- **Center Panel (Expandable)**: Main canvas - place and edit widgets
- **Right Panel (300px)**: Properties - appears when widget is selected
- **Top Bar**: App title, Undo/Redo buttons, widget count

---

## 🧪 Testing Steps - Follow Along!

### ✅ TEST 1: Load & Login (2 min)

**Step 1:** Open http://127.0.0.1:56153
- ✅ Login screen should appear immediately
- ✅ Blue draw icon at top
- ✅ "Canvas Editor" title visible

**Step 2:** Register a new user
- Click **"Don't have an account? Register"**
- Fill in:
  ```
  Name:     My Test User
  Email:    test1@example.com
  Password: password123
  ```
- Click **"Register"**
- ✅ Should redirect to Canvas Editor screen

**What if it fails?**
- Check browser console (F12) for errors
- Look at Network tab for API call to `/api/auth/register`
- Check backend terminal for error messages

---

### ✅ TEST 2: Explore Canvas Editor (2 min)

**After successful login, you should see:**

1. **Top Bar:**
   - "Canvas Editor" title on left
   - Undo button (↶)
   - Redo button (↷)
   - Widget count chip (e.g., "0 widgets")

2. **Left Panel (Widget Library):**
   - List of available widget types
   - May include: Text, Rectangle, Circle, etc.
   - Click to select widget type

3. **Center Panel (Canvas):**
   - Gray background area
   - Empty initially
   - This is where you place widgets

4. **Right Panel (Properties):**
   - Only appears when widget is selected
   - Hidden initially (no widgets yet)

---

### ✅ TEST 3: Check API Connection (1 min)

**Open Browser DevTools:**
1. Press **F12**
2. Go to **Console** tab
3. Look for any errors (red text)

**Go to Network Tab:**
1. Click **"Network"** tab
2. Look for these API calls:
   - ✅ `POST /api/auth/register` - Status 201
   - ✅ `POST /api/auth/login` - Status 200
   - ✅ `GET /api/auth/me` - Status 200

**All requests should show:**
- Status: 200 or 201 (green)
- No CORS errors
- Response with user data

---

### ✅ TEST 4: Check WebSocket (1 min)

**In DevTools Network Tab:**
1. Click **"WS"** filter at top
2. Look for WebSocket connection

**Should see:**
- Connection to `ws://localhost:5000`
- Status: 101 Switching Protocols
- Shows as "open" or "connected"

**WebSocket Events to watch for:**
- Connection established
- Canvas join event
- Widget updates (when you add widgets)

---

### ✅ TEST 5: Try Adding Widgets (if implemented)

**Steps:**
1. Look at **Left Panel (Widget Library)**
2. Click on a widget type (e.g., "Rectangle")
3. Click on the **canvas** to place it
4. Widget should appear on canvas

**What to check:**
- ✅ Widget appears where you clicked
- ✅ Widget is selectable (click on it)
- ✅ Properties panel appears on right
- ✅ Can modify widget properties
- ✅ Can drag widget to move it
- ✅ Widget count updates in top bar

---

### ✅ TEST 6: Real-time Collaboration (2 min)

**Open TWO tabs:**
1. Tab 1: http://127.0.0.1:56153 (already open)
2. Tab 2: Open in new tab (Ctrl+T → same URL)

**In Tab 2:**
- Login with **same credentials**
- Should see same canvas

**Test real-time sync:**
1. Add widget in **Tab 1**
2. Watch **Tab 2** - should appear automatically
3. Move widget in **Tab 2**
4. Watch **Tab 1** - should update

✅ **Both tabs stay in sync without refresh!**

---

## 🎯 Expected Behavior Summary

### ✅ What Should Work:

| Feature | Expected Behavior |
|---------|-------------------|
| **Login Screen** | Clean UI, email/password fields, validation |
| **Registration** | Create account, redirect to editor |
| **Canvas Editor** | 3-panel layout loads correctly |
| **Widget Library** | List of widgets on left panel |
| **Canvas Area** | Gray background, ready for widgets |
| **API Connection** | All requests succeed (200/201) |
| **WebSocket** | Connection established and stays open |
| **Authentication** | Token stored, auto-login on refresh |

---

## 🐛 Troubleshooting Guide

### Problem: Login screen doesn't load
**Solutions:**
1. Check backend is running: http://localhost:5000/health
2. Hard refresh: **Ctrl+Shift+R**
3. Clear browser cache
4. Check browser console for errors

### Problem: Registration fails
**Check:**
1. Network tab → Look at API response
2. Backend terminal → Check for errors
3. Database → Verify PostgreSQL is running
4. Try different email (might already exist)

### Problem: Canvas editor is blank
**Solutions:**
1. Check browser console for errors
2. Verify you're logged in (check token in Application → Local Storage)
3. Try logout and login again
4. Check if JavaScript errors prevent rendering

### Problem: Widgets don't appear
**Possible reasons:**
1. Widget functionality not yet implemented
2. JavaScript error preventing rendering
3. Canvas BLoC state issue
4. Check console for errors

### Problem: No real-time updates
**Check:**
1. WebSocket connection (DevTools → Network → WS)
2. Backend WebSocket server running
3. Both tabs logged in with same user
4. Browser console for connection errors

---

## 📊 Testing Checklist - Quick Reference

**Pre-flight:**
- [ ] Backend running: http://localhost:5000/health ✅
- [ ] Frontend running: http://127.0.0.1:56153 ✅
- [ ] Browser DevTools open (F12)

**User Flow:**
- [ ] Login screen loads
- [ ] Can register new user
- [ ] Can login successfully
- [ ] Canvas editor appears
- [ ] Widget library visible
- [ ] Canvas area visible
- [ ] Properties panel logic works

**API Integration:**
- [ ] Auth API calls succeed
- [ ] Token stored in localStorage
- [ ] Auto-login works (refresh page)
- [ ] API errors handled gracefully

**Real-time:**
- [ ] WebSocket connects
- [ ] Multi-tab sync works
- [ ] Updates appear instantly
- [ ] No disconnections

---

## 🎉 Success Criteria

**You'll know it's working when:**

1. ✅ You can register and login
2. ✅ Canvas editor loads with 3-panel layout
3. ✅ No errors in browser console
4. ✅ API calls show in Network tab (green status)
5. ✅ WebSocket connection established
6. ✅ Token saved (check Application → Local Storage)
7. ✅ Page works after refresh (auto-login)
8. ✅ Two tabs can see each other's changes (if widgets working)

---

## 📞 Quick Help

### Check Backend Status:
```bash
curl http://localhost:5000/health
```

Should return:
```json
{
  "success": true,
  "message": "Server is healthy"
}
```

### View Backend Logs:
Check the backend terminal for API request logs

### Check Database:
```bash
# Check users table
node backend/check-database.js
```

---

## 🚀 Start Testing NOW!

**Your frontend is open at**: http://127.0.0.1:56153

**Follow these steps:**
1. Look at the login screen
2. Register a new user
3. Explore the canvas editor
4. Check browser DevTools
5. Open a second tab and test real-time

**Report back what you see!** 📝
