/**
 * Page Routes
 * API endpoints for page management
 */

const express = require('express');
const router = express.Router();
const pageController = require('../controllers/page.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

// All page routes require authentication
router.use(authMiddleware);

/**
 * @route   POST /api/pages
 * @desc    Create a new page
 * @access  Private
 */
router.post('/', pageController.createPage);

/**
 * @route   GET /api/pages
 * @desc    Get all pages accessible to user
 * @access  Private
 */
router.get('/', pageController.getUserPages);

/**
 * @route   GET /api/pages/:id
 * @desc    Get specific page by ID
 * @access  Private
 */
router.get('/:id', pageController.getPageById);

/**
 * @route   PATCH /api/pages/:id
 * @desc    Update page (name, pageData, etc.)
 * @access  Private (requires edit permission)
 */
router.patch('/:id', pageController.updatePage);

/**
 * @route   DELETE /api/pages/:id
 * @desc    Delete page (soft delete)
 * @access  Private (owner only)
 */
router.delete('/:id', pageController.deletePage);

/**
 * @route   PUT /api/pages/:id/name
 * @desc    Rename page
 * @access  Private (requires edit permission)
 */
router.put('/:id/name', pageController.renamePage);

/**
 * @route   POST /api/pages/:id/share
 * @desc    Share page with another user
 * @access  Private (owner only)
 */
router.post('/:id/share', pageController.sharePage);

/**
 * @route   GET /api/pages/:id/permissions
 * @desc    Get all permissions for a page
 * @access  Private
 */
router.get('/:id/permissions', pageController.getPagePermissions);

/**
 * @route   PATCH /api/pages/:id/permissions/:userId
 * @desc    Update user permission on page
 * @access  Private (owner only)
 */
router.patch('/:id/permissions/:userId', pageController.updatePermission);

/**
 * @route   DELETE /api/pages/:id/permissions/:userId
 * @desc    Revoke user access to page
 * @access  Private (owner only)
 */
router.delete('/:id/permissions/:userId', pageController.revokeAccess);

module.exports = router;
