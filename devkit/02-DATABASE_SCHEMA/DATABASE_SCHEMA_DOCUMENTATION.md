# SyncEditor Database Schema Documentation

## 📚 Table of Contents
1. [Project Overview](#project-overview)
2. [Database Architecture](#database-architecture)
3. [Tables Details](#tables-details)
4. [Relationships](#relationships)
5. [Key Features](#key-features)

---

## 🎯 Project Overview

**SyncEditor** is a **real-time collaborative page/canvas editor** similar to Figma, Google Docs, or Miro. Multiple users can simultaneously edit pages with widgets (UI components), with changes synchronized in real-time using WebSocket connections and Operational Transformation (OT).

### Core Functionality:
- ✅ Multi-user real-time collaboration
- ✅ Undo/Redo with per-user stacks
- ✅ Version control and history tracking
- ✅ Comments and @mentions
- ✅ Permission-based access control
- ✅ Real-time presence indicators
- ✅ Incremental sync using JSON Patches

---

## 🏗️ Database Architecture

The database uses **PostgreSQL** with the following design principles:

1. **Document-Centric**: Pages store entire widget trees as JSONB for efficient read/write
2. **Event Sourcing**: Operation history tracks all changes for undo/redo
3. **Optimistic Locking**: Version numbers prevent concurrent update conflicts
4. **Soft Deletes**: Critical data (pages, comments) uses soft deletes for recovery
5. **Indexing Strategy**: GIN indexes for JSONB queries, B-tree for relational queries

---

## 📋 Tables Details

### 1. 👤 **users** Table
**Purpose**: Store user accounts and authentication information

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key, unique user identifier |
| email | VARCHAR(255) | User's email (unique, used for login) |
| password_hash | VARCHAR(255) | Bcrypt hashed password (never store plain text) |
| name | VARCHAR(255) | User's display name |
| avatar_url | TEXT | URL to user's profile picture (optional) |
| created_at | TIMESTAMP | Account creation timestamp |
| updated_at | TIMESTAMP | Last update timestamp (auto-updated) |

**Why This Table?**
- Central authentication system for all users
- Enables login/logout functionality
- Referenced by all other tables for ownership and authorship

**Indexes**:
- `idx_users_email` - Fast email lookup for login

---

### 2. 📄 **pages** Table
**Purpose**: Main collaborative documents (like Figma files or Google Docs)

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key, unique page identifier |
| name | VARCHAR(255) | Page display name |
| owner_id | UUID | Reference to user who owns this page |
| page_data | JSONB | Complete page content (widgets, metadata, settings) |
| version | INTEGER | Incremental version number for conflict detection |
| created_at | TIMESTAMP | Page creation timestamp |
| updated_at | TIMESTAMP | Last modification timestamp |
| deleted_at | TIMESTAMP | Soft delete timestamp (NULL = active) |

**page_data Structure Example**:
```json
{
  "pageId": "uuid",
  "name": "Landing Page Design",
  "version": 42,
  "metadata": {
    "width": 1920,
    "height": 1080,
    "backgroundColor": "#FFFFFF",
    "gridSize": 10
  },
  "widgets": [
    {
      "id": "widget-1",
      "type": "Container",
      "position": { "x": 100, "y": 50 },
      "size": { "width": 200, "height": 150 },
      "properties": { 
        "backgroundColor": "#FF5733",
        "borderRadius": 8
      },
      "children": []
    }
  ]
}
```

**Why This Table?**
- Central document storage for the entire application
- Single JSONB document enables atomic updates and fast reads
- Version field prevents lost updates in concurrent editing
- Soft deletes allow "Trash" functionality

**Indexes**:
- `idx_pages_owner` - Find all pages owned by a user
- `idx_pages_updated` - Sort pages by recent activity
- `idx_pages_data_gin` - Fast JSONB queries (e.g., find widgets by type)
- `idx_pages_deleted` - Filter active pages

---

### 3. 🔐 **page_permissions** Table
**Purpose**: Control who can access and edit pages (sharing system)

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| page_id | UUID | Reference to shared page |
| user_id | UUID | User being granted access |
| permission_type | ENUM | Level: 'owner', 'edit', 'comment', 'view' |
| granted_at | TIMESTAMP | When permission was granted |
| granted_by | UUID | User who shared the page |
| updated_at | TIMESTAMP | Last update timestamp |

**Permission Hierarchy**:
```
owner > edit > comment > view
(Full)  (Edit) (Comment) (Read-only)
```

**Why This Table?**
- Enables collaborative sharing like Google Docs
- Fine-grained access control (view-only, commenting, editing)
- Audit trail (who granted access and when)

**Indexes**:
- `idx_permissions_page` - List all users with access to a page
- `idx_permissions_user` - List all pages a user can access

---

### 4. 📦 **operation_history** Table
**Purpose**: Track ALL changes to pages for undo/redo and audit trail

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| page_id | UUID | Page being modified |
| user_id | UUID | User who made the change |
| operation | JSONB | Forward operation (JSON Patch - what was done) |
| inverse_operation | JSONB | Reverse operation (for undo) |
| from_version | INTEGER | Page version before change |
| to_version | INTEGER | Page version after change |
| parent_operations | UUID[] | Operations this depends on (for OT) |
| operation_type | VARCHAR(50) | Type: 'add', 'remove', 'replace', 'move', 'copy' |
| affected_paths | TEXT[] | JSON paths modified |
| created_at | TIMESTAMP | When operation occurred |

**Example Operations (JSON Patch RFC 6902)**:
```json
// Forward operation (what was done)
[
  { "op": "add", "path": "/widgets/-", "value": {...} },
  { "op": "replace", "path": "/widgets/0/position/x", "value": 150 }
]

// Inverse operation (for undo)
[
  { "op": "replace", "path": "/widgets/0/position/x", "value": 100 },
  { "op": "remove", "path": "/widgets/3" }
]
```

**Why This Table?**
- **Undo/Redo**: Store inverse operations to reverse changes
- **Operational Transformation (OT)**: Resolve concurrent edits
- **Audit Trail**: Complete history of who changed what and when
- **Conflict Resolution**: Detect and merge conflicting operations

**Indexes**:
- `idx_operation_history_page_user` - User's operations on a page
- `idx_operation_history_version` - Find operations by version
- `idx_operation_history_parents` - OT dependency tracking

---

### 5. ↩️ **user_undo_stacks** Table
**Purpose**: Per-user undo/redo stacks for each page

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| page_id | UUID | Page reference |
| user_id | UUID | User reference |
| undo_stack | UUID[] | Stack of operation IDs that can be undone |
| redo_stack | UUID[] | Stack of operation IDs that can be redone |
| max_stack_size | INTEGER | Max operations to keep (default 100) |
| updated_at | TIMESTAMP | Last modification |

**Why This Table?**
- **Individual Undo/Redo**: Each user has their own undo stack
- **Performance**: Quick access to undoable operations
- **Memory Management**: Limit stack size to prevent unbounded growth

**How It Works**:
```
User makes change → Add to undo_stack
User clicks Undo → Pop from undo_stack, push to redo_stack
User clicks Redo → Pop from redo_stack, push to undo_stack
User makes new change → Clear redo_stack
```

---

### 6. 📸 **page_versions** Table
**Purpose**: Snapshots of pages at specific versions (like Git commits)

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| page_id | UUID | Page reference |
| version | INTEGER | Version number |
| page_data | JSONB | Complete page snapshot at this version |
| operations | JSONB | Operations that created this version (optional) |
| description | TEXT | Human-readable change description |
| created_by | UUID | User who created this version |
| created_at | TIMESTAMP | Creation timestamp |

**Why This Table?**
- **Version Control**: Like Git history for pages
- **Restore Capability**: Revert to any previous version
- **Branching**: Future feature to create alternate versions
- **Comparison**: Diff between versions

**Use Cases**:
- "Restore to version 5"
- "Show me what changed in version 10"
- "Create a backup before major refactor"

---

### 7. 🔄 **page_patches** Table
**Purpose**: Incremental changes (JSON Patches) for efficient sync

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| page_id | UUID | Page reference |
| user_id | UUID | User who made changes |
| patches | JSONB | Array of JSON Patch operations |
| from_version | INTEGER | Starting version |
| to_version | INTEGER | Ending version |
| created_at | TIMESTAMP | Creation timestamp |

**Why This Table?**
- **Efficient Sync**: Send only changes, not entire page
- **Bandwidth Optimization**: Small patches vs. large documents
- **Real-time Updates**: WebSocket sends patches to other users
- **Replay**: Rebuild page state from patches

**Example**:
```json
{
  "from_version": 10,
  "to_version": 11,
  "patches": [
    { "op": "replace", "path": "/widgets/0/position/x", "value": 250 }
  ]
}
```

---

### 8. 👥 **active_editors** Table
**Purpose**: Real-time presence tracking (who's online and where)

| Column | Type | Description |
|--------|------|-------------|
| page_id | UUID | Page reference (composite PK) |
| user_id | UUID | User reference (composite PK) |
| cursor_position | JSONB | Current cursor coordinates { x, y } |
| selected_widget_id | VARCHAR(255) | Widget currently selected by user |
| last_active | TIMESTAMP | Last activity timestamp |

**Why This Table?**
- **Presence Indicators**: Show "User A is editing"
- **Cursor Tracking**: Display other users' cursors in real-time
- **Selection Awareness**: Show who's editing which widget
- **Auto-cleanup**: Remove inactive users after 5 minutes

**UI Display**:
```
🟢 John Doe (editing)
🟡 Jane Smith (viewing)
🔵 Bob Johnson (Widget #5)
```

---

### 9. 💬 **comments** Table
**Purpose**: Collaborative feedback with threaded discussions

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| page_id | UUID | Page reference |
| user_id | UUID | Comment author |
| content | TEXT | Comment text (max 5000 chars) |
| position_x | FLOAT | X coordinate for canvas annotation (optional) |
| position_y | FLOAT | Y coordinate for canvas annotation (optional) |
| widget_id | VARCHAR(255) | Widget-specific comment (optional) |
| parent_comment_id | UUID | Parent for threaded replies |
| resolved | BOOLEAN | Thread resolution status |
| resolved_by | UUID | User who resolved |
| resolved_at | TIMESTAMP | Resolution timestamp |
| edited | BOOLEAN | Whether comment was edited |
| edited_at | TIMESTAMP | Edit timestamp |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Update timestamp |
| deleted_at | TIMESTAMP | Soft delete |

**Comment Types**:
1. **General Comments**: No position or widget
2. **Canvas Annotations**: Has position_x, position_y
3. **Widget Comments**: Has widget_id
4. **Thread Replies**: Has parent_comment_id

**Why This Table?**
- **Collaboration**: Team feedback like Figma comments
- **Threading**: Reply to specific comments
- **Resolution**: Mark discussions as resolved
- **Pinned Annotations**: Comments on specific canvas locations

---

### 10. 🔔 **comment_mentions** Table
**Purpose**: @mention notifications in comments

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| comment_id | UUID | Comment containing mention |
| user_id | UUID | Mentioned user |
| read | BOOLEAN | Notification read status |
| read_at | TIMESTAMP | When notification was read |
| created_at | TIMESTAMP | Creation timestamp |

**Why This Table?**
- **Notifications**: Alert users when mentioned
- **Inbox**: Show unread mentions
- **Collaboration**: Direct attention to specific users

**Example**:
```
Comment: "@john can you review this button design?"
→ Creates mention for user 'john'
→ John sees notification "You were mentioned in Landing Page"
```

---

### 11. 😊 **comment_reactions** Table
**Purpose**: Emoji reactions to comments (like Slack reactions)

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| comment_id | UUID | Comment reference |
| user_id | UUID | User who reacted |
| reaction | VARCHAR(50) | Emoji (👍 ❤️ 🎉 etc.) |
| created_at | TIMESTAMP | Creation timestamp |

**Why This Table?**
- **Quick Feedback**: React without writing full comment
- **Engagement**: Show agreement/approval
- **Fun**: Add personality to collaboration

---

### 12. 🗂️ **canvases** Table (Legacy - Not Currently Used)
**Purpose**: Old canvas system before migration to pages

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| owner_id | UUID | Canvas owner |
| name | VARCHAR(255) | Canvas name |
| description | TEXT | Description |
| settings | JSONB | Canvas settings (background, grid, zoom) |
| is_public | BOOLEAN | Public visibility |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Update timestamp |

**Note**: This table is from the old architecture. The project migrated from:
- **Old**: Canvases → Widgets (separate tables)
- **New**: Pages (single JSONB document)

**Why Keep It?**
- Migration in progress
- Backward compatibility
- May be removed in future cleanup

---

### 13. 🎨 **widgets** Table (Legacy - Not Currently Used)
**Purpose**: Individual UI components on canvases (old system)

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| canvas_id | UUID | Parent canvas |
| type | VARCHAR(50) | Widget type (Button, Text, Container, etc.) |
| parent_id | UUID | Parent widget (for nesting) |
| position | JSONB | { x, y, z_index } |
| size | JSONB | { width, height, units } |
| properties | JSONB | Widget-specific properties |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Update timestamp |

**Note**: In the new architecture, widgets are stored inside `pages.page_data` JSONB field.

---

### 14. 📜 **widget_versions** Table (Legacy)
**Purpose**: Version history for individual widgets (old system)

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| widget_id | UUID | Widget reference |
| canvas_id | UUID | Canvas reference |
| operation | VARCHAR(20) | 'create', 'update', 'delete' |
| data | JSONB | Widget snapshot |
| created_by | UUID | User who made change |
| created_at | TIMESTAMP | Creation timestamp |

**Note**: Replaced by `operation_history` in new system.

---

### 15. 👥 **canvas_collaborators** Table (Legacy)
**Purpose**: Sharing system for old canvas architecture

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| canvas_id | UUID | Canvas reference |
| user_id | UUID | Collaborator |
| role | VARCHAR(20) | 'owner', 'editor', 'viewer' |
| created_at | TIMESTAMP | Creation timestamp |

**Note**: Replaced by `page_permissions` in new system.

---

## 🔗 Relationships

### Core Entity Relationships:

```
users (1) ──────┬──────── (N) pages (owns)
                │
                ├──────── (N) page_permissions (granted)
                │
                ├──────── (N) operation_history (performed)
                │
                ├──────── (N) user_undo_stacks (belongs to)
                │
                ├──────── (N) active_editors (editing)
                │
                └──────── (N) comments (authored)

pages (1) ──────┬──────── (N) operation_history
                │
                ├──────── (N) page_versions
                │
                ├──────── (N) page_patches
                │
                ├──────── (N) page_permissions
                │
                ├──────── (N) active_editors
                │
                └──────── (N) comments

comments (1) ───┬──────── (N) comments (replies - self-join)
                │
                ├──────── (N) comment_mentions
                │
                └──────── (N) comment_reactions
```

---

## 🎯 Key Features

### 1. Real-Time Collaboration
**Tables Involved**: `pages`, `operation_history`, `page_patches`, `active_editors`

**How It Works**:
1. User A edits widget → Creates `operation_history` entry
2. Server generates `page_patch`
3. WebSocket broadcasts patch to all connected users
4. User B receives patch → Applies to local state
5. `active_editors` shows User A is editing

---

### 2. Undo/Redo System
**Tables Involved**: `operation_history`, `user_undo_stacks`

**Flow**:
```
User makes change:
1. Create operation_history (forward + inverse)
2. Push operation ID to user_undo_stacks.undo_stack
3. Clear redo_stack

User clicks Undo:
1. Pop from undo_stack
2. Apply inverse_operation
3. Push to redo_stack

User clicks Redo:
1. Pop from redo_stack
2. Apply forward operation
3. Push to undo_stack
```

---

### 3. Version Control
**Tables Involved**: `pages`, `page_versions`, `operation_history`

**Capabilities**:
- **Snapshots**: Save `page_versions` at milestones
- **History**: View all `operation_history` entries
- **Restore**: Load `page_versions.page_data` to revert
- **Diff**: Compare versions by analyzing operations

---

### 4. Comments & Mentions
**Tables Involved**: `comments`, `comment_mentions`, `comment_reactions`

**Features**:
- **Threading**: `parent_comment_id` creates reply chains
- **Annotations**: `position_x/y` pins comments to canvas
- **Mentions**: `@username` creates `comment_mentions` entry
- **Resolution**: Mark discussions complete
- **Reactions**: Quick emoji feedback

---

### 5. Permissions System
**Tables Involved**: `page_permissions`

**Access Levels**:
- **Owner**: Full control (delete, share, settings)
- **Edit**: Modify content (add/remove widgets)
- **Comment**: Add comments only
- **View**: Read-only access

---

## 📊 Database Statistics

| Category | Count | Purpose |
|----------|-------|---------|
| **Active Tables** | 12 | Current production tables |
| **Legacy Tables** | 3 | Old architecture (canvases, widgets, etc.) |
| **Core Tables** | 4 | Users, pages, permissions, operations |
| **Collaboration** | 3 | Comments, mentions, reactions |
| **Version Control** | 3 | Versions, patches, undo stacks |
| **Real-Time** | 1 | Active editors presence |
| **Indexes** | 50+ | Performance optimization |
| **Views** | 2 | Aggregated statistics |

---

## 🚀 Performance Optimizations

### Indexing Strategy:
1. **B-tree Indexes**: Foreign keys, timestamps, version numbers
2. **GIN Indexes**: JSONB columns for fast JSON queries
3. **Partial Indexes**: Filter by `deleted_at IS NULL`
4. **Composite Indexes**: Multi-column queries (page_id + user_id)

### JSONB Benefits:
- **Flexibility**: Schema-less widget properties
- **Performance**: Faster than parsing JSON strings
- **Querying**: PostgreSQL operators (@>, ->, etc.)
- **Indexing**: GIN indexes enable fast searches

---

## 🔧 Maintenance Functions

### Cleanup Functions:
```sql
-- Remove inactive editors (>5 min)
SELECT cleanup_inactive_editors();

-- Delete old operation history (>30 days)
SELECT cleanup_old_operations(30);

-- Trim undo/redo stacks to max size
SELECT trim_undo_stacks();
```

---

## 📝 Summary

**SyncEditor Database** is designed for:
✅ **Real-time collaboration** - Multiple users editing simultaneously  
✅ **Version control** - Complete history and undo/redo  
✅ **Scalability** - JSONB documents for performance  
✅ **Conflict resolution** - Operational Transformation  
✅ **Team collaboration** - Comments, mentions, permissions  
✅ **Audit trail** - Track who changed what and when  

The architecture balances **performance** (JSONB documents), **consistency** (version numbers), and **flexibility** (JSON Patch operations) to create a robust collaborative editing platform.
