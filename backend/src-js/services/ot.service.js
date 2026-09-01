/**
 * Operational Transformation (OT) Service
 * 
 * Transforms concurrent operations to maintain convergence
 * Based on JSON Patch (RFC 6902) operations
 */

class OTService {
  /**
   * Transform client patch against server patches
   * 
   * @param {Array} clientPatches - Client's patch operations
   * @param {Array} serverPatches - Server's patch operations since client's version
   * @param {number} clientVersion - Client's base version
   * @param {number} serverVersion - Current server version
   * @returns {Array} Transformed client patches
   */
  transformPatch(clientPatches, serverPatches, clientVersion, serverVersion) {
    console.log(`🔀 Transforming client patches (v${clientVersion}) against ${serverPatches.length} server operations`);

    let transformedPatches = [...clientPatches];

    // Transform client patches against each server patch in order
    for (const serverPatch of serverPatches) {
      transformedPatches = transformedPatches
        .map(clientOp => this.transformOperation(clientOp, serverPatch))
        .filter(op => op !== null); // Remove nullified operations
    }

    console.log(`✅ Transformed ${clientPatches.length} → ${transformedPatches.length} operations`);
    return transformedPatches;
  }

  /**
   * Transform one operation against another
   * 
   * @param {Object} op1 - Operation to transform
   * @param {Object} op2 - Operation to transform against
   * @returns {Object|null} Transformed operation or null if cancelled
   */
  transformOperation(op1, op2) {
    const operation = op1.op;
    const againstOp = op2.op;

    // If paths don't overlap, no transformation needed
    if (!this.pathsOverlap(op1.path, op2.path)) {
      return op1;
    }

    // Same path transformations
    if (op1.path === op2.path) {
      return this.transformSamePath(op1, op2);
    }

    // Parent-child path transformations
    if (this.isParentPath(op2.path, op1.path)) {
      return this.transformChildAgainstParent(op1, op2);
    }

    // Array index adjustments
    if (this.isArrayPath(op1.path) && this.isArrayPath(op2.path)) {
      return this.transformArrayPaths(op1, op2);
    }

    return op1;
  }

  /**
   * Transform operations on the same path
   */
  transformSamePath(op1, op2) {
    // add + add: Both trying to add at same position
    if (op1.op === 'add' && op2.op === 'add') {
      // Server's add happened first, increment client's index
      return this.incrementPathIndex(op1);
    }

    // remove + remove: Both removing same thing
    if (op1.op === 'remove' && op2.op === 'remove') {
      console.log('⚠️ Both removing same item - cancelling client operation');
      return null; // Already removed by server
    }

    // replace + remove: Server deleted, client trying to update
    if (op1.op === 'replace' && op2.op === 'remove') {
      console.log('⚠️ Server removed item client is updating - cancelling');
      return null; // Can't update deleted item
    }

    // remove + replace: Client deleting, server updated
    if (op1.op === 'remove' && op2.op === 'replace') {
      // Delete wins - keep the remove operation
      return op1;
    }

    // replace + replace: Both updating same field
    if (op1.op === 'replace' && op2.op === 'replace') {
      // Last-Write-Wins: Server's update already applied
      // We still apply client's update (will overwrite)
      console.log('⚠️ Concurrent updates to same field - Last-Write-Wins');
      return op1;
    }

    return op1;
  }

  /**
   * Transform child path against parent path operation
   */
  transformChildAgainstParent(childOp, parentOp) {
    // Parent removed - child operation is meaningless
    if (parentOp.op === 'remove') {
      console.log(`⚠️ Parent ${parentOp.path} removed - cancelling child ${childOp.path}`);
      return null;
    }

    // Parent replaced - child operation may still be valid
    if (parentOp.op === 'replace') {
      // Keep child operation, it will apply to new parent value
      return childOp;
    }

    return childOp;
  }

