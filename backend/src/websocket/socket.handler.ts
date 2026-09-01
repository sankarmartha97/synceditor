import { Server, Socket } from 'socket.io';
import { verifyToken } from '../utils/jwt';
import pool from '../config/database';
import redis from '../config/redis';
import { v4 as uuidv4 } from 'uuid';
import {
  CLIENT_EVENTS,
  SERVER_EVENTS,
  CanvasJoinPayload,
  CanvasLeavePayload,
  WidgetAddPayload,
  WidgetUpdatePayload,
  WidgetDeletePayload,
  WidgetMovePayload,
  CursorMovePayload,
  UserInfo,
} from './events';

// Extended socket interface with user data
interface AuthenticatedSocket extends Socket {
  userId?: string;
  email?: string;
  currentCanvasId?: string;
}

export const setupSocketHandlers = (io: Server) => {
  // Authentication middleware for Socket.io
  io.use(async (socket: AuthenticatedSocket, next) => {
    try {
      const token = socket.handshake.auth.token;

      if (!token) {
        return next(new Error('Authentication token required'));
      }

      // Verify JWT token
      const decoded = verifyToken(token);
      socket.userId = decoded.userId;
      socket.email = decoded.email;

      next();
    } catch (error) {
      next(new Error('Authentication failed'));
    }
  });

  // Connection handler
  io.on('connection', (socket: AuthenticatedSocket) => {
    console.log(`🔌 User connected: ${socket.userId} (${socket.id})`);

    // ============================================
    // CANVAS JOIN/LEAVE
    // ============================================

    socket.on(CLIENT_EVENTS.CANVAS_JOIN, async (data: CanvasJoinPayload) => {
      try {
        const { canvasId } = data;

        // Verify user has access to canvas
        const accessCheck = await pool.query(
          `SELECT c.id, c.name, u.name as user_name, u.avatar_url 
           FROM canvases c
           LEFT JOIN canvas_collaborators cc ON c.id = cc.canvas_id
           LEFT JOIN users u ON u.id = $2
           WHERE c.id = $1 AND (c.owner_id = $2 OR cc.user_id = $2 OR c.is_public = true)`,
          [canvasId, socket.userId]
        );

        if (accessCheck.rows.length === 0) {
          socket.emit(SERVER_EVENTS.CONNECTION_ERROR, {
            message: 'Access denied to canvas',
          });
          return;
        }

        const userInfo = accessCheck.rows[0];

        // Join canvas room
        socket.join(`canvas:${canvasId}`);
        socket.currentCanvasId = canvasId;

        // Store active user in Redis
        const userKey = `canvas:${canvasId}:users`;
        const userData: UserInfo = {
          userId: socket.userId!,
          name: userInfo.user_name,
          email: socket.email!,
          avatarUrl: userInfo.avatar_url,
        };
        await redis.hset(userKey, socket.userId!, JSON.stringify(userData));

        // Get all active users in this canvas
        const activeUsers = await redis.hgetall(userKey);
        const users = Object.values(activeUsers).map((u) => JSON.parse(u));

        // Notify user they joined successfully
        socket.emit(SERVER_EVENTS.CANVAS_JOINED, {
          canvasId,
          canvasName: userInfo.name,
          activeUsers: users,
        });

        // Notify other users in canvas
        socket.to(`canvas:${canvasId}`).emit(SERVER_EVENTS.USER_JOINED, {
          user: userData,
          timestamp: new Date().toISOString(),
        });

        console.log(`📍 User ${socket.userId} joined canvas ${canvasId}`);
      } catch (error) {
        console.error('Canvas join error:', error);
        socket.emit(SERVER_EVENTS.SYNC_ERROR, {
          operation: 'canvas:join',
          message: 'Failed to join canvas',
        });
      }
    });

    socket.on(CLIENT_EVENTS.CANVAS_LEAVE, async (data: CanvasLeavePayload) => {
      try {
        const { canvasId } = data;
        await handleCanvasLeave(socket, canvasId);
      } catch (error) {
        console.error('Canvas leave error:', error);
      }
    });

    // ============================================
    // WIDGET OPERATIONS
    // ============================================

    socket.on(CLIENT_EVENTS.WIDGET_ADD, async (data: WidgetAddPayload) => {
      try {
        const { canvasId, widget } = data;

        // Verify editor access
        const accessCheck = await pool.query(
          `SELECT c.id FROM canvases c
           LEFT JOIN canvas_collaborators cc ON c.id = cc.canvas_id
           WHERE c.id = $1 AND (c.owner_id = $2 OR (cc.user_id = $2 AND cc.role IN ('owner', 'editor')))`,
          [canvasId, socket.userId]
        );

        if (accessCheck.rows.length === 0) {
          socket.emit(SERVER_EVENTS.SYNC_ERROR, {
            operation: 'widget:add',
            message: 'Insufficient permissions',
          });
          return;
        }

        // Create widget in database
        const widgetId = uuidv4();
        const result = await pool.query(
          `INSERT INTO widgets (id, canvas_id, type, position, size, properties, parent_id)
           VALUES ($1, $2, $3, $4, $5, $6, $7)
           RETURNING *`,
          [
            widgetId,
            canvasId,
            widget.type,
            widget.position,
            widget.size,
            widget.properties,
            widget.parent_id || null,
          ]
        );

        const createdWidget = result.rows[0];

        // Create version entry
        await pool.query(
          `INSERT INTO widget_versions (id, widget_id, canvas_id, operation, data, created_by)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [uuidv4(), widgetId, canvasId, 'create', createdWidget, socket.userId]
        );

        // Broadcast to all users in canvas except sender
        socket.to(`canvas:${canvasId}`).emit(SERVER_EVENTS.WIDGET_ADDED, {
          widget: createdWidget,
          userId: socket.userId,
          timestamp: new Date().toISOString(),
        });

        // Acknowledge to sender
        socket.emit('widget:add:success', {
          widget: createdWidget,
        });

        console.log(`✨ Widget ${widgetId} added to canvas ${canvasId}`);
      } catch (error) {
        console.error('Widget add error:', error);
        socket.emit(SERVER_EVENTS.SYNC_ERROR, {
          operation: 'widget:add',
          message: 'Failed to add widget',
        });
      }
    });

    socket.on(CLIENT_EVENTS.WIDGET_UPDATE, async (data: WidgetUpdatePayload) => {
      try {
        const { canvasId, widgetId, updates } = data;

        // Verify editor access
        const accessCheck = await pool.query(
          `SELECT c.id FROM canvases c
           LEFT JOIN canvas_collaborators cc ON c.id = cc.canvas_id
           WHERE c.id = $1 AND (c.owner_id = $2 OR (cc.user_id = $2 AND cc.role IN ('owner', 'editor')))`,
          [canvasId, socket.userId]
        );

        if (accessCheck.rows.length === 0) {
          socket.emit(SERVER_EVENTS.SYNC_ERROR, {
            operation: 'widget:update',
            message: 'Insufficient permissions',
          });
          return;
        }

        // Build update query
        const updateFields: string[] = [];
        const values: any[] = [];
        let paramCount = 1;

        if (updates.position !== undefined) {
          updateFields.push(`position = $${paramCount++}`);
          values.push(updates.position);
        }
        if (updates.size !== undefined) {
          updateFields.push(`size = $${paramCount++}`);
          values.push(updates.size);
        }
        if (updates.properties !== undefined) {
          updateFields.push(`properties = $${paramCount++}`);
          values.push(updates.properties);
        }

        if (updateFields.length === 0) {
          socket.emit(SERVER_EVENTS.SYNC_ERROR, {
            operation: 'widget:update',
            message: 'No fields to update',
          });
          return;
        }

        values.push(widgetId, canvasId);

        const result = await pool.query(
          `UPDATE widgets 
           SET ${updateFields.join(', ')}, updated_at = NOW()
           WHERE id = $${paramCount} AND canvas_id = $${paramCount + 1}
           RETURNING *`,
          values
        );

        if (result.rows.length === 0) {
          socket.emit(SERVER_EVENTS.SYNC_ERROR, {
            operation: 'widget:update',
            message: 'Widget not found',
          });
          return;
        }

        const updatedWidget = result.rows[0];

        // Create version entry
        await pool.query(
          `INSERT INTO widget_versions (id, widget_id, canvas_id, operation, data, created_by)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [uuidv4(), widgetId, canvasId, 'update', updatedWidget, socket.userId]
        );

        // Broadcast to all users in canvas except sender
        socket.to(`canvas:${canvasId}`).emit(SERVER_EVENTS.WIDGET_UPDATED, {
          widget: updatedWidget,
          userId: socket.userId,
          timestamp: new Date().toISOString(),
        });

        // Acknowledge to sender
        socket.emit('widget:update:success', {
          widget: updatedWidget,
        });

        console.log(`🔄 Widget ${widgetId} updated in canvas ${canvasId}`);
      } catch (error) {
        console.error('Widget update error:', error);
        socket.emit(SERVER_EVENTS.SYNC_ERROR, {
          operation: 'widget:update',
          message: 'Failed to update widget',
        });
      }
    });

    socket.on(CLIENT_EVENTS.WIDGET_DELETE, async (data: WidgetDeletePayload) => {
      try {
        const { canvasId, widgetId } = data;

        // Verify editor access
        const accessCheck = await pool.query(
          `SELECT c.id FROM canvases c
           LEFT JOIN canvas_collaborators cc ON c.id = cc.canvas_id
           WHERE c.id = $1 AND (c.owner_id = $2 OR (cc.user_id = $2 AND cc.role IN ('owner', 'editor')))`,
          [canvasId, socket.userId]
        );

        if (accessCheck.rows.length === 0) {
          socket.emit(SERVER_EVENTS.SYNC_ERROR, {
            operation: 'widget:delete',
            message: 'Insufficient permissions',
          });
          return;
        }

        // Get widget before deletion
        const widgetResult = await pool.query(
          'SELECT * FROM widgets WHERE id = $1 AND canvas_id = $2',
          [widgetId, canvasId]
        );

        if (widgetResult.rows.length === 0) {
          socket.emit(SERVER_EVENTS.SYNC_ERROR, {
            operation: 'widget:delete',
            message: 'Widget not found',
          });
          return;
        }

        // Create version entry before deletion
        await pool.query(
          `INSERT INTO widget_versions (id, widget_id, canvas_id, operation, data, created_by)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [uuidv4(), widgetId, canvasId, 'delete', widgetResult.rows[0], socket.userId]
        );

        // Delete widget
        await pool.query(
          'DELETE FROM widgets WHERE id = $1 AND canvas_id = $2',
          [widgetId, canvasId]
        );

        // Broadcast to all users in canvas except sender
        socket.to(`canvas:${canvasId}`).emit(SERVER_EVENTS.WIDGET_DELETED, {
          widgetId,
          userId: socket.userId,
          timestamp: new Date().toISOString(),
        });

        // Acknowledge to sender
        socket.emit('widget:delete:success', {
          widgetId,
        });

        console.log(`🗑️  Widget ${widgetId} deleted from canvas ${canvasId}`);
      } catch (error) {
        console.error('Widget delete error:', error);
        socket.emit(SERVER_EVENTS.SYNC_ERROR, {
          operation: 'widget:delete',
          message: 'Failed to delete widget',
        });
      }
    });

    // ============================================
    // CURSOR TRACKING
    // ============================================

    socket.on(CLIENT_EVENTS.CURSOR_MOVE, (data: CursorMovePayload) => {
      const { canvasId, position } = data;

      if (socket.currentCanvasId !== canvasId) {
        return;
      }

      // Broadcast cursor position to other users
      socket.to(`canvas:${canvasId}`).emit(SERVER_EVENTS.CURSOR_UPDATED, {
        userId: socket.userId,
        position,
        timestamp: new Date().toISOString(),
      });
    });

    socket.on(CLIENT_EVENTS.CURSOR_HIDE, (data: { canvasId: string }) => {
      const { canvasId } = data;

      // Broadcast cursor hide to other users
      socket.to(`canvas:${canvasId}`).emit(SERVER_EVENTS.CURSOR_HIDDEN, {
        userId: socket.userId,
      });
    });

    // ============================================
    // DISCONNECT
    // ============================================

    socket.on('disconnect', async () => {
      console.log(`🔌 User disconnected: ${socket.userId} (${socket.id})`);

      if (socket.currentCanvasId) {
        await handleCanvasLeave(socket, socket.currentCanvasId);
      }
    });
  });

  console.log('📡 WebSocket handlers configured');
};

// Helper function to handle canvas leave
async function handleCanvasLeave(socket: AuthenticatedSocket, canvasId: string) {
  try {
    // Leave room
    socket.leave(`canvas:${canvasId}`);

    // Remove user from Redis
    const userKey = `canvas:${canvasId}:users`;
    await redis.hdel(userKey, socket.userId!);

    // Notify other users
    socket.to(`canvas:${canvasId}`).emit(SERVER_EVENTS.USER_LEFT, {
      userId: socket.userId,
      timestamp: new Date().toISOString(),
    });

    // Acknowledge to user
    socket.emit(SERVER_EVENTS.CANVAS_LEFT, {
      canvasId,
    });

    if (socket.currentCanvasId === canvasId) {
      socket.currentCanvasId = undefined;
    }

    console.log(`📍 User ${socket.userId} left canvas ${canvasId}`);
  } catch (error) {
    console.error('Canvas leave error:', error);
  }
}
