import { pool } from '../config/database';
import * as fs from 'fs';
import * as path from 'path';

// Migration files to run
const migrations = [
  '005_create_pages_table.sql',
  '006_create_page_permissions_table.sql',
  '007_create_page_versions_table.sql',
  '008_create_active_editors_table.sql',
];

async function runMigrations() {
  const client = await pool.connect();
  
  try {
    console.log('🚀 Starting Phase 1 migrations...\n');
    
    for (const migrationFile of migrations) {
      const filePath = path.join(__dirname, '../../../database/migrations', migrationFile);
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
      AND table_name IN ('pages', 'page_permissions', 'page_versions', 'active_editors')
      ORDER BY table_name;
    `);
    
    console.log('\n📊 Created tables:');
    result.rows.forEach((row: any) => {
      console.log(`  ✓ ${row.table_name}`);
    });
    
    console.log('\n✅ Phase 1.1 Database Schema - COMPLETE!');
    
  } catch (error: any) {
    console.error('❌ Migration failed:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigrations();
