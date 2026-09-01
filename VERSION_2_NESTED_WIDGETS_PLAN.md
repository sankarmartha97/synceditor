# SyncEditor Version 2.0 - Nested Widget Implementation Plan

## 📋 Document Overview

**Version**: 2.0  
**Feature**: Nested Widget Support (Widget Tree Hierarchy)  
**Status**: Planning Phase  
**Estimated Duration**: 6-10 hours development  
**Complexity**: Medium  
**Priority**: High  

---

## 🎯 Executive Summary

### Current Limitation (Version 1.0):
- All widgets stored in flat list
- No parent-child relationships
- Widgets cannot contain other widgets
- Limited to simple layouts

### Version 2.0 Goal:
Transform SyncEditor into a **professional design tool** with hierarchical widget trees, similar to Figma, Framer, or Adobe XD.

### Key Capabilities After Implementation:
1. ✅ Container widgets can hold multiple children
2. ✅ Widgets can be nested infinitely
3. ✅ Drag-and-drop widgets into containers
4. ✅ Move entire widget groups as one unit
5. ✅ Visual widget tree hierarchy panel
6. ✅ Real-time sync of nested structures
7. ✅ Professional-grade UI/UX

---

## 📊 System Architecture

### Current Architecture (V1.0):

```
PageData
└── widgets: List<PageWidget> (flat)
    ├── Widget 1 (position: absolute)
    ├── Widget 2 (position: absolute)
    ├── Widget 3 (position: absolute)
    └── Widget 4 (position: absolute)
```

**Problems**:
- No relationships between widgets
- Cannot group widgets logically
- Position always absolute to canvas
- Limited design complexity

### New Architecture (V2.0):

```
PageData
└── widgets: List<PageWidget> (tree structure)
    ├── Container (root)
    │   ├── Card (child - position relative to Container)
    │   │   ├── Text (child - position relative to Card)
    │   │   └── Button (child - position relative to Card)
    │   └── Image (child - position relative to Container)
    ├── Container (root)
    │   └── Column (child)
    │       ├── Text (child)
    │       ├── Text (child)
    │       └── Button (child)
    └── Button (root - no parent)
```

**Benefits**:
- Hierarchical organization
- Logical grouping
- Relative positioning
- Complex layouts possible
- Reusable components

---

## 🗂️ Data Model Changes

### 1. Enhanced PageWidget Model

#### Current Model (V1.0):
```dart
class PageWidget {
  final String id;
  final String type;
  final Offset position;    // Always absolute
  final Size size;
  final Map<String, dynamic> properties;
  final String? createdAt;
  final String? createdBy;
  final String? updatedAt;
  final String? updatedBy;
}
```

#### New Model (V2.0):
```dart
class PageWidget {
  final String id;
  final String type;
  final Offset position;              // Relative to parent or canvas
  final Size size;
  final Map<String, dynamic> properties;
  
  // ✨ NEW FIELDS:
  final String? parentId;             // Parent widget ID (null = root)
  final List<String> childrenIds;     // List of child widget IDs
  final bool isContainer;             // Can this widget contain children?
  final int zIndex;                   // Stacking order within parent
  final PositionMode positionMode;    // absolute | relative | fixed
  
  final String? createdAt;
  final String? createdBy;
  final String? updatedAt;
  final String? updatedBy;

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

  // Auto-detect if widget type is a container
  static bool _isContainerType(String type) {
    const containerTypes = [
      'Container',
      'Card',
      'Row',
      'Column',
      'Stack',
      'ListView',
      'GridView',
      'Wrap',
      'Flex',
    ];
    return containerTypes.contains(type);
  }

  // Copy with method (updated)
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
  }) {
    return PageWidget(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      parentId: parentId ?? this.parentId,
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

  // JSON serialization (updated)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'position': {'x': position.dx, 'y': position.dy},
      'size': {'width': size.width, 'height': size.height},
      'properties': properties,
      'parentId': parentId,
      'childrenIds': childrenIds,
      'isContainer': isContainer,
      'zIndex': zIndex,
      'positionMode': positionMode.toString().split('.').last,
      if (createdAt != null) 'createdAt': createdAt,
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (updatedBy != null) 'updatedBy': updatedBy,
    };
  }

  // JSON deserialization (updated)
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
      parentId: json['parentId'],
      childrenIds: List<String>.from(json['childrenIds'] ?? []),
      isContainer: json['isContainer'] ?? false,
      zIndex: json['zIndex'] ?? 0,
      positionMode: _parsePositionMode(json['positionMode']),
      createdAt: json['createdAt'],
      createdBy: json['createdBy'],
      updatedAt: json['updatedAt'],
      updatedBy: json['updatedBy'],
    );
  }

  static PositionMode _parsePositionMode(String? mode) {
    switch (mode) {
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

### 2. New Enums

```dart
// Position mode for widgets
enum PositionMode {
  absolute,  // Position relative to canvas
  relative,  // Position relative to parent
  fixed,     // Fixed position (doesn't move with parent)
}

