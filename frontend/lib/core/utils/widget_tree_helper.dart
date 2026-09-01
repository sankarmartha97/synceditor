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
