import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/canvas_bloc.dart';
import '../bloc/canvas_event.dart';
import '../bloc/canvas_state.dart';
import '../models/canvas_widget.dart';
import '../../../core/api/websocket_client.dart';

class CanvasView extends StatelessWidget {
  const CanvasView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasBloc, CanvasState>(
      builder: (context, state) {
        return Focus(
          autofocus: true,
          onKey: (node, event) {
            // Handle Delete key
            if (event.logicalKey.keyLabel == 'Delete' &&
                event is KeyDownEvent &&
                state.selectedWidgetId != null) {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Delete Widget?'),
                    ],
                  ),
                  content: const Text(
                    'Are you sure you want to delete this widget? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.read<CanvasBloc>().add(
                          DeleteWidget(state.selectedWidgetId!),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              return KeyEventResult.handled;
            }

            // Handle Ctrl+Z (Undo) - Only for canvas, not page editor
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.keyZ &&
                HardwareKeyboard.instance.isControlPressed &&
                !HardwareKeyboard.instance.isShiftPressed) {
              // Check if we have undo history before triggering
              if (state.undoHistory.isNotEmpty) {
                context.read<CanvasBloc>().add(const UndoAction());
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored; // Let page editor handle it
            }

            // Handle Ctrl+Y (Redo) - Only for canvas, not page editor
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.keyY &&
                HardwareKeyboard.instance.isControlPressed) {
              // Check if we have redo history before triggering
              if (state.redoHistory.isNotEmpty) {
                context.read<CanvasBloc>().add(const RedoAction());
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored; // Let page editor handle it
            }

            return KeyEventResult.ignored;
          },
          child: _buildCanvas(context, state),
        );
      },
    );
  }

  Widget _buildCanvas(BuildContext context, CanvasState state) {
    return MouseRegion(
      onHover: (event) {
        // Emit cursor position to other users (throttled by WebSocket client)
        if (state.currentCanvasId != null) {
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final localPosition = renderBox.globalToLocal(event.position);
            // Emit directly to WebSocket (throttled internally)
            WebSocketClient.instance.emitCursorMoved(
              state.currentCanvasId!,
              localPosition.dx,
              localPosition.dy,
            );
          }
        }
      },
      child: DragTarget<Map<String, dynamic>>(
        onWillAccept: (data) => data != null,
        onAccept: (data) {
          final type = data['type'] as String;
          final position = data['position'] as Offset;

          final widget = CanvasWidget(
            type: type,
            position: position,
            size: const Size(150, 100),
            backgroundColor: _getDefaultColor(type),
            text: type == 'Text' ? 'Sample Text' : null,
          );

          context.read<CanvasBloc>().add(AddWidgetToCanvas(widget));
        },
        builder: (context, candidateData, rejectedData) {
          return GestureDetector(
            onTap: () {
              // Deselect when tapping empty canvas
              context.read<CanvasBloc>().add(const SelectWidget(null));
            },
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: state.canvasBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Grid background
                  CustomPaint(size: Size.infinite, painter: GridPainter()),

                  // Widgets
                  ...(state.widgets.toList()
                        ..sort((a, b) => a.zIndex.compareTo(b.zIndex)))
                      .map((widget) {
                        final isSelected = widget.id == state.selectedWidgetId;
                        return _DraggableWidget(
                          widget: widget,
                          isSelected: isSelected,
                        );
                      }),

                  // Drop indicator
                  if (candidateData.isNotEmpty)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 2),
                          color: Colors.blue.withOpacity(0.1),
                        ),
                      ),
                    ),

                  // Remote cursors
                  ...state.remoteCursors.values.map((cursor) {
                    return Positioned(
                      left: cursor.position.dx,
                      top: cursor.position.dy,
                      child: _buildRemoteCursor(cursor),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Build remote cursor widget
  Widget _buildRemoteCursor(RemoteCursor cursor) {
    return Transform.translate(
      offset: const Offset(-2, -2), // Center the cursor icon
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.navigation,
            color: cursor.color,
            size: 20,
            shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cursor.color,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 2),
              ],
            ),
            child: Text(
              cursor.userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDefaultColor(String type) {
    switch (type) {
      case 'Container':
        return Colors.blue[100]!;
      case 'Card':
        return Colors.purple[100]!;
      case 'Text':
        return Colors.transparent;
      case 'Button':
        return Colors.red[400]!;
      case 'Image':
        return Colors.orange[200]!;
      default:
        return Colors.grey[300]!;
    }
  }
}

class _DraggableWidget extends StatefulWidget {
  final CanvasWidget widget;
  final bool isSelected;

  const _DraggableWidget({required this.widget, required this.isSelected});

  @override
  State<_DraggableWidget> createState() => _DraggableWidgetState();
}

class _DraggableWidgetState extends State<_DraggableWidget> {
  Offset? dragOffset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.widget.position.dx,
      top: widget.widget.position.dy,
      child: GestureDetector(
        onPanStart: (details) {
          dragOffset = details.localPosition;
          context.read<CanvasBloc>().add(SelectWidget(widget.widget.id));
        },
        onPanUpdate: (details) {
          if (dragOffset != null) {
            final newPosition = Offset(
              widget.widget.position.dx + details.delta.dx,
              widget.widget.position.dy + details.delta.dy,
            );
            context.read<CanvasBloc>().add(
              UpdateWidgetPosition(widget.widget.id, newPosition),
            );
          }
        },
        onPanEnd: (details) {
          dragOffset = null;
        },
        onTap: () {
          context.read<CanvasBloc>().add(SelectWidget(widget.widget.id));
        },
        child: Transform.rotate(
          angle:
              widget.widget.rotation *
              3.14159 /
              180, // Convert degrees to radians
          child: Container(
            width: widget.widget.size.width,
            height: widget.widget.size.height,
            decoration: BoxDecoration(
              color: widget.widget.backgroundColor.withOpacity(
                widget.widget.opacity,
              ),
              borderRadius: BorderRadius.circular(widget.widget.borderRadius),
              border: Border.all(
                color: widget.isSelected ? Colors.blue : Colors.grey[400]!,
                width: widget.isSelected ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Widget content
                Center(child: _buildWidgetContent()),

                // Selection handles
                if (widget.isSelected) ...[
                  // Top-left
                  Positioned(left: -4, top: -4, child: _buildHandle()),
                  // Top-right
                  Positioned(right: -4, top: -4, child: _buildHandle()),
                  // Bottom-left
                  Positioned(left: -4, bottom: -4, child: _buildHandle()),
                  // Bottom-right (resize handle)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        final newSize = Size(
                          (widget.widget.size.width + details.delta.dx).clamp(
                            50.0,
                            500.0,
                          ),
                          (widget.widget.size.height + details.delta.dy).clamp(
                            50.0,
                            500.0,
                          ),
                        );
                        context.read<CanvasBloc>().add(
                          UpdateWidgetSize(widget.widget.id, newSize),
                        );
                      },
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.open_in_full,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ), // Close Container
        ), // Close Transform.rotate
      ),
    );
  }

  Widget _buildWidgetContent() {
    switch (widget.widget.type) {
      case 'Text':
        return Text(
          widget.widget.text ?? 'Text',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        );
      case 'Button':
        return ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.widget.backgroundColor,
          ),
          child: const Text('Button'),
        );
      case 'Image':
        return Icon(Icons.image, size: 48, color: Colors.grey[600]);
      case 'Card':
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.credit_card, color: Colors.grey[600]),
              const SizedBox(height: 4),
              Text('Card', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        );
      default:
        return Icon(Icons.crop_square, size: 48, color: Colors.grey[600]);
    }
  }

  Widget _buildHandle() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!.withOpacity(0.3)
      ..strokeWidth = 1;

    const gridSize = 20.0;

    // Draw vertical lines
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
