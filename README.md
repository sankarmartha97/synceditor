# 🎨 Canvas Editor - Full-Stack Collaborative Editor

A real-time collaborative canvas editor built with **Flutter** (frontend) and **Node.js + TypeScript** (backend). Features drag-and-drop widgets, properties panel, and WebSocket-based real-time synchronization.

## 🚀 Features

- ✅ **Split-panel interface** - Widget Library | Canvas | Properties Panel
- ✅ **Drag & Drop** - Intuitive widget placement on canvas
- ✅ **Real-time Collaboration** - Multiple users editing simultaneously
- ✅ **Properties Panel** - Edit width, height, background color, position
- ✅ **WebSocket Sync** - Instant updates across all clients
- ✅ **JWT Authentication** - Secure user management
- ✅ **PostgreSQL Database** - Persistent storage with version history
- ✅ **Redis Caching** - Fast session and presence management
- ✅ **Docker Support** - Easy local development setup

---

## 📁 Project Structure

```
SyncEditor/
├── backend/                 # Node.js + TypeScript API
│   ├── src/
│   │   ├── config/         # Database, Redis, environment config
│   │   ├── controllers/    # Request handlers
│   │   ├── middleware/     # Auth, validation, error handling
│   │   ├── routes/         # API route definitions
│   │   ├── websocket/      # Socket.io handlers
│   │   ├── utils/          # Helper functions
│   │   ├── app.ts          # Express app setup
│   │   └── server.ts       # Server entry point
│   ├── package.json
│   └── tsconfig.json
│
├── frontend/               # Flutter application
│   ├── lib/
│   │   ├── core/           # API clients, models, services
│   │   ├── features/       # Feature modules (canvas, auth, etc.)
│   │   └── editor/         # Main editor screen
│   └── pubspec.yaml
│
├── database/               # Database schemas and migrations
│   ├── migrations/         # SQL migration files
│   ├── seeds/              # Sample data
│   └── schema.sql          # Complete database schema
│
├── deployment/             # Docker and deployment configs
│   ├── docker/             # Dockerfiles
│   └── scripts/            # Deployment scripts
│
└── docker-compose.yml      # Local development setup
```

---

## 🛠️ Tech Stack

### Backend
- **Runtime**: Node.js 18+
- **Language**: TypeScript
- **Framework**: Express.js 4.x
- **Real-time**: Socket.io 4.x
- **Database**: PostgreSQL 15+
- **Cache**: Redis 7+
- **Authentication**: JWT + bcrypt
- **Validation**: Zod

### Frontend
- **Framework**: Flutter 3.x
- **State Management**: flutter_bloc
- **HTTP Client**: dio
- **WebSocket**: socket_io_client
- **Local Storage**: hive

---

## 🚦 Getting Started

### Prerequisites

- Node.js 18+ and npm
- PostgreSQL 15+
- Redis 7+
- Docker & Docker Compose (optional, for easy setup)
- Flutter 3.x (for frontend development)

### Option 1: Docker Setup (Recommended)

1. **Clone the repository**
   ```bash
   cd c:\Users\RedoQ\KuickStudio_Work_Space\SyncEditor
   ```

2. **Start all services with Docker Compose**
   ```bash
   docker-compose up
   ```

   This will start:
   - PostgreSQL database (port 5432)
   - Redis cache (port 6379)
   - Backend API (port 5000)

3. **Verify services are running**
   ```bash
   # Check backend health
   curl http://localhost:5000/health
   
   # Check API info
   curl http://localhost:5000/api
   ```

### Option 2: Manual Setup

#### Backend Setup

1. **Navigate to backend directory**
   ```bash
   cd backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Create .env file**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` with your database credentials.

4. **Start PostgreSQL and Redis**
   Ensure PostgreSQL and Redis are running locally.

5. **Initialize database**
   ```bash
   # Connect to PostgreSQL
   psql -U postgres
   
   # Create database
   CREATE DATABASE canvas_db;
   
   # Run schema
   psql -U postgres -d canvas_db -f ../database/schema.sql
   
   # (Optional) Load sample data
   psql -U postgres -d canvas_db -f ../database/seeds/sample_data.sql
   ```

