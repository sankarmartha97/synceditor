const { pool } = require('../config/database');

/**
 * Dual-write sync (Track B1 -- devkit/13-SCALING_AND_COLLABORATION)
 *
 * Mirrors a page's full page_data.widgets array into the normalized
 * page_widgets table. This runs *alongside* the existing page_data JSONB
 * write, which remains the source of truth during B1 -- if this sync fails,
 * it's logged and swallowed rather than failing the patch, since page_data
 * is still correct either way. B2 flips which one is authoritative.
 *
 * Safe to call repeatedly: every widget is upserted, and any page_widgets
 * row for this page whose id is no longer in pageData.widgets is deleted
 * (handles widget removal).
 */
async function syncPageWidgets(pageId, pageData, userId) {
  const widgets = Array.isArray(pageData?.widgets) ? pageData.widgets : [];
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const idsOnPage = new Set(widgets.map((w) => w.id));

    // Pass 1: upsert every widget, parent_id left NULL for now (avoids the
    // self-referential FK failing when a child appears before its parent).
    for (let i = 0; i < widgets.length; i++) {
      const w = widgets[i];
      const orderKey = (i + 1) * 1000;

      await client.query(
        `INSERT INTO page_widgets (
           id, page_id, parent_id, order_key, type, position, size, properties,
           children_ids, is_container, z_index, position_mode, is_default_container,
           updated_at, updated_by
         ) VALUES (
           $1, $2, NULL, $3, $4, $5, $6, $7,
           $8, $9, $10, $11, $12,
           NOW(), $13
         )
         ON CONFLICT (id) DO UPDATE SET
           order_key = EXCLUDED.order_key,
           type = EXCLUDED.type,
           position = EXCLUDED.position,
           size = EXCLUDED.size,
           properties = EXCLUDED.properties,
           children_ids = EXCLUDED.children_ids,
           is_container = EXCLUDED.is_container,
           z_index = EXCLUDED.z_index,
           position_mode = EXCLUDED.position_mode,
           is_default_container = EXCLUDED.is_default_container,
           version = page_widgets.version + 1,
           updated_at = NOW(),
           updated_by = EXCLUDED.updated_by`,
        [
          w.id,
          pageId,
          orderKey,
          w.type,
          JSON.stringify(w.position || { x: 0, y: 0 }),
          JSON.stringify(w.size || { width: 0, height: 0 }),
          JSON.stringify(w.properties || {}),
          JSON.stringify(w.childrenIds || []),
          !!w.isContainer,
          w.zIndex || 0,
          w.positionMode || 'absolute',
          !!w.isDefaultContainer,
          userId || w.updatedBy || null,
        ]
      );
    }

    // Pass 2: wire up parent_id now that every widget on this page is a row.
    // A parentId not present among this page's widgets is a pre-existing data
    // issue (see backfill script) -- treated as top-level, not a hard failure.
    for (const w of widgets) {
      const parentId = w.parentId && idsOnPage.has(w.parentId) ? w.parentId : null;
      await client.query(
        `UPDATE page_widgets SET parent_id = $1 WHERE id = $2 AND page_id = $3`,
        [parentId, w.id, pageId]
      );
    }

    // Remove rows for widgets that no longer exist on the page (deletions)
    await client.query(
      `DELETE FROM page_widgets
       WHERE page_id = $1
         AND id NOT IN (SELECT unnest($2::uuid[]))`,
      [pageId, widgets.map((w) => w.id)]
    );

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

function widgetContentEqual(a, b) {
  const norm = (w) => JSON.stringify({
    type: w.type,
    position: w.position || { x: 0, y: 0 },
    size: w.size || { width: 0, height: 0 },
    properties: w.properties || {},
    parentId: w.parentId || null,
    childrenIds: w.childrenIds || [],
    isContainer: !!w.isContainer,
    zIndex: w.zIndex || 0,
    positionMode: w.positionMode || 'absolute',
    isDefaultContainer: !!w.isDefaultContainer,
  });
  return norm(a) === norm(b);
}

/**
 * Targeted dual-write sync (Track B2)
 *
 * Diffs oldPageData.widgets against newPageData.widgets and only touches the
 * rows that actually changed -- inserts new widgets, updates changed ones,
 * deletes removed ones, and leaves every untouched widget's row alone
 * entirely. This is what makes a single edit cost O(1) against page_widgets
 * regardless of how many widgets the page has, instead of B1's full-array
 * re-sync on every call.
 *
 * Used by the hot real-time paths (page:patch, page:undo, page:redo), which
 * always have both the before and after document on hand already. The REST
 * update path and the backfill script keep using the simpler full-resync
 * syncPageWidgets() above, since they don't have a reliable "old" snapshot
 * and aren't performance-sensitive.
 *
 * Note: conflict serialization for a given page still flows through the
 * existing page-level OT (page_data + page_patches) upstream of this
 * function -- this does not yet make two edits to the *same* widget fully
 * independent of that. What it does deliver now: edits to *different*
 * widgets touch different rows and nothing else, and each row carries its
 * own incrementing version for when the write path fully moves per-row.
 */
async function syncPageWidgetsTargeted(pageId, oldPageData, newPageData, userId) {
  const oldWidgets = Array.isArray(oldPageData?.widgets) ? oldPageData.widgets : [];
  const newWidgets = Array.isArray(newPageData?.widgets) ? newPageData.widgets : [];
  const oldById = new Map(oldWidgets.map((w) => [w.id, w]));
  const newById = new Map(newWidgets.map((w) => [w.id, w]));
  const newIds = new Set(newById.keys());

  const changedIds = [...newById.keys()].filter((id) => {
    const old = oldById.get(id);
    return !old || !widgetContentEqual(old, newById.get(id));
  });
  const deletedIds = [...oldById.keys()].filter((id) => !newById.has(id));

  if (changedIds.length === 0 && deletedIds.length === 0) {
    return; // nothing to do -- the common case for a patch that didn't touch widgets at all
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    if (deletedIds.length > 0) {
      await client.query(
        `DELETE FROM page_widgets WHERE page_id = $1 AND id = ANY($2::uuid[])`,
        [pageId, deletedIds]
      );
    }

    for (const id of changedIds) {
      const w = newById.get(id);
      const isNew = !oldById.has(id);

      if (isNew) {
        const parentForOrder = w.parentId && newIds.has(w.parentId) ? w.parentId : null;
        const { rows } = await client.query(
          `SELECT COALESCE(MAX(order_key), 0) AS max_key FROM page_widgets
           WHERE page_id = $1 AND parent_id IS NOT DISTINCT FROM $2`,
          [pageId, parentForOrder]
        );
        const orderKey = Number(rows[0].max_key) + 1000;

        await client.query(
          `INSERT INTO page_widgets (
             id, page_id, parent_id, order_key, type, position, size, properties,
             children_ids, is_container, z_index, position_mode, is_default_container,
             updated_at, updated_by
           ) VALUES ($1, $2, NULL, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW(), $13)`,
          [
            id, pageId, orderKey, w.type,
            JSON.stringify(w.position || { x: 0, y: 0 }),
            JSON.stringify(w.size || { width: 0, height: 0 }),
            JSON.stringify(w.properties || {}),
            JSON.stringify(w.childrenIds || []),
            !!w.isContainer, w.zIndex || 0, w.positionMode || 'absolute',
            !!w.isDefaultContainer, userId || w.updatedBy || null,
          ]
        );
      } else {
        const result = await client.query(
          `UPDATE page_widgets SET
             type = $1, position = $2, size = $3, properties = $4, children_ids = $5,
             is_container = $6, z_index = $7, position_mode = $8, is_default_container = $9,
             version = version + 1, updated_at = NOW(), updated_by = $10
           WHERE id = $11 AND page_id = $12`,
          [
            w.type,
            JSON.stringify(w.position || { x: 0, y: 0 }),
            JSON.stringify(w.size || { width: 0, height: 0 }),
            JSON.stringify(w.properties || {}),
            JSON.stringify(w.childrenIds || []),
            !!w.isContainer, w.zIndex || 0, w.positionMode || 'absolute',
            !!w.isDefaultContainer, userId || w.updatedBy || null, id, pageId,
          ]
        );
        if (result.rowCount === 0) {
          console.warn(`⚠️  page_widgets targeted update hit 0 rows for widget ${id} (page ${pageId}) -- row missing`);
        }
      }

      // Wire up parent_id now that this row (and any sibling in the same
      // batch) exists. Orphaned parentId -> top-level, same as the backfill.
      const parentId = w.parentId && newIds.has(w.parentId) ? w.parentId : null;
      await client.query(
        `UPDATE page_widgets SET parent_id = $1 WHERE id = $2 AND page_id = $3`,
        [parentId, id, pageId]
      );
    }

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * Read-side cutover (Track B2)
 *
 * Reconstructs a page's widgets array from page_widgets instead of the
 * page_data JSONB blob. Widget order matches order_key, which the sync
 * function above always assigns to match the original page_data.widgets
 * array order, so this is a drop-in replacement for reading page_data.widgets.
 *
 * Metadata (width, height, backgroundColor, ...) still comes from page_data --
 * that part of the blob isn't touched until B3 splits it out for real.
 */
async function getWidgetsForPage(pageId) {
  const { rows } = await pool.query(
    `SELECT id, parent_id, type, position, size, properties, children_ids,
            is_container, z_index, position_mode, is_default_container,
            created_at, created_by, updated_at, updated_by
     FROM page_widgets
     WHERE page_id = $1
     ORDER BY order_key ASC`,
    [pageId]
  );

  return rows.map((w) => ({
    id: w.id,
    type: w.type,
    position: w.position,
    size: w.size,
    properties: w.properties,
    parentId: w.parent_id,
    childrenIds: w.children_ids,
    isContainer: w.is_container,
    zIndex: w.z_index,
    positionMode: w.position_mode,
    isDefaultContainer: w.is_default_container,
    createdAt: w.created_at ? w.created_at.toISOString() : undefined,
    createdBy: w.created_by || undefined,
    updatedAt: w.updated_at ? w.updated_at.toISOString() : undefined,
    updatedBy: w.updated_by || undefined,
  }));
}

/**
 * Returns a page_data-shaped object whose `widgets` array is sourced from
 * page_widgets rather than the stored blob. `storedPageData` supplies
 * everything else (metadata, name, pageId, version) unchanged.
 */
async function buildPageDataFromWidgets(pageId, storedPageData) {
  const base = typeof storedPageData === 'string' ? JSON.parse(storedPageData) : storedPageData;
  const widgets = await getWidgetsForPage(pageId);
  return { ...base, widgets };
}

module.exports = { syncPageWidgets, syncPageWidgetsTargeted, getWidgetsForPage, buildPageDataFromWidgets };
