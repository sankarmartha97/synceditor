const otService = require('../src-js/services/ot.service');

describe('OT Service - Operational Transformation', () => {
  describe('1. Same Path Transformations', () => {
    test('1.1 Add + Add: Increment client index', () => {
      const clientOp = { op: 'add', path: '/widgets/0', value: { id: 'A' } };
      const serverOp = { op: 'add', path: '/widgets/0', value: { id: 'B' } };

      const result = otService.transformOperation(clientOp, serverOp);

      expect(result).not.toBeNull();
      expect(result.path).toBe('/widgets/1');
      expect(result.op).toBe('add');
    });

    test('1.2 Remove + Remove: Cancel client operation', () => {
      const clientOp = { op: 'remove', path: '/widgets/1' };
      const serverOp = { op: 'remove', path: '/widgets/1' };

      const result = otService.transformOperation(clientOp, serverOp);

      expect(result).toBeNull();
    });

    test('1.3 Replace + Remove: Cancel client update', () => {
      const clientOp = { op: 'replace', path: '/widgets/1/position', value: { x: 100 } };
      const serverOp = { op: 'remove', path: '/widgets/1/position' };

      const result = otService.transformOperation(clientOp, serverOp);

      expect(result).toBeNull();
    });

    test('1.4 Remove + Replace: Delete wins', () => {
      const clientOp = { op: 'remove', path: '/widgets/1' };
      const serverOp = { op: 'replace', path: '/widgets/1', value: { id: 'updated' } };

      const result = otService.transformOperation(clientOp, serverOp);

      expect(result).not.toBeNull();
      expect(result.op).toBe('remove');
    });

    test('1.5 Replace + Replace: Last-Write-Wins', () => {
      const clientOp = { op: 'replace', path: '/widgets/0/position', value: { x: 100 } };
      const serverOp = { op: 'replace', path: '/widgets/0/position', value: { x: 200 } };

      const result = otService.transformOperation(clientOp, serverOp);

      expect(result).not.toBeNull();
      expect(result.value).toEqual({ x: 100 });
    });
  });

  describe('2. Array Index Adjustments', () => {
    test('2.1 Server add before client: Increment client index', () => {
      const clientOp = { op: 'add', path: '/widgets/2', value: { id: 'C' } };
      const serverOp = { op: 'add', path: '/widgets/0', value: { id: 'A' } };

      const result = otService.transformOperation(clientOp, serverOp);

      expect(result).not.toBeNull();
      expect(result.path).toBe('/widgets/3');
    });

    test('2.2 Server add after client: No change', () => {
      const clientOp = { op: 'add', path: '/widgets/0', value: { id: 'A' } };
      const serverOp = { op: 'add', path: '/widgets/2', value: { id: 'C' } };

      const result = otService.transformOperation(clientOp, serverOp);

      expect(result).not.toBeNull();
      expect(result.path).toBe('/widgets/0');
    });

    test('2.3 Server remove before client: Decrement client index', () => {
      const clientOp = { op: 'replace', path: '/widgets/3/position', value: { x: 100 } };
      const serverOp = { op: 'remove', path: '/widgets/1' };

      const result = otService.transformOperation(clientOp, serverOp);

      expect(result).not.toBeNull();
      expect(result.path).toBe('/widgets/2/position');
    });

    test('2.4 Server remove at client index: Cancel operation', () => {
      const clientOp = { op: 'replace', path: '/widgets/2/color', value: 'blue' };
      const serverOp = { op: 'remove', path: '/widgets/2' };

      const result = otService.transformOperation(clientOp, serverOp);

      expect(result).toBeNull();
    });
  });

  describe('3. Parent-Child Path Operations', () => {
    test('3.1 Parent removed: Cancel child operation', () => {
      const clientOp = { op: 'replace', path: '/widgets/1/position/x', value: 100 };
      const serverOp = { op: 'remove', path: '/widgets/1' };

      const result = otService.transformOperation(clientOp, serverOp);

      expect(result).toBeNull();
    });

    test('3.2 Parent replaced: Keep child operation', () => {
      const clientOp = { op: 'replace', path: '/widgets/1/properties/text', value: 'Hello' };
      const serverOp = { op: 'replace', path: '/widgets/1', value: { id: 'new' } };

      const result = otService.transformOperation(clientOp, serverOp);

      expect(result).not.toBeNull();
      expect(result.path).toBe('/widgets/1/properties/text');
    });
  });

  describe('4. Non-overlapping Paths', () => {
    test('4.1 Different widgets: No transformation', () => {
      const clientOp = { op: 'replace', path: '/widgets/0/position', value: { x: 100 } };
      const serverOp = { op: 'replace', path: '/widgets/1/color', value: 'blue' };

      const result = otService.transformOperation(clientOp, serverOp);

      expect(result).toEqual(clientOp);
    });

    test('4.2 Different properties: No transformation', () => {
      const clientOp = { op: 'replace', path: '/widgets/0/position', value: { x: 100 } };
      const serverOp = { op: 'replace', path: '/widgets/0/size', value: { w: 200 } };

      const result = otService.transformOperation(clientOp, serverOp);

      expect(result).toEqual(clientOp);
    });

    test('4.3 Metadata vs widgets: No transformation', () => {
      const clientOp = { op: 'replace', path: '/metadata/zoom', value: 1.5 };
      const serverOp = { op: 'add', path: '/widgets/0', value: { id: 'A' } };

      const result = otService.transformOperation(clientOp, serverOp);

      expect(result).toEqual(clientOp);
    });
  });

  describe('5. Multi-Operation Patch Transformation', () => {
    test('5.1 Transform patch against multiple server operations', () => {
      // Simpler test case
      const clientPatches = [
        { op: 'add', path: '/widgets/1', value: { id: 'C' } }
      ];

      const serverPatches = [
        { op: 'add', path: '/widgets/0', value: { id: 'A' } },  // Add before client
        { op: 'remove', path: '/widgets/2' }                     // Remove after transformed position
      ];

      const result = otService.transformPatch(clientPatches, serverPatches, 1, 3);

      expect(result).toHaveLength(1);
      // Client adds at 1, server adds at 0 → shifts to 2, server removes at 2 (different item) → stays at 2
      expect(result[0].path).toBe('/widgets/2');
    });

    test('5.2 Some operations cancelled', () => {
      const clientPatches = [
        { op: 'replace', path: '/widgets/1/color', value: 'blue' },
        { op: 'add', path: '/widgets/0', value: { id: 'A' } }
      ];

      const serverPatches = [
        { op: 'remove', path: '/widgets/1' }
      ];

      const result = otService.transformPatch(clientPatches, serverPatches, 1, 2);

      expect(result).toHaveLength(1); // First operation cancelled
      expect(result[0].op).toBe('add');
    });
  });

  describe('6. Helper Functions', () => {
    test('6.1 pathsOverlap: Exact match', () => {
      const result = otService.pathsOverlap('/widgets/0', '/widgets/0');
      expect(result).toBe(true);
    });

    test('6.2 pathsOverlap: Parent-child', () => {
      const result = otService.pathsOverlap('/widgets/0/position', '/widgets/0');
      expect(result).toBe(true);
    });

    test('6.3 pathsOverlap: Same array base', () => {
      const result = otService.pathsOverlap('/widgets/0', '/widgets/1');
      expect(result).toBe(true);
    });

    test('6.4 pathsOverlap: No overlap', () => {
      const result = otService.pathsOverlap('/widgets/0', '/metadata/zoom');
      expect(result).toBe(false);
    });

    test('6.5 getPathIndex: Extract index', () => {
      expect(otService.getPathIndex('/widgets/0')).toBe(0);
      expect(otService.getPathIndex('/widgets/5/position')).toBe(5);
      expect(otService.getPathIndex('/metadata/zoom')).toBeNull();
    });

    test('6.6 isArrayPath: Detect array', () => {
      expect(otService.isArrayPath('/widgets/0')).toBe(true);
      expect(otService.isArrayPath('/widgets/0/position')).toBe(true);
      expect(otService.isArrayPath('/metadata/zoom')).toBe(false);
    });

    test('6.7 adjustPathIndex: Adjust by delta', () => {
      const op = { op: 'add', path: '/widgets/2', value: {} };
      const result = otService.adjustPathIndex(op, +1);
      expect(result.path).toBe('/widgets/3');
    });

    test('6.8 adjustPathIndex: Negative index returns null', () => {
      const op = { op: 'add', path: '/widgets/0', value: {} };
      const result = otService.adjustPathIndex(op, -1);
      expect(result).toBeNull();
    });
  });

  describe('7. Edge Cases', () => {
    test('7.1 Empty client patches', () => {
      const result = otService.transformPatch([], [{ op: 'add', path: '/widgets/0', value: {} }], 1, 2);
      expect(result).toEqual([]);
    });

    test('7.2 Empty server patches', () => {
      const clientPatches = [{ op: 'add', path: '/widgets/0', value: {} }];
      const result = otService.transformPatch(clientPatches, [], 1, 1);
      expect(result).toEqual(clientPatches);
    });

    test('7.3 Multiple adds at same index', () => {
      const clientOp = { op: 'add', path: '/widgets/0', value: { id: 'C' } };
      const serverOps = [
        { op: 'add', path: '/widgets/0', value: { id: 'A' } },
        { op: 'add', path: '/widgets/0', value: { id: 'B' } }
      ];

      const result = otService.transformPatch([clientOp], serverOps, 1, 3);

      expect(result[0].path).toBe('/widgets/2'); // Pushed to index 2
    });
  });

  describe('8. Operation Priority', () => {
    test('8.1 getOperationPriority', () => {
      expect(otService.getOperationPriority({ op: 'remove' })).toBe(3);
      expect(otService.getOperationPriority({ op: 'add' })).toBe(2);
      expect(otService.getOperationPriority({ op: 'replace' })).toBe(1);
    });

    test('8.2 resolveConflict: Higher priority wins', () => {
      const clientOp = { op: 'replace', path: '/widgets/0', value: {} };
      const serverOp = { op: 'remove', path: '/widgets/0' };

      const result = otService.resolveConflict(clientOp, serverOp);

      expect(result).toBeNull(); // Server's remove has higher priority
    });
  });
});
