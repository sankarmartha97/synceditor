// Parity check (Track B1 -- devkit/13-SCALING_AND_COLLABORATION)
//
// Originally: compares page_data.widgets (the JSONB blob, the live source of
// truth during B1/B2) against the corresponding rows in page_widgets and
// reports any mismatch.
//
// Since Track B3, page_data is metadata-only for any page that's received a
// write since B3 shipped -- it correctly has NO "widgets" key at all, and
// page_widgets is the sole source of truth. Comparing against an
// intentionally-empty blob would report every such page as "broken" when
// it's actually correct. So: a page with a "widgets" key in its blob (never
// touched since before B3, or a stale pre-B3 snapshot) still gets the full
// old-style comparison; a page without one is reported separately as
// "post-B3, nothing to compare" rather than a false failure.

const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'canvas_db',
  user: 'canvas_user',
  password: 'canvas_pass',
});

function normalize(value) {
  // Order-insensitive, type-tolerant comparison for JSON-ish values
  return JSON.stringify(value === undefined ? null : value);
}

async function verifyPage(client, page) {
  const pageId = page.id;
  const pageData = typeof page.page_data === 'string' ? JSON.parse(page.page_data) : page.page_data;

  if (!Object.prototype.hasOwnProperty.call(pageData || {}, 'widgets')) {
    // Post-B3 page: page_data is correctly metadata-only, nothing to compare.
    const { rows } = await client.query('SELECT COUNT(*) FROM page_widgets WHERE page_id = $1', [pageId]);
    return { postB3: true, widgetCount: Number(rows[0].count), issues: [] };
  }

  const blobWidgets = Array.isArray(pageData?.widgets) ? pageData.widgets : [];
  const blobById = new Map(blobWidgets.map((w) => [w.id, w]));

  const { rows: dbWidgets } = await client.query(
    `SELECT id, parent_id, type, position, size, properties, children_ids,
            is_container, z_index, position_mode, is_default_container
     FROM page_widgets WHERE page_id = $1`,
    [pageId]
  );
  const dbById = new Map(dbWidgets.map((w) => [w.id, w]));

  const issues = [];

  for (const id of blobById.keys()) {
    if (!dbById.has(id)) issues.push(`missing from page_widgets: ${id}`);
  }
  for (const id of dbById.keys()) {
    if (!blobById.has(id)) issues.push(`extra row in page_widgets (not in page_data): ${id}`);
  }

  for (const [id, blobW] of blobById) {
    const dbW = dbById.get(id);
    if (!dbW) continue;

    const idsOnPage = new Set(blobWidgets.map((w) => w.id));
    const expectedParent = blobW.parentId && idsOnPage.has(blobW.parentId) ? blobW.parentId : null;

    const checks = [
      ['type', blobW.type, dbW.type],
      ['parentId', expectedParent, dbW.parent_id],
      ['position', blobW.position || { x: 0, y: 0 }, dbW.position],
      ['size', blobW.size || { width: 0, height: 0 }, dbW.size],
      ['properties', blobW.properties || {}, dbW.properties],
      ['childrenIds', blobW.childrenIds || [], dbW.children_ids],
      ['isContainer', !!blobW.isContainer, dbW.is_container],
      ['zIndex', blobW.zIndex || 0, dbW.z_index],
      ['positionMode', blobW.positionMode || 'absolute', dbW.position_mode],
      ['isDefaultContainer', !!blobW.isDefaultContainer, dbW.is_default_container],
    ];

    for (const [field, expected, actual] of checks) {
      if (normalize(expected) !== normalize(actual)) {
        issues.push(`${id}.${field}: page_data=${normalize(expected)} vs page_widgets=${normalize(actual)}`);
      }
    }
  }

  return { postB3: false, issues };
}

async function main() {
  const client = await pool.connect();
  try {
    const { rows: pages } = await client.query(
      `SELECT id, page_data FROM pages WHERE deleted_at IS NULL`
    );

    console.log(`🔍 Verifying parity for ${pages.length} page(s)...\n`);

    let totalIssues = 0;
    let postB3Count = 0;
    for (const page of pages) {
      const result = await verifyPage(client, page);

      if (result.postB3) {
        console.log(`  ⏭️  ${page.id}: post-B3, page_data correctly metadata-only (${result.widgetCount} widget(s) in page_widgets, nothing to compare)`);
        postB3Count++;
        continue;
      }

      if (result.issues.length === 0) {
        console.log(`  ✅ ${page.id}: matches`);
      } else {
        console.log(`  ❌ ${page.id}: ${result.issues.length} issue(s)`);
        result.issues.forEach((i) => console.log(`      - ${i}`));
        totalIssues += result.issues.length;
      }
    }

    console.log(`\n${totalIssues === 0 ? '🎉 All pages match (or are correctly post-B3).' : `⚠️  ${totalIssues} total issue(s) found.`}${postB3Count > 0 ? ` (${postB3Count} page(s) skipped as post-B3)` : ''}`);
    process.exit(totalIssues === 0 ? 0 : 1);
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((err) => {
  console.error('❌ Verification failed:', err.message);
  process.exit(1);
});
