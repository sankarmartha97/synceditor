const { pool } = require('../config/database');
const { redis } = require('../config/redis');
const { CLIENT_EVENTS, SERVER_EVENTS } = require('./events');
const patchService = require('../services/patch.service');
const otService = require('../services/ot.service');
const { getUserColor } = require('../utils/userColors');
const operationHistoryService = require('../services/operationHistory.service');
const undoRedoService = require('../services/undoRedo.service');
const commentsService = require('../services/comments.service');

// ============================================
// RATE LIMITING FOR UNDO/REDO
// ============================================
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
  
  // Cleanup old entries (optional, prevents memory leak)
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

/**
 * Setup Page WebSocket Handlers
 * Handles real-time collaboration with JSON Patch sync + OT conflict resolution
 */
const setupPageHandlers = (io, socket) => {
  
  // ============================================
  // PAGE JOIN - User joins a page for editing
  // ============================================
  
  socket.on(CLIENT_EVENTS.PAGE_JOIN, async (data) => {
    try {
      const { pageId } = data;
      console.log(`ðŸ“„ User ${socket.userId} requesting to join page ${pageId}`);

      // Verify user has access to page
      const accessCheck = await pool.query(
        `SELECT 
          p.id, 
          p.name, 
          p.page_data,
          p.version,
          p.owner_id,
          pp.permission_type,
          u.name as user_name, 
          u.email as user_email,
          u.avatar_url
         FROM pages p
         LEFT JOIN page_permissions pp ON p.id = pp.page_id AND pp.user_id = $2
         LEFT JOIN users u ON u.id = $2
         WHERE p.id = $1 
         AND p.deleted_at IS NULL
         AND (p.owner_id = $2 OR pp.permission_type IS NOT NULL)`,
        [pageId, socket.userId]
      );

      if (accessCheck.rows.length === 0) {
        socket.emit(SERVER_EVENTS.CONNECTION_ERROR, {
          message: 'Access denied to page',
        });
        return;
      }

      const pageInfo = accessCheck.rows[0];
      const permission = pageInfo.owner_id === socket.userId 
        ? 'owner' 
        : pageInfo.permission_type;

      // Join page room
      socket.join(`page:${pageId}`);
      socket.currentPageId = pageId;
      socket.pagePermission = permission;

      // Store active editor in database
      const editorId = await pool.query(
        `INSERT INTO active_editors (page_id, user_id, last_active)
         VALUES ($1, $2, NOW())
         ON CONFLICT (page_id, user_id) 
         DO UPDATE SET last_active = NOW()
         RETURNING page_id`,
        [pageId, socket.userId]
      );

      socket.editorId = pageId; // Use pageId as identifier

      // Get user color (consistent per user)
      const userColor = getUserColor(socket.userId);

      // Store user info in Redis for fast access
      const userKey = `page:${pageId}:users`;
      const userData = {
        userId: socket.userId,
        name: pageInfo.user_name,
        email: pageInfo.user_email,
        avatarUrl: pageInfo.avatar_url,
        permission: permission,
        color: userColor, // Add user color for presence
        joinedAt: new Date().toISOString(),
      };
      await redis.hset(userKey, socket.userId, JSON.stringify(userData));

      // Get all active users in this page
      const activeUsers = await redis.hgetall(userKey);
      const users = Object.values(activeUsers).map((u) => JSON.parse(u));

      console.log(`?? Active users in page ${pageId}:`, users.map(u => `${u.name} (${u.userId})`).join(', '));

      // Notify user they joined successfully
      socket.emit(SERVER_EVENTS.PAGE_JOINED, {
        pageId,
        pageName: pageInfo.name,
        pageData: pageInfo.page_data,
        version: pageInfo.version,
        permission: permission,
        activeUsers: users,
      });

      // Send initial undo/redo state
      const canUndo = await operationHistoryService.canUndo(pageId, socket.userId);
      const canRedo = await operationHistoryService.canRedo(pageId, socket.userId);
      socket.emit(SERVER_EVENTS.PAGE_UNDO_STATE, {
        canUndo,
        canRedo,
      });

      // Notify other users in page
      socket.to(`page:${pageId}`).emit(SERVER_EVENTS.PAGE_USER_JOINED, {
        user: userData,
        timestamp: new Date().toISOString(),
      });

      console.log(`âœ… User ${socket.userId} joined page ${pageId} (${permission})`);
    } catch (error) {
      console.error('âŒ Page join error:', error);
      socket.emit(SERVER_EVENTS.SYNC_ERROR, {
        operation: 'page:join',
        message: 'Failed to join page',
        error: error.message,
      });
    }
  });

  // ============================================
  // PAGE LEAVE - User leaves a page
  // ============================================
  
  socket.on(CLIENT_EVENTS.PAGE_LEAVE, async (data) => {
    try {
      const { pageId } = data || { pageId: socket.currentPageId };

      if (!pageId) return;

      console.log(`ðŸ“¤ User ${socket.userId} leaving page ${pageId}`);

      // Remove from database (or mark inactive)
      await pool.query(
        `DELETE FROM active_editors 
         WHERE page_id = $1 AND user_id = $2`,
        [pageId, socket.userId]
      );

      // Remove from Redis
      await redis.hdel(`page:${pageId}:users`, socket.userId);
      await redis.hdel(`page:${pageId}:cursors`, socket.userId);

      // Leave room
      socket.leave(`page:${pageId}`);

      // Notify others
      socket.to(`page:${pageId}`).emit(SERVER_EVENTS.PAGE_USER_LEFT, {
        userId: socket.userId,
        timestamp: new Date().toISOString(),
      });

      socket.currentPageId = null;
      socket.pagePermission = null;

      console.log(`âœ… User ${socket.userId} left page ${pageId}`);
    } catch (error) {
      console.error('âŒ Page leave error:', error);
    }
  });

  // ============================================
  // PAGE PATCH - Incremental update with JSON Patch
  // ============================================
  
  socket.on(CLIENT_EVENTS.PAGE_PATCH, async (data) => {
    try {
      const { pageId, patches, clientVersion } = data;

      console.log(`ðŸ”„ User ${socket.userId} sending patch to page ${pageId}`);
      console.log(`   Patches:`, patches.length, 'operations');

      // Verify permission (must have edit or owner)
      if (!['owner', 'edit'].includes(socket.pagePermission)) {
        socket.emit(SERVER_EVENTS.PAGE_PATCH_ERROR, {
          message: 'Permission denied: read-only access',
          patches,
        });
        return;
      }

      // Get current page
      const pageResult = await pool.query(
        `SELECT page_data, version FROM pages WHERE id = $1 AND deleted_at IS NULL`,
        [pageId]
      );

      if (pageResult.rows.length === 0) {
        socket.emit(SERVER_EVENTS.PAGE_PATCH_ERROR, {
          message: 'Page not found',
        });
        return;
      }

      const currentData = pageResult.rows[0].page_data;
      const serverVersion = pageResult.rows[0].version;

      // Initialize patches to apply
      let patchesToApply = patches;

      // Check version conflict and transform if needed
      if (clientVersion && clientVersion !== serverVersion) {
        console.log(`ðŸ”€ Version conflict detected: client=${clientVersion}, server=${serverVersion}`);
        console.log(`   Applying Operational Transformation...`);

        // Get patches between client version and server version
        const serverPatches = await patchService.getPatchesBetweenVersions(
          pageId,
          clientVersion,
          serverVersion
        );

        if (serverPatches.length > 0) {
          console.log(`   Found ${serverPatches.length} server patches to transform against`);

          // Transform client patches using OT
          patchesToApply = otService.transformPatch(
            patches,
            serverPatches,
            clientVersion,
            serverVersion
          );

          console.log(`   âœ… Transformed ${patches.length} â†’ ${patchesToApply.length} operations`);

          if (patchesToApply.length === 0) {
            console.log(`   âš ï¸ All operations cancelled by OT`);
            socket.emit(SERVER_EVENTS.PAGE_PATCH_APPLIED, {
              pageId,
              version: serverVersion,
              patches: [],
              transformed: true,
              timestamp: new Date().toISOString(),
            });
            return;
          }
        } else {
          // No patches found but versions differ - possible race condition
          console.warn(`   âš ï¸ No patches found between v${clientVersion} and v${serverVersion}`);
          console.warn(`   Rejecting patch to maintain consistency`);
          socket.emit(SERVER_EVENTS.PAGE_CONFLICT, {
            clientVersion,
            serverVersion,
            message: 'Version mismatch - please refresh',
          });
          return;
        }
      }

      // Apply patches (original or transformed)
      const result = patchService.applyPatch(currentData, patchesToApply);

      if (!result.success) {
        socket.emit(SERVER_EVENTS.PAGE_PATCH_ERROR, {
          message: 'Failed to apply patches',
          errors: result.errors,
          patches,
        });
        return;
      }

      // Update database with new version
      const newVersion = serverVersion + 1;
      await pool.query(
        `UPDATE pages 
         SET page_data = $1, 
             version = $2,
             updated_at = NOW()
         WHERE id = $3`,
        [JSON.stringify(result.data), newVersion, pageId]
      );

      // Save patch history (save the transformed patches that were actually applied)
      await patchService.savePatchHistory(
        pageId,
        socket.userId,
        patchesToApply,
        serverVersion,
        newVersion
      );

      // Generate inverse operation and save to operation history for undo/redo
      try {
        const inverseOperation = undoRedoService.generateInverse(patchesToApply, currentData);
        
        const savedOp = await operationHistoryService.saveOperation({
          pageId,
          userId: socket.userId,
          operation: patchesToApply,
          inverseOperation,
          fromVersion: serverVersion,
          toVersion: newVersion,
          parentOperations: [], // Could be populated if tracking dependencies
        });

        // Push to user's undo stack
        await operationHistoryService.pushToUndoStack(pageId, socket.userId, savedOp.id);
        
        console.log(`ðŸ’¾ Operation saved for undo: ${savedOp.id}`);
      } catch (historyError) {
        console.error('âŒ Failed to save operation history:', historyError);
        // Don't fail the patch - undo just won't be available for this operation
      }

      // Send updated undo/redo state to user
      const canUndo = await operationHistoryService.canUndo(pageId, socket.userId);
      const canRedo = await operationHistoryService.canRedo(pageId, socket.userId);
      socket.emit(SERVER_EVENTS.PAGE_UNDO_STATE, {
        canUndo,
        canRedo,
      });

      // Confirm to sender
      socket.emit(SERVER_EVENTS.PAGE_PATCH_APPLIED, {
        pageId,
        version: newVersion,
        patches: patchesToApply,
        transformed: patchesToApply !== patches, // Indicate if OT was applied
        timestamp: new Date().toISOString(),
      });

      // Broadcast to other users
      socket.to(`page:${pageId}`).emit(SERVER_EVENTS.PAGE_PATCH_RECEIVED, {
        pageId,
        userId: socket.userId,
        patches: patchesToApply,
        version: newVersion,
        timestamp: new Date().toISOString(),
      });

      console.log(`âœ… Patch applied: page ${pageId} v${serverVersion} â†’ v${newVersion}`);
      if (patchesToApply !== patches) {
        console.log(`   ðŸ”€ Patches were transformed by OT`);
      }
    } catch (error) {
      console.error('âŒ Page patch error:', error);
      socket.emit(SERVER_EVENTS.PAGE_PATCH_ERROR, {
        message: 'Failed to process patch',
        error: error.message,
      });
    }
  });

  // ============================================
  // PAGE CURSOR - Real-time cursor position with presence
  // ============================================
  
  socket.on(CLIENT_EVENTS.PAGE_CURSOR, async (data) => {
    try {
      const { pageId, position } = data;

      if (!socket.currentPageId || socket.currentPageId !== pageId) {
        return;
      }

      // Store cursor in Redis with 30-second TTL
      const cursorKey = `page:${pageId}:cursors`;
      const cursorData = {
        userId: socket.userId,
        position: position,
        timestamp: new Date().toISOString(),
      };
      
      // Set cursor with TTL (auto-expire if user stops moving)
      await redis.hset(cursorKey, socket.userId, JSON.stringify(cursorData));
      await redis.expire(cursorKey, 30);

      // Get user info for broadcasting
      const userKey = `page:${pageId}:users`;
      const userDataStr = await redis.hget(userKey, socket.userId);
      const userData = userDataStr ? JSON.parse(userDataStr) : null;

      // Broadcast cursor position to others (not to self)
      socket.to(`page:${pageId}`).emit(SERVER_EVENTS.PAGE_CURSOR_UPDATED, {
        userId: socket.userId,
        userName: userData?.name || 'Unknown',
        userColor: userData?.color || '#3B82F6',
        position,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      console.error('âŒ Cursor update error:', error);
    }
  });

  // ============================================
  // PAGE SELECTION - Widget selection state
  // ============================================
  
  socket.on(CLIENT_EVENTS.PAGE_SELECTION, async (data) => {
    try {
      const { pageId, widgetId } = data;

      if (!socket.currentPageId || socket.currentPageId !== pageId) {
        return;
      }

      // Get user info from Redis to include in selection event
      const userKey = `page:${pageId}:users`;
      const userDataStr = await redis.hget(userKey, socket.userId);
      const userData = userDataStr ? JSON.parse(userDataStr) : null;

      // Broadcast selection to others with user name
      socket.to(`page:${pageId}`).emit(SERVER_EVENTS.PAGE_SELECTION_UPDATED, {
        userId: socket.userId,
        userName: userData?.name || 'Unknown User',
        widgetId,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      console.error('âŒ Selection update error:', error);
    }
  });

  // ============================================
  // UNDO/REDO EVENTS - Operational Transformation-based undo/redo
  // ============================================

  /**
   * Undo operation
   * Uses OT to transform undo against concurrent operations
   */
  socket.on(CLIENT_EVENTS.PAGE_UNDO, async (data) => {
    try {
      const { pageId } = data;

      if (!socket.currentPageId || socket.currentPageId !== pageId) {
        socket.emit(SERVER_EVENTS.PAGE_UNDO_ERROR, {
          message: 'Not joined to this page',
        });
        return;
      }

      // Verify permission
      if (!['owner', 'edit'].includes(socket.pagePermission)) {
        socket.emit(SERVER_EVENTS.PAGE_UNDO_ERROR, {
          message: 'Permission denied: read-only access',
        });
        return;
      }

      console.log(`â†©ï¸ User ${socket.userId} requesting undo on page ${pageId}`);

      // Check if can undo
      const canUndo = await operationHistoryService.canUndo(pageId, socket.userId);
      if (!canUndo) {
        socket.emit(SERVER_EVENTS.PAGE_UNDO_ERROR, {
          message: 'Nothing to undo',
        });
        return;
      }

      // Pop from undo stack
      const operationId = await operationHistoryService.popFromUndoStack(pageId, socket.userId);
      if (!operationId) {
        socket.emit(SERVER_EVENTS.PAGE_UNDO_ERROR, {
          message: 'Undo stack is empty',
        });
        return;
      }

      // Get the operation to undo
      const operation = await operationHistoryService.getOperationById(operationId);
      const inverseOp = operation.inverse_operation;
      const undoVersion = operation.to_version; // Version when op was applied

      // Get current page state
      const pageResult = await pool.query(
        `SELECT page_data, version FROM pages WHERE id = $1 AND deleted_at IS NULL`,
        [pageId]
      );

      if (pageResult.rows.length === 0) {
        socket.emit(SERVER_EVENTS.PAGE_UNDO_ERROR, {
          message: 'Page not found',
        });
        return;
      }

      const currentData = pageResult.rows[0].page_data;
      const currentVersion = pageResult.rows[0].version;

      // Get operations that happened after the operation we're undoing
      const concurrentOps = await operationHistoryService.getOperationsSinceVersion(
        pageId,
        undoVersion
      );

      console.log(`   Found ${concurrentOps.length} concurrent operations since v${undoVersion}`);

      // Transform undo operation against concurrent operations
      let transformedUndo = inverseOp;
      if (concurrentOps.length > 0) {
        transformedUndo = undoRedoService.transformUndo(
          inverseOp,
          concurrentOps.map(op => op.operation).flat(),
          undoVersion,
          currentVersion
        );
      }

      // Validate undo
      const validation = undoRedoService.validateUndo(transformedUndo, currentData);
      if (!validation.valid) {
        console.warn(`âš ï¸ Undo validation failed: ${validation.error}`);
        socket.emit(SERVER_EVENTS.PAGE_UNDO_ERROR, {
          message: validation.error,
        });
        
        // Push back to undo stack since we couldn't apply
        await operationHistoryService.popFromRedoStack(pageId, socket.userId);
        return;
      }

      // Apply undo
      const result = undoRedoService.applyUndo(currentData, transformedUndo);
      if (!result.success) {
        console.error(`âŒ Undo application failed:`, result.errors);
        socket.emit(SERVER_EVENTS.PAGE_UNDO_ERROR, {
          message: 'Failed to apply undo',
          errors: result.errors,
        });
        
        // Push back to undo stack
        await operationHistoryService.popFromRedoStack(pageId, socket.userId);
        return;
      }

      // Update database
      const newVersion = currentVersion + 1;
      await pool.query(
        `UPDATE pages 
         SET page_data = $1, 
             version = $2,
             updated_at = NOW()
         WHERE id = $3`,
        [JSON.stringify(result.data), newVersion, pageId]
      );

      // Save the undo as a new operation in history
      const redoOp = operation.operation; // Forward operation becomes redo
      const undoSavedOp = await operationHistoryService.saveOperation({
        pageId,
        userId: socket.userId,
        operation: transformedUndo,
        inverseOperation: redoOp, // Undo's inverse is the original operation
        fromVersion: currentVersion,
        toVersion: newVersion,
        parentOperations: [operationId],
      });

      // Send updated undo/redo state
      const canUndoNow = await operationHistoryService.canUndo(pageId, socket.userId);
      const canRedoNow = await operationHistoryService.canRedo(pageId, socket.userId);

      // Notify user
      socket.emit(SERVER_EVENTS.PAGE_UNDO_APPLIED, {
        pageId,
        version: newVersion,
        patches: transformedUndo,
        operationDescription: undoRedoService.describeOperation(operation.operation),
        canUndo: canUndoNow,
        canRedo: canRedoNow,
        timestamp: new Date().toISOString(),
      });

      // Broadcast to other users
      socket.to(`page:${pageId}`).emit(SERVER_EVENTS.PAGE_PATCH_RECEIVED, {
        pageId,
        userId: socket.userId,
        patches: transformedUndo,
        version: newVersion,
        isUndo: true,
        timestamp: new Date().toISOString(),
      });

      console.log(`âœ… Undo applied: page ${pageId} v${currentVersion} â†’ v${newVersion}`);
    } catch (error) {
      console.error('âŒ Undo error:', error);
      socket.emit(SERVER_EVENTS.PAGE_UNDO_ERROR, {
        message: 'Failed to undo operation',
        error: error.message,
      });
    }
  });

  /**
   * Redo operation
   * Re-applies a previously undone operation
   */
  socket.on(CLIENT_EVENTS.PAGE_REDO, async (data) => {
    try {
      const { pageId } = data;

      if (!socket.currentPageId || socket.currentPageId !== pageId) {
        socket.emit(SERVER_EVENTS.PAGE_REDO_ERROR, {
          message: 'Not joined to this page',
        });
        return;
      }

      // Verify permission
      if (!['owner', 'edit'].includes(socket.pagePermission)) {
        socket.emit(SERVER_EVENTS.PAGE_REDO_ERROR, {
          message: 'Permission denied: read-only access',
        });
        return;
      }

      console.log(`â†ªï¸ User ${socket.userId} requesting redo on page ${pageId}`);

      // Check if can redo
      const canRedo = await operationHistoryService.canRedo(pageId, socket.userId);
      if (!canRedo) {
        socket.emit(SERVER_EVENTS.PAGE_REDO_ERROR, {
          message: 'Nothing to redo',
        });
        return;
      }

      // Pop from redo stack
      const operationId = await operationHistoryService.popFromRedoStack(pageId, socket.userId);
      if (!operationId) {
        socket.emit(SERVER_EVENTS.PAGE_REDO_ERROR, {
          message: 'Redo stack is empty',
        });
        return;
      }

      // Get the operation to redo
      const operation = await operationHistoryService.getOperationById(operationId);
      const redoOp = operation.operation; // Forward operation
      const redoVersion = operation.to_version;

      // Get current page state
      const pageResult = await pool.query(
        `SELECT page_data, version FROM pages WHERE id = $1 AND deleted_at IS NULL`,
        [pageId]
      );

      if (pageResult.rows.length === 0) {
        socket.emit(SERVER_EVENTS.PAGE_REDO_ERROR, {
          message: 'Page not found',
        });
        return;
      }

      const currentData = pageResult.rows[0].page_data;
      const currentVersion = pageResult.rows[0].version;

      // Get operations that happened after the original redo operation
      const concurrentOps = await operationHistoryService.getOperationsSinceVersion(
        pageId,
        redoVersion
      );

      console.log(`   Found ${concurrentOps.length} concurrent operations since v${redoVersion}`);

      // Transform redo operation if needed
      let transformedRedo = redoOp;
      if (concurrentOps.length > 0) {
        // Use OT to transform redo
        transformedRedo = otService.transformPatch(
          redoOp,
          concurrentOps.map(op => op.operation).flat(),
          redoVersion,
          currentVersion
        );
      }

      // Apply redo
      const result = patchService.applyPatch(currentData, transformedRedo);
      if (!result.success) {
        console.error(`âŒ Redo application failed:`, result.errors);
        socket.emit(SERVER_EVENTS.PAGE_REDO_ERROR, {
          message: 'Failed to apply redo',
          errors: result.errors,
        });
        
        // Push back to redo stack
        await operationHistoryService.popFromUndoStack(pageId, socket.userId);
        return;
      }

      // Update database
      const newVersion = currentVersion + 1;
      await pool.query(
        `UPDATE pages 
         SET page_data = $1, 
             version = $2,
             updated_at = NOW()
         WHERE id = $3`,
        [JSON.stringify(result.data), newVersion, pageId]
      );

      // Save the redo as a new operation in history
      const redoInverse = undoRedoService.generateInverse(transformedRedo, currentData);
      const redoSavedOp = await operationHistoryService.saveOperation({
        pageId,
        userId: socket.userId,
        operation: transformedRedo,
        inverseOperation: redoInverse,
        fromVersion: currentVersion,
        toVersion: newVersion,
        parentOperations: [operationId],
      });

      // Push to undo stack (redo becomes undoable)
      await operationHistoryService.pushToUndoStack(pageId, socket.userId, redoSavedOp.id);

      // Send updated undo/redo state
      const canUndoNow = await operationHistoryService.canUndo(pageId, socket.userId);
      const canRedoNow = await operationHistoryService.canRedo(pageId, socket.userId);

      // Notify user
      socket.emit(SERVER_EVENTS.PAGE_REDO_APPLIED, {
        pageId,
        version: newVersion,
        patches: transformedRedo,
        operationDescription: undoRedoService.describeOperation(redoOp),
        canUndo: canUndoNow,
        canRedo: canRedoNow,
        timestamp: new Date().toISOString(),
      });

      // Broadcast to other users
      socket.to(`page:${pageId}`).emit(SERVER_EVENTS.PAGE_PATCH_RECEIVED, {
        pageId,
        userId: socket.userId,
        patches: transformedRedo,
        version: newVersion,
        isRedo: true,
        timestamp: new Date().toISOString(),
      });

      console.log(`âœ… Redo applied: page ${pageId} v${currentVersion} â†’ v${newVersion}`);
    } catch (error) {
      console.error('âŒ Redo error:', error);
      socket.emit(SERVER_EVENTS.PAGE_REDO_ERROR, {
        message: 'Failed to redo operation',
        error: error.message,
      });
    }
  });

  // ============================================
  // COMMENT EVENTS - Real-time comment sync
  // ============================================
  
  /**
   * Create comment via WebSocket
   * Real-time notification to all users in the page
   */
  socket.on(CLIENT_EVENTS.COMMENT_CREATE, async (data) => {
    try {
      const { pageId, content, positionX, positionY, widgetId, parentCommentId } = data;

      if (!socket.currentPageId || socket.currentPageId !== pageId) {
        socket.emit(SERVER_EVENTS.SYNC_ERROR, {
          operation: 'comment:create',
          message: 'Not joined to this page',
        });
        return;
      }

      console.log(`ðŸ’¬ User ${socket.userId} creating comment on page ${pageId}`);

      // Create comment
      const comment = await commentsService.createComment({
        pageId,
        userId: socket.userId,
        content,
        positionX,
        positionY,
        widgetId,
        parentCommentId,
      });

      // Notify creator
      socket.emit(SERVER_EVENTS.COMMENT_CREATED, {
        comment,
        isOwn: true,
        timestamp: new Date().toISOString(),
      });

      // Broadcast to others in the page
      socket.to(`page:${pageId}`).emit(SERVER_EVENTS.COMMENT_CREATED, {
        comment,
        isOwn: false,
        timestamp: new Date().toISOString(),
      });

      // Send mention notifications to mentioned users
      const mentions = commentsService.extractMentions(content);
      if (mentions.length > 0) {
        const mentionedUserIds = await commentsService.resolveMentions(mentions);
        
        // Emit mention event to each mentioned user (if they're online)
        mentionedUserIds.forEach((mentionedUserId) => {
          if (mentionedUserId !== socket.userId) {
            // Send to specific user across all their sockets
            const userSockets = Array.from(io.sockets.sockets.values())
              .filter(s => s.userId === mentionedUserId);
            
            userSockets.forEach(userSocket => {
              userSocket.emit(SERVER_EVENTS.COMMENT_MENTION, {
                comment,
                mentionedBy: {
                  userId: socket.userId,
                  userName: comment.user_name,
                },
                timestamp: new Date().toISOString(),
              });
            });
          }
        });
      }

      console.log(`âœ… Comment created: ${comment.id}`);
    } catch (error) {
      console.error('âŒ Comment create error:', error);
      socket.emit(SERVER_EVENTS.SYNC_ERROR, {
        operation: 'comment:create',
        message: error.message || 'Failed to create comment',
      });
    }
  });

  /**
   * Update comment via WebSocket
   */
  socket.on(CLIENT_EVENTS.COMMENT_UPDATE, async (data) => {
    try {
      const { commentId, content } = data;

      console.log(`âœï¸ User ${socket.userId} updating comment ${commentId}`);

      // Update comment
      const updatedComment = await commentsService.updateComment(
        commentId,
        socket.userId,
        content
      );

      // Get page ID from comment
      const pageId = updatedComment.page_id;

      // Notify creator
      socket.emit(SERVER_EVENTS.COMMENT_UPDATED, {
        comment: updatedComment,
        isOwn: true,
        timestamp: new Date().toISOString(),
      });

      // Broadcast to others in the page
      socket.to(`page:${pageId}`).emit(SERVER_EVENTS.COMMENT_UPDATED, {
        comment: updatedComment,
        isOwn: false,
        timestamp: new Date().toISOString(),
      });

      console.log(`âœ… Comment updated: ${commentId}`);
    } catch (error) {
      console.error('âŒ Comment update error:', error);
      socket.emit(SERVER_EVENTS.SYNC_ERROR, {
        operation: 'comment:update',
        message: error.message || 'Failed to update comment',
      });
    }
  });

  /**
   * Delete comment via WebSocket
   */
  socket.on(CLIENT_EVENTS.COMMENT_DELETE, async (data) => {
    try {
      const { commentId, pageId } = data;

      console.log(`ðŸ—‘ï¸ User ${socket.userId} deleting comment ${commentId}`);

      // Delete comment
      await commentsService.deleteComment(commentId, socket.userId);

      // Notify creator
      socket.emit(SERVER_EVENTS.COMMENT_DELETED, {
        commentId,
        isOwn: true,
        timestamp: new Date().toISOString(),
      });

      // Broadcast to others in the page
      socket.to(`page:${pageId}`).emit(SERVER_EVENTS.COMMENT_DELETED, {
        commentId,
        isOwn: false,
        timestamp: new Date().toISOString(),
      });

      console.log(`âœ… Comment deleted: ${commentId}`);
    } catch (error) {
      console.error('âŒ Comment delete error:', error);
      socket.emit(SERVER_EVENTS.SYNC_ERROR, {
        operation: 'comment:delete',
        message: error.message || 'Failed to delete comment',
      });
    }
  });

  /**
   * Resolve/unresolve comment via WebSocket
   */
  socket.on(CLIENT_EVENTS.COMMENT_RESOLVE, async (data) => {
    try {
      const { commentId, pageId, resolved = true } = data;

      console.log(`${resolved ? 'âœ…' : 'ðŸ”“'} User ${socket.userId} ${resolved ? 'resolving' : 'reopening'} comment ${commentId}`);


      const updatedComment = await commentsService.resolveComment(
        commentId,
        socket.userId,
        resolved
      );

      // Notify all users in the page
      io.to(`page:${pageId}`).emit(SERVER_EVENTS.COMMENT_RESOLVED, {
        comment: updatedComment,
        resolved,
        resolvedBy: {
          userId: socket.userId,
          userName: updatedComment.resolved_by_name,
        },
        timestamp: new Date().toISOString(),
      });

      console.log(`? Comment ${resolved ? 'resolved' : 'reopened'}: ${commentId}`);
    } catch (error) {
      console.error('? Comment resolve error:', error);
      socket.emit(SERVER_EVENTS.SYNC_ERROR, {
        operation: 'comment:resolve',
        message: error.message || 'Failed to resolve comment',
      });
    }
  });

  // ============================================
  // DISCONNECT - Clean up on disconnect
  // ============================================
  
  socket.on('disconnect', async () => {
    console.log(`?? User ${socket.userId} disconnected`);

    if (socket.currentPageId) {
      try {
        // Remove from database
        await pool.query(
          `DELETE FROM active_editors 
           WHERE page_id = $1 AND user_id = $2`,
          [socket.currentPageId, socket.userId]
        );

        // Remove from Redis (user data and cursor)
        await redis.hdel(`page:${socket.currentPageId}:users`, socket.userId);
        await redis.hdel(`page:${socket.currentPageId}:cursors`, socket.userId);

        // Notify others
        socket.to(`page:${socket.currentPageId}`).emit(SERVER_EVENTS.PAGE_USER_LEFT, {
          userId: socket.userId,
          timestamp: new Date().toISOString(),
        });
      } catch (error) {
        console.error('? Disconnect cleanup error:', error);
      }
    }
  });

  // ============================================
  // FOLLOW FEATURE - Figma-like user following
  // ============================================
  
  /**
   * Start following a user's viewport
   */
  socket.on(CLIENT_EVENTS.PAGE_FOLLOW_START, async (data) => {
    try {
      const { pageId, targetUserId } = data;

      if (!socket.currentPageId || socket.currentPageId !== pageId) {
        socket.emit(SERVER_EVENTS.PAGE_FOLLOW_ERROR, {
          message: 'Not joined to this page',
        });
        return;
      }

      // Cannot follow yourself
      if (targetUserId === socket.userId) {
        socket.emit(SERVER_EVENTS.PAGE_FOLLOW_ERROR, {
          message: 'Cannot follow yourself',
        });
        return;
      }

      // Check if target user is already following you (prevent mutual following)
      const followsKey = `page:${pageId}:follows`;
      const targetFollowing = await redis.hget(followsKey, targetUserId);
      if (targetFollowing === socket.userId) {
        // Get target user info for better error message
        const userKey = `page:${pageId}:users`;
        const targetUserStr = await redis.hget(userKey, targetUserId);
        const targetUser = targetUserStr ? JSON.parse(targetUserStr) : null;
        const targetName = targetUser ? targetUser.name : 'This user';
        
        socket.emit(SERVER_EVENTS.PAGE_FOLLOW_ERROR, {
          message: `${targetName} is already following you. Mutual following is not allowed.`,
        });
        return;
      }

      console.log(`👁️ User ${socket.userId} starting to follow ${targetUserId} in page ${pageId}`);

      // Check if target user is in the page
      const userKey = `page:${pageId}:users`;
      const targetUserStr = await redis.hget(userKey, targetUserId);
      
      if (!targetUserStr) {
        socket.emit(SERVER_EVENTS.PAGE_FOLLOW_ERROR, {
          message: 'Target user not in this page',
        });
        return;
      }

      const targetUser = JSON.parse(targetUserStr);

      // Store follow relationship in Redis
      const followKey = `page:${pageId}:follows`;
      await redis.hset(followKey, socket.userId, targetUserId);
      await redis.expire(followKey, 3600); // 1 hour TTL

      // Get target user's current viewport if available
      const viewportKey = `page:${pageId}:viewport:${targetUserId}`;
      const viewportStr = await redis.get(viewportKey);
      let initialViewport = null;
      if (viewportStr) {
        initialViewport = JSON.parse(viewportStr);
      }

      // Confirm to follower
      socket.emit(SERVER_EVENTS.PAGE_FOLLOW_STARTED, {
        pageId,
        targetUserId,
        targetUserName: targetUser.name,
        initialViewport,
        timestamp: new Date().toISOString(),
      });

      console.log(`✅ Follow started: ${socket.userId} → ${targetUserId}`);
    } catch (error) {
      console.error('❌ Follow start error:', error);
      socket.emit(SERVER_EVENTS.PAGE_FOLLOW_ERROR, {
        message: 'Failed to start following',
        error: error.message,
      });
    }
  });

  /**
   * Stop following a user
   */
  socket.on(CLIENT_EVENTS.PAGE_FOLLOW_STOP, async (data) => {
    try {
      const { pageId } = data;

      if (!socket.currentPageId || socket.currentPageId !== pageId) {
        return;
      }

      console.log(`👁️‍🗨️ User ${socket.userId} stopping follow in page ${pageId}`);

      // Remove follow relationship
      const followKey = `page:${pageId}:follows`;
      await redis.hdel(followKey, socket.userId);

      // Confirm to user
      socket.emit(SERVER_EVENTS.PAGE_FOLLOW_STOPPED, {
        pageId,
        timestamp: new Date().toISOString(),
      });

      console.log(`✅ Follow stopped: ${socket.userId}`);
    } catch (error) {
      console.error('❌ Follow stop error:', error);
    }
  });

  /**
   * Viewport update - broadcast to followers
   */
  socket.on(CLIENT_EVENTS.PAGE_VIEWPORT_UPDATE, async (data) => {
    try {
      const { pageId, viewport } = data;

      if (!socket.currentPageId || socket.currentPageId !== pageId) {
        return;
      }

      // Store viewport in Redis with 30s TTL
      const viewportKey = `page:${pageId}:viewport:${socket.userId}`;
      await redis.setex(viewportKey, 30, JSON.stringify(viewport));

      // Find who is following this user
      const followKey = `page:${pageId}:follows`;
      const allFollows = await redis.hgetall(followKey);
      
      const followers = Object.entries(allFollows)
        .filter(([follower, target]) => target === socket.userId)
        .map(([follower]) => follower);

      if (followers.length === 0) {
        return; // No one is following
      }

      // Get user info for broadcasting
      const userKey = `page:${pageId}:users`;
      const userDataStr = await redis.hget(userKey, socket.userId);
      const userData = userDataStr ? JSON.parse(userDataStr) : null;

      // Broadcast viewport update to followers only
      followers.forEach((followerId) => {
        // Find follower's socket and emit
        const followerSockets = Array.from(io.sockets.sockets.values())
          .filter(s => s.userId === followerId && s.currentPageId === pageId);
        
        followerSockets.forEach(followerSocket => {
          followerSocket.emit(SERVER_EVENTS.PAGE_VIEWPORT_UPDATED, {
            userId: socket.userId,
            userName: userData?.name || 'Unknown',
            viewport,
            timestamp: new Date().toISOString(),
          });
        });
      });
    } catch (error) {
      console.error('❌ Viewport update error:', error);
    }
  });
};

module.exports = { setupPageHandlers };
