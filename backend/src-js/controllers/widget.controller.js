const { v4: uuidv4 } = require('uuid');
const { pool } = require('../config/database');
const { AppError, asyncHandler } = require('../middleware/error.middleware');
const { successResponse } = require('../utils/response');

// Get all widgets for a canvas
const getWidgets = asyncHandler(
  async (req, res, next) => {
    const { canvasId } = req.params;
    const userId = req.user?.userId;

    // Check canvas access
    const accessCheck = await pool.query(
      `SELECT c.id FROM canvases c
       LEFT JOIN canvas_collaborators cc ON c.id = cc.canvas_id
       WHERE c.id = $1 AND (c.owner_id = $2 OR cc.user_id = $2 OR c.is_public = true)`,
      [canvasId, userId]
    );

    if (accessCheck.rows.length === 0) {
      throw new AppError('Canvas not found or access denied', 404);
    }

    // Get all widgets
    const result = await pool.query(
      `SELECT * FROM widgets 
       WHERE canvas_id = $1 
       ORDER BY (position->>'z_index')::int, created_at`,
      [canvasId]
    );

    successResponse(res, result.rows, 'Widgets retrieved successfully');
  }
);

// Get single widget
const getWidgetById = asyncHandler(
  async (req, res, next) => {
    const { canvasId, widgetId } = req.params;
    const userId = req.user?.userId;

    // Check canvas access
    const accessCheck = await pool.query(
      `SELECT c.id FROM canvases c
       LEFT JOIN canvas_collaborators cc ON c.id = cc.canvas_id
       WHERE c.id = $1 AND (c.owner_id = $2 OR cc.user_id = $2 OR c.is_public = true)`,
      [canvasId, userId]
    );

    if (accessCheck.rows.length === 0) {
      throw new AppError('Canvas not found or access denied', 404);
    }

    // Get widget
    const result = await pool.query(
      'SELECT * FROM widgets WHERE id = $1 AND canvas_id = $2',
      [widgetId, canvasId]
    );

    if (result.rows.length === 0) {
      throw new AppError('Widget not found', 404);
    }

    successResponse(res, result.rows[0], 'Widget retrieved successfully');
  }
);

// Create new widget
const createWidget = asyncHandler(
  async (req, res, next) => {
    const { canvasId } = req.params;
    const userId = req.user?.userId;
    const { type, position, size, properties, parent_id } = req.body;

    // Check if user has editor access
    const accessCheck = await pool.query(
      `SELECT c.id FROM canvases c
       LEFT JOIN canvas_collaborators cc ON c.id = cc.canvas_id
       WHERE c.id = $1 AND (c.owner_id = $2 OR (cc.user_id = $2 AND cc.role IN ('owner', 'editor')))`,
      [canvasId, userId]
    );

    if (accessCheck.rows.length === 0) {
      throw new AppError('Canvas not found or insufficient permissions', 403);
    }

    // Create widget
    const widgetId = uuidv4();
    const result = await pool.query(
      `INSERT INTO widgets (id, canvas_id, type, position, size, properties, parent_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [
        widgetId,
        canvasId,
        type,
        position || { x: 0, y: 0, z_index: 0 },
        size || { width: 100, height: 100, width_unit: 'px', height_unit: 'px' },
        properties || {},
        parent_id || null
      ]
    );

    // Create version entry
    await pool.query(
      `INSERT INTO widget_versions (id, widget_id, canvas_id, operation, data, created_by)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [uuidv4(), widgetId, canvasId, 'create', result.rows[0], userId]
    );

    successResponse(res, result.rows[0], 'Widget created successfully', 201);
  }
);

