// ============================================
// ADD THIS CODE TO: backend/src-js/websocket/page.handler.js
// Location: After the require statements, before setupPageHandlers function
// ============================================

// RATE LIMITING FOR UNDO/REDO
const undoRedoRateLimits = new Map();

/**
 * Check if user can perform undo/redo (rate limiting)
 * @param {string} userId - User ID
 * @param {string} action - 'undo' or 'redo'
 * @returns {boolean} true if allowed, false if rate limited
 */
function checkRateLimit(userId, action) {
  const key = `${userId}:${action}`;
  const now = Date.now();
  const lastCall = undoRedoRateLimits.get(key) || 0;
  
  // Allow 1 undo/redo per 200ms per user (prevents spam)
  if (now - lastCall < 200) {
    return false; // Rate limited
  }
  
  undoRedoRateLimits.set(key, now);
  
  // Cleanup old entries (prevents memory leak)
  if (undoRedoRateLimits.size > 1000) {
    const threshold = now - 60000; // 1 minute
    for (const [k, v] of undoRedoRateLimits.entries()) {
      if (v < threshold) {
        undoRedoRateLimits.delete(k);
      }
    }
  }
  
  return true;
}

// ============================================
// THEN, IN THE PAGE_UNDO HANDLER, ADD THIS AT THE TOP:
// ============================================

socket.on(CLIENT_EVENTS.PAGE_UNDO, async (data) => {
  try {
    const { pageId } = data;

    // Rate limiting - prevent spam (ADD THIS)
    if (!checkRateLimit(socket.userId, 'undo')) {
      console.log(`WARNING: Rate limit - User ${socket.userId} undo too fast (< 200ms)`);
      return; // Silently ignore
    }

    console.log(`User ${socket.userId} requesting undo on page ${pageId}`);

    // ... rest of the handler code

// ============================================
// ALSO ADD RATE LIMITING TO PAGE_REDO HANDLER:
// ============================================

socket.on(CLIENT_EVENTS.PAGE_REDO, async (data) => {
  try {
    const { pageId } = data;

    // Rate limiting - prevent spam (ADD THIS)
    if (!checkRateLimit(socket.userId, 'redo')) {
      console.log(`WARNING: Rate limit - User ${socket.userId} redo too fast (< 200ms)`);
      return; // Silently ignore
    }

    console.log(`User ${socket.userId} requesting redo on page ${pageId}`);

    // ... rest of the handler code

// ============================================
// MANUAL ADDITION COMPLETE
// ============================================
