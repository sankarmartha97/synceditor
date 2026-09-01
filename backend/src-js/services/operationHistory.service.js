/**
 * Operation History Service
 * Manages operation history for undo/redo functionality
 */

const { pool } = require('../config/database');

/**
 * Extract operation type from JSON Patch operation
 * @param {Object} operation - JSON Patch operation
 * @returns {string} Operation type: 'add', 'remove', 'replace', 'move', 'copy'
 */
const extractOperationType = (operation) => {
  return operation.op || 'unknown';
};

/**
 * Extract affected paths from operations
 * @param {Array} operations - Array of JSON Patch operations
 * @returns {Array} Array of paths
 */
const extractAffectedPaths = (operations) => {
  const paths = new Set();
  
  operations.forEach(op => {
    if (op.path) paths.add(op.path);
    if (op.from) paths.add(op.from); // For move/copy operations
  });
  
  return Array.from(paths);
};

/**
 * Save an operation to history
 * @param {Object} params
 * @returns {Promise<Object>} Saved operation record
 */
const saveOperation = async ({
  pageId,
  userId,
  operation,
  inverseOperation,
  fromVersion,
  toVersion,
  parentOperations = [],
}) => {
  try {
    // Extract metadata
    const operationType = extractOperationType(operation[0]);
    const affectedPaths = extractAffectedPaths(operation);

    const result = await pool.query(
      `INSERT INTO operation_history (
        page_id, user_id, operation, inverse_operation,
        from_version, to_version, parent_operations,
        operation_type, affected_paths
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *`,
      [
        pageId,
        userId,
        JSON.stringify(operation),
        JSON.stringify(inverseOperation),
        fromVersion,
        toVersion,
        parentOperations,
        operationType,
        affectedPaths,
      ]
    );

    return result.rows[0];
  } catch (error) {
    console.error('❌ Save operation error:', error);
    throw error;
  }
};

/**
 * Get operations by user for a page (for undo stack)
 * @param {string} pageId
 * @param {string} userId
 * @param {number} limit - Max operations to retrieve
 * @returns {Promise<Array>} Array of operations
 */
const getOperationsByUser = async (pageId, userId, limit = 100) => {
  try {
    const result = await pool.query(
      `SELECT * FROM operation_history
       WHERE page_id = $1 AND user_id = $2
       ORDER BY created_at DESC
       LIMIT $3`,
      [pageId, userId, limit]
    );

    return result.rows.map(row => ({
      ...row,
      operation: JSON.parse(row.operation),
      inverse_operation: JSON.parse(row.inverse_operation),
    }));
  } catch (error) {
    console.error('❌ Get operations by user error:', error);
    throw error;
  }
};

/**
 * Get operations between versions (for OT transformation)
 * @param {string} pageId
 * @param {number} fromVersion - Start version (exclusive)
 * @param {number} toVersion - End version (inclusive)
 * @returns {Promise<Array>} Array of operations
 */
const getOperationsBetweenVersions = async (pageId, fromVersion, toVersion) => {
  try {
    const result = await pool.query(
      `SELECT * FROM operation_history
       WHERE page_id = $1 
       AND from_version >= $2 
       AND to_version <= $3
       ORDER BY to_version ASC`,
      [pageId, fromVersion, toVersion]
    );

    return result.rows.map(row => ({
      ...row,
      operation: JSON.parse(row.operation),
      inverse_operation: JSON.parse(row.inverse_operation),
    }));
  } catch (error) {
    console.error('❌ Get operations between versions error:', error);
    throw error;
  }
};

/**
 * Get operation by ID
 * @param {string} operationId
 * @returns {Promise<Object>} Operation record
 */
const getOperationById = async (operationId) => {
  try {
    const result = await pool.query(
      `SELECT * FROM operation_history WHERE id = $1`,
      [operationId]
    );

    if (result.rows.length === 0) {
      throw new Error('Operation not found');
    }

    const row = result.rows[0];
    return {
      ...row,
      // PostgreSQL returns JSONB as already-parsed objects, no need to parse again
      operation: typeof row.operation === 'string' ? JSON.parse(row.operation) : row.operation,
      inverse_operation: typeof row.inverse_operation === 'string' ? JSON.parse(row.inverse_operation) : row.inverse_operation,
    };
  } catch (error) {
    console.error('❌ Get operation by ID error:', error);
    throw error;
  }
};

