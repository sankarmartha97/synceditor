# Follow Feature API Specification

## WebSocket Events

### Client → Server Events

#### 1. Start Following User
```javascript
Event: 'page:follow:start'

Payload:
{
  pageId: string,        // Page ID
  targetUserId: string   // User ID to follow
}

Example:
socket.emit('page:follow:start', {
  pageId: 'page-123',
  targetUserId: 'user-456'
});
```

**Response Events:**
- `page:follow:started` - Success
- `page:follow:error` - Failure

---

#### 2. Stop Following User
```javascript
Event: 'page:follow:stop'

Payload:
{
  pageId: string   // Page ID
}

Example:
socket.emit('page:follow:stop', {
  pageId: 'page-123'
});
```

**Response Events:**
- `page:follow:stopped` - Success
- `page:follow:error` - Failure

---

#### 3. Send Viewport Update
```javascript
Event: 'page:viewport:update'

Payload:
{
  pageId: string,
  viewport: {
    scrollX: number,      // Canvas horizontal scroll position
    scrollY: number,      // Canvas vertical scroll position
    zoom: number,         // Zoom level (0.1 to 5.0)
    centerX: number,      // Viewport center X coordinate
    centerY: number,      // Viewport center Y coordinate
    width: number,        // Viewport width in pixels
    height: number        // Viewport height in pixels
  }
}

Example:
socket.emit('page:viewport:update', {
  pageId: 'page-123',
  viewport: {
    scrollX: 100,
    scrollY: 200,
    zoom: 1.0,
    centerX: 960,
    centerY: 540,
    width: 1920,
    height: 1080
  }
});
```

**Note:** This event should be throttled on the client side to max 10 updates/second.

---

### Server → Client Events

#### 1. Follow Started Confirmation
```javascript
Event: 'page:follow:started'

Payload:
{
  pageId: string,
  followedUserId: string,
  followedUserName: string,
  initialViewport: {      // Current viewport of followed user
    scrollX: number,
    scrollY: number,
    zoom: number,
    centerX: number,
    centerY: number,
    width: number,
    height: number,
    timestamp: string     // ISO 8601 format
  }
}

Example:
socket.on('page:follow:started', (data) => {
  console.log(`Now following ${data.followedUserName}`);
  // Sync viewport to initialViewport
});
```

---

#### 2. Follow Stopped Confirmation
```javascript
Event: 'page:follow:stopped'

Payload:
{
  pageId: string,
  reason: string        // 'user_action', 'target_left', 'connection_lost'
}

Example:
socket.on('page:follow:stopped', (data) => {
  console.log(`Stopped following: ${data.reason}`);
  // Exit follow mode
});
```

---

#### 3. Viewport Update from Followed User
```javascript
Event: 'page:viewport:updated'

Payload:
{
  pageId: string,
  userId: string,       // User ID of the followed user
  userName: string,     // User name for display
  viewport: {
    scrollX: number,
    scrollY: number,
    zoom: number,
    centerX: number,
    centerY: number,
    width: number,
    height: number
  },
  timestamp: string     // ISO 8601 format
}

Example:
socket.on('page:viewport:updated', (data) => {
  // Only process if currently following this user
  if (currentlyFollowing === data.userId) {
    syncToViewport(data.viewport);
  }
});
```

**Note:** This event is only sent to users who are actively following the viewport owner.

---

#### 4. Follow Error
```javascript
Event: 'page:follow:error'

Payload:
{
  operation: string,    // 'follow_start', 'follow_stop', 'viewport_update'
  message: string,      // Human-readable error message
  code: string         // Error code for programmatic handling
}

Error Codes:
- 'USER_NOT_FOUND' - Target user not in page
- 'PERMISSION_DENIED' - Not allowed to follow
- 'ALREADY_FOLLOWING' - Already following this user
- 'NOT_FOLLOWING' - Not currently following anyone
- 'INVALID_VIEWPORT' - Viewport data validation failed
- 'RATE_LIMITED' - Too many follow/unfollow requests

Example:
socket.on('page:follow:error', (data) => {
  console.error(`Follow error: ${data.message}`);
  showErrorNotification(data.message);
});
```

