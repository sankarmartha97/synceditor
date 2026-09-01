# Version 2.0 Implementation Guide - Frontend & Backend Changes

## 📋 Document Overview

This guide provides a **complete, step-by-step** implementation checklist for adding nested widget support to SyncEditor.

**Structure**:
- Part A: Flutter Frontend Changes
- Part B: Node.js Backend Changes
- Part C: Integration & Testing

---

# PART A: FLUTTER FRONTEND CHANGES

## 🎨 Frontend File Structure

```
frontend/lib/
├── core/
│   ├── models/
│   │   ├── page.dart                    ← MODIFY (add parent/child fields)
│   │   └── position_mode.dart           ← NEW (position mode enum)
│   ├── utils/
│   │   └── widget_tree_helper.dart      ← NEW (tree operations)
│   └── services/
│       └── patch_service.dart           ← NO CHANGE (already works)
├── features/
│   ├── page/
│   │   ├── bloc/
│   │   │   ├── page_bloc.dart           ← MODIFY (add new events)
│   │   │   ├── page_event.dart          ← MODIFY (add nested events)
│   │   │   └── page_state.dart          ← MINIMAL CHANGE
│   │   ├── views/
│   │   │   ├── page_canvas_view.dart    ← MODIFY (recursive rendering)
│   │   │   └── widget_tree_panel.dart   ← NEW (tree visualization)
│   │   └── widgets/
│   │       └── widget_drop_zone.dart    ← NEW (container drop target)
│   ├── properties/
│   │   └── views/
│   │       └── properties_panel.dart    ← MODIFY (show parent info)
│   └── widget_library/
│       └── views/
│           └── widget_library_panel.dart ← MODIFY (container indicators)
```

---

## 📁 FRONTEND CHANGES - DETAILED

### 1️⃣ NEW FILE: `core/models/position_mode.dart`

**Location**: `frontend/lib/core/models/position_mode.dart`

**Purpose**: Define position modes for widgets

**Code**:
```dart
/// Position mode for widgets in the canvas
enum PositionMode {
  /// Position relative to canvas (absolute coordinates)
  absolute,
  
  /// Position relative to parent widget
  relative,
  
  /// Fixed position (doesn't move with parent)
  fixed,
}

/// Extension methods for PositionMode
extension PositionModeExtension on PositionMode {
  String toJsonString() {
    switch (this) {
      case PositionMode.absolute:
        return 'absolute';
      case PositionMode.relative:
        return 'relative';
      case PositionMode.fixed:
        return 'fixed';
    }
  }

  static PositionMode fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'absolute':
        return PositionMode.absolute;
      case 'relative':
        return PositionMode.relative;
      case 'fixed':
        return PositionMode.fixed;
      default:
        return PositionMode.absolute;
    }
  }
}
```

**Status**: ✅ Complete code provided  
**Estimated Time**: 10 minutes  

---

### 2️⃣ MODIFY FILE: `core/models/page.dart`

**Location**: `frontend/lib/core/models/page.dart`

**Changes Required**:

#### A. Add imports at top:
```dart
import 'position_mode.dart';
```

#### B. Update `PageWidget` class:

**Find this section** (around line 87):
```dart
class PageWidget {
  final String id;
  final String type;
  final Offset position;
  final Size size;
  final Map<String, dynamic> properties;
  final String? createdAt;
  final String? createdBy;
  final String? updatedAt;
  final String? updatedBy;
```

**Replace with**:
```dart
class PageWidget {
  final String id;
  final String type;
  final Offset position;
  final Size size;
  final Map<String, dynamic> properties;
  
  // ✨ NEW: Nesting support fields
  final String? parentId;
  final List<String> childrenIds;
  final bool isContainer;
  final int zIndex;
  final PositionMode positionMode;
  
  final String? createdAt;
  final String? createdBy;
  final String? updatedAt;
  final String? updatedBy;
```

#### C. Update constructor:

**Find**:
```dart
PageWidget({
  required this.id,
  required this.type,
  required this.position,
  required this.size,
  required this.properties,
  this.createdAt,
  this.createdBy,
  this.updatedAt,
  this.updatedBy,
});
```

**Replace with**:
```dart
PageWidget({
  required this.id,
  required this.type,
  required this.position,
  required this.size,
  required this.properties,
  this.parentId,
  List<String>? childrenIds,
  bool? isContainer,
  this.zIndex = 0,
  this.positionMode = PositionMode.absolute,
  this.createdAt,
  this.createdBy,
  this.updatedAt,
  this.updatedBy,
}) : childrenIds = childrenIds ?? [],
     isContainer = isContainer ?? _isContainerType(type);

// Helper to detect container types
static bool _isContainerType(String type) {
  const containerTypes = [
    'Container',
    'Card',
    'Row',
    'Column',
    'Stack',
    'ListView',
    'GridView',
  ];
  return containerTypes.contains(type);
}
```

#### D. Update `fromJson` method:

**Find**:
```dart
factory PageWidget.fromJson(Map<String, dynamic> json) {
  final position = json['position'] as Map<String, dynamic>;
  final size = json['size'] as Map<String, dynamic>;

  return PageWidget(
    id: json['id'],
    type: json['type'],
    position: Offset(
      (position['x'] as num).toDouble(),
      (position['y'] as num).toDouble(),
    ),
    size: Size(
      (size['width'] as num).toDouble(),
      (size['height'] as num).toDouble(),
    ),
    properties: Map<String, dynamic>.from(json['properties'] ?? {}),
    createdAt: json['createdAt'],
    createdBy: json['createdBy'],
    updatedAt: json['updatedAt'],
    updatedBy: json['updatedBy'],
  );
}
```