/**
 * Get all operations since a version (for conflict detection)
 * @param {string} pageId
 * @param {number} sinceVersion
 * @returns {Promise<Array>} Array of operations
 */
const getOperationsSinceVersion = async (pageId, sinceVersion) => {
  try {
    const result = await pool.query(
      `SELECT * FROM operation_history
       WHERE page_id = $1 AND from_version >= $2
       ORDER BY to_version ASC`,
      [pageId, sinceVersion]
    );

    // PostgreSQL returns JSONB columns as objects, no need to parse
    return result.rows.map(row => ({
      ...row,
      operation: typeof row.operation === 'string' ? JSON.parse(row.operation) : row.operation,
      inverse_operation: typeof row.inverse_operation === 'string' ? JSON.parse(row.inverse_operation) : row.inverse_operation,
    }));
  } catch (error) {
    console.error('❌ Get operations since version error:', error);
    throw error;
  }
};

/**
 * Get user's undo stack
 * @param {string} pageId
 * @param {string} userId
 * @returns {Promise<Object>} Undo stack data
 */
const getUserUndoStack = async (pageId, userId) => {
  try {
    const result = await pool.query(
      `SELECT * FROM user_undo_stacks
       WHERE page_id = $1 AND user_id = $2`,
      [pageId, userId]
    );

    if (result.rows.length === 0) {
      // Create new stack if doesn't exist
      const createResult = await pool.query(
        `INSERT INTO user_undo_stacks (page_id, user_id)
         VALUES ($1, $2)
         RETURNING *`,
        [pageId, userId]
      );
      return createResult.rows[0];
    }

    return result.rows[0];
  } catch (error) {
    console.error('❌ Get user undo stack error:', error);
    throw error;
  }
};

/**
 * Push operation to undo stack
 * @param {string} pageId
 * @param {string} userId
 * @param {string} operationId
 * @returns {Promise<void>}
 */
const pushToUndoStack = async (pageId, userId, operationId) => {
  try {
    await pool.query(
      `INSERT INTO user_undo_stacks (page_id, user_id, undo_stack)
       VALUES ($1, $2, ARRAY[$3]::UUID[])
       ON CONFLICT (page_id, user_id)
       DO UPDATE SET 
         undo_stack = ARRAY[$3]::UUID[] || user_undo_stacks.undo_stack,
         redo_stack = ARRAY[]::UUID[], -- Clear redo stack on new operation
         updated_at = NOW()`,
      [pageId, userId, operationId]
    );
  } catch (error) {
    console.error('❌ Push to undo stack error:', error);
    throw error;
  }
};

/**
 * Pop from undo stack and push to redo stack
 * @param {string} pageId
 * @param {string} userId
 * @returns {Promise<string|null>} Operation ID or null if stack empty
 */
const popFromUndoStack = async (pageId, userId) => {
  try {
    const result = await pool.query(
      `UPDATE user_undo_stacks
       SET 
         undo_stack = undo_stack[2:array_length(undo_stack, 1)],
         redo_stack = ARRAY[undo_stack[1]] || redo_stack,
         updated_at = NOW()
       WHERE page_id = $1 AND user_id = $2
       AND array_length(undo_stack, 1) > 0
       RETURNING undo_stack[1] as operation_id`,
      [pageId, userId]
    );

    if (result.rows.length === 0) {
      return null; // Stack was empty
    }

    return result.rows[0].operation_id;
  } catch (error) {
    console.error('❌ Pop from undo stack error:', error);
    throw error;
  }
};

/**
 * Pop from redo stack and push to undo stack
 * @param {string} pageId
 * @param {string} userId
 * @returns {Promise<string|null>} Operation ID or null if stack empty
 */
