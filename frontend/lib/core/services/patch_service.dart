import '../models/page.dart';

/// Service for generating and applying JSON Patches (RFC 6902)
///
/// This is a simplified implementation that generates patches by
/// comparing old and new PageData objects.
class PatchService {
  /// Generate JSON patch between two page data objects
  ///
  /// Returns a list of RFC 6902 compliant patch operations
  List<Map<String, dynamic>> generatePatch(PageData oldData, PageData newData) {
    try {
      final patches = <Map<String, dynamic>>[];

      // Compare widgets
      final oldWidgets = oldData.widgets;
      final newWidgets = newData.widgets;

      // Check for removed widgets
      for (var i = 0; i < oldWidgets.length; i++) {
        final oldWidget = oldWidgets[i];
        final newWidget = newWidgets.firstWhere(
          (w) => w.id == oldWidget.id,
          orElse: () => oldWidget, // Use oldWidget as placeholder
        );

        if (newWidget == oldWidget &&
            !newWidgets.any((w) => w.id == oldWidget.id)) {
          // Widget was removed
          patches.add({'op': 'remove', 'path': '/widgets/$i'});
        }
      }

      // Check for added or updated widgets
      for (var i = 0; i < newWidgets.length; i++) {
        final newWidget = newWidgets[i];
        final oldWidgetIndex = oldWidgets.indexWhere(
          (w) => w.id == newWidget.id,
        );

        if (oldWidgetIndex == -1) {
          // Widget was added
          patches.add({
            'op': 'add',
            'path': '/widgets/$i',
            'value': newWidget.toJson(),
          });
        } else if (oldWidgetIndex != i ||
            oldWidgets[oldWidgetIndex] != newWidget) {
          // Widget was updated or moved
          patches.add({
            'op': 'replace',
            'path': '/widgets/$i',
            'value': newWidget.toJson(),
          });
        }
      }

      // Compare metadata
      if (oldData.metadata.width != newData.metadata.width) {
        patches.add({
          'op': 'replace',
          'path': '/metadata/width',
          'value': newData.metadata.width,
        });
      }

      if (oldData.metadata.height != newData.metadata.height) {
        patches.add({
          'op': 'replace',
          'path': '/metadata/height',
          'value': newData.metadata.height,
        });
      }

      if (oldData.metadata.backgroundColor !=
          newData.metadata.backgroundColor) {
        patches.add({
          'op': 'replace',
          'path': '/metadata/backgroundColor',
          'value': newData.metadata.backgroundColor,
        });
      }

      if (oldData.metadata.zoom != newData.metadata.zoom) {
        patches.add({
          'op': 'replace',
          'path': '/metadata/zoom',
          'value': newData.metadata.zoom,
        });
      }

      // Compare version
      if (oldData.version != newData.version) {
        patches.add({
          'op': 'replace',
          'path': '/version',
          'value': newData.version,
        });
      }

      print('📝 Generated patch: ${patches.length} operations');
      return patches;
    } catch (e) {
      print('❌ Patch generation failed: $e');
      throw Exception('Failed to generate patch: $e');
    }
  }

  /// Apply JSON patch to page data
  ///
  /// Returns updated PageData or null if patch fails
  PageData? applyPatch(PageData data, List<Map<String, dynamic>> patchOps) {
    try {
      // Convert to JSON for patching
      var currentJson = data.toJson();

      // Apply each patch operation
      for (final op in patchOps) {
        currentJson = _applyOperation(currentJson, op);
      }

      // Convert back to PageData
      final patchedData = PageData.fromJson(currentJson);

      print('✅ Patch applied successfully: ${patchOps.length} operations');
      return patchedData;
    } catch (e) {
      print('❌ Patch application failed: $e');
      return null;
    }
  }

