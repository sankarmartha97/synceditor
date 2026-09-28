/**
 * Project Service
 * Business logic for the Projects layer (Track E).
 *
 * Access model:
 *   project_permissions is a bookkeeping table.  When a user is added to a
 *   project, page_permissions rows are written for every page currently in
 *   that project.  When a page is created inside a project, page_permissions
 *   rows are written for every current project member.  This keeps the
 *   existing page-level permission check (REST + socket handlers) as the
 *   single authoritative gate rather than adding a second runtime check.
 */

const { pool } = require('../config/database');

const PermissionType = {
  OWNER: 'owner',
  EDIT: 'edit',
  COMMENT: 'comment',
  VIEW: 'view',
};

class ProjectService {
  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  async createProject(userId, { name, description }) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const projectResult = await client.query(
        `INSERT INTO projects (name, owner_id, description)
         VALUES ($1, $2, $3)
         RETURNING *`,
        [name, userId, description || null]
      );
      const project = projectResult.rows[0];

      await client.query(
        `INSERT INTO project_permissions (project_id, user_id, permission_type, granted_by)
         VALUES ($1, $2, $3, $4)`,
        [project.id, userId, PermissionType.OWNER, userId]
      );

      await client.query('COMMIT');
      return this._mapProject(project);
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  async getUserProjects(userId) {
    const result = await pool.query(
      `SELECT pr.*, pp.permission_type
       FROM projects pr
       INNER JOIN project_permissions pp
               ON pr.id = pp.project_id AND pp.user_id = $1
       WHERE pr.deleted_at IS NULL
       ORDER BY pr.updated_at DESC`,
      [userId]
    );
    return result.rows.map(r => this._mapProjectList(r));
  }

  async getProjectById(projectId, userId) {
    const result = await pool.query(
      `SELECT pr.*, pp.permission_type
       FROM projects pr
       INNER JOIN project_permissions pp
               ON pr.id = pp.project_id AND pp.user_id = $1
       WHERE pr.id = $2 AND pr.deleted_at IS NULL`,
      [userId, projectId]
    );
    if (result.rows.length === 0) return null;
    return this._mapProject(result.rows[0]);
  }

  async updateProject(projectId, userId, { name, description }) {
    const result = await pool.query(
      `UPDATE projects
       SET name        = COALESCE($1, name),
           description = COALESCE($2, description),
           updated_at  = NOW()
       WHERE id = $3
         AND deleted_at IS NULL
         AND EXISTS (
           SELECT 1 FROM project_permissions
           WHERE project_id = $3 AND user_id = $4
             AND permission_type = 'owner'
         )
       RETURNING *`,
      [name || null, description !== undefined ? description : null, projectId, userId]
    );
    if (result.rows.length === 0) return null;
    return this._mapProject(result.rows[0]);
  }

  /** Soft-delete the project and every page inside it. */
  async deleteProject(projectId, userId) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Verify caller is owner.
      const check = await client.query(
        `SELECT 1 FROM project_permissions
         WHERE project_id = $1 AND user_id = $2 AND permission_type = 'owner'`,
        [projectId, userId]
      );
      if (check.rows.length === 0) {
        await client.query('ROLLBACK');
        return false;
      }

      // Soft-delete all pages in the project.
      await client.query(
        `UPDATE pages SET deleted_at = NOW()
         WHERE project_id = $1 AND deleted_at IS NULL`,
        [projectId]
      );

      // Soft-delete the project itself.
      await client.query(
        `UPDATE projects SET deleted_at = NOW() WHERE id = $1`,
        [projectId]
      );

      await client.query('COMMIT');
      return true;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  // ---------------------------------------------------------------------------
  // Pages inside a project
  // ---------------------------------------------------------------------------

  async getProjectPages(projectId, userId) {
    const result = await pool.query(
      `SELECT p.id, p.name, p.owner_id, p.version, p.project_id,
              p.created_at, p.updated_at, pp.permission_type
       FROM pages p
       INNER JOIN page_permissions pp ON p.id = pp.page_id AND pp.user_id = $1
       WHERE p.project_id = $2 AND p.deleted_at IS NULL
       ORDER BY p.updated_at DESC`,
      [userId, projectId]
    );
    return result.rows.map(r => ({
      id: r.id,
      name: r.name,
      ownerId: r.owner_id,
      version: r.version,
      projectId: r.project_id,
      permission: r.permission_type,
      updatedAt: r.updated_at,
      createdAt: r.created_at,
    }));
  }

