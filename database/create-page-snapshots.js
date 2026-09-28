// Manual/scheduled snapshot run (Track B3 -- devkit/13-SCALING_AND_COLLABORATION)
//
// The backend already takes an automatic snapshot every 50 versions of
// activity (see backend/src-js/services/pageSnapshot.service.js). This script
// is for the pages that don't hit that milestone often (low-traffic pages) --
// run it periodically (e.g. a nightly Windows Task Scheduler / cron job) to
// make sure every page has at least one reasonably recent snapshot, which is
// what lets prune-old-patches.js safely remove old page_patches rows.
//
// For each page: if it has no snapshot at all, or its latest snapshot is
// older than STALE_AFTER_DAYS, take a fresh one at the page's current version.

const path = require('path');
const { Pool } = require('pg');
const { buildPageDataFromWidgets } = require(path.join(__dirname, '..', 'backend', 'src-js', 'services', 'pageWidgetsSync.service'));

const STALE_AFTER_DAYS = 7;

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'canvas_db',
  user: 'canvas_user',
  password: 'canvas_pass',
});

async function main() {
  const client = await pool.connect();
  try {
    const { rows: pages } = await client.query(`
      SELECT p.id, p.owner_id, p.version, p.page_data,
             (SELECT MAX(pv.version) FROM page_versions pv WHERE pv.page_id = p.id) AS latest_snapshot_version,
             (SELECT MAX(pv.created_at) FROM page_versions pv WHERE pv.page_id = p.id) AS latest_snapshot_at
      FROM pages p
      WHERE p.deleted_at IS NULL
    `);

    console.log(`🔍 Checking ${pages.length} page(s) for stale/missing snapshots...\n`);

    let created = 0;
    let skipped = 0;

    for (const page of pages) {
      const hasNoSnapshot = page.latest_snapshot_version === null;
      const isStale = page.latest_snapshot_at && (Date.now() - new Date(page.latest_snapshot_at).getTime()) > STALE_AFTER_DAYS * 24 * 60 * 60 * 1000;
      const isBehindCurrentVersion = page.latest_snapshot_version !== null && page.latest_snapshot_version < page.version;

      if (!hasNoSnapshot && !isStale) {
        skipped++;
        continue;
      }
      if (!isBehindCurrentVersion && !hasNoSnapshot) {
        // Snapshot is stale by age but the page hasn't changed since -- nothing new to capture.
        skipped++;
        continue;
      }

      const fullPageData = await buildPageDataFromWidgets(page.id, page.page_data);
      const result = await client.query(
        `INSERT INTO page_versions (page_id, version, page_data, description, created_by)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (page_id, version) DO NOTHING
         RETURNING id`,
        [page.id, page.version, JSON.stringify(fullPageData), 'Scheduled snapshot run', page.owner_id]
      );

      if (result.rows.length > 0) {
        console.log(`  📸 ${page.id}: snapshot taken at v${page.version}`);
        created++;
      } else {
        skipped++;
      }
    }

    console.log(`\n🎉 Done. ${created} snapshot(s) created, ${skipped} page(s) already up to date.`);
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((err) => {
  console.error('❌ Snapshot run failed:', err.message);
  process.exit(1);
});
