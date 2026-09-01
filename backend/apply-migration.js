const { pool } = require('./src-js/config/database');
const fs = require('fs');
const path = require('path');

async function applyMigration() {
  try {
    console.log('📦 Reading migration file...');
    const sql = fs.readFileSync(
      path.join(__dirname, '..', 'database', 'migrations', '006_create_operation_history.sql'),
      'utf8'
    );

    console.log('🔄 Applying migration 006...');
    await pool.query(sql);
    
    console.log('✅ Migration 006 applied successfully!');
    
    // Verify tables were created
    const result = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_name IN ('operation_history', 'user_undo_stacks')
    `);
    
    console.log('✅ Tables created:', result.rows.map(r => r.table_name).join(', '));
    
    // Verify indexes
    const indexes = await pool.query(`
      SELECT indexname 
      FROM pg_indexes 
      WHERE tablename IN ('operation_history', 'user_undo_stacks')
    `);
    
    console.log('✅ Indexes created:', indexes.rows.length);
    
    process.exit(0);
  } catch (err) {
    if (err.message.includes('already exists')) {
      console.log('✅ Migration 006 already applied');
      process.exit(0);
    } else {
      console.error('❌ Migration failed:', err.message);
      process.exit(1);
    }
  }
}

applyMigration();