6. **Start backend server**
   ```bash
   npm run dev
   ```

   Backend will start on http://localhost:5000

#### Frontend Setup

1. **Navigate to frontend directory**
   ```bash
   cd frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # For web (single instance)
   flutter run -d chrome
   
   # For desktop
   flutter run -d windows  # or macos, linux
   ```

#### Testing Real-Time Collaboration (2 Instances)

To test collaboration features, you need to run 2 frontend instances simultaneously:

1. **Start Backend** (if not already running)
   ```bash
   cd backend
   npm run dev
   ```

2. **Start First Instance** (Alice - Port 3000)
   ```bash
   cd frontend
   flutter run -d chrome --web-hostname=localhost --web-port=3000
   ```

3. **Start Second Instance** (Bob - Port 3001) - Open a new terminal
   ```bash
   cd frontend
   flutter run -d chrome --web-hostname=localhost --web-port=3001
   ```

4. **Test Accounts**
   - **Alice**: 
     - URL: http://localhost:3000
     - Email: `alice@test.com`
     - Password: `test123456`
   
   - **Bob**: 
     - URL: http://localhost:3001
     - Email: `bob@test.com`
     - Password: `test123456`

5. **Testing Collaboration**
   - Login to both instances with different accounts
   - Open the same page in both browsers
   - Drop a widget in Alice's browser → should appear in Bob's browser instantly
   - Edit widget properties in Alice → Bob sees changes in real-time
   - See each other's cursors and selections
   - Test undo/redo (Ctrl+Z / Ctrl+Y) - changes sync across instances

---

## 📡 API Documentation

### Authentication Endpoints

#### Register User
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

Response:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "name": "John Doe"
    },
    "token": "jwt_token_here"
  }
}
```

#### Get Current User
```http
GET /api/auth/me
Authorization: Bearer {token}
```

### Canvas Endpoints

#### Get All Canvases
```http
GET /api/canvases?page=1&limit=20
Authorization: Bearer {token}
```

#### Create Canvas
```http
POST /api/canvases
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "My Canvas",
  "description": "A new canvas",
  "settings": {
    "backgroundColor": "#ffffff",
    "gridSize": 20,
    "showGrid": true
  }
}
```

#### Get Canvas with Widgets
```http
GET /api/canvases/{canvasId}
Authorization: Bearer {token}
```

#### Update Canvas
```http
PUT /api/canvases/{canvasId}
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Updated Name",
  "settings": { ... }
}
```

### Widget Endpoints

#### Create Widget
```http
POST /api/canvases/{canvasId}/widgets
Authorization: Bearer {token}
Content-Type: application/json

{
  "type": "Container",
  "position": {
    "x": 100,
    "y": 100,
    "z_index": 1
  },
  "size": {
    "width": 200,
    "height": 150,
    "width_unit": "px",
    "height_unit": "px"
  },
  "properties": {
    "backgroundColor": "#3498db",
    "opacity": 1.0
  }
}
```

#### Update Widget
```http
PUT /api/canvases/{canvasId}/widgets/{widgetId}
Authorization: Bearer {token}
Content-Type: application/json

{
  "position": { "x": 150, "y": 150 },
  "properties": { "backgroundColor": "#e74c3c" }
}
```

#### Delete Widget
```http
DELETE /api/canvases/{canvasId}/widgets/{widgetId}
Authorization: Bearer {token}
```

---

## 🔌 WebSocket Events

### Client → Server

```javascript
// Connect with authentication
const socket = io('http://localhost:5000', {
  auth: { token: 'jwt_token' }
});

// Join canvas
socket.emit('canvas:join', { canvasId: 'uuid' });

// Add widget
socket.emit('widget:add', {
  canvasId: 'uuid',
  widget: { type: 'Container', position: {...}, size: {...} }
});

// Update widget
socket.emit('widget:update', {
  canvasId: 'uuid',
  widgetId: 'uuid',
  updates: { position: { x: 200, y: 200 } }
});

