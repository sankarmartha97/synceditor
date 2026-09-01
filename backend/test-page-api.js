/**
 * Test script for Page API endpoints
 * Run with: node test-page-api.js
 */

const axios = require('axios');

const API_URL = 'http://localhost:5000/api';
let authToken = '';
let createdPageId = '';

// Test credentials
const testUser = {
  email: 'sankar@gmail.com',
  password: 'sankar@123',
};

async function login() {
  console.log('\n🔐 Step 1: Login...');
  try {
    const response = await axios.post(`${API_URL}/auth/login`, testUser);
    authToken = response.data.data.token;
    console.log('✅ Login successful');
    console.log(`   Token: ${authToken.substring(0, 20)}...`);
    return true;
  } catch (error) {
    console.error('❌ Login failed:', error.response?.data || error.message);
    return false;
  }
}

async function createPage() {
  console.log('\n📄 Step 2: Create a new page...');
  try {
    const response = await axios.post(
      `${API_URL}/pages`,
      {
        name: 'Test Page - E-commerce Homepage',
        metadata: {
          width: 1920,
          height: 1080,
          backgroundColor: '#F5F5F5',
          gridSize: 10,
        },
      },
      {
        headers: { Authorization: `Bearer ${authToken}` },
      }
    );
    
    createdPageId = response.data.data.id;
    console.log('✅ Page created successfully');
    console.log(`   Page ID: ${createdPageId}`);
    console.log(`   Page Name: ${response.data.data.name}`);
    console.log(`   Version: ${response.data.data.version}`);
    return true;
  } catch (error) {
    console.error('❌ Create page failed:', error.response?.data || error.message);
    return false;
  }
}

async function getUserPages() {
  console.log('\n📋 Step 3: Get all user pages...');
  try {
    const response = await axios.get(`${API_URL}/pages`, {
      headers: { Authorization: `Bearer ${authToken}` },
    });
    
    console.log('✅ Pages retrieved successfully');
    console.log(`   Total pages: ${response.data.data.length}`);
    response.data.data.forEach((page, index) => {
      console.log(`   ${index + 1}. ${page.name} (${page.permission})`);
    });
    return true;
  } catch (error) {
    console.error('❌ Get pages failed:', error.response?.data || error.message);
    return false;
  }
}

async function getPageById() {
  console.log('\n📖 Step 4: Get specific page...');
  try {
    const response = await axios.get(`${API_URL}/pages/${createdPageId}`, {
      headers: { Authorization: `Bearer ${authToken}` },
    });
    
    console.log('✅ Page retrieved successfully');
    console.log(`   Page ID: ${response.data.data.id}`);
    console.log(`   Name: ${response.data.data.name}`);
    console.log(`   Version: ${response.data.data.version}`);
    console.log(`   Widgets: ${response.data.data.pageData.widgets.length}`);
    console.log(`   Metadata:`, response.data.data.pageData.metadata);
    return true;
  } catch (error) {
    console.error('❌ Get page failed:', error.response?.data || error.message);
    return false;
  }
}

async function renamePage() {
  console.log('\n✏️  Step 5: Rename page...');
  try {
    const response = await axios.put(
      `${API_URL}/pages/${createdPageId}/name`,
      { name: 'Updated Test Page - Landing Page' },
      {
        headers: { Authorization: `Bearer ${authToken}` },
      }
    );
    
    console.log('✅ Page renamed successfully');
    console.log(`   New name: ${response.data.data.name}`);
    return true;
  } catch (error) {
    console.error('❌ Rename failed:', error.response?.data || error.message);
    return false;
  }
}

async function sharePage() {
  console.log('\n👥 Step 6: Share page with another user...');
  try {
    const response = await axios.post(
      `${API_URL}/pages/${createdPageId}/share`,
      {
        email: 'john@gmail.com',
        permissionType: 'edit',
      },
      {
        headers: { Authorization: `Bearer ${authToken}` },
      }
    );
    
    console.log('✅ Page shared successfully');
    console.log(`   Shared with: john@gmail.com`);
    console.log(`   Permission: edit`);
    return true;
  } catch (error) {
    console.error('❌ Share failed:', error.response?.data || error.message);
    return false;
  }
}

async function getPermissions() {
  console.log('\n🔑 Step 7: Get page permissions...');
  try {
    const response = await axios.get(
      `${API_URL}/pages/${createdPageId}/permissions`,
      {
        headers: { Authorization: `Bearer ${authToken}` },
      }
    );
    
    console.log('✅ Permissions retrieved successfully');
    console.log(`   Total collaborators: ${response.data.data.length}`);
    response.data.data.forEach((perm, index) => {
      console.log(`   ${index + 1}. ${perm.user_name} (${perm.user_email}) - ${perm.permission_type}`);
    });
    return true;
  } catch (error) {
    console.error('❌ Get permissions failed:', error.response?.data || error.message);
    return false;
  }
}

async function runTests() {
  console.log('🧪 Testing Page API Endpoints');
  console.log('================================\n');
  
  const results = [];
  
  // Run tests sequentially
  results.push(await login());
  if (!results[0]) return;
  
  results.push(await createPage());
  if (!results[1]) return;
  
  results.push(await getUserPages());
  results.push(await getPageById());
  results.push(await renamePage());
  results.push(await sharePage());
  results.push(await getPermissions());
  
  // Summary
  console.log('\n\n📊 Test Summary');
  console.log('================================');
  const passed = results.filter(r => r).length;
  const total = results.length;
  console.log(`✅ Passed: ${passed}/${total}`);
  console.log(`❌ Failed: ${total - passed}/${total}`);
  
  if (passed === total) {
    console.log('\n🎉 All tests passed! Phase 1.2 Backend API is working!');
  } else {
    console.log('\n⚠️  Some tests failed. Check errors above.');
  }
  
  console.log(`\n📝 Created page ID: ${createdPageId}`);
  console.log('   You can use this ID for further testing.');
}

// Run the tests
runTests().catch(console.error);