  // ---------------------------------------------------------------------------
  // Members
  // ---------------------------------------------------------------------------

  async addMember(projectId, callerUserId, { email, permissionType }) {
    // Resolve the target user by email.
    const userResult = await pool.query(
      `SELECT id FROM users WHERE email = $1`,
      [email]
    );
    if (userResult.rows.length === 0) return { error: 'user_not_found' };
    const targetUserId = userResult.rows[0].id;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Upsert project_permissions entry.
      await client.query(
        `INSERT INTO project_permissions (project_id, user_id, permission_type, granted_by)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (project_id, user_id) DO UPDATE
           SET permission_type = EXCLUDED.permission_type,
               granted_by      = EXCLUDED.granted_by,
               granted_at      = NOW()`,
        [projectId, targetUserId, permissionType || PermissionType.EDIT, callerUserId]
      );

      // Fan out: grant page_permissions on every page currently in this project.
      await client.query(
        `INSERT INTO page_permissions (page_id, user_id, permission_type, granted_by)
         SELECT p.id, $1, $2, $3
         FROM pages p
         WHERE p.project_id = $4 AND p.deleted_at IS NULL
         ON CONFLICT (page_id, user_id) DO UPDATE
           SET permission_type = EXCLUDED.permission_type,
               granted_by      = EXCLUDED.granted_by`,
        [targetUserId, permissionType || PermissionType.EDIT, callerUserId, projectId]
      );

      await client.query('COMMIT');
      return { success: true, userId: targetUserId };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  async removeMember(projectId, callerUserId, targetUserId) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      await client.query(
        `DELETE FROM project_permissions
         WHERE project_id = $1 AND user_id = $2`,
        [projectId, targetUserId]
      );

      // Remove page_permissions for every page in this project (non-owner rows only).
      await client.query(
        `DELETE FROM page_permissions pp
         USING pages p
         WHERE pp.page_id = p.id
           AND p.project_id = $1
           AND pp.user_id = $2
           AND pp.permission_type <> 'owner'`,
        [projectId, targetUserId]
      );

      await client.query('COMMIT');
      return true;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  async getMembers(projectId, userId) {
    // Caller must be a member.
    const result = await pool.query(
      `SELECT u.id, u.name, u.email, u.avatar_url, pp.permission_type, pp.granted_at
       FROM project_permissions pp
       INNER JOIN users u ON u.id = pp.user_id
       WHERE pp.project_id = $1
         AND EXISTS (
           SELECT 1 FROM project_permissions
           WHERE project_id = $1 AND user_id = $2
         )
       ORDER BY pp.granted_at ASC`,
      [projectId, userId]
    );
    return result.rows.map(r => ({
      id: r.id,
      name: r.name,
      email: r.email,
      avatarUrl: r.avatar_url,
      permission: r.permission_type,
      grantedAt: r.granted_at,
    }));
  }

  // ---------------------------------------------------------------------------
  // Internal helpers called by page.service.js on page creation
  // ---------------------------------------------------------------------------

  /**
   * When a page is created inside a project, fan out page_permissions to every
   * existing project member (called inside page.service.js createPage).
   */
  async grantProjectMembersPageAccess(client, pageId, projectId, ownerUserId) {
    await client.query(
      `INSERT INTO page_permissions (page_id, user_id, permission_type, granted_by)
       SELECT $1, pp.user_id,
              CASE WHEN pp.user_id = $3 THEN 'owner' ELSE pp.permission_type END,
              $3
       FROM project_permissions pp
       WHERE pp.project_id = $2
       ON CONFLICT (page_id, user_id) DO NOTHING`,
      [pageId, projectId, ownerUserId]
    );
  }

  // ---------------------------------------------------------------------------
  // Mappers
  // ---------------------------------------------------------------------------

  _mapProject(r) {
    return {
      id: r.id,
      name: r.name,
      ownerId: r.owner_id,
      description: r.description,
      permission: r.permission_type,
      createdAt: r.created_at,
      updatedAt: r.updated_at,
    };
  }

  _mapProjectList(r) {
    return {
      id: r.id,
      name: r.name,
      ownerId: r.owner_id,
      description: r.description,
      permission: r.permission_type,
      updatedAt: r.updated_at,
      createdAt: r.created_at,
    };
  }
}

module.exports = new ProjectService();
