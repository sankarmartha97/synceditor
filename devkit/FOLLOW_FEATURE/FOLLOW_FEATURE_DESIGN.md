# Follow Feature Design Document

## Overview
Implement a "Follow User" feature similar to Figma, allowing users to follow another user's viewport and cursor position in real-time during collaborative editing.

## User Experience Flow

### 1. Following a User
1. User sees active users list in the page editor
2. User clicks "Follow" button next to another user's name
3. Canvas viewport automatically pans/zooms to match the followed user's view
4. Visual indicator shows "Following [Username]"
5. Cursor movements are synchronized in real-time

### 2. During Follow Mode
- Canvas automatically follows the user's viewport changes
- Scroll position syncs continuously
- Zoom level syncs continuously
- User's own edits are disabled (view-only while following)
- Visual border/overlay indicates follow mode is active

### 3. Exiting Follow Mode
- User clicks "Unfollow" button
- User manually interacts with canvas (pan, zoom, or click)
- Followed user leaves the page
- Follow mode automatically exits

## Technical Architecture

### Backend Changes

#### 1. WebSocket Events (events.js)

**New Client Events:**
```javascript
PAGE_FOLLOW_START: 'page:follow:start'    // Start following a user
PAGE_FOLLOW_STOP: 'page:follow:stop'      // Stop following a user
PAGE_VIEWPORT_UPDATE: 'page:viewport:update' // Send viewport position/zoom
```

**New Server Events:**
```javascript
PAGE_FOLLOW_STARTED: 'page:follow:started'  // Follow started confirmation
PAGE_FOLLOW_STOPPED: 'page:follow:stopped'  // Follow stopped confirmation
PAGE_VIEWPORT_UPDATED: 'page:viewport:updated' // Receive viewport from followed user
PAGE_FOLLOW_ERROR: 'page:follow:error'      // Follow operation error
```

#### 2. WebSocket Handler (page.handler.js)

**Follow State Management:**
```javascript
// Store in Redis
page:{pageId}:follows -> Map<followerId, followedUserId>

// Follow start handler
socket.on('page:follow:start', async (data) => {
  const { pageId, targetUserId } = data;
  
  // Validate target user is in the page
  // Store follow relationship in Redis
  // Get current viewport of target user
  // Send initial viewport to follower
  // Notify both users
});

// Follow stop handler
socket.on('page:follow:stop', async (data) => {
  const { pageId } = data;
  
  // Remove follow relationship from Redis
  // Notify both users
});

// Viewport update handler (existing cursor logic extended)
socket.on('page:viewport:update', async (data) => {
  const { pageId, viewport } = data;
  // viewport: { x, y, zoom, scrollX, scrollY }
  
  // Store in Redis with TTL
  // Broadcast to followers only
  // Check who is following this user
  // Send viewport update to those users
});
```

#### 3. Data Structure

**Viewport Data:**
```javascript
{
  userId: "user123",
  viewport: {
    scrollX: 100,      // Canvas scroll X position
    scrollY: 200,      // Canvas scroll Y position
    zoom: 1.0,         // Zoom level
    centerX: 500,      // Viewport center X
    centerY: 300,      // Viewport center Y
    width: 1920,       // Viewport width
    height: 1080       // Viewport height
  },
  timestamp: "2024-01-01T00:00:00Z"
}
```

**Follow Relationship:**
```javascript
{
  followerId: "user123",
  followedUserId: "user456",
  pageId: "page789",
  startedAt: "2024-01-01T00:00:00Z"
}
```

### Frontend Changes

#### 1. Page State (page_state.dart)

**New State Properties:**
```dart
// Following state
final String? followingUserId;      // User ID being followed
final bool isFollowing;              // Currently in follow mode
final ViewportData? followedViewport; // Last viewport from followed user

// New copyWith parameters
String? followingUserId;
bool? isFollowing;
ViewportData? followedViewport;
```

#### 2. Page Bloc Events (page_event.dart)

**New Events:**
```dart
// Start following a user
class StartFollowingUser extends PageEvent {
  final String userId;
  final String userName;
  
  StartFollowingUser({required this.userId, required this.userName});
}

// Stop following
class StopFollowingUser extends PageEvent {
  StopFollowingUser();
}

// Receive viewport update from followed user
class FollowedUserViewportUpdated extends PageEvent {
  final ViewportData viewport;
  
  FollowedUserViewportUpdated({required this.viewport});
}

// Follow mode exited (user interaction)
class FollowModeExitedByUser extends PageEvent {
  FollowModeExitedByUser();
}
```