**Replace with**:
```dart
factory PageWidget.fromJson(Map<String, dynamic> json) {
  final position = json['position'] as Map<String, dynamic>;
  final size = json['size'] as Map<String, dynamic>;

  return PageWidget(
    id: json['id'],
    type: json['type'],
    position: Offset(
      (position['x'] as num).toDouble(),
      (position['y'] as num).toDouble(),
    ),
    size: Size(
      (size['width'] as num).toDouble(),
      (size['height'] as num).toDouble(),
    ),
    properties: Map<String, dynamic>.from(json['properties'] ?? {}),
    // ✨ NEW: Parse nesting fields
    parentId: json['parentId'],
    childrenIds: json['childrenIds'] != null 
        ? List<String>.from(json['childrenIds'])
        : null,
    isContainer: json['isContainer'],
    zIndex: json['zIndex'] ?? 0,
    positionMode: PositionModeExtension.fromString(json['positionMode']),
    createdAt: json['createdAt'],
    createdBy: json['createdBy'],
    updatedAt: json['updatedAt'],
    updatedBy: json['updatedBy'],
  );
}
```

#### E. Update `toJson` method:

**Find**:
```dart
Map<String, dynamic> toJson() {
  return {
    'id': id,
    'type': type,
    'position': {
      'x': position.dx,
      'y': position.dy,
    },
    'size': {
      'width': size.width,
      'height': size.height,
    },
    'properties': properties,
    if (createdAt != null) 'createdAt': createdAt,
    if (createdBy != null) 'createdBy': createdBy,
    if (updatedAt != null) 'updatedAt': updatedAt,
    if (updatedBy != null) 'updatedBy': updatedBy,
  };
}
```

**Replace with**:
```dart
Map<String, dynamic> toJson() {
  return {
    'id': id,
    'type': type,
    'position': {
      'x': position.dx,
      'y': position.dy,
    },
    'size': {
      'width': size.width,
      'height': size.height,
    },
    'properties': properties,
    // ✨ NEW: Include nesting fields
    'parentId': parentId,
    'childrenIds': childrenIds,
    'isContainer': isContainer,
    'zIndex': zIndex,
    'positionMode': positionMode.toJsonString(),
    if (createdAt != null) 'createdAt': createdAt,
    if (createdBy != null) 'createdBy': createdBy,
    if (updatedAt != null) 'updatedAt': updatedAt,
    if (updatedBy != null) 'updatedBy': updatedBy,
  };
}
```

#### F. Update `copyWith` method:

**Find**:
```dart
PageWidget copyWith({
  String? id,
  String? type,
  Offset? position,
  Size? size,
  Map<String, dynamic>? properties,
}) {
  return PageWidget(
    id: id ?? this.id,
    type: type ?? this.type,
    position: position ?? this.position,
    size: size ?? this.size,
    properties: properties ?? this.properties,
    createdAt: createdAt,
    createdBy: createdBy,
    updatedAt: updatedAt,
    updatedBy: updatedBy,
  );
}
```

**Replace with**:
```dart
PageWidget copyWith({
  String? id,
  String? type,
  Offset? position,
  Size? size,
  Map<String, dynamic>? properties,
  String? parentId,
  List<String>? childrenIds,
  bool? isContainer,
  int? zIndex,
  PositionMode? positionMode,
  bool clearParent = false,
}) {
  return PageWidget(
    id: id ?? this.id,
    type: type ?? this.type,
    position: position ?? this.position,
    size: size ?? this.size,
    properties: properties ?? this.properties,
    // ✨ NEW: Copy nesting fields
    parentId: clearParent ? null : (parentId ?? this.parentId),
    childrenIds: childrenIds ?? this.childrenIds,
    isContainer: isContainer ?? this.isContainer,
    zIndex: zIndex ?? this.zIndex,
    positionMode: positionMode ?? this.positionMode,
    createdAt: createdAt,
    createdBy: createdBy,
    updatedAt: updatedAt,
    updatedBy: updatedBy,
  );
}
```

**Status**: ✅ All changes documented  
**Estimated Time**: 30 minutes  

---

### 3️⃣ NEW FILE: `core/utils/widget_tree_helper.dart`

**Location**: `frontend/lib/core/utils/widget_tree_helper.dart`

**Purpose**: Helper functions for widget tree operations

**Full Code** (create this file):

