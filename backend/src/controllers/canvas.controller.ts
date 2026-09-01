import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';
import pool from '../config/database';
import { AppError, asyncHandler } from '../middleware/error.middleware';
import { successResponse, paginatedResponse } from '../utils/response';

// Get all canvases for current user
export const getCanvases = asyncHandler(
  async (req: Request, res: Response, next: NextFunction) => {
    const userId = req.user?.userId;
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const offset = (page - 1) * limit;

    // Get canvases where user is owner or collaborator
    const result = await pool.query(
      `SELECT DISTINCT c.*, 
              u.name as owner_name,
              u.email as owner_email,
              (SELECT COUNT(*) FROM widgets WHERE canvas_id = c.id) as widget_count,
              (SELECT COUNT(*) FROM canvas_collaborators WHERE canvas_id = c.id) as collaborator_count
       FROM canvases c
       LEFT JOIN users u ON c.owner_id = u.id
       LEFT JOIN canvas_collaborators cc ON c.id = cc.canvas_id
       WHERE c.owner_id = $1 OR cc.user_id = $1
       ORDER BY c.updated_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    // Get total count
    const countResult = await pool.query(
      `SELECT COUNT(DISTINCT c.id) as total
       FROM canvases c
       LEFT JOIN canvas_collaborators cc ON c.id = cc.canvas_id
       WHERE c.owner_id = $1 OR cc.user_id = $1`,
      [userId]
    );

    const total = parseInt(countResult.rows[0].total);

    paginatedResponse(res, result.rows, page, limit, total, 'Canvases retrieved successfully');
  }
);

// Get single canvas by ID
export const getCanvasById = asyncHandler(
  async (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;
    const userId = req.user?.userId;

    // Check access permission
    const accessCheck = await pool.query(
      `SELECT c.* FROM canvases c
       LEFT JOIN canvas_collaborators cc ON c.id = cc.canvas_id
       WHERE c.id = $1 AND (c.owner_id = $2 OR cc.user_id = $2 OR c.is_public = true)`,
      [id, userId]
    );

    if (accessCheck.rows.length === 0) {
      throw new AppError('Canvas not found or access denied', 404);
    }

    // Get canvas with widgets
    const result = await pool.query(
      `SELECT c.*, 
              u.name as owner_name,
              u.email as owner_email,
              json_agg(
                json_build_object(
                  'id', w.id,
                  'type', w.type,
                  'position', w.position,
                  'size', w.size,
                  'properties', w.properties,
                  'parent_id', w.parent_id,
                  'created_at', w.created_at,
                  'updated_at', w.updated_at
                ) ORDER BY w.created_at
              ) FILTER (WHERE w.id IS NOT NULL) as widgets
       FROM canvases c
       LEFT JOIN users u ON c.owner_id = u.id
       LEFT JOIN widgets w ON c.id = w.canvas_id
       WHERE c.id = $1
       GROUP BY c.id, u.name, u.email`,
      [id]
    );

    successResponse(res, result.rows[0], 'Canvas retrieved successfully');
  }
);

// Create new canvas
export const createCanvas = asyncHandler(
  async (req: Request, res: Response, next: NextFunction) => {
    const userId = req.user?.userId;
    const { name, description, settings, is_public } = req.body;

    const canvasId = uuidv4();
    const result = await pool.query(
      `INSERT INTO canvases (id, owner_id, name, description, settings, is_public)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [canvasId, userId, name, description || null, settings || {}, is_public || false]
    );

    successResponse(res, result.rows[0], 'Canvas created successfully', 201);
  }
);

