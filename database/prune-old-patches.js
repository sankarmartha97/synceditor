// Retention policy for page_patches (Track B3 -- devkit/13-SCALING_AND_COLLABORATION)
//
// page_patches is an append-only log (one row per page:patch, used for OT
// re-basing when a client's version is stale) with no pruning today -- it
// grows forever. This deletes patches that are BOTH:
//   (a) older than RETENTION_DAYS, and
//   (b) covered by a page_versions snapshot at or after their version
//         (so a client that's merely a little stale can still OT-rebase off
//          recent patches; a client stale enough to need something older
//          than the retention window should just refetch the page instead)
//
// Never deletes a patch that isn't yet covered by a snapshot, regardless of
// age -- that patch may be the only record of that history. Run
// create-page-snapshots.js first (or let the automatic 50-version snapshots
// accumulate) so pruning actually has something to work with.
//
// Run with --dry-run to see what would be deleted without deleting anything.

const { Pool } = require('pg');

const RETENTION_DAYS = 30;
const DRY_RUN = process.argv.includes('--dry-run');

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
    const countResult = await client.query(
      `SELECT COUNT(*) FROM page_patches pp
       WHERE pp.created_at < NOW() - ($1 || ' days')::interval
         AND EXISTS (
           SELECT 1 FROM page_versions pv
           WHERE pv.page_id = pp.page_id AND pv.version >= pp.to_version
         )`,
      [RETENTION_DAYS]
    );
    const eligibleCount = parseInt(countResult.rows[0].count, 10);

    console.log(`🔍 ${eligibleCount} patch(es) older than ${RETENTION_DAYS} days and covered by a later snapshot.`);

    if (eligibleCount === 0) {
      console.log('🎉 Nothing to prune.');
      return;
    }

    if (DRY_RUN) {
      console.log('   (--dry-run: not deleting anything)');
      return;
    }

    const deleteResult = await client.query(
      `DELETE FROM page_patches pp
       WHERE pp.created_at < NOW() - ($1 || ' days')::interval
         AND EXISTS (
           SELECT 1 FROM page_versions pv
           WHERE pv.page_id = pp.page_id AND pv.version >= pp.to_version
         )`,
      [RETENTION_DAYS]
    );

    console.log(`🎉 Pruned ${deleteResult.rowCount} patch(es).`);
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((err) => {
  console.error('❌ Prune failed:', err.message);
  process.exit(1);
});
