# SyncEditor - Technical Architecture Document

## Executive Summary

**SyncEditor** is a real-time collaborative canvas editor that enables multiple users to simultaneously edit pages with widgets, comments, and operational transformation-based conflict resolution. The system uses a modern client-server architecture with WebSocket for real-time synchronization and JSON Patch for incremental updates.

---

## 1. System Overview

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         FRONTEND (Flutter/Dart)                  │
├─────────────────────────────────────────────────────────────────┤
│  Presentation Layer (BLoC Pattern)                               │
│  ├── Auth Bloc              ├── Page Bloc                       │
│  ├── Canvas Bloc            ├── Widget Bloc                     │
│  └── Comments Bloc          └── Collaboration Bloc              │
│                                                                   │
│  Service Layer                                                   │
│  ├── API Client (Dio/HTTP)  ├── WebSocket Client                │
│  ├── Page Service           ├── Comments Service                │
│  ├── Sync Service           └── Patch Service                   │
│                                                                   │
│  Data Layer                                                      │
│  ├── Models                 ├── Local Storage                   │
│  └── WebSocket Events       └── JWT Token Management            │
└─────────────────────────────────────────────────────────────────┘
                                    ▲  │
                     HTTP REST API  │  │  WebSocket (Socket.io)
                                    │  ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND (Node.js/Express)                     │
├─────────────────────────────────────────────────────────────────┤
│  API Layer (REST + WebSocket)                                   │
│  ├── Express Middleware     ├── Socket.io Handler               │
│  ├── Auth Middleware        ├── JWT Verification                │
│  └── Error Handling         └── CORS Configuration              │
│                                                                   │
│  Business Logic Layer                                           │
│  ├── Page Controllers       ├── Auth Controllers                │
│  ├── Canvas Controllers     ├── Widget Controllers              │
│  └── Comments Controllers   └── Collaboration Logic             │
│                                                                   │
│  Service Layer                                                   │
│  ├── Patch Service          ├── OT Service                      │
│  ├── Undo/Redo Service      ├── Operation History Service       │
│  └── Comments Service       └── User Colors Service             │
│                                                                   │
│  Data Access Layer                                              │
│  ├── PostgreSQL Pool        └── Redis Client                    │
└─────────────────────────────────────────────────────────────────┘
                                    │  │
                     ┌──────────────┴──┴──────────────┐
                     ▼                                 ▼
         ┌───────────────────────┐       ┌───────────────────────┐
         │  PostgreSQL Database  │       │    Redis Cache        │
         │  - Users              │       │  - Active Sessions    │
         │  - Pages              │       │  - User Presence      │
         │  - Widgets            │       │  - Cursor Positions   │
         │  - Comments           │       │  - Undo/Redo Stacks   │
         │  - Permissions        │       └───────────────────────┘
         │  - Operation History  │
         │  - Page Patches       │
         └───────────────────────┘
