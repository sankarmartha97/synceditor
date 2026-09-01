# Phase 3: Advanced Collaborative Features

## 🎯 Overview

**Goal**: Enhance real-time collaboration with advanced features that make multi-user editing more powerful and intuitive.

**Status**: Planning → Implementation  
**Priority**: High  
**Estimated Time**: 15-20 hours

---

## 📋 Phase 3 Features

### Feature 3.1: Undo/Redo with OT Support ⭐
**Priority**: HIGH  
**Complexity**: HIGH  
**Time**: 6-8 hours

**What**: Implement undo/redo that works correctly in multi-user environments using OT

**Why**: Users need to undo mistakes without breaking other users' work

**Challenges**:
- Undo must transform against concurrent operations
- Redo must reapply operations correctly
- Multi-user undo is complex
- Operation history must be maintained

**Deliverables**:
- Operation history tracking
- Undo/redo service with OT
- Frontend undo/redo UI (Ctrl+Z, Ctrl+Y)
- Tests for undo/redo scenarios

---

### Feature 3.2: Presence Awareness (User Cursors) ⭐
**Priority**: HIGH  
**Complexity**: MEDIUM  
**Time**: 3-4 hours

**What**: Show where other users are editing in real-time with cursors/avatars

**Why**: Users need to see what others are doing to avoid conflicts

**Deliverables**:
- Real-time cursor position tracking
- Visual cursor indicators (colored dots/cursors)
- User avatar/name tooltips
- Cursor smoothing (interpolation)

---

### Feature 3.3: Comments & Annotations
**Priority**: MEDIUM  
**Complexity**: MEDIUM  
**Time**: 4-5 hours

**What**: Allow users to add comments on widgets or canvas areas

**Why**: Teams need to discuss changes without external tools

**Deliverables**:
- Comment data model
- Comment API endpoints
- Comment UI (thread view)
- Real-time comment sync
- Notifications for mentions

---

### Feature 3.4: Page Templates
**Priority**: MEDIUM  
**Complexity**: LOW  
**Time**: 2-3 hours

**What**: Pre-built page layouts users can start from

**Why**: Speed up page creation with common patterns

**Deliverables**:
- Template data structure
- Template library UI
- Create page from template
- Save page as template
- Template categories

---

## 🎯 Phase 3.1: Undo/Redo with OT (DETAILED PLAN)

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    UNDO/REDO ARCHITECTURE                    │
└─────────────────────────────────────────────────────────────┘

Backend:
├── Operation History Service
│   ├── Store all operations (user_id, patches, timestamp)
│   ├── Track operation dependencies
│   └── Provide history for transformation
│
├── Undo/Redo Service
│   ├── Generate inverse operations (undo)
│   ├── Transform undos against concurrent ops (OT)
│   ├── Maintain undo/redo stacks per user
│   └── Validate undo operations
│
└── Database
    └── operation_history table
        ├── id, page_id, user_id
        ├── operation (patches JSONB)
        ├── inverse_operation (patches JSONB)
        ├── version, parent_version
        └── created_at

Frontend:
├── Undo/Redo Manager
│   ├── Local undo/redo stacks
│   ├── Keyboard shortcuts (Ctrl+Z, Ctrl+Y)
│   ├── UI buttons (undo/redo)
│   └── Transform local operations
│
└── PageBloc Updates
    ├── Track operation history
    ├── Handle undo events
    ├── Handle redo events
    └── Sync with backend
```

### Undo/Redo Algorithm

#### Generate Inverse Operation (Undo):

```javascript
// Add → Remove
{op: 'add', path: '/widgets/0', value: widget}
→ {op: 'remove', path: '/widgets/0'}

// Remove → Add
{op: 'remove', path: '/widgets/0'}
→ {op: 'add', path: '/widgets/0', value: <original widget>}

// Replace → Replace
{op: 'replace', path: '/widgets/0/color', value: 'blue'}
→ {op: 'replace', path: '/widgets/0/color', value: 'red'} // original value
```

#### Transform Undo with OT:

```javascript
User A (v10): Add widget at index 0
User B (v10): Add widget at index 0 (concurrent)