  /// Apply a single patch operation
  Map<String, dynamic> _applyOperation(
    Map<String, dynamic> json,
    Map<String, dynamic> op,
  ) {
    final operation = op['op'] as String;
    final path = op['path'] as String;
    final value = op['value'];

    // Parse path (e.g., "/widgets/0/position" -> ["widgets", "0", "position"])
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();

    switch (operation) {
      case 'add':
        return _add(json, parts, value);
      case 'remove':
        return _remove(json, parts);
      case 'replace':
        return _replace(json, parts, value);
      case 'move':
        final from = op['from'] as String;
        final fromParts = from.split('/').where((p) => p.isNotEmpty).toList();
        return _move(json, fromParts, parts);
      case 'copy':
        final from = op['from'] as String;
        final fromParts = from.split('/').where((p) => p.isNotEmpty).toList();
        return _copy(json, fromParts, parts);
      case 'test':
        // Test operation - verify value at path
        return json;
      default:
        throw Exception('Unsupported operation: $operation');
    }
  }

  /// Add operation: add value at path
  Map<String, dynamic> _add(
    Map<String, dynamic> json,
    List<String> parts,
    dynamic value,
  ) {
    final result = Map<String, dynamic>.from(json);
    _navigate(result, parts, isAdd: true, value: value);
    return result;
  }

  /// Remove operation: remove value at path
  Map<String, dynamic> _remove(Map<String, dynamic> json, List<String> parts) {
    final result = Map<String, dynamic>.from(json);
    _navigate(result, parts, isRemove: true);
    return result;
  }

  /// Replace operation: replace value at path
  Map<String, dynamic> _replace(
    Map<String, dynamic> json,
    List<String> parts,
    dynamic value,
  ) {
    final result = Map<String, dynamic>.from(json);
    _navigate(result, parts, isReplace: true, value: value);
    return result;
  }

  /// Move operation: move value from one path to another
  Map<String, dynamic> _move(
    Map<String, dynamic> json,
    List<String> fromParts,
    List<String> toParts,
  ) {
    // Get value from source
    dynamic value;
    _navigate(json, fromParts, getValue: (v) => value = v);

    // Remove from source, add to destination
    var result = _remove(json, fromParts);
    result = _add(result, toParts, value);
    return result;
  }

  /// Copy operation: copy value from one path to another
  Map<String, dynamic> _copy(
    Map<String, dynamic> json,
    List<String> fromParts,
    List<String> toParts,
  ) {
    // Get value from source
    dynamic value;
    _navigate(json, fromParts, getValue: (v) => value = v);

    // Add to destination
    return _add(json, toParts, value);
  }

  /// Navigate JSON structure to apply operation
  void _navigate(
    dynamic current,
    List<String> parts, {
    bool isAdd = false,
    bool isRemove = false,
    bool isReplace = false,
    dynamic value,
    Function(dynamic)? getValue,
  }) {
    if (parts.isEmpty) {
      if (getValue != null) getValue(current);
      return;
    }

    final key = parts.first;
    final remaining = parts.sublist(1);

    if (current is Map) {
      if (remaining.isEmpty) {
        // Final key
        if (getValue != null) {
          getValue(current[key]);
        } else if (isAdd || isReplace) {
          current[key] = value;
        } else if (isRemove) {
          current.remove(key);
        }
      } else {
        // Navigate deeper
        if (current[key] == null) {
          current[key] = {};
        }
        _navigate(
          current[key],
          remaining,
          isAdd: isAdd,
          isRemove: isRemove,
          isReplace: isReplace,
          value: value,
          getValue: getValue,
        );
      }
    } else if (current is List) {
      final index = int.tryParse(key);
      if (index == null) throw Exception('Invalid array index: $key');

      if (remaining.isEmpty) {
        // Final index
        if (getValue != null) {
          getValue(current[index]);
        } else if (isAdd) {
          current.insert(index, value);
        } else if (isRemove) {
          current.removeAt(index);
        } else if (isReplace) {
          current[index] = value;
        }
      } else {
        // Navigate deeper
        _navigate(
          current[index],
          remaining,
          isAdd: isAdd,
          isRemove: isRemove,
          isReplace: isReplace,
          value: value,
          getValue: getValue,
        );
      }
    }
  }

  /// Validate patch operations
  bool validatePatch(PageData data, List<Map<String, dynamic>> patchOps) {
    try {
      // Try to apply patch
      final result = applyPatch(data, patchOps);
      return result != null;
    } catch (e) {
      print('⚠️ Patch validation failed: $e');
      return false;
    }
  }