```

---

## 2. Technology Stack

### 2.1 Frontend Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Framework** | Flutter 3.11+ (Dart) | Cross-platform UI framework for web/mobile |
| **State Management** | BLoC (Business Logic Component) | Predictable state management with streams |
| **HTTP Client** | Dio 5.3+ | HTTP requests with interceptors and error handling |
| **WebSocket** | socket_io_client 2.0+ | Real-time bidirectional communication |
| **Local Storage** | shared_preferences 2.2+ | JWT token persistence |
| **JSON Patching** | json_patch 3.0+ | Client-side patch generation and application |
| **Utilities** | uuid, intl, equatable | ID generation, i18n, value comparison |

### 2.2 Backend Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Runtime** | Node.js 18+ | JavaScript runtime environment |
| **Framework** | Express.js 4.18+ | HTTP server and REST API framework |
| **WebSocket** | Socket.io 4.6+ | Real-time event-based communication |
| **Database** | PostgreSQL 14+ | Relational database for persistent storage |
| **Cache** | Redis 6+ | In-memory cache for sessions and real-time data |
| **Authentication** | JWT (jsonwebtoken 9.0+) | Stateless authentication tokens |
| **Password Hashing** | bcrypt 5.1+ | Secure password hashing |
| **JSON Patching** | fast-json-patch 3.1+ | RFC 6902 JSON Patch implementation |
| **Schema Validation** | Zod 3.22+ | Runtime type checking and validation |
| **Security** | Helmet 7.1+ | Security headers middleware |

---

## 3. Backend Architecture (Node.js/JavaScript)

### 3.1 Directory Structure

```
backend/
├── src-js/                      # JavaScript source (production)
│   ├── app.js                   # Express app configuration
│   ├── server.js                # Server startup and lifecycle
│   ├── config/
│   │   ├── database.js          # PostgreSQL connection pool
│   │   ├── redis.js             # Redis client configuration
│   │   └── env.js               # Environment variable validation
│   ├── controllers/
│   │   ├── auth.controller.js   # Auth endpoints (login, register)
│   │   ├── page.controller.js   # Page CRUD operations
│   │   ├── canvas.controller.js # Legacy canvas endpoints
│   │   ├── widget.controller.js # Widget operations
│   │   └── comments.controller.js # Comments CRUD
│   ├── middleware/
│   │   ├── auth.middleware.js   # JWT verification
│   │   ├── validation.middleware.js # Request validation
│   │   └── error.middleware.js  # Global error handler
│   ├── routes/
│   │   ├── auth.routes.js       # /api/auth/*
│   │   ├── page.routes.js       # /api/pages/*
│   │   ├── canvas.routes.js     # /api/canvases/* (deprecated)
│   │   └── comments.routes.js   # /api/comments/*
│   ├── services/
│   │   ├── page.service.js      # Page business logic
│   │   ├── patch.service.js     # JSON Patch operations
│   │   ├── ot.service.js        # Operational Transformation
│   │   ├── undoRedo.service.js  # Undo/Redo logic
│   │   ├── operationHistory.service.js # Operation tracking
│   │   └── comments.service.js  # Comments business logic
│   ├── utils/
│   │   ├── jwt.js               # JWT token generation/verification
│   │   ├── response.js          # Standardized API responses
│   │   └── userColors.js        # User presence color assignment
│   └── websocket/
│       ├── socket.handler.js    # Main WebSocket handler
│       ├── page.handler.js      # Page-specific WebSocket events
│       └── events.js            # Event type definitions
├── src/                         # TypeScript source (development)
├── package.json
├── .env.example
└── README.md
```

### 3.2 Core Backend Components

#### 3.2.1 Express Application (`app.js`)

**Responsibilities:**
- HTTP server configuration
- Middleware setup (CORS, Helmet, Body Parser, Morgan)
- Route registration
- Global error handling

**Key Middleware:**
```javascript
- helmet()              // Security headers
- cors()                // Cross-origin resource sharing
- express.json()        // JSON body parsing (10MB limit)
- morgan()              // HTTP request logging
- errorHandler()        // Global error middleware
```

#### 3.2.2 Server Lifecycle (`server.js`)

**Initialization Sequence:**
1. Validate environment variables
2. Create HTTP server
3. Initialize Socket.io with CORS
4. Test PostgreSQL connection
5. Test Redis connection (non-blocking)
6. Start HTTP server
7. Setup graceful shutdown handlers

**Graceful Shutdown:**
- Close HTTP server
- Disconnect Socket.io clients
- Close database pool
- Close Redis connection
- 10-second force shutdown timeout

#### 3.2.3 Database Layer (`config/database.js`)

**PostgreSQL Connection Pool:**
```javascript
Pool Configuration:
- Max connections: 20
- Idle timeout: 30 seconds
- Connection timeout: 2 seconds
```

**Core Tables:**
```sql
users                 -- User accounts
pages                 -- Canvas pages
page_permissions      -- Page access control
page_patches          -- JSON Patch history
widgets               -- Canvas widgets (deprecated)
comments              -- Page comments
comment_mentions      -- @mentions in comments
operation_history     -- Undo/Redo operation log
active_editors        -- Real-time user presence
```

#### 3.2.4 Redis Cache (`config/redis.js`)

**Usage:**
- Active user sessions per page (`page:{pageId}:users`)
- Real-time cursor positions (`page:{pageId}:cursors`)
- Undo/Redo stacks per user (`page:{pageId}:undo:{userId}`)
- WebSocket connection metadata

**Configuration:**
- Retry strategy: Exponential backoff (max 2 seconds)
- Max retries per request: 3
- Auto-reconnection enabled

---

## 4. Frontend Architecture (Flutter/Dart)

### 4.1 Directory Structure

```
frontend/
├── lib/
│   ├── main.dart                # App entry point
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart  # HTTP client (Dio)
│   │   │   ├── websocket_client.dart # Socket.io client
│   │   │   └── endpoints.dart   # API endpoint constants
│   │   ├── models/
│   │   │   ├── page.dart        # Page data models
│   │   │   ├── widget_model.dart # Widget models
│   │   │   ├── comment.dart     # Comment models
│   │   │   └── user.dart        # User models
│   │   └── services/
│   │       ├── auth_service.dart     # Authentication
│   │       ├── page_service.dart     # Page API calls
│   │       ├── canvas_service.dart   # Canvas operations
│   │       ├── sync_service.dart     # Sync queue management
│   │       ├── patch_service.dart    # JSON Patch handling
│   │       └── comments_service.dart # Comments API calls
│   ├── features/
│   │   ├── auth/
│   │   │   ├── bloc/            # Auth state management
│   │   │   └── views/           # Login/register screens
│   │   ├── page/
│   │   │   ├── bloc/            # Page state management
│   │   │   ├── views/           # Page dashboard, editor
│   │   │   └── widgets/         # Page UI components
│   │   ├── canvas/
│   │   │   ├── bloc/            # Canvas state management
│   │   │   └── views/           # Canvas editor view
│   │   └── comments/
│   │       ├── bloc/            # Comments state management
│   │       └── widgets/         # Comment UI components
│   └── editor/
│       └── widgets/             # Reusable editor widgets
├── pubspec.yaml
└── README.md
```

### 4.2 Core Frontend Components

#### 4.2.1 API Client (`api_client.dart`)

**Responsibilities:**
- HTTP request/response handling
- JWT token management
- Request/response interceptors
- Error handling and retry logic

**Features:**
```dart
- Automatic token injection (Authorization: Bearer {token})
- 401 handling (automatic logout)
- Request/response logging
- Token persistence (SharedPreferences)
- 10-second connection/receive timeout
```

#### 4.2.2 WebSocket Client (`websocket_client.dart`)

**Socket.io Events:**
```dart
CLIENT_EVENTS:
- page:join                 // Join page room
- page:leave                // Leave page room
- page:patch                // Send JSON Patch
- page:cursor               // Cursor position update
- page:selection            // Widget selection
- page:undo                 // Undo operation
- page:redo                 // Redo operation
- comment:create            // Create comment
- comment:update            // Update comment
- comment:delete            // Delete comment
- comment:resolve           // Resolve/unresolve

