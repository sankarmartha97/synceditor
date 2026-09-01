# Canvas Editor - Setup Instructions

## Phase 2: Backend Integration Complete! 🎉

The frontend and backend are now fully integrated with:
- ✅ REST API with Dio HTTP client
- ✅ WebSocket real-time collaboration
- ✅ Authentication system (register/login)
- ✅ Canvas & Widget CRUD operations
- ✅ Optimistic UI updates with sync service

---

## Prerequisites

### Required Software

1. **Node.js** (v18 or higher)
   - Already installed: v24.19.0 ✅

2. **Flutter** (v3.0 or higher)
   - Already installed: v3.41.2 ✅

3. **PostgreSQL** (v14 or higher)
   - Download: https://www.postgresql.org/download/windows/
   - Or use installer: https://www.enterprisedb.com/downloads/postgres-postgresql-downloads

4. **Redis** (v6 or higher)
   - Windows: https://github.com/microsoftarchive/redis/releases
   - Or use WSL: `sudo apt-get install redis-server`

5. **Docker Desktop** (Optional - for easier setup)
   - Download: https://www.docker.com/products/docker-desktop/
   - **Note**: Docker is currently not installed

---

## Setup Options

### Option 1: Using Docker (Recommended - Requires Docker Installation)

1. **Install Docker Desktop**
   ```powershell
   # Download and install from: https://www.docker.com/products/docker-desktop/
   # After installation, restart your computer
   ```

2. **Start all services**
   ```powershell
   cd c:\Users\RedoQ\KuickStudio_Work_Space\SyncEditor
   docker-compose up -d
   ```

3. **Check services are running**
   ```powershell
   docker-compose ps
   ```

4. **View logs**
   ```powershell
   docker-compose logs -f backend
   ```

### Option 2: Manual Setup (Without Docker)

#### Step 1: Install PostgreSQL

1. Download PostgreSQL installer for Windows
2. Run installer and set password (e.g., `postgres`)
3. Create database and user:
   ```sql
   -- Open pgAdmin or psql
   CREATE DATABASE canvas_db;
   CREATE USER canvas_user WITH PASSWORD 'canvas_pass';
   GRANT ALL PRIVILEGES ON DATABASE canvas_db TO canvas_user;
   ```

4. Run database migrations:
   ```powershell
   cd c:\Users\RedoQ\KuickStudio_Work_Space\SyncEditor\database
   
   # Connect to PostgreSQL and run migrations
   psql -U canvas_user -d canvas_db -f schema.sql
   psql -U canvas_user -d canvas_db -f migrations/001_create_users_table.sql
   psql -U canvas_user -d canvas_db -f migrations/002_create_canvases_table.sql
   psql -U canvas_user -d canvas_db -f migrations/003_create_widgets_table.sql
   psql -U canvas_user -d canvas_db -f migrations/004_create_versions_and_collaborators.sql
   ```

#### Step 2: Install Redis

**Option A: Using Windows Installer**
1. Download Redis from: https://github.com/microsoftarchive/redis/releases
2. Install and run Redis server
3. Verify: `redis-cli ping` (should return PONG)

**Option B: Using WSL**
```bash
# In WSL terminal
sudo apt-get update
sudo apt-get install redis-server
sudo service redis-server start
redis-cli ping  # Should return PONG
```

#### Step 3: Setup Backend

1. **Install dependencies**
   ```powershell
   cd c:\Users\RedoQ\KuickStudio_Work_Space\SyncEditor\backend
   npm install
   ```

2. **Create .env file**
   ```powershell
   cp .env.example .env
   
   # Edit .env file with your database credentials
   # Make sure DATABASE_URL and REDIS_URL match your setup
   ```

3. **Start backend server**
   ```powershell
   npm run dev
   ```

4. **Verify backend is running**
   - Open browser: http://localhost:5000/health
   - Should see: `{"status":"ok"}`

#### Step 4: Run Frontend

1. **Frontend is already running**
   - The Flutter app should already be running in Chrome
   - If not, start it:
   ```powershell
   cd c:\Users\RedoQ\KuickStudio_Work_Space\SyncEditor\frontend
   flutter run -d chrome
   ```

---

## Testing the Integration

### 1. Test Authentication

1. Open the Flutter app in Chrome (should show login screen)
2. Click "Register" and create a new account:
   - Name: Test User
   - Email: test@example.com
   - Password: password123

3. You should be logged in and see the canvas editor

### 2. Test Canvas Creation

1. In the app, you should see an empty canvas
2. Try dragging widgets from the left panel onto the canvas
3. Check that widgets are saved (refresh the page - they should persist)

### 3. Test Real-time Collaboration

1. Open the app in **two browser tabs**
2. In Tab 1: Add a widget to the canvas
3. In Tab 2: You should see the widget appear in real-time!
4. Try moving widgets in one tab and watch them update in the other

### 4. Verify Backend Connection

Check the backend logs for successful WebSocket connections:
```
✅ WebSocket connected
🎨 User joined canvas: <canvas_id>
📦 Widget added: <widget_id>
```

