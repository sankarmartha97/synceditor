const { Pool } = require('pg');
const bcrypt = require('bcrypt');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'canvas_db',
  user: process.env.DB_USER || 'canvas_user',
  password: process.env.DB_PASSWORD || 'canvas_pass',
});

async function cleanAndSeedDatabase() {
  const client = await pool.connect();
  
  try {
    console.log('🗑️  Starting database cleanup...\n');
    
    // Start transaction
    await client.query('BEGIN');
    
    // Get all table names
    const tablesResult = await client.query(`
      SELECT tablename 
      FROM pg_tables 
      WHERE schemaname = 'public' 
      ORDER BY tablename;
    `);
    
    const tables = tablesResult.rows.map(row => row.tablename);
    
    if (tables.length === 0) {
      console.log('ℹ️  No tables found in the database.');
      await client.query('COMMIT');
      return;
    }
    
    console.log(`Found ${tables.length} tables:\n${tables.join(', ')}\n`);
    
    // Truncate all tables with CASCADE
    const tablesList = tables.map(t => `"${t}"`).join(', ');
    const truncateQuery = `TRUNCATE TABLE ${tablesList} RESTART IDENTITY CASCADE;`;
    
    console.log('🔄 Truncating all tables...');
    await client.query(truncateQuery);
    
    console.log('✅ All table data has been cleaned!\n');
    
    // Create 2 test users
    console.log('👤 Creating test users...\n');
    
    const password1 = 'Admin@123';
    const password2 = 'User@123';
    
    const hashedPassword1 = await bcrypt.hash(password1, 10);
    const hashedPassword2 = await bcrypt.hash(password2, 10);
    
    // User 1 - Admin
    const user1Result = await client.query(`
      INSERT INTO users (email, password_hash, name, created_at, updated_at)
      VALUES ($1, $2, $3, NOW(), NOW())
      RETURNING id, email, name, created_at;
    `, ['admin@synceditor.com', hashedPassword1, 'Admin User']);
    
    // User 2 - Regular User
    const user2Result = await client.query(`
      INSERT INTO users (email, password_hash, name, created_at, updated_at)
      VALUES ($1, $2, $3, NOW(), NOW())
      RETURNING id, email, name, created_at;
    `, ['user@synceditor.com', hashedPassword2, 'Test User']);
    
    // Commit transaction
    await client.query('COMMIT');
    
    const user1 = user1Result.rows[0];
    const user2 = user2Result.rows[0];
    
    console.log('✅ Test users created successfully!\n');
    console.log('═══════════════════════════════════════════════════════');
    console.log('                    LOGIN DETAILS                      ');
    console.log('═══════════════════════════════════════════════════════\n');
    
    console.log('👤 USER 1 (Admin):');
    console.log('   Email:    admin@synceditor.com');
    console.log('   Password: Admin@123');
    console.log(`   User ID:  ${user1.id}`);
    console.log(`   Name:     ${user1.name}\n`);
    
    console.log('👤 USER 2 (Test User):');
    console.log('   Email:    user@synceditor.com');
    console.log('   Password: User@123');
    console.log(`   User ID:  ${user2.id}`);
    console.log(`   Name:     ${user2.name}\n`);
    
    console.log('═══════════════════════════════════════════════════════\n');
    
    // Verify table counts
    console.log('📊 Final table counts:');
    for (const table of tables) {
      const countResult = await client.query(`SELECT COUNT(*) FROM "${table}"`);
      const count = countResult.rows[0].count;
      if (count > 0) {
        console.log(`   ${table}: ${count} rows`);
      }
    }
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Error:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

// Run the cleanup and seed
cleanAndSeedDatabase()
  .then(() => {
    console.log('\n✅ Database reset completed successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Database reset failed:', error);
    process.exit(1);
  });
