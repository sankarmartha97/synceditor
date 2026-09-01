/**
 * Quick Database Preview
 * Shows what data you'll see in pgAdmin
 */

const { pool } = require('./src-js/config/database');

async function checkDatabase() {
  console.log('\n' + '='.repeat(60));
  console.log('📊 CANVAS EDITOR DATABASE PREVIEW');
  console.log('='.repeat(60) + '\n');

  try {
    // Connect to database
    await pool.connect();
    console.log('✅ Connected to database: canvas_db\n');

    // Check users
    const usersResult = await pool.query('SELECT COUNT(*) FROM users');
    const usersCount = usersResult.rows[0].count;
    console.log(`👥 Users table: ${usersCount} users`);
    
    if (usersCount > 0) {
      const recentUsers = await pool.query(
        'SELECT email, name, created_at FROM users ORDER BY created_at DESC LIMIT 3'
      );
      console.log('   Recent users:');
      recentUsers.rows.forEach(user => {
        console.log(`   - ${user.name} (${user.email})`);
      });
    }

    // Check canvases
    const canvasesResult = await pool.query('SELECT COUNT(*) FROM canvases');
    const canvasesCount = canvasesResult.rows[0].count;
    console.log(`\n🎨 Canvases table: ${canvasesCount} canvases`);
    
    if (canvasesCount > 0) {
      const recentCanvases = await pool.query(
        `SELECT c.name, u.name as owner, c.created_at 
         FROM canvases c 
         JOIN users u ON c.owner_id = u.id 
         ORDER BY c.created_at DESC LIMIT 3`
      );
      console.log('   Recent canvases:');
      recentCanvases.rows.forEach(canvas => {
        console.log(`   - "${canvas.name}" by ${canvas.owner}`);
      });
    }

    // Check widgets
    const widgetsResult = await pool.query('SELECT COUNT(*) FROM widgets');
    const widgetsCount = widgetsResult.rows[0].count;
    console.log(`\n🔷 Widgets table: ${widgetsCount} widgets`);
    
    if (widgetsCount > 0) {
      const widgetsByCanvas = await pool.query(
        `SELECT c.name as canvas_name, COUNT(w.id) as widget_count
         FROM canvases c
         LEFT JOIN widgets w ON c.id = w.canvas_id
         GROUP BY c.id, c.name
         HAVING COUNT(w.id) > 0
         ORDER BY widget_count DESC`
      );
      if (widgetsByCanvas.rows.length > 0) {
        console.log('   Widgets per canvas:');
        widgetsByCanvas.rows.forEach(row => {
          console.log(`   - "${row.canvas_name}": ${row.widget_count} widgets`);
        });
      }
    }

    // Check collaborators
    const collabResult = await pool.query('SELECT COUNT(*) FROM canvas_collaborators');
    const collabCount = collabResult.rows[0].count;
    console.log(`\n👥 Canvas Collaborators: ${collabCount} collaborations`);

    // Check versions
    const versionsResult = await pool.query('SELECT COUNT(*) FROM widget_versions');
    const versionsCount = versionsResult.rows[0].count;
    console.log(`📝 Widget Versions: ${versionsCount} version records`);

    // Database size
    const sizeResult = await pool.query(
      "SELECT pg_size_pretty(pg_database_size('canvas_db')) as size"
    );
    console.log(`\n💾 Database size: ${sizeResult.rows[0].size}`);

    console.log('\n' + '='.repeat(60));
    console.log('✅ DATABASE IS READY TO VIEW IN pgAdmin!');
    console.log('='.repeat(60));
    
    console.log('\n📋 What you\'ll see in pgAdmin:');
    console.log('   1. Navigate to: Servers → Canvas Editor DB');
    console.log('   2. Expand: Databases → canvas_db → Schemas → public → Tables');
    console.log('   3. Right-click any table → View/Edit Data → All Rows');
    console.log('   4. Browse your Canvas Editor data!');
    console.log('');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await pool.end();
    process.exit(0);
  }
}

checkDatabase();
