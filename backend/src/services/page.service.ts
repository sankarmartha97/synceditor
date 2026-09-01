/**
 * Page Service
 * Business logic for page management and CRUD operations
 */

import { pool } from '../config/database';
import {
  Page,
  PageData,
  PagePermission,
  PageListItem,
  CreatePageDTO,
  UpdatePageDTO,
  PermissionType,
  PageMetadata,
  SharePageDTO,
} from '../models/Page';

export class PageService {
  /**
   * Create a new page
   */
  async createPage(
    userId: string,
    data: CreatePageDTO
  ): Promise<Page> {
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');
      
      // Create default page data structure
      const pageData: PageData = {
        pageId: '', // Will be set after insert
        name: data.name,
        version: 1,
        metadata: {
          width: data.metadata?.width || 1920,
          height: data.metadata?.height || 1080,
          backgroundColor: data.metadata?.backgroundColor || '#FFFFFF',
          gridSize: data.metadata?.gridSize || 10,
          showGrid: data.metadata?.showGrid ?? true,
          snapToGrid: data.metadata?.snapToGrid ?? false,
          zoom: data.metadata?.zoom || 1.0,
        },
        widgets: [],
      };
      
      // Insert page
      const pageResult = await client.query(
        `INSERT INTO pages (name, owner_id, page_data, version)
         VALUES ($1, $2, $3, $4)
         RETURNING *`,
        [data.name, userId, JSON.stringify(pageData), 1]
      );
      
      const page = pageResult.rows[0];
      
      // Update pageId in page_data
      page.page_data.pageId = page.id;
      await client.query(
        `UPDATE pages SET page_data = $1 WHERE id = $2`,
        [JSON.stringify(page.page_data), page.id]
      );
      
      // Grant owner permission
      await client.query(
        `INSERT INTO page_permissions (page_id, user_id, permission_type, granted_by)
         VALUES ($1, $2, $3, $4)`,
        [page.id, userId, PermissionType.OWNER, userId]
      );
      
      await client.query('COMMIT');
      
      return this.mapToPage(page);
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
  
  /**
   * Get page by ID
   */
  async getPageById(pageId: string, userId: string): Promise<Page | null> {
    const result = await pool.query(
      `SELECT p.* 
       FROM pages p
       INNER JOIN page_permissions pp ON p.id = pp.page_id
       WHERE p.id = $1 
       AND pp.user_id = $2 
       AND p.deleted_at IS NULL`,
      [pageId, userId]
    );
    
    if (result.rows.length === 0) {
      return null;
    }
    
    return this.mapToPage(result.rows[0]);
  }
  
  /**
   * Get all pages accessible to user
   */
  async getUserPages(userId: string): Promise<PageListItem[]> {
    const result = await pool.query(
      `SELECT p.id, p.name, p.owner_id, p.version, p.created_at, p.updated_at,
              pp.permission_type
       FROM pages p
       INNER JOIN page_permissions pp ON p.id = pp.page_id
       WHERE pp.user_id = $1 
       AND p.deleted_at IS NULL
       ORDER BY p.updated_at DESC`,
      [userId]
    );
    
    return result.rows.map(row => ({
      id: row.id,
      name: row.name,
      ownerId: row.owner_id,
      version: row.version,
      permission: row.permission_type as PermissionType,
      updatedAt: row.updated_at,
      createdAt: row.created_at,
    }));
  }
  
  /**
   * Update page
   */
  async updatePage(
    pageId: string,
    userId: string,
    data: UpdatePageDTO
  ): Promise<Page> {
    const client = await pool.connect();
    
    try {
      // Check permission
      const hasPermission = await this.checkEditPermission(pageId, userId);
      if (!hasPermission) {
        throw new Error('Insufficient permissions');
      }
      
      const updates: string[] = [];
      const values: any[] = [];
      let paramCount = 1;
      
      if (data.name) {
        updates.push(`name = $${paramCount++}`);
        values.push(data.name);
      }
      
      if (data.pageData) {
        updates.push(`page_data = $${paramCount++}`);
        values.push(JSON.stringify(data.pageData));
      }
      
      updates.push(`updated_at = NOW()`);
      values.push(pageId);
      
      const result = await client.query(
        `UPDATE pages 
         SET ${updates.join(', ')}
         WHERE id = $${paramCount}
         RETURNING *`,
        values
      );
      
      return this.mapToPage(result.rows[0]);
    } finally {
      client.release();
    }
  }
  
  /**
   * Delete page (soft delete)
   */
  async deletePage(pageId: string, userId: string): Promise<void> {
    const client = await pool.connect();
    
    try {
      // Check if user is owner
      const isOwner = await this.isOwner(pageId, userId);
      if (!isOwner) {
        throw new Error('Only owner can delete page');
      }
      
      await client.query(
        `UPDATE pages 
         SET deleted_at = NOW() 
         WHERE id = $1`,
        [pageId]
      );
    } finally {
      client.release();
    }
  }
  
  /**
   * Rename page
   */
  async renamePage(
    pageId: string,
    userId: string,
    newName: string
  ): Promise<Page> {
    return this.updatePage(pageId, userId, { name: newName });
  }
  
  /**
   * Share page with another user
   */
  async sharePage(
    pageId: string,
    ownerId: string,
    data: SharePageDTO
  ): Promise<PagePermission> {
    const client = await pool.connect();
    
    try {
      // Check if owner
      const isOwner = await this.isOwner(pageId, ownerId);
      if (!isOwner) {
        throw new Error('Only owner can share page');
      }
      
      // Find user by email
      const userResult = await client.query(
        `SELECT id FROM users WHERE email = $1`,
        [data.email]
      );
      
      if (userResult.rows.length === 0) {
        throw new Error('User not found');
      }
      
      const targetUserId = userResult.rows[0].id;
      
      // Check if permission already exists
      const existingPerm = await client.query(
        `SELECT * FROM page_permissions WHERE page_id = $1 AND user_id = $2`,
        [pageId, targetUserId]
      );
      
      if (existingPerm.rows.length > 0) {
        // Update existing permission
        const result = await client.query(
          `UPDATE page_permissions 
           SET permission_type = $1, updated_at = NOW()
           WHERE page_id = $2 AND user_id = $3
           RETURNING *`,
          [data.permissionType, pageId, targetUserId]
        );
        return result.rows[0];
      } else {
        // Create new permission
        const result = await client.query(
          `INSERT INTO page_permissions (page_id, user_id, permission_type, granted_by)
           VALUES ($1, $2, $3, $4)
           RETURNING *`,
          [pageId, targetUserId, data.permissionType, ownerId]
        );
        return result.rows[0];
      }
    } finally {
      client.release();
    }
  }
  
  /**
   * Get page permissions
   */
  async getPagePermissions(pageId: string): Promise<PagePermission[]> {
    const result = await pool.query(
      `SELECT pp.*, u.name as user_name, u.email as user_email
       FROM page_permissions pp
       INNER JOIN users u ON pp.user_id = u.id
       WHERE pp.page_id = $1
       ORDER BY pp.granted_at DESC`,
      [pageId]
    );
    
    return result.rows;
  }
  
  /**
   * Revoke access
   */
  async revokeAccess(
    pageId: string,
    ownerId: string,
    targetUserId: string
  ): Promise<void> {
    const client = await pool.connect();
    
    try {
      // Check if owner
      const isOwner = await this.isOwner(pageId, ownerId);
      if (!isOwner) {
        throw new Error('Only owner can revoke access');
      }
      
      // Cannot revoke owner permission
      const targetPerm = await client.query(
        `SELECT permission_type FROM page_permissions 
         WHERE page_id = $1 AND user_id = $2`,
        [pageId, targetUserId]
      );
      
      if (targetPerm.rows[0]?.permission_type === PermissionType.OWNER) {
        throw new Error('Cannot revoke owner permission');
      }
      
      await client.query(
        `DELETE FROM page_permissions 
         WHERE page_id = $1 AND user_id = $2`,
        [pageId, targetUserId]
      );
    } finally {
      client.release();
    }
  }
  
  /**
   * Check if user has edit permission
   */
  async checkEditPermission(pageId: string, userId: string): Promise<boolean> {
    const result = await pool.query(
      `SELECT permission_type FROM page_permissions
       WHERE page_id = $1 AND user_id = $2`,
      [pageId, userId]
    );
    
    if (result.rows.length === 0) {
      return false;
    }
    
    const permission = result.rows[0].permission_type;
    return permission === PermissionType.OWNER || permission === PermissionType.EDIT;
  }
  
  /**
   * Check if user is owner
   */
  async isOwner(pageId: string, userId: string): Promise<boolean> {
    const result = await pool.query(
      `SELECT permission_type FROM page_permissions
       WHERE page_id = $1 AND user_id = $2`,
      [pageId, userId]
    );
    
    return result.rows[0]?.permission_type === PermissionType.OWNER;
  }
  
  /**
   * Get user's permission for a page
   */
  async getUserPermission(
    pageId: string,
    userId: string
  ): Promise<PermissionType | null> {
    const result = await pool.query(
      `SELECT permission_type FROM page_permissions
       WHERE page_id = $1 AND user_id = $2`,
      [pageId, userId]
    );
    
    return result.rows[0]?.permission_type || null;
  }
  
  /**
   * Map database row to Page model
   */
  private mapToPage(row: any): Page {
    return {
      id: row.id,
      name: row.name,
      ownerId: row.owner_id,
      pageData: row.page_data,
      version: row.version,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      deletedAt: row.deleted_at,
    };
  }
}

export const pageService = new PageService();