Server applies A first → v11
Server applies B with OT → v12 (B's widget now at index 1)

User A wants to undo:
- Original: {op: 'remove', path: '/widgets/0'}
- Must transform against B's operation
- Transformed: Still {op: 'remove', path: '/widgets/0'}
  (A's widget still at 0, B's at 1)

User B wants to undo:
- Original: {op: 'remove', path: '/widgets/0'} (wanted to remove at 0)
- Must transform against A's operation
- Transformed: {op: 'remove', path: '/widgets/1'} (now at index 1)
```

### Database Schema

```sql
-- Operation history table
CREATE TABLE operation_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id UUID NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),
  
  -- Forward operation (what was done)
  operation JSONB NOT NULL,
  
  -- Inverse operation (for undo)
  inverse_operation JSONB NOT NULL,
  
  -- Version tracking
  from_version INT NOT NULL,
  to_version INT NOT NULL,
  
  -- Dependencies (for OT)
  parent_operations UUID[] DEFAULT '{}',
  
  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  
  INDEX idx_operation_history_page (page_id),
  INDEX idx_operation_history_user (user_id),
  INDEX idx_operation_history_version (page_id, to_version)
);
```

### Implementation Steps

#### Backend (6 steps):

1. **Create operation_history table migration** (30 min)
   - Write SQL migration
   - Add indexes
   - Test migration

2. **Build OperationHistoryService** (1 hour)
   - saveOperation(pageId, userId, operation, inverse)
   - getOperationsByUser(pageId, userId, limit)
   - getOperationsBetweenVersions(pageId, fromV, toV)

3. **Build UndoRedoService** (2 hours)
   - generateInverse(operation) → inverse operation
   - transformUndo(undoOp, concurrentOps) → transformed undo
   - validateUndo(undoOp, currentState) → can undo?

4. **Update page.handler.js** (1 hour)
   - Add page:undo event handler
   - Add page:redo event handler
   - Transform undos with OT
   - Broadcast undo/redo to other users

5. **Add WebSocket events** (30 min)
   - CLIENT_EVENTS.PAGE_UNDO
   - CLIENT_EVENTS.PAGE_REDO
   - SERVER_EVENTS.PAGE_UNDO_APPLIED
   - SERVER_EVENTS.PAGE_REDO_APPLIED

6. **Write tests** (2 hours)
   - Inverse generation tests (10 tests)
   - Undo transformation tests (15 tests)
   - Multi-user undo tests (10 tests)
   - Edge cases (5 tests)

#### Frontend (5 steps):

1. **Update PageBloc** (1.5 hours)
   - Add undo/redo stacks
   - Handle UndoRequested event
   - Handle RedoRequested event
   - Track operation history locally

2. **Update PageWebSocketClient** (30 min)
   - Add sendUndo(pageId, operation)
   - Add sendRedo(pageId, operation)
   - Handle page:undo:applied
   - Handle page:redo:applied

3. **Add keyboard shortcuts** (30 min)
   - Ctrl+Z → Undo
   - Ctrl+Y / Ctrl+Shift+Z → Redo
   - Handle in editor screen

4. **Add UI buttons** (30 min)
   - Undo button (enabled when can undo)
   - Redo button (enabled when can redo)
   - Tooltips with shortcuts

5. **Write tests** (1 hour)
   - Unit tests for undo/redo logic
   - Widget tests for UI
   - Integration tests

### Test Scenarios

1. **Single User Undo**
   - Add widget → Undo → Widget removed ✅

2. **Single User Undo/Redo**
   - Add widget → Undo → Redo → Widget back ✅

3. **Multi-User Undo (No Conflict)**
   - User A: Add widget at 0
   - User B: Add widget at 5
   - User A: Undo → Only A's widget removed ✅

4. **Multi-User Undo (With Conflict)**
   - User A: Add widget at 0
   - User B: Add widget at 0 (concurrent)
   - User A: Undo → OT transforms, correct widget removed ✅

5. **Undo After Delete**
   - User A: Add widget at 0
   - User B: Delete widget at 0
   - User A: Try undo → Cannot undo (already deleted) ✅

6. **Multiple Undos**
   - User A: Add widget → Update color → Update size
   - User A: Undo 3x → All changes reverted ✅

7. **Redo After Concurrent Change**
   - User A: Add widget → Undo
   - User B: Add widget
   - User A: Redo → OT transforms, both widgets present ✅

### Performance Considerations

- **Operation History Size**: Limit to last 100 operations per page
- **Cleanup**: Archive old operations after 30 days
- **Memory**: Keep only recent operations in memory
- **Transform Cost**: Cache transformed operations

### Edge Cases

1. **Undo Limit**: Max 100 undos per user
2. **Concurrent Undo**: Two users undo same operation → OT resolves
3. **Invalid Undo**: Operation no longer valid → Show error, don't apply
4. **Redo Invalidation**: New operation clears redo stack
5. **Undo Across Sessions**: Persist undo stack? (Future enhancement)

---

## 🎯 Phase 3.2: Presence Awareness (DETAILED PLAN)

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENCE ARCHITECTURE                     │
└─────────────────────────────────────────────────────────────┘

Backend:
├── Redis (Presence Data)
│   ├── page:<pageId>:cursors → Hash of user cursors
│   ├── page:<pageId>:selections → Hash of user selections
│   └── TTL: Auto-expire after 30 seconds
│
└── WebSocket Events
    ├── page:cursor → Update cursor position
    ├── page:selection → Update selection
    └── Broadcast to room

Frontend:
├── Presence Manager
│   ├── Track local cursor position
│   ├── Throttle updates (100ms)
│   ├── Render remote cursors
│   └── Handle user join/leave
│
└── UI Components
    ├── RemoteCursor widget (colored dot + label)
    ├── SelectionOverlay (highlight selected widget)
    └── ActiveUsersList (sidebar)
```