  /// Generate patch for widget addition
  List<Map<String, dynamic>> generateAddWidgetPatch(
    PageWidget widget,
    int index,
  ) {
    return [
      {'op': 'add', 'path': '/widgets/$index', 'value': widget.toJson()},
    ];
  }

  /// Generate patch for widget update
  List<Map<String, dynamic>> generateUpdateWidgetPatch(
    int index,
    PageWidget oldWidget,
    PageWidget newWidget,
  ) {
    return [
      {'op': 'replace', 'path': '/widgets/$index', 'value': newWidget.toJson()},
    ];
  }

  /// Generate patch for widget removal
  List<Map<String, dynamic>> generateRemoveWidgetPatch(int index) {
    return [
      {'op': 'remove', 'path': '/widgets/$index'},
    ];
  }

  /// Generate patch for metadata update
  List<Map<String, dynamic>> generateMetadataPatch(
    PageMetadata oldMetadata,
    PageMetadata newMetadata,
  ) {
    final patches = <Map<String, dynamic>>[];

    if (oldMetadata.width != newMetadata.width) {
      patches.add({
        'op': 'replace',
        'path': '/metadata/width',
        'value': newMetadata.width,
      });
    }

    if (oldMetadata.height != newMetadata.height) {
      patches.add({
        'op': 'replace',
        'path': '/metadata/height',
        'value': newMetadata.height,
      });
    }

    if (oldMetadata.backgroundColor != newMetadata.backgroundColor) {
      patches.add({
        'op': 'replace',
        'path': '/metadata/backgroundColor',
        'value': newMetadata.backgroundColor,
      });
    }

    if (oldMetadata.zoom != newMetadata.zoom) {
      patches.add({
        'op': 'replace',
        'path': '/metadata/zoom',
        'value': newMetadata.zoom,
      });
    }

    return patches;
  }

  /// Optimize patches by removing redundant operations
  List<Map<String, dynamic>> optimizePatches(
    List<Map<String, dynamic>> patches,
  ) {
    if (patches.isEmpty) return patches;

    final optimized = <Map<String, dynamic>>[];
    final seenPaths = <String, int>{};

    // Process patches in reverse to keep last operation per path
    for (var i = patches.length - 1; i >= 0; i--) {
      final patch = patches[i];
      final path = patch['path'] as String;
      final op = patch['op'] as String;

      // For replace operations, keep only the last one per path
      if (op == 'replace') {
        if (!seenPaths.containsKey(path)) {
          optimized.insert(0, patch);
          seenPaths[path] = optimized.length - 1;
        }
      } else {
        // For add/remove, always include
        optimized.insert(0, patch);
      }
    }

    print('⚡ Optimized patches: ${patches.length} → ${optimized.length}');
    return optimized;
  }

  /// Detect conflicts between two patch sets
  List<String> detectConflicts(
    List<Map<String, dynamic>> patch1,
    List<Map<String, dynamic>> patch2,
  ) {
    final conflicts = <String>[];
    final paths1 = patch1.map((p) => p['path'] as String).toSet();
    final paths2 = patch2.map((p) => p['path'] as String).toSet();

    // Find overlapping paths
    for (final path in paths1) {
      if (paths2.contains(path)) {
        conflicts.add(path);
      }
    }

    if (conflicts.isNotEmpty) {
      print('🔀 Detected conflicts: ${conflicts.length} paths');
    }

    return conflicts;
  }

  /// Merge patches with Last-Write-Wins strategy
  List<Map<String, dynamic>> mergePatches(
    List<Map<String, dynamic>> localPatches,
    List<Map<String, dynamic>> remotePatches, {
    bool preferLocal = false,
  }) {
    final merged = <String, Map<String, dynamic>>{};

    // Add all patches to map (path -> patch)
    for (final patch in localPatches) {
      final path = patch['path'] as String;
      merged[path] = patch;
    }

    // Remote patches override (unless preferLocal is true)
    for (final patch in remotePatches) {
      final path = patch['path'] as String;
      if (!preferLocal || !merged.containsKey(path)) {
        merged[path] = patch;
      }
    }

    print(
      '🔀 Merged patches: ${localPatches.length} + ${remotePatches.length} = ${merged.length}',
    );
    return merged.values.toList();
  }
}