```dart
import 'package:flutter/material.dart';
import '../models/page.dart';

/// Helper class for widget tree operations
class WidgetTreeHelper {
  /// Get all direct children of a widget
  static List<PageWidget> getChildren(
    String widgetId,
    List<PageWidget> allWidgets,
  ) {
    return allWidgets
        .where((w) => w.parentId == widgetId)
        .toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
  }

  /// Get the parent widget (if exists)
  static PageWidget? getParent(
    String widgetId,
    List<PageWidget> allWidgets,
  ) {
    try {
      final widget = allWidgets.firstWhere((w) => w.id == widgetId);
      if (widget.parentId == null) return null;
      return allWidgets.firstWhere((w) => w.id == widget.parentId);
    } catch (e) {
      return null;
    }
  }

  /// Get all ancestors (parent, grandparent, etc.)
  static List<PageWidget> getAncestors(
    String widgetId,
    List<PageWidget> allWidgets,
  ) {
    final ancestors = <PageWidget>[];
    PageWidget? current;
    
    try {
      current = allWidgets.firstWhere((w) => w.id == widgetId);
    } catch (e) {
      return ancestors;
    }

    while (current?.parentId != null) {
      final parent = getParent(current!.id, allWidgets);
      if (parent == null) break;
      ancestors.add(parent);
      current = parent;
    }

    return ancestors;
  }

  /// Get all descendants (children, grandchildren, etc.) recursively
  static List<PageWidget> getDescendants(
    String widgetId,
    List<PageWidget> allWidgets,
  ) {
    final children = getChildren(widgetId, allWidgets);
    final descendants = <PageWidget>[];

    for (final child in children) {
      descendants.add(child);
      descendants.addAll(getDescendants(child.id, allWidgets));
    }

    return descendants;
  }

  /// Get all root widgets (widgets without parent)
  static List<PageWidget> getRootWidgets(List<PageWidget> allWidgets) {
    return allWidgets
        .where((w) => w.parentId == null)
        .toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
  }

  /// Calculate absolute position on canvas
  static Offset calculateAbsolutePosition(
    PageWidget widget,
    List<PageWidget> allWidgets,
  ) {
    if (widget.parentId == null) {
      return widget.position;
    }

    final parent = getParent(widget.id, allWidgets);
    if (parent == null) return widget.position;

    final parentPosition = calculateAbsolutePosition(parent, allWidgets);

    return Offset(
      parentPosition.dx + widget.position.dx,
      parentPosition.dy + widget.position.dy,
    );
  }

  /// Calculate relative position to parent
  static Offset calculateRelativePosition(
    Offset absolutePosition,
    PageWidget? parent,
    List<PageWidget> allWidgets,
  ) {
    if (parent == null) return absolutePosition;

    final parentAbsolutePosition = calculateAbsolutePosition(parent, allWidgets);

    return Offset(
      absolutePosition.dx - parentAbsolutePosition.dx,
      absolutePosition.dy - parentAbsolutePosition.dy,
    );
  }

  /// Check if widget can accept children
  static bool canAcceptChildren(PageWidget widget) {
    return widget.isContainer;
  }

  /// Check if draggedWidget can be dropped into targetWidget
  static bool canDropInto(
    PageWidget draggedWidget,
    PageWidget targetWidget,
    List<PageWidget> allWidgets,
  ) {
    // Cannot drop into self
    if (draggedWidget.id == targetWidget.id) return false;

    // Target must be a container
    if (!targetWidget.isContainer) return false;

    // Cannot drop a parent into its own descendant (circular reference)
    final descendants = getDescendants(draggedWidget.id, allWidgets);
    if (descendants.any((w) => w.id == targetWidget.id)) {
      return false;
    }

    return true;
  }

  /// Get widget depth in tree (root = 0)
  static int getDepth(String widgetId, List<PageWidget> allWidgets) {
    final ancestors = getAncestors(widgetId, allWidgets);
    return ancestors.length;
  }

  /// Get widget path string (e.g., "Container > Card > Text")
  static String getWidgetPath(String widgetId, List<PageWidget> allWidgets) {
    try {
      final widget = allWidgets.firstWhere((w) => w.id == widgetId);
      final ancestors = getAncestors(widgetId, allWidgets);

      final path = [...ancestors.reversed.map((w) => w.type), widget.type];
      return path.join(' > ');
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Find widget at specific position (hit testing)
  static PageWidget? findWidgetAtPosition(
    Offset position,
    List<PageWidget> allWidgets,
  ) {
    // Check from top to bottom (reverse z-index order)
    final sortedWidgets = allWidgets.toList()
      ..sort((a, b) => b.zIndex.compareTo(a.zIndex));

    for (final widget in sortedWidgets) {
      final absolutePos = calculateAbsolutePosition(widget, allWidgets);
      final rect = Rect.fromLTWH(
        absolutePos.dx,
        absolutePos.dy,
        widget.size.width,
        widget.size.height,
      );

      if (rect.contains(position)) {
        return widget;
      }
    }

    return null;
  }

  /// Build widget tree structure
  static WidgetTreeNode buildTree(List<PageWidget> allWidgets) {
    final root = WidgetTreeNode(
      widget: null,
      children: [],
    );

    for (final widget in getRootWidgets(allWidgets)) {
      root.children.add(_buildTreeNode(widget, allWidgets));
    }

    return root;
  }

  static WidgetTreeNode _buildTreeNode(
    PageWidget widget,
    List<PageWidget> allWidgets,
  ) {
    final children = getChildren(widget.id, allWidgets);

    return WidgetTreeNode(
      widget: widget,
      children: children
          .map((child) => _buildTreeNode(child, allWidgets))
          .toList(),
    );
  }
}

/// Widget tree node for visualization
class WidgetTreeNode {
  final PageWidget? widget;
  final List<WidgetTreeNode> children;

  WidgetTreeNode({
    required this.widget,
    required this.children,
  });

  int get depth => _calculateDepth(0);

  int _calculateDepth(int currentDepth) {
    if (children.isEmpty) return currentDepth;
    return children
        .map((c) => c._calculateDepth(currentDepth + 1))
        .reduce((a, b) => a > b ? a : b);
  }
}
```

**Status**: ✅ Complete code provided  
**Estimated Time**: 15 minutes (copy-paste)  

---

### 4️⃣ MODIFY FILE: `features/page/bloc/page_event.dart`

**Location**: `frontend/lib/features/page/bloc/page_event.dart`

**Add these new events at the end of the file (before the closing)**:

```dart
// ==================== NESTED WIDGET EVENTS ====================

/// Move widget to a different parent
class MoveWidgetToParent extends PageEvent {
  final String widgetId;
  final String? newParentId;  // null = move to root
  final Offset? newPosition;   // optional new position

  const MoveWidgetToParent({
    required this.widgetId,
    this.newParentId,
    this.newPosition,
  });

  @override
  List<Object?> get props => [widgetId, newParentId, newPosition];
}

/// Remove widget and all its descendants
class RemoveWidgetWithChildren extends PageEvent {
  final String widgetId;
  final bool cascade;  // If true, also remove children

  const RemoveWidgetWithChildren(
    this.widgetId, {
    this.cascade = true,
  });

  @override
  List<Object?> get props => [widgetId, cascade];
}
```

