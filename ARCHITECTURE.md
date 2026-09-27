# SyncEditor Backend Architecture Documentation

## Table of Contents
- [Overview](#overview)
- [Technology Stack](#technology-stack)
- [Architecture Overview](#architecture-overview)
- [Complete Data Flow](#complete-data-flow)
- [Authentication System](#authentication-system)
- [Database Design](#database-design)
- [WebSocket Implementation](#websocket-implementation)
- [REST API Endpoints](#rest-api-endpoints)
- [Permission System](#permission-system)
- [Error Handling](#error-handling)
- [Performance Optimizations](#performance-optimizations)
- [Architectural Patterns](#architectural-patterns)
- [Configuration](#configuration)
- [Future Improvements](#future-improvements)

---

## Overview

SyncEditor is a **real-time collaborative canvas editor** that allows multiple users to work together on visual content simultaneously. The backend is built with **Node.js (JavaScript ES6)** and provides a robust foundation for real-time synchronization, permission management, and persistent storage of collaborative workspaces.

### Key Features
- Real-time collaborative editing
- WebSocket-based synchronization
- Role-based access control (Owner, Editor, Commenter, Viewer)
- Comments and annotations system
- User mentions and notifications
- Undo/Redo with operational history
- Version history and audit trails
- Cursor tracking and user presence
- JWT-based authentication
- Optimistic updates with eventual consistency

---

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Runtime** | Node.js (JavaScript ES6) | Server-side JavaScript runtime |
| **Framework** | Express.js | HTTP REST API framework |
| **Database** | PostgreSQL | Persistent data storage |
| **Cache** | Redis | Session management, active user tracking |
| **Real-time** | Socket.IO | WebSocket implementation |
| **Authentication** | JWT (jsonwebtoken) | Stateless authentication |
| **Security** | Helmet, CORS | Security headers, cross-origin protection |
| **Validation** | Zod | Schema validation |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Client Layer                          │
│              (Web/Mobile with Socket.IO Client)              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ HTTP/WebSocket
                     │
┌────────────────────▼────────────────────────────────────────┐
│                     Express + Socket.IO                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Middleware │  │  Controllers │  │   WebSocket  │      │
│  │   (Auth,     │  │  (REST API)  │  │   Handlers   │      │
│  │   CORS,      │  │              │  │              │      │
│  │   Helmet)    │  │              │  │              │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                  │              │
│         └─────────────────┼──────────────────┘              │
│                           │                                 │
│                  ┌────────▼────────┐                        │
│                  │  Service Layer  │                        │
│                  │  (Business      │                        │
│                  │   Logic)        │                        │
│                  └────────┬────────┘                        │
└───────────────────────────┼─────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
      ┌─────────▼─────────┐   ┌─────────▼──────────┐
      │   PostgreSQL      │   │      Redis         │
      │   (Persistent)    │   │   (Ephemeral)      │
      │                   │   │                    │
      │  • Pages          │   │  • Active users    │
      │  • Permissions    │   │  • Presence data   │
      │  • Versions       │   │  • Sessions        │
      │  • Users          │   │                    │
      └───────────────────┘   └────────────────────┘
```

---

## Complete Data Flow

### 1. Application Bootstrap Flow

```
server.ts
├─ Validate environment variables (throws if invalid)
├─ Create HTTP server (Express app)
├─ Initialize Socket.IO server with CORS config
├─ Test PostgreSQL connection
│  └─ EXIT if database unavailable
├─ Test Redis connection
│  └─ WARN if Redis unavailable (continues)
├─ Register WebSocket event handlers
├─ Start HTTP server on configured port
└─ Register graceful shutdown handlers
   ├─ SIGTERM
   ├─ SIGINT
   ├─ uncaughtException
   └─ unhandledRejection
```

**Graceful Shutdown Process:**
```javascript
1. Receive shutdown signal
2. Stop accepting new connections
3. Close Socket.IO server
4. Close PostgreSQL connection pool
5. Close Redis connection
6. Exit process (timeout after 10s)
```

### 2. REST API Request Flow

```
Incoming HTTP Request
    ↓
┌───────────────────────────────────────┐
│   Express Middleware Chain            │
├───────────────────────────────────────┤
│ 1. helmet() - Security headers        │
│ 2. cors() - Cross-origin validation   │
│ 3. express.json() - Body parsing      │
│ 4. morgan() - Request logging         │
└───────────────┬───────────────────────┘
                ↓
┌───────────────────────────────────────┐
│   Route Matching                      │
├───────────────────────────────────────┤
│ • /api/auth/*                         │
│ • /api/pages/*                        │
│ • /api/canvases/* (legacy)            │
└───────────────┬───────────────────────┘
                ↓
┌───────────────────────────────────────┐
│   Authentication Middleware           │
├───────────────────────────────────────┤
│ 1. Extract JWT from Authorization     │
│ 2. Verify token signature             │
│ 3. Attach user to req.user            │
│    - userId                           │
│    - email                            │
└───────────────┬───────────────────────┘
                ↓
┌───────────────────────────────────────┐
│   Controller Layer                    │
├───────────────────────────────────────┤
│ • Validate request data               │
│ • Call service methods                │
│ • Format response                     │
└───────────────┬───────────────────────┘
                ↓
┌───────────────────────────────────────┐
│   Service Layer                       │
├───────────────────────────────────────┤
│ • Business logic                      │
│ • Permission checks                   │
│ • Database transactions               │
│ • Data transformation                 │
└───────────────┬───────────────────────┘
                ↓
┌───────────────────────────────────────┐
│   Database Layer (PostgreSQL)         │
├───────────────────────────────────────┤
│ • Connection pooling                  │
│ • SQL queries                         │
│ • Transaction management              │
└───────────────┬───────────────────────┘
                ↓
┌───────────────────────────────────────┐
│   Response Formatting                 │
├───────────────────────────────────────┤
│ Success: { success, data, message }   │
│ Error: { success, error, message }    │
└───────────────────────────────────────┘
```

### 3. WebSocket Connection Flow

```
Client Connection Request
    ↓
┌─────────────────────────────────────────┐
│   Socket.IO Handshake                   │
└─────────────────┬───────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│   Authentication Middleware (io.use)    │
├─────────────────────────────────────────┤
│ 1. Extract token from handshake.auth    │
│ 2. Verify JWT token                     │
│ 3. Attach userId & email to socket      │
│ 4. REJECT if authentication fails       │
└─────────────────┬───────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│   Connection Established                │
│   Socket authenticated & ready          │
└─────────────────────────────────────────┘
```

---

## Authentication System

### JWT Token Structure

```javascript
// JWT Payload
{
  userId: string,      // Unique user identifier
  email: string,       // User email address
  iat: number,         // Issued at timestamp
  exp: number          // Expiration timestamp
}
```

### Dual Authentication Points

#### 1. HTTP REST Authentication

```javascript
// Header format
Authorization: Bearer <jwt_token>

// Middleware processing
const authMiddleware = async (req, res, next) => {
  // 1. Extract token from header
  // 2. Verify signature with JWT_SECRET
  // 3. Attach decoded payload to req.user
  // 4. Continue to route handler OR return 401
}
```

#### 2. WebSocket Authentication

```javascript
// Connection format (client-side)
io.connect(url, {
  auth: { token: jwt_token }
});

// Server-side processing
io.use(async (socket, next) => {
  // 1. Extract token from socket.handshake.auth.token
  // 2. Verify token
  // 3. Attach userId & email to socket object
  // 4. Accept connection OR reject with error
});
```

### Token Flow Diagram

```
┌──────────┐         ┌──────────┐
│  Client  │         │  Server  │
└────┬─────┘         └────┬─────┘
     │                    │
     │  POST /api/auth/login
     │  { email, password }
     ├───────────────────>│
     │                    │ Verify credentials
     │                    │ Generate JWT
     │    200 OK          │
     │    { token }       │
     │<───────────────────┤
     │                    │
     │  Store token       │
     │                    │
     │  GET /api/pages    │
     │  Authorization: Bearer <token>
     ├───────────────────>│
     │                    │ Verify token
     │                    │ Process request
     │    200 OK          │
     │    { data }        │
     │<───────────────────┤
```

---

## Database Design

### PostgreSQL Schema

#### Pages Table (New Architecture)
```sql
CREATE TABLE pages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  owner_id UUID NOT NULL REFERENCES users(id),
  page_data JSONB NOT NULL,  -- Full page document
  version INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP NULL  -- Soft delete
);

-- Indexes
CREATE INDEX idx_pages_owner ON pages(owner_id);
CREATE INDEX idx_pages_deleted ON pages(deleted_at);
CREATE INDEX idx_pages_page_data ON pages USING gin(page_data);
```

**page_data JSONB Structure:**
```json
{
  "pageId": "uuid",
  "name": "Page Name",
  "version": 1,
  "metadata": {
    "width": 1920,
    "height": 1080,
    "backgroundColor": "#FFFFFF",
    "gridSize": 10,
    "showGrid": true,
    "snapToGrid": false,
    "zoom": 1.0
  },
  "widgets": [
    {
      "id": "uuid",
      "type": "rectangle",
      "position": { "x": 100, "y": 200 },
      "size": { "width": 150, "height": 100 },
      "properties": {
        "backgroundColor": "#FF0000",
        "borderRadius": 8,
        "opacity": 1.0,
        "rotation": 0,
        "zIndex": 1
      },
      "createdAt": "ISO-8601",
      "createdBy": "userId",
      "updatedAt": "ISO-8601",
      "updatedBy": "userId"
    }
  ]
}
```

#### Page Permissions Table
```sql
CREATE TABLE page_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id UUID NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  permission_type VARCHAR(20) NOT NULL,  -- owner, edit, comment, view
  granted_by UUID NOT NULL REFERENCES users(id),
  granted_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(page_id, user_id)
);

-- Indexes
CREATE INDEX idx_page_permissions_page ON page_permissions(page_id);
CREATE INDEX idx_page_permissions_user ON page_permissions(user_id);
```

#### Page Versions Table (Audit Trail)
```sql
CREATE TABLE page_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id UUID NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
  version INTEGER NOT NULL,
  page_data JSONB NOT NULL,
  operations JSONB,  -- JSON Patch operations
  description TEXT,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_page_versions_page ON page_versions(page_id, version);
```

#### Canvases Table (Legacy)
```sql
CREATE TABLE canvases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES users(id),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  settings JSONB DEFAULT '{}',
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

#### Widgets Table (Legacy)
```sql
CREATE TABLE widgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  canvas_id UUID NOT NULL REFERENCES canvases(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  position JSONB NOT NULL,  -- {x, y}
  size JSONB NOT NULL,      -- {width, height}
  properties JSONB DEFAULT '{}',
  parent_id UUID REFERENCES widgets(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_widgets_canvas ON widgets(canvas_id);
CREATE INDEX idx_widgets_parent ON widgets(parent_id);
```

#### Widget Versions Table (Legacy Audit)
```sql
CREATE TABLE widget_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  widget_id UUID NOT NULL,
  canvas_id UUID NOT NULL REFERENCES canvases(id) ON DELETE CASCADE,
  operation VARCHAR(20) NOT NULL,  -- create, update, delete
  data JSONB NOT NULL,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_widget_versions_widget ON widget_versions(widget_id);
CREATE INDEX idx_widget_versions_canvas ON widget_versions(canvas_id);
```

### Redis Data Structures

#### Active Users (per canvas)
```redis
Key: canvas:{canvasId}:users
Type: Hash
TTL: None (manually managed)

Fields:
  {userId1}: '{"userId":"uuid","name":"John","email":"john@example.com","avatarUrl":"url"}'
  {userId2}: '{"userId":"uuid","name":"Jane","email":"jane@example.com","avatarUrl":"url"}'
```

**Operations:**
- `HSET canvas:123:users user456 {...}` - Add user
- `HDEL canvas:123:users user456` - Remove user
- `HGETALL canvas:123:users` - Get all active users
- `HLEN canvas:123:users` - Count active users

---

## WebSocket Implementation

### Socket.IO Configuration

```javascript
const { Server } = require('socket.io');

const io = new Server(httpServer, {
  cors: {
    origin: config.cors.allowedOrigins,
    credentials: true,
    methods: ['GET', 'POST'],
  },
  pingTimeout: 60000,      // Client ping timeout
  pingInterval: 25000,     // Server ping interval
});
```

### Event System

#### Client → Server Events

| Event | Payload | Description |
|-------|---------|-------------|
| `canvas:join` | `{ canvasId }` | Join a canvas room |
| `canvas:leave` | `{ canvasId }` | Leave a canvas room |
| `widget:add` | `{ canvasId, widget: {...} }` | Create new widget |
| `widget:update` | `{ canvasId, widgetId, updates: {...} }` | Update widget |
| `widget:delete` | `{ canvasId, widgetId }` | Delete widget |
| `cursor:move` | `{ canvasId, position: {x, y} }` | Update cursor position |
| `cursor:hide` | `{ canvasId }` | Hide cursor |

#### Server → Client Events

| Event | Payload | Description |
|-------|---------|-------------|
| `canvas:joined` | `{ canvasId, canvasName, activeUsers: [...] }` | Join confirmation |
| `canvas:left` | `{ canvasId }` | Leave confirmation |
| `user:joined` | `{ user: {...}, timestamp }` | User joined notification |
| `user:left` | `{ userId, timestamp }` | User left notification |
| `widget:added` | `{ widget: {...}, userId, timestamp }` | Widget created |
| `widget:updated` | `{ widget: {...}, userId, timestamp }` | Widget modified |
| `widget:deleted` | `{ widgetId, userId, timestamp }` | Widget removed |
| `cursor:updated` | `{ userId, position: {x, y}, timestamp }` | Cursor moved |
| `cursor:hidden` | `{ userId }` | Cursor hidden |
| `sync:error` | `{ operation, message }` | Sync operation failed |
| `connection:error` | `{ message }` | Connection issue |

### Canvas Join Flow (Detailed)

```javascript
// Client emits
socket.emit('canvas:join', { canvasId: '123-456-789' });

// Server processes
async function handleCanvasJoin(socket, data) {
  const { canvasId } = data;
  
  // Step 1: Verify access permission
  const access = await db.query(`
    SELECT c.id, c.name, u.name as user_name, u.avatar_url 
    FROM canvases c
    LEFT JOIN canvas_collaborators cc ON c.id = cc.canvas_id
    LEFT JOIN users u ON u.id = $1
    WHERE c.id = $2 
    AND (c.owner_id = $1 OR cc.user_id = $1 OR c.is_public = true)
  `, [socket.userId, canvasId]);
  
  if (!access.rows.length) {
    return socket.emit('connection:error', { 
      message: 'Access denied' 
    });
  }
  
  // Step 2: Join Socket.IO room
  socket.join(`canvas:${canvasId}`);
  socket.currentCanvasId = canvasId;
  
  // Step 3: Store user in Redis
  const userInfo = {
    userId: socket.userId,
    name: access.rows[0].user_name,
    email: socket.email,
    avatarUrl: access.rows[0].avatar_url
  };
  await redis.hset(
    `canvas:${canvasId}:users`,
    socket.userId,
    JSON.stringify(userInfo)
  );
  
  // Step 4: Get all active users
  const activeUsersHash = await redis.hgetall(`canvas:${canvasId}:users`);
  const activeUsers = Object.values(activeUsersHash).map(JSON.parse);
  
  // Step 5: Confirm to joining user
  socket.emit('canvas:joined', {
    canvasId,
    canvasName: access.rows[0].name,
    activeUsers
  });
  
  // Step 6: Notify other users
  socket.to(`canvas:${canvasId}`).emit('user:joined', {
    user: userInfo,
    timestamp: new Date().toISOString()
  });
}
```

### Widget Operations Flow

#### Add Widget

```javascript
socket.on('widget:add', async (data) => {
  const { canvasId, widget } = data;
  
  // 1. Permission check
  const hasPermission = await checkEditorAccess(canvasId, socket.userId);
  if (!hasPermission) {
    return socket.emit('sync:error', { 
      operation: 'widget:add',
      message: 'Insufficient permissions' 
    });
  }
  
  // 2. Create widget in database
  const widgetId = uuidv4();
  const result = await db.query(`
    INSERT INTO widgets (id, canvas_id, type, position, size, properties)
    VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING *
  `, [widgetId, canvasId, widget.type, widget.position, 
      widget.size, widget.properties]);
  
  const createdWidget = result.rows[0];
  
  // 3. Create audit entry
  await db.query(`
    INSERT INTO widget_versions (id, widget_id, canvas_id, operation, data, created_by)
    VALUES ($1, $2, $3, 'create', $4, $5)
  `, [uuidv4(), widgetId, canvasId, createdWidget, socket.userId]);
  
  // 4. Broadcast to others
  socket.to(`canvas:${canvasId}`).emit('widget:added', {
    widget: createdWidget,
    userId: socket.userId,
    timestamp: new Date().toISOString()
  });
  
  // 5. Acknowledge to sender
  socket.emit('widget:add:success', { widget: createdWidget });
});
```

#### Update Widget

```javascript
socket.on('widget:update', async (data) => {
  const { canvasId, widgetId, updates } = data;
  
  // 1. Permission check
  const hasPermission = await checkEditorAccess(canvasId, socket.userId);
  if (!hasPermission) {
    return socket.emit('sync:error', { 
      operation: 'widget:update',
      message: 'Insufficient permissions' 
    });
  }
  
  // 2. Build dynamic UPDATE query
  const updateFields = [];
  const values = [];
  let paramCount = 1;
  
  if (updates.position !== undefined) {
    updateFields.push(`position = $${paramCount++}`);
    values.push(updates.position);
  }
  if (updates.size !== undefined) {
    updateFields.push(`size = $${paramCount++}`);
    values.push(updates.size);
  }
  if (updates.properties !== undefined) {
    updateFields.push(`properties = $${paramCount++}`);
    values.push(updates.properties);
  }
  
  values.push(widgetId, canvasId);
  
  // 3. Execute update
  const result = await db.query(`
    UPDATE widgets 
    SET ${updateFields.join(', ')}, updated_at = NOW()
    WHERE id = $${paramCount} AND canvas_id = $${paramCount + 1}
    RETURNING *
  `, values);
  
  const updatedWidget = result.rows[0];
  
  // 4. Create version entry
  await db.query(`
    INSERT INTO widget_versions (id, widget_id, canvas_id, operation, data, created_by)
    VALUES ($1, $2, $3, 'update', $4, $5)
  `, [uuidv4(), widgetId, canvasId, updatedWidget, socket.userId]);
  
  // 5. Broadcast
  socket.to(`canvas:${canvasId}`).emit('widget:updated', {
    widget: updatedWidget,
    userId: socket.userId,
    timestamp: new Date().toISOString()
  });
  
  socket.emit('widget:update:success', { widget: updatedWidget });
});
```

#### Delete Widget

```javascript
socket.on('widget:delete', async (data) => {
  const { canvasId, widgetId } = data;
  
  // 1. Permission check
  const hasPermission = await checkEditorAccess(canvasId, socket.userId);
  if (!hasPermission) {
    return socket.emit('sync:error', { 
      operation: 'widget:delete',
      message: 'Insufficient permissions' 
    });
  }
  
  // 2. Get widget (for audit trail)
  const widgetResult = await db.query(
    'SELECT * FROM widgets WHERE id = $1 AND canvas_id = $2',
    [widgetId, canvasId]
  );
  
  if (!widgetResult.rows.length) {
    return socket.emit('sync:error', { 
      operation: 'widget:delete',
      message: 'Widget not found' 
    });
  }
  
  // 3. Create version entry BEFORE deletion
  await db.query(`
    INSERT INTO widget_versions (id, widget_id, canvas_id, operation, data, created_by)
    VALUES ($1, $2, $3, 'delete', $4, $5)
  `, [uuidv4(), widgetId, canvasId, widgetResult.rows[0], socket.userId]);
  
  // 4. Delete widget
  await db.query(
    'DELETE FROM widgets WHERE id = $1 AND canvas_id = $2',
    [widgetId, canvasId]
  );
  
  // 5. Broadcast
  socket.to(`canvas:${canvasId}`).emit('widget:deleted', {
    widgetId,
    userId: socket.userId,
    timestamp: new Date().toISOString()
  });
  
  socket.emit('widget:delete:success', { widgetId });
});
```

### Cursor Tracking (Lightweight)

```javascript
socket.on('cursor:move', (data) => {
  const { canvasId, position } = data;
  
  // Verify user is in canvas
  if (socket.currentCanvasId !== canvasId) {
    return;
  }
  
  // Broadcast immediately (no DB write)
  socket.to(`canvas:${canvasId}`).emit('cursor:updated', {
    userId: socket.userId,
    position,
    timestamp: new Date().toISOString()
  });
});

socket.on('cursor:hide', (data) => {
  const { canvasId } = data;
  
  socket.to(`canvas:${canvasId}`).emit('cursor:hidden', {
    userId: socket.userId
  });
});
```

### Disconnect Handling

```javascript
socket.on('disconnect', async () => {
  console.log(`User disconnected: ${socket.userId}`);
  
  if (socket.currentCanvasId) {
    await handleCanvasLeave(socket, socket.currentCanvasId);
  }
});

async function handleCanvasLeave(socket, canvasId) {
  // 1. Leave Socket.IO room
  socket.leave(`canvas:${canvasId}`);
  
  // 2. Remove from Redis
  await redis.hdel(`canvas:${canvasId}:users`, socket.userId);
  
  // 3. Notify others
  socket.to(`canvas:${canvasId}`).emit('user:left', {
    userId: socket.userId,
    timestamp: new Date().toISOString()
  });
  
  // 4. Confirm to user (if still connected)
  socket.emit('canvas:left', { canvasId });
  
  // 5. Clear current canvas
  socket.currentCanvasId = undefined;
}
```

---

## REST API Endpoints

### Authentication Endpoints

```
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/logout
GET    /api/auth/me
POST   /api/auth/refresh
```

### Pages API (New Architecture)

```
POST   /api/pages
  Description: Create a new page
  Auth: Required
  Body: {
    name: string,
    metadata?: {
      width?: number,
      height?: number,
      backgroundColor?: string,
      gridSize?: number,
      showGrid?: boolean,
      snapToGrid?: boolean,
      zoom?: number
    }
  }
  Response: Page object

GET    /api/pages
  Description: Get all pages accessible to user
  Auth: Required
  Response: PageListItem[]

GET    /api/pages/:id
  Description: Get specific page with full data
  Auth: Required
  Response: Page object (includes all widgets)

PATCH  /api/pages/:id
  Description: Update page
  Auth: Required (edit permission)
  Body: {
    name?: string,
    pageData?: Partial<PageData>
  }
  Response: Page object

DELETE /api/pages/:id
  Description: Soft delete page
  Auth: Required (owner only)
  Response: Success message

PUT    /api/pages/:id/name
  Description: Rename page
  Auth: Required (edit permission)
  Body: { name: string }
  Response: Page object

POST   /api/pages/:id/share
  Description: Share page with user
  Auth: Required (owner only)
  Body: {
    email: string,
    permissionType: 'owner' | 'edit' | 'comment' | 'view'
  }
  Response: PagePermission object

GET    /api/pages/:id/permissions
  Description: Get all permissions for page
  Auth: Required
  Response: PagePermission[]

PATCH  /api/pages/:id/permissions/:userId
  Description: Update user permission
  Auth: Required (owner only)
  Body: { permissionType: string }
  Response: PagePermission object

DELETE /api/pages/:id/permissions/:userId
  Description: Revoke user access
  Auth: Required (owner only)
  Response: Success message
```

### Canvas API (Legacy - Deprecated)

```
GET    /api/canvases
  Description: Get user's canvases (paginated)
  Auth: Required
  Query: ?page=1&limit=20
  Response: Paginated canvas list

POST   /api/canvases
  Description: Create canvas
  Auth: Required
  Body: {
    name: string,
    description?: string,
    settings?: object,
    is_public?: boolean
  }
  Response: Canvas object

GET    /api/canvases/:id
  Description: Get canvas with widgets
  Auth: Required
  Response: Canvas object with widgets array

PATCH  /api/canvases/:id
  Description: Update canvas
  Auth: Required (owner only)
  Body: { name?, description?, settings?, is_public? }
  Response: Canvas object

DELETE /api/canvases/:id
  Description: Delete canvas and all widgets
  Auth: Required (owner only)
  Response: Success message

GET    /api/canvases/:id/collaborators
  Description: Get canvas collaborators
  Auth: Required
  Response: Collaborator[]

POST   /api/canvases/:id/collaborators
  Description: Add collaborator
  Auth: Required (owner only)
  Body: { user_id: string, role: 'owner'|'editor'|'viewer' }
  Response: Collaborator object

DELETE /api/canvases/:id/collaborators/:userId
  Description: Remove collaborator
  Auth: Required (owner only)
  Response: Success message
```

### System Endpoints

```
GET    /health
  Description: Health check
  Auth: Not required
  Response: {
    success: true,
    message: "Server is healthy",
    timestamp: "ISO-8601",
    environment: "development"
  }

GET    /api
  Description: API documentation
  Auth: Not required
  Response: API version and endpoint list
```

---

## Permission System

### Permission Types

```javascript
// Permission levels (string values)
const PermissionType = {
  OWNER: 'owner',        // Full control
  EDIT: 'edit',          // Can modify content
  COMMENT: 'comment',    // Can add comments
  VIEW: 'view'           // Read-only
};
```

### Permission Matrix

| Action | Owner | Editor | Commenter | Viewer |
|--------|-------|--------|-----------|--------|
| **View page** | ✅ | ✅ | ✅ | ✅ |
| **Edit widgets** | ✅ | ✅ | ❌ | ❌ |
| **Add widgets** | ✅ | ✅ | ❌ | ❌ |
| **Delete widgets** | ✅ | ✅ | ❌ | ❌ |
| **Add comments** | ✅ | ✅ | ✅ | ❌ |
| **Share page** | ✅ | ❌ | ❌ | ❌ |
| **Change permissions** | ✅ | ❌ | ❌ | ❌ |
| **Delete page** | ✅ | ❌ | ❌ | ❌ |
| **Rename page** | ✅ | ✅ | ❌ | ❌ |

### Permission Checking Flow

```javascript
// Service layer method
async checkEditPermission(pageId, userId) {
  const result = await db.query(`
    SELECT permission_type 
    FROM page_permissions
    WHERE page_id = $1 AND user_id = $2
  `, [pageId, userId]);
  
  if (result.rows.length === 0) {
    return false;
  }
  
  const permission = result.rows[0].permission_type;
  return permission === 'owner' || permission === 'edit';
}

// Usage in WebSocket handler
socket.on('widget:update', async (data) => {
  const hasPermission = await pageService.checkEditPermission(
    data.canvasId, 
    socket.userId
  );
  
  if (!hasPermission) {
    return socket.emit('sync:error', {
      operation: 'widget:update',
      message: 'Insufficient permissions'
    });
  }
  
  // Continue with update...
});
```

### Permission Granting

```javascript
// Share page endpoint
POST /api/pages/:id/share
Body: {
  email: "user@example.com",
  permissionType: "edit"
}

// Service implementation
async sharePage(pageId, ownerId, { email, permissionType }) {
  // 1. Verify requester is owner
  const isOwner = await this.isOwner(pageId, ownerId);
  if (!isOwner) {
    throw new Error('Only owner can share page');
  }
  
  // 2. Find target user
  const user = await db.query('SELECT id FROM users WHERE email = $1', [email]);
  if (!user.rows.length) {
    throw new Error('User not found');
  }
  
  // 3. Create or update permission
  await db.query(`
    INSERT INTO page_permissions (page_id, user_id, permission_type, granted_by)
    VALUES ($1, $2, $3, $4)
    ON CONFLICT (page_id, user_id) 
    DO UPDATE SET permission_type = $3, updated_at = NOW()
  `, [pageId, user.rows[0].id, permissionType, ownerId]);
}
```

---

## Error Handling

### REST API Error Handling

```javascript
// Global error middleware
const errorHandler = (err, req, res, next) => {
  // Log error
  console.error('Error:', err);
  
  // Determine status code
  const statusCode = err.statusCode || 500;
  
  // Send error response
  res.status(statusCode).json({
    success: false,
    error: err.name || 'Error',
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// Custom error helper
const createError = (message, statusCode = 500) => {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
};

// Usage
if (!page) {
  throw createError('Page not found', 404);
}

if (!hasPermission) {
  throw createError('Insufficient permissions', 403);
}

module.exports = { errorHandler, createError };
```

### WebSocket Error Handling

```javascript
// In event handlers
socket.on('widget:add', async (data) => {
  try {
    // Operation logic...
  } catch (error) {
    console.error('Widget add error:', error);
    
    socket.emit('sync:error', {
      operation: 'widget:add',
      message: error.message || 'Failed to add widget',
      timestamp: new Date().toISOString()
    });
  }
});

// Authentication errors
io.use(async (socket, next) => {
  try {
    const token = socket.handshake.auth.token;
    if (!token) {
      return next(new Error('Authentication token required'));
    }
    
    const decoded = verifyToken(token);
    socket.userId = decoded.userId;
    socket.email = decoded.email;
    next();
  } catch (error) {
    next(new Error('Authentication failed'));
  }
});
```

### Error Response Formats

#### REST API Error Response
```json
{
  "success": false,
  "error": "AppError",
  "message": "Insufficient permissions"
}
```

#### WebSocket Error Response
```json
{
  "operation": "widget:add",
  "message": "Failed to add widget",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

---

## Performance Optimizations

### 1. Database Connection Pooling

```javascript
const { Pool } = require('pg');

// PostgreSQL pool configuration
const pool = new Pool({
  host: process.env.DB_HOST,
  port: 5432,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20,                      // Maximum connections
  idleTimeoutMillis: 30000,     // Idle timeout
  connectionTimeoutMillis: 2000  // Connection timeout
});
```

**Benefits:**
- Reuse database connections
- Reduce connection overhead
- Handle concurrent requests efficiently

### 2. Redis Caching

**Active users stored in Redis (not database):**
```typescript
// Fast lookup - O(1) complexity
const activeUsers = await redis.hgetall(`canvas:${canvasId}:users`);
```

**Benefits:**
- Sub-millisecond read/write
- Reduced database load
- Better scalability

### 3. Socket.IO Rooms

```javascript
// Targeted broadcasting
socket.to(`canvas:${canvasId}`).emit('widget:updated', data);

// Instead of global broadcast
io.emit('widget:updated', data);  // ❌ Inefficient
```

**Benefits:**
- Only relevant clients receive updates
- Reduced network traffic
- Better performance with many concurrent users

### 4. Selective Field Updates

```javascript
// Only update changed fields
const updates = [];
if (data.position !== undefined) updates.push('position = $1');
if (data.size !== undefined) updates.push('size = $2');

// Instead of full object replacement
UPDATE widgets SET * = ...  // ❌ Inefficient
```

### 5. Indexed Queries

```sql
-- Fast lookups with indexes
CREATE INDEX idx_pages_owner ON pages(owner_id);
CREATE INDEX idx_page_permissions_user ON page_permissions(user_id);
CREATE INDEX idx_widgets_canvas ON widgets(canvas_id);
```

### 6. Pagination

```javascript
// GET /api/canvases?page=1&limit=20

// Implementation
const offset = (page - 1) * limit;
const result = await db.query(`
  SELECT * FROM canvases 
  LIMIT $1 OFFSET $2
`, [limit, offset]);
```

### 7. JSONB Indexing (PostgreSQL)

```sql
-- Fast JSON queries
CREATE INDEX idx_pages_page_data ON pages USING gin(page_data);

-- Enables efficient queries like:
SELECT * FROM pages 
WHERE page_data @> '{"metadata": {"backgroundColor": "#FFFFFF"}}';
```

### 8. Request Body Size Limits

```javascript
const express = require('express');

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
```

**Prevents:**
- Memory exhaustion attacks
- Slow request processing
- Server overload

---

## Architectural Patterns

### 1. Layered Architecture

```
┌─────────────────────────────────┐
│      Presentation Layer         │
│  (Routes, Controllers)          │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│      Business Logic Layer       │
│  (Services)                     │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│      Data Access Layer          │
│  (Database, Redis)              │
└─────────────────────────────────┘
```

**Benefits:**
- Separation of concerns
- Easier testing
- Maintainable codebase

### 2. Service Layer Pattern

```javascript
// services/page.service.js
class PageService {
  async createPage(userId, data) {
    // Encapsulates data access logic
    const page = await db.query(...);
    return this.mapToPage(page);
  }
  
  async getPageById(pageId, userId) {
    // Business logic + data access
  }
}

module.exports = new PageService();
```

### 3. Schema Validation (Zod)

```javascript
const { z } = require('zod');

// Define schemas
const CreatePageSchema = z.object({
  name: z.string().min(1),
  metadata: z.object({
    width: z.number().optional(),
    height: z.number().optional(),
    backgroundColor: z.string().optional()
  }).optional()
});

// Validate input
const validateCreatePage = (data) => {
  return CreatePageSchema.parse(data);
};
```

**Benefits:**
- Runtime type checking
- Clear API contracts
- Input validation
- Automatic error messages

### 4. Middleware Chain Pattern

```javascript
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');

app.use(helmet());           // Security
app.use(cors());            // Cross-origin
app.use(express.json());    // Body parsing
app.use(morgan('dev'));     // Logging
app.use('/api/pages', authMiddleware, pageRoutes);  // Auth
```

### 5. Pub-Sub Pattern (Socket.IO Rooms)

```javascript
// Subscribe
socket.join(`canvas:${canvasId}`);

// Publish
socket.to(`canvas:${canvasId}`).emit('widget:added', data);

// Unsubscribe
socket.leave(`canvas:${canvasId}`);
```

### 6. Factory Pattern

```javascript
const { v4: uuidv4 } = require('uuid');

function createWidget(type, position, size, properties) {
  return {
    id: uuidv4(),
    type,
    position,
    size,
    properties,
    createdAt: new Date().toISOString()
  };
}
```

### 7. Singleton Pattern (Database Connection)

```javascript
// Single shared pool instance
const { Pool } = require('pg');
const pool = new Pool(config);

module.exports = { pool };

// Used across the application
const { pool } = require('./config/database');
```

---

## Configuration

### Environment Variables

```bash
# Server
PORT=3000
NODE_ENV=development|production

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=canvas_db
DB_USER=canvas_user
DB_PASSWORD=canvas_pass

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your-secret-key-here
JWT_EXPIRATION=7d

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

### Configuration Validation

```javascript
function validateEnv() {
  const required = [
    'DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD',
    'JWT_SECRET'
  ];
  
  const missing = required.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }
}

// Called at startup
validateEnv();

module.exports = { validateEnv };
```

### CORS Configuration

```javascript
const cors = require('cors');

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, curl)
    if (!origin) return callback(null, true);
    
    // Check whitelist
    if (config.cors.allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
```

---

## Future Improvements

### 1. Operational Transformation (OT)

**Current State:** Last-write-wins model (no conflict resolution)

**Improvement:**
```javascript
// Implement OT algorithm
function transform(operation1, operation2) {
  // Transform conflicting operations
  // Ensure convergence
}

// Apply transformed operations
socket.on('widget:update', async (data) => {
  const transformed = transform(data.operation, concurrentOperations);
  await applyOperation(transformed);
});
```

**Benefits:**
- True concurrent editing (like Google Docs)
- Conflict resolution
- Better user experience

### 2. CRDT (Conflict-free Replicated Data Types)

Alternative to OT for distributed systems:
```javascript
// Use CRDT library like Yjs
const Y = require('yjs');

const doc = new Y.Doc();
const widgets = doc.getArray('widgets');

// Automatic conflict resolution
widgets.push([newWidget]);
```

### 3. Rate Limiting

```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 100                    // Limit per window
});

app.use('/api/', limiter);
```

### 4. WebSocket Compression

```javascript
const { Server } = require('socket.io');

const io = new Server(httpServer, {
  perMessageDeflate: {
    threshold: 1024  // Compress messages > 1KB
  }
});
```

### 5. Database Replication

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Primary │────>│ Replica 1│────>│ Replica 2│
│   (Write)│     │  (Read)  │     │  (Read)  │
└──────────┘     └──────────┘     └──────────┘
```

**Benefits:**
- Read scalability
- High availability
- Disaster recovery

### 6. Message Queue (for events)

```
┌────────┐     ┌──────────┐     ┌─────────┐
│ Backend│────>│ RabbitMQ │────>│ Workers │
└────────┘     └──────────┘     └─────────┘
```

**Use cases:**
- Email notifications
- Webhook processing
- Background jobs

### 7. Monitoring & Logging

```javascript
// APM tools
const Sentry = require('@sentry/node');
const prometheus = require('prom-client');

// Error tracking
Sentry.init({ dsn: process.env.SENTRY_DSN });

// Metrics
const httpRequestDuration = new prometheus.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds'
});
```

### 8. API Versioning

```javascript
// v1 API
app.use('/api/v1/pages', pagesV1Routes);

// v2 API (with breaking changes)
app.use('/api/v2/pages', pagesV2Routes);
```

### 9. GraphQL API (Alternative)

```graphql
type Query {
  pages: [Page!]!
  page(id: ID!): Page
}

type Mutation {
  createPage(input: CreatePageInput!): Page!
  updatePage(id: ID!, input: UpdatePageInput!): Page!
  deletePage(id: ID!): Boolean!
}

type Subscription {
  pageUpdated(pageId: ID!): Page!
  widgetAdded(canvasId: ID!): Widget!
}
```

### 10. Horizontal Scaling

```
           ┌──────────┐
           │  Load    │
           │ Balancer │
           └────┬─────┘
                │
        ┌───────┼───────┐
        │       │       │
    ┌───▼──┐ ┌──▼──┐ ┌─▼───┐
    │Server│ │Server│ │Server│
    │   1  │ │  2  │ │  3  │
    └───┬──┘ └──┬──┘ └─┬───┘
        │       │      │
        └───────┼──────┘
                │
        ┌───────▼───────┐
        │ Shared Redis  │
        │   (Sticky     │
        │   Sessions)   │
        └───────────────┘
```

**Requirements:**
- Redis for session sharing
- Socket.IO Redis adapter
- Sticky sessions or shared state

---

## Conclusion

This architecture provides a solid foundation for a real-time collaborative canvas editor with:

✅ **Real-time synchronization** via WebSocket (Socket.IO)  
✅ **Robust permission system** (Owner, Editor, Commenter, Viewer)  
✅ **Comments and annotations** with mentions  
✅ **Undo/Redo functionality** with operational history  
✅ **Version history** and audit trails  
✅ **Scalable data storage** (PostgreSQL + Redis)  
✅ **JWT authentication** for REST and WebSocket  
✅ **Schema validation** with Zod  
✅ **Error handling** at all layers  
✅ **Performance optimizations** (pooling, caching, indexing)

The main areas for production readiness are:
- Implementing OT/CRDT for conflict resolution
- Adding comprehensive monitoring
- Setting up horizontal scaling
- Implementing rate limiting
- Adding integration tests

---

**Document Version:** 1.1  
**Last Updated:** 2024  
**Technology:** Node.js (JavaScript ES6)  
**Author:** Backend Architecture Team
