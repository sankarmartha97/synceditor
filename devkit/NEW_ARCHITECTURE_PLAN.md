# 🎯 NEW ARCHITECTURE PLAN: Page-Based Collaborative Editor

**Version:** 2.0  
**Last Updated:** January 2025  
**Status:** Planning Phase

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Current vs New Architecture](#current-vs-new-architecture)
3. [Phase 1: Page Management System](#phase-1-page-management-system-week-1)
4. [Phase 2: Incremental Sync System](#phase-2-incremental-sync-system-week-2)
5. [Phase 3: Permission System](#phase-3-permission-system-week-3)
6. [Phase 4: Real-Time Collaboration](#phase-4-real-time-collaboration-week-4)
7. [Phase 5: Advanced Features](#phase-5-advanced-features-week-5)
8. [Migration Plan](#migration-plan-current--new)
9. [Technical Implementation](#technical-implementation-details)
10. [Implementation Order](#suggested-implementation-order)

---

## 🏗️ Architecture Overview

### **Core Concept**
Transform from **canvas-based widget management** to **page-based document collaboration** with incremental sync and real-time multi-user editing.

### **Key Changes**
- **Pages** replace Canvases (semantic shift)
- **Single JSON document** represents entire page
- **Incremental sync** - only changed parts transmitted
- **Permission-based sharing** (Edit/View/Comment)
- **Real-time collaboration** with conflict resolution
- **Version history** with restore capability

---

## 📊 Current vs New Architecture

### **Current (Canvas-Based)**

```
User creates "Canvas"
   ↓
Adds individual widgets
   ↓
Each widget = separate DB row
   ↓
Widget operations:
- POST /api/widgets (create)
- PATCH /api/widgets/:id (update)
- DELETE /api/widgets/:id (delete)
   ↓
Canvas = collection of widget IDs
```

**Limitations:**
- ❌ Each widget change = separate API call
- ❌ No incremental sync (full widget updates)
- ❌ No permission system
- ❌ No version history
- ❌ Conflict resolution difficult

---

### **New (Page-Based)** ✨

```
User creates "Page"
   ↓
Page = single JSON document
   ↓
All widgets stored in page.widgets[]
   ↓
Page operations:
- POST /api/pages (create page)
- PATCH /api/pages/:id (sync changes)
- GET /api/pages/:id (load page)
   ↓
Operations = JSON Patch format
   ↓
Real-time sync via WebSocket
```

**Benefits:**
- ✅ Single JSON document (easier to manage)
- ✅ Incremental sync (only changed data)
- ✅ Permission system (edit/view)
- ✅ Version history (time travel)
- ✅ Conflict resolution (OT/CRDT)
- ✅ Better performance (batching)

---

## 🔧 Phase 1: Page Management System (Week 1)

### **1.1 Database Schema Changes**

```sql
-- Pages table (replaces canvases)
CREATE TABLE pages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  page_data JSONB NOT NULL DEFAULT '{"widgets": [], "metadata": {}}',
  version INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP NULL,
  
  INDEX idx_pages_owner (owner_id),
  INDEX idx_pages_updated (updated_at DESC)
);

-- Page permissions (sharing)
CREATE TABLE page_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id UUID NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  permission_type VARCHAR(20) NOT NULL CHECK (permission_type IN ('owner', 'edit', 'view', 'comment')),
  granted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  granted_by UUID NOT NULL REFERENCES users(id),
  
  UNIQUE (page_id, user_id),
  INDEX idx_permissions_user (user_id),
  INDEX idx_permissions_page (page_id)
);

-- Page versions (history)
CREATE TABLE page_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id UUID NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
  version INTEGER NOT NULL,
  page_data JSONB NOT NULL,
  operations JSONB NULL, -- JSON Patch operations that created this version
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  description TEXT NULL,
  
  UNIQUE (page_id, version),
  INDEX idx_versions_page (page_id, version DESC)
);

-- Active editors (real-time tracking)
CREATE TABLE active_editors (
  page_id UUID NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  cursor_position JSONB NULL DEFAULT '{}',
  selected_widget_id VARCHAR(255) NULL,
  last_active TIMESTAMP NOT NULL DEFAULT NOW(),
  
  PRIMARY KEY (page_id, user_id),
  INDEX idx_active_last_active (last_active)
);

-- Clean up inactive editors (run periodically)
-- DELETE FROM active_editors WHERE last_active < NOW() - INTERVAL '5 minutes';
```

---

### **1.2 Page JSON Structure**

```json
{
  "pageId": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Landing Page Design",
  "version": 12,
  "metadata": {
    "width": 1920,
    "height": 1080,
    "backgroundColor": "#FFFFFF",
    "gridSize": 10,
    "showGrid": true,
    "snapToGrid": false,
    "zoom": 1.0,
    "createdAt": "2025-01-15T10:00:00Z",
    "updatedAt": "2025-01-15T14:30:00Z",
    "createdBy": {
      "userId": "user-123",
      "name": "Sankar"
    }
  },
  "widgets": [
    {
      "id": "widget-1",
      "type": "Container",
      "position": {
        "x": 100,
        "y": 50
      },
      "size": {
        "width": 200,
        "height": 150
      },
      "properties": {
        "backgroundColor": "#FF5733",
        "borderRadius": 8,
        "opacity": 1.0,
        "rotation": 0,
        "zIndex": 1,
        "shadow": {
          "enabled": true,
          "blur": 4,
          "color": "#00000033"
        }
      },
      "createdAt": "2025-01-15T10:15:00Z",
      "createdBy": "user-123",
      "updatedAt": "2025-01-15T14:25:00Z",
      "updatedBy": "user-456"
    },
    {
      "id": "widget-2",
      "type": "Text",
      "position": {
        "x": 120,
        "y": 80
      },
      "size": {
        "width": 160,
        "height": 40
      },
      "properties": {
        "text": "Hello World",
        "fontSize": 24,
        "fontWeight": "bold",
        "color": "#000000",
        "textAlign": "center",
        "zIndex": 2
      },
      "createdAt": "2025-01-15T10:20:00Z",
      "createdBy": "user-456"
    }
  ]
}
```

---

### **1.3 Backend API Endpoints**

```typescript
// Page Management
POST   /api/pages                    // Create new page
GET    /api/pages                    // List user's pages (owned + shared)
GET    /api/pages/:id                // Get specific page (full JSON)
PATCH  /api/pages/:id                // Update page (incremental sync)
DELETE /api/pages/:id                // Delete page
PUT    /api/pages/:id/name           // Rename page

// Page Sharing
POST   /api/pages/:id/share          // Share page with user
GET    /api/pages/:id/permissions    // Get all permissions
PATCH  /api/pages/:id/permissions/:userId  // Update user permission
DELETE /api/pages/:id/permissions/:userId  // Revoke access
POST   /api/pages/:id/share-link     // Generate shareable link

// Version History
GET    /api/pages/:id/versions       // Get version history
GET    /api/pages/:id/versions/:version  // Get specific version
POST   /api/pages/:id/restore/:version   // Restore to version

// Active Editors
GET    /api/pages/:id/editors        // Get active editors

// Templates (bonus)
POST   /api/pages/:id/template       // Save page as template
GET    /api/templates                // List templates
POST   /api/templates/:id/create     // Create page from template
```

---

### **1.4 Frontend Changes**

#### **Update Navigation**
```dart
// Replace
'/canvas/:id' → '/page/:id'

// Update UI text
'Canvas' → 'Page'
'Create Canvas' → 'Create Page'
'My Canvases' → 'My Pages'
```

#### **State Management**
```dart
// OLD: Multiple widgets in state
class CanvasState {
  List<CanvasWidget> widgets;
  String? currentCanvasId;
}

// NEW: Single page document
class PageState {
  PageDocument? currentPage;  // Contains full JSON
  int version;
  List<Operation> pendingOperations;
  SyncStatus syncStatus;
}

class PageDocument {
  String pageId;
  String name;
  int version;
  PageMetadata metadata;
  List<Widget> widgets;
}
```

---

## ⚡ Phase 2: Incremental Sync System (Week 2)

### **2.1 JSON Patch Operations**

**Standard:** [RFC 6902](https://datatracker.ietf.org/doc/html/rfc6902)

```json
// Add widget
{
  "op": "add",
  "path": "/widgets/-",
  "value": {
    "id": "widget-3",
    "type": "Button",
    "position": { "x": 300, "y": 200 },
    "size": { "width": 100, "height": 40 }
  }
}

// Update widget position
{
  "op": "replace",
  "path": "/widgets/0/position/x",
  "value": 150
}

// Update widget property
{
  "op": "replace",
  "path": "/widgets/0/properties/backgroundColor",
  "value": "#FF5733"
}

// Remove widget
{
  "op": "remove",
  "path": "/widgets/1"
}

// Batch operations
[
  { "op": "replace", "path": "/widgets/0/position/x", "value": 150 },
  { "op": "replace", "path": "/widgets/0/position/y", "value": 250 },
  { "op": "replace", "path": "/widgets/0/size/width", "value": 200 }
]
```

---

### **2.2 WebSocket Events**

```typescript
// Client → Server Events
interface ClientEvents {
  'page:join': { pageId: string };
  'page:leave': { pageId: string };
  'page:sync': {
    pageId: string;
    version: number;
    operations: Operation[];
    timestamp: number;
  };
  'cursor:move': {
    pageId: string;
    position: { x: number; y: number };
  };
  'widget:select': {
    pageId: string;
    widgetId: string | null;
  };
  'widget:lock': {
    pageId: string;
    widgetId: string;
  };
  'widget:unlock': {
    pageId: string;
    widgetId: string;
  };
}

// Server → Client Events
interface ServerEvents {
  'page:joined': {
    page: PageDocument;
    activeUsers: ActiveUser[];
  };
  'page:update': {
    operations: Operation[];
    version: number;
    userId: string;
    userName: string;
    timestamp: number;
  };
  'page:conflict': {
    conflictingOperations: Operation[];
    serverVersion: number;
  };
  'user:joined': {
    user: ActiveUser;
  };
  'user:left': {
    userId: string;
  };
  'cursor:updated': {
    userId: string;
    userName: string;
    position: { x: number; y: number };
  };
  'widget:locked': {
    widgetId: string;
    userId: string;
    userName: string;
  };
  'widget:unlocked': {
    widgetId: string;
  };
}
```

---

### **2.3 Sync Service Implementation**

```typescript
// Client-side Sync Service
class PageSyncService {
  private localPage: PageDocument;
  private pendingOps: Operation[] = [];
  private syncing = false;
  private debounceTimer?: Timer;
  
  // Apply local change (optimistic)
  applyChange(operation: Operation): void {
    // 1. Apply to local state immediately
    this.localPage = applyOperation(this.localPage, operation);
    
    // 2. Queue operation
    this.pendingOps.push(operation);
    
    // 3. Update UI
    this.notifyStateChange();
    
    // 4. Debounce sync (500ms)
    this.scheduleSync();
  }
  
  // Debounced sync
  private scheduleSync(): void {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }
    
    this.debounceTimer = setTimeout(() => {
      this.sync();
    }, 500);
  }
  
  // Sync with server
  async sync(): Promise<void> {
    if (this.syncing || this.pendingOps.length === 0) {
      return;
    }
    
    this.syncing = true;
    this.updateSyncStatus('syncing');
    
    const operationsToSync = [...this.pendingOps];
    this.pendingOps = [];
    
    try {
      const response = await this.ws.emit('page:sync', {
        pageId: this.localPage.pageId,
        version: this.localPage.version,
        operations: operationsToSync,
        timestamp: Date.now(),
      });
      
      // Success - update version
      this.localPage.version = response.newVersion;
      this.updateSyncStatus('saved');
      
      // Apply any remote changes
      if (response.remoteOperations) {
        this.applyRemoteOperations(response.remoteOperations);
      }
      
    } catch (error) {
      // Error - re-queue operations and retry
      this.pendingOps.unshift(...operationsToSync);
      this.updateSyncStatus('error');
      this.retrySync();
    } finally {
      this.syncing = false;
    }
  }
  
  // Apply remote changes
  applyRemoteOperations(operations: Operation[]): void {
    for (const op of operations) {
      this.localPage = applyOperation(this.localPage, op);
    }
    this.notifyStateChange();
  }
  
  // Retry with exponential backoff
  private retrySync(): void {
    const delays = [1000, 2000, 4000, 8000]; // 1s, 2s, 4s, 8s
    let attempt = 0;
    
    const retry = () => {
      if (attempt >= delays.length) {
        this.updateSyncStatus('offline');
        return;
      }
      
      setTimeout(async () => {
        try {
          await this.sync();
        } catch {
          attempt++;
          retry();
        }
      }, delays[attempt]);
    };
    
    retry();
  }
}
```

---

### **2.4 Conflict Resolution**

```typescript
// Server-side Conflict Resolution
async function syncPage(req: SyncRequest): Promise<SyncResponse> {
  const { pageId, version, operations } = req;
  
  // 1. Get current page from database
  const currentPage = await db.getPage(pageId);
  
  // 2. Check version
  if (currentPage.version !== version) {
    // CONFLICT: Client is behind server
    
    // Get operations since client's version
    const missedOps = await db.getOperationsSince(pageId, version);
    
    // Try operational transform
    const merged = operationalTransform(operations, missedOps);
    
    if (merged.hasConflicts) {
      // Cannot auto-resolve - send conflict to client
      return {
        success: false,
        error: 'CONFLICT',
        conflicts: merged.conflicts,
        remoteOperations: missedOps,
        serverVersion: currentPage.version,
      };
    }
    
    // Auto-resolved - use transformed operations
    operations = merged.transformedOps;
  }
  
  // 3. Apply operations
  const updatedPage = applyOperations(currentPage, operations);
  updatedPage.version++;
  updatedPage.updatedAt = new Date();
  
  // 4. Save to database
  await db.updatePage(updatedPage);
  
  // 5. Save to version history
  await db.saveVersion({
    pageId,
    version: updatedPage.version,
    operations,
    createdBy: req.userId,
  });
  
  // 6. Broadcast to other users
  io.to(pageId).except(req.socketId).emit('page:update', {
    operations,
    version: updatedPage.version,
    userId: req.userId,
    userName: req.userName,
    timestamp: Date.now(),
  });
  
  // 7. Return success
  return {
    success: true,
    newVersion: updatedPage.version,
  };
}

// Operational Transform (simplified)
function operationalTransform(
  clientOps: Operation[],
  serverOps: Operation[]
): TransformResult {
  // This is simplified - real OT is more complex
  const transformed: Operation[] = [];
  const conflicts: Conflict[] = [];
  
  for (const clientOp of clientOps) {
    let op = { ...clientOp };
    
    for (const serverOp of serverOps) {
      // Transform client operation against server operation
      const result = transform(op, serverOp);
      
      if (result.conflict) {
        conflicts.push({
          clientOp,
          serverOp,
          reason: result.reason,
        });
      } else {
        op = result.transformed;
      }
    }
    
    transformed.push(op);
  }
  
  return {
    transformedOps: transformed,
    hasConflicts: conflicts.length > 0,
    conflicts,
  };
}
```

---

## 🔐 Phase 3: Permission System (Week 3)

### **3.1 Permission Levels**

```typescript
enum PermissionType {
  OWNER = 'owner',      // Full control (can delete, transfer ownership)
  EDIT = 'edit',        // Can edit page and share with others
  COMMENT = 'comment',  // Can add comments, view page
  VIEW = 'view',        // Read-only access
}

interface Permission {
  pageId: string;
  userId: string;
  type: PermissionType;
  grantedAt: Date;
  grantedBy: string;
}
```

### **3.2 Permission Matrix**

| Action | Owner | Edit | Comment | View |
|--------|-------|------|---------|------|
| View page | ✅ | ✅ | ✅ | ✅ |
| Add widgets | ✅ | ✅ | ❌ | ❌ |
| Edit widgets | ✅ | ✅ | ❌ | ❌ |
| Delete widgets | ✅ | ✅ | ❌ | ❌ |
| Add comments | ✅ | ✅ | ✅ | ❌ |
| Share page | ✅ | ✅ | ❌ | ❌ |
| Change permissions | ✅ | ❌ | ❌ | ❌ |
| Delete page | ✅ | ❌ | ❌ | ❌ |
| Transfer ownership | ✅ | ❌ | ❌ | ❌ |
| View history | ✅ | ✅ | ✅ | ✅ |
| Restore version | ✅ | ✅ | ❌ | ❌ |

---

### **3.3 Backend Middleware**

```typescript
// Permission check middleware
async function checkPagePermission(
  req: Request,
  res: Response,
  next: NextFunction
) {
  const { pageId } = req.params;
  const userId = req.user.id;
  
  try {
    // Get permission
    const permission = await db.getPermission(pageId, userId);
    
    if (!permission) {
      return res.status(403).json({
        error: 'ACCESS_DENIED',
        message: 'You do not have access to this page',
      });
    }
    
    // Attach to request
    req.permission = permission;
    next();
    
  } catch (error) {
    return res.status(500).json({ error: 'Permission check failed' });
  }
}

// Require specific permission level
function requirePermission(minLevel: PermissionType) {
  return (req: Request, res: Response, next: NextFunction) => {
    const userPermission = req.permission?.type;
    
    const levels = {
      [PermissionType.VIEW]: 1,
      [PermissionType.COMMENT]: 2,
      [PermissionType.EDIT]: 3,
      [PermissionType.OWNER]: 4,
    };
    
    if (levels[userPermission] < levels[minLevel]) {
      return res.status(403).json({
        error: 'INSUFFICIENT_PERMISSION',
        message: `This action requires ${minLevel} permission`,
        yourPermission: userPermission,
      });
    }
    
    next();
  };
}

// Usage
router.patch(
  '/pages/:id',
  authenticate,
  checkPagePermission,
  requirePermission(PermissionType.EDIT),
  syncPageHandler
);
```

---

### **3.4 Share Page UI**

```dart
// Share Dialog Widget
class SharePageDialog extends StatefulWidget {
  final String pageId;
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text('Share Page', style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 24),
            
            // Email input
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email address',
                hintText: 'user@example.com',
              ),
            ),
            SizedBox(height: 16),
            
            // Permission dropdown
            DropdownButton<PermissionType>(
              value: _selectedPermission,
              items: [
                DropdownMenuItem(
                  value: PermissionType.EDIT,
                  child: Text('Can edit'),
                ),
                DropdownMenuItem(
                  value: PermissionType.COMMENT,
                  child: Text('Can comment'),
                ),
                DropdownMenuItem(
                  value: PermissionType.VIEW,
                  child: Text('Can view'),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedPermission = value!);
              },
            ),
            SizedBox(height: 16),
            
            // Send button
            ElevatedButton(
              onPressed: _shareWithUser,
              child: Text('Send Invitation'),
            ),
            SizedBox(height: 32),
            
            // Current collaborators
            Text('Current Collaborators'),
            SizedBox(height: 16),
            _buildCollaboratorsList(),
            
            // Shareable link
            SizedBox(height: 32),
            _buildShareableLink(),
          ],
        ),
      ),
    );
  }
  
  Future<void> _shareWithUser() async {
    final email = _emailController.text.trim();
    
    try {
      await pageService.sharePage(
        pageId: pageId,
        email: email,
        permission: _selectedPermission,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitation sent to $email')),
      );
      
      _emailController.clear();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: $e')),
      );
    }
  }
}
```

---

## 🔄 Phase 4: Real-Time Collaboration (Week 4)

### **4.1 Live Presence**

```typescript
// Track active users
interface ActiveUser {
  userId: string;
  userName: string;
  avatarUrl?: string;
  permission: PermissionType;
  cursor?: { x: number; y: number };
  selectedWidget?: string;
  lastActive: Date;
  color: string; // Consistent color for this user
}

// Server-side presence tracking
class PresenceManager {
  private activeUsers = new Map<string, Map<string, ActiveUser>>();
  
  // User joins page
  userJoined(pageId: string, user: ActiveUser): void {
    if (!this.activeUsers.has(pageId)) {
      this.activeUsers.set(pageId, new Map());
    }
    
    this.activeUsers.get(pageId)!.set(user.userId, user);
    
    // Broadcast to room
    io.to(pageId).emit('user:joined', { user });
  }
  
  // User leaves page
  userLeft(pageId: string, userId: string): void {
    const pageUsers = this.activeUsers.get(pageId);
    if (pageUsers) {
      pageUsers.delete(userId);
      io.to(pageId).emit('user:left', { userId });
    }
  }
  
  // Update cursor position
  updateCursor(pageId: string, userId: string, position: Point): void {
    const user = this.activeUsers.get(pageId)?.get(userId);
    if (user) {
      user.cursor = position;
      user.lastActive = new Date();
      
      io.to(pageId).except(userId).emit('cursor:updated', {
        userId,
        userName: user.userName,
        position,
      });
    }
  }
  
  // Clean up inactive users (run every minute)
  cleanupInactive(): void {
    const timeout = 5 * 60 * 1000; // 5 minutes
    const now = new Date();
    
    for (const [pageId, users] of this.activeUsers) {
      for (const [userId, user] of users) {
        if (now.getTime() - user.lastActive.getTime() > timeout) {
          this.userLeft(pageId, userId);
        }
      }
    }
  }
}
```

---

### **4.2 Widget Locking**

```typescript
// Lock manager
class WidgetLockManager {
  private locks = new Map<string, WidgetLock>(); // widgetId → lock
  
  // Try to acquire lock
  acquireLock(
    pageId: string,
    widgetId: string,
    userId: string,
    userName: string
  ): boolean {
    const lockKey = `${pageId}:${widgetId}`;
    const existingLock = this.locks.get(lockKey);
    
    // Check if already locked by someone else
    if (existingLock && existingLock.userId !== userId) {
      const age = Date.now() - existingLock.timestamp;
      
      // Auto-release after 30 seconds
      if (age < 30000) {
        return false; // Still locked
      }
    }
    
    // Acquire lock
    this.locks.set(lockKey, {
      pageId,
      widgetId,
      userId,
      userName,
      timestamp: Date.now(),
    });
    
    // Broadcast lock
    io.to(pageId).emit('widget:locked', {
      widgetId,
      userId,
      userName,
    });
    
    return true;
  }
  
  // Release lock
  releaseLock(pageId: string, widgetId: string, userId: string): void {
    const lockKey = `${pageId}:${widgetId}`;
    const lock = this.locks.get(lockKey);
    
    if (lock && lock.userId === userId) {
      this.locks.delete(lockKey);
      
      // Broadcast unlock
      io.to(pageId).emit('widget:unlocked', { widgetId });
    }
  }
}
```

---

### **4.3 Frontend Real-Time UI**

```dart
// Render remote cursors
Widget _buildRemoteCursors(List<ActiveUser> users) {
  return Stack(
    children: users
      .where((u) => u.userId != currentUserId && u.cursor != null)
      .map((user) {
        return Positioned(
          left: user.cursor!.x,
          top: user.cursor!.y,
          child: _buildCursor(user),
        );
      })
      .toList(),
  );
}

Widget _buildCursor(ActiveUser user) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.navigation,
        color: user.color,
        size: 20,
      ),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: user.color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          user.userName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      ),
    ],
  );
}

// Show widget lock indicator
Widget _buildWidget(Widget widget) {
  final isLocked = lockedWidgets.contains(widget.id);
  final lockedBy = isLocked ? getLockedBy(widget.id) : null;
  
  return Stack(
    children: [
      // Widget content
      WidgetRenderer(widget: widget),
      
      // Lock overlay
      if (isLocked)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: lockedBy!.color,
                width: 2,
              ),
              color: Colors.black12,
            ),
            child: Center(
              child: Chip(
                avatar: Icon(Icons.lock, size: 16),
                label: Text('Editing by ${lockedBy.userName}'),
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ),
    ],
  );
}
```

---

## ✨ Phase 5: Advanced Features (Week 5)

### **5.1 Version History**

```typescript
// Save version periodically or on major changes
async function autoSaveVersion(pageId: string): Promise<void> {
  const page = await db.getPage(pageId);
  const lastVersion = await db.getLastVersion(pageId);
  
  // Save if 5 minutes passed or 10+ operations
  const timeSinceLastSave = Date.now() - lastVersion.createdAt.getTime();
  const shouldSave = 
    timeSinceLastSave > 5 * 60 * 1000 || 
    page.version - lastVersion.version > 10;
  
  if (shouldSave) {
    await db.saveVersion({
      pageId,
      version: page.version,
      pageData: page.pageData,
      description: 'Auto-save',
    });
  }
}

// Restore to version
async function restoreVersion(
  pageId: string,
  targetVersion: number,
  userId: string
): Promise<void> {
  // Get target version data
  const versionData = await db.getVersion(pageId, targetVersion);
  
  // Get current page
  const currentPage = await db.getPage(pageId);
  
  // Save current as new version
  await db.saveVersion({
    pageId,
    version: currentPage.version,
    pageData: currentPage.pageData,
    description: `Before restore to v${targetVersion}`,
  });
  
  // Replace current with target version
  await db.updatePage({
    ...currentPage,
    pageData: versionData.pageData,
    version: currentPage.version + 1,
  });
  
  // Broadcast to all users
  io.to(pageId).emit('page:restored', {
    version: targetVersion,
    restoredBy: userId,
  });
}
```

---

### **5.2 Comments System**

```sql
-- Comments table
CREATE TABLE page_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id UUID NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
  widget_id VARCHAR(255) NULL, -- Null = page-level comment
  user_id UUID NOT NULL REFERENCES users(id),
  comment_text TEXT NOT NULL,
  position JSONB NULL, -- { x, y } for positioned comments
  parent_id UUID NULL REFERENCES page_comments(id), -- For threaded replies
  resolved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  INDEX idx_comments_page (page_id),
  INDEX idx_comments_widget (widget_id)
);
```

---

### **5.3 Page Templates**

```typescript
// Save as template
async function saveAsTemplate(
  pageId: string,
  userId: string,
  templateData: {
    name: string;
    description: string;
    isPublic: boolean;
  }
): Promise<Template> {
  const page = await db.getPage(pageId);
  
  const template = await db.createTemplate({
    name: templateData.name,
    description: templateData.description,
    pageData: page.pageData,
    createdBy: userId,
    isPublic: templateData.isPublic,
  });
  
  return template;
}

// Create page from template
async function createFromTemplate(
  templateId: string,
  userId: string,
  pageName: string
): Promise<Page> {
  const template = await db.getTemplate(templateId);
  
  const page = await db.createPage({
    name: pageName,
    ownerId: userId,
    pageData: template.pageData, // Copy template data
  });
  
  return page;
}
```

---

## 🔄 Migration Plan: Current → New

### **Step 1: Database Migration**

```sql
-- Create new tables
CREATE TABLE pages (...);
CREATE TABLE page_permissions (...);
CREATE TABLE page_versions (...);
CREATE TABLE active_editors (...);

-- Migrate canvases to pages
INSERT INTO pages (id, name, owner_id, page_data, created_at, updated_at)
SELECT 
  c.id,
  c.name,
  c.user_id,
  jsonb_build_object(
    'pageId', c.id,
    'name', c.name,
    'version', 1,
    'metadata', jsonb_build_object(
      'backgroundColor', c.background_color,
      'width', 1920,
      'height', 1080
    ),
    'widgets', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'id', w.id,
          'type', w.type,
          'position', w.position,
          'size', w.size,
          'properties', w.properties,
          'createdAt', w.created_at
        )
      ), '[]'::jsonb)
      FROM widgets w
      WHERE w.canvas_id = c.id
    )
  ),
  c.created_at,
  c.updated_at
FROM canvases c;

-- Grant owner permissions
INSERT INTO page_permissions (page_id, user_id, permission_type, granted_at, granted_by)
SELECT id, owner_id, 'owner', NOW(), owner_id
FROM pages;

-- Keep old tables for rollback
-- DROP TABLE widgets;  -- Don't drop yet
-- DROP TABLE canvases; -- Don't drop yet
```

---

### **Step 2: Dual API Support**

```typescript
// Support both old and new APIs during transition
app.use('/api/v1', oldRoutes); // Legacy canvas-based
app.use('/api/v2', newRoutes); // New page-based

// Add deprecation headers
app.use('/api/v1/*', (req, res, next) => {
  res.setHeader('X-API-Deprecated', 'true');
  res.setHeader('X-API-Sunset', '2025-03-01');
  next();
});
```

---

### **Step 3: Frontend Feature Flag**

```dart
// Feature flag
class FeatureFlags {
  static const bool USE_NEW_PAGE_SYSTEM = true; // Toggle here
}

// Conditional routing
void setupRoutes() {
  if (FeatureFlags.USE_NEW_PAGE_SYSTEM) {
    router.define('/page/:id', handler: NewPageEditorScreen);
  } else {
    router.define('/canvas/:id', handler: OldCanvasEditorScreen);
  }
}
```

---

### **Step 4: Gradual Rollout**

```
Week 1: Deploy new backend (dual API support)
Week 2: Deploy frontend with feature flag OFF
Week 3: Enable for 10% of users
Week 4: Enable for 50% of users
Week 5: Enable for 100% of users
Week 6: Remove old API, clean up old tables
```

---

## 🎯 Suggested Implementation Order

### **Priority 1: Foundation** (2 weeks)

1. ✅ Create database schema (pages, permissions)
2. ✅ Implement basic CRUD APIs for pages
3. ✅ Update frontend to use page concept
4. ✅ Migrate existing data
5. ✅ Basic permission checks

### **Priority 2: Sync System** (2 weeks)

6. ✅ Implement JSON Patch operations
7. ✅ Add WebSocket events
8. ✅ Build sync service (client-side)
9. ✅ Implement conflict detection
10. ✅ Add optimistic updates

### **Priority 3: Collaboration** (1-2 weeks)

11. ✅ Live presence system
12. ✅ Cursor tracking
13. ✅ Widget locking
14. ✅ Permission-based UI

### **Priority 4: Polish** (1 week)

15. ✅ Version history
16. ✅ Auto-save with status
17. ✅ Error handling & retry
18. ✅ Performance optimization

---

## 📊 Success Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Sync Latency | < 200ms | Track WebSocket round-trip |
| Save Success Rate | > 99% | Monitor sync failures |
| Conflict Rate | < 1% | Track auto-resolve vs manual |
| Simultaneous Users | 10+ per page | Load testing |
| Operation Throughput | 100+ ops/sec | Stress testing |

---

## 🚨 Risk Mitigation

### **Risk 1: Data Loss During Migration**
- **Solution:** Keep old tables, run dual systems in parallel
- **Rollback:** Switch feature flag, revert to old API

### **Risk 2: Sync Conflicts**
- **Solution:** Implement OT, save all versions
- **Fallback:** Manual conflict resolution UI

### **Risk 3: Performance Issues**
- **Solution:** Database indexes, operation batching
- **Monitor:** Add performance metrics, alerts

---

**End of New Architecture Plan**