// Update canvas
export const updateCanvas = asyncHandler(
  async (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;
    const userId = req.user?.userId;
    const { name, description, settings, is_public } = req.body;

    // Check if user is owner
    const ownerCheck = await pool.query(
      'SELECT id FROM canvases WHERE id = $1 AND owner_id = $2',
      [id, userId]
    );

    if (ownerCheck.rows.length === 0) {
      throw new AppError('Canvas not found or you do not have permission to update it', 403);
    }

    // Build update query dynamically
    const updates: string[] = [];
    const values: any[] = [];
    let paramCount = 1;

    if (name !== undefined) {
      updates.push(`name = $${paramCount++}`);
      values.push(name);
    }
    if (description !== undefined) {
      updates.push(`description = $${paramCount++}`);
      values.push(description);
    }
    if (settings !== undefined) {
      updates.push(`settings = $${paramCount++}`);
      values.push(settings);
    }
    if (is_public !== undefined) {
      updates.push(`is_public = $${paramCount++}`);
      values.push(is_public);
    }

    if (updates.length === 0) {
      throw new AppError('No fields to update', 400);
    }

    values.push(id);

    const result = await pool.query(
      `UPDATE canvases SET ${updates.join(', ')}, updated_at = NOW()
       WHERE id = $${paramCount}
       RETURNING *`,
      values
    );

    successResponse(res, result.rows[0], 'Canvas updated successfully');
  }
);

// Delete canvas
export const deleteCanvas = asyncHandler(
  async (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;
    const userId = req.user?.userId;

    // Check if user is owner
    const ownerCheck = await pool.query(
      'SELECT id FROM canvases WHERE id = $1 AND owner_id = $2',
      [id, userId]
    );

    if (ownerCheck.rows.length === 0) {
      throw new AppError('Canvas not found or you do not have permission to delete it', 403);
    }

    // Delete canvas (widgets will be cascade deleted)
    await pool.query('DELETE FROM canvases WHERE id = $1', [id]);

    successResponse(res, null, 'Canvas deleted successfully');
  }
);

// Get canvas collaborators
export const getCollaborators = asyncHandler(
  async (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;
    const userId = req.user?.userId;

    // Check if user has access to canvas
    const accessCheck = await pool.query(
      `SELECT c.id FROM canvases c
       LEFT JOIN canvas_collaborators cc ON c.id = cc.canvas_id
       WHERE c.id = $1 AND (c.owner_id = $2 OR cc.user_id = $2)`,
      [id, userId]
    );

    if (accessCheck.rows.length === 0) {
      throw new AppError('Canvas not found or access denied', 404);
    }

    // Get collaborators
    const result = await pool.query(
      `SELECT cc.id, cc.role, cc.created_at,
              u.id as user_id, u.name, u.email, u.avatar_url
       FROM canvas_collaborators cc
       JOIN users u ON cc.user_id = u.id
       WHERE cc.canvas_id = $1
       ORDER BY cc.created_at DESC`,
      [id]
    );

    successResponse(res, result.rows, 'Collaborators retrieved successfully');
  }
);

// Add collaborator to canvas
export const addCollaborator = asyncHandler(
  async (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;
    const userId = req.user?.userId;
    const { user_id, role } = req.body;

    // Check if user is owner
    const ownerCheck = await pool.query(
      'SELECT id FROM canvases WHERE id = $1 AND owner_id = $2',
      [id, userId]
    );

    if (ownerCheck.rows.length === 0) {
      throw new AppError('Canvas not found or you do not have permission', 403);
    }

    // Check if collaborator user exists
    const userCheck = await pool.query('SELECT id FROM users WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      throw new AppError('User not found', 404);
    }

    // Add collaborator
    const collaboratorId = uuidv4();
    const result = await pool.query(
      `INSERT INTO canvas_collaborators (id, canvas_id, user_id, role)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [collaboratorId, id, user_id, role || 'viewer']
    );

    successResponse(res, result.rows[0], 'Collaborator added successfully', 201);
  }
);

// Remove collaborator
export const removeCollaborator = asyncHandler(
  async (req: Request, res: Response, next: NextFunction) => {
    const { id, userId: collaboratorUserId } = req.params;
    const userId = req.user?.userId;

    // Check if user is owner
    const ownerCheck = await pool.query(
      'SELECT id FROM canvases WHERE id = $1 AND owner_id = $2',
      [id, userId]
    );

    if (ownerCheck.rows.length === 0) {
      throw new AppError('Canvas not found or you do not have permission', 403);
    }

    // Remove collaborator
    await pool.query(
      'DELETE FROM canvas_collaborators WHERE canvas_id = $1 AND user_id = $2',
      [id, collaboratorUserId]
    );

    successResponse(res, null, 'Collaborator removed successfully');
  }
);
