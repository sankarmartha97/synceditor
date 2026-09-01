import { Router } from 'express';
import {
  getCanvases,
  getCanvasById,
  createCanvas,
  updateCanvas,
  deleteCanvas,
  getCollaborators,
  addCollaborator,
  removeCollaborator,
} from '../controllers/canvas.controller';
import {
  getWidgets,
  getWidgetById,
  createWidget,
  updateWidget,
  deleteWidget,
  batchUpdateWidgets,
} from '../controllers/widget.controller';
import { authMiddleware } from '../middleware/auth.middleware';

const router = Router();

// All canvas routes require authentication
router.use(authMiddleware);

// ============================================
// CANVAS ROUTES
// ============================================

/**
 * @route   GET /api/canvases
 * @desc    Get all canvases for current user
 * @access  Private
 */
router.get('/', getCanvases);

/**
 * @route   POST /api/canvases
 * @desc    Create new canvas
 * @access  Private
 */
router.post('/', createCanvas);

/**
 * @route   GET /api/canvases/:id
 * @desc    Get canvas by ID with widgets
 * @access  Private
 */
router.get('/:id', getCanvasById);

/**
 * @route   PUT /api/canvases/:id
 * @desc    Update canvas
 * @access  Private (Owner only)
 */
router.put('/:id', updateCanvas);

/**
 * @route   DELETE /api/canvases/:id
 * @desc    Delete canvas
 * @access  Private (Owner only)
 */
router.delete('/:id', deleteCanvas);

// ============================================
// COLLABORATOR ROUTES
// ============================================

/**
 * @route   GET /api/canvases/:id/collaborators
 * @desc    Get canvas collaborators
 * @access  Private
 */
router.get('/:id/collaborators', getCollaborators);

/**
 * @route   POST /api/canvases/:id/collaborators
 * @desc    Add collaborator to canvas
 * @access  Private (Owner only)
 */
router.post('/:id/collaborators', addCollaborator);

/**
 * @route   DELETE /api/canvases/:id/collaborators/:userId
 * @desc    Remove collaborator from canvas
 * @access  Private (Owner only)
 */
router.delete('/:id/collaborators/:userId', removeCollaborator);

// ============================================
// WIDGET ROUTES
// ============================================

/**
 * @route   GET /api/canvases/:canvasId/widgets
 * @desc    Get all widgets for a canvas
 * @access  Private
 */
router.get('/:canvasId/widgets', getWidgets);

/**
 * @route   POST /api/canvases/:canvasId/widgets
 * @desc    Create new widget
 * @access  Private (Editor role)
 */
router.post('/:canvasId/widgets', createWidget);

/**
 * @route   POST /api/canvases/:canvasId/widgets/batch
 * @desc    Batch update widgets
 * @access  Private (Editor role)
 */
router.post('/:canvasId/widgets/batch', batchUpdateWidgets);

/**
 * @route   GET /api/canvases/:canvasId/widgets/:widgetId
 * @desc    Get widget by ID
 * @access  Private
 */
router.get('/:canvasId/widgets/:widgetId', getWidgetById);

/**
 * @route   PUT /api/canvases/:canvasId/widgets/:widgetId
 * @desc    Update widget
 * @access  Private (Editor role)
 */
router.put('/:canvasId/widgets/:widgetId', updateWidget);

/**
 * @route   DELETE /api/canvases/:canvasId/widgets/:widgetId
 * @desc    Delete widget
 * @access  Private (Editor role)
 */
router.delete('/:canvasId/widgets/:widgetId', deleteWidget);

export default router;
