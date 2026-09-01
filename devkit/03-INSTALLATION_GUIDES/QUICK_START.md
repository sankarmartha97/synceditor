# Canvas Editor - Quick Start Guide

## 🚀 Applications Running

| Application | URL | Status | Technology |
|-------------|-----|--------|------------|
| **Backend API** | http://localhost:5000 | ✅ Running | Node.js (JavaScript) |
| **Frontend** | http://127.0.0.1:56153 | ✅ Running | Flutter Web |
| **Database** | localhost:5432 | ✅ Connected | PostgreSQL 16 |
| **Cache** | localhost:6379 | ✅ Connected | Redis |

---

## 📱 Open the Application

**Click here to open the frontend:**  
👉 http://127.0.0.1:56153

---

## 🔍 Quick Health Check

**Backend Health:**  
```
curl http://localhost:5000/health
```

**API Info:**  
```
curl http://localhost:5000/api
```

---

## 🧪 Test Status

### Backend API Tests: ✅ **100% PASS** (14/14 tests)

| Category | Tests | Status |
|----------|-------|--------|
| Health & System | 2/2 | ✅ |
| Authentication | 3/3 | ✅ |
| Canvas Management | 5/5 | ✅ |
| Widget Management | 4/4 | ✅ |

---

## 📖 What to Test Next

### 1. **Registration & Login** (Start Here)
1. Open frontend: http://127.0.0.1:56153
2. Register a new user
3. Login with your credentials

### 2. **Create Your First Canvas**
1. Click "Create Canvas" button
2. Enter canvas name
3. Start adding widgets!

### 3. **Test Real-time Features**
1. Open canvas in 2 browser tabs
2. Make changes in one tab
3. See updates appear in other tab

---

## 🎯 Features Available

### ✅ Working Features
- User Registration & Login
- JWT Authentication
- Canvas CRUD operations
- Widget CRUD operations
- Real-time WebSocket collaboration
- User presence tracking
- Cursor tracking
- Widget versioning

### 🔄 WebSocket Events (15 events)
**Client → Server:**
- canvas:join, canvas:leave
- widget:add, widget:update, widget:delete
- cursor:move, cursor:hide

**Server → Client:**
- canvas:joined, canvas:left
- widget:added, widget:updated, widget:deleted
- user:joined, user:left
- cursor:updated, cursor:hidden
- sync:error

---

## 📚 API Endpoints (18 total)

### Authentication
```
POST   /api/auth/register    - Register new user
POST   /api/auth/login       - Login user
GET    /api/auth/me          - Get current user
POST   /api/auth/logout      - Logout user
```

### Canvas Management
```
GET    /api/canvases         - Get all canvases
POST   /api/canvases         - Create new canvas
GET    /api/canvases/:id     - Get canvas by ID
PUT    /api/canvases/:id     - Update canvas
DELETE /api/canvases/:id     - Delete canvas
```

### Collaborators
```
GET    /api/canvases/:id/collaborators        - Get collaborators
POST   /api/canvases/:id/collaborators        - Add collaborator
DELETE /api/canvases/:id/collaborators/:uid   - Remove collaborator
```

### Widgets
```
GET    /api/canvases/:cid/widgets             - Get all widgets
POST   /api/canvases/:cid/widgets             - Create widget
GET    /api/canvases/:cid/widgets/:wid        - Get widget
PUT    /api/canvases/:cid/widgets/:wid        - Update widget
DELETE /api/canvases/:cid/widgets/:wid        - Delete widget
POST   /api/canvases/:cid/widgets/batch       - Batch update
```

---

## 🛠️ Development Commands

### Backend
```bash
cd backend
npm run dev          # Start JavaScript backend (current)
npm run dev:ts       # Start TypeScript backend
npm run start        # Production start
```

### Frontend
```bash
cd frontend
flutter run -d chrome    # Start in Chrome (current)
flutter clean            # Clean build
flutter pub get          # Get dependencies
```

### Database
```bash
# Check PostgreSQL status
Get-Service -Name postgresql*

# Check Redis status
redis-cli ping
```

---

## 🔧 Restart Everything

If something goes wrong, restart in this order:

```bash
# 1. Stop all
Ctrl+C in backend terminal
Ctrl+C in frontend terminal

# 2. Restart PostgreSQL (if needed)
Restart-Service postgresql*

# 3. Restart Redis (if needed)
redis-server

# 4. Start Backend
cd backend
npm run dev

# 5. Start Frontend
cd frontend
flutter run -d chrome
```

---

## 📊 Monitoring

### Backend Logs
Check backend terminal for:
- API requests (GET, POST, PUT, DELETE)
- WebSocket connections
- Database queries
- Errors

### Browser DevTools
Press F12 in Chrome:
- **Console**: Check for JavaScript errors
- **Network**: Monitor API calls
- **WebSocket**: Check WS connections

---

## 🐛 Troubleshooting

### Backend Not Responding
```bash
# Check if backend is running
curl http://localhost:5000/health

# Check processes
Get-Process -Name node

# Restart backend
cd backend
npm run dev
```

### Frontend Not Loading
```bash
# Check Flutter process
flutter doctor

# Restart Flutter
flutter clean
flutter pub get
flutter run -d chrome
```

### Database Connection Issues
```bash
# Test PostgreSQL
psql -U canvas_user -d canvas_db

# Test Redis
redis-cli ping
```

---

## 📞 Quick Reference

| What | Where |
|------|-------|
| Frontend | http://127.0.0.1:56153 |
| Backend API | http://localhost:5000 |
| API Health | http://localhost:5000/health |
| API Docs | http://localhost:5000/api |
| Test Script | `node backend/test-api.js` |
| Testing Guide | `TESTING_GUIDE.md` |
| Test Results | `TEST_RESULTS.md` |

---

## 🎉 You're All Set!

Your Canvas Editor is ready to use! Open http://127.0.0.1:56153 and start creating!

**Need help?** Check the testing guide or test results for detailed information.