#### 3. WebSocket Client (page_websocket_client.dart)

**New Stream Controllers:**
```dart
final _followStartedController = StreamController<FollowStartedEvent>.broadcast();
final _followStoppedController = StreamController<FollowStoppedEvent>.broadcast();
final _viewportUpdatedController = StreamController<ViewportUpdateEvent>.broadcast();

// Public streams
Stream<FollowStartedEvent> get followStartedEvents;
Stream<FollowStoppedEvent> get followStoppedEvents;
Stream<ViewportUpdateEvent> get viewportUpdatedEvents;
```

**New Methods:**
```dart
// Start following a user
void startFollowing({
  required String pageId,
  required String targetUserId,
});

// Stop following
void stopFollowing({required String pageId});

// Send viewport updates (throttled)
void sendViewportUpdate({
  required String pageId,
  required ViewportData viewport,
});
```

**Event Listeners:**
```dart
socket.on('page:follow:started', (data) {
  // Emit to stream
});

socket.on('page:follow:stopped', (data) {
  // Emit to stream
});

socket.on('page:viewport:updated', (data) {
  // Parse viewport data
  // Emit to stream
});
```

#### 4. Active Users List UI (active_users_list.dart)

**Enhanced User Tile:**
```dart
Widget _buildUserTile(BuildContext context, ActiveUser user, bool isCurrentUser) {
  return Container(
    // ... existing code ...
    child: Row(
      children: [
        _buildAvatar(user, isCurrentUser),
        Expanded(child: _buildUserInfo(user, isCurrentUser)),
        
        // NEW: Follow/Unfollow button
        if (!isCurrentUser && onFollowUser != null)
          _buildFollowButton(context, user),
      ],
    ),
  );
}

Widget _buildFollowButton(BuildContext context, ActiveUser user) {
  final isFollowing = followingUserId == user.userId;
  
  return IconButton(
    icon: Icon(
      isFollowing ? Icons.visibility_off : Icons.visibility,
      size: 20,
    ),
    onPressed: () => onFollowUser?.call(user.userId, !isFollowing),
    tooltip: isFollowing ? 'Stop following' : 'Follow ${user.name}',
    color: isFollowing ? Colors.blue : Colors.grey[600],
  );
}
```

**New Properties:**
```dart
final String? followingUserId;          // Currently following this user
final Function(String, bool)? onFollowUser; // Callback(userId, shouldFollow)
```

#### 5. Page Canvas View (page_canvas_view.dart)

**Follow Mode Overlay:**
```dart
Widget _buildFollowModeOverlay() {
  if (!isFollowing || followingUserId == null) return SizedBox.shrink();
  
  return Positioned(
    top: 16,
    left: 0,
    right: 0,
    child: Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Following ${followedUserName}',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 16),
            TextButton(
              onPressed: onStopFollowing,
              child: Text('Stop', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ),
  );
}
```

**Follow Mode Border:**
```dart
Widget build(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      border: isFollowing 
        ? Border.all(color: Colors.blue, width: 3)
        : null,
    ),
    child: Stack(
      children: [
        _buildCanvas(),
        if (isFollowing) _buildFollowModeOverlay(),
      ],
    ),
  );
}
```

**Viewport Sync Logic:**
```dart
void _syncViewportWithFollowedUser(ViewportData viewport) {
  if (!isFollowing) return;
  
  // Animate canvas to match viewport
  final targetScrollX = viewport.scrollX;
  final targetScrollY = viewport.scrollY;
  final targetZoom = viewport.zoom;
  
  // Use animation controller for smooth transition
  _animateToViewport(
    targetScrollX,
    targetScrollY,
    targetZoom,
    duration: Duration(milliseconds: 300),
  );
}
```

**Disable Interaction in Follow Mode:**
```dart
Widget _buildCanvas() {
  return GestureDetector(
    onPanStart: isFollowing ? _handleFollowModeInteraction : _handlePanStart,
    onPanUpdate: isFollowing ? _handleFollowModeInteraction : _handlePanUpdate,
    onScaleStart: isFollowing ? _handleFollowModeInteraction : _handleScaleStart,
    // ...
  );
}

void _handleFollowModeInteraction(_) {
  // User interacted with canvas - exit follow mode
  context.read<PageBloc>().add(FollowModeExitedByUser());
}
```

#### 6. Viewport Update Throttling