---

## Redis Data Structures

### 1. Follow Relationships

**Key:** `page:{pageId}:follows`

**Type:** Hash

**Structure:**
```
{
  "follower-user-id-1": "followed-user-id-1",
  "follower-user-id-2": "followed-user-id-2",
  ...
}
```

**Operations:**
```javascript
// Set follow relationship
await redis.hset('page:123:follows', 'user-456', 'user-789');

// Get who a user is following
const followedUserId = await redis.hget('page:123:follows', 'user-456');

// Remove follow relationship
await redis.hdel('page:123:follows', 'user-456');

// Get all followers of a specific user
const allFollows = await redis.hgetall('page:123:follows');
const followers = Object.entries(allFollows)
  .filter(([_, followed]) => followed === 'user-789')
  .map(([follower, _]) => follower);
```

**TTL:** None (removed on explicit unfollow or user disconnect)

---

### 2. Viewport Data

**Key:** `page:{pageId}:viewport:{userId}`

**Type:** String (JSON)

**Structure:**
```json
{
  "userId": "user-789",
  "viewport": {
    "scrollX": 100,
    "scrollY": 200,
    "zoom": 1.0,
    "centerX": 960,
    "centerY": 540,
    "width": 1920,
    "height": 1080
  },
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

**Operations:**
```javascript
// Store viewport
await redis.setex(
  'page:123:viewport:user-789',
  30,  // TTL: 30 seconds
  JSON.stringify(viewportData)
);

// Get viewport
const data = await redis.get('page:123:viewport:user-789');
const viewport = JSON.parse(data);

// Check if viewport exists (user recently active)
const exists = await redis.exists('page:123:viewport:user-789');
```

**TTL:** 30 seconds (auto-expire if user stops sending updates)

---

## Backend Implementation Details

### Follow Start Handler

```javascript
socket.on(CLIENT_EVENTS.PAGE_FOLLOW_START, async (data) => {
  try {
    const { pageId, targetUserId } = data;
    
    // 1. Validate request
    if (!socket.currentPageId || socket.currentPageId !== pageId) {
      socket.emit(SERVER_EVENTS.PAGE_FOLLOW_ERROR, {
        operation: 'follow_start',
        message: 'Not joined to this page',
        code: 'NOT_IN_PAGE'
      });
      return;
    }
    
    // 2. Check if target user is in the page
    const userKey = `page:${pageId}:users`;
    const targetUserData = await redis.hget(userKey, targetUserId);
    
    if (!targetUserData) {
      socket.emit(SERVER_EVENTS.PAGE_FOLLOW_ERROR, {
        operation: 'follow_start',
        message: 'Target user not found in page',
        code: 'USER_NOT_FOUND'
      });
      return;
    }
    
    const targetUser = JSON.parse(targetUserData);
    
    // 3. Check if already following
    const followKey = `page:${pageId}:follows`;
    const existingFollow = await redis.hget(followKey, socket.userId);
    
    if (existingFollow === targetUserId) {
      socket.emit(SERVER_EVENTS.PAGE_FOLLOW_ERROR, {
        operation: 'follow_start',
        message: 'Already following this user',
        code: 'ALREADY_FOLLOWING'
      });
      return;
    }
    
    // 4. Store follow relationship
    await redis.hset(followKey, socket.userId, targetUserId);
    
    // 5. Get current viewport of target user
    const viewportKey = `page:${pageId}:viewport:${targetUserId}`;
    const viewportData = await redis.get(viewportKey);
    
    let initialViewport = null;
    if (viewportData) {
      const parsed = JSON.parse(viewportData);
      initialViewport = parsed.viewport;
    }
    
    // 6. Send confirmation to follower
    socket.emit(SERVER_EVENTS.PAGE_FOLLOW_STARTED, {
      pageId,
      followedUserId: targetUserId,
      followedUserName: targetUser.name,
      initialViewport,
      timestamp: new Date().toISOString()
    });
    
    console.log(`✅ User ${socket.userId} started following ${targetUserId}`);
    
  } catch (error) {
    console.error('❌ Follow start error:', error);
    socket.emit(SERVER_EVENTS.PAGE_FOLLOW_ERROR, {
      operation: 'follow_start',
      message: 'Failed to start following',
      code: 'INTERNAL_ERROR'
    });
  }
});
```

---

### Follow Stop Handler

```javascript
socket.on(CLIENT_EVENTS.PAGE_FOLLOW_STOP, async (data) => {
  try {
    const { pageId } = data;
    
    if (!socket.currentPageId || socket.currentPageId !== pageId) {
      return;
    }
    
    // Remove follow relationship
    const followKey = `page:${pageId}:follows`;
    await redis.hdel(followKey, socket.userId);
    
    // Confirm to user
    socket.emit(SERVER_EVENTS.PAGE_FOLLOW_STOPPED, {
      pageId,
      reason: 'user_action',
      timestamp: new Date().toISOString()
    });
    
    console.log(`✅ User ${socket.userId} stopped following`);
    
  } catch (error) {
    console.error('❌ Follow stop error:', error);
  }
});
```

---

### Viewport Update Handler

```javascript
// Rate limiting map
const viewportRateLimits = new Map();