**Status**: ✅ Complete code provided  
**Estimated Time**: 5 minutes  

---

### 5️⃣ MODIFY FILE: `features/page/bloc/page_bloc.dart`

**Location**: `frontend/lib/features/page/bloc/page_bloc.dart`

#### A. Add import at top:
```dart
import '../../../core/utils/widget_tree_helper.dart';
```

#### B. Register new event handlers in constructor:

**Find this section** (around line 50-60):
```dart
on<AddWidgetToPage>(_onAddWidgetToPage);
on<UpdateWidgetInPage>(_onUpdateWidgetInPage);
on<RemoveWidgetFromPage>(_onRemoveWidgetFromPage);
on<SelectPageWidget>(_onSelectPageWidget);
```

**Add after these lines**:
```dart
// ✨ NEW: Nested widget handlers
on<MoveWidgetToParent>(_onMoveWidgetToParent);
on<RemoveWidgetWithChildren>(_onRemoveWidgetWithChildren);
```

#### C. Add new event handler methods at the end of the class (before closing brace):

```dart
// ==================== NESTED WIDGET HANDLERS ====================

Future<void> _onMoveWidgetToParent(
  MoveWidgetToParent event,
  Emitter<PageState> emit,
) async {
  if (state.currentPage == null) return;

  final allWidgets = state.currentPage!.pageData.widgets;
  final widgetIndex = allWidgets.indexWhere((w) => w.id == event.widgetId);
  if (widgetIndex == -1) return;

  final widget = allWidgets[widgetIndex];
  final oldParentId = widget.parentId;

  // Calculate new position (relative to new parent or absolute)
  Offset newPosition = event.newPosition ?? widget.position;
  if (event.newParentId != null) {
    // Calculate relative position to new parent
    final absolutePos =
        WidgetTreeHelper.calculateAbsolutePosition(widget, allWidgets);
    final newParent = allWidgets.firstWhere((w) => w.id == event.newParentId);
    newPosition = WidgetTreeHelper.calculateRelativePosition(
      absolutePos,
      newParent,
      allWidgets,
    );
  }

  // Update widget
  final updatedWidget = widget.copyWith(
    parentId: event.newParentId,
    position: newPosition,
    positionMode: event.newParentId != null
        ? PositionMode.relative
        : PositionMode.absolute,
  );

  // Remove from old parent's children list
  List<PageWidget> updatedWidgets = [...allWidgets];
  if (oldParentId != null) {
    final oldParentIndex =
        updatedWidgets.indexWhere((w) => w.id == oldParentId);
    if (oldParentIndex != -1) {
      final oldParent = updatedWidgets[oldParentIndex];
      final updatedOldParent = oldParent.copyWith(
        childrenIds:
            oldParent.childrenIds.where((id) => id != widget.id).toList(),
      );
      updatedWidgets[oldParentIndex] = updatedOldParent;
    }
  }

  // Add to new parent's children list
  if (event.newParentId != null) {
    final newParentIndex =
        updatedWidgets.indexWhere((w) => w.id == event.newParentId);
    if (newParentIndex != -1) {
      final newParent = updatedWidgets[newParentIndex];
      final updatedNewParent = newParent.copyWith(
        childrenIds: [...newParent.childrenIds, widget.id],
      );
      updatedWidgets[newParentIndex] = updatedNewParent;
    }
  }

  // Update the moved widget
  updatedWidgets[widgetIndex] = updatedWidget;

  // Create updated page data
  final oldData = state.currentPage!.pageData;
  final currentVersion = state.currentPage!.version;

  final updatedPageData = oldData.copyWith(
    widgets: updatedWidgets,
    version: currentVersion + 1,
  );

  final updatedPage = PageModel(
    id: state.currentPage!.id,
    name: state.currentPage!.name,
    ownerId: state.currentPage!.ownerId,
    pageData: updatedPageData,
    version: currentVersion + 1,
    createdAt: state.currentPage!.createdAt,
    updatedAt: DateTime.now(),
    deletedAt: state.currentPage!.deletedAt,
  );

  emit(state.copyWith(currentPage: updatedPage, isSyncing: true));

  // Generate and send patch
  final patches = _patchService.generatePatch(oldData, updatedPageData);
  _sendPatchAndClearSync(
    state.currentPage!.id,
    patches,
    currentVersion,
  );
}

Future<void> _onRemoveWidgetWithChildren(
  RemoveWidgetWithChildren event,
  Emitter<PageState> emit,
) async {
  if (state.currentPage == null) return;

  final allWidgets = state.currentPage!.pageData.widgets;

  try {
    final widget = allWidgets.firstWhere((w) => w.id == event.widgetId);

    // Get descendants if cascade delete
    List<PageWidget> widgetsToRemove = [widget];
    if (event.cascade) {
      final descendants =
          WidgetTreeHelper.getDescendants(event.widgetId, allWidgets);
      widgetsToRemove = [widget, ...descendants];
    }

    final idsToRemove = widgetsToRemove.map((w) => w.id).toSet();

    // Remove from parent's children list
    List<PageWidget> updatedWidgets = [...allWidgets];
    if (widget.parentId != null) {
      final parentIndex =
          updatedWidgets.indexWhere((w) => w.id == widget.parentId);
      if (parentIndex != -1) {
        final parent = updatedWidgets[parentIndex];
        final updatedParent = parent.copyWith(
          childrenIds:
              parent.childrenIds.where((id) => id != widget.id).toList(),
        );
        updatedWidgets[parentIndex] = updatedParent;
      }
    }

    // Remove widget and descendants
    updatedWidgets =
        updatedWidgets.where((w) => !idsToRemove.contains(w.id)).toList();

    // Create updated page data
    final oldData = state.currentPage!.pageData;
    final currentVersion = state.currentPage!.version;

    final updatedPageData = oldData.copyWith(
      widgets: updatedWidgets,
      version: currentVersion + 1,
    );

    final updatedPage = PageModel(
      id: state.currentPage!.id,
      name: state.currentPage!.name,
      ownerId: state.currentPage!.ownerId,
      pageData: updatedPageData,
      version: currentVersion + 1,
      createdAt: state.currentPage!.createdAt,
      updatedAt: DateTime.now(),
      deletedAt: state.currentPage!.deletedAt,
    );

    emit(
      state.copyWith(
        currentPage: updatedPage,
        isSyncing: true,
        clearSelection: state.selectedWidgetId == event.widgetId,
      ),
    );

    // Generate and send patch
    final patches = _patchService.generatePatch(oldData, updatedPageData);
    _sendPatchAndClearSync(
      state.currentPage!.id,
      patches,
      currentVersion,
    );
  } catch (e) {
    print('❌ Error removing widget: $e');
  }
}
```

