/**
 * Undo/Redo Service
 * Generates inverse operations and transforms undos using Operational Transformation
 */

const jsonpatch = require('fast-json-patch');
const otService = require('./ot.service');

/**
 * Generate inverse operation for a JSON Patch operation
 * The inverse operation, when applied, undoes the original operation
 * 
 * @param {Array} operations - JSON Patch operations to invert
 * @param {Object} documentBeforeOp - Document state before operations applied
 * @returns {Array} Inverse operations
 */
const generateInverse = (operations, documentBeforeOp) => {
  const inverseOps = [];

  // Process operations in reverse order
  for (let i = operations.length - 1; i >= 0; i--) {
    const op = operations[i];
    let inverseOp = null;

    switch (op.op) {
      case 'add':
        // Inverse of add is remove
        inverseOp = {
          op: 'remove',
          path: op.path,
        };
        break;

      case 'remove':
        // Inverse of remove is add (need the removed value)
        // Get the value that was removed from the document before operation
        const removedValue = getValueAtPath(documentBeforeOp, op.path);
        inverseOp = {
          op: 'add',
          path: op.path,
          value: removedValue,
        };
        break;

      case 'replace':
        // Inverse of replace is replace with old value
        const oldValue = getValueAtPath(documentBeforeOp, op.path);
        inverseOp = {
          op: 'replace',
          path: op.path,
          value: oldValue,
        };
        break;

      case 'move':
        // Inverse of move from A to B is move from B to A
        inverseOp = {
          op: 'move',
          from: op.path, // New location becomes source
          path: op.from, // Old location becomes destination
        };
        break;

      case 'copy':
        // Inverse of copy is remove the copied item
        inverseOp = {
          op: 'remove',
          path: op.path,
        };
        break;

      default:
        console.warn(`⚠️ Unknown operation type: ${op.op}`);
    }

    if (inverseOp) {
      inverseOps.push(inverseOp);
    }
  }

  return inverseOps;
};

/**
 * Get value at a JSON Pointer path
 * @param {Object} document - The document
 * @param {string} path - JSON Pointer path (e.g., "/widgets/0/color")
 * @returns {*} Value at path, or undefined if not found
 */
const getValueAtPath = (document, path) => {
  try {
    // Remove leading slash and split path
    const parts = path.substring(1).split('/').map(part => {
      // Unescape JSON Pointer special characters
      return part.replace(/~1/g, '/').replace(/~0/g, '~');
    });

    let current = document;
    for (const part of parts) {
      if (current === undefined || current === null) {
        return undefined;
      }
      current = current[part];
    }

    // Deep clone to avoid reference issues
    return JSON.parse(JSON.stringify(current));
  } catch (error) {
    console.error('❌ Get value at path error:', error);
    return undefined;
  }
};

/**
 * Transform an undo operation against concurrent operations using OT
 * This ensures that undo works correctly even when other users made concurrent changes
 * 
 * @param {Array} undoOperation - The undo operation to transform
 * @param {Array} concurrentOperations - Operations that happened concurrently
 * @param {number} undoVersion - Version when the original operation was performed
 * @param {number} currentVersion - Current document version
 * @returns {Array} Transformed undo operation
 */
const transformUndo = (undoOperation, concurrentOperations, undoVersion, currentVersion) => {
  if (concurrentOperations.length === 0) {
    // No concurrent operations, undo can be applied as-is
    return undoOperation;
  }

  console.log(`🔀 Transforming undo operation against ${concurrentOperations.length} concurrent operations`);

  // Use OT to transform the undo operation
  // The undo operation was created at undoVersion, but we're now at currentVersion
  // We need to transform it against all operations that happened between
  let transformedUndo = undoOperation;

  for (const concurrentOp of concurrentOperations) {
    // Transform undo operation against each concurrent operation
    transformedUndo = otService.transformPatch(
      transformedUndo,
      [concurrentOp],
      undoVersion,
      concurrentOp.to_version || currentVersion
    );
  }

  console.log(`✅ Undo operation transformed`);
  return transformedUndo;
};

/**
 * Validate if an undo operation can be applied to the current document state
 * Returns true if the undo is valid, false otherwise
 * 
 * @param {Array} undoOperation - The undo operation to validate
 * @param {Object} currentDocument - Current document state
 * @returns {Object} { valid: boolean, error: string|null }
 */