### Implementation Steps

#### Backend (2 steps):

1. **Update page.handler.js** (1 hour)
   - Store cursor in Redis (TTL: 30s)
   - Broadcast cursor updates efficiently
   - Clean up on disconnect

2. **Add cursor smoothing** (optional, 30 min)
   - Interpolate cursor positions
   - Reduce jitter

#### Frontend (4 steps):

1. **Create RemoteCursor widget** (1 hour)
   - Colored dot with user name
   - Position on canvas
   - Smooth movement (animation)

2. **Track local cursor** (30 min)
   - Mouse move listener
   - Throttle updates (send every 100ms)
   - Send to WebSocket

3. **Render remote cursors** (1 hour)
   - Listen for cursor updates
   - Create/update RemoteCursor widgets
   - Remove on user leave

4. **Add ActiveUsersList** (30 min)
   - Sidebar with active users
   - User avatar + name + status
   - Cursor color indicator

### User Colors

Assign consistent colors per user:
```dart
const userColors = [
  Colors.blue,
  Colors.red,
  Colors.green,
  Colors.purple,
  Colors.orange,
  Colors.pink,
  Colors.teal,
  Colors.amber,
];

// Hash user ID to get consistent color
int colorIndex = userId.hashCode % userColors.length;
Color userColor = userColors[colorIndex];
```

---

## 🎯 Phase 3.3: Comments & Annotations (DETAILED PLAN)

### Database Schema

```sql
-- Comments table
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id UUID NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),
  
  -- Comment content
  content TEXT NOT NULL,
  
  -- Position (optional, for canvas comments)
  position_x FLOAT,
  position_y FLOAT,
  
  -- Reference (optional, for widget comments)
  widget_id VARCHAR(255),
  
  -- Thread support
  parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  
  -- Status
  resolved BOOLEAN DEFAULT false,
  resolved_by UUID REFERENCES users(id),
  resolved_at TIMESTAMP,
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP,
  
  INDEX idx_comments_page (page_id),
  INDEX idx_comments_widget (widget_id),
  INDEX idx_comments_thread (parent_comment_id)
);

-- Comment mentions (for @mentions)
CREATE TABLE comment_mentions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id UUID NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  
  UNIQUE(comment_id, user_id),
  INDEX idx_mentions_user (user_id)
);
```

### Implementation Steps

#### Backend (4 steps):

1. **Create comments table** (30 min)
2. **Build CommentsService** (1 hour)
3. **Add API endpoints** (1 hour)
4. **Add WebSocket events** (1 hour)

#### Frontend (4 steps):

1. **Create Comment model** (30 min)
2. **Build CommentThread widget** (1.5 hours)
3. **Add comment UI to editor** (1 hour)
4. **Real-time comment sync** (1 hour)