// Delete widget
socket.emit('widget:delete', {
  canvasId: 'uuid',
  widgetId: 'uuid'
});

// Move cursor (for collaboration)
socket.emit('cursor:move', {
  canvasId: 'uuid',
  position: { x: 300, y: 400 }
});
```

### Server → Client

```javascript
// Canvas joined successfully
socket.on('canvas:joined', (data) => {
  console.log('Joined canvas:', data.canvasId);
  console.log('Active users:', data.activeUsers);
});

// Widget added by another user
socket.on('widget:added', (data) => {
  console.log('New widget:', data.widget);
  console.log('Added by:', data.userId);
});

// Widget updated by another user
socket.on('widget:updated', (data) => {
  console.log('Updated widget:', data.widget);
});

// Widget deleted by another user
socket.on('widget:deleted', (data) => {
  console.log('Deleted widget:', data.widgetId);
});

// User joined canvas
socket.on('user:joined', (data) => {
  console.log('User joined:', data.user);
});

// User left canvas
socket.on('user:left', (data) => {
  console.log('User left:', data.userId);
});

// Cursor updated
socket.on('cursor:updated', (data) => {
  console.log('Cursor moved:', data.userId, data.position);
});

// Sync error
socket.on('sync:error', (data) => {
  console.error('Sync error:', data.message);
});
```

---

## 🗄️ Database Schema

### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Canvases Table
```sql
CREATE TABLE canvases (
    id UUID PRIMARY KEY,
    owner_id UUID REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    settings JSONB DEFAULT '{}',
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Widgets Table
```sql
CREATE TABLE widgets (
    id UUID PRIMARY KEY,
    canvas_id UUID REFERENCES canvases(id),
    type VARCHAR(50) NOT NULL,
    position JSONB NOT NULL,
    size JSONB NOT NULL,
    properties JSONB NOT NULL,
    parent_id UUID REFERENCES widgets(id),
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🧪 Testing

### Backend Tests
```bash
cd backend
npm test
```

### Frontend Tests
```bash
cd frontend
flutter test
```

---

## 🔒 Environment Variables

### Backend (.env)

```env
# Server
NODE_ENV=development
PORT=5000

# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/canvas_db
DB_HOST=localhost
DB_PORT=5432
DB_NAME=canvas_db
DB_USER=canvas_user
DB_PASSWORD=canvas_pass

# Redis
REDIS_URL=redis://localhost:6379
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your_secret_key_here
JWT_EXPIRES_IN=7d

# CORS
FRONTEND_URL=http://localhost:3000
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

---

## 📦 Deployment

### Backend Deployment

1. **Build TypeScript**
   ```bash
   cd backend
   npm run build
   ```

2. **Start production server**
   ```bash
   npm start
   ```

### Docker Deployment

```bash
# Build images
docker-compose build

# Start production
docker-compose -f docker-compose.prod.yml up -d
```

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License.

---

## 🐛 Troubleshooting

### Database Connection Error
```bash
# Check if PostgreSQL is running
docker-compose ps

# Restart PostgreSQL
docker-compose restart postgres
```

### Redis Connection Error
```bash
# Check if Redis is running
docker-compose ps

# Restart Redis
docker-compose restart redis
```

### Port Already in Use
```bash
# Find process using port 5000
netstat -ano | findstr :5000

# Kill process (Windows)
taskkill /PID <PID> /F
```

---

## 📞 Support

For issues and questions:
- Create an issue on GitHub
- Email: support@canvaseditor.com

---

## 🎯 Roadmap

### Phase 2 (Upcoming)
- [ ] Flutter frontend implementation
- [ ] Advanced widget library (20+ widgets)
- [ ] Undo/redo functionality
- [ ] Export canvas to image/PDF
- [ ] Template system

### Phase 3 (Future)
- [ ] Plugin system
- [ ] AI-powered design suggestions
- [ ] Mobile app (iOS/Android)
- [ ] Desktop app (Windows/Mac/Linux)

---

**Built with ❤️ using Flutter and Node.js**