const validateUndo = (undoOperation, currentDocument) => {
  try {
    // Try to apply the operation to a clone of the document
    const testDoc = JSON.parse(JSON.stringify(currentDocument));
    const errors = jsonpatch.validate(undoOperation, testDoc);

    if (errors) {
      return {
        valid: false,
        error: `Undo validation failed: ${errors.message || 'Invalid operation'}`,
      };
    }

    // Additional validation: check if paths still exist
    for (const op of undoOperation) {
      if (op.op === 'remove' || op.op === 'replace') {
        const value = getValueAtPath(testDoc, op.path);
        if (value === undefined) {
          return {
            valid: false,
            error: `Path ${op.path} no longer exists in document`,
          };
        }
      }
    }

    return { valid: true, error: null };
  } catch (error) {
    return {
      valid: false,
      error: `Undo validation error: ${error.message}`,
    };
  }
};

/**
 * Apply an undo operation to a document
 * Similar to patch application but specifically for undo
 * 
 * @param {Object} document - The document to apply undo to
 * @param {Array} undoOperation - The undo operation
 * @returns {Object} { success: boolean, data: Object|null, errors: Array }
 */
const applyUndo = (document, undoOperation) => {
  try {
    // Validate first
    const validation = validateUndo(undoOperation, document);
    if (!validation.valid) {
      return {
        success: false,
        data: null,
        errors: [validation.error],
      };
    }

    // Apply the undo operation
    const docCopy = JSON.parse(JSON.stringify(document));
    
    try {
      // applyPatch(document, patch, validateOperation = true, mutateDocument = true, banPrototypeModifications = true)
      // We want to validate and mutate
      jsonpatch.applyPatch(docCopy, undoOperation, true, true);
      
      return {
        success: true,
        data: docCopy,
        errors: [],
      };
    } catch (patchError) {
      // jsonpatch.applyPatch throws on error
      return {
        success: false,
        data: null,
        errors: [patchError.message || String(patchError)],
      };
    }
  } catch (error) {
    console.error('❌ Apply undo error:', error);
    return {
      success: false,
      data: null,
      errors: [error.message],
    };
  }
};

/**
 * Check if two operations conflict (operate on same or overlapping paths)
 * Used to detect when OT transformation is needed
 * 
 * @param {Object} op1 - First operation
 * @param {Object} op2 - Second operation
 * @returns {boolean} True if operations conflict
 */
const operationsConflict = (op1, op2) => {
  const path1 = op1.path || '';
  const path2 = op2.path || '';

  // Exact path match
  if (path1 === path2) return true;

  // Check if one path is ancestor of the other
  if (path1.startsWith(path2 + '/') || path2.startsWith(path1 + '/')) {
    return true;
  }

  // Check array index operations (e.g., /widgets/0 and /widgets/1)
  const arrayRegex = /^(.*\/)(\d+)(\/.*)?$/;
  const match1 = path1.match(arrayRegex);
  const match2 = path2.match(arrayRegex);

  if (match1 && match2 && match1[1] === match2[1]) {
    // Same array, might affect indices
    return true;
  }

  return false;
};

/**
 * Analyze operation to determine its impact
 * Useful for UI feedback and optimization
 * 
 * @param {Array} operations - Operations to analyze
 * @returns {Object} Impact analysis
 */
const analyzeOperationImpact = (operations) => {
  const analysis = {
    operationCount: operations.length,
    operationTypes: {},
    affectedPaths: new Set(),
    isComplex: false,
  };

  for (const op of operations) {
    // Count operation types
    analysis.operationTypes[op.op] = (analysis.operationTypes[op.op] || 0) + 1;

    // Track affected paths
    if (op.path) analysis.affectedPaths.add(op.path);
    if (op.from) analysis.affectedPaths.add(op.from);
  }

  // Determine complexity
  analysis.isComplex = 
    operations.length > 5 || 
    analysis.affectedPaths.size > 3;

  analysis.affectedPaths = Array.from(analysis.affectedPaths);

  return analysis;
};

/**
 * Generate a human-readable description of an operation
 * Useful for undo/redo UI
 * 
 * @param {Array} operations - Operations to describe
 * @returns {string} Human-readable description
 */
const describeOperation = (operations) => {
  if (operations.length === 0) return 'No operation';

  if (operations.length === 1) {
    const op = operations[0];
    const pathParts = op.path?.split('/').filter(Boolean) || [];
    const target = pathParts[0] || 'item';

    switch (op.op) {
      case 'add':
        return `Add ${target}`;
      case 'remove':
        return `Remove ${target}`;
      case 'replace':
        return `Update ${target}`;
      case 'move':
        return `Move ${target}`;
      case 'copy':
        return `Copy ${target}`;
      default:
        return 'Modify item';
    }
  }

  // Multiple operations
  const types = new Set(operations.map(op => op.op));
  if (types.size === 1) {
    const type = Array.from(types)[0];
    return `${operations.length} ${type} operations`;
  }

  return `${operations.length} operations`;
};

module.exports = {
  generateInverse,
  transformUndo,
  validateUndo,
  applyUndo,
  operationsConflict,
  analyzeOperationImpact,
  describeOperation,
  getValueAtPath,
};