const popFromRedoStack = async (pageId, userId) => {
  try {
    // First, get the top of redo stack
    const getResult = await pool.query(
      `SELECT redo_stack[1] as operation_id
       FROM user_undo_stacks
       WHERE page_id = $1 AND user_id = $2
       AND array_length(redo_stack, 1) > 0`,
      [pageId, userId]
    );

    if (getResult.rows.length === 0) {
      return null; // Stack was empty
    }

    const operationId = getResult.rows[0].operation_id;

    // Now pop from redo and push to undo
    await pool.query(
      `UPDATE user_undo_stacks
       SET 
         redo_stack = redo_stack[2:array_length(redo_stack, 1)],
         undo_stack = ARRAY[$3::uuid] || undo_stack,
         updated_at = NOW()
       WHERE page_id = $1 AND user_id = $2`,
      [pageId, userId, operationId]
    );

    return operationId;
  } catch (error) {
    console.error('❌ Pop from redo stack error:', error);
    throw error;
  }
};

/**
 * Check if user can undo
 * @param {string} pageId
 * @param {string} userId
 * @returns {Promise<boolean>}
 */
const canUndo = async (pageId, userId) => {
  try {
    const result = await pool.query(
      `SELECT array_length(undo_stack, 1) as stack_size
       FROM user_undo_stacks
       WHERE page_id = $1 AND user_id = $2`,
      [pageId, userId]
    );

    if (result.rows.length === 0) return false;
    return (result.rows[0].stack_size || 0) > 0;
  } catch (error) {
    console.error('❌ Can undo check error:', error);
    return false;
  }
};

/**
 * Check if user can redo
 * @param {string} pageId
 * @param {string} userId
 * @returns {Promise<boolean>}
 */
const canRedo = async (pageId, userId) => {
  try {
    const result = await pool.query(
      `SELECT array_length(redo_stack, 1) as stack_size
       FROM user_undo_stacks
       WHERE page_id = $1 AND user_id = $2`,
      [pageId, userId]
    );

    if (result.rows.length === 0) return false;
    return (result.rows[0].stack_size || 0) > 0;
  } catch (error) {
    console.error('❌ Can redo check error:', error);
    return false;
  }
};

/**
 * Get operation statistics for a page
 * @param {string} pageId
 * @returns {Promise<Object>} Operation statistics
 */
const getOperationStats = async (pageId) => {
  try {
    const result = await pool.query(
      `SELECT 
        COUNT(*) as total_operations,
        COUNT(DISTINCT user_id) as unique_users,
        MAX(to_version) as latest_version,
        MIN(created_at) as first_operation_at,
        MAX(created_at) as last_operation_at
       FROM operation_history
       WHERE page_id = $1`,
      [pageId]
    );

    return result.rows[0];
  } catch (error) {
    console.error('❌ Get operation stats error:', error);
    throw error;
  }
};

/**
 * Cleanup old operations (maintenance function)
 * @param {number} daysToKeep - Keep operations from last N days
 * @returns {Promise<number>} Number of deleted operations
 */
const cleanupOldOperations = async (daysToKeep = 30) => {
  try {
    const result = await pool.query(
      `SELECT * FROM cleanup_old_operations($1)`,
      [daysToKeep]
    );

    const deletedCount = result.rows[0].deleted_count;
    console.log(`🗑️ Cleaned up ${deletedCount} old operations`);
    return deletedCount;
  } catch (error) {
    console.error('❌ Cleanup old operations error:', error);
    throw error;
  }
};

/**
 * Trim undo/redo stacks to max size (maintenance function)
 * @returns {Promise<number>} Number of trimmed users
 */
const trimUndoStacks = async () => {
  try {
    const result = await pool.query(`SELECT * FROM trim_undo_stacks()`);
    
    const trimmedCount = result.rows[0].trimmed_users;
    console.log(`✂️ Trimmed ${trimmedCount} user undo/redo stacks`);
    return trimmedCount;
  } catch (error) {
    console.error('❌ Trim undo stacks error:', error);
    throw error;
  }
};

module.exports = {
  saveOperation,
  getOperationsByUser,
  getOperationsBetweenVersions,
  getOperationById,
  getOperationsSinceVersion,
  getUserUndoStack,
  pushToUndoStack,
  popFromUndoStack,
  popFromRedoStack,
  canUndo,
  canRedo,
  getOperationStats,
  cleanupOldOperations,
  trimUndoStacks,
};