**Status**: ✅ Complete code provided  
**Estimated Time**: 20 minutes  

---

### 6️⃣ MODIFY FILE: `features/page/views/page_canvas_view.dart`

**Location**: `frontend/lib/features/page/views/page_canvas_view.dart`

This file needs the most changes for recursive rendering.

#### A. Add import at top:
```dart
import '../../../core/utils/widget_tree_helper.dart';
import '../../../core/models/position_mode.dart';
```

#### B. Update `_buildWidget` method to handle nesting:

**Find the `_buildWidget` method** (around line 90-130)

**Replace entire method with**:

```dart
Widget _buildWidget(
  BuildContext context,
  PageWidget widget,
  PageState state,
) {
  final isSelected = state.selectedWidgetId == widget.id;
  final canEdit = state.canEdit;
  final allWidgets = state.currentPage!.pageData.widgets;

  // Only render root widgets or widgets being rendered by their parent
  // (This prevents double rendering)
  if (widget.parentId != null) {
    return const SizedBox.shrink();
  }

  // Calculate absolute position
  final absolutePosition = WidgetTreeHelper.calculateAbsolutePosition(
    widget,
    allWidgets,
  );

  return Positioned(
    left: absolutePosition.dx,
    top: absolutePosition.dy,
    child: _buildDraggableWidget(
      context,
      widget,
      isSelected,
      canEdit,
      allWidgets,
      state,
    ),
  );
}

Widget _buildDraggableWidget(
  BuildContext context,
  PageWidget widget,
  bool isSelected,
  bool canEdit,
  List<PageWidget> allWidgets,
  PageState state,
) {
  final children = WidgetTreeHelper.getChildren(widget.id, allWidgets);

  return Draggable<PageWidget>(
    data: widget,
    feedback: Transform.scale(
      scale: 1.05,
      child: Opacity(
        opacity: 0.9,
        child: _buildWidgetContent(widget, true, false, [], allWidgets),
      ),
    ),
    childWhenDragging: Opacity(
      opacity: 0.3,
      child: _buildWidgetContent(widget, false, false, children, allWidgets),
    ),
    onDragEnd: canEdit
        ? (details) => _handleWidgetMove(context, widget, details, allWidgets)
        : null,
    child: MouseRegion(
      cursor: SystemMouseCursors.move,
      child: GestureDetector(
        onTap: () {
          print('🎯 Widget tapped: ${widget.type} - ${widget.id}');
          context.read<PageBloc>().add(SelectPageWidget(widget.id));
        },
        behavior: HitTestBehavior.opaque,
        child: _buildContainerOrWidget(
          context,
          widget,
          isSelected,
          children,
          allWidgets,
          state,
        ),
      ),
    ),
  );
}

Widget _buildContainerOrWidget(
  BuildContext context,
  PageWidget widget,
  bool isSelected,
  List<PageWidget> children,
  List<PageWidget> allWidgets,
  PageState state,
) {
  if (widget.isContainer) {
    // Container widget with drop target
    return DragTarget<PageWidget>(
      onWillAccept: (draggedWidget) {
        if (draggedWidget == null) return false;
        return WidgetTreeHelper.canDropInto(
          draggedWidget,
          widget,
          allWidgets,
        );
      },
      onAccept: (draggedWidget) {
        _handleNestedDrop(context, draggedWidget, widget);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: Colors.blue, width: 2.5)
                : isHovering
                    ? Border.all(
                        color: Colors.green,
                        width: 2,
                        style: BorderStyle.solid,
                      )
                    : null,
            borderRadius: BorderRadius.circular(
              (widget.properties['borderRadius'] as num?)?.toDouble() ?? 8.0,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Container background
              _buildWidgetContent(widget, false, isSelected, [], allWidgets),

              // Render children with relative positions
              ...children.map((child) {
                final childSelected = state.selectedWidgetId == child.id;
                final childChildren =
                    WidgetTreeHelper.getChildren(child.id, allWidgets);

                return Positioned(
                  left: child.position.dx,
                  top: child.position.dy,
                  child: _buildDraggableWidget(
                    context,
                    child,
                    childSelected,
                    state.canEdit,
                    allWidgets,
                    state,
                  ),
                );
              }),

              // Drop zone indicator
              if (isHovering)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      border: Border.all(
                        color: Colors.green,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '📦 Drop here',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  } else {
    // Regular widget (no children)
    return Container(
      decoration: BoxDecoration(
        border: isSelected ? Border.all(color: Colors.blue, width: 2.5) : null,
        borderRadius: BorderRadius.circular(
          (widget.properties['borderRadius'] as num?)?.toDouble() ?? 8.0,
        ),
      ),
      child: _buildWidgetContent(widget, false, isSelected, children, allWidgets),
    );
  }
}
```