SERVER_EVENTS:
- page:joined               // Confirmation + page data
- page:user-joined          // Another user joined
- page:user-left            // Another user left
- page:patch-applied        // Patch acknowledged
- page:patch-received       // Broadcast from other users
- page:conflict             // Version conflict detected
- page:undo-applied         // Undo successful
- page:redo-applied         // Redo successful
- comment:created           // Comment created
- comment:updated           // Comment updated
- comment:deleted           // Comment deleted
```

#### 4.2.3 BLoC Architecture

**State Management Pattern:**
```dart
Events → BLoC → States → UI Rebuild

Example (Page BLoC):
PageEvent                PageBloc              PageState
├── LoadPages     →     ├── Event Handler  →  ├── PageLoading
├── CreatePage    →     ├── Business Logic →  ├── PageLoaded
├── UpdatePage    →     ├── API Calls      →  ├── PageError
└── DeletePage    →     └── State Emission →  └── PageOperationSuccess
```

**Key BLoCs:**
- `AuthBloc` - Authentication state (login, logout, token refresh)
- `PageBloc` - Page lifecycle (CRUD, permissions)
- `CanvasBloc` - Canvas editing state
- `CollaborationBloc` - Real-time collaboration state
- `CommentsBloc` - Comments state

#### 4.2.4 Sync Service (`sync_service.dart`)

**Operation Queue:**
```dart
Queue<SyncOperation> _pendingOperations
Map<String, SyncOperation> _inProgressOperations

