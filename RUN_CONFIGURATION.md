# SyncEditor - Run Configuration

## 🎯 Standard Run Configuration

When you say **"run all"** or **"re run all"**, the following servers will be started:

### Servers to Run:

| Server | Port | URL | Command |
|--------|------|-----|---------|
| **Frontend 1** | 3000 | http://localhost:3000 | `flutter run -d chrome --web-port=3000` |
| **Frontend 2** | 3001 | http://localhost:3001 | `flutter run -d chrome --web-port=3001` |
| **Backend** | 5000 | http://localhost:5000 | `npm run dev` |

---

## 📁 Configuration Files

### Backend Port Configuration:
**File**: `backend/.env`
```env
PORT=5000
```

### Frontend API Configuration:
**File**: `frontend/lib/core/api/endpoints.dart`
```dart
static const String baseUrl = 'http://localhost:5000';
static const String wsUrl = 'ws://localhost:5000';
```

---

## 🚀 Quick Commands

### Start All Servers:
Say: **"run all"** or **"re run all"**

### Stop All Servers:
Say: **"close all run"** or **"stop all"**

### Check Status:
Say: **"check is any process running"**

---

## 🧪 Testing Setup

### Multi-User Real-Time Collaboration Testing:

1. **Browser Tab 1** (Port 3000):
   - Open: http://localhost:3000
   - Login: `admin@synceditor.com` / `Admin@123`

2. **Browser Tab 2** (Port 3001):
   - Open: http://localhost:3001
   - Login: `user@synceditor.com` / `User@123`

3. **Test Real-Time Sync**:
   - Create/open a page in Tab 1
   - Add a widget
   - Select widget and edit properties
   - Watch Tab 2 update in real-time! 🎉

---

## 🔧 Port Usage

| Port | Purpose | Status |
|------|---------|--------|
| 3000 | Frontend Instance 1 | ✅ Active |
| 3001 | Frontend Instance 2 | ✅ Active |
| 5000 | Backend API + WebSocket | ✅ Active |
| 5432 | PostgreSQL Database | External |
| 6379 | Redis Cache | External |

---

## 📝 Notes

- **Two Frontend Instances**: Allows testing real-time collaboration without opening multiple browser windows
- **Single Backend**: Handles both frontend instances with WebSocket connections
- **Shared Database**: Both frontends connect to the same PostgreSQL database via backend
- **Real-Time Sync**: Changes in one frontend instantly appear in the other

---

## ⚠️ Important

- Backend MUST be on port **5000** (configured in frontend API endpoints)
- Frontend instances can be on any port (we use 3000 and 3001)
- Make sure PostgreSQL and Redis are running before starting backend

---

## 🎉 Current Status

All three servers are configured and ready to run with the above setup!