#### C. Add new method for handling nested drops:

**Add this method after `_handleWidgetMove`**:

```dart
void _handleNestedDrop(
  BuildContext context,
  PageWidget draggedWidget,
  PageWidget targetContainer,
) {
  print('📦 Dropping ${draggedWidget.type} into ${targetContainer.type}');

  // Dispatch event to move widget to new parent
  context.read<PageBloc>().add(
    MoveWidgetToParent(
      widgetId: draggedWidget.id,
      newParentId: targetContainer.id,
      newPosition: const Offset(20, 20), // Default position inside container
    ),
  );
}
```

#### D. Update `_buildWidgetContent` signature:

**Find the method signature**:
```dart
Widget _buildWidgetContent(PageWidget widget, bool isDragging, bool isSelected) {
```

**Change to**:
```dart
Widget _buildWidgetContent(
  PageWidget widget,
  bool isDragging,
  bool isSelected,
  List<PageWidget> children,
  List<PageWidget> allWidgets,
) {
```

**Note**: The body of this method doesn't need changes, just the signature.

**Status**: ✅ Complete code provided  
**Estimated Time**: 45 minutes  

---

### 7️⃣ MODIFY FILE: `features/widget_library/views/widget_library_panel.dart`

**Location**: `frontend/lib/features/widget_library/views/widget_library_panel.dart`

#### Add container indicator badges:

**Find the `_WidgetItem` class** (at the bottom):

```dart
class _WidgetItem {
  final String name;
  final IconData icon;
  final Color color;
  final String type;

  _WidgetItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });
}
```

**Replace with**:

```dart
class _WidgetItem {
  final String name;
  final IconData icon;
  final Color color;
  final String type;
  final bool isContainer;  // ✨ NEW

  _WidgetItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isContainer = false,  // ✨ NEW
  });
}
```

**Update widget items in the build method**:

**Find**:
```dart
_buildCategory(context, 'LAYOUT', [
  _WidgetItem(
    name: 'Container',
    icon: Icons.crop_square,
    color: Colors.blue[400]!,
    type: 'Container',
  ),
  _WidgetItem(
    name: 'Card',
    icon: Icons.credit_card,
    color: Colors.purple[400]!,
    type: 'Card',
  ),
]),
```

**Replace with**:
```dart
_buildCategory(context, 'LAYOUT', [
  _WidgetItem(
    name: 'Container',
    icon: Icons.crop_square,
    color: Colors.blue[400]!,
    type: 'Container',
    isContainer: true,  // ✨ NEW
  ),
  _WidgetItem(
    name: 'Card',
    icon: Icons.credit_card,
    color: Colors.purple[400]!,
    type: 'Card',
    isContainer: true,  // ✨ NEW
  ),
]),
```

**Update `_buildWidgetCard` method to show container badge**:

**Find**:
```dart
title: Text(
  item.name,
  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
),
```

**Replace with**:
```dart
title: Row(
  children: [
    Text(
      item.name,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    if (item.isContainer) ...[  // ✨ NEW
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Text(
          'CONTAINER',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
      ),
    ],
  ],
),
```

**Status**: ✅ Complete code provided  
**Estimated Time**: 15 minutes  

---

### 8️⃣ OPTIONAL: NEW FILE - Widget Tree Panel

**Location**: `frontend/lib/features/page/views/widget_tree_panel.dart`

**Purpose**: Visual tree hierarchy panel (optional but recommended)

**Note**: This is a large file. See the full code in `VERSION_2_NESTED_WIDGETS_PLAN.md` section "Widget Tree Panel".

For now, you can skip this and add it later. It's not required for basic nested widget functionality.

**Status**: ⏭️ Optional (skip for now)  
**Estimated Time**: 2 hours (if implementing)  

---

## 📊 Frontend Changes Summary

| File | Action | Time | Status |
|------|--------|------|--------|
| `core/models/position_mode.dart` | NEW | 10 min | ✅ Ready |
| `core/models/page.dart` | MODIFY | 30 min | ✅ Ready |
| `core/utils/widget_tree_helper.dart` | NEW | 15 min | ✅ Ready |
| `features/page/bloc/page_event.dart` | MODIFY | 5 min | ✅ Ready |
| `features/page/bloc/page_bloc.dart` | MODIFY | 20 min | ✅ Ready |
| `features/page/views/page_canvas_view.dart` | MODIFY | 45 min | ✅ Ready |
| `features/widget_library/views/widget_library_panel.dart` | MODIFY | 15 min | ✅ Ready |
| `features/page/views/widget_tree_panel.dart` | NEW (Optional) | 2 hours | ⏭️ Skip |

**Total Frontend Time**: ~2.5 hours (without optional widget tree panel)

---

# PART B: NODE.JS BACKEND CHANGES

## 🔧 Backend File Structure

