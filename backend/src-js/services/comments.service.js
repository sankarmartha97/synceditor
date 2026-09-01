/**
 * Comments Service
 * Handles all comment operations including threading, mentions, and annotations
 */

const { pool } = require('../config/database');

/**
 * Extract @mentions from comment content
 * @param {string} content - Comment text
 * @returns {string[]} Array of mentioned user IDs/emails
 */
const extractMentions = (content) => {
  // Match @username or @email patterns
  const mentionRegex = /@(\w+(?:\.\w+)*@?\w*\.?\w*)/g;
  const matches = content.match(mentionRegex);
  
  if (!matches) return [];
  
  // Remove @ prefix and return unique mentions
  return [...new Set(matches.map(m => m.substring(1)))];
};

/**
 * Resolve mentions to user IDs
 * @param {string[]} mentions - Array of usernames/emails
 * @returns {Promise<string[]>} Array of user IDs
 */
const resolveMentions = async (mentions) => {
  if (mentions.length === 0) return [];
  
  try {
    const result = await pool.query(
      `SELECT id FROM users 
       WHERE email = ANY($1) OR name = ANY($1)`,
      [mentions]
    );
    
    return result.rows.map(row => row.id);
  } catch (error) {
    console.error('Error resolving mentions:', error);
    return [];
  }
};

/**
 * Create a new comment
 * @param {Object} data - Comment data
 * @returns {Promise<Object>} Created comment with user info
 */
