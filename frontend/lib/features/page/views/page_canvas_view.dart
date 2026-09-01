import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/page.dart';
import '../../../core/utils/widget_tree_helper.dart';
import '../bloc/page_bloc.dart';
import '../bloc/page_event.dart';
import '../bloc/page_state.dart';

class PageCanvasView extends StatefulWidget {
  final PageModel page;
  final ValueChanged<TransformationController>? onTransformationControllerReady;

  const PageCanvasView({
    super.key,
    required this.page,
    this.onTransformationControllerReady,
  });

  @override
  State<PageCanvasView> createState() => _PageCanvasViewState();
}

class _PageCanvasViewState extends State<PageCanvasView> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    // Notify parent that transformation controller is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTransformationControllerReady?.call(_transformationController);
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PageBloc, PageState>(
      builder: (context, state) {
        // Debug: Print other users' selections
        if (state.otherUsersSelections.isNotEmpty) {
          print('🔍 Other users selections: ${state.otherUsersSelections}');
        }

        // Use currentPage from state, not the prop
        final page = state.currentPage ?? widget.page;
        final metadata = page.pageData.metadata;

        // ✨ V2.1: Disable canvas drops - only allow drops into containers
        return Container(
          color: Colors.grey[100],
          child: Stack(
            children: [
              // Grid (if enabled)
              if (metadata.showGrid) _buildGrid(metadata),
              // Canvas with widgets
              InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.1,
                maxScale: 5.0,
                child: Container(
                  width: metadata.width,
                  height: metadata.height,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Render only root widgets (nested children rendered by parents)
                      ...WidgetTreeHelper.getRootWidgets(
                        page.pageData.widgets,
                      ).map((widget) {
                        // Force rebuild by including selection state in key
                        final selectionKey = state.otherUsersSelections.entries
                            .map((e) => '${e.key}:${e.value}')
                            .join(',');
                        return KeyedSubtree(
                          key: ValueKey('${widget.id}_$selectionKey'),
                          child: _buildWidget(context, widget, state),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              // Zoom controls
              Positioned(bottom: 16, right: 16, child: _buildZoomControls()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid(PageMetadata metadata) {
    return CustomPaint(
      size: Size(metadata.width, metadata.height),
      painter: GridPainter(
        gridSize: metadata.gridSize,
        color: Colors.grey.withOpacity(0.2),
      ),
    );
  }

  Widget _buildWidget(
    BuildContext context,
    PageWidget widget,
    PageState state,
  ) {
    print('🔨 Building widget: ${widget.id}');

    final isSelected = state.selectedWidgetId == widget.id;
    final canEdit = state.canEdit;
    final allWidgets = state.currentPage!.pageData.widgets;

    // Check if selected by another user
    final selectedByOthers = state.otherUsersSelections.entries
        .where((entry) => entry.value == widget.id)
        .toList();

    // Debug: Print selection info
    if (selectedByOthers.isNotEmpty) {
      print(
        '🟠 Widget ${widget.id} selected by ${selectedByOthers.length} other user(s)',
      );
      for (var entry in selectedByOthers) {
        print('   User: ${entry.key}');
      }
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
        selectedByOthers: selectedByOthers,
      ),
    );
  }

  Widget _buildDraggableWidget(
    BuildContext context,
    PageWidget widget,
    bool isSelected,
    bool canEdit,
    List<PageWidget> allWidgets,
    PageState state, {
    List<MapEntry<String, String?>> selectedByOthers = const [],
  }) {
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
            selectedByOthers: selectedByOthers,
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
    List<PageWidget> allWidgets, {
    List<MapEntry<String, String?>> selectedByOthers = const [],
  }) {
    if (widget.isContainer) {
      // Container widget with drop target - accepts both library widgets and existing widgets
      return DragTarget<Object>(
        onWillAccept: (draggedData) {
          if (draggedData == null) return false;

          // Accept Map<String, dynamic> from widget library
          if (draggedData is Map<String, dynamic>) {
            return true;
          }

          // Accept PageWidget for moving existing widgets
          if (draggedData is PageWidget) {
            return WidgetTreeHelper.canDropInto(
              draggedData,
              widget,
              allWidgets,
            );
          }

          return false;
        },
        onAccept: (draggedData) {
          if (draggedData is Map<String, dynamic>) {
            _handleLibraryDrop(context, draggedData, widget);
          } else if (draggedData is PageWidget) {
            _handleNestedDrop(context, draggedData, widget);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          final hasOtherUserSelection = selectedByOthers.isNotEmpty;

          // Debug: Print border decision
          if (hasOtherUserSelection) {
            print('🎨 Showing ORANGE border for widget ${widget.id}');
          }

          return SizedBox(
            width: widget.size.width,
            height: widget.size.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Container background with children rendered inside proper layout
                _buildWidgetContent(
                  widget,
                  false,
                  isSelected,
                  children,
                  allWidgets,
                ),

                // Selection/hover border overlay
                if (isSelected || hasOtherUserSelection || isHovering)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: isSelected
                              ? Border.all(color: Colors.blue, width: 2.5)
                              : hasOtherUserSelection
                              ? Border.all(
                                  color: Colors.orange,
                                  width: 2.5,
                                  style: BorderStyle.solid,
                                )
                              : isHovering
                              ? Border.all(
                                  color: Colors.green,
                                  width: 2,
                                  style: BorderStyle.solid,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(
                            (widget.properties['borderRadius'] as num?)
                                    ?.toDouble() ??
                                8.0,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Drop zone indicator
                if (isHovering)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.05),
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
                  ),
              ],
            ),
          );
        },
      );
    } else {
      // Regular widget (no children)
      final hasOtherUserSelection = selectedByOthers.isNotEmpty;

      return SizedBox(
        width: widget.size.width,
        height: widget.size.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Widget content
            _buildWidgetContent(
              widget,
              false,
              isSelected,
              children,
              allWidgets,
            ),

            // Selection/hover border overlay
            if (isSelected || hasOtherUserSelection)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: isSelected
                          ? Border.all(color: Colors.blue, width: 2.5)
                          : hasOtherUserSelection
                          ? Border.all(
                              color: Colors.orange,
                              width: 2.5,
                              style: BorderStyle.solid,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(
                        (widget.properties['borderRadius'] as num?)
                                ?.toDouble() ??
                            8.0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }

  void _handleLibraryDrop(
    BuildContext context,
    Map<String, dynamic> widgetData,
    PageWidget targetContainer,
  ) {
    print(
      '📦 Dropping ${widgetData['type']} from library into ${targetContainer.type}',
    );

    // ✨ V2.3: Calculate vertical position (column layout) for library drops
    final state = context.read<PageBloc>().state;
    final allWidgets = state.currentPage!.pageData.widgets;
    final existingChildren = WidgetTreeHelper.getChildren(
      targetContainer.id,
      allWidgets,
    );

    // Calculate Y position: stack vertically with 16px spacing
    double yPosition = 20.0; // Top padding
    if (existingChildren.isNotEmpty) {
      // Find the bottom-most child
      double maxBottom = 0;
      for (final child in existingChildren) {
        final childBottom = child.position.dy + child.size.height;
        if (childBottom > maxBottom) {
          maxBottom = childBottom;
        }
      }
      yPosition = maxBottom + 16.0; // 16px spacing between children
    }

    // Create new widget inside the container with calculated position
    final newWidget = PageWidget(
      id: const Uuid().v4(),
      type: widgetData['type'],
      position: Offset(20.0, yPosition), // Relative to container
      size: Size(
        (widgetData['defaultWidth'] as num?)?.toDouble() ?? 150,
        (widgetData['defaultHeight'] as num?)?.toDouble() ?? 60,
      ),
      properties: Map<String, dynamic>.from(widgetData['properties'] ?? {}),
      parentId: targetContainer.id, // Set parent
    );

    // Dispatch event to add widget to the page
    context.read<PageBloc>().add(AddWidgetToPage(newWidget));
  }

  void _handleNestedDrop(
    BuildContext context,
    PageWidget draggedWidget,
    PageWidget targetContainer,
  ) {
    print('📦 Dropping ${draggedWidget.type} into ${targetContainer.type}');

    // ✨ V2.1: Calculate vertical position (column layout)
    final state = context.read<PageBloc>().state;
    final allWidgets = state.currentPage!.pageData.widgets;
    final existingChildren = WidgetTreeHelper.getChildren(
      targetContainer.id,
      allWidgets,
    );

    // Calculate Y position: stack vertically with 16px spacing
    double yPosition = 20.0; // Top padding
    if (existingChildren.isNotEmpty) {
      // Find the bottom-most child
      double maxBottom = 0;
      for (final child in existingChildren) {
        final childBottom = child.position.dy + child.size.height;
        if (childBottom > maxBottom) {
          maxBottom = childBottom;
        }
      }
      yPosition = maxBottom + 16.0; // 16px spacing between children
    }

    // Dispatch event to move widget to new parent with calculated position
    context.read<PageBloc>().add(
      MoveWidgetToParent(
        widgetId: draggedWidget.id,
        newParentId: targetContainer.id,
        newPosition: Offset(
          20.0,
          yPosition,
        ), // Left padding: 20px, calculated Y
      ),
    );
  }

  Widget _buildWidgetContent(
    PageWidget widget,
    bool isDragging,
    bool isSelected,
    List<PageWidget> children,
    List<PageWidget> allWidgets,
  ) {
    final color = _parseColor(
      widget.properties['color'] as String? ?? '#2196F3',
    );
    final text = widget.properties['text'] as String?;
    final borderRadius =
        (widget.properties['borderRadius'] as num?)?.toDouble() ?? 8.0;
    final opacity = (widget.properties['opacity'] as num?)?.toDouble() ?? 1.0;

    // Build child widgets recursively
    List<Widget> renderedChildren = children.map((child) {
      final childState = context.read<PageBloc>().state;
      final childSelected = childState.selectedWidgetId == child.id;
      final childChildren = WidgetTreeHelper.getChildren(child.id, allWidgets);

      // Check if child is selected by another user
      final childSelectedByOthers = childState.otherUsersSelections.entries
          .where((entry) => entry.value == child.id)
          .toList();

      return _buildDraggableWidget(
        context,
        child,
        childSelected,
        childState.canEdit,
        allWidgets,
        childState,
        selectedByOthers: childSelectedByOthers,
      );
    }).toList();

    // Different styling based on widget type
    Widget content;

    if (widget.type == 'Button') {
      // Enhanced button with gradient and elevation
      return Container(
        width: widget.size.width,
        height: widget.size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: isDragging ? 16 : 8,
              offset: Offset(0, isDragging ? 8 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                text ?? 'Button',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    } else if (widget.type == 'Text') {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Text(
            text ?? 'Sample Text',
            style: TextStyle(
              color: _getContrastColor(color),
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    } else if (widget.type == 'Image') {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getContrastColor(color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.image_outlined,
                size: 48,
                color: _getContrastColor(color).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              text ?? 'Image',
              style: TextStyle(
                color: _getContrastColor(color),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (widget.type == 'Container' || widget.type == 'Card') {
      // Container and Card: Column layout (vertical stacking)
      // Get padding from properties, default to 0.0
      final paddingValue =
          (widget.properties['padding'] as num?)?.toDouble() ?? 0.0;

      if (children.isEmpty) {
        // Empty container - show placeholder
        content = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.type == 'Card' ? Icons.credit_card : Icons.crop_square,
                size: 32,
                color: _getContrastColor(color).withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                widget.type,
                style: TextStyle(
                  color: _getContrastColor(color).withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      } else {
        // Has children - auto-arrange vertically using Flutter Column with scroll
        content = Padding(
          padding: EdgeInsets.all(paddingValue),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...renderedChildren.map((child) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: child,
                  );
                }).toList(),
                // ✨ NEW: Add minimum drop zone at bottom
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }
    } else if (widget.type == 'Column') {
      // Column layout: vertical stacking
      // Get padding from properties, default to 0.0
      final paddingValue =
          (widget.properties['padding'] as num?)?.toDouble() ?? 0.0;

      if (children.isEmpty) {
        content = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.view_column,
                size: 32,
                color: _getContrastColor(color).withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'Column',
                style: TextStyle(
                  color: _getContrastColor(color).withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      } else {
        // Has children - auto-arrange vertically using Flutter Column with scroll
        content = Padding(
          padding: EdgeInsets.all(paddingValue),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...renderedChildren.map((child) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: child,
                  );
                }).toList(),
                // ✨ NEW: Add minimum drop zone at bottom
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }
    } else if (widget.type == 'Row') {
      // Row layout: horizontal arrangement
      // Get padding from properties, default to 0.0
      final paddingValue =
          (widget.properties['padding'] as num?)?.toDouble() ?? 0.0;

      if (children.isEmpty) {
        content = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.view_week,
                size: 32,
                color: _getContrastColor(color).withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'Row',
                style: TextStyle(
                  color: _getContrastColor(color).withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      } else {
        // Has children - auto-arrange horizontally using Flutter Row with scroll
        content = Padding(
          padding: EdgeInsets.all(paddingValue),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...renderedChildren.map((child) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: child,
                  );
                }).toList(),
                // ✨ NEW: Add minimum drop zone at right
                const SizedBox(width: 40),
              ],
            ),
          ),
        );
      }
    } else if (widget.type == 'Stack') {
      // Stack layout: overlapping/layered
      if (children.isEmpty) {
        content = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.layers,
                size: 32,
                color: _getContrastColor(color).withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'Stack',
                style: TextStyle(
                  color: _getContrastColor(color).withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      } else {
        // Stack allows overlapping - use z-index
        content = Stack(
          clipBehavior: Clip.none,
          children: renderedChildren.map((child) {
            final index = renderedChildren.indexOf(child);
            final childWidget = children[index];

            return Positioned(
              left: childWidget.position.dx,
              top: childWidget.position.dy,
              child: child,
            );
          }).toList(),
        );
      }
    } else {
      // Default - empty container
      content = Center(
        child: Icon(
          Icons.crop_square,
          size: 32,
          color: _getContrastColor(color).withOpacity(0.3),
        ),
      );
    }

    return Container(
      width: widget.size.width,
      height: widget.size.height,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: content,
    );
  }

  Widget _buildZoomControls() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () {
                final currentScale = _transformationController.value
                    .getMaxScaleOnAxis();
                final newScale = (currentScale * 1.2).clamp(0.1, 5.0);
                _transformationController.value = Matrix4.identity()
                  ..scale(newScale);
              },
              tooltip: 'Zoom In',
              splashRadius: 20,
            ),
            Container(width: 32, height: 1, color: Colors.grey[300]),
            IconButton(
              icon: const Icon(Icons.remove, size: 20),
              onPressed: () {
                final currentScale = _transformationController.value
                    .getMaxScaleOnAxis();
                final newScale = (currentScale / 1.2).clamp(0.1, 5.0);
                _transformationController.value = Matrix4.identity()
                  ..scale(newScale);
              },
              tooltip: 'Zoom Out',
              splashRadius: 20,
            ),
            Container(width: 32, height: 1, color: Colors.grey[300]),
            IconButton(
              icon: const Icon(Icons.center_focus_strong, size: 20),
              onPressed: () {
                _transformationController.value = Matrix4.identity();
              },
              tooltip: 'Reset Zoom',
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _handleWidgetDrop(BuildContext context, Map<String, dynamic> data) {
    // Calculate drop position (center of viewport)
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final position = Offset((size.width - 200) / 2, (size.height - 200) / 2);

    // Create new widget
    final newWidget = PageWidget(
      id: const Uuid().v4(),
      type: data['type'] as String,
      position: position,
      size: Size(
        (data['defaultWidth'] as num?)?.toDouble() ?? 200,
        (data['defaultHeight'] as num?)?.toDouble() ?? 200,
      ),
      properties: Map<String, dynamic>.from(data['properties'] ?? {}),
    );

    // Add to page
    context.read<PageBloc>().add(AddWidgetToPage(newWidget));
  }

  void _handleWidgetMove(
    BuildContext context,
    PageWidget widget,
    DraggableDetails details,
    List<PageWidget> allWidgets,
  ) {
    // Skip canvas move for child widgets - they should only be moved via container drops
    if (widget.parentId != null) {
      print(
        '⏭️ Skipping canvas move for child widget ${widget.id} - use container drop instead',
      );
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.offset);

    // Snap to grid if enabled
    final metadata = widget.properties['metadata'] as Map<String, dynamic>?;
    final snapToGrid = metadata?['snapToGrid'] as bool? ?? false;
    final gridSize = (metadata?['gridSize'] as num?)?.toDouble() ?? 10;

    Offset newPosition = localPosition;
    if (snapToGrid) {
      newPosition = Offset(
        (localPosition.dx / gridSize).round() * gridSize,
        (localPosition.dy / gridSize).round() * gridSize,
      );
    }

    // Update widget position
    final updatedWidget = widget.copyWith(position: newPosition);
    context.read<PageBloc>().add(
      UpdateWidgetInPage(widgetId: widget.id, updatedWidget: updatedWidget),
    );
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(
          int.parse(colorString.substring(1), radix: 16) + 0xFF000000,
        );
      }
      return Colors.blue;
    } catch (e) {
      return Colors.blue;
    }
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

class GridPainter extends CustomPainter {
  final double gridSize;
  final Color color;

  GridPainter({required this.gridSize, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize || oldDelegate.color != color;
  }
}