socket.on(CLIENT_EVENTS.PAGE_VIEWPORT_UPDATE, async (data) => {
  try {
    const { pageId, viewport } = data;
    
    if (!socket.currentPageId || socket.currentPageId !== pageId) {
      return;
    }
    
    // 1. Rate limiting (max 10 updates per second per user)
    const rateLimitKey = `${socket.userId}:viewport`;
    const now = Date.now();
    const lastUpdate = viewportRateLimits.get(rateLimitKey) || 0;
    
    if (now - lastUpdate < 100) {
      return; // Skip this update
    }
    
    viewportRateLimits.set(rateLimitKey, now);
    
    // 2. Validate viewport data
    if (!viewport || typeof viewport.scrollX !== 'number') {
      return;
    }
    
    // 3. Store viewport in Redis with TTL
    const viewportKey = `page:${pageId}:viewport:${socket.userId}`;
    const viewportData = {
      userId: socket.userId,
      viewport,
      timestamp: new Date().toISOString()
    };
    
    await redis.setex(
      viewportKey,
      30,  // 30 second TTL
      JSON.stringify(viewportData)
    );
    
    // 4. Find users following this user
    const followKey = `page:${pageId}:follows`;
    const allFollows = await redis.hgetall(followKey);
    
    const followers = Object.entries(allFollows)
      .filter(([_, followed]) => followed === socket.userId)
      .map(([follower, _]) => follower);
    
    if (followers.length === 0) {
      return; // No one is following
    }
    
    // 5. Get user info
    const userKey = `page:${pageId}:users`;
    const userData = await redis.hget(userKey, socket.userId);
    const user = JSON.parse(userData);
    
    // 6. Broadcast to followers only
    followers.forEach(followerId => {
      const followerSockets = Array.from(io.sockets.sockets.values())
        .filter(s => s.userId === followerId && s.currentPageId === pageId);
      
      followerSockets.forEach(followerSocket => {
        followerSocket.emit(SERVER_EVENTS.PAGE_VIEWPORT_UPDATED, {
          pageId,
          userId: socket.userId,
          userName: user.name,
          viewport,
          timestamp: new Date().toISOString()
        });
      });
    });
    
  } catch (error) {
    console.error('❌ Viewport update error:', error);
  }
});
```

---

### Cleanup on Disconnect

```javascript
socket.on('disconnect', async () => {
  if (socket.currentPageId) {
    const pageId = socket.currentPageId;
    
    // 1. Remove follow relationships where this user is the follower
    const followKey = `page:${pageId}:follows`;
    await redis.hdel(followKey, socket.userId);
    
    // 2. Notify users who were following this user
    const allFollows = await redis.hgetall(followKey);
    const followersOfThisUser = Object.entries(allFollows)
      .filter(([_, followed]) => followed === socket.userId)
      .map(([follower, _]) => follower);
    
    followersOfThisUser.forEach(followerId => {
      const followerSockets = Array.from(io.sockets.sockets.values())
        .filter(s => s.userId === followerId && s.currentPageId === pageId);
      
      followerSockets.forEach(followerSocket => {
        followerSocket.emit(SERVER_EVENTS.PAGE_FOLLOW_STOPPED, {
          pageId,
          reason: 'target_left',
          timestamp: new Date().toISOString()
        });
      });
      
      // Remove their follow relationship
      redis.hdel(followKey, followerId);
    });
    
    // 3. Delete viewport data
    const viewportKey = `page:${pageId}:viewport:${socket.userId}`;
    await redis.del(viewportKey);
  }
});
```

---

## Frontend Integration

### WebSocket Client Methods

```dart
/// Start following a user
void startFollowing({
  required String pageId,
  required String targetUserId,
}) {
  if (_socket?.connected != true) return;
  
  _socket!.emit('page:follow:start', {
    'pageId': pageId,
    'targetUserId': targetUserId,
  });
}

