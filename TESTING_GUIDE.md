# Canvas Editor - Testing Guide

## ✅ Backend API Tests: PASSED (100%)

All 14 REST API endpoints have been tested and are working correctly:

- ✅ Health Check
- ✅ API Info
- ✅ User Registration
- ✅ User Login
- ✅ Get Current User
- ✅ Create Canvas
- ✅ Get Canvases
- ✅ Get Canvas By ID
- ✅ Create Widget
- ✅ Get Widgets
- ✅ Update Widget
- ✅ Update Canvas
- ✅ Delete Widget
- ✅ Delete Canvas

---

## 🧪 Frontend Manual Testing Guide

### Applications Running:
- **Backend**: http://localhost:5000 (JavaScript)
- **Frontend**: http://127.0.0.1:56153 (Flutter Web)

### Test Scenarios:

#### 1. **User Authentication** 🔐

**Test Registration:**
1. Open frontend: http://127.0.0.1:56153
2. Look for Register/Sign Up screen
3. Fill in registration form:
   - Email: your_email@example.com
   - Password: password123
   - Name: Your Name
4. Click Register/Submit
5. ✅ Should see success message or redirect to login/home

**Test Login:**
1. If not logged in, go to Login screen
2. Enter credentials:
   - Email: (use the email you registered with)
   - Password: password123
3. Click Login
4. ✅ Should be redirected to canvas list or main dashboard

---

#### 2. **Canvas Management** 🎨

**Test Create Canvas:**
1. After login, look for "Create Canvas" or "New Canvas" button
2. Click to create new canvas
3. Enter canvas details:
   - Name: "My Test Canvas"
   - Description: "Testing canvas creation"
4. Click Create/Save
5. ✅ Should see new canvas in list or open canvas editor

**Test View Canvas List:**
1. Navigate to canvas list/dashboard
2. ✅ Should see all your canvases displayed
3. ✅ Should show canvas names and metadata

**Test Open Canvas:**
1. Click on a canvas from the list
2. ✅ Should open canvas editor view
3. ✅ Should see empty canvas or existing widgets

---

#### 3. **Widget Operations** 🔷

**Test Add Widget:**
1. In canvas editor, look for "Add Widget" or widget toolbar
2. Select a widget type (rectangle, circle, text, etc.)
3. Click on canvas to place widget
4. ✅ Widget should appear on canvas
5. ✅ Check browser console for no errors

**Test Move Widget:**
1. Click and drag a widget
2. Move it to different position
3. ✅ Widget should move smoothly
4. ✅ Position should be saved (refresh page to verify)

**Test Resize Widget:**
1. Select a widget
2. Look for resize handles
3. Drag handles to resize
4. ✅ Widget should resize correctly

**Test Update Widget Properties:**
1. Select a widget
2. Look for properties panel
3. Change properties:
   - Color
   - Border width
   - Text content (if text widget)
4. ✅ Changes should apply immediately

**Test Delete Widget:**
1. Select a widget
2. Press Delete key or click Delete button
3. ✅ Widget should be removed from canvas

---

#### 4. **Real-time Collaboration** 🔄 (WebSocket)

**Test Multi-User (if possible):**
1. Open canvas in two browser windows/tabs
2. Login with same or different accounts
3. Open the same canvas in both windows
4. Add/move/delete widget in one window
5. ✅ Changes should appear in other window automatically

**Test Cursor Tracking:**
1. With two users in same canvas
2. Move cursor in one window
3. ✅ Should see other user's cursor position in second window

**Test User Presence:**
1. When joining a canvas
2. ✅ Should see list of active users in canvas
3. When user leaves
4. ✅ User should be removed from active users list

---

#### 5. **Error Handling** ⚠️

**Test Offline Backend:**
1. Stop backend server (Ctrl+C in backend terminal)
2. Try to perform operations in frontend
3. ✅ Should show appropriate error messages
4. Restart backend and retry
5. ✅ Operations should work again

**Test Invalid Data:**
1. Try to create canvas with empty name
2. ✅ Should show validation error
3. Try invalid email format during registration
4. ✅ Should show email validation error

---

## 📊 Testing Checklist

### Authentication
- [ ] Register new user
- [ ] Login with valid credentials
- [ ] Login with invalid credentials (should fail)
- [ ] Access protected routes without login (should redirect)
- [ ] Logout functionality

### Canvas Operations
- [ ] Create new canvas
- [ ] View canvas list
- [ ] Open canvas
- [ ] Update canvas details
- [ ] Delete canvas

### Widget Operations
- [ ] Add widget to canvas
- [ ] Move widget
- [ ] Resize widget
- [ ] Update widget properties
- [ ] Delete widget
- [ ] Multiple widgets on same canvas

### Real-time Features
- [ ] WebSocket connection established
- [ ] Real-time widget updates
- [ ] User presence indicators
- [ ] Cursor tracking (if implemented)

### Performance
- [ ] App loads quickly
- [ ] Smooth animations
- [ ] No memory leaks (check browser DevTools)
- [ ] No console errors

---

## 🐛 Common Issues & Solutions

### Backend not responding:
- Check backend terminal for errors
- Verify backend is running: http://localhost:5000/health
- Check PostgreSQL is running
- Check Redis is running

### Frontend not loading:
- Check frontend terminal for errors
- Try refreshing browser
- Clear browser cache
- Check browser console for JavaScript errors

### WebSocket not connecting:
- Check backend WebSocket setup
- Verify CORS settings
- Check browser network tab for WebSocket connection

### Database errors:
- Verify PostgreSQL is running
- Check database credentials in .env file
- Run migrations: `npm run migrate`

---

## 📝 Test Results

**Date**: _________________________

**Tested By**: _________________________

### Results Summary:
- Authentication: ⬜ PASS / ⬜ FAIL
- Canvas Operations: ⬜ PASS / ⬜ FAIL
- Widget Operations: ⬜ PASS / ⬜ FAIL
- Real-time Features: ⬜ PASS / ⬜ FAIL
- Overall: ⬜ PASS / ⬜ FAIL

### Notes:
_________________________________________
_________________________________________
_________________________________________
_________________________________________

---

## 🚀 Next Steps After Testing

If all tests pass:
1. ✅ Add more widget types
2. ✅ Implement undo/redo
3. ✅ Add export functionality
4. ✅ Prepare for production deployment

If tests fail:
1. ❌ Document issues found
2. ❌ Check browser console for errors
3. ❌ Check backend logs
4. ❌ Fix bugs and retest
