/**
 * Page Routes
 * API endpoints for page management
 */

import { Router } from 'express';
import { pageController } from '../controllers/page.controller';
import { authMiddleware } from '../middleware/auth.middleware';

const router = Router();

// All page routes require authentication
router.use(authMiddleware);

/**
 * @route   POST /api/pages
 * @desc    Create a new page
 * @access  Private
 */
router.post('/', (req, res, next) => 
  pageController.createPage(req, res, next)
);

/**
 * @route   GET /api/pages
 * @desc    Get all pages accessible to user
 * @access  Private
 */
router.get('/', (req, res, next) => 
  pageController.getUserPages(req, res, next)
);

/**
 * @route   GET /api/pages/:id
 * @desc    Get specific page by ID
 * @access  Private
 */
router.get('/:id', (req, res, next) => 
  pageController.getPageById(req, res, next)
);

/**
 * @route   PATCH /api/pages/:id
 * @desc    Update page (name, pageData, etc.)
 * @access  Private (requires edit permission)
 */
router.patch('/:id', (req, res, next) => 
  pageController.updatePage(req, res, next)
);

/**
 * @route   DELETE /api/pages/:id
 * @desc    Delete page (soft delete)
 * @access  Private (owner only)
 */
router.delete('/:id', (req, res, next) => 
  pageController.deletePage(req, res, next)
);

/**
 * @route   PUT /api/pages/:id/name
 * @desc    Rename page
 * @access  Private (requires edit permission)
 */
router.put('/:id/name', (req, res, next) => 
  pageController.renamePage(req, res, next)
);

/**
 * @route   POST /api/pages/:id/share
 * @desc    Share page with another user
 * @access  Private (owner only)
 */
router.post('/:id/share', (req, res, next) => 
  pageController.sharePage(req, res, next)
);

/**
 * @route   GET /api/pages/:id/permissions
 * @desc    Get all permissions for a page
 * @access  Private
 */
router.get('/:id/permissions', (req, res, next) => 
  pageController.getPagePermissions(req, res, next)
);

/**
 * @route   PATCH /api/pages/:id/permissions/:userId
 * @desc    Update user permission on page
 * @access  Private (owner only)
 */
router.patch('/:id/permissions/:userId', (req, res, next) => 
  pageController.updatePermission(req, res, next)
);

/**
 * @route   DELETE /api/pages/:id/permissions/:userId
 * @desc    Revoke user access to page
 * @access  Private (owner only)
 */
router.delete('/:id/permissions/:userId', (req, res, next) => 
  pageController.revokeAccess(req, res, next)
);

export default router;