Flow:
1. User action → Queue operation
2. Debounce timer (500ms)
3. Process queue sequentially
4. REST API call
5. Backend broadcasts via WebSocket
6. Update local state
```

**Sync States:**
- `synced` - All changes persisted
- `pending` - Waiting for debounce
- `syncing` - Actively syncing
- `failed` - Sync error (retry logic)

---

## 5. Real-Time Collaboration Architecture

### 5.1 JSON Patch Synchronization

**Protocol: RFC 6902 JSON Patch**

**Patch Operations:**
```json
[
  { "op": "add", "path": "/widgets/123", "value": {...} },
  { "op": "remove", "path": "/widgets/456" },
  { "op": "replace", "path": "/widgets/789/x", "value": 150 }
]
```

**Synchronization Flow:**

```
Client A                    Server                      Client B
   │                           │                           │
   │  1. Edit widget           │                           │
   ├──────────────────────────►│                           │
   │  PATCH /api/pages/:id     │                           │
   │  + JSON Patch operations  │                           │
   │                           │                           │
   │                           │  2. Apply patch           │
   │                           │  3. Increment version     │
   │                           │  4. Save to DB            │
   │                           │                           │
   │◄──────────────────────────┤                           │
   │  5. Confirmation          │                           │
   │  { version: 42 }          │                           │
   │                           │                           │
   │                           ├──────────────────────────►│
   │                           │  6. Broadcast via WS      │
   │                           │  page:patch-received      │
   │                           │  { patches, version: 42 } │
   │                           │                           │
   │                           │                           │  7. Apply patch
   │                           │                           │     locally
```

### 5.2 Operational Transformation (OT)

**Purpose:** Resolve concurrent edit conflicts to maintain eventual consistency.

**Algorithm:**
```javascript
transform(clientPatches, serverPatches) {
  for each serverPatch in serverPatches:
    for each clientPatch in clientPatches:
      if paths_overlap(clientPatch, serverPatch):
        clientPatch = transform_operation(clientPatch, serverPatch)
  
  return transformed_clientPatches
}
```

**Transformation Rules:**

| Client Op | Server Op | Transformation |
|-----------|-----------|----------------|
| `add` at index N | `add` at index N | Increment client index to N+1 |
| `remove` at index N | `remove` at index N | Cancel client operation (already removed) |
| `replace` path X | `remove` path X | Cancel client operation (target deleted) |
| `replace` path X | `replace` path X | Last-Write-Wins (client overwrites) |
| Child path edit | Parent path `remove` | Cancel client operation (parent deleted) |

**OT Service Features:**
- Path overlap detection
- Array index adjustment
- Parent-child relationship handling
- Operation priority resolution
- Conflict cancellation

### 5.3 Version Control & Conflict Resolution

**Page Versioning:**
```javascript
pages table:
├── version (integer)        // Incremented on each change
├── page_data (jsonb)        // Current state
└── updated_at (timestamp)

page_patches table:
├── from_version             // Version before patch
├── to_version               // Version after patch
├── patches (jsonb[])        // Patch operations
└── created_at
```

**Conflict Resolution Flow:**
```
Client sends patch with clientVersion = 40
Server currentVersion = 42

1. Version mismatch detected (40 ≠ 42)
2. Fetch patches between v40 and v42
3. Apply OT: transform clientPatches against serverPatches
4. Apply transformed patches
5. Increment version to v43
6. Send acknowledgment with new version
```

### 5.4 Undo/Redo with OT

**Stack Architecture:**
```
Redis:
├── page:{pageId}:undo:{userId}    // Undo stack (operation IDs)
└── page:{pageId}:redo:{userId}    // Redo stack (operation IDs)