// Update widget
const updateWidget = asyncHandler(
  async (req, res, next) => {
    const { canvasId, widgetId } = req.params;
    const userId = req.user?.userId;
    const updates = req.body;

    // Check if user has editor access
    const accessCheck = await pool.query(
      `SELECT c.id FROM canvases c
       LEFT JOIN canvas_collaborators cc ON c.id = cc.canvas_id
       WHERE c.id = $1 AND (c.owner_id = $2 OR (cc.user_id = $2 AND cc.role IN ('owner', 'editor')))`,
      [canvasId, userId]
    );

    if (accessCheck.rows.length === 0) {
      throw new AppError('Canvas not found or insufficient permissions', 403);
    }

    // Build update query
    const updateFields = [];
    const values = [];
    let paramCount = 1;

    if (updates.type !== undefined) {
      updateFields.push(`type = $${paramCount++}`);
      values.push(updates.type);
    }
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
    if (updates.parent_id !== undefined) {
      updateFields.push(`parent_id = $${paramCount++}`);
      values.push(updates.parent_id);
    }

    if (updateFields.length === 0) {
      throw new AppError('No fields to update', 400);
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
      throw new AppError('Widget not found', 404);
    }

    // Create version entry
    await pool.query(
      `INSERT INTO widget_versions (id, widget_id, canvas_id, operation, data, created_by)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [uuidv4(), widgetId, canvasId, 'update', result.rows[0], userId]
    );

    successResponse(res, result.rows[0], 'Widget updated successfully');
  }
);

// Delete widget
const deleteWidget = asyncHandler(
  async (req, res, next) => {
    const { canvasId, widgetId } = req.params;
    const userId = req.user?.userId;

    // Check if user has editor access
    const accessCheck = await pool.query(
      `SELECT c.id FROM canvases c
       LEFT JOIN canvas_collaborators cc ON c.id = cc.canvas_id
       WHERE c.id = $1 AND (c.owner_id = $2 OR (cc.user_id = $2 AND cc.role IN ('owner', 'editor')))`,
      [canvasId, userId]
    );

    if (accessCheck.rows.length === 0) {
      throw new AppError('Canvas not found or insufficient permissions', 403);
    }

    // Get widget before deletion for version history
    const widgetResult = await pool.query(
      'SELECT * FROM widgets WHERE id = $1 AND canvas_id = $2',
      [widgetId, canvasId]
    );

    if (widgetResult.rows.length === 0) {
      throw new AppError('Widget not found', 404);
    }

    // Create version entry before deletion
    await pool.query(
      `INSERT INTO widget_versions (id, widget_id, canvas_id, operation, data, created_by)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [uuidv4(), widgetId, canvasId, 'delete', widgetResult.rows[0], userId]
    );

    // Delete widget
    await pool.query(
      'DELETE FROM widgets WHERE id = $1 AND canvas_id = $2',
      [widgetId, canvasId]
    );

    successResponse(res, null, 'Widget deleted successfully');
  }
);

// Batch update widgets
const batchUpdateWidgets = asyncHandler(
  async (req, res, next) => {
    const { canvasId } = req.params;
    const userId = req.user?.userId;
    const { widgets } = req.body; // Array of {id, updates}

    if (!Array.isArray(widgets) || widgets.length === 0) {
      throw new AppError('Invalid widgets array', 400);
    }

    // Check if user has editor access
    const accessCheck = await pool.query(
      `SELECT c.id FROM canvases c
       LEFT JOIN canvas_collaborators cc ON c.id = cc.canvas_id
       WHERE c.id = $1 AND (c.owner_id = $2 OR (cc.user_id = $2 AND cc.role IN ('owner', 'editor')))`,
      [canvasId, userId]
    );

    if (accessCheck.rows.length === 0) {
      throw new AppError('Canvas not found or insufficient permissions', 403);
    }

    // Use transaction for batch update
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');
      
      const updatedWidgets = [];
      
      for (const widget of widgets) {
        const { id, updates } = widget;
        
        // Build update query for each widget
        const updateFields = [];
        const values = [];
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

        if (updateFields.length > 0) {
          values.push(id, canvasId);
          
          const result = await client.query(
            `UPDATE widgets 
             SET ${updateFields.join(', ')}, updated_at = NOW()
             WHERE id = $${paramCount} AND canvas_id = $${paramCount + 1}
             RETURNING *`,
            values
          );
          
          if (result.rows.length > 0) {
            updatedWidgets.push(result.rows[0]);
          }
        }
      }
      
      await client.query('COMMIT');
      
      successResponse(res, updatedWidgets, 'Widgets updated successfully');
      
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
);

module.exports = {
  getWidgets,
  getWidgetById,
  createWidget,
  updateWidget,
  deleteWidget,
  batchUpdateWidgets,
};
