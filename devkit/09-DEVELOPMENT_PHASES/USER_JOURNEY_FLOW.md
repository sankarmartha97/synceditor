# 🚀 User Journey Flow - Page-Based Collaborative Editor

**Last Updated:** January 2025  
**Version:** 2.0 (New Page-Based Architecture)

---

## 📱 Table of Contents

1. [New User Registration & First Page](#flow-1-new-user-registration--first-page)
2. [Existing User Login](#flow-2-existing-user-login)
3. [Creating & Editing a Page](#flow-3-creating--editing-a-page)
4. [Adding Widgets to Page](#flow-4-adding-widgets-to-page)
5. [Real-Time Collaboration (Two Users)](#flow-5-real-time-collaboration-two-users)
6. [Sharing a Page](#flow-6-sharing-a-page)
7. [View-Only Permission](#flow-7-view-only-permission)
8. [Auto-Save & Sync Status](#flow-8-auto-save--sync-status)
9. [Incremental Sync (Technical)](#flow-9-incremental-sync-technical-flow)
10. [Multiple Changes (Batching)](#flow-10-multiple-changes-batching)
11. [Version History & Restore](#flow-11-version-history--restore)
12. [Complete Data Flow Diagram](#complete-data-flow-diagram)

---

## FLOW 1: New User Registration & First Page

```
1. User visits app → Landing Page
   ↓
2. Click "Sign Up"
   ↓
3. Enter: Name, Email, Password
   ↓
4. Email verification (optional)
   ↓
5. Login automatically
   ↓
6. Welcome screen: "Create Your First Page"
   ↓
7. Enter page name: "My Landing Page"
   ↓
8. Redirect to → Page Editor
```

**Time:** ~1 minute  
**Result:** User is in the page editor with a blank canvas

---

## FLOW 2: Existing User Login

```
1. User visits app → Login Page
   ↓
2. Enter: Email + Password
   ↓
3. Click "Login"
   ↓
4. Redirect to → Dashboard (My Pages)
   ↓
5. See list of pages:
   - Pages I Own
   - Pages Shared With Me
   ↓
6. Click on a page → Page Editor
```

**Time:** ~10 seconds  
**Result:** User sees their dashboard with all accessible pages

---

## FLOW 3: Creating & Editing a Page

### Dashboard View

```
DASHBOARD VIEW
┌────────────────────────────────────────┐
│  My Pages                    [+ New]   │
├────────────────────────────────────────┤
│  📄 Landing Page Design      Owner     │
│  📄 Dashboard Mockup         Owner     │
│  📄 Mobile App UI   (Shared) Editor    │
└────────────────────────────────────────┘
```

### Create New Page Flow

```
User clicks [+ New Page]
   ↓
Enter Page Name: "E-commerce Homepage"
   ↓
Page Created → Redirect to Editor
   ↓
```

### Page Editor Screen

```
PAGE EDITOR SCREEN
┌──────────────────────────────────────────────────┐
│ 🏠 E-commerce Homepage    [👤 Share] [💾 Saved]  │
├──────────┬──────────────────────────┬────────────┤
│          │                          │            │
│ WIDGET   │       CANVAS             │ PROPERTIES │
│ LIBRARY  │                          │   PANEL    │
│          │                          │            │
│ 📦 Box   │   [Drag widgets here]    │  Selected: │
│ 📝 Text  │                          │   None     │
│ 🖼️ Image │                          │            │
│ 🔘 Button│                          │            │
│          │                          │            │
└──────────┴──────────────────────────┴────────────┘
```

**Key Elements:**
- **Left Panel:** Widget Library (drag sources)
- **Center:** Canvas (drop target, workspace)
- **Right Panel:** Properties of selected widget
- **Top Bar:** Page name, share button, sync status

---

## FLOW 4: Adding Widgets to Page

```
Step 1: User drags "Container" from Widget Library
   ↓
Step 2: Drop on canvas at position (100, 200)
   ↓
Step 3: Widget appears on canvas
   ↓
Step 4: AUTO-SYNC happens (background)
   ├─► Local State Updated (Optimistic)
   ├─► Operation queued: 
   │   { op: "add", path: "/widgets/-", value: {...} }
   ├─► WebSocket sends to server
   ├─► Server saves to database
   ├─► Server broadcasts to other users
   └─► Status shows: "💾 Saved"
   ↓
Step 5: Properties Panel shows widget properties
   ↓
Step 6: User changes background color
   ↓
Step 7: AUTO-SYNC happens again
   ├─► Operation: 
   │   { op: "replace", path: "/widgets/0/properties/backgroundColor", value: "#FF5733" }
   └─► Synced in <100ms
```

### What Happens Behind the Scenes

```json
// Local State (Client)
{
  "pageId": "abc-123",
  "version": 5,
  "widgets": [
    {
      "id": "widget-1",
      "type": "Container",
      "position": { "x": 100, "y": 200 },
      "size": { "width": 150, "height": 100 },
      "properties": {
        "backgroundColor": "#FF5733"
      }
    }
  ]
}

// Operation Sent to Server
{
  "op": "add",
  "path": "/widgets/-",
  "value": {
    "id": "widget-1",
    "type": "Container",
    "position": { "x": 100, "y": 200 },
    "size": { "width": 150, "height": 100 },
    "properties": {
      "backgroundColor": "#FF5733"
    }
  }
}
```

**Time:** ~2 seconds  
**Result:** Widget added, saved, and ready for collaboration

---

## FLOW 5: Real-Time Collaboration (Two Users)

```
USER 1 (Sankar)                    USER 2 (John)
═══════════════════════════════════════════════════

Opens page "Landing Page"
   ↓
WebSocket connects
   ↓
Server: "Sankar joined"
   ↓                               Opens same page
Status: "Just you" (alone)             ↓
                                   WebSocket connects
   ↓                                   ↓
   ← Server broadcasts →          Server: "John joined"
   ↓                                   ↓
Status: "👤 Sankar, John (2)"     Status: "👤 Sankar, John (2)"
```

### Live Cursor Tracking

```
Sankar moves mouse on canvas
   ↓
Emits: cursor:move {x: 150, y: 200}
   ↓
   ← Server broadcasts →
   ↓                                   ↓
                                   Sees Sankar's cursor
                                   🖱️ "Sankar" at (150, 200)
```

### Widget Addition

```
Sankar drags "Container"              |
Drops at (200, 300)                   |
   ↓                                  |
Operation: widget:add                 |
   ↓                                  |
   ← Server broadcasts →              |
   ↓                                  ↓
Widget added                      Widget appears instantly!
                                  "Sankar added Container"
```

### Simultaneous Editing (No Conflict)

```
Both editing simultaneously:
────────────────────────────────
Sankar: Editing widget-1               John: Editing widget-2
   ↓                                       ↓
Changes color to red                   Changes text to "Hello"
   ↓                                       ↓
   ← Both changes sync in real-time →
   ↓                                       ↓
Both see both changes!                Both see both changes!
No conflicts (different widgets)      No conflicts (different widgets)
```

### Widget Locking (Same Widget)

```
CONFLICT SCENARIO:
────────────────────────────────
Both click same widget (widget-1) at same time
   ↓                                   ↓
Widget-1 locked by Sankar          Shows: "🔒 Editing by Sankar"
Widget selected                     Widget disabled (read-only)
   ↓                                   ↓
Sankar moves widget                John can only view
   ↓                                   ↓
Sankar clicks elsewhere            Widget unlocked
Widget unlocked                        ↓
   ↓                               Now John can edit
   ← Lock released →                   ↓
```

**Time:** Instant (< 100ms latency)  
**Result:** Seamless real-time collaboration

---

## FLOW 6: Sharing a Page

### Owner's Perspective

```
USER: Sankar (Owner)
────────────────────
Opens page "Landing Page Design"
   ↓
Clicks [👤 Share] button
   ↓
```

### Share Dialog

```
SHARE DIALOG OPENS:
┌─────────────────────────────────────────┐
│  Share "Landing Page Design"            │
├─────────────────────────────────────────┤
│  Email: [john@gmail.com        ]        │
│  Permission: [Edit ▼] or [View ▼]      │
│           [Send Invite]                 │
├─────────────────────────────────────────┤
│  Current Collaborators:                 │
│  👤 Sankar (You)          Owner         │
│  👤 Alice Smith           Editor        │
│  👤 Bob Johnson           Viewer        │
├─────────────────────────────────────────┤
│  📋 Copy Link                           │
│  🔗 https://app.com/page/abc-123        │
└─────────────────────────────────────────┘
```

### Invitation Flow

```
Sankar enters: john@gmail.com
Selects: Edit permission
Clicks: [Send Invite]
   ↓
Backend:
  ├─► Create permission record in DB
  ├─► Send email to john@gmail.com
  └─► Return success
   ↓
UI shows: "✅ Invitation sent to John"
```

### Recipient's Perspective

```
USER: John
──────────
Receives email:
┌─────────────────────────────────────────┐
│  Sankar invited you to collaborate!    │
│  Page: "Landing Page Design"            │
│  Permission: Editor                     │
│                                         │
│       [Open Page]                       │
└─────────────────────────────────────────┘

Clicks [Open Page]
   ↓
If not logged in → Login/Signup
   ↓
Redirect to page editor
   ↓
Page opens with EDIT permission
   ↓
John can now edit the page
Sees: "Shared by Sankar"
```

**Time:** ~5 seconds  
**Result:** Page shared, collaborator has access

---

## FLOW 7: View-Only Permission

```
USER: Alice (Viewer)
────────────────────
Opens shared page "Landing Page"
   ↓
Permission: VIEW ONLY
   ↓
```

### Read-Only Editor

```
EDITOR UI (Read-Only Mode):
┌──────────────────────────────────────────────────┐
│ 🔒 Landing Page (View Only)      [Request Edit] │
├──────────┬──────────────────────────┬────────────┤
│          │                          │            │
│ WIDGET   │       CANVAS             │ PROPERTIES │
│ LIBRARY  │                          │   PANEL    │
│ (Hidden) │   [Widgets displayed]    │ (Read-Only)│
│          │                          │            │
│          │   ⚠️ You have view-only  │            │
│          │      permission          │            │
│          │                          │            │
└──────────┴──────────────────────────┴────────────┘
```

### Permissions Matrix

| Action | Owner | Editor | Viewer |
|--------|-------|--------|--------|
| View widgets | ✅ | ✅ | ✅ |
| Add widgets | ✅ | ✅ | ❌ |
| Edit widgets | ✅ | ✅ | ❌ |
| Delete widgets | ✅ | ✅ | ❌ |
| Share page | ✅ | ❌ | ❌ |
| Delete page | ✅ | ❌ | ❌ |
| See real-time updates | ✅ | ✅ | ✅ |
| See other cursors | ✅ | ✅ | ✅ |

### What Alice CAN do:
- ✅ View all widgets
- ✅ Zoom/pan canvas
- ✅ See real-time updates from editors
- ✅ See other users' cursors
- ✅ Copy widget properties (read values)

### What Alice CANNOT do:
- ❌ Add widgets
- ❌ Edit widgets
- ❌ Delete widgets
- ❌ Change page settings
- ❌ Share page with others

### User Interaction

```
If Alice tries to drag widget:
   ↓
Shows toast: "⚠️ You don't have edit permission"
```

**Result:** Safe viewing without accidental edits

---

## FLOW 8: Auto-Save & Sync Status

```
User makes any change (move, resize, color change)
   ↓
Immediate visual feedback (Optimistic Update)
   ↓
Status indicator changes:
```

### Timeline

```
─────────────────────────────────────────
t=0ms:    User moves widget
          Status: "💾 Saving..."
          ↓
t=50ms:   Change queued
          Debounce timer started
          ↓
t=500ms:  Debounce complete
          Send to server
          Status: "💾 Syncing..."
          ↓
t=700ms:  Server responds: Success
          Status: "✅ All changes saved"
          ↓
t=3000ms: Status fades to just icon "💾"
```

### Error Handling

```
If error occurs:
───────────────
t=700ms:  Server error (network issue)
          Status: "⚠️ Sync failed - Retrying..."
          ↓
t=2000ms: Retry attempt 1
          ↓
t=4000ms: Retry attempt 2
          ↓
t=8000ms: Retry attempt 3
          ↓
If still failing:
          Status: "❌ Offline - Changes saved locally"
          ↓
When network restored:
          Auto-sync queued changes
          Status: "✅ All changes saved"
```

### Status Indicator States

| Icon | Status | Meaning |
|------|--------|---------|
| 💾 | Idle | No pending changes |
| 💾 Saving... | Queueing | Changes queued locally |
| 💾 Syncing... | Syncing | Sending to server |
| ✅ All changes saved | Success | Sync complete |
| ⚠️ Sync failed | Warning | Retrying... |
| ❌ Offline | Error | Changes saved locally |

**Result:** User always knows sync status

---

## FLOW 9: Incremental Sync (Technical Flow)

### User Action

```
USER ACTION: Move widget from (100, 200) → (150, 250)
```

### Client Side

```
CLIENT SIDE:
────────────
1. User drags widget
   ↓
2. onDragEnd event fires
   ↓
3. Calculate operation:
   {
     op: "replace",
     path: "/widgets/0/position",
     value: { x: 150, y: 250 }
   }
   ↓
4. Apply to local state (Optimistic)
   localPage.widgets[0].position = { x: 150, y: 250 }
   ↓
5. Queue operation
   pendingOps.push(operation)
   ↓
6. Debounce 500ms
   ↓
7. Send to server via WebSocket:
   {
     event: "page:sync",
     data: {
       pageId: "abc-123",
       version: 5,
       operations: [operation],
       timestamp: 1234567890
     }
   }
```

### Server Side

```
SERVER SIDE:
────────────
8. Receive sync request
   ↓
9. Validate user permission (edit?)
   ↓
10. Get current page from DB
    currentVersion = 5
    ↓
11. Check version match
    if (requestVersion === currentVersion) {
      ✅ No conflict
    } else {
      ⚠️ Conflict detected
      Get missed operations
      Attempt merge
    }
    ↓
12. Apply operation to page JSON
    page.widgets[0].position = { x: 150, y: 250 }
    ↓
13. Increment version
    page.version = 6
    ↓
14. Save to database
    UPDATE pages SET page_data = ..., version = 6
    ↓
15. Save to version history
    INSERT INTO page_versions ...
    ↓
16. Broadcast to all other users in room:
    io.to(pageId).emit('page:update', {
      operations: [operation],
      version: 6,
      userId: "sankar-id"
    })
    ↓
17. Send acknowledgment to original client
    {
      success: true,
      newVersion: 6
    }
```

### Other Clients

```
OTHER CLIENTS:
──────────────
18. Receive 'page:update' event
    ↓
19. Apply operation to their local state
    localPage.widgets[0].position = { x: 150, y: 250 }
    ↓
20. Update UI (re-render)
    Widget smoothly moves to new position
    ↓
21. Show notification: "Sankar moved Container"
```

### JSON Patch Operations

```json
// Add widget
{
  "op": "add",
  "path": "/widgets/-",
  "value": { "id": "widget-3", "type": "Text", ... }
}

// Update widget position
{
  "op": "replace",
  "path": "/widgets/0/position",
  "value": { "x": 150, "y": 250 }
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
```

**Time:** ~500ms (end-to-end)  
**Result:** Efficient incremental sync

---

## FLOW 10: Multiple Changes (Batching)

```
User makes rapid changes:
─────────────────────────
t=0ms:    Move widget → Operation 1 queued
t=50ms:   Resize widget → Operation 2 queued
t=100ms:  Change color → Operation 3 queued
t=150ms:  Change text → Operation 4 queued
   ↓
Debounce waits...
   ↓
t=650ms:  Debounce complete (500ms after last change)
   ↓
Send all 4 operations in ONE batch:
{
  pageId: "abc-123",
  version: 5,
  operations: [
    { op: "replace", path: "/widgets/0/position", ... },
    { op: "replace", path: "/widgets/0/size", ... },
    { op: "replace", path: "/widgets/0/properties/backgroundColor", ... },
    { op: "replace", path: "/widgets/0/properties/text", ... }
  ]
}
   ↓
Server applies all 4 operations
   ↓
Single database write
   ↓
Single broadcast to other users
   ↓
✅ Efficient! (1 network call instead of 4)
```

### Benefits

- **Network Efficiency:** 1 request instead of 4
- **Database Efficiency:** 1 write instead of 4
- **Broadcast Efficiency:** 1 broadcast instead of 4
- **Better Performance:** Reduced overhead

**Result:** Smooth experience even with rapid changes

---

## FLOW 11: Version History & Restore

### Open History

```
User clicks "⏱️ History" button
   ↓
```

### History Panel

```
HISTORY PANEL OPENS:
┌─────────────────────────────────────────┐
│  Version History                        │
├─────────────────────────────────────────┤
│  📅 Today, 10:45 AM (Current)           │
│  👤 Sankar moved Container              │
│                                         │
│  📅 Today, 10:30 AM                     │
│  👤 John changed text color             │
│                            [Restore]    │
│                                         │
│  📅 Today, 10:15 AM                     │
│  👤 Sankar added Button widget          │
│                            [Restore]    │
│                                         │
│  📅 Today, 10:00 AM                     │
│  👤 John created page                   │
│                            [Restore]    │
└─────────────────────────────────────────┘
```

### Restore Flow

```
User clicks [Restore] on "10:15 AM" version
   ↓
Confirmation dialog:
"⚠️ Restore to this version?
This will replace the current page.
Current version will be saved in history."
   [Cancel]  [Restore]
   ↓
User clicks [Restore]
   ↓
Backend:
  ├─► Get version 3 data from page_versions table
  ├─► Save current state as new version
  ├─► Replace current page_data with version 3
  └─► Broadcast to all users
   ↓
All users see page revert to version 3
   ↓
Notification: "Sankar restored to version from 10:15 AM"
```

### Version Information

```json
{
  "versionId": "v123",
  "pageId": "abc-123",
  "version": 3,
  "timestamp": 1234567890,
  "userId": "sankar-id",
  "userName": "Sankar",
  "changes": [
    {
      "op": "add",
      "path": "/widgets/-",
      "description": "Added Button widget"
    }
  ]
}
```

**Time:** ~10 seconds  
**Result:** Page restored to previous state

---

## 🔄 Complete Data Flow Diagram

```
┌─────────────┐
│   CLIENT    │
│  (Flutter)  │
└──────┬──────┘
       │
       │ 1. User Action (drag, click, type)
       ↓
┌─────────────────────┐
│  BLoC State Manager │
│  - Apply optimistic │
│  - Queue operation  │
└──────┬──────────────┘
       │
       │ 2. Operation queued
       ↓
┌─────────────────────┐
│   Sync Service      │
│  - Debounce 500ms   │
│  - Batch operations │
└──────┬──────────────┘
       │
       │ 3. WebSocket emit 'page:sync'
       ↓
┌─────────────────────┐
│   WebSocket Client  │
└──────┬──────────────┘
       │
       │ 4. Network call
       ↓
╔═════════════════════╗
║   SERVER            ║
║  (Node.js + Socket) ║
╚══════┬══════════════╝
       │
       │ 5. Validate & authorize
       ↓
┌─────────────────────┐
│  Permission Check   │
│  - Edit or View?    │
└──────┬──────────────┘
       │
       │ 6. If authorized
       ↓
┌─────────────────────┐
│  Conflict Detection │
│  - Check version    │
│  - Merge if needed  │
└──────┬──────────────┘
       │
       │ 7. Apply operations
       ↓
┌─────────────────────┐
│  PostgreSQL DB      │
│  - Update page_data │
│  - Increment version│
│  - Save history     │
└──────┬──────────────┘
       │
       │ 8. Broadcast
       ↓
┌─────────────────────────────────┐
│  WebSocket Broadcast            │
│  - Send to all clients except   │
│    sender                       │
└──────┬──────────────────────────┘
       │
       ├────────────┬────────────┐
       ↓            ↓            ↓
  [Client 1]   [Client 2]   [Client 3]
  (Sender)     (Receives)   (Receives)
       │            │            │
       │            ↓            ↓
       │       Update UI    Update UI
       │       Show change  Show change
       ↓
  Acknowledge
  Show "Saved"
```

---

## 📊 Flow Summary

| Flow | Description | Time | Result |
|------|-------------|------|--------|
| **Sign Up** | New user → Verification → Dashboard | 1 min | Access granted |
| **Login** | Existing user → Dashboard | 10 sec | Dashboard loaded |
| **Create Page** | Name → Editor with empty canvas | 5 sec | Blank page ready |
| **Add Widget** | Drag → Drop → Auto-saved | 2 sec | Widget added & synced |
| **Edit Widget** | Change property → Synced | <1 sec | Change propagated |
| **Share Page** | Invite user → Email sent | 5 sec | Access granted |
| **Real-time Collab** | Multiple users → Live updates | Instant | Seamless collaboration |
| **Sync Change** | Edit → Queue → Send → Broadcast | 500ms | All users updated |
| **View History** | Open panel → Browse → Restore | 10 sec | Version restored |

---

## 🎯 Key Takeaways

### For Users
1. **Instant Feedback** - Changes appear immediately
2. **Always Saved** - Auto-save every 500ms
3. **Real-Time** - See collaborators' changes instantly
4. **Permissions** - Control who can edit or view
5. **Version History** - Never lose work, restore anytime

### For Developers
1. **Optimistic Updates** - Apply changes locally first
2. **Incremental Sync** - Send only changed data
3. **Conflict Resolution** - Version-based merging
4. **WebSocket** - Real-time bidirectional communication
5. **JSON Patch** - Standard operation format

---

## 📝 Notes

- All times are approximate and depend on network conditions
- WebSocket latency typically < 100ms on good connection
- Debounce time of 500ms balances responsiveness vs efficiency
- Version history saved every 5 minutes or on major changes
- Widget locking timeout: 30 seconds of inactivity

---

**End of User Journey Flow Documentation**
