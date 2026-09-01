const axios = require('axios');

// API Base URL
const API_URL = 'http://localhost:5000/api';

// Test user credentials
const testUser = {
  email: 'test@example.com',
  password: 'Test123!@#',
  name: 'Test User'
};

let authToken = null;
let testPageId = null;
let testPage2Id = null;

// Helper function to make authenticated requests
const apiClient = (token) => ({
  get: (url) => axios.get(`${API_URL}${url}`, {
    headers: { Authorization: `Bearer ${token}` }
  }),
  post: (url, data) => axios.post(`${API_URL}${url}`, data, {
    headers: { Authorization: `Bearer ${token}` }
  }),
  patch: (url, data) => axios.patch(`${API_URL}${url}`, data, {
    headers: { Authorization: `Bearer ${token}` }
  }),
  put: (url, data) => axios.put(`${API_URL}${url}`, data, {
    headers: { Authorization: `Bearer ${token}` }
  }),
  delete: (url) => axios.delete(`${API_URL}${url}`, {
    headers: { Authorization: `Bearer ${token}` }
  }),
});

describe('Page API Integration Tests', () => {
  
  // ==================== SETUP ====================
  
  beforeAll(async () => {
    console.log('\n🚀 Starting Page API Test Suite...');
    console.log('🔗 Testing against:', API_URL);
    
    // Register or login test user
    try {
      const response = await axios.post(`${API_URL}/auth/register`, testUser);
      authToken = response.data.data.token;
      console.log('✅ Test user registered');
    } catch (error) {
      // If user exists, try login
      try {
        const loginResponse = await axios.post(`${API_URL}/auth/login`, {
          email: testUser.email,
          password: testUser.password
        });
        authToken = loginResponse.data.data.token;
        console.log('✅ Test user logged in');
      } catch (loginError) {
        console.error('❌ Authentication failed:', loginError.message);
        throw loginError;
      }
    }
  });
  
  // ==================== 1. PAGE CREATION TESTS ====================
  
  describe('1. Page Creation', () => {
    
    test('1.1 Create new page with default metadata', async () => {
      const client = apiClient(authToken);
      
      const response = await client.post('/pages', {
        name: 'Test Page 1'
      });
      
      expect(response.status).toBe(201);
      expect(response.data.success).toBe(true);
      expect(response.data.data).toHaveProperty('id');
      expect(response.data.data.name).toBe('Test Page 1');
      expect(response.data.data.pageData).toHaveProperty('metadata');
      expect(response.data.data.pageData.widgets).toEqual([]);
      
      testPageId = response.data.data.id;
      
      console.log('✅ Test 1.1 passed: Page created with default metadata');
    });
    
    test('1.2 Create page with custom metadata', async () => {
      const client = apiClient(authToken);
      
      const response = await client.post('/pages', {
        name: 'Test Page 2',
        metadata: {
          width: 2560,
          height: 1440,
          backgroundColor: '#F0F0F0',
          gridSize: 20
        }
      });
      
      expect(response.status).toBe(201);
      expect(response.data.data.pageData.metadata.width).toBe(2560);
      expect(response.data.data.pageData.metadata.height).toBe(1440);
      expect(response.data.data.pageData.metadata.backgroundColor).toBe('#F0F0F0');
      
      testPage2Id = response.data.data.id;
      
      console.log('✅ Test 1.2 passed: Page created with custom metadata');
    });
    
    test('1.3 Reject page creation without name', async () => {
      const client = apiClient(authToken);
      
      try {
        await client.post('/pages', {});
        fail('Should have thrown error');
      } catch (error) {
        expect(error.response.status).toBe(400);
        console.log('✅ Test 1.3 passed: Rejected page without name');
      }
    });
    
    test('1.4 Reject unauthenticated page creation', async () => {
      try {
        await axios.post(`${API_URL}/pages`, {
          name: 'Unauthorized Page'
        });
        fail('Should have thrown error');
      } catch (error) {
        expect(error.response.status).toBe(401);
        console.log('✅ Test 1.4 passed: Rejected unauthenticated request');
      }
    });
  });
  
  // ==================== 2. PAGE RETRIEVAL TESTS ====================
  
  describe('2. Page Retrieval', () => {
    
    test('2.1 Get all user pages', async () => {
      const client = apiClient(authToken);
      
      const response = await client.get('/pages');
      
      expect(response.status).toBe(200);
      expect(response.data.success).toBe(true);
      expect(Array.isArray(response.data.data)).toBe(true);
      expect(response.data.data.length).toBeGreaterThanOrEqual(2);
      
      console.log(`✅ Test 2.1 passed: Retrieved ${response.data.data.length} pages`);
    });
    
    test('2.2 Get specific page by ID', async () => {
      const client = apiClient(authToken);
      
      const response = await client.get(`/pages/${testPageId}`);
      
      expect(response.status).toBe(200);
      expect(response.data.data.id).toBe(testPageId);
      expect(response.data.data.name).toBe('Test Page 1');
      expect(response.data.data).toHaveProperty('pageData');
      expect(response.data.data).toHaveProperty('version');
      
      console.log('✅ Test 2.2 passed: Retrieved specific page');
    });
    
    test('2.3 Return 404 for non-existent page', async () => {
      const client = apiClient(authToken);
      const fakeId = '00000000-0000-0000-0000-000000000000';
      
      try {
        await client.get(`/pages/${fakeId}`);
        fail('Should have thrown error');
      } catch (error) {
        expect(error.response.status).toBe(404);
        console.log('✅ Test 2.3 passed: 404 for non-existent page');
      }
    });
  });
  
  // ==================== 3. PAGE UPDATE TESTS ====================
  
  describe('3. Page Updates', () => {
    
    test('3.1 Update page name', async () => {
      const client = apiClient(authToken);
      
      const response = await client.put(`/pages/${testPageId}/name`, {
        name: 'Updated Test Page 1'
      });
      
      expect(response.status).toBe(200);
      expect(response.data.data.name).toBe('Updated Test Page 1');
      
      console.log('✅ Test 3.1 passed: Page name updated');
    });
    
    test('3.2 Update page data (add widget)', async () => {
      const client = apiClient(authToken);
      
      // Get current page
      const currentPage = await client.get(`/pages/${testPageId}`);
      const currentData = currentPage.data.data.pageData;
      
      // Add widget
      currentData.widgets.push({
        id: 'widget-1',
        type: 'rectangle',
        position: { x: 100, y: 100 },
        size: { width: 200, height: 150 },
        properties: { color: '#FF0000' }
      });
      
      const response = await client.patch(`/pages/${testPageId}`, {
        pageData: currentData
      });
      
      expect(response.status).toBe(200);
      expect(response.data.data.pageData.widgets.length).toBe(1);
      expect(response.data.data.pageData.widgets[0].id).toBe('widget-1');
      expect(response.data.data.version).toBe(currentPage.data.data.version + 1);
      
      console.log('✅ Test 3.2 passed: Widget added to page');
    });
    
    test('3.3 Update widget position', async () => {
      const client = apiClient(authToken);
      
      // Get current page
      const currentPage = await client.get(`/pages/${testPageId}`);
      const currentData = currentPage.data.data.pageData;
      
      // Update widget position
      currentData.widgets[0].position = { x: 200, y: 250 };
      
      const response = await client.patch(`/pages/${testPageId}`, {
        pageData: currentData
      });
      
      expect(response.status).toBe(200);
      expect(response.data.data.pageData.widgets[0].position.x).toBe(200);
      expect(response.data.data.pageData.widgets[0].position.y).toBe(250);
      
      console.log('✅ Test 3.3 passed: Widget position updated');
    });
    
    test('3.4 Update metadata', async () => {
      const client = apiClient(authToken);
      
      const currentPage = await client.get(`/pages/${testPageId}`);
      const currentData = currentPage.data.data.pageData;
      
      currentData.metadata.zoom = 1.5;
      currentData.metadata.backgroundColor = '#333333';
      
      const response = await client.patch(`/pages/${testPageId}`, {
        pageData: currentData
      });
      
      expect(response.status).toBe(200);
      expect(response.data.data.pageData.metadata.zoom).toBe(1.5);
      expect(response.data.data.pageData.metadata.backgroundColor).toBe('#333333');
      
      console.log('✅ Test 3.4 passed: Metadata updated');
    });
  });
  
  // ==================== 4. PERMISSION TESTS ====================
  
  describe('4. Page Permissions', () => {
    
    test('4.1 Get page permissions (owner only)', async () => {
      const client = apiClient(authToken);
      
      const response = await client.get(`/pages/${testPageId}/permissions`);
      
      expect(response.status).toBe(200);
      expect(Array.isArray(response.data.data)).toBe(true);
      
      console.log(`✅ Test 4.1 passed: Retrieved ${response.data.data.length} permissions`);
    });
    
    test('4.2 Share page with view permission', async () => {
      const client = apiClient(authToken);
      
      const response = await client.post(`/pages/${testPageId}/share`, {
        email: 'viewer@example.com',
        permissionType: 'view'
      });
      
      expect(response.status).toBe(201);
      expect(response.data.data.permission_type).toBe('view');
      
      console.log('✅ Test 4.2 passed: Page shared with view permission');
    });
    
    test('4.3 Share page with edit permission', async () => {
      const client = apiClient(authToken);
      
      const response = await client.post(`/pages/${testPageId}/share`, {
        email: 'editor@example.com',
        permissionType: 'edit'
      });
      
      expect(response.status).toBe(201);
      expect(response.data.data.permission_type).toBe('edit');
      
      console.log('✅ Test 4.3 passed: Page shared with edit permission');
    });
    
    test('4.4 Reject invalid permission type', async () => {
      const client = apiClient(authToken);
      
      try {
        await client.post(`/pages/${testPageId}/share`, {
          email: 'user@example.com',
          permissionType: 'invalid'
        });
        fail('Should have thrown error');
      } catch (error) {
        expect(error.response.status).toBe(400);
        console.log('✅ Test 4.4 passed: Invalid permission type rejected');
      }
    });
  });
  
  // ==================== 5. PAGE DELETION TESTS ====================
  
  describe('5. Page Deletion', () => {
    
    test('5.1 Soft delete page', async () => {
      const client = apiClient(authToken);
      
      const response = await client.delete(`/pages/${testPage2Id}`);
      
      expect(response.status).toBe(200);
      expect(response.data.success).toBe(true);
      
      console.log('✅ Test 5.1 passed: Page soft deleted');
    });
    
    test('5.2 Deleted page not in list', async () => {
      const client = apiClient(authToken);
      
      const response = await client.get('/pages');
      const deletedPage = response.data.data.find(p => p.id === testPage2Id);
      
      expect(deletedPage).toBeUndefined();
      
      console.log('✅ Test 5.2 passed: Deleted page not in list');
    });
    
    test('5.3 Cannot access deleted page', async () => {
      const client = apiClient(authToken);
      
      try {
        await client.get(`/pages/${testPage2Id}`);
        fail('Should have thrown error');
      } catch (error) {
        expect(error.response.status).toBe(404);
        console.log('✅ Test 5.3 passed: Cannot access deleted page');
      }
    });
  });
  
  // ==================== 6. VERSION TRACKING TESTS ====================
  
  describe('6. Version Tracking', () => {
    
    test('6.1 Version increments on update', async () => {
      const client = apiClient(authToken);
      
      const before = await client.get(`/pages/${testPageId}`);
      const beforeVersion = before.data.data.version;
      
      // Make update
      const currentData = before.data.data.pageData;
      currentData.metadata.zoom = 2.0;
      
      const after = await client.patch(`/pages/${testPageId}`, {
        pageData: currentData
      });
      
      expect(after.data.data.version).toBe(beforeVersion + 1);
      
      console.log(`✅ Test 6.1 passed: Version incremented (${beforeVersion} → ${after.data.data.version})`);
    });
    
    test('6.2 Version stays same on name change', async () => {
      const client = apiClient(authToken);
      
      const before = await client.get(`/pages/${testPageId}`);
      const beforeVersion = before.data.data.version;
      
      await client.put(`/pages/${testPageId}/name`, {
        name: 'Version Test Page'
      });
      
      const after = await client.get(`/pages/${testPageId}`);
      
      // Name changes don't increment page_data version
      expect(after.data.data.version).toBe(beforeVersion);
      
      console.log('✅ Test 6.2 passed: Version unchanged on name change');
    });
  });
  
  // ==================== CLEANUP ====================
  
  afterAll(async () => {
    // Clean up test page
    try {
      const client = apiClient(authToken);
      await client.delete(`/pages/${testPageId}`);
      console.log('\n🧹 Cleanup: Test pages deleted');
    } catch (error) {
      console.warn('⚠️ Cleanup warning:', error.message);
    }
    
    console.log('\n✅ All Page API tests completed!\n');
  });
});