```
backend/
├── src-js/
│   ├── models/
│   │   └── (No changes - using JSONB)
│   ├── services/
│   │   ├── page.service.js          ← MINIMAL CHANGE (validation)
│   │   ├── ot.service.js            ← NO CHANGE (already works)
│   │   └── patch.service.js         ← NO CHANGE (already works)
│   ├── controllers/
│   │   └── page.controller.js       ← NO CHANGE
│   ├── routes/
│   │   └── page.routes.js           ← NO CHANGE
│   └── websocket/
│       ├── socket.handler.js        ← NO CHANGE
│       └── events.ts                ← NO CHANGE
└── database/
    └── migrations/
        └── (No new migrations needed)
```

---

## 📁 BACKEND CHANGES - DETAILED

### Good News! 🎉

The backend **already supports** nested widgets because:

1. ✅ **JSONB Storage**: `page_data` is stored as JSONB, which naturally handles nested structures
2. ✅ **JSON Patch**: Existing patch system works with nested JSON
3. ✅ **OT System**: Operational Transformation handles nested conflicts automatically
4. ✅ **WebSocket**: Real-time sync works without changes

---

### 1️⃣ OPTIONAL: Add Validation in `services/page.service.js`

**Location**: `backend/src-js/services/page.service.js`

**Purpose**: Validate nested widget structure (prevent circular references)

**Find the `createPage` or `updatePage` function** and add validation:

```javascript
// Add this helper function at the top of the file

/**
 * Validate widget tree structure
 * Prevents circular references and orphaned widgets
 */
function validateWidgetTree(widgets) {
  if (!Array.isArray(widgets)) {
    return { valid: false, error: 'Widgets must be an array' };
  }

  const widgetIds = new Set(widgets.map(w => w.id));

  for (const widget of widgets) {
    // Check if parentId exists
    if (widget.parentId && !widgetIds.has(widget.parentId)) {
      return {
        valid: false,
        error: `Widget ${widget.id} has non-existent parent ${widget.parentId}`,
      };
    }

    // Check if all childrenIds exist
    if (widget.childrenIds) {
      for (const childId of widget.childrenIds) {
        if (!widgetIds.has(childId)) {
          return {
            valid: false,
            error: `Widget ${widget.id} references non-existent child ${childId}`,
          };
        }
      }
    }

    // Check for circular references (widget cannot be its own ancestor)
    if (widget.parentId) {
      const visited = new Set([widget.id]);
      let currentId = widget.parentId;

      while (currentId) {
        if (visited.has(currentId)) {
          return {
            valid: false,
            error: `Circular reference detected: widget ${widget.id}`,
          };
        }
        visited.add(currentId);
        const parent = widgets.find(w => w.id === currentId);
        currentId = parent?.parentId;
      }
    }
  }

  return { valid: true };
}
```

**Then in your update function, add**:

```javascript
async function updatePage(pageId, pageData, userId) {
  // ✨ NEW: Validate widget tree
  if (pageData && pageData.widgets) {
    const validation = validateWidgetTree(pageData.widgets);
    if (!validation.valid) {
      throw new Error(`Invalid widget tree: ${validation.error}`);
    }
  }

  // ... rest of existing code
}
```

**Status**: ⚠️ Optional but recommended  
**Estimated Time**: 15 minutes  

---

### 2️⃣ Database Schema

**Good News**: The database already supports nested widgets!

