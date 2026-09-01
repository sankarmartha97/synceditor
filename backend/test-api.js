/**
 * API Integration Test Script
 * Tests all backend endpoints to verify functionality
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:5000';
let authToken = '';
let userId = '';
let canvasId = '';
let widgetId = '';

// Test data
const testUser = {
  email: `test_${Date.now()}@example.com`,
  password: 'password123',
  name: 'Test User'
};

const testCanvas = {
  name: 'Test Canvas',
  description: 'A test canvas for integration testing',
  settings: { grid: true, snap: true },
  is_public: false
};

const testWidget = {
  type: 'rectangle',
  position: { x: 100, y: 100, z_index: 0 },
  size: { width: 200, height: 150, width_unit: 'px', height_unit: 'px' },
  properties: { color: '#ff0000', borderWidth: 2 }
};

// Helper function to make requests
async function makeRequest(method, endpoint, data = null, useAuth = false) {
  try {
    const config = {
      method,
      url: `${BASE_URL}${endpoint}`,
      headers: useAuth ? { Authorization: `Bearer ${authToken}` } : {},
      data
    };
    
    const response = await axios(config);
    return { success: true, data: response.data, status: response.status };
  } catch (error) {
    return {
      success: false,
      error: error.response?.data || error.message,
      status: error.response?.status
    };
  }
}

// Test functions
async function testHealthCheck() {
  console.log('\n📋 Testing Health Check...');
  const result = await makeRequest('GET', '/health');
  
  if (result.success && result.data.success) {
    console.log('✅ Health check passed');
    return true;
  } else {
    console.log('❌ Health check failed:', result.error);
    return false;
  }
}

async function testAPIInfo() {
  console.log('\n📋 Testing API Info...');
  const result = await makeRequest('GET', '/api');
  
  if (result.success && result.data.success) {
    console.log('✅ API info retrieved');
    console.log('   Version:', result.data.version);
    return true;
  } else {
    console.log('❌ API info failed:', result.error);
    return false;
  }
}

async function testRegister() {
  console.log('\n📋 Testing User Registration...');
  const result = await makeRequest('POST', '/api/auth/register', testUser);
  
  if (result.success && result.data.success) {
    authToken = result.data.data.token;
    userId = result.data.data.user.id;
    console.log('✅ User registered successfully');
    console.log('   User ID:', userId);
    console.log('   Email:', result.data.data.user.email);
    return true;
  } else {
    console.log('❌ Registration failed:', result.error);
    return false;
  }
}

async function testLogin() {
  console.log('\n📋 Testing User Login...');
  const result = await makeRequest('POST', '/api/auth/login', {
    email: testUser.email,
    password: testUser.password
  });
  
  if (result.success && result.data.success) {
    authToken = result.data.data.token;
    console.log('✅ Login successful');
    console.log('   Token received');
    return true;
  } else {
    console.log('❌ Login failed:', result.error);
    return false;
  }
}

async function testGetCurrentUser() {
  console.log('\n📋 Testing Get Current User...');
  const result = await makeRequest('GET', '/api/auth/me', null, true);
  
  if (result.success && result.data.success) {
    console.log('✅ Current user retrieved');
    console.log('   Name:', result.data.data.name);
    console.log('   Email:', result.data.data.email);
    return true;
  } else {
    console.log('❌ Get current user failed:', result.error);
    return false;
  }
}

async function testCreateCanvas() {
  console.log('\n📋 Testing Create Canvas...');
  const result = await makeRequest('POST', '/api/canvases', testCanvas, true);
  
  if (result.success && result.data.success) {
    canvasId = result.data.data.id;
    console.log('✅ Canvas created successfully');
    console.log('   Canvas ID:', canvasId);
    console.log('   Canvas Name:', result.data.data.name);
    return true;
  } else {
    console.log('❌ Create canvas failed:', result.error);
    return false;
  }
}

async function testGetCanvases() {
  console.log('\n📋 Testing Get Canvases...');
  const result = await makeRequest('GET', '/api/canvases', null, true);
  
  if (result.success && result.data.success) {
    console.log('✅ Canvases retrieved');
    console.log('   Total canvases:', result.data.data.length);
    return true;
  } else {
    console.log('❌ Get canvases failed:', result.error);
    return false;
  }
}

async function testGetCanvasById() {
  console.log('\n📋 Testing Get Canvas By ID...');
  const result = await makeRequest('GET', `/api/canvases/${canvasId}`, null, true);
  
  if (result.success && result.data.success) {
    console.log('✅ Canvas retrieved');
    console.log('   Canvas Name:', result.data.data.name);
    console.log('   Widgets:', result.data.data.widgets?.length || 0);
    return true;
  } else {
    console.log('❌ Get canvas by ID failed:', result.error);
    return false;
  }
}

async function testCreateWidget() {
  console.log('\n📋 Testing Create Widget...');
  const result = await makeRequest('POST', `/api/canvases/${canvasId}/widgets`, testWidget, true);
  
  if (result.success && result.data.success) {
    widgetId = result.data.data.id;
    console.log('✅ Widget created successfully');
    console.log('   Widget ID:', widgetId);
    console.log('   Widget Type:', result.data.data.type);
    return true;
  } else {
    console.log('❌ Create widget failed:', result.error);
    return false;
  }
}

async function testGetWidgets() {
  console.log('\n📋 Testing Get Widgets...');
  const result = await makeRequest('GET', `/api/canvases/${canvasId}/widgets`, null, true);
  
  if (result.success && result.data.success) {
    console.log('✅ Widgets retrieved');
    console.log('   Total widgets:', result.data.data.length);
    return true;
  } else {
    console.log('❌ Get widgets failed:', result.error);
    return false;
  }
}

async function testUpdateWidget() {
  console.log('\n📋 Testing Update Widget...');
  const updates = {
    position: { x: 200, y: 200, z_index: 1 },
    properties: { color: '#00ff00', borderWidth: 3 }
  };
  
  const result = await makeRequest('PUT', `/api/canvases/${canvasId}/widgets/${widgetId}`, updates, true);
  
  if (result.success && result.data.success) {
    console.log('✅ Widget updated successfully');
    console.log('   New position:', result.data.data.position);
    return true;
  } else {
    console.log('❌ Update widget failed:', result.error);
    return false;
  }
}

async function testUpdateCanvas() {
  console.log('\n📋 Testing Update Canvas...');
  const updates = {
    name: 'Updated Test Canvas',
    description: 'Updated description'
  };
  
  const result = await makeRequest('PUT', `/api/canvases/${canvasId}`, updates, true);
  
  if (result.success && result.data.success) {
    console.log('✅ Canvas updated successfully');
    console.log('   New name:', result.data.data.name);
    return true;
  } else {
    console.log('❌ Update canvas failed:', result.error);
    return false;
  }
}

async function testDeleteWidget() {
  console.log('\n📋 Testing Delete Widget...');
  const result = await makeRequest('DELETE', `/api/canvases/${canvasId}/widgets/${widgetId}`, null, true);
  
  if (result.success && result.data.success) {
    console.log('✅ Widget deleted successfully');
    return true;
  } else {
    console.log('❌ Delete widget failed:', result.error);
    return false;
  }
}

async function testDeleteCanvas() {
  console.log('\n📋 Testing Delete Canvas...');
  const result = await makeRequest('DELETE', `/api/canvases/${canvasId}`, null, true);
  
  if (result.success && result.data.success) {
    console.log('✅ Canvas deleted successfully');
    return true;
  } else {
    console.log('❌ Delete canvas failed:', result.error);
    return false;
  }
}

// Run all tests
async function runAllTests() {
  console.log('\n' + '='.repeat(60));
  console.log('🧪 CANVAS EDITOR API INTEGRATION TESTS');
  console.log('='.repeat(60));
  
  const tests = [
    { name: 'Health Check', fn: testHealthCheck },
    { name: 'API Info', fn: testAPIInfo },
    { name: 'User Registration', fn: testRegister },
    { name: 'User Login', fn: testLogin },
    { name: 'Get Current User', fn: testGetCurrentUser },
    { name: 'Create Canvas', fn: testCreateCanvas },
    { name: 'Get Canvases', fn: testGetCanvases },
    { name: 'Get Canvas By ID', fn: testGetCanvasById },
    { name: 'Create Widget', fn: testCreateWidget },
    { name: 'Get Widgets', fn: testGetWidgets },
    { name: 'Update Widget', fn: testUpdateWidget },
    { name: 'Update Canvas', fn: testUpdateCanvas },
    { name: 'Delete Widget', fn: testDeleteWidget },
    { name: 'Delete Canvas', fn: testDeleteCanvas }
  ];
  
  let passed = 0;
  let failed = 0;
  
  for (const test of tests) {
    try {
      const result = await test.fn();
      if (result) {
        passed++;
      } else {
        failed++;
      }
    } catch (error) {
      console.log(`❌ ${test.name} threw an error:`, error.message);
      failed++;
    }
    
    // Small delay between tests
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  
  console.log('\n' + '='.repeat(60));
  console.log('📊 TEST RESULTS');
  console.log('='.repeat(60));
  console.log(`✅ Passed: ${passed}`);
  console.log(`❌ Failed: ${failed}`);
  console.log(`📈 Success Rate: ${((passed / tests.length) * 100).toFixed(1)}%`);
  console.log('='.repeat(60) + '\n');
  
  process.exit(failed > 0 ? 1 : 0);
}

// Run tests
runAllTests().catch(error => {
  console.error('💥 Test suite error:', error);
  process.exit(1);
});
