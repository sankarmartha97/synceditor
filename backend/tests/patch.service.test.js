const patchService = require('../src-js/services/patch.service');

describe('Patch Service Tests', () => {
  
  // ==================== PATCH GENERATION TESTS ====================
  
  describe('1. Patch Generation', () => {
    
    test('1.1 Generate patch for widget position change', () => {
      const oldData = {
        pageId: 'test-page',
        widgets: [
          { id: 'widget-1', position: { x: 100, y: 100 } }
        ]
      };
      
      const newData = {
        pageId: 'test-page',
        widgets: [
          { id: 'widget-1', position: { x: 150, y: 200 } }
        ]
      };
      
      const patches = patchService.generatePatch(oldData, newData);
      
      expect(patches).toBeDefined();
      expect(patches.length).toBeGreaterThan(0);
      expect(patches[0].op).toBe('replace');
      expect(patches[0].path).toContain('/widgets/0/position');
      
      console.log('✅ Test 1.1 passed: Position change patch generated');
    });
    
    test('1.2 Generate patch for widget addition', () => {
      const oldData = {
        widgets: []
      };
      
      const newData = {
        widgets: [
          { id: 'widget-1', type: 'rectangle', position: { x: 50, y: 50 } }
        ]
      };
      
      const patches = patchService.generatePatch(oldData, newData);
      
      expect(patches).toBeDefined();
      expect(patches.length).toBeGreaterThan(0);
      expect(patches.some(p => p.op === 'add')).toBe(true);
      
      console.log('✅ Test 1.2 passed: Widget addition patch generated');
    });
    
    test('1.3 Generate patch for widget removal', () => {
      const oldData = {
        widgets: [
          { id: 'widget-1', type: 'rectangle' },
          { id: 'widget-2', type: 'circle' }
        ]
      };
      
      const newData = {
        widgets: [
          { id: 'widget-1', type: 'rectangle' }
        ]
      };
      
      const patches = patchService.generatePatch(oldData, newData);
      
      expect(patches).toBeDefined();
      expect(patches.length).toBeGreaterThan(0);
      
      console.log('✅ Test 1.3 passed: Widget removal patch generated');
    });
    
    test('1.4 Generate patch for property change', () => {
      const oldData = {
        metadata: { backgroundColor: '#FFFFFF', zoom: 1.0 }
      };
      
      const newData = {
        metadata: { backgroundColor: '#000000', zoom: 1.5 }
      };
      
      const patches = patchService.generatePatch(oldData, newData);
      
      expect(patches).toBeDefined();
      expect(patches.length).toBe(2);
      expect(patches.every(p => p.op === 'replace')).toBe(true);
      
      console.log('✅ Test 1.4 passed: Property change patches generated');
    });
    
    test('1.5 No patches for identical data', () => {
      const data = {
        widgets: [{ id: 'widget-1', x: 100 }]
      };
      
      const patches = patchService.generatePatch(data, data);
      
      expect(patches).toBeDefined();
      expect(patches.length).toBe(0);
      
      console.log('✅ Test 1.5 passed: No patches for identical data');
    });
  });
  
  // ==================== PATCH APPLICATION TESTS ====================
  
  describe('2. Patch Application', () => {
    
    test('2.1 Apply valid position change patch', () => {
      const data = {
        widgets: [
          { id: 'widget-1', position: { x: 100, y: 100 } }
        ]
      };
      
      const patches = [
        { op: 'replace', path: '/widgets/0/position/x', value: 200 }
      ];
      
      const result = patchService.applyPatch(data, patches);
      
      expect(result.success).toBe(true);
      expect(result.data.widgets[0].position.x).toBe(200);
      expect(result.data.widgets[0].position.y).toBe(100); // Unchanged
      
      console.log('✅ Test 2.1 passed: Position patch applied successfully');
    });
    
    test('2.2 Apply widget addition patch', () => {
      const data = {
        widgets: []
      };
      
      const patches = [
        { 
          op: 'add', 
          path: '/widgets/0', 
          value: { id: 'new-widget', type: 'circle' } 
        }
      ];
      
      const result = patchService.applyPatch(data, patches);
      
      expect(result.success).toBe(true);
      expect(result.data.widgets.length).toBe(1);
      expect(result.data.widgets[0].id).toBe('new-widget');
      
      console.log('✅ Test 2.2 passed: Widget addition patch applied');
    });
    
    test('2.3 Apply widget removal patch', () => {
      const data = {
        widgets: [
          { id: 'widget-1' },
          { id: 'widget-2' }
        ]
      };
      
      const patches = [
        { op: 'remove', path: '/widgets/1' }
      ];
      
      const result = patchService.applyPatch(data, patches);
      
      expect(result.success).toBe(true);
      expect(result.data.widgets.length).toBe(1);
      expect(result.data.widgets[0].id).toBe('widget-1');
      
      console.log('✅ Test 2.3 passed: Widget removal patch applied');
    });
    
    test('2.4 Reject invalid patch (bad path)', () => {
      const data = {
        widgets: []
      };
      
      const patches = [
        { op: 'replace', path: '/nonexistent/path', value: 'test' }
      ];
      
      const result = patchService.applyPatch(data, patches);
      
      expect(result.success).toBe(false);
      expect(result.errors).toBeDefined();
      // errors is an object, not an array
      expect(result.errors).toBeTruthy();
      
      console.log('✅ Test 2.4 passed: Invalid patch rejected');
    });
    
    test('2.5 Apply multiple patches atomically', () => {
      const data = {
        widgets: [
          { id: 'w1', x: 100 },
          { id: 'w2', x: 200 }
        ]
      };
      
      const patches = [
        { op: 'replace', path: '/widgets/0/x', value: 150 },
        { op: 'replace', path: '/widgets/1/x', value: 250 }
      ];
      
      const result = patchService.applyPatch(data, patches);
      
      expect(result.success).toBe(true);
      expect(result.data.widgets[0].x).toBe(150);
      expect(result.data.widgets[1].x).toBe(250);
      
      console.log('✅ Test 2.5 passed: Multiple patches applied atomically');
    });
  });
  
  // ==================== PATCH VALIDATION TESTS ====================
  
  describe('3. Patch Validation', () => {
    
    test('3.1 Validate correct patch structure', () => {
      const data = { widgets: [{ id: 'w1' }] };
      const patches = [
        { op: 'replace', path: '/widgets/0/id', value: 'w2' }
      ];
      
      const result = patchService.validatePatch(patches, data);
      
      expect(result.valid).toBe(true);
      expect(result.errors.length).toBe(0);
      
      console.log('✅ Test 3.1 passed: Valid patch structure confirmed');
    });
    
    test('3.2 Detect invalid operation', () => {
      const data = { widgets: [] };
      const patches = [
        { op: 'invalid_op', path: '/widgets', value: 'test' }
      ];
      
      const result = patchService.validatePatch(patches, data);
      
      expect(result.valid).toBe(false);
      
      console.log('✅ Test 3.2 passed: Invalid operation detected');
    });
    
    test('3.3 Detect missing path in patch', () => {
      const data = { widgets: [] };
      const patches = [
        { op: 'add', value: 'test' } // Missing path
      ];
      
      const result = patchService.validatePatch(patches, data);
      
      expect(result.valid).toBe(false);
      
      console.log('✅ Test 3.3 passed: Missing path detected');
    });
  });
  
  // ==================== PATCH OPTIMIZATION TESTS ====================
  
  describe('4. Patch Optimization', () => {
    
    test('4.1 Remove redundant replace operations', () => {
      const patches = [
        { op: 'replace', path: '/widgets/0/x', value: 100 },
        { op: 'replace', path: '/widgets/0/x', value: 150 },
        { op: 'replace', path: '/widgets/0/x', value: 200 }
      ];
      
      const optimized = patchService.optimizePatches(patches);
      
      expect(optimized.length).toBeLessThan(patches.length);
      expect(optimized[0].value).toBe(200); // Should keep last value
      
      console.log('✅ Test 4.1 passed: Redundant operations removed');
      console.log(`   Optimized: ${patches.length} → ${optimized.length} operations`);
    });
    
    test('4.2 Keep all non-replace operations', () => {
      const patches = [
        { op: 'add', path: '/widgets/0', value: { id: 'w1' } },
        { op: 'add', path: '/widgets/1', value: { id: 'w2' } },
        { op: 'remove', path: '/widgets/0' }
      ];
      
      const optimized = patchService.optimizePatches(patches);
      
      expect(optimized.length).toBe(patches.length);
      
      console.log('✅ Test 4.2 passed: All non-replace operations kept');
    });
  });
  
  // ==================== CONFLICT DETECTION TESTS ====================
  
  describe('5. Conflict Detection', () => {
    
    test('5.1 Detect concurrent edits on same path', () => {
      const patch1 = [
        { op: 'replace', path: '/widgets/0/x', value: 100 }
      ];
      
      const patch2 = [
        { op: 'replace', path: '/widgets/0/x', value: 150 }
      ];
      
      const result = patchService.transformPatches(patch1, patch2);
      
      expect(result.conflicts).toBeDefined();
      expect(result.conflicts.length).toBeGreaterThan(0);
      expect(result.conflicts[0]).toBe('/widgets/0/x');
      
      console.log('✅ Test 5.1 passed: Conflict detected on same path');
    });
    
    test('5.2 No conflicts on different paths', () => {
      const patch1 = [
        { op: 'replace', path: '/widgets/0/x', value: 100 }
      ];
      
      const patch2 = [
        { op: 'replace', path: '/widgets/1/x', value: 150 }
      ];
      
      const result = patchService.transformPatches(patch1, patch2);
      
      expect(result.conflicts.length).toBe(0);
      
      console.log('✅ Test 5.2 passed: No conflicts on different paths');
    });
    
    test('5.3 Detect multiple conflicts', () => {
      const patch1 = [
        { op: 'replace', path: '/widgets/0/x', value: 100 },
        { op: 'replace', path: '/widgets/0/y', value: 200 },
        { op: 'replace', path: '/metadata/zoom', value: 1.5 }
      ];
      
      const patch2 = [
        { op: 'replace', path: '/widgets/0/x', value: 150 },
        { op: 'replace', path: '/metadata/zoom', value: 2.0 }
      ];
      
      const result = patchService.transformPatches(patch1, patch2);
      
      expect(result.conflicts.length).toBe(2);
      
      console.log('✅ Test 5.3 passed: Multiple conflicts detected');
      console.log(`   Found ${result.conflicts.length} conflicts`);
    });
  });
  
  // ==================== INTEGRATION TESTS ====================
  
  describe('6. Integration Tests', () => {
    
    test('6.1 Full cycle: generate → apply → verify', () => {
      const oldData = {
        pageId: 'page-1',
        widgets: [
          { id: 'w1', position: { x: 100, y: 100 }, color: '#FF0000' }
        ],
        metadata: { zoom: 1.0 }
      };
      
      const newData = {
        pageId: 'page-1',
        widgets: [
          { id: 'w1', position: { x: 200, y: 150 }, color: '#00FF00' }
        ],
        metadata: { zoom: 1.5 }
      };
      
      // Generate patches
      const patches = patchService.generatePatch(oldData, newData);
      expect(patches.length).toBeGreaterThan(0);
      
      // Apply patches
      const result = patchService.applyPatch(oldData, patches);
      expect(result.success).toBe(true);
      
      // Verify result matches newData
      expect(result.data.widgets[0].position.x).toBe(200);
      expect(result.data.widgets[0].position.y).toBe(150);
      expect(result.data.widgets[0].color).toBe('#00FF00');
      expect(result.data.metadata.zoom).toBe(1.5);
      
      console.log('✅ Test 6.1 passed: Full cycle completed successfully');
    });
    
    test('6.2 Complex scenario: add, modify, remove', () => {
      const oldData = {
        widgets: [
          { id: 'w1', x: 100 },
          { id: 'w2', x: 200 },
          { id: 'w3', x: 300 }
        ]
      };
      
      const newData = {
        widgets: [
          { id: 'w1', x: 150 },  // Modified
          { id: 'w4', x: 400 }   // w2 removed, w4 added, w3 removed
        ]
      };
      
      const patches = patchService.generatePatch(oldData, newData);
      const result = patchService.applyPatch(oldData, patches);
      
      expect(result.success).toBe(true);
      expect(result.data.widgets.length).toBe(2);
      expect(result.data.widgets[0].x).toBe(150);
      expect(result.data.widgets[1].id).toBe('w4');
      
      console.log('✅ Test 6.2 passed: Complex add/modify/remove scenario');
    });
  });
});

// Run tests
console.log('\n🧪 ==================== PATCH SERVICE TEST SUITE ====================\n');
console.log('Testing JSON Patch generation, application, validation, optimization, and conflict detection\n');