#### Current Schema:
```sql
CREATE TABLE pages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  page_data JSONB NOT NULL DEFAULT '{"widgets": [], "metadata": {}}',  -- ✅ Flexible JSONB
  version INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

The `page_data` JSONB column can store nested structures without any schema changes:

```json
{
  "widgets": [
    {
      "id": "container-1",
      "parentId": null,
      "childrenIds": ["text-1", "button-1"],
      "isContainer": true,
      ...
    },
    {
      "id": "text-1",
      "parentId": "container-1",
      "childrenIds": [],
      "isContainer": false,
      ...
    }
  ]
}
```

**No migration needed!** ✅

---

### 3️⃣ JSON Patch Examples

Your existing `patch.service.js` already handles nested operations:

#### Adding a child to container:
```javascript
const patches = [
  {
    op: 'add',
    path: '/widgets/-',
    value: {
      id: 'text-2',
      parentId: 'container-1',
      type: 'Text',
      // ... other fields
    }
  },
  {
    op: 'add',
    path: '/widgets/0/childrenIds/-',
    value: 'text-2'
  }
];
```

#### Moving widget to different parent:
```javascript
const patches = [
  // Update widget's parentId
  {
    op: 'replace',
    path: '/widgets/3/parentId',
    value: 'new-parent-id'
  },
  // Remove from old parent's childrenIds
  {
    op: 'remove',
    path: '/widgets/0/childrenIds/2'
  },
  // Add to new parent's childrenIds
  {
    op: 'add',
    path: '/widgets/5/childrenIds/-',
    value: 'widget-3-id'
  }
];
```

**No code changes needed!** The existing patch service handles this. ✅

---

### 4️⃣ Operational Transformation (OT)

Your `ot.service.js` already handles nested widget conflicts:

**Example Scenario**:
- User A: Moves widget-1 to container-A
- User B: Moves widget-1 to container-B (same time)

**OT Resolution** (automatic):
1. Server receives both patches
2. OT transforms patches to avoid conflicts
3. Last operation wins (consistent state)
4. Both users see the same result

**No code changes needed!** ✅

---

### 5️⃣ WebSocket Events

Your WebSocket handlers already support nested widgets:

**Existing events that work**:
- `patch:received` - Works with nested patches
- `patch:applied` - Works with nested patches
- `conflict` - OT handles nested conflicts

**No code changes needed!** ✅

---

## 📊 Backend Changes Summary

| Component | Status | Changes Needed | Time |
|-----------|--------|----------------|------|
| Database Schema | ✅ Ready | None | 0 min |
| JSON Patch Service | ✅ Ready | None | 0 min |
| OT Service | ✅ Ready | None | 0 min |
| WebSocket | ✅ Ready | None | 0 min |
| Validation | ⚠️ Optional | Add tree validation | 15 min |

**Total Backend Time**: 15 minutes (optional validation only)

---

# PART C: INTEGRATION & TESTING

## 🧪 Testing Checklist

### Unit Tests (Frontend):

```bash
# Test widget tree helper functions
flutter test test/utils/widget_tree_helper_test.dart
```

**Tests to write**:
- ✅ `getChildren` returns correct children
- ✅ `getParent` returns correct parent
- ✅ `calculateAbsolutePosition` calculates correctly
- ✅ `canDropInto` validates correctly
- ✅ Circular reference detection

### Integration Tests:

**Test 1: Create Container and Add Child**
1. Create a Container widget
2. Create a Button widget
3. Drag Button into Container
4. Verify: Button's `parentId` = Container's `id`
5. Verify: Container's `childrenIds` includes Button's `id`
6. Verify: Button renders inside Container

**Test 2: Multi-User Nested Sync**
1. User A creates Container
2. User B sees Container appear
3. User A adds Button to Container
4. User B sees Button inside Container
5. User B moves Text into Container
6. User A sees Text appear inside Container

**Test 3: Delete Container with Children**
1. Create Container with 3 children
2. Delete Container
3. Verify: All 3 children are also deleted
4. Verify: Patch syncs to other users

**Test 4: Move Widget Between Parents**
1. Create Container A with Button
2. Create Container B (empty)
3. Drag Button from Container A to Container B
4. Verify: Button's `parentId` changed
5. Verify: Container A's `childrenIds` updated
6. Verify: Container B's `childrenIds` updated

---

## 🐛 Common Issues & Solutions

### Issue 1: Widget Renders Twice
**Cause**: Both root rendering and child rendering happening  
**Solution**: Check `if (widget.parentId != null) return SizedBox.shrink();` in `_buildWidget`

### Issue 2: Position Calculation Wrong
**Cause**: Not recursively calculating parent positions  
**Solution**: Use `WidgetTreeHelper.calculateAbsolutePosition()`

### Issue 3: Circular Reference Error
**Cause**: Widget set as parent of its own ancestor  
**Solution**: Use `WidgetTreeHelper.canDropInto()` validation

### Issue 4: Sync Not Working
**Cause**: JSON Patch not updating `childrenIds`  
**Solution**: Ensure both `parentId` and `childrenIds` are updated in same patch

---

## 📅 Implementation Timeline

### Day 1: Frontend Data Model (2.5 hours)
- ✅ Create `position_mode.dart`
- ✅ Modify `page.dart` model
- ✅ Create `widget_tree_helper.dart`
- ✅ Add new BLoC events
- ✅ Add BLoC handlers

### Day 2: Frontend UI (3 hours)
- ✅ Update `page_canvas_view.dart` for recursive rendering
- ✅ Update `widget_library_panel.dart` with container indicators
- ✅ Test drag-and-drop into containers
- ✅ Test visual feedback

### Day 3: Backend & Testing (1 hour)
- ✅ Add backend validation (optional)
- ✅ Test JSON Patch with nested structures
- ✅ Test multi-user sync
- ✅ Fix any bugs

### Day 4: Polish & Documentation (1 hour)
- ✅ Add error handling
- ✅ Update user documentation
- ✅ Create tutorial/demo

**Total**: 7.5 hours

---

## ✅ Implementation Checklist

### Frontend:
- [ ] Create `position_mode.dart`
- [ ] Modify `page.dart` (add parent/child fields)
- [ ] Create `widget_tree_helper.dart`
- [ ] Add events to `page_event.dart`
- [ ] Add handlers to `page_bloc.dart`
- [ ] Update `page_canvas_view.dart` (recursive rendering)
- [ ] Update `widget_library_panel.dart` (container badges)
- [ ] Test in browser (2 tabs)

### Backend:
- [ ] Add validation in `page.service.js` (optional)
- [ ] Test JSON Patch operations
- [ ] Test multi-user sync

### Testing:
- [ ] Create container widget
- [ ] Drag widget into container
- [ ] Verify nesting works
- [ ] Test with 2 users
- [ ] Test delete cascade
- [ ] Test move between parents

---

## 🎯 Success Criteria

✅ **Functional**:
- Containers can hold children
- Drag-and-drop into containers works
- Nested structures sync in real-time
- Delete cascades to children

✅ **Performance**:
- <100ms render time
- <200ms sync latency
- No memory leaks

✅ **UX**:
- Clear visual indicators
- Smooth drag-and-drop
- Intuitive nesting behavior

---

## 📞 Support

**Issues?**
1. Check console for error messages
2. Verify JSON structure in backend logs
3. Test with single user first, then multi-user
4. Review this guide for missed steps

**Questions?**
- Check `VERSION_2_NESTED_WIDGETS_PLAN.md` for detailed architecture
- Review `WIDGET_TREE_ANALYSIS.md` for concepts

---

## 🎉 Summary

### Frontend Changes:
- **3 new files**: `position_mode.dart`, `widget_tree_helper.dart`, (optional: `widget_tree_panel.dart`)
- **5 modified files**: `page.dart`, `page_event.dart`, `page_bloc.dart`, `page_canvas_view.dart`, `widget_library_panel.dart`
- **Time**: 2.5 hours

### Backend Changes:
- **1 optional change**: Add validation in `page.service.js`
- **Time**: 15 minutes (optional)

### Total Implementation Time:
**~3 hours** (with testing and polish)

---

*End of Implementation Guide*