---

## 🎯 Phase 3.4: Page Templates (DETAILED PLAN)

### Database Schema

```sql
-- Templates table
CREATE TABLE page_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  
  -- Template content
  template_data JSONB NOT NULL,
  
  -- Preview thumbnail
  thumbnail_url VARCHAR(512),
  
  -- Category
  category VARCHAR(100), -- 'blank', 'dashboard', 'form', 'report', etc.
  
  -- Visibility
  is_public BOOLEAN DEFAULT false,
  created_by UUID REFERENCES users(id),
  
  -- Stats
  usage_count INT DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  INDEX idx_templates_category (category),
  INDEX idx_templates_public (is_public)
);
```

### Pre-built Templates

1. **Blank Canvas** - Empty page
2. **Dashboard** - Grid with cards
3. **Form** - Input fields layout
4. **Report** - Header + sections
5. **Prototype** - Mobile/desktop frames

---

## 📊 Phase 3 Priority & Roadmap

### Recommended Order:

**Week 1**:
1. ✅ Phase 3.2: Presence Awareness (3-4 hours)
   - Most visible impact
   - Medium complexity
   - High user value

**Week 2**:
2. ✅ Phase 3.4: Page Templates (2-3 hours)
   - Low complexity
   - Quick win
   - Improves onboarding

**Week 3**:
3. ✅ Phase 3.3: Comments & Annotations (4-5 hours)
   - Medium complexity
   - High team value
   - Natural progression

**Week 4**:
4. ✅ Phase 3.1: Undo/Redo (6-8 hours)
   - Most complex
   - Requires solid OT foundation
   - Highest technical value

**Total Time**: 15-20 hours over 4 weeks

---

## 🎯 Success Criteria

### Phase 3.1 (Undo/Redo):
- ✅ User can undo last 50 operations
- ✅ Undo works in multi-user scenarios
- ✅ Ctrl+Z / Ctrl+Y shortcuts work
- ✅ No data corruption from undos
- ✅ 40+ tests passing

### Phase 3.2 (Presence):
- ✅ User sees other users' cursors
- ✅ < 100ms cursor update latency
- ✅ Smooth cursor movement
- ✅ User colors consistent
- ✅ Active users list accurate

### Phase 3.3 (Comments):
- ✅ Users can add comments
- ✅ Thread support works
- ✅ @mentions notify users
- ✅ Real-time comment sync
- ✅ Comments persist

### Phase 3.4 (Templates):
- ✅ 5+ templates available
- ✅ Create page from template
- ✅ Save page as template
- ✅ Template preview works
- ✅ Templates categorized

---

## 🚀 Next Steps

### Immediate:
1. **Choose starting feature** (Recommended: 3.2 Presence)
2. **Create detailed task breakdown**
3. **Start implementation**

### This Session:
**Option A**: Start with Phase 3.2 (Presence Awareness)
- Quick to implement (3-4 hours)
- High visual impact
- Good introduction to Phase 3

**Option B**: Start with Phase 3.1 (Undo/Redo)
- Most complex, tackle it first
- Leverages fresh OT knowledge
- Highest technical value

**Option C**: Start with Phase 3.4 (Templates)
- Easiest to implement
- Quick win
- Good for momentum

### My Recommendation:
**Start with Phase 3.2 (Presence Awareness)** ⭐

**Why**:
- Medium complexity (good challenge)
- High user impact (immediately visible)
- Builds on existing cursor events (already partially implemented)
- Good foundation for comments (users can see who's active)

---

## 📋 Phase 3 Deliverables Summary

By end of Phase 3, users will have:

✅ **Undo/Redo** - Mistake recovery with OT  
✅ **User Presence** - See who's editing where  
✅ **Comments** - Discuss changes inline  
✅ **Templates** - Quick start layouts  

Result: **Professional-grade collaborative editor** 🎉

---

**Ready to start?** Which feature would you like to implement first?

**A)** Phase 3.2 - Presence Awareness (Recommended) ⭐  
**B)** Phase 3.1 - Undo/Redo (Most complex)  
**C)** Phase 3.4 - Templates (Quick win)  
**D)** Phase 3.3 - Comments (Team collaboration)  

Or tell me your preference! 🚀