PostgreSQL:
operation_history:
├── id                              // Operation UUID
├── operation (jsonb[])             // Forward patch
├── inverse_operation (jsonb[])     // Reverse patch
├── from_version                    // Version before
├── to_version                      // Version after
└── parent_operations               // Dependencies
```

**Undo Flow:**
```
1. Pop operation ID from undo stack
2. Get operation from operation_history
3. Extract inverse_operation
4. Get concurrent operations since original version
5. Transform inverse_operation using OT
6. Apply transformed inverse
7. Push operation ID to redo stack
8. Broadcast to other users
```

**Redo Flow:**
```
1. Pop operation ID from redo stack
2. Get operation from operation_history
3. Extract forward operation
4. Transform against concurrent operations
5. Apply transformed operation
6. Push to undo stack
7. Broadcast to other users
```

---

## 6. Authentication & Authorization

### 6.1 JWT Authentication

**Token Structure:**
```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "userId": "uuid",
    "email": "user@example.com",
    "iat": 1234567890,
    "exp": 1234654290
  }
}
```

**Token Lifecycle:**
```
1. User login → Generate JWT
2. Store in SharedPreferences (Frontend)
3. Include in every HTTP request (Authorization: Bearer {token})
4. Include in WebSocket handshake (auth.token)
5. Verify on server for each protected route
6. Auto-logout on 401 response
```

### 6.2 Permission System

**Permission Levels:**
```
owner     - Full control (delete page, manage permissions)
edit      - Edit content (add/update/delete widgets, comments)
view      - Read-only access
```

**Database Schema:**
```sql
page_permissions:
├── page_id (FK)
├── user_id (FK)
├── permission_type (enum: owner, edit, view)
└── granted_at
```

**Authorization Check:**
```javascript
// Middleware checks:
1. JWT valid?
2. User has access to page?
3. User has required permission level?
```

---

## 7. Real-Time Presence & Collaboration

### 7.1 User Presence

**Active Users Tracking:**
```javascript
Redis: page:{pageId}:users
{
  "user-uuid-1": {
    "userId": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "avatarUrl": "https://...",
    "color": "#3B82F6",      // Unique color per user
    "joinedAt": "2024-01-01T00:00:00Z"
  }
}
```

**Events:**
- `page:user-joined` - User enters page
- `page:user-left` - User leaves page
- Auto-cleanup on disconnect

### 7.2 Cursor Tracking

**Real-Time Cursor Positions:**
```javascript
Redis: page:{pageId}:cursors (TTL: 30s)
{
  "user-uuid-1": {
    "userId": "uuid",
    "position": { "x": 150, "y": 200 },
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

**WebSocket Events:**
- Client sends `page:cursor` every 100ms
- Server broadcasts `page:cursor-updated` to others
- Auto-expires after 30 seconds of inactivity

### 7.3 Widget Selection State

**Selection Broadcasting:**
```javascript
Client selects widget:
1. Emit page:selection { pageId, widgetId }
2. Server broadcasts to others
3. UI shows colored selection border

Client deselects:
1. Emit page:selection { pageId, widgetId: null }
2. Server broadcasts deselection
```

---

## 8. Comments System

### 8.1 Comment Structure

**Database Schema:**
```sql
comments:
├── id (uuid)
├── page_id (uuid FK)
├── user_id (uuid FK)
├── content (text)              // Markdown supported
├── position_x (float)          // Canvas X coordinate
├── position_y (float)          // Canvas Y coordinate
├── widget_id (uuid FK)         // Optional: attached to widget
├── parent_comment_id (uuid FK) // Optional: reply thread
├── resolved (boolean)
├── resolved_by (uuid FK)
├── resolved_at (timestamp)
├── created_at (timestamp)
└── updated_at (timestamp)

comment_mentions:
├── comment_id (uuid FK)
└── user_id (uuid FK)
```

### 8.2 Real-Time Comment Sync

**WebSocket Events:**
```
CREATE:
Client: comment:create → Server: comment:created (broadcast)

UPDATE:
Client: comment:update → Server: comment:updated (broadcast)

DELETE:
Client: comment:delete → Server: comment:deleted (broadcast)

RESOLVE:
Client: comment:resolve → Server: comment:resolved (broadcast)
```

### 8.3 @Mentions

**Mention Parsing:**
```javascript
Content: "Hey @john, can you review this widget?"

1. Extract mentions: ["@john"]
2. Resolve to user IDs: ["uuid-john"]
3. Insert into comment_mentions table
4. Emit mention event to mentioned users
5. UI shows notification badge
```

---

## 9. Performance Optimization

### 9.1 Database Optimization

**Indexes:**
```sql
CREATE INDEX idx_pages_owner ON pages(owner_id);
CREATE INDEX idx_pages_deleted ON pages(deleted_at);
CREATE INDEX idx_permissions_page ON page_permissions(page_id);
CREATE INDEX idx_permissions_user ON page_permissions(user_id);
CREATE INDEX idx_patches_page_version ON page_patches(page_id, to_version);
CREATE INDEX idx_comments_page ON comments(page_id);
CREATE INDEX idx_comments_widget ON comments(widget_id);
```

**Connection Pooling:**
- Max 20 concurrent connections
- Idle timeout: 30 seconds
- Connection reuse for performance

### 9.2 Redis Caching Strategy

**Cache Keys:**
```
page:{pageId}:users          // Active users (Hash)
page:{pageId}:cursors        // Cursor positions (Hash, TTL: 30s)
page:{pageId}:undo:{userId}  // Undo stack (List)
page:{pageId}:redo:{userId}  // Redo stack (List)
```

**Expiration:**
- Cursor positions: 30 seconds (auto-cleanup inactive)
- User presence: Manual cleanup on disconnect
- Undo/Redo stacks: 24 hours

### 9.3 Frontend Optimization

**Debouncing:**
- Sync operations: 500ms debounce
- Cursor updates: 100ms throttle
- Search/filter: 300ms debounce

**State Management:**
- BLoC pattern prevents unnecessary rebuilds
- Equatable for efficient state comparison
- Stream-based reactive updates

**Network:**
- HTTP connection pooling (Dio)
- WebSocket persistent connection
- Automatic retry on network failure

---

## 10. Error Handling & Resilience

### 10.1 Backend Error Handling

**Global Error Middleware:**
```javascript
errorHandler(err, req, res, next) {
  // Log error
  console.error(err);
  
  // Determine status code
  const statusCode = err.statusCode || 500;
  
  // Send standardized response
  res.status(statusCode).json({
    success: false,
    message: err.message,
    ...(env.NODE_ENV === 'development' && { stack: err.stack })
  });
}
```

**Database Error Handling:**
- Connection retry with exponential backoff
- Transaction rollback on failure
- Graceful degradation (Redis optional)

### 10.2 Frontend Error Handling

**API Exception Types:**
```dart
enum ApiExceptionType {
  timeout,         // Connection timeout
  unauthorized,    // 401 - Auto logout
  forbidden,       // 403 - Show error
  notFound,        // 404 - Show not found
  badRequest,      // 400 - Validation error
  server,          // 500+ - Server error
  network,         // Network failure
  cancel,          // Request cancelled
  unknown,         // Unknown error
}
```

**Retry Logic:**
- Sync operations: 3 retries with exponential backoff
- WebSocket reconnection: Automatic with socket.io
- HTTP timeout: 10 seconds

### 10.3 Conflict Resolution Strategy

**Strategies:**
1. **Optimistic Locking** - Version-based conflict detection
2. **Operational Transformation** - Automatic patch transformation
3. **Last-Write-Wins** - For unresolvable conflicts
4. **User Notification** - Show conflict dialog if needed

---

## 11. Security Considerations

### 11.1 Authentication Security

**JWT Security:**
- Secret stored in environment variable (256-bit)
- Token expiration: 24 hours
- HTTPS-only in production
- HttpOnly cookies (planned)

**Password Security:**
- bcrypt hashing (cost factor: 10)
- Min 8 characters, complexity requirements
- Rate limiting on login attempts

### 11.2 Authorization Security

**Access Control:**
- Row-level security via page_permissions
- Owner-only operations (delete, manage permissions)
- Editor-only operations (edit content)
- Viewer-only operations (read)

**WebSocket Security:**
- JWT verification on connection
- Room-based isolation (page:${pageId})
- Permission checks on every event

### 11.3 API Security

**Middleware:**
```javascript
- Helmet.js              // Security headers
- CORS                   // Origin whitelisting
- Rate limiting          // Planned: express-rate-limit
- Input validation       // Zod schema validation
- SQL injection          // Parameterized queries
- XSS protection         // Output sanitization
```

**Data Validation:**
- Schema validation with Zod
- JSON Patch validation
- File upload restrictions (planned)

---

## 12. Deployment Architecture

### 12.1 Production Environment

**Recommended Stack:**
```
┌─────────────────────────────────────────────────┐
│            Load Balancer (Nginx)                │
│  - SSL Termination                              │
│  - Rate Limiting                                │
│  - Static Asset Caching                         │
└────────────────┬────────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
┌───────▼─────────┐  ┌───▼──────────────┐
│  Node.js Server │  │ Node.js Server   │
│  (Port 3000)    │  │ (Port 3001)      │
│  + Socket.io    │  │ + Socket.io      │
└────────┬────────┘  └───┬──────────────┘
         │               │
         └───────┬───────┘
                 │
        ┌────────┴────────┐
        │                 │
┌───────▼─────────┐  ┌───▼──────────────┐
│   PostgreSQL    │  │     Redis         │
│   (Primary)     │  │   (Cache/Queue)   │
│                 │  │                   │
│  + Replication  │  │  + Persistence    │
└─────────────────┘  └───────────────────┘
```

### 12.2 Environment Configuration

**Backend (.env):**
```bash
NODE_ENV=production
PORT=3000

# Database
DB_HOST=postgres.example.com
DB_PORT=5432
DB_NAME=synceditor_prod
DB_USER=app_user
DB_PASSWORD=***

# Redis
REDIS_HOST=redis.example.com
REDIS_PORT=6379

# JWT
JWT_SECRET=*** (256-bit random string)
JWT_EXPIRES_IN=24h

# CORS
ALLOWED_ORIGINS=https://app.example.com,https://www.example.com
```

**Frontend (Flutter build):**
```bash
flutter build web --release
# Output: build/web/

# Deploy to:
- Vercel
- Netlify
- AWS S3 + CloudFront
- Firebase Hosting
```

### 12.3 Monitoring & Logging

**Logging:**
- Morgan for HTTP request logging
- Winston for application logging (planned)
- Error tracking: Sentry (planned)

**Metrics:**
- WebSocket connection count
- Active users per page
- Database connection pool usage
- Redis memory usage
- API response times

---

## 13. API Reference

### 13.1 REST API Endpoints

**Authentication:**
```
POST   /api/auth/register      - Register new user
POST   /api/auth/login         - Login user
POST   /api/auth/logout        - Logout user
GET    /api/auth/me            - Get current user
```

**Pages:**
```
GET    /api/pages              - List user's pages
POST   /api/pages              - Create new page
GET    /api/pages/:id          - Get page by ID
PATCH  /api/pages/:id          - Update page
DELETE /api/pages/:id          - Delete page
PUT    /api/pages/:id/name     - Rename page
```

**Page Permissions:**
```
POST   /api/pages/:id/share             - Share page with user
GET    /api/pages/:id/permissions       - Get page permissions
PATCH  /api/pages/:id/permissions/:uid  - Update user permission
DELETE /api/pages/:id/permissions/:uid  - Revoke access
```

**Comments:**
```
GET    /api/pages/:id/comments          - Get page comments
POST   /api/pages/:id/comments          - Create comment
PATCH  /api/comments/:id                - Update comment
DELETE /api/comments/:id                - Delete comment
PUT    /api/comments/:id/resolve        - Resolve/unresolve comment
```

**Health:**
```
GET    /health                 - Health check
GET    /api                    - API info
```

### 13.2 WebSocket Events

**Connection:**
```javascript
// Client → Server
socket.emit('page:join', { pageId })

// Server → Client
socket.on('page:joined', { pageId, pageName, pageData, version, activeUsers })
```

**Real-Time Sync:**
```javascript
// Client → Server
socket.emit('page:patch', { pageId, patches, clientVersion })

// Server → Client
socket.on('page:patch-applied', { pageId, version, patches, transformed })
socket.on('page:patch-received', { pageId, userId, patches, version })
```

**Undo/Redo:**
```javascript
// Client → Server
socket.emit('page:undo', { pageId })
socket.emit('page:redo', { pageId })

// Server → Client
socket.on('page:undo-applied', { pageId, version, patches, canUndo, canRedo })
socket.on('page:redo-applied', { pageId, version, patches, canUndo, canRedo })
```

**Collaboration:**
```javascript
// Client → Server
socket.emit('page:cursor', { pageId, position: { x, y } })
socket.emit('page:selection', { pageId, widgetId })

// Server → Client
socket.on('page:cursor-updated', { userId, userName, userColor, position })
socket.on('page:selection-updated', { userId, widgetId })
socket.on('page:user-joined', { user })
socket.on('page:user-left', { userId })
```

---

## 14. Future Enhancements

### 14.1 Planned Features

**Backend:**
- [ ] Rate limiting (express-rate-limit)
- [ ] WebSocket authentication refresh
- [ ] Operation history pruning (old operations)
- [ ] Patch compression
- [ ] File upload support
- [ ] Export page to JSON/PDF
- [ ] Audit logging
- [ ] Webhook notifications

**Frontend:**
- [ ] Offline mode with local queue
- [ ] Conflict resolution UI
- [ ] Real-time notifications panel
- [ ] Keyboard shortcuts
- [ ] Widget templates library
- [ ] Version history browser
- [ ] Mobile app (iOS/Android)
- [ ] Dark mode

### 14.2 Scalability Improvements

**Horizontal Scaling:**
- WebSocket load balancing (Socket.io with Redis adapter)
- Stateless server design (JWT + Redis)
- Database read replicas
- CDN for static assets

**Performance:**
- GraphQL API (alternative to REST)
- Server-side rendering (SSR)
- Lazy loading widgets
- Virtual scrolling for large canvases
- WebAssembly for complex operations

---

## 15. Development Setup

### 15.1 Prerequisites

**Backend:**
```bash
Node.js 18+
PostgreSQL 14+
Redis 6+
```

**Frontend:**
```bash
Flutter SDK 3.11+
Dart SDK 3.11+
```

### 15.2 Local Development

**Backend:**
```bash
cd backend
cp .env.example .env
npm install
npm run dev           # JavaScript (nodemon)
# OR
npm run dev:ts        # TypeScript (ts-node)
```

**Frontend:**
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

**Database Setup:**
```bash
psql -U postgres
CREATE DATABASE synceditor_dev;
CREATE USER synceditor WITH PASSWORD 'dev_password';
GRANT ALL PRIVILEGES ON DATABASE synceditor_dev TO synceditor;

# Run migrations
cd backend
node src/scripts/run-migrations.ts
```

---

## 16. Testing Strategy

### 16.1 Backend Testing

**Unit Tests:**
- Service layer logic
- OT transformation algorithms
- JWT generation/verification

**Integration Tests:**
- API endpoints
- Database operations
- WebSocket events

**Load Tests:**
- Concurrent users per page
- WebSocket connection limits
- Database query performance

### 16.2 Frontend Testing

**Widget Tests:**
- UI components
- BLoC state transitions

**Integration Tests:**
- API service calls
- WebSocket connections

**E2E Tests:**
- User flows (create page, edit, collaborate)
- Multi-user scenarios

---

## 17. Conclusion

SyncEditor implements a robust real-time collaborative editing system using:

- **JSON Patch** for efficient incremental updates
- **Operational Transformation** for conflict resolution
- **WebSocket** for real-time synchronization
- **BLoC pattern** for predictable state management
- **JWT authentication** for secure access
- **PostgreSQL + Redis** for persistent and ephemeral storage

The architecture is designed for:
✅ **Scalability** - Horizontal scaling with load balancers
✅ **Performance** - Optimistic UI updates, debouncing, caching
✅ **Reliability** - Retry logic, graceful degradation, error handling
✅ **Security** - JWT auth, permission-based access, input validation
✅ **Collaboration** - Real-time presence, cursor tracking, conflict resolution

---

**Document Version:** 1.0  
**Last Updated:** 2024-01-01  
**Author:** Technical Architecture Team
