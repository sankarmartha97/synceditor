# Follow Feature Implementation Checklist

## Phase 1: Backend Foundation ⏳

### WebSocket Events Definition
- [ ] Add new client events to `backend/src-js/websocket/events.js`
  - [ ] `PAGE_FOLLOW_START: 'page:follow:start'`
  - [ ] `PAGE_FOLLOW_STOP: 'page:follow:stop'`
  - [ ] `PAGE_VIEWPORT_UPDATE: 'page:viewport:update'`
- [ ] Add new server events to `backend/src-js/websocket/events.js`
  - [ ] `PAGE_FOLLOW_STARTED: 'page:follow:started'`
  - [ ] `PAGE_FOLLOW_STOPPED: 'page:follow:stopped'`
  - [ ] `PAGE_VIEWPORT_UPDATED: 'page:viewport:updated'`
  - [ ] `PAGE_FOLLOW_ERROR: 'page:follow:error'`

### WebSocket Handlers
- [ ] Implement `page:follow:start` handler in `backend/src-js/websocket/page.handler.js`
  - [ ] Validate both users are in the same page
  - [ ] Store follow relationship in Redis
  - [ ] Get current viewport of target user
  - [ ] Send initial viewport to follower
  - [ ] Emit confirmation events
- [ ] Implement `page:follow:stop` handler
  - [ ] Remove follow relationship from Redis
  - [ ] Emit stop confirmation
- [ ] Implement `page:viewport:update` handler
  - [ ] Store viewport in Redis with TTL (30s)
  - [ ] Query Redis for followers
  - [ ] Broadcast viewport to followers only
  - [ ] Throttle updates (max 10/second per user)

### Redis Data Structures
- [ ] Define follow relationship storage
  - [ ] Key: `page:{pageId}:follows`
  - [ ] Type: Hash
  - [ ] Value: `{followerId: followedUserId}`
- [ ] Define viewport storage
  - [ ] Key: `page:{pageId}:viewport:{userId}`
  - [ ] Type: String (JSON)
  - [ ] TTL: 30 seconds
  - [ ] Value: ViewportData JSON

### Testing
- [ ] Test follow start/stop with WebSocket test client
- [ ] Test viewport updates with multiple users
- [ ] Test Redis data expiration
- [ ] Test edge cases (user leaves, disconnects)

---

## Phase 2: Frontend State Management ⏳

### Data Models
- [ ] Create `ViewportData` model in `frontend/lib/core/models/`
  - [ ] scrollX, scrollY properties
  - [ ] zoom property
  - [ ] centerX, centerY properties
  - [ ] width, height properties
  - [ ] timestamp property
  - [ ] fromJson/toJson methods

### Page State Updates
- [ ] Update `frontend/lib/features/page/bloc/page_state.dart`
  - [ ] Add `followingUserId` property
  - [ ] Add `isFollowing` property
  - [ ] Add `followedViewport` property
  - [ ] Add `followingUserName` property
  - [ ] Update `copyWith` method
  - [ ] Update `props` getter

### Page Events
- [ ] Create new events in `frontend/lib/features/page/bloc/page_event.dart`
  - [ ] `StartFollowingUser` event
  - [ ] `StopFollowingUser` event
  - [ ] `FollowedUserViewportUpdated` event
  - [ ] `FollowModeExitedByUser` event

### Page Bloc Logic
- [ ] Implement event handlers in `frontend/lib/features/page/bloc/page_bloc.dart`
  - [ ] Handle `StartFollowingUser`
    - [ ] Send WebSocket follow start
    - [ ] Update state with followingUserId
    - [ ] Set isFollowing = true
  - [ ] Handle `StopFollowingUser`
    - [ ] Send WebSocket follow stop
    - [ ] Clear following state
    - [ ] Set isFollowing = false
  - [ ] Handle `FollowedUserViewportUpdated`
    - [ ] Update followedViewport in state
    - [ ] Trigger viewport sync
  - [ ] Handle `FollowModeExitedByUser`
    - [ ] Exit follow mode
    - [ ] Send stop follow WebSocket event

