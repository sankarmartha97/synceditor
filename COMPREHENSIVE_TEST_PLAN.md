# Comprehensive Test Plan - SyncEditor
## All Phases Testing Documentation

**Project**: Collaborative Canvas Editor  
**Test Date**: August 27, 2026  
**Status**: Ready for Testing

---

## 📋 Table of Contents

1. [System Overview](#system-overview)
2. [Test Environment Setup](#test-environment-setup)
3. [Feature Matrix](#feature-matrix)
4. [Phase-by-Phase Testing](#phase-by-phase-testing)
5. [Integration Testing](#integration-testing)
6. [Performance Testing](#performance-testing)
7. [Test Execution Checklist](#test-execution-checklist)

---

## 🏗️ System Overview

### Architecture
- **Backend**: Node.js + Express + Socket.io + PostgreSQL + Redis
- **Frontend**: Flutter (Web, Mobile, Desktop)
- **Real-time**: WebSocket for collaborative editing
- **Conflict Resolution**: Operational Transformation (OT)

### Key Features Implemented
1. ✅ User Authentication & Authorization
2. ✅ Canvas/Page Management
3. ✅ Widget Management (CRUD)
4. ✅ Real-time Collaborative Editing
5. ✅ Operational Transformation (OT)
6. ✅ Version Control
7. ✅ Comments System
8. ✅ Undo/Redo with OT
9. ✅ Active Editors Tracking

---

## 🔧 Test Environment Setup

### Prerequisites Checklist

#### Backend Setup
```bash
# 1. Check Node.js version
node --version  # Should be v16+

# 2. Install dependencies
cd backend
npm install

# 3. Setup environment
cp .env.example .env
# Edit .env with your database credentials

# 4. Start services
# PostgreSQL - should be running on port 5432
# Redis - should be running on port 6379
```

#### Database Setup
```bash
# 1. Apply all migrations
cd backend
node -e "const {pool} = require('./src-js/config/database'); const fs = require('fs'); const path = require('path'); const migrationsDir = '../database/migrations'; fs.readdirSync(migrationsDir).filter(f => f.endsWith('.sql')).sort().forEach(file => { const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8'); pool.query(sql).then(() => console.log('✅', file)).catch(err => console.error('❌', file, err.message)); });"

# 2. Verify tables
# Should see: users, pages, widgets, versions, collaborators, comments, operation_history, user_undo_stacks, etc.
```

#### Frontend Setup
```bash
# 1. Check Flutter version
flutter --version  # Should be 3.0+

# 2. Install dependencies
cd frontend
flutter pub get

# 3. Run on web (for testing)
flutter run -d chrome

# Or run on desktop
flutter run -d windows  # or macos, linux
```

#### Start Backend Server
```bash
cd backend
npm run dev
# Should see:
# ✅ Database connected
# ✅ Redis connected
# 🚀 Server running on http://localhost:5000
# 📡 WebSocket ready
```

---

## 📊 Feature Matrix

| Feature | Phase | Backend | Frontend | WebSocket | Tested |
|---------|-------|---------|----------|-----------|--------|
| User Auth | 1 | ✅ | ✅ | N/A | ⏳ |
| Page CRUD | 1 | ✅ | ✅ | N/A | ⏳ |
| Widget CRUD | 1 | ✅ | ✅ | ✅ | ⏳ |
| Real-time Sync | 2 | ✅ | ✅ | ✅ | ⏳ |
| Operational Transformation | 2 | ✅ | ✅ | ✅ | ⏳ |
| Version Control | 2 | ✅ | ✅ | N/A | ⏳ |
| Collaborators | 2 | ✅ | ✅ | ✅ | ⏳ |
| Comments | 2.5 | ✅ | ✅ | ✅ | ⏳ |
| Undo/Redo | 3.1 | ✅ | ✅ | ✅ | ✅ |
| Active Editors | 3 | ✅ | ✅ | ✅ | ⏳ |

---

## 🧪 Phase-by-Phase Testing

### Phase 1: Core Functionality

#### Test 1.1: User Authentication

**Backend API Tests:**
```bash
# Register new user
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"password123"}'

# Login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Expected: Returns JWT token
```

**Frontend Tests:**
- [ ] Open app, see login screen
- [ ] Register new account - success
- [ ] Register duplicate email - shows error
- [ ] Login with correct credentials - success
- [ ] Login with wrong password - shows error
- [ ] Token persists after app restart

#### Test 1.2: Page Management

**Backend API Tests:**
```bash
# Get JWT token first (from login)
export TOKEN="your-jwt-token-here"

# Create page
curl -X POST http://localhost:5000/api/pages \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Page","description":"Test description"}'

# List pages
curl http://localhost:5000/api/pages \
  -H "Authorization: Bearer $TOKEN"

# Get page details
curl http://localhost:5000/api/pages/{page-id} \
  -H "Authorization: Bearer $TOKEN"

# Update page
curl -X PUT http://localhost:5000/api/pages/{page-id} \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated Page Name"}'

# Delete page
curl -X DELETE http://localhost:5000/api/pages/{page-id} \
  -H "Authorization: Bearer $TOKEN"
```

**Frontend Tests:**
- [ ] Dashboard shows "Create New Page" button
- [ ] Create page - appears in list
- [ ] Click page - opens editor
- [ ] Rename page - updates in list
- [ ] Delete page - removes from list
- [ ] Page list shows owner name
- [ ] Page list shows last modified date

#### Test 1.3: Widget CRUD (Local)

**Frontend Tests:**
- [ ] Open page editor
- [ ] Add button widget - appears on canvas
- [ ] Add text widget - appears on canvas
- [ ] Add shape widget (rectangle) - appears on canvas
- [ ] Select widget - shows selection handles
- [ ] Move widget by dragging - position updates
- [ ] Resize widget - size updates
- [ ] Change widget properties (color, text, etc.) - updates immediately
- [ ] Delete widget - removes from canvas
- [ ] Undo delete (Ctrl+Z) - widget reappears

---

### Phase 2: Real-time Collaboration

#### Test 2.1: Multi-User Setup

**Setup:**
1. Open same page in 2 browser tabs (User A and User B)
2. Or use 2 different devices/browsers

**Initial Connection Tests:**
- [ ] User A joins page - sees canvas
- [ ] User B joins page - sees same canvas
- [ ] User A sees "User B is editing" indicator
- [ ] User B sees "User A is editing" indicator

#### Test 2.2: Real-time Widget Sync

**Test Scenario:**
1. User A adds a red button at (100, 100)
2. User B should see the red button appear immediately
3. User B moves the button to (200, 200)
4. User A should see the button move
5. User A changes button color to blue
6. User B should see color change

**Checklist:**
- [ ] Widget add syncs to all users
- [ ] Widget move syncs to all users
- [ ] Widget resize syncs to all users
- [ ] Widget property changes sync to all users
- [ ] Widget delete syncs to all users
- [ ] Sync latency < 500ms

#### Test 2.3: Operational Transformation (Conflict Resolution)

**Test Scenario - Concurrent Edits:**
1. User A and User B both edit simultaneously
2. User A adds widget at `/widgets/0`
3. User B adds widget at `/widgets/0` (same path)
4. OT should resolve the conflict

**Test Steps:**
- [ ] Disconnect User B's network (simulate offline)
- [ ] User A adds 3 widgets
- [ ] User B adds 2 widgets (while offline)
- [ ] Reconnect User B's network
- [ ] Both users should see all 5 widgets without duplicates
- [ ] No errors in console
- [ ] Page version is consistent

**Test Scenario - Path Transformation:**
1. User A removes widget at index 0
2. User B (simultaneously) modifies widget at index 1
3. After OT, User B's modification should target index 0

**Checklist:**
- [ ] Concurrent adds don't create duplicates
- [ ] Concurrent removes don't cause errors
- [ ] Path indices adjust correctly
- [ ] No data loss
- [ ] Page remains consistent

#### Test 2.4: Version Control

**Backend Tests:**
```bash
# Get page versions
curl http://localhost:5000/api/pages/{page-id}/versions \
  -H "Authorization: Bearer $TOKEN"

# Expected: Array of versions with incrementing version numbers
```

**Frontend Tests:**
- [ ] Make 5 changes to page
- [ ] Version number increments after each change
- [ ] Version history shows correct timestamps
- [ ] Version history shows user who made change

---

### Phase 2.5: Comments System

#### Test 2.5.1: Comment CRUD

**Frontend Tests:**
- [ ] Click on canvas area - "Add Comment" button appears
- [ ] Add comment with text - comment appears
- [ ] Edit comment - text updates
- [ ] Delete comment - comment disappears
- [ ] Comment shows author name
- [ ] Comment shows timestamp

#### Test 2.5.2: Comment Threads

**Test Scenario:**
- [ ] Add root comment
- [ ] Reply to comment - creates thread
- [ ] Reply to reply - nested thread
- [ ] Thread shows correct hierarchy
- [ ] Collapse/expand thread works

#### Test 2.5.3: Comment Position

**Test Scenario:**
- [ ] Add comment at canvas position (100, 100)
- [ ] Comment marker appears at correct position
- [ ] Move widget - comment stays at original position
- [ ] Zoom in/out - comment position scales correctly

#### Test 2.5.4: Real-time Comment Sync

**Multi-User Test:**
- [ ] User A adds comment
- [ ] User B sees comment appear immediately
- [ ] User B replies to comment
- [ ] User A sees reply appear immediately
- [ ] User A deletes comment
- [ ] User B sees comment disappear

---

### Phase 3.1: Undo/Redo

#### Test 3.1.1: Single User Undo/Redo ✅

**Automated Test:** `backend/test-undo-redo.js` - **PASSED**

**Frontend Tests:**
- [ ] Add widget - press Ctrl+Z - widget disappears
- [ ] Press Ctrl+Y - widget reappears
- [ ] Make 5 changes - press Ctrl+Z 5 times - all undone
- [ ] Press Ctrl+Y 5 times - all redone
- [ ] Undo button in toolbar disabled when nothing to undo
- [ ] Redo button disabled when nothing to redo
- [ ] Keyboard shortcuts work: Ctrl+Z, Ctrl+Y (Windows/Linux)
- [ ] Keyboard shortcuts work: Cmd+Z, Cmd+Shift+Z (Mac)

#### Test 3.1.2: Multi-User Undo

**Test Scenario:**
1. User A adds red button
2. User B adds blue button
3. User A presses Ctrl+Z (undo red button)
4. Both users should see only blue button
5. User A presses Ctrl+Y (redo red button)
6. Both users should see both buttons

**Checklist:**
- [ ] Each user has independent undo stack
- [ ] User A's undo doesn't affect User B's changes
- [ ] Undo syncs to all connected users
- [ ] Redo syncs to all connected users
- [ ] No conflicts or errors

#### Test 3.1.3: Undo with OT

**Test Scenario:**
1. User A adds widget at index 0
2. User B adds widget at index 1
3. User A modifies widget at index 0
4. User B presses Ctrl+Z (undo their widget add)
5. OT should transform the undo operation

**Checklist:**
- [ ] User B's widget is removed
- [ ] User A's widget remains at index 0
- [ ] No path conflicts
- [ ] Page state is consistent

---

### Phase 3: Active Editors

#### Test 3.1: Active Editor Tracking

**Multi-User Test:**
- [ ] User A joins page - shown as active editor
- [ ] User B joins page - both shown as active editors
- [ ] User A closes tab - removed from active editors
- [ ] User B sees User A removed
- [ ] User reconnects - added back to active editors

#### Test 3.2: Cursor Position Tracking

**Test Scenario:**
- [ ] User A moves mouse on canvas
- [ ] User B sees User A's cursor position indicator
- [ ] User B moves mouse
- [ ] User A sees User B's cursor
- [ ] Cursors have different colors per user
- [ ] Cursor shows user name label

---

## 🔗 Integration Testing

### Test I.1: Complete User Journey

**Scenario: New User Creates and Collaborates**

1. **Registration & Login**
   - [ ] Register new account
   - [ ] Login successfully
   - [ ] See dashboard

2. **Create Page**
   - [ ] Click "New Page"
   - [ ] Enter name and description
   - [ ] Page appears in list

3. **Add Content**
   - [ ] Add 3 widgets (button, text, shape)
   - [ ] Arrange widgets on canvas
   - [ ] Change colors and properties
   - [ ] Add comment on canvas

4. **Invite Collaborator**
   - [ ] Share page link with User B
   - [ ] User B opens link
   - [ ] User B sees same content

5. **Collaborate**
   - [ ] User A and User B edit simultaneously
   - [ ] Changes sync in real-time
   - [ ] No conflicts or errors
   - [ ] Comments sync between users

6. **Use Advanced Features**
   - [ ] User A makes changes and undoes (Ctrl+Z)
   - [ ] User B sees undo effect
   - [ ] Check version history
   - [ ] Restore previous version

### Test I.2: Conflict Resolution Journey

**Scenario: Stress Test OT System**

1. **Setup**
   - [ ] User A and User B open same page
   - [ ] Disconnect User B (simulate network issue)

2. **Offline Changes**
   - [ ] User A adds 5 widgets
   - [ ] User B (offline) adds 3 widgets
   - [ ] User A deletes 2 widgets
   - [ ] User B (offline) modifies 2 widgets

3. **Reconnection**
   - [ ] Reconnect User B
   - [ ] Wait for sync to complete
   - [ ] Verify all changes are present
   - [ ] Verify no duplicates or conflicts
   - [ ] Page state is consistent between users

### Test I.3: Undo/Redo with Comments

**Scenario: Complex Interaction**

1. [ ] User A adds widget
2. [ ] User B adds comment on that widget
3. [ ] User A presses Ctrl+Z (undo widget)
4. [ ] Widget disappears but comment remains
5. [ ] User A presses Ctrl+Y (redo widget)
6. [ ] Widget reappears at correct position
7. [ ] Comment still at correct position

---

## ⚡ Performance Testing

### Test P.1: Load Testing

**Backend Load Test:**
```bash
# Install artillery
npm install -g artillery

# Create test config: artillery-load-test.yml
# Run load test
artillery run artillery-load-test.yml

# Metrics to check:
# - Response time < 100ms for 95th percentile
# - WebSocket connections: 100 concurrent users
# - Database queries < 50ms
# - No memory leaks
```

**Test Scenarios:**
- [ ] 10 concurrent users - stable
- [ ] 50 concurrent users - stable
- [ ] 100 concurrent users - acceptable performance
- [ ] 500 operations/second - system handles load

### Test P.2: Large Document Testing

**Test Scenario:**
- [ ] Create page with 500 widgets
- [ ] Add widget - latency < 200ms
- [ ] Move widget - smooth animation
- [ ] Undo operation - completes < 100ms
- [ ] Multi-user sync with 500 widgets - works

### Test P.3: Network Conditions

**Test Scenarios:**
- [ ] Slow 3G - page loads and works
- [ ] High latency (500ms) - operations still work
- [ ] Packet loss (10%) - reconnects automatically
- [ ] Network disconnect/reconnect - recovers gracefully

---

## 📝 Test Execution Checklist

### Pre-Testing
- [ ] All migrations applied
- [ ] Backend server running without errors
- [ ] Redis connected
- [ ] PostgreSQL connected
- [ ] Frontend compiles without errors
- [ ] No console errors on startup

### Core Features
- [ ] User authentication works
- [ ] Page CRUD operations work
- [ ] Widget CRUD operations work
- [ ] Real-time sync works
- [ ] OT conflict resolution works
- [ ] Comments system works
- [ ] Undo/redo works (automated tests passed ✅)
- [ ] Active editors tracking works

### Multi-User Features
- [ ] 2 users can edit simultaneously
- [ ] Changes sync in < 500ms
- [ ] No race conditions
- [ ] No data loss
- [ ] Consistent state across clients

### Error Handling
- [ ] Network disconnect - shows reconnecting message
- [ ] Network reconnect - syncs changes
- [ ] Server restart - clients reconnect automatically
- [ ] Invalid operation - shows error message
- [ ] Database error - handled gracefully

### UI/UX
- [ ] Buttons respond to clicks
- [ ] Keyboard shortcuts work
- [ ] Drag and drop is smooth
- [ ] Loading states show appropriately
- [ ] Error messages are clear
- [ ] Success confirmations appear

### Performance
- [ ] Page loads < 3 seconds
- [ ] Operations complete < 200ms
- [ ] No memory leaks (test for 30 minutes)
- [ ] Works with 100+ widgets
- [ ] Works with 10+ concurrent users

---

## 🐛 Known Issues & Limitations

### Current Limitations
1. Undo stack limited to 100 operations per user
2. Maximum 1000 widgets per page (performance consideration)
3. Comment attachments not yet implemented
4. Mobile touch gestures need refinement

### Browser Support
- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+

---

## 📊 Test Results Summary

### Automated Tests
| Test Suite | Status | Pass/Total |
|------------|--------|------------|
| Undo/Redo Backend | ✅ PASS | 5/5 |
| OT Transformations | ⏳ Pending | 0/? |
| API Integration | ⏳ Pending | 0/? |

### Manual Tests
| Feature Category | Status | Tests Passed |
|-----------------|--------|--------------|
| Authentication | ⏳ Pending | 0/6 |
| Page Management | ⏳ Pending | 0/7 |
| Widget CRUD | ⏳ Pending | 0/10 |
| Real-time Sync | ⏳ Pending | 0/6 |
| OT Conflicts | ⏳ Pending | 0/8 |
| Comments | ⏳ Pending | 0/12 |
| Undo/Redo | ⏳ Pending | 0/15 |
| Performance | ⏳ Pending | 0/8 |

---

## 🚀 Test Execution Commands

### Quick Start Testing

```bash
# 1. Start backend
cd backend
npm run dev

# 2. Run automated tests
node test-undo-redo.js

# 3. Start frontend (in new terminal)
cd frontend
flutter run -d chrome

# 4. Open second tab for multi-user testing
# Navigate to: http://localhost:8080 (or your Flutter web port)
```

### Automated Test Suites

```bash
# Backend unit tests
cd backend
npm test

# Backend integration tests
npm run test:integration

# Undo/Redo tests
node test-undo-redo.js

# OT tests (if available)
node test-ot.js

# Load tests
artillery run artillery-load-test.yml
```

---

## 📚 Documentation References

- **API Documentation**: `backend/API_DOCS.md`
- **WebSocket Events**: `backend/src-js/websocket/events.js`
- **Database Schema**: `database/schema.sql`
- **Undo/Redo Guide**: `backend/UNDO_REDO_TESTING_GUIDE.md`
- **Test Results**: `TEST_RESULTS_PHASE_3_1.md`

---

## ✅ Sign-off

### Test Sign-off Checklist

- [ ] All automated tests pass
- [ ] All critical paths tested manually
- [ ] Multi-user scenarios verified
- [ ] Performance is acceptable
- [ ] No critical bugs found
- [ ] Documentation is complete

### Approval

**Tester**: ________________  
**Date**: ________________  
**Status**: ⏳ IN PROGRESS  

**Notes**:
_Add any additional notes or observations here_

---

**Document Version**: 1.0  
**Last Updated**: August 27, 2026  
**Next Review**: After manual testing completion