const createComment = async (data) => {
  const {
    pageId,
    userId,
    content,
    positionX = null,
    positionY = null,
    widgetId = null,
    parentCommentId = null,
  } = data;

  // Validate required fields
  if (!pageId || !userId || !content) {
    throw new Error('Missing required fields: pageId, userId, content');
  }

  // Validate content length
  if (content.length > 5000) {
    throw new Error('Comment content exceeds 5000 characters');
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Verify user has access to page
    const accessCheck = await client.query(
      `SELECT p.id FROM pages p
       LEFT JOIN page_permissions pp ON p.id = pp.page_id AND pp.user_id = $2
       WHERE p.id = $1 
       AND p.deleted_at IS NULL
       AND (p.owner_id = $2 OR pp.permission_type IS NOT NULL)`,
      [pageId, userId]
    );

    if (accessCheck.rows.length === 0) {
      throw new Error('Access denied to page');
    }

    // If replying, verify parent comment exists
    if (parentCommentId) {
      const parentCheck = await client.query(
        `SELECT id FROM comments 
         WHERE id = $1 AND page_id = $2 AND deleted_at IS NULL`,
        [parentCommentId, pageId]
      );

      if (parentCheck.rows.length === 0) {
        throw new Error('Parent comment not found');
      }
    }

    // Create comment
    const commentResult = await client.query(
      `INSERT INTO comments (
        page_id, user_id, content, 
        position_x, position_y, widget_id, parent_comment_id
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *`,
      [pageId, userId, content, positionX, positionY, widgetId, parentCommentId]
    );

    const comment = commentResult.rows[0];

    // Extract and save mentions
    const mentions = extractMentions(content);
    const mentionedUserIds = await resolveMentions(mentions);

    if (mentionedUserIds.length > 0) {
      const mentionValues = mentionedUserIds
        .filter(id => id !== userId) // Don't mention yourself
        .map(id => `('${comment.id}', '${id}')`)
        .join(',');

      if (mentionValues) {
        await client.query(
          `INSERT INTO comment_mentions (comment_id, user_id)
           VALUES ${mentionValues}
           ON CONFLICT (comment_id, user_id) DO NOTHING`
        );
      }
    }

    // Get comment with user info
    const fullCommentResult = await client.query(
      `SELECT 
        c.*,
        u.name as user_name,
        u.email as user_email,
        u.avatar_url as user_avatar,
        (SELECT COUNT(*) FROM comments WHERE parent_comment_id = c.id AND deleted_at IS NULL) as reply_count,
        (SELECT COUNT(*) FROM comment_mentions WHERE comment_id = c.id) as mention_count
       FROM comments c
       JOIN users u ON c.user_id = u.id
       WHERE c.id = $1`,
      [comment.id]
    );

    await client.query('COMMIT');

    return fullCommentResult.rows[0];
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Get all comments for a page
 * @param {string} pageId - Page ID
 * @param {Object} options - Query options (includeResolved, widgetId)
 * @returns {Promise<Array>} Array of comments with user info
 */
const getPageComments = async (pageId, options = {}) => {
  const { includeResolved = true, widgetId = null } = options;

  let query = `
    SELECT 
      c.*,
      u.name as user_name,
      u.email as user_email,
      u.avatar_url as user_avatar,
      ru.name as resolved_by_name,
      (SELECT COUNT(*) FROM comments WHERE parent_comment_id = c.id AND deleted_at IS NULL) as reply_count,
      (SELECT COUNT(*) FROM comment_mentions WHERE comment_id = c.id) as mention_count
    FROM comments c
    JOIN users u ON c.user_id = u.id
    LEFT JOIN users ru ON c.resolved_by = ru.id
    WHERE c.page_id = $1 
    AND c.deleted_at IS NULL
    AND c.parent_comment_id IS NULL
  `;

  const params = [pageId];

  if (!includeResolved) {
    query += ` AND c.resolved = false`;
  }

  if (widgetId) {
    query += ` AND c.widget_id = $${params.length + 1}`;
    params.push(widgetId);
  }

  query += ` ORDER BY c.created_at DESC`;

  const result = await pool.query(query, params);
  return result.rows;
};

/**
 * Get a comment thread (parent + all replies)
 * @param {string} commentId - Parent comment ID
 * @returns {Promise<Object>} Parent comment with replies array
 */
const getCommentThread = async (commentId) => {
  // Get parent comment
  const parentResult = await pool.query(
    `SELECT 
      c.*,
      u.name as user_name,
      u.email as user_email,
      u.avatar_url as user_avatar,
      ru.name as resolved_by_name,
      (SELECT COUNT(*) FROM comments WHERE parent_comment_id = c.id AND deleted_at IS NULL) as reply_count,
      (SELECT COUNT(*) FROM comment_mentions WHERE comment_id = c.id) as mention_count
     FROM comments c
     JOIN users u ON c.user_id = u.id
     LEFT JOIN users ru ON c.resolved_by = ru.id
     WHERE c.id = $1 AND c.deleted_at IS NULL`,
    [commentId]
  );

  if (parentResult.rows.length === 0) {
    throw new Error('Comment not found');
  }

  const parent = parentResult.rows[0];

  // Get all replies
  const repliesResult = await pool.query(
    `SELECT 
      c.*,
      u.name as user_name,
      u.email as user_email,
      u.avatar_url as user_avatar
     FROM comments c
     JOIN users u ON c.user_id = u.id
     WHERE c.parent_comment_id = $1 
     AND c.deleted_at IS NULL
     ORDER BY c.created_at ASC`,
    [commentId]
  );

  return {
    ...parent,
    replies: repliesResult.rows,
  };
};

/**
 * Update a comment
 * @param {string} commentId - Comment ID
 * @param {string} userId - User ID (for authorization)
 * @param {string} content - New content
 * @returns {Promise<Object>} Updated comment
 */
const updateComment = async (commentId, userId, content) => {
  // Validate content
  if (!content || content.length === 0) {
    throw new Error('Comment content cannot be empty');
  }

  if (content.length > 5000) {
    throw new Error('Comment content exceeds 5000 characters');
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Verify user owns the comment
    const ownerCheck = await client.query(
      `SELECT id, page_id FROM comments 
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
      [commentId, userId]
    );

    if (ownerCheck.rows.length === 0) {
      throw new Error('Comment not found or access denied');
    }

    const pageId = ownerCheck.rows[0].page_id;

    // Update comment
    const result = await client.query(
      `UPDATE comments 
       SET content = $1, edited = true, edited_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [content, commentId]
    );

    // Update mentions
    // Delete old mentions
    await client.query(
      `DELETE FROM comment_mentions WHERE comment_id = $1`,
      [commentId]
    );

    // Add new mentions
    const mentions = extractMentions(content);
    const mentionedUserIds = await resolveMentions(mentions);

    if (mentionedUserIds.length > 0) {
      const mentionValues = mentionedUserIds
        .filter(id => id !== userId)
        .map(id => `('${commentId}', '${id}')`)
        .join(',');

      if (mentionValues) {
        await client.query(
          `INSERT INTO comment_mentions (comment_id, user_id)
           VALUES ${mentionValues}
           ON CONFLICT (comment_id, user_id) DO NOTHING`
        );
      }
    }

    // Get updated comment with user info
    const fullResult = await client.query(
      `SELECT 
        c.*,
        u.name as user_name,
        u.email as user_email,
        u.avatar_url as user_avatar,
        (SELECT COUNT(*) FROM comments WHERE parent_comment_id = c.id AND deleted_at IS NULL) as reply_count,
        (SELECT COUNT(*) FROM comment_mentions WHERE comment_id = c.id) as mention_count
       FROM comments c
       JOIN users u ON c.user_id = u.id
       WHERE c.id = $1`,
      [commentId]
    );

    await client.query('COMMIT');

    return fullResult.rows[0];
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Delete a comment (soft delete)
 * @param {string} commentId - Comment ID
 * @param {string} userId - User ID (for authorization)
 * @returns {Promise<void>}
 */
const deleteComment = async (commentId, userId) => {
  // Verify user owns the comment or is page owner
  const result = await pool.query(
    `UPDATE comments c
     SET deleted_at = NOW()
     WHERE c.id = $1 
     AND c.deleted_at IS NULL
     AND (
       c.user_id = $2 
       OR EXISTS (
         SELECT 1 FROM pages p 
         WHERE p.id = c.page_id AND p.owner_id = $2
       )
     )
     RETURNING id`,
    [commentId, userId]
  );

  if (result.rows.length === 0) {
    throw new Error('Comment not found or access denied');
  }

  return { success: true };
};

/**
 * Resolve a comment thread
 * @param {string} commentId - Comment ID
 * @param {string} userId - User ID
 * @param {boolean} resolved - Resolved status
 * @returns {Promise<Object>} Updated comment
 */
const resolveComment = async (commentId, userId, resolved = true) => {
  const result = await pool.query(
    `UPDATE comments
     SET 
       resolved = $1,
       resolved_by = CASE WHEN $1 = true THEN $2 ELSE NULL END,
       resolved_at = CASE WHEN $1 = true THEN NOW() ELSE NULL END
     WHERE id = $3 AND deleted_at IS NULL
     RETURNING *`,
    [resolved, userId, commentId]
  );

  if (result.rows.length === 0) {
    throw new Error('Comment not found');
  }

  // Get full comment with user info
  const fullResult = await pool.query(
    `SELECT 
      c.*,
      u.name as user_name,
      u.email as user_email,
      u.avatar_url as user_avatar,
      ru.name as resolved_by_name,
      (SELECT COUNT(*) FROM comments WHERE parent_comment_id = c.id AND deleted_at IS NULL) as reply_count
     FROM comments c
     JOIN users u ON c.user_id = u.id
     LEFT JOIN users ru ON c.resolved_by = ru.id
     WHERE c.id = $1`,
    [commentId]
  );

  return fullResult.rows[0];
};

/**
 * Get mentions for a user
 * @param {string} userId - User ID
 * @param {boolean} unreadOnly - Only unread mentions
 * @returns {Promise<Array>} Array of comments where user is mentioned
 */
const getUserMentions = async (userId, unreadOnly = false) => {
  let query = `
    SELECT 
      c.*,
      u.name as user_name,
      u.email as user_email,
      u.avatar_url as user_avatar,
      m.read as mention_read,
      m.read_at as mention_read_at,
      p.name as page_name
    FROM comment_mentions m
    JOIN comments c ON m.comment_id = c.id
    JOIN users u ON c.user_id = u.id
    JOIN pages p ON c.page_id = p.id
    WHERE m.user_id = $1 
    AND c.deleted_at IS NULL
  `;

  if (unreadOnly) {
    query += ` AND m.read = false`;
  }

  query += ` ORDER BY c.created_at DESC`;

  const result = await pool.query(query, [userId]);
  return result.rows;
};

/**
 * Mark mention as read
 * @param {string} commentId - Comment ID
 * @param {string} userId - User ID
 * @returns {Promise<void>}
 */
const markMentionAsRead = async (commentId, userId) => {
  await pool.query(
    `UPDATE comment_mentions
     SET read = true, read_at = NOW()
     WHERE comment_id = $1 AND user_id = $2`,
    [commentId, userId]
  );

  return { success: true };
};

/**
 * Get comment statistics for a page
 * @param {string} pageId - Page ID
 * @returns {Promise<Object>} Comment stats
 */
const getPageCommentStats = async (pageId) => {
  const result = await pool.query(
    `SELECT 
      COUNT(*) as total_comments,
      COUNT(*) FILTER (WHERE resolved = false) as unresolved_comments,
      COUNT(*) FILTER (WHERE resolved = true) as resolved_comments,
      COUNT(DISTINCT user_id) as unique_commenters,
      COUNT(*) FILTER (WHERE parent_comment_id IS NOT NULL) as total_replies
     FROM comments
     WHERE page_id = $1 AND deleted_at IS NULL`,
    [pageId]
  );

  return result.rows[0];
};

module.exports = {
  createComment,
  getPageComments,
  getCommentThread,
  updateComment,
  deleteComment,
  resolveComment,
  getUserMentions,
  markMentionAsRead,
  getPageCommentStats,
  extractMentions,
  resolveMentions,
};
