/// Comment thread widget with threaded replies
/// Displays parent comment and all replies with actions

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/comment.dart';

/// Comment thread widget - displays parent and replies
class CommentThreadWidget extends StatelessWidget {
  final CommentThread thread;
  final String? currentUserId;
  final VoidCallback? onReply;
  final VoidCallback? onResolve;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CommentThreadWidget({
    super.key,
    required this.thread,
    this.currentUserId,
    this.onReply,
    this.onResolve,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: thread.isResolved ? 0 : 1,
      color: thread.isResolved
          ? Colors.grey.shade50
          : Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parent comment
          CommentCard(
            comment: thread.parent,
            currentUserId: currentUserId,
            isParent: true,
            onReply: onReply,
            onResolve: onResolve,
            onEdit: onEdit,
            onDelete: onDelete,
          ),

          // Replies
          if (thread.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 48, right: 8, bottom: 8),
              child: Column(
                children: thread.replies
                    .map((reply) => CommentCard(
                          comment: reply,
                          currentUserId: currentUserId,
                          isReply: true,
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Individual comment card
class CommentCard extends StatefulWidget {
  final Comment comment;
  final String? currentUserId;
  final bool isParent;
  final bool isReply;
  final VoidCallback? onReply;
  final VoidCallback? onResolve;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CommentCard({
    super.key,
    required this.comment,
    this.currentUserId,
    this.isParent = false,
    this.isReply = false,
    this.onReply,
    this.onResolve,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  bool _showActions = false;

  bool get _isOwner => widget.comment.userId == widget.currentUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = _formatTimeAgo(widget.comment.createdAt);

    return MouseRegion(
      onEnter: (_) => setState(() => _showActions = true),
      onExit: (_) => setState(() => _showActions = false),
      child: Padding(
        padding: EdgeInsets.only(
          top: widget.isReply ? 8 : 12,
          bottom: widget.isReply ? 0 : 4,
          left: 12,
          right: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User avatar
            _buildAvatar(),
            const SizedBox(width: 12),

            // Comment content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Username + time + badges
                  Row(
                    children: [
                      Text(
                        widget.comment.userName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (widget.comment.edited) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(edited)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (_showActions && !widget.comment.resolved)
                        _buildActionButtons(context),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Comment content with mentions
                  RichText(
                    text: TextSpan(
                      children: widget.comment.renderContentWithMentions(
                        defaultStyle: theme.textTheme.bodyMedium,
                        mentionStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Metadata row
                  if (widget.isParent) ...[
                    const SizedBox(height: 8),
                    _buildMetadataRow(context),
                  ],

                  // Resolved badge
                  if (widget.comment.resolved && widget.isParent) ...[
                    const SizedBox(height: 8),
                    _buildResolvedBadge(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (widget.comment.userAvatar != null) {
      return CircleAvatar(
        radius: widget.isReply ? 14 : 16,
        backgroundImage: NetworkImage(widget.comment.userAvatar!),
      );
    }

    // Fallback to initials
    final initials = widget.comment.userName
        .split(' ')
        .take(2)
        .map((n) => n.isNotEmpty ? n[0].toUpperCase() : '')
        .join();

    return CircleAvatar(
      radius: widget.isReply ? 14 : 16,
      backgroundColor: _getAvatarColor(widget.comment.userId),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: widget.isReply ? 10 : 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isParent && widget.onReply != null)
          _IconButton(
            icon: Icons.reply,
            tooltip: 'Reply',
            onPressed: widget.onReply,
          ),
        if (_isOwner && widget.onEdit != null)
          _IconButton(
            icon: Icons.edit,
            tooltip: 'Edit',
            onPressed: widget.onEdit,
          ),
        if (_isOwner && widget.onDelete != null)
          _IconButton(
            icon: Icons.delete_outline,
            tooltip: 'Delete',
            onPressed: widget.onDelete,
          ),
        if (widget.isParent && widget.onResolve != null)
          _IconButton(
            icon: widget.comment.resolved
                ? Icons.check_circle
                : Icons.check_circle_outline,
            tooltip: widget.comment.resolved ? 'Reopen' : 'Resolve',
            onPressed: widget.onResolve,
            color: widget.comment.resolved ? Colors.green : null,
          ),
      ],
    );
  }

  Widget _buildMetadataRow(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: [
        if (widget.comment.replyCount > 0)
          _MetadataChip(
            icon: Icons.comment_outlined,
            label: '${widget.comment.replyCount} ${widget.comment.replyCount == 1 ? 'reply' : 'replies'}',
          ),
        if (widget.comment.isAnnotation)
          _MetadataChip(
            icon: Icons.place_outlined,
            label: 'Canvas annotation',
          ),
        if (widget.comment.widgetId != null)
          _MetadataChip(
            icon: Icons.widgets_outlined,
            label: 'Widget comment',
          ),
      ],
    );
  }

  Widget _buildResolvedBadge(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedText = widget.comment.resolvedByName != null
        ? 'Resolved by ${widget.comment.resolvedByName}'
        : 'Resolved';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            resolvedText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Small icon button for actions
class _IconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18),
        iconSize: 18,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        color: color ?? Colors.grey.shade600,
        onPressed: onPressed,
        splashRadius: 16,
      ),
    );
  }
}

/// Metadata chip
class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetadataChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }
}

/// Comment input widget for creating/editing comments
class CommentInput extends StatefulWidget {
  final String? initialContent;
  final String hintText;
  final VoidCallback? onCancel;
  final Function(String content)? onSubmit;
  final bool isReply;

  const CommentInput({
    super.key,
    this.initialContent,
    this.hintText = 'Add a comment...',
    this.onCancel,
    this.onSubmit,
    this.isReply = false,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final content = _controller.text.trim();
    if (content.isNotEmpty) {
      widget.onSubmit?.call(content);
      _controller.clear();
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = _controller.text.trim().isEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isReply ? Colors.grey.shade50 : null,
        border: Border.all(
          color: _isFocused ? theme.primaryColor : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: _isFocused ? 4 : 1,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: theme.textTheme.bodyMedium,
            onSubmitted: (_) => _submit(),
          ),
          if (_isFocused) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onCancel != null)
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isEmpty ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(widget.isReply ? 'Reply' : 'Comment'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