// Widget category for filtering
enum WidgetCategory {
  layout,      // Container, Card, Row, Column, Stack
  basic,       // Text, Button, Image, Icon
  input,       // TextField, Checkbox, Radio, Switch
  media,       // Image, Video, Audio
  custom,      // Custom widgets
}
```

### 3. Widget Tree Helper Class

```dart
class WidgetTreeHelper {
  // Get all children of a widget
  static List<PageWidget> getChildren(
    String widgetId,
    List<PageWidget> allWidgets,
  ) {
    return allWidgets
        .where((w) => w.parentId == widgetId)
        .toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
  }

  // Get direct parent of a widget
  static PageWidget? getParent(
    String widgetId,
    List<PageWidget> allWidgets,
  ) {
    final widget = allWidgets.firstWhere((w) => w.id == widgetId);
    if (widget.parentId == null) return null;
    
    try {
      return allWidgets.firstWhere((w) => w.id == widget.parentId);
    } catch (e) {
      return null;
    }
  }

  // Get all ancestors (parent, grandparent, etc.)
  static List<PageWidget> getAncestors(
    String widgetId,
    List<PageWidget> allWidgets,
  ) {
    final ancestors = <PageWidget>[];
    PageWidget? current = allWidgets.firstWhere((w) => w.id == widgetId);

    while (current?.parentId != null) {
      final parent = getParent(current!.id, allWidgets);
      if (parent == null) break;
      ancestors.add(parent);
      current = parent;
    }

    return ancestors;
  }

  // Get all descendants (children, grandchildren, etc.) - recursive
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

  // Get root widgets (widgets without parent)
  static List<PageWidget> getRootWidgets(List<PageWidget> allWidgets) {
    return allWidgets
        .where((w) => w.parentId == null)
        .toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
  }