### WebSocket Client Updates
- [ ] Update `frontend/lib/core/api/page_websocket_client.dart`
  - [ ] Add stream controllers
    - [ ] `_followStartedController`
    - [ ] `_followStoppedController`
    - [ ] `_viewportUpdatedController`
  - [ ] Add public streams
  - [ ] Add WebSocket event listeners
    - [ ] Listen to `page:follow:started`
    - [ ] Listen to `page:follow:stopped`
    - [ ] Listen to `page:viewport:updated`
  - [ ] Add methods
    - [ ] `startFollowing(pageId, targetUserId)`
    - [ ] `stopFollowing(pageId)`
    - [ ] `sendViewportUpdate(pageId, viewport)`

### Event Classes
- [ ] Create event classes in `page_websocket_client.dart`
  - [ ] `FollowStartedEvent`
  - [ ] `FollowStoppedEvent`
  - [ ] `ViewportUpdateEvent`

### Testing
- [ ] Test state transitions
- [ ] Test WebSocket event flow
- [ ] Test Bloc event handling
- [ ] Test stream subscriptions

---

## Phase 3: UI Components ⏳

### Active Users List Updates
- [ ] Update `frontend/lib/features/page/widgets/active_users_list.dart`
  - [ ] Add `followingUserId` property
  - [ ] Add `onFollowUser` callback
  - [ ] Create `_buildFollowButton` method
  - [ ] Update `_buildUserTile` to include follow button
  - [ ] Add follow/unfollow icons
  - [ ] Add tooltips
  - [ ] Visual indicator for followed user (highlight)

### Follow Mode Overlay
- [ ] Create follow mode banner component
  - [ ] Blue background with white text
  - [ ] Show "Following [Username]"
  - [ ] Add eye icon
  - [ ] Add "Stop" button
  - [ ] Center position at top of canvas
  - [ ] Fade in/out animation

### Follow Mode Visual Indicators
- [ ] Add blue border around canvas when following
  - [ ] 3px solid blue border
  - [ ] Smooth transition
- [ ] Add glow effect to followed user's avatar
  - [ ] Blue glow/shadow
  - [ ] Animation when follow starts

### Follow Button States
- [ ] Implement button state styling
  - [ ] Default: Gray eye icon
  - [ ] Following: Blue filled eye icon
  - [ ] Hover: Show tooltip
  - [ ] Disabled: Gray out for current user

### Testing
- [ ] Test UI rendering in different states
- [ ] Test button interactions
- [ ] Test visual indicators
- [ ] Test responsive design

---

## Phase 4: Viewport Synchronization ⏳

### Canvas Controller Updates
- [ ] Update `frontend/lib/features/page/views/page_canvas_view.dart`
  - [ ] Add follow mode properties
  - [ ] Implement `_syncViewportWithFollowedUser` method
  - [ ] Create animation controller for smooth transitions
  - [ ] Implement `_animateToViewport` method

### Interaction Handling
- [ ] Detect user interaction in follow mode
  - [ ] Override `onPanStart` when following
  - [ ] Override `onPanUpdate` when following
  - [ ] Override `onScaleStart` when following
  - [ ] Trigger `FollowModeExitedByUser` event
- [ ] Disable widget selection in follow mode
- [ ] Show cursor but disable editing

### Viewport Broadcasting
- [ ] Implement viewport update detection
  - [ ] Listen to scroll changes
  - [ ] Listen to zoom changes
  - [ ] Calculate viewport bounds
- [ ] Create throttling mechanism
  - [ ] Max 10 updates per second
  - [ ] Use Timer for batching
  - [ ] Store pending viewport
- [ ] Send viewport updates via WebSocket
  - [ ] Only when not following
  - [ ] Include all viewport data

