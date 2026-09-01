const { pool } = require('./src-js/config/database');

(async () => {
  try {
    // Check column types
    const types = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name='operation_history' 
      AND column_name IN ('operation','inverse_operation')
    `);
    
    console.log('Column types:');
    console.table(types.rows);
    
    // Check actual data
    const data = await pool.query(`
      SELECT id, 
             operation, 
             inverse_operation,
             pg_typeof(operation) as op_type,
             pg_typeof(inverse_operation) as inv_type
      FROM operation_history 
      LIMIT 1
    `);
    
    console.log('\nSample data:');
    if (data.rows.length > 0) {
      const row = data.rows[0];
      console.log('Operation type:', typeof row.operation, row.op_type);
      console.log('Operation value:', row.operation);
      console.log('Inverse type:', typeof row.inverse_operation, row.inv_type);
      console.log('Inverse value:', row.inverse_operation);
    } else {
      console.log('No data found');
    }
    
    await pool.end();
  } catch (e) {
    console.error('Error:', e.message);
    process.exit(1);
  }
})();
