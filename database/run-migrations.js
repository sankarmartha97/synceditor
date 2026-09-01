const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

// Database configuration
const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'canvas_db',
  user: 'canvas_user',
  password: 'canvas_pass',
});

// Migration files to run
const migrations = [
  '005_create_pages_table.sql',
  '006_create_page_permissions_table.sql',
  '007_create_page_versions_table.sql',
  '008_create_active_editors_table.sql',
  '009_create_page_patches_table.sql',
];

async function runMigrations() {
  const client = await pool.connect();
  
  try {
    console.log('🚀 Starting migrations...\n');
    
    for (const migrationFile of migrations) {
      const filePath = path.join(__dirname, 'migrations', migrationFile);
      const sql = fs.readFileSync(filePath, 'utf8');
      
      console.log(`📄 Running: ${migrationFile}`);
      
      await client.query(sql);
      
      console.log(`✅ Completed: ${migrationFile}\n`);
    }
    
    console.log('🎉 All migrations completed successfully!');
    
    // Verify tables were created
    const result = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('pages', 'page_permissions', 'page_versions', 'active_editors', 'page_patches')
      ORDER BY table_name;
    `);
    
    console.log('\n📊 Created tables:');
    result.rows.forEach(row => {
      console.log(`  ✓ ${row.table_name}`);
    });
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigrations();