  /**
   * Transform array path operations
   */
  transformArrayPaths(op1, op2) {
    const index1 = this.getPathIndex(op1.path);
    const index2 = this.getPathIndex(op2.path);

    if (index1 === null || index2 === null) {
      return op1;
    }

    // Server added before client's index
    if (op2.op === 'add' && index2 <= index1) {
      return this.adjustPathIndex(op1, +1);
    }

    // Server removed before client's index
    if (op2.op === 'remove' && index2 < index1) {
      return this.adjustPathIndex(op1, -1);
    }

    // Server removed at client's index
    if (op2.op === 'remove' && index2 === index1) {
      if (op1.op === 'remove') {
        return null; // Already removed
      }
      // Client trying to update removed item
      console.log(`⚠️ Server removed index ${index2} - cancelling client operation`);
      return null;
    }

    return op1;
  }

  /**
   * Check if two paths overlap
   */
  pathsOverlap(path1, path2) {
    // Exact match
    if (path1 === path2) return true;

    // One is parent of the other
    if (path1.startsWith(path2 + '/') || path2.startsWith(path1 + '/')) {
      return true;
    }

    // Same array, different indices
    const base1 = this.getPathBase(path1);
    const base2 = this.getPathBase(path2);
    if (base1 === base2 && this.isArrayPath(path1) && this.isArrayPath(path2)) {
      return true;
    }

    return false;
  }

  /**
   * Check if path2 is parent of path1
   */
  isParentPath(parentPath, childPath) {
    return childPath.startsWith(parentPath + '/');
  }

  /**
   * Check if path contains array index
   */
  isArrayPath(path) {
    const parts = path.split('/').filter(p => p.length > 0);
    return parts.some(part => /^\d+$/.test(part));
  }

  /**
   * Get array index from path
   */
  getPathIndex(path) {
    const parts = path.split('/').filter(p => p.length > 0);
    for (let i = parts.length - 1; i >= 0; i--) {
      if (/^\d+$/.test(parts[i])) {
        return parseInt(parts[i], 10);
      }
    }
    return null;
  }

  /**
   * Get base path (without index)
   */
  getPathBase(path) {
    const parts = path.split('/');
    const filtered = [];
    
    for (const part of parts) {
      if (/^\d+$/.test(part)) {
        break;
      }
      filtered.push(part);
    }
    
    return filtered.join('/');
  }

  /**
   * Adjust path index by delta
   */
  adjustPathIndex(operation, delta) {
    const index = this.getPathIndex(operation.path);
    if (index === null) return operation;

    const newIndex = index + delta;
    if (newIndex < 0) {
      console.log(`⚠️ Index would be negative - cancelling operation`);
      return null;
    }

    const newPath = operation.path.replace(
      /\/\d+/,
      `/${newIndex}`
    );

    return {
      ...operation,
      path: newPath
    };
  }

  /**
   * Increment path index by 1
   */
  incrementPathIndex(operation) {
    return this.adjustPathIndex(operation, 1);
  }

  /**
   * Decrement path index by 1
   */
  decrementPathIndex(operation) {
    return this.adjustPathIndex(operation, -1);
  }

  /**
   * Validate transformed patches
   */
  validateTransformedPatches(patches) {
    for (const patch of patches) {
      if (!patch.op || !patch.path) {
        console.error('❌ Invalid patch:', patch);
        return false;
      }

      if (['add', 'replace', 'test'].includes(patch.op) && patch.value === undefined) {
        console.error('❌ Patch missing value:', patch);
        return false;
      }
    }
    return true;
  }

  /**
   * Get operation priority (for conflict resolution)
   */
  getOperationPriority(operation) {
    const priorities = {
      'remove': 3,  // Delete has highest priority
      'add': 2,     // Add is next
      'replace': 1, // Replace is lowest
      'test': 0
    };
    return priorities[operation.op] || 0;
  }

  /**
   * Resolve operation conflict using priority
   */
  resolveConflict(op1, op2) {
    const priority1 = this.getOperationPriority(op1);
    const priority2 = this.getOperationPriority(op2);

    if (priority2 > priority1) {
      console.log(`⚠️ Server operation has higher priority - cancelling client operation`);
      return null;
    }

    return op1;
  }
}

module.exports = new OTService();