### Smooth Animations
- [ ] Implement smooth viewport transitions
  - [ ] Use AnimationController
  - [ ] Duration: 300ms
  - [ ] Easing: easeInOut
  - [ ] Animate scroll position
  - [ ] Animate zoom level

### Performance Optimization
- [ ] Debounce viewport updates
- [ ] Skip animation if viewport unchanged
- [ ] Batch multiple updates
- [ ] Use transform instead of layout changes

### Testing
- [ ] Test viewport sync with 2 users
- [ ] Test viewport sync with 3+ users
- [ ] Test animation smoothness
- [ ] Test performance with rapid changes
- [ ] Test interaction detection

---

## Phase 5: Testing & Polish ⏳

### Functional Testing
- [ ] Test basic follow/unfollow flow
- [ ] Test with multiple simultaneous followers
- [ ] Test viewport synchronization accuracy
- [ ] Test animation performance
- [ ] Test with different zoom levels
- [ ] Test with different screen sizes

### Edge Case Testing
- [ ] Test followed user leaves page
  - [ ] Verify auto-exit from follow mode
  - [ ] Show appropriate notification
- [ ] Test connection loss during follow
  - [ ] Graceful degradation
  - [ ] Don't resume on reconnect
- [ ] Test rapid follow/unfollow
  - [ ] No race conditions
  - [ ] State consistency
- [ ] Test circular following (A follows B, B follows A)
  - [ ] Ensure no infinite loops
  - [ ] Both users see each other's viewport
- [ ] Test following yourself (should be prevented)
  - [ ] Button disabled
  - [ ] Error message if triggered

### Performance Testing
- [ ] Measure viewport update latency
- [ ] Test with slow network connection
- [ ] Test with 5+ active users
- [ ] Monitor memory usage
- [ ] Check for memory leaks
- [ ] Verify Redis cleanup

### Error Handling
- [ ] Handle WebSocket disconnect during follow
- [ ] Handle followed user loses permissions
- [ ] Handle invalid viewport data
- [ ] Handle Redis connection errors
- [ ] Show user-friendly error messages

### UI/UX Polish
- [ ] Add loading states
- [ ] Add success notifications
- [ ] Improve button hover states
- [ ] Add keyboard shortcuts (optional)
  - [ ] ESC to exit follow mode
  - [ ] F to toggle follow on selected user
- [ ] Add sound effects (optional)
- [ ] Improve animations
- [ ] Test accessibility

### Documentation
- [ ] Update API documentation
- [ ] Add inline code comments
- [ ] Create user guide
- [ ] Add feature to README
- [ ] Record demo video

### Code Review
- [ ] Backend code review
- [ ] Frontend code review
- [ ] Performance review
- [ ] Security review

---

## Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] Code reviewed and approved
- [ ] Documentation complete
- [ ] Demo prepared

### Deployment Steps
- [ ] Merge to main branch
- [ ] Deploy backend changes
- [ ] Deploy frontend changes
- [ ] Test in production
- [ ] Monitor for errors
- [ ] Gather user feedback

### Post-Deployment
- [ ] Monitor performance metrics
- [ ] Check error logs
- [ ] Collect user feedback
- [ ] Plan improvements

---

## Future Enhancements

### Phase 6 (Optional)
- [ ] Multi-follow with picture-in-picture
- [ ] Follow history and replay
- [ ] Follow notifications
- [ ] Follow recording
- [ ] Smart follow suggestions
- [ ] Voice chat during follow mode

---

## Progress Tracking

**Overall Progress:** 0/5 Phases Complete

- ⏳ Phase 1: Backend Foundation - Not Started
- ⏳ Phase 2: Frontend State Management - Not Started
- ⏳ Phase 3: UI Components - Not Started
- ⏳ Phase 4: Viewport Synchronization - Not Started
- ⏳ Phase 5: Testing & Polish - Not Started

**Last Updated:** September 1, 2026