/// Stop following current user
void stopFollowing({required String pageId}) {
  if (_socket?.connected != true) return;
  
  _socket!.emit('page:follow:stop', {
    'pageId': pageId,
  });
}

/// Send viewport update (throttled on client)
void sendViewportUpdate({
  required String pageId,
  required ViewportData viewport,
}) {
  if (_socket?.connected != true) return;
  
  _socket!.emit('page:viewport:update', {
    'pageId': pageId,
    'viewport': {
      'scrollX': viewport.scrollX,
      'scrollY': viewport.scrollY,
      'zoom': viewport.zoom,
      'centerX': viewport.centerX,
      'centerY': viewport.centerY,
      'width': viewport.width,
      'height': viewport.height,
    },
  });
}
```

---

## Security Considerations

### 1. Permission Checks
- Both follower and followed must have access to the same page
- No additional permission check needed (page access is sufficient)

### 2. Rate Limiting
- Viewport updates: Max 10 per second per user
- Follow/unfollow actions: Max 5 per minute per user (optional)

### 3. Data Validation
- Validate viewport data ranges (zoom: 0.1-5.0, coordinates: reasonable bounds)
- Sanitize user IDs and page IDs
- Check for valid JSON structure

### 4. Privacy
- Only broadcast viewport to users in the same page
- Only send viewport to actual followers
- Don't expose follow relationships to non-participants

---

## Performance Optimization

### 1. Throttling
- Client-side: Batch viewport updates to max 10/second
- Server-side: Skip rapid updates if rate limit exceeded

### 2. Redis Optimization
- Use TTL for auto-cleanup (viewport: 30s)
- Use hash for efficient follow relationship lookups
- Minimal data storage (only essential viewport info)

### 3. Broadcasting Optimization
- Only broadcast to actual followers (not entire page)
- Use targeted socket.emit instead of broadcast
- Skip viewport broadcast if no followers

### 4. Memory Management
- Clean up rate limit maps periodically
- Remove expired entries from in-memory caches
- Rely on Redis TTL for automatic cleanup

---

## Testing API

### WebSocket Test Script (Node.js)

```javascript
const io = require('socket.io-client');

const socket = io('http://localhost:3000', {
  auth: { token: 'your-jwt-token' },
  transports: ['websocket']
});

socket.on('connect', () => {
  console.log('Connected');
  
  // Join page
  socket.emit('page:join', { pageId: 'test-page' });
});

socket.on('page:joined', (data) => {
  console.log('Joined page:', data);
  
  // Start following user
  socket.emit('page:follow:start', {
    pageId: 'test-page',
    targetUserId: 'target-user-id'
  });
});

socket.on('page:follow:started', (data) => {
  console.log('Follow started:', data);
});

socket.on('page:viewport:updated', (data) => {
  console.log('Viewport update:', data.viewport);
});

socket.on('page:follow:error', (error) => {
  console.error('Follow error:', error);
});
```

---

## Summary

This API specification provides:
- ✅ Complete WebSocket event definitions
- ✅ Redis data structure specifications
- ✅ Backend handler implementations
- ✅ Frontend integration methods
- ✅ Security and performance guidelines
- ✅ Testing scripts

All implementations should follow this specification for consistency and interoperability.