**Throttle viewport broadcasts:**
```dart
Timer? _viewportUpdateTimer;
ViewportData? _pendingViewport;

void _scheduleViewportUpdate(ViewportData viewport) {
  _pendingViewport = viewport;
  
  if (_viewportUpdateTimer == null || !_viewportUpdateTimer!.isActive) {
    _viewportUpdateTimer = Timer(Duration(milliseconds: 100), () {
      if (_pendingViewport != null) {
        _wsClient.sendViewportUpdate(
          pageId: currentPageId,
          viewport: _pendingViewport!,
        );
        _pendingViewport = null;
      }
    });
  }
}
```

## Data Models

### ViewportData
```dart
class ViewportData {
  final double scrollX;
  final double scrollY;
  final double zoom;
  final double centerX;
  final double centerY;
  final double width;
  final double height;
  final DateTime timestamp;
  
  ViewportData({
    required this.scrollX,
    required this.scrollY,
    required this.zoom,
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.height,
    required this.timestamp,
  });
  
  factory ViewportData.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

## Implementation Phases

### Phase 1: Backend Foundation
- Add new WebSocket events to events.js
- Implement follow start/stop handlers
- Implement viewport update handler with Redis storage
- Add follow state management in Redis
- Test with WebSocket client tools

### Phase 2: Frontend State Management
- Add follow state to PageState
- Create new PageEvent classes
- Implement event handlers in PageBloc
- Add WebSocket stream controllers and listeners
- Wire up WebSocket events to Bloc events

### Phase 3: UI Components
- Add follow button to ActiveUsersList
- Create follow mode overlay component
- Add visual indicators (border, badge)
- Implement follow/unfollow callbacks

### Phase 4: Viewport Synchronization
- Implement viewport update broadcasting
- Add throttling for performance
- Create smooth animation for viewport transitions
- Handle follow mode interaction detection
- Auto-exit on user interaction

### Phase 5: Testing & Polish
- Test with multiple users
- Test network latency scenarios
- Test edge cases (user leaves, connection drops)
- Add loading states and error handling
- Performance optimization

## Edge Cases & Error Handling

### 1. Followed User Leaves Page
- Automatically exit follow mode
- Show notification: "[User] has left the page"
- Return to normal editing mode

### 2. Connection Lost
- Exit follow mode
- Show reconnection message
- Don't auto-resume follow on reconnect

### 3. Permission Changes
- If followed user loses edit permission, continue following
- If follower loses access to page, disconnect

### 4. Rapid Viewport Changes
- Throttle updates to prevent performance issues
- Use interpolation for smooth animations
- Skip updates if they arrive faster than animation speed

### 5. Circular Following
- User A follows User B, User B follows User A
- Allow this - each user sees the other's viewport
- No infinite loop since it's one-way data flow

### 6. Following Yourself
- Disable follow button for current user
- If somehow triggered, ignore and show error

## Performance Considerations

1. **Viewport Update Frequency**: Throttle to max 10 updates/second
2. **Redis TTL**: Viewport data expires after 30 seconds
3. **Animation**: Use CSS transforms for smooth transitions
4. **Network**: Compress viewport data, only send when changed
5. **Memory**: Clean up old follow relationships on disconnect

## Security Considerations

1. **Permission Check**: Verify both users have access to page
2. **Rate Limiting**: Prevent spam follow/unfollow
3. **Validation**: Validate viewport data ranges
4. **Privacy**: Don't expose viewport to users without page access

## Visual Design

### Follow Button States
- **Not Following**: Eye icon (gray)
- **Following**: Eye icon (blue, filled)
- **Hover**: Tooltip with "Follow [Name]" or "Stop following"

### Follow Mode Indicator
- **Top Banner**: Blue background, white text
- **Border**: 3px solid blue around canvas
- **Animation**: Smooth fade in/out

### User Avatar Highlight
- **Following**: Blue glow around avatar
- **Being Followed**: Green glow around avatar (optional)

## Future Enhancements

1. **Multi-Follow**: Follow multiple users with picture-in-picture
2. **Follow History**: "Jump to" previous followed viewports
3. **Follow Notification**: Notify user when someone follows them
4. **Follow Recording**: Record and replay follow sessions
5. **Smart Follow**: AI suggests interesting areas to follow
6. **Follow with Audio**: Add voice chat during follow mode

---

## Summary

This follow feature will significantly enhance real-time collaboration by allowing users to:
- See exactly what their teammates are working on
- Learn from each other by watching viewport movements
- Coordinate complex editing tasks more effectively
- Provide better remote assistance and feedback

The implementation follows the existing architecture patterns and integrates seamlessly with the current WebSocket-based synchronization system.
