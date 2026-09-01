/**
 * Comments Controller
 * Handles HTTP requests for comment operations
 */

const commentsService = require('../services/comments.service');
const { successResponse, errorResponse } = require('../utils/response');

/**
 * Create a new comment
 * POST /api/pages/:pageId/comments
 */
const createComment = async (req, res) => {
  try {
    const { pageId } = req.params;
    const userId = req.userId; // From auth middleware
    const { content, positionX, positionY, widgetId, parentCommentId } = req.body;

    // Validate required fields
    if (!content || content.trim().length === 0) {
      return errorResponse(res, 'Comment content is required', 400);
    }

    const comment = await commentsService.createComment({
      pageId,
      userId,
      content: content.trim(),
      positionX,
      positionY,
      widgetId,
      parentCommentId,
    });

    return successResponse(
      res,
      'Comment created successfully',
      comment,
      201
    );
  } catch (error) {
    console.error('❌ Create comment error:', error);
    
    if (error.message === 'Access denied to page') {
      return errorResponse(res, error.message, 403);
    }
    
    if (error.message === 'Parent comment not found') {
      return errorResponse(res, error.message, 404);
    }
    
    if (error.message.includes('exceeds 5000 characters')) {
      return errorResponse(res, error.message, 400);
    }
    
    return errorResponse(res, 'Failed to create comment', 500);
  }
};

/**
 * Get all comments for a page
 * GET /api/pages/:pageId/comments
 * Query params: includeResolved (boolean), widgetId (string)
 */
const getPageComments = async (req, res) => {
  try {
    const { pageId } = req.params;
    const { includeResolved = 'true', widgetId } = req.query;

    const comments = await commentsService.getPageComments(pageId, {
      includeResolved: includeResolved === 'true',
      widgetId: widgetId || null,
    });

    return successResponse(
      res,
      'Comments retrieved successfully',
      comments
    );
  } catch (error) {
    console.error('❌ Get page comments error:', error);
    return errorResponse(res, 'Failed to retrieve comments', 500);
  }
};

/**
 * Get comment thread (parent + replies)
 * GET /api/comments/:commentId/thread
 */
const getCommentThread = async (req, res) => {
  try {
    const { commentId } = req.params;

    const thread = await commentsService.getCommentThread(commentId);

    return successResponse(
      res,
      'Comment thread retrieved successfully',
      thread
    );
  } catch (error) {
    console.error('❌ Get comment thread error:', error);
    
    if (error.message === 'Comment not found') {
      return errorResponse(res, error.message, 404);
    }
    
    return errorResponse(res, 'Failed to retrieve comment thread', 500);
  }
};

/**
 * Update a comment
 * PUT /api/comments/:commentId
 */
const updateComment = async (req, res) => {
  try {
    const { commentId } = req.params;
    const userId = req.userId;
    const { content } = req.body;

    if (!content || content.trim().length === 0) {
      return errorResponse(res, 'Comment content is required', 400);
    }

    const updatedComment = await commentsService.updateComment(
      commentId,
      userId,
      content.trim()
    );

    return successResponse(
      res,
      'Comment updated successfully',
      updatedComment
    );
  } catch (error) {
    console.error('❌ Update comment error:', error);
    
    if (error.message === 'Comment not found or access denied') {
      return errorResponse(res, error.message, 403);
    }
    
    if (error.message.includes('exceeds 5000 characters')) {
      return errorResponse(res, error.message, 400);
    }
    
    return errorResponse(res, 'Failed to update comment', 500);
  }
};

/**
 * Delete a comment
 * DELETE /api/comments/:commentId
 */
const deleteComment = async (req, res) => {
  try {
    const { commentId } = req.params;
    const userId = req.userId;

    await commentsService.deleteComment(commentId, userId);

    return successResponse(
      res,
      'Comment deleted successfully',
      { id: commentId }
    );
  } catch (error) {
    console.error('❌ Delete comment error:', error);
    
    if (error.message === 'Comment not found or access denied') {
      return errorResponse(res, error.message, 403);
    }
    
    return errorResponse(res, 'Failed to delete comment', 500);
  }
};

/**
 * Resolve/unresolve a comment thread
 * PUT /api/comments/:commentId/resolve
 */
const resolveComment = async (req, res) => {
  try {
    const { commentId } = req.params;
    const userId = req.userId;
    const { resolved = true } = req.body;

    const updatedComment = await commentsService.resolveComment(
      commentId,
      userId,
      resolved
    );

    return successResponse(
      res,
      resolved ? 'Comment resolved successfully' : 'Comment reopened successfully',
      updatedComment
    );
  } catch (error) {
    console.error('❌ Resolve comment error:', error);
    
    if (error.message === 'Comment not found') {
      return errorResponse(res, error.message, 404);
    }
    
    return errorResponse(res, 'Failed to resolve comment', 500);
  }
};

/**
 * Get user mentions
 * GET /api/users/me/mentions
 * Query params: unreadOnly (boolean)
 */
const getUserMentions = async (req, res) => {
  try {
    const userId = req.userId;
    const { unreadOnly = 'false' } = req.query;

    const mentions = await commentsService.getUserMentions(
      userId,
      unreadOnly === 'true'
    );

    return successResponse(
      res,
      'Mentions retrieved successfully',
      mentions
    );
  } catch (error) {
    console.error('❌ Get user mentions error:', error);
    return errorResponse(res, 'Failed to retrieve mentions', 500);
  }
};

/**
 * Mark mention as read
 * PUT /api/comments/:commentId/mentions/read
 */
const markMentionAsRead = async (req, res) => {
  try {
    const { commentId } = req.params;
    const userId = req.userId;

    await commentsService.markMentionAsRead(commentId, userId);

    return successResponse(
      res,
      'Mention marked as read',
      { commentId }
    );
  } catch (error) {
    console.error('❌ Mark mention as read error:', error);
    return errorResponse(res, 'Failed to mark mention as read', 500);
  }
};

/**
 * Get comment statistics for a page
 * GET /api/pages/:pageId/comments/stats
 */
const getPageCommentStats = async (req, res) => {
  try {
    const { pageId } = req.params;

    const stats = await commentsService.getPageCommentStats(pageId);

    return successResponse(
      res,
      'Comment stats retrieved successfully',
      stats
    );
  } catch (error) {
    console.error('❌ Get comment stats error:', error);
    return errorResponse(res, 'Failed to retrieve comment stats', 500);
  }
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
};
