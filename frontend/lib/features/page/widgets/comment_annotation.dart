/// Comment annotation widget for canvas
/// Visual pin/marker that shows comment location on canvas

import 'package:flutter/material.dart';
import '../../../core/models/comment.dart';

/// Annotation pin on canvas
class CommentAnnotation extends StatefulWidget {
  final Comment comment;
  final VoidCallback? onTap;
  final VoidCallback? onDrag;
  final bool isSelected;
  final bool isDraggable;

  const CommentAnnotation({
    super.key,
    required this.comment,
    this.onTap,
    this.onDrag,
    this.isSelected = false,
    this.isDraggable = false,
  });

  @override
  State<CommentAnnotation> createState() => _CommentAnnotationState();
}

class _CommentAnnotationState extends State<CommentAnnotation>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.comment.position;
    if (position == null) return const SizedBox.shrink();

    return Positioned(
      left: position.dx - 16, // Center the pin
      top: position.dy - 32, // Position above the point
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: AnimatedScale(
            scale: _isHovered || widget.isSelected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pin indicator
                _buildPin(context),

                // Thread preview on hover
                if (_isHovered || widget.isSelected)
                  _buildPreviewTooltip(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPin(BuildContext context) {
    final isResolved = widget.comment.resolved;
    final hasReplies = widget.comment.replyCount > 0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse effect for unresolved comments
        if (!isResolved && !widget.isSelected)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 32 * _pulseAnimation.value,
                height: 32 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.1),
                ),
              );
            },
          ),

        // Main pin
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isResolved ? Colors.green.shade400 : Colors.blue.shade500,
            border: Border.all(
              color: widget.isSelected ? Colors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isResolved ? Icons.check : Icons.chat_bubble,
            color: Colors.white,
            size: 16,
          ),
        ),

        // Reply count badge
        if (hasReplies)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Center(
                child: Text(
                  widget.comment.replyCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        // Pointer/tail
        Positioned(
          bottom: -8,
          child: CustomPaint(
            size: const Size(12, 8),
            painter: _PinTailPainter(
              color: isResolved ? Colors.green.shade400 : Colors.blue.shade500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewTooltip(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // User info
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: _getAvatarColor(widget.comment.userId),
                    child: Text(
                      _getInitials(widget.comment.userName),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.comment.userName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.comment.replyCount > 0)
                          Text(
                            '${widget.comment.replyCount} ${widget.comment.replyCount == 1 ? 'reply' : 'replies'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.comment.resolved)
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                ],
              ),
              const SizedBox(height: 8),

              // Comment preview
              Text(
                widget.comment.content,
                style: theme.textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Action hint
              Text(
                'Click to view thread',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String userId) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[userId.hashCode.abs() % colors.length];
  }

  String _getInitials(String name) {
    return name
        .split(' ')
        .take(2)
        .map((n) => n.isNotEmpty ? n[0].toUpperCase() : '')
        .join();
  }
}

/// Custom painter for pin tail/pointer
class _PinTailPainter extends CustomPainter {
  final Color color;

  _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height) // Bottom point
      ..lineTo(0, 0) // Top left
      ..lineTo(size.width, 0) // Top right
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Annotation overlay - renders all annotations on canvas
class CommentAnnotationsOverlay extends StatelessWidget {
  final List<Comment> annotations;
  final String? selectedCommentId;
  final Function(Comment)? onAnnotationTap;

  const CommentAnnotationsOverlay({
    super.key,
    required this.annotations,
    this.selectedCommentId,
    this.onAnnotationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: annotations
          .where((c) => c.isAnnotation) // Only show comments with positions
          .map((annotation) {
        return CommentAnnotation(
          key: ValueKey(annotation.id),
          comment: annotation,
          isSelected: annotation.id == selectedCommentId,
          onTap: () => onAnnotationTap?.call(annotation),
        );
      }).toList(),
    );
  }
}

/// Create annotation mode indicator
class CreateAnnotationIndicator extends StatelessWidget {
  final Offset? position;

  const CreateAnnotationIndicator({
    super.key,
    this.position,
  });

  @override
  Widget build(BuildContext context) {
    if (position == null) return const SizedBox.shrink();

    return Positioned(
      left: position!.dx - 20,
      top: position!.dy - 20,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.shade500.withOpacity(0.3),
          border: Border.all(
            color: Colors.blue.shade500,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.add_comment,
          color: Colors.blue.shade700,
          size: 20,
        ),
      ),
    );
  }
}

/// Floating action button for creating annotations
class AddAnnotationButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onPressed;

  const AddAnnotationButton({
    super.key,
    this.isActive = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: isActive ? Colors.blue.shade700 : Colors.blue.shade500,
      tooltip: isActive ? 'Click canvas to add comment' : 'Add comment',
      child: Icon(
        isActive ? Icons.close : Icons.add_comment,
        color: Colors.white,
      ),
    );
  }
}

/// Comment count badge for page header
class CommentCountBadge extends StatelessWidget {
  final int count;
  final int unresolvedCount;
  final VoidCallback? onTap;

  const CommentCountBadge({
    super.key,
    required this.count,
    this.unresolvedCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: unresolvedCount > 0
              ? Colors.blue.shade50
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unresolvedCount > 0
                ? Colors.blue.shade200
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 16,
              color: unresolvedCount > 0
                  ? Colors.blue.shade700
                  : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: unresolvedCount > 0
                    ? Colors.blue.shade700
                    : Colors.grey.shade700,
              ),
            ),
            if (unresolvedCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade500,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unresolvedCount.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