---

## API Endpoints Reference

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login user
- `GET /api/v1/auth/me` - Get current user
- `POST /api/v1/auth/logout` - Logout user

### Canvas
- `GET /api/v1/canvases` - Get all canvases
- `POST /api/v1/canvases` - Create canvas
- `GET /api/v1/canvases/:id` - Get canvas by ID
- `PUT /api/v1/canvases/:id` - Update canvas
- `DELETE /api/v1/canvases/:id` - Delete canvas

### Widgets
- `GET /api/v1/canvases/:id/widgets` - Get canvas widgets
- `POST /api/v1/canvases/:id/widgets` - Create widget
- `PUT /api/v1/canvases/:id/widgets/:widgetId` - Update widget
- `DELETE /api/v1/canvases/:id/widgets/:widgetId` - Delete widget

### WebSocket Events
- `canvas:join` - Join canvas room
- `canvas:leave` - Leave canvas room
- `widget:add` - Add widget (broadcast)
- `widget:update` - Update widget (broadcast)
- `widget:delete` - Delete widget (broadcast)
- `cursor:move` - Move cursor (broadcast)

---

## Troubleshooting

### Backend won't start

**Error: Cannot connect to PostgreSQL**
- Check PostgreSQL is running: `pg_isready`
- Verify credentials in `.env` file
- Try connecting manually: `psql -U canvas_user -d canvas_db`

**Error: Cannot connect to Redis**
- Check Redis is running: `redis-cli ping`
- On Windows: Check Windows Services for Redis
- On WSL: `sudo service redis-server status`

**Error: Port 5000 already in use**
- Change PORT in `.env` file
- Update `ApiEndpoints.baseUrl` in Flutter frontend

### Frontend won't connect to backend

**Error: Connection timeout**
- Verify backend is running: http://localhost:5000/health
- Check CORS settings in backend
- Verify `ApiEndpoints.baseUrl` in Flutter matches backend URL

**Error: 401 Unauthorized**
- Clear app storage and login again
- Check JWT_SECRET is set in backend `.env`

### WebSocket not connecting

**Check WebSocket URL**
- Verify `ApiEndpoints.wsUrl` points to correct backend
- Default: `ws://localhost:5000`

**Check authentication**
- WebSocket requires valid JWT token
- Login first, then WebSocket will auto-connect

---

## Development Commands

### Backend
```powershell
cd backend

# Development (with hot reload)
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Run tests
npm test

# Lint code
npm run lint
```

### Frontend
```powershell
cd frontend

# Run on Chrome
flutter run -d chrome

# Run on Windows desktop
flutter run -d windows

# Build for web
flutter build web

# Run tests
flutter test

# Analyze code
flutter analyze
```

### Docker
```powershell
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f

# Restart a service
docker-compose restart backend

# Rebuild containers
docker-compose up --build
```

---

## Project Structure

```
SyncEditor/
├── frontend/                    # Flutter Web App
│   ├── lib/
│   │   ├── core/
│   │   │   ├── api/            # API client, WebSocket, endpoints
│   │   │   ├── models/         # Data models
│   │   │   └── services/       # Auth, Canvas, Sync services
│   │   ├── features/
│   │   │   ├── auth/           # Login, Register screens
│   │   │   ├── canvas/         # Canvas editor
│   │   │   ├── widget_library/ # Widget library panel
│   │   │   └── properties/     # Properties panel
│   │   └── editor/             # Main editor screen
│   └── pubspec.yaml
│
├── backend/                     # Node.js + Express API
│   ├── src/
│   │   ├── controllers/        # API controllers
│   │   ├── routes/             # API routes
│   │   ├── middleware/         # Auth, validation, error handling
│   │   ├── websocket/          # Socket.io handlers
│   │   ├── config/             # Database, Redis, env config
│   │   └── utils/              # JWT, response helpers
│   ├── package.json
│   └── .env
│
├── database/                    # PostgreSQL schemas & migrations
│   ├── schema.sql
│   ├── migrations/
│   └── seeds/
│
└── docker-compose.yml          # Docker services configuration
```

---

## Next Steps

1. **Install PostgreSQL and Redis** (if not using Docker)
2. **Run database migrations**
3. **Start backend server**
4. **Test authentication** by registering a new user
5. **Test canvas operations** by adding/editing widgets
6. **Test real-time sync** by opening multiple browser tabs

---

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review backend logs: `npm run dev` output
3. Check browser console for frontend errors
4. Verify all services are running

---

**Phase 2 Backend Integration Status**: ✅ **COMPLETE**

All features implemented:
- ✅ REST API client with Dio
- ✅ WebSocket client with Socket.io
- ✅ Authentication (register/login/logout)
- ✅ Canvas CRUD operations
- ✅ Widget CRUD operations
- ✅ Real-time collaboration
- ✅ Optimistic UI updates
- ✅ Sync service with retry logic

**Ready for testing!** 🚀
