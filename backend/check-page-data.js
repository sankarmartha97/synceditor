const { pool } = require('./src-js/config/database');

(async () => {
  try {
    const result = await pool.query(
      'SELECT id, name, version, page_data FROM pages WHERE id = $1',
      ['304e77db-82f0-4860-b868-69c0a2f35fb8']
    );
    
    if (result.rows.length > 0) {
      console.log('Page:', result.rows[0].name);
      console.log('Version:', result.rows[0].version);
      console.log('Widgets count:', result.rows[0].page_data.widgets?.length || 0);
      console.log('\nFull page data:');
      console.log(JSON.stringify(result.rows[0].page_data, null, 2));
    } else {
      console.log('Page not found');
    }
    
    await pool.end();
  } catch (e) {
    console.error('Error:', e.message);
    process.exit(1);
  }
})();
