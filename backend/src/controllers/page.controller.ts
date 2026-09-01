/**
 * Page Controller
 * Handles HTTP requests for page operations
 */

import { Request, Response, NextFunction } from 'express';
import { pageService } from '../services/page.service';
import { successResponse, errorResponse } from '../utils/response';
import { CreatePageDTO, UpdatePageDTO, SharePageDTO } from '../models/Page';

export class PageController {
  /**
   * POST /api/pages
   * Create a new page
   */
  async createPage(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      const data: CreatePageDTO = req.body;
      
      if (!data.name || data.name.trim().length === 0) {
        return errorResponse(res, 'Page name is required', 400);
      }
      
      const page = await pageService.createPage(userId, data);
      
      return successResponse(res, page, 'Page created successfully', 201);
    } catch (error: any) {
      next(error);
    }
  }
  
  /**
   * GET /api/pages
   * Get all pages accessible to user
   */
  async getUserPages(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      
      const pages = await pageService.getUserPages(userId);
      
      return successResponse(res, pages);
    } catch (error: any) {
      next(error);
    }
  }
  
  /**
   * GET /api/pages/:id
   * Get specific page by ID
   */
  async getPageById(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const userId = req.user!.userId;
      
      const page = await pageService.getPageById(id, userId);
      
      if (!page) {
        return errorResponse(res, 'Page not found or access denied', 404);
      }
      
      return successResponse(res, page);
    } catch (error: any) {
      next(error);
    }
  }
  
  /**
   * PATCH /api/pages/:id
   * Update page
   */
  async updatePage(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const userId = req.user!.userId;
      const data: UpdatePageDTO = req.body;
      
      const page = await pageService.updatePage(id, userId, data);
      
      return successResponse(res, page, 'Page updated successfully');
    } catch (error: any) {
      if (error.message === 'Insufficient permissions') {
        return errorResponse(res, error.message, 403);
      }
      next(error);
    }
  }
  
  /**
   * DELETE /api/pages/:id
   * Delete page (soft delete)
   */
  async deletePage(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const userId = req.user!.userId;
      
      await pageService.deletePage(id, userId);
      
      return successResponse(res, null, 'Page deleted successfully');
    } catch (error: any) {
      if (error.message === 'Only owner can delete page') {
        return errorResponse(res, error.message, 403);
      }
      next(error);
    }
  }
  
  /**
   * PUT /api/pages/:id/name
   * Rename page
   */
  async renamePage(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const userId = req.user!.userId;
      const { name } = req.body;
      
      if (!name || name.trim().length === 0) {
        return errorResponse(res, 'Page name is required', 400);
      }
      
      const page = await pageService.renamePage(id, userId, name);
      
      return successResponse(res, page, 'Page renamed successfully');
    } catch (error: any) {
      next(error);
    }
  }
  
  /**
   * POST /api/pages/:id/share
   * Share page with another user
   */
  async sharePage(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const userId = req.user!.userId;
      const data: SharePageDTO = req.body;
      
      if (!data.email || !data.permissionType) {
        return errorResponse(res, 'Email and permission type are required', 400);
      }
      
      const permission = await pageService.sharePage(id, userId, data);
      
      return successResponse(res, permission, 'Page shared successfully');
    } catch (error: any) {
      if (error.message === 'Only owner can share page') {
        return errorResponse(res, error.message, 403);
      }
      if (error.message === 'User not found') {
        return errorResponse(res, error.message, 404);
      }
      next(error);
    }
  }
  
  /**
   * GET /api/pages/:id/permissions
   * Get all permissions for a page
   */
  async getPagePermissions(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const userId = req.user!.userId;
      
      // Check if user has access to page
      const userPermission = await pageService.getUserPermission(id, userId);
      if (!userPermission) {
        return errorResponse(res, 'Access denied', 403);
      }
      
      const permissions = await pageService.getPagePermissions(id);
      
      return successResponse(res, permissions);
    } catch (error: any) {
      next(error);
    }
  }
  
  /**
   * DELETE /api/pages/:id/permissions/:userId
   * Revoke user access to page
   */
  async revokeAccess(req: Request, res: Response, next: NextFunction) {
    try {
      const { id, userId: targetUserId } = req.params;
      const userId = req.user!.userId;
      
      await pageService.revokeAccess(id, userId, targetUserId);
      
      return successResponse(res, null, 'Access revoked successfully');
    } catch (error: any) {
      if (error.message.includes('Only owner')) {
        return errorResponse(res, error.message, 403);
      }
      if (error.message.includes('Cannot revoke owner')) {
        return errorResponse(res, error.message, 400);
      }
      next(error);
    }
  }
  
  /**
   * PATCH /api/pages/:id/permissions/:userId
   * Update user permission
   */
  async updatePermission(req: Request, res: Response, next: NextFunction) {
    try {
      const { id, userId: targetUserId } = req.params;
      const userId = req.user!.userId;
      const { permissionType } = req.body;
      
      if (!permissionType) {
        return errorResponse(res, 'Permission type is required', 400);
      }
      
      // Get target user email first
      const pool = require('../config/database').pool;
      const userResult = await pool.query(
        'SELECT email FROM users WHERE id = $1',
        [targetUserId]
      );
      
      if (userResult.rows.length === 0) {
        return errorResponse(res, 'User not found', 404);
      }
      
      const permission = await pageService.sharePage(id, userId, {
        email: userResult.rows[0].email,
        permissionType,
      });
      
      return successResponse(res, permission, 'Permission updated successfully');
    } catch (error: any) {
      next(error);
    }
  }
}

export const pageController = new PageController();
