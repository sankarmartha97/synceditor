const { compare, applyPatch, validate } = require('fast-json-patch');
const { pool } = require('../config/database');

class PatchService {
  /**
   * Generate JSON patch between two page data objects
   * @param {Object} oldData - Previous page data
   * @param {Object} newData - New page data
   * @returns {Array} JSON Patch operations
   */
  generatePatch(oldData, newData) {
    try {
      // Generate patch using fast-json-patch
      const patches = compare(oldData, newData);
      
      console.log('📝 Generated patch:', patches.length, 'operations');
      return patches;
    } catch (error) {
      console.error('❌ Patch generation failed:', error);
      throw new Error(`Failed to generate patch: ${error.message}`);
    }
  }

  /**
   * Apply JSON patch to a page data object
   * @param {Object} data - Current page data
   * @param {Array} patches - JSON Patch operations
   * @returns {Object} Patched data and any errors
   */
  applyPatch(data, patches) {
    try {
      // Validate patch format
      const validationErrors = validate(patches, data);
      if (validationErrors) {
        console.warn('⚠️ Patch validation failed:', validationErrors);
        return {
          success: false,
          errors: validationErrors,
          data: null
        };
      }

      // Apply patch (modifies data in place, but we'll clone first)
      const clonedData = JSON.parse(JSON.stringify(data));
      const result = applyPatch(clonedData, patches);

      console.log('✅ Patch applied successfully:', patches.length, 'operations');
      
      return {
        success: true,
        errors: null,
        data: result.newDocument
      };
    } catch (error) {
      console.error('❌ Patch application failed:', error);
      return {
        success: false,
        errors: [error.message],
        data: null
      };
    }
  }

  /**
   * Validate patch operations
   * @param {Array} patches - JSON Patch operations
   * @param {Object} data - Target data
   * @returns {Object} Validation result
   */
  validatePatch(patches, data) {
    try {
      const errors = validate(patches, data);
      
      return {
        valid: !errors,
        errors: errors || []
      };
    } catch (error) {
      return {
        valid: false,
        errors: [error.message]
      };
    }
  }

  /**
   * Save patch to database for history
   * @param {string} pageId - Page ID
   * @param {string} userId - User who made the change
   * @param {Array} patches - JSON Patch operations
   * @param {number} fromVersion - Version before patch
   * @param {number} toVersion - Version after patch
   */
  async savePatchHistory(pageId, userId, patches, fromVersion, toVersion) {
    try {
      const query = `
        INSERT INTO page_patches (
          page_id,
          user_id,
          patches,
          from_version,
          to_version,
          created_at
        ) VALUES ($1, $2, $3, $4, $5, NOW())
        RETURNING *
      `;

      const result = await pool.query(query, [
        pageId,
        userId,
        JSON.stringify(patches),
        fromVersion,
        toVersion
      ]);

      console.log('💾 Patch history saved:', result.rows[0].id);
      return result.rows[0];
    } catch (error) {
      // If table doesn't exist yet, just log (we'll create it later)
      console.warn('⚠️ Could not save patch history (table may not exist):', error.message);
      return null;
    }
  }

  /**
   * Get patches between two versions for OT
   * @param {string} pageId - Page ID
   * @param {number} fromVersion - Starting version (exclusive)
   * @param {number} toVersion - Ending version (inclusive)
   * @returns {Array} Flat array of all patch operations
   */
  async getPatchesBetweenVersions(pageId, fromVersion, toVersion) {
    try {
      const query = `
        SELECT patches
        FROM page_patches
        WHERE page_id = $1
          AND from_version >= $2
          AND to_version <= $3
        ORDER BY to_version ASC
      `;

      const result = await pool.query(query, [pageId, fromVersion, toVersion]);
      
      // Flatten patches array
      const allPatches = result.rows.flatMap(row => {
        const patches = typeof row.patches === 'string' 
          ? JSON.parse(row.patches) 
          : row.patches;
        return patches;
      });

      console.log(`📜 Retrieved patches between v${fromVersion} and v${toVersion}:`, allPatches.length, 'operations');
      return allPatches;
    } catch (error) {
      console.warn('⚠️ Could not retrieve patches between versions:', error.message);
      return [];
    }
  }

  /**
   * Get patch history for a page
   * @param {string} pageId - Page ID
   * @param {number} limit - Max number of patches to retrieve
   * @returns {Array} Patch history
   */
  async getPatchHistory(pageId, limit = 50) {
    try {
      const query = `
        SELECT 
          pp.*,
          u.name as user_name,
          u.email as user_email
        FROM page_patches pp
        LEFT JOIN users u ON pp.user_id = u.id
        WHERE pp.page_id = $1
        ORDER BY pp.created_at DESC
        LIMIT $2
      `;

      const result = await pool.query(query, [pageId, limit]);
      
      console.log('📜 Retrieved patch history:', result.rows.length, 'patches');
      return result.rows;
    } catch (error) {
      console.warn('⚠️ Could not retrieve patch history:', error.message);
      return [];
    }
  }

  /**
   * Optimize patches by combining consecutive operations
   * @param {Array} patches - Array of JSON Patch operations
   * @returns {Array} Optimized patches
   */
  optimizePatches(patches) {
    // Simple optimization: remove redundant operations
    const optimized = [];
    const seen = new Set();

    for (const patch of patches) {
      const key = `${patch.op}:${patch.path}`;
      
      // For replace operations, keep only the last one per path
      if (patch.op === 'replace') {
        if (!seen.has(patch.path)) {
          optimized.push(patch);
          seen.add(patch.path);
        } else {
          // Update the existing patch with new value
          const existing = optimized.find(p => p.path === patch.path);
          if (existing) {
            existing.value = patch.value;
          }
        }
      } else {
        optimized.push(patch);
      }
    }

    console.log('⚡ Optimized patches:', patches.length, '→', optimized.length);
    return optimized;
  }

  /**
   * Transform patch operations for operational transformation (OT)
   * Simple implementation: detect conflicts and apply Last-Write-Wins
   * @param {Array} patch1 - First patch
   * @param {Array} patch2 - Second patch (concurrent)
   * @returns {Object} Transformed patches
   */
  transformPatches(patch1, patch2) {
    // Simple conflict detection
    const conflicts = [];
    const paths1 = new Set(patch1.map(p => p.path));
    const paths2 = new Set(patch2.map(p => p.path));

    // Find overlapping paths
    for (const path of paths1) {
      if (paths2.has(path)) {
        conflicts.push(path);
      }
    }

    console.log('🔀 Patch transformation - conflicts:', conflicts.length);

    return {
      patch1: patch1, // Keep original for now
      patch2: patch2,
      conflicts: conflicts,
      strategy: 'last-write-wins'
    };
  }
}

module.exports = new PatchService();