  // Calculate absolute position on canvas
  static Offset calculateAbsolutePosition(
    PageWidget widget,
    List<PageWidget> allWidgets,
  ) {
    if (widget.parentId == null || widget.positionMode == PositionMode.absolute) {
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

  // Calculate relative position to parent
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

  // Check if widget can accept children
  static bool canAcceptChildren(PageWidget widget) {
    return widget.isContainer;
  }

  // Check if widget can be dropped into another widget
  static bool canDropInto(
    PageWidget draggedWidget,
    PageWidget targetWidget,
  ) {
    // Cannot drop into self
    if (draggedWidget.id == targetWidget.id) return false;
    
    // Target must be a container
    if (!targetWidget.isContainer) return false;
    
    // Cannot drop a parent into its own descendant (circular reference)
    // This would be checked using getDescendants
    
    return true;
  }

  // Get widget depth in tree (root = 0)
  static int getDepth(String widgetId, List<PageWidget> allWidgets) {
    final ancestors = getAncestors(widgetId, allWidgets);
    return ancestors.length;
  }

  // Get widget path (e.g., "Container > Card > Text")
  static String getWidgetPath(String widgetId, List<PageWidget> allWidgets) {
    final widget = allWidgets.firstWhere((w) => w.id == widgetId);
    final ancestors = getAncestors(widgetId, allWidgets);
    
    final path = [...ancestors.reversed.map((w) => w.type), widget.type];
    return path.join(' > ');
  }

  // Find widget by position (hit testing)
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

  // Build widget tree structure
  static WidgetTreeNode buildTree(List<PageWidget> allWidgets) {
    final root = WidgetTreeNode(
      widget: null,
      children: [],
    );

    // Build tree recursively
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
      children: children.map((child) => _buildTreeNode(child, allWidgets)).toList(),
    );
  }
}

// Widget tree node for visualization
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
    return children.map((c) => c._calculateDepth(currentDepth + 1)).reduce((a, b) => a > b ? a : b);
  }
}
```

---

## 🎨 UI/UX Implementation

### 1. Widget Library Panel Updates

#### Add Container Indicators:
```dart
Widget _buildWidgetCard(_WidgetItem item) {
  return Card(
    child: ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(item.icon, color: item.color, size: 20),
      ),
      title: Row(
        children: [
          Text(item.name, style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          // ✨ NEW: Container badge
          if (item.isContainer)
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
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        item.isContainer 
          ? 'Can hold other widgets'
          : 'Drag to canvas or container',
        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
      ),
      trailing: item.isContainer
        ? Icon(Icons.folder, color: Colors.green.shade400, size: 20)
        : Icon(Icons.insert_drive_file_outlined, color: Colors.grey, size: 20),
    ),
  );
}
```

#### Updated Widget Items:
```dart
final widgetItems = [
  // LAYOUT (Containers)
  _WidgetItem(
    name: 'Container',
    icon: Icons.crop_square,
    color: Colors.blue[400]!,
    type: 'Container',
    isContainer: true,
    category: WidgetCategory.layout,
  ),
  _WidgetItem(
    name: 'Card',
    icon: Icons.credit_card,
    color: Colors.purple[400]!,
    type: 'Card',
    isContainer: true,
    category: WidgetCategory.layout,
  ),
  _WidgetItem(
    name: 'Row',
    icon: Icons.view_week,
    color: Colors.teal[400]!,
    type: 'Row',
    isContainer: true,
    category: WidgetCategory.layout,
  ),
  _WidgetItem(
    name: 'Column',
    icon: Icons.view_column,
    color: Colors.indigo[400]!,
    type: 'Column',
    isContainer: true,
    category: WidgetCategory.layout,
  ),
  _WidgetItem(
    name: 'Stack',
    icon: Icons.layers,
    color: Colors.cyan[400]!,
    type: 'Stack',
    isContainer: true,
    category: WidgetCategory.layout,
  ),
  
  // BASIC (Single widgets)
  _WidgetItem(
    name: 'Text',
    icon: Icons.text_fields,
    color: Colors.green[400]!,
    type: 'Text',
    isContainer: false,
    category: WidgetCategory.basic,
  ),
  _WidgetItem(
    name: 'Button',
    icon: Icons.smart_button,
    color: Colors.red[400]!,
    type: 'Button',
    isContainer: false,
    category: WidgetCategory.basic,
  ),
  _WidgetItem(
    name: 'Image',
    icon: Icons.image,
    color: Colors.orange[400]!,
    type: 'Image',
    isContainer: false,
    category: WidgetCategory.basic,
  ),
];
```

### 2. Canvas Rendering with Nesting

#### Recursive Widget Rendering:
```dart
Widget _buildWidget(
  BuildContext context,
  PageWidget widget,
  PageState state,
  List<PageWidget> allWidgets,
) {
  final isSelected = state.selectedWidgetId == widget.id;
  final canEdit = state.canEdit;
  
  // Get children if this is a container
  final children = widget.isContainer
      ? WidgetTreeHelper.getChildren(widget.id, allWidgets)
      : <PageWidget>[];

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
      children,
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
  List<PageWidget> children,
  List<PageWidget> allWidgets,
  PageState state,
) {
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
    onDragEnd: canEdit ? (details) => _handleWidgetMove(context, widget, details, allWidgets) : null,
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
        return WidgetTreeHelper.canDropInto(draggedWidget, widget);
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
                    ? Border.all(color: Colors.green, width: 2, style: BorderStyle.dashed)
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
                return Positioned(
                  left: child.position.dx,
                  top: child.position.dy,
                  child: _buildDraggableWidget(
                    context,
                    child,
                    state.selectedWidgetId == child.id,
                    state.canEdit,
                    WidgetTreeHelper.getChildren(child.id, allWidgets),
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
                      color: Colors.green.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.green,
                        width: 2,
                        style: BorderStyle.dashed,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Drop here',
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
        border: isSelected
            ? Border.all(color: Colors.blue, width: 2.5)
            : null,
        borderRadius: BorderRadius.circular(
          (widget.properties['borderRadius'] as num?)?.toDouble() ?? 8.0,
        ),
      ),
      child: _buildWidgetContent(widget, false, isSelected, children, allWidgets),
    );
  }
}
```

### 3. Widget Tree Panel (NEW Component)

```dart
class WidgetTreePanel extends StatelessWidget {
  const WidgetTreePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PageBloc, PageState>(
      builder: (context, state) {
        if (state.currentPage == null) {
          return const Center(child: Text('No page loaded'));
        }

        final widgets = state.currentPage!.pageData.widgets;
        final treeRoot = WidgetTreeHelper.buildTree(widgets);

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_tree, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Widget Tree',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Tree view
            Expanded(
              child: Container(
                color: Colors.grey[50],
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    ...treeRoot.children.map((node) => _buildTreeNode(
                      context,
                      node,
                      0,
                      state.selectedWidgetId,
                    )),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTreeNode(
    BuildContext context,
    WidgetTreeNode node,
    int depth,
    String? selectedWidgetId,
  ) {
    final widget = node.widget!;
    final isSelected = widget.id == selectedWidgetId;
    final hasChildren = node.children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            context.read<PageBloc>().add(SelectPageWidget(widget.id));
          },
          child: Container(
            margin: EdgeInsets.only(left: depth * 20.0),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade50 : null,
              borderRadius: BorderRadius.circular(4),
              border: isSelected
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                // Expand/collapse icon
                if (hasChildren)
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.grey[600],
                  )
                else
                  const SizedBox(width: 16),
                
                const SizedBox(width: 4),
                
                // Widget icon
                Icon(
                  widget.isContainer ? Icons.folder : Icons.insert_drive_file,
                  size: 18,
                  color: widget.isContainer ? Colors.blue : Colors.grey,
                ),
                
                const SizedBox(width: 8),
                
                // Widget type
                Text(
                  widget.type,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blue : Colors.black87,
                  ),
                ),
                
                const SizedBox(width: 4),
                
                // Widget ID (shortened)
                Text(
                  '(${widget.id.substring(0, 6)})',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                
                const Spacer(),
                
                // Child count badge
                if (hasChildren)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${node.children.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Render children
        ...node.children.map((child) => _buildTreeNode(
          context,
          child,
          depth + 1,
          selectedWidgetId,
        )),
      ],
    );
  }
}
```

### 4. Enhanced Properties Panel

Update properties panel to show parent information:

```dart
// In properties_panel.dart, add parent info section:

if (selectedWidget.parentId != null) ...[
  _buildSection('Parent', [
    Card(
      child: ListTile(
        leading: const Icon(Icons.folder, color: Colors.blue),
        title: Text('Parent: ${_getParentType(selectedWidget, state)}'),
        subtitle: Text('ID: ${selectedWidget.parentId!.substring(0, 8)}...'),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_upward),
          onPressed: () {
            // Select parent widget
            context.read<PageBloc>().add(
              SelectPageWidget(selectedWidget.parentId),
            );
          },
          tooltip: 'Select Parent',
        ),
      ),
    ),
  ]),
  const SizedBox(height: 16),
],

