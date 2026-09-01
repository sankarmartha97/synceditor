/**
 * Comments Routes
 * API endpoints for comment operations
 */

const express = require('express');
const router = express.Router();
const commentsController = require('../controllers/comments.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

// All comment routes require authentication
router.use(authMiddleware);

// ============================================
// Page Comments Routes
// ============================================

/**
 * @route   POST /api/pages/:pageId/comments
 * @desc    Create a new comment on a page
 * @access  Private (authenticated users with page access)
 * @body    {content, positionX?, positionY?, widgetId?, parentCommentId?}
 */
router.post(
  '/pages/:pageId/comments',
  commentsController.createComment
);

/**
 * @route   GET /api/pages/:pageId/comments
 * @desc    Get all comments for a page
 * @access  Private (authenticated users with page access)
 * @query   includeResolved (boolean), widgetId (string)
 */
router.get(
  '/pages/:pageId/comments',
  commentsController.getPageComments
);

/**
 * @route   GET /api/pages/:pageId/comments/stats
 * @desc    Get comment statistics for a page
 * @access  Private (authenticated users with page access)
 */
router.get(
  '/pages/:pageId/comments/stats',
  commentsController.getPageCommentStats
);

// ============================================
// Individual Comment Routes
// ============================================

/**
 * @route   GET /api/comments/:commentId/thread
 * @desc    Get a comment thread (parent + all replies)
 * @access  Private (authenticated users with page access)
 */
router.get(
  '/comments/:commentId/thread',
  commentsController.getCommentThread
);

/**
 * @route   PUT /api/comments/:commentId
 * @desc    Update a comment (owner only)
 * @access  Private (comment owner)
 * @body    {content}
 */
router.put(
  '/comments/:commentId',
  commentsController.updateComment
);

/**
 * @route   DELETE /api/comments/:commentId
 * @desc    Delete a comment (soft delete, owner or page owner only)
 * @access  Private (comment owner or page owner)
 */
router.delete(
  '/comments/:commentId',
  commentsController.deleteComment
);

/**
 * @route   PUT /api/comments/:commentId/resolve
 * @desc    Resolve or reopen a comment thread
 * @access  Private (authenticated users with page access)
 * @body    {resolved: boolean}
 */
router.put(
  '/comments/:commentId/resolve',
  commentsController.resolveComment
);

/**
 * @route   PUT /api/comments/:commentId/mentions/read
 * @desc    Mark a mention as read
 * @access  Private (mentioned user)
 */
router.put(
  '/comments/:commentId/mentions/read',
  commentsController.markMentionAsRead
);

// ============================================
// User Mentions Routes
// ============================================

/**
 * @route   GET /api/users/me/mentions
 * @desc    Get all mentions for current user
 * @access  Private (authenticated user)
 * @query   unreadOnly (boolean)
 */
router.get(
  '/users/me/mentions',
  commentsController.getUserMentions
);

module.exports = router;
