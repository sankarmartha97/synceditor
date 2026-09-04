// WebSocket event names

// Client -> Server events
const CLIENT_EVENTS = {
  // Canvas events (legacy)
  CANVAS_JOIN: 'canvas:join',
  CANVAS_LEAVE: 'canvas:leave',
  WIDGET_ADD: 'widget:add',
  WIDGET_UPDATE: 'widget:update',
  WIDGET_DELETE: 'widget:delete',
  WIDGET_MOVE: 'widget:move',
  CURSOR_MOVE: 'cursor:move',
  CURSOR_HIDE: 'cursor:hide',
  
  // Page events (new)
  PAGE_JOIN: 'page:join',
  PAGE_LEAVE: 'page:leave',
  PAGE_PATCH: 'page:patch',           // Send JSON Patch
  PAGE_CURSOR: 'page:cursor',         // Cursor position
  PAGE_SELECTION: 'page:selection',   // Widget selection
  
  // Comment events
  COMMENT_CREATE: 'comment:create',   // Create a comment
  COMMENT_UPDATE: 'comment:update',   // Update a comment
  COMMENT_DELETE: 'comment:delete',   // Delete a comment
  COMMENT_RESOLVE: 'comment:resolve', // Resolve/unresolve a comment
  
  // Undo/Redo events
  PAGE_UNDO: 'page:undo',             // Request undo
  PAGE_REDO: 'page:redo',             // Request redo
  
  // Follow events
  PAGE_FOLLOW_START: 'page:follow:start',   // Start following a user
  PAGE_FOLLOW_STOP: 'page:follow:stop',     // Stop following
  PAGE_VIEWPORT_UPDATE: 'page:viewport:update', // Send viewport position
};

// Server -> Client events
const SERVER_EVENTS = {
  // Canvas events (legacy)
  CANVAS_JOINED: 'canvas:joined',
  CANVAS_LEFT: 'canvas:left',
  WIDGET_ADDED: 'widget:added',
  WIDGET_UPDATED: 'widget:updated',
  WIDGET_DELETED: 'widget:deleted',
  WIDGET_MOVED: 'widget:moved',
  USER_JOINED: 'user:joined',
  USER_LEFT: 'user:left',
  CURSOR_UPDATED: 'cursor:updated',
  CURSOR_HIDDEN: 'cursor:hidden',
  SYNC_ERROR: 'sync:error',
  CONNECTION_ERROR: 'connection:error',
  
  // Page events (new)
  PAGE_JOINED: 'page:joined',
  PAGE_LEFT: 'page:left',
  PAGE_PATCH_APPLIED: 'page:patch:applied',     // Patch applied successfully
  PAGE_PATCH_RECEIVED: 'page:patch:received',   // Receive patch from another user
  PAGE_PATCH_ERROR: 'page:patch:error',         // Patch application failed
  PAGE_CONFLICT: 'page:conflict',               // Conflict detected
  PAGE_CURSOR_UPDATED: 'page:cursor:updated',   // Other user's cursor
  PAGE_SELECTION_UPDATED: 'page:selection:updated', // Other user's selection
  PAGE_USER_JOINED: 'page:user:joined',         // User joined page
  PAGE_USER_LEFT: 'page:user:left',             // User left page
  PAGE_SYNC_COMPLETE: 'page:sync:complete',     // Initial sync done
  
  // Comment events
  COMMENT_CREATED: 'comment:created',           // Comment created
  COMMENT_UPDATED: 'comment:updated',           // Comment updated
  COMMENT_DELETED: 'comment:deleted',           // Comment deleted
  COMMENT_RESOLVED: 'comment:resolved',         // Comment resolved/reopened
  COMMENT_MENTION: 'comment:mention',           // User mentioned in comment
  
  // Undo/Redo events
  PAGE_UNDO_APPLIED: 'page:undo:applied',       // Undo successfully applied
  PAGE_REDO_APPLIED: 'page:redo:applied',       // Redo successfully applied
  PAGE_UNDO_ERROR: 'page:undo:error',           // Undo failed
  PAGE_REDO_ERROR: 'page:redo:error',           // Redo failed
  PAGE_UNDO_STATE: 'page:undo:state',           // Undo/redo availability state
  
  // Follow events
  PAGE_FOLLOW_STARTED: 'page:follow:started',   // Follow started confirmation
  PAGE_FOLLOW_STOPPED: 'page:follow:stopped',   // Follow stopped confirmation
  PAGE_VIEWPORT_UPDATED: 'page:viewport:updated', // Viewport update from followed user
  PAGE_FOLLOW_ERROR: 'page:follow:error',       // Follow operation failed
};

module.exports = { CLIENT_EVENTS, SERVER_EVENTS };