// Add position mode toggle
_buildSection('Position', [
  Card(
    child: Column(
      children: [
        ListTile(
          title: const Text('Position Mode'),
          trailing: ToggleButtons(
            isSelected: [
              selectedWidget.positionMode == PositionMode.absolute,
              selectedWidget.positionMode == PositionMode.relative,
            ],
            onPressed: (index) {
              final newMode = index == 0
                  ? PositionMode.absolute
                  : PositionMode.relative;
              _updatePositionMode(context, selectedWidget, newMode);
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Absolute'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Relative'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        _buildNumberInput(
          label: 'X',
          value: selectedWidget.position.dx,
          onChanged: (newX) {
            _updateWidgetPosition(
              context,
              selectedWidget,
              newX,
              selectedWidget.position.dy,
            );
          },
        ),
        const SizedBox(height: 12),
        _buildNumberInput(
          label: 'Y',
          value: selectedWidget.position.dy,
          onChanged: (newY) {
            _updateWidgetPosition(
              context,
              selectedWidget,
              selectedWidget.position.dx,
              newY,
            );
          },
        ),
      ],
    ),
  ),
]),
```

---

## 🔄 Backend & Sync Changes

### 1. Database Support

The PostgreSQL database already supports nested widgets via the `parent_id` field:

```sql
-- widgets table in old architecture (already has parent_id)
CREATE TABLE widgets (
  id UUID PRIMARY KEY,
  canvas_id UUID,
  type VARCHAR(50),
  parent_id UUID REFERENCES widgets(id) ON DELETE CASCADE,  -- ✅ Already exists!
  position JSONB,
  size JSONB,
  properties JSONB
);
```

For the new JSONB-based `page_data` system, the structure is already flexible:

```json
{
  "pageId": "page-1",
  "version": 5,
  "widgets": [
    {
      "id": "container-1",
      "type": "Container",
      "parentId": null,
      "childrenIds": ["text-1", "button-1"],
      "isContainer": true,
      "position": { "x": 100, "y": 100 },
      "size": { "width": 400, "height": 300 },
      "properties": { "color": "#FFFFFF" }
    },
    {
      "id": "text-1",
      "type": "Text",
      "parentId": "container-1",
      "childrenIds": [],
      "isContainer": false,
      "position": { "x": 20, "y": 20 },
      "size": { "width": 200, "height": 50 },
      "properties": { "text": "Hello" }
    },
    {
      "id": "button-1",
      "type": "Button",
      "parentId": "container-1",
      "childrenIds": [],
      "isContainer": false,
      "position": { "x": 20, "y": 90 },
      "size": { "width": 140, "height": 50 },
      "properties": { "text": "Click" }
    }
  ]
}
```

### 2. JSON Patch Operations

The existing JSON Patch system works perfectly with nested structures:

#### Adding a child to a container:
```json
[
  {
    "op": "add",
    "path": "/widgets/-",
    "value": {
      "id": "text-2",
      "parentId": "container-1",
      "type": "Text",
      ...
    }
  },
  {
    "op": "add",
    "path": "/widgets/0/childrenIds/-",
    "value": "text-2"
  }
]
```

#### Moving a widget to a different parent:
```json
[
  {
    "op": "replace",
    "path": "/widgets/3/parentId",
    "value": "new-parent-id"
  },
  {
    "op": "remove",
    "path": "/widgets/0/childrenIds/2"
  },
  {
    "op": "add",
    "path": "/widgets/5/childrenIds/-",
    "value": "widget-3-id"
  }
]
```

#### Deleting a container with children (cascade):
```json
[
  {
    "op": "remove",
    "path": "/widgets/2"
  },
  {
    "op": "remove",
    "path": "/widgets/5"
  },
  {
    "op": "remove",
    "path": "/widgets/8"
  }
]
```

### 3. Operational Transformation (OT)

The existing OT system will handle nested widget conflicts automatically:

**Example Conflict**:
- User A: Moves widget-1 into container-A
- User B: Moves widget-1 into container-B (same time)

**OT Resolution**:
1. Server receives both patches
2. OT transforms one patch based on the other
3. Both operations are applied in order
4. Result: Last operation wins (consistent across all users)

**No changes needed** - OT already handles this!

---

## 📦 BLoC Event Updates

### New Events for Nested Widgets:

```dart
// In page_event.dart, add:

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

/// Add widget as child of parent
class AddWidgetToParent extends PageEvent {
  final PageWidget widget;
  final String? parentId;

  const AddWidgetToParent({
    required this.widget,
    this.parentId,
  });

  @override
  List<Object?> get props => [widget, parentId];
}

/// Remove widget and all descendants
class RemoveWidgetWithChildren extends PageEvent {
  final String widgetId;

  const RemoveWidgetWithChildren(this.widgetId);

  @override
  List<Object?> get props => [widgetId];
}

/// Update widget parent relationship
class UpdateWidgetParent extends PageEvent {
  final String widgetId;
  final String? newParentId;

  const UpdateWidgetParent({
    required this.widgetId,
    this.newParentId,
  });

  @override
  List<Object?> get props => [widgetId, newParentId];
}
```

### Event Handlers in PageBloc:

```dart
// In page_bloc.dart, add:

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
    final absolutePos = WidgetTreeHelper.calculateAbsolutePosition(widget, allWidgets);
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
    positionMode: event.newParentId != null ? PositionMode.relative : PositionMode.absolute,
  );

  // Remove from old parent's children list
  List<PageWidget> updatedWidgets = [...allWidgets];
  if (oldParentId != null) {
    final oldParentIndex = updatedWidgets.indexWhere((w) => w.id == oldParentId);
    if (oldParentIndex != -1) {
      final oldParent = updatedWidgets[oldParentIndex];
      final updatedOldParent = oldParent.copyWith(
        childrenIds: oldParent.childrenIds.where((id) => id != widget.id).toList(),
      );
      updatedWidgets[oldParentIndex] = updatedOldParent;
    }
  }

  // Add to new parent's children list
  if (event.newParentId != null) {
    final newParentIndex = updatedWidgets.indexWhere((w) => w.id == event.newParentId);
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
  
  // Get widget and all its descendants
  final widget = allWidgets.firstWhere((w) => w.id == event.widgetId);
  final descendants = WidgetTreeHelper.getDescendants(event.widgetId, allWidgets);
  final widgetsToRemove = [widget, ...descendants];
  final idsToRemove = widgetsToRemove.map((w) => w.id).toSet();

  // Remove from parent's children list
  List<PageWidget> updatedWidgets = [...allWidgets];
  if (widget.parentId != null) {
    final parentIndex = updatedWidgets.indexWhere((w) => w.id == widget.parentId);
    if (parentIndex != -1) {
      final parent = updatedWidgets[parentIndex];
      final updatedParent = parent.copyWith(
        childrenIds: parent.childrenIds.where((id) => id != widget.id).toList(),
      );
      updatedWidgets[parentIndex] = updatedParent;
    }
  }

  // Remove widget and all descendants
  updatedWidgets = updatedWidgets.where((w) => !idsToRemove.contains(w.id)).toList();

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
}
```

---

## 🧪 Testing Strategy

### Unit Tests:

```dart
// widget_tree_helper_test.dart

void main() {
  group('WidgetTreeHelper', () {
    late List<PageWidget> testWidgets;

    setUp(() {
      testWidgets = [
        PageWidget(
          id: 'container-1',
          type: 'Container',
          position: Offset(100, 100),
          size: Size(400, 300),
          properties: {},
          parentId: null,
          childrenIds: ['text-1', 'button-1'],
          isContainer: true,
        ),
        PageWidget(
          id: 'text-1',
          type: 'Text',
          position: Offset(20, 20),
          size: Size(200, 50),
          properties: {},
          parentId: 'container-1',
          childrenIds: [],
          isContainer: false,
        ),
        PageWidget(
          id: 'button-1',
          type: 'Button',
          position: Offset(20, 90),
          size: Size(140, 50),
          properties: {},
          parentId: 'container-1',
          childrenIds: [],
          isContainer: false,
        ),
      ];
    });

    test('getChildren returns correct children', () {
      final children = WidgetTreeHelper.getChildren('container-1', testWidgets);
      expect(children.length, 2);
      expect(children.map((w) => w.id), containsAll(['text-1', 'button-1']));
    });

    test('getParent returns correct parent', () {
      final parent = WidgetTreeHelper.getParent('text-1', testWidgets);
      expect(parent?.id, 'container-1');
    });

    test('calculateAbsolutePosition works correctly', () {
      final text = testWidgets.firstWhere((w) => w.id == 'text-1');
      final absolutePos = WidgetTreeHelper.calculateAbsolutePosition(text, testWidgets);
      expect(absolutePos.dx, 120); // 100 + 20
      expect(absolutePos.dy, 120); // 100 + 20
    });

    test('getRootWidgets returns only root level widgets', () {
      final roots = WidgetTreeHelper.getRootWidgets(testWidgets);
      expect(roots.length, 1);
      expect(roots.first.id, 'container-1');
    });

    test('canDropInto rejects invalid drops', () {
      final container = testWidgets.firstWhere((w) => w.id == 'container-1');
      final text = testWidgets.firstWhere((w) => w.id == 'text-1');
      
      expect(WidgetTreeHelper.canDropInto(text, container), true);
      expect(WidgetTreeHelper.canDropInto(container, text), false); // text is not a container
      expect(WidgetTreeHelper.canDropInto(container, container), false); // cannot drop into self
    });

    test('getDepth calculates correct depth', () {
      expect(WidgetTreeHelper.getDepth('container-1', testWidgets), 0);
      expect(WidgetTreeHelper.getDepth('text-1', testWidgets), 1);
    });
  });
}
```

### Integration Tests:

1. **Test Nested Widget Rendering**
   - Create container, add children
   - Verify children render inside container
   - Verify positions are calculated correctly

2. **Test Drag and Drop**
   - Drag widget onto container
   - Verify parent-child relationship created
   - Verify position recalculated

3. **Test Multi-User Sync**
   - User A creates container
   - User B adds child to container
   - Verify both see same structure

4. **Test Delete Cascade**
   - Delete container with children
   - Verify all children deleted
   - Verify parent-child links cleaned up

---

## 📅 Implementation Timeline

### Phase 1: Data Model & Helpers (2-3 hours)
- ✅ Update `PageWidget` model
- ✅ Add new enums (`PositionMode`, `WidgetCategory`)
- ✅ Create `WidgetTreeHelper` class
- ✅ Update JSON serialization/deserialization
- ✅ Write unit tests

### Phase 2: UI Updates (3-4 hours)
- ✅ Update widget library with container indicators
- ✅ Add drop target for containers
- ✅ Implement recursive widget rendering
- ✅ Add visual feedback (drop zones, hover effects)
- ✅ Create widget tree panel
- ✅ Update properties panel

### Phase 3: BLoC & Events (2-3 hours)
- ✅ Add new events for nested operations
- ✅ Implement event handlers
- ✅ Update existing handlers for nesting
- ✅ Test with JSON Patch generation

### Phase 4: Testing & Polish (2-3 hours)
- ✅ Integration testing
- ✅ Multi-user testing
- ✅ Bug fixes
- ✅ Performance optimization
- ✅ Documentation updates

**Total Estimated Time**: 9-13 hours

---

## 🚀 Migration Strategy

### Option A: Fresh Start (Recommended for V2.0)
- New pages use nested structure
- Old pages remain as-is
- Add "Upgrade to V2" button for old pages
- Conversion: flatten nested widgets → add parentId fields

### Option B: Auto-Migration
- On first load, convert flat widgets to nested
- All root-level widgets get `parentId: null`
- All widgets get `childrenIds: []`
- Add `isContainer` field based on type

### Migration Script:
```dart
Future<void> migrateToV2(PageData oldPageData) async {
  final migratedWidgets = oldPageData.widgets.map((widget) {
    return PageWidget(
      id: widget.id,
      type: widget.type,
      position: widget.position,
      size: widget.size,
      properties: widget.properties,
      parentId: null,                              // All root level
      childrenIds: [],                             // No children initially
      isContainer: PageWidget._isContainerType(widget.type),
      zIndex: 0,
      positionMode: PositionMode.absolute,
      createdAt: widget.createdAt,
      createdBy: widget.createdBy,
      updatedAt: widget.updatedAt,
      updatedBy: widget.updatedBy,
    );
  }).toList();

  return PageData(
    pageId: oldPageData.pageId,
    name: oldPageData.name,
    version: oldPageData.version + 1,
    metadata: oldPageData.metadata,
    widgets: migratedWidgets,
  );
}
```

---

## 📊 Success Metrics

### Functional Requirements:
- ✅ Containers can hold multiple children
- ✅ Widgets can be dragged into containers
- ✅ Nested structures sync in real-time
- ✅ Delete cascades to children
- ✅ Move widget between parents
- ✅ Widget tree visualizes hierarchy

### Performance Requirements:
- ✅ <100ms render time for 50 widgets
- ✅ <200ms sync time for nested operations
- ✅ No memory leaks with deep nesting
- ✅ Smooth drag-and-drop experience

### User Experience:
- ✅ Clear visual indicators for containers
- ✅ Intuitive drop zones
- ✅ Obvious parent-child relationships
- ✅ Easy to navigate widget tree
- ✅ No accidental circular references

---

## 🎓 Learning Resources

### Concepts to Understand:
1. **Tree Data Structures**: Recursive traversal, depth calculation
2. **Relative vs Absolute Positioning**: CSS concepts
3. **Drag and Drop APIs**: Flutter Draggable/DragTarget
4. **Recursive Rendering**: Building widgets from tree
5. **JSON Patch Operations**: Nested JSON updates

### Similar Implementations:
- **Figma**: Hierarchical layers panel
- **Framer**: Component tree
- **Adobe XD**: Layers panel
- **Webflow**: Navigator panel

---

## 🎯 Version 2.0 Summary

### Current State (V1.0):
```
❌ Flat widget list
❌ No nesting
❌ Simple layouts only
❌ Limited organization
```

### After V2.0:
```
✅ Hierarchical widget tree
✅ Infinite nesting
✅ Complex layouts
✅ Professional organization
✅ Container widgets
✅ Relative positioning
✅ Widget tree panel
✅ Real-time nested sync
```

### Impact:
- **Users**: Can build complex UIs like professional design tools
- **Developers**: Clean hierarchical data model
- **Product**: Competitive with Figma/Framer/Adobe XD

---

## 📝 Next Steps

1. **Review this plan** - Ensure all requirements are covered
2. **Approve implementation** - Confirm go-ahead for V2.0
3. **Start Phase 1** - Begin with data model updates
4. **Iterative development** - Build, test, refine each phase
5. **Documentation** - Update user guides and API docs
6. **Release V2.0** - Deploy with migration strategy

---

## ✅ Sign-Off

**Document Version**: 1.0  
**Created**: 2026-08-31  
**Status**: Ready for Implementation  
**Approval Required**: Yes  

**Questions or Concerns?** Review this plan and provide feedback before implementation begins.

---

*End of Version 2.0 Implementation Plan*
