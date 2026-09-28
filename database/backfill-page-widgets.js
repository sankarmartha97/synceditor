// Backfill script (Track B1 -- devkit/13-SCALING_AND_COLLABORATION)
//
// Reads every existing page's page_data.widgets array and inserts one row per
// widget into the new page_widgets table, deriving order_key from array order
// (spaced by 1000 so future reorders can insert between two without renumbering).
//
// Safe to re-run: every widget is upserted (ON CONFLICT ... DO UPDATE), so this
// can run again after further edits to re-sync page_widgets from page_data.
//
// Two-pass insert per page: first insert every widget with parent_id = NULL,
// then update parent_id afterward -- this avoids the self-referential foreign
// key failing when a child widget appears before its parent in the array.

const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'canvas_db',
  user: 'canvas_user',
  password: 'canvas_pass',
});

async function backfillPage(client, page) {
  const pageId = page.id;
  const pageData = typeof page.page_data === 'string' ? JSON.parse(page.page_data) : page.page_data;
  const widgets = Array.isArray(pageData?.widgets) ? pageData.widgets : [];

  if (widgets.length === 0) {
    return { pageId, count: 0 };
  }

  await client.query('BEGIN');
  try {
    // Pass 1: insert/update every widget with parent_id left NULL for now
    for (let i = 0; i < widgets.length; i++) {
      const w = widgets[i];
      const orderKey = (i + 1) * 1000;

      await client.query(
        `INSERT INTO page_widgets (
           id, page_id, parent_id, order_key, type, position, size, properties,
           children_ids, is_container, z_index, position_mode, is_default_container,
           created_at, created_by, updated_at, updated_by
         ) VALUES (
           $1, $2, NULL, $3, $4, $5, $6, $7,
           $8, $9, $10, $11, $12,
           COALESCE($13, NOW()), $14, COALESCE($15, NOW()), $16
         )
         ON CONFLICT (id) DO UPDATE SET
           page_id = EXCLUDED.page_id,
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
           updated_at = COALESCE(EXCLUDED.updated_at, NOW()),
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
          w.createdAt || null,
          w.createdBy || null,
          w.updatedAt || null,
          w.updatedBy || null,
        ]
      );
    }

    // Pass 2: now that every widget on this page exists as a row, wire up parent_id.
    // A parentId that doesn't match any widget actually on this page is a pre-existing
    // data issue in page_data (e.g. a deleted container whose children's parentId was
    // never cleared) -- treat it as top-level rather than failing the whole backfill.
    const idsOnPage = new Set(widgets.map((w) => w.id));
    let orphanCount = 0;
    for (const w of widgets) {
      if (w.parentId && idsOnPage.has(w.parentId)) {
        await client.query(
          `UPDATE page_widgets SET parent_id = $1 WHERE id = $2 AND page_id = $3`,
          [w.parentId, w.id, pageId]
        );
      } else if (w.parentId) {
        orphanCount++;
        console.warn(
          `  ⚠️  ${pageId}: widget ${w.id} has parentId ${w.parentId}, which is not on this page -- left as top-level`
        );
      }
    }

    await client.query('COMMIT');
    return { pageId, count: widgets.length, orphanCount };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  }
}

async function main() {
  const client = await pool.connect();
  try {
    const { rows: pages } = await client.query(
      `SELECT id, page_data FROM pages WHERE deleted_at IS NULL`
    );

    console.log(`🚀 Backfilling ${pages.length} page(s) into page_widgets...\n`);

    let totalWidgets = 0;
    let totalOrphans = 0;
    for (const page of pages) {
      const result = await backfillPage(client, page);
      console.log(`  ✅ ${result.pageId}: ${result.count} widget(s)`);
      totalWidgets += result.count;
      totalOrphans += result.orphanCount || 0;
    }

    console.log(`\n🎉 Done. ${pages.length} page(s), ${totalWidgets} widget row(s) total.`);
    if (totalOrphans > 0) {
      console.log(`⚠️  ${totalOrphans} widget(s) had an orphaned parentId and were left top-level -- see warnings above.`);
    }
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((err) => {
  console.error('❌ Backfill failed:', err.message);
  process.exit(1);
});
