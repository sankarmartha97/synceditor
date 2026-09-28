/**
 * Page Snapshot Service (Track B3 -- devkit/13-SCALING_AND_COLLABORATION)
 *
 * Periodically materializes a full page document (metadata + widgets,
 * reconstructed from page_widgets) into page_versions, so:
 *  - joining a very old page, or replaying history, doesn't require walking
 *    every page_patches row back to version 1
 *  - page_patches can be safely pruned once a snapshot covers its version
 *    (see database/prune-old-patches.js)
 *
 * Reuses the existing page_versions table (created by migration 007) instead
 * of adding a new page_snapshots table -- it already has exactly the shape
 * needed (page_id, version, full page_data JSONB, created_by, created_at)
 * and was sitting unused.
 */

const { pool } = require('../config/database');
const { buildPageDataFromWidgets } = require('./pageWidgetsSync.service');

// Snapshot every N versions of activity, not on every single edit.
const SNAPSHOT_INTERVAL = 50;

/**
 * True when `version` is a snapshot milestone (and therefore due for one),
 * e.g. every 50th version: 50, 100, 150...
 */
function isSnapshotMilestone(version) {
  return version > 0 && version % SNAPSHOT_INTERVAL === 0;
}

/**
 * Materialize a full snapshot of a page at its current version.
 * Idempotent: a snapshot already existing for this (page_id, version) is
 * left as-is (unique_page_version conflict is ignored), so calling this
 * more than once for the same version is harmless.
 *
 * @param {string} pageId
 * @param {number} version - the version being snapshotted
 * @param {string} userId - attributed as the snapshot's created_by
 * @param {string} [description]
 */
async function createPageSnapshot(pageId, version, userId, description = null) {
  const pageResult = await pool.query(
    `SELECT page_data FROM pages WHERE id = $1 AND deleted_at IS NULL`,
    [pageId]
  );
  if (pageResult.rows.length === 0) return null;

  const fullPageData = await buildPageDataFromWidgets(pageId, pageResult.rows[0].page_data);

  const result = await pool.query(
    `INSERT INTO page_versions (page_id, version, page_data, description, created_by)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (page_id, version) DO NOTHING
     RETURNING id`,
    [pageId, version, JSON.stringify(fullPageData), description, userId]
  );

  return result.rows[0]?.id || null;
}

/**
 * Call after a successful patch/undo/redo write. Fires a snapshot only at
 * SNAPSHOT_INTERVAL milestones, and never throws -- a failed snapshot must
 * not fail the edit that triggered it, it just means that milestone's
 * snapshot is missing (the next one will still land on schedule).
 */
async function maybeSnapshotAfterWrite(pageId, newVersion, userId) {
  if (!isSnapshotMilestone(newVersion)) return;

  try {
    const snapshotId = await createPageSnapshot(pageId, newVersion, userId, `Automatic snapshot at v${newVersion}`);
    if (snapshotId) {
      console.log(`📸 Snapshot created: page ${pageId} v${newVersion}`);
    }
  } catch (error) {
    console.error(`❌ Failed to create snapshot for page ${pageId} v${newVersion}:`, error);
  }
}

module.exports = { createPageSnapshot, maybeSnapshotAfterWrite, isSnapshotMilestone, SNAPSHOT_INTERVAL };
