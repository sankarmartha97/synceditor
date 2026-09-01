/// Comments panel sidebar
/// Collapsible panel showing all comments with filters, search, and composition

import 'package:flutter/material.dart';
import '../../../core/models/comment.dart';
import 'comment_thread.dart';

/// Filter options for comments
enum CommentFilter {
  all,
  unresolved,
  resolved,
  mentions,
}

/// Comments panel sidebar
class CommentsPanel extends StatefulWidget {
  final List<CommentThread> threads;
  final CommentStats? stats;
  final String? currentUserId;
  final CommentFilter filter;
  final bool isVisible;
  final Function(CommentFilter)? onFilterChanged;
  final Function(String)? onCreateComment;
  final Function(Comment, String)? onReplyComment;
  final Function(Comment)? onResolveComment;
  final Function(Comment, String)? onEditComment;
  final Function(Comment)? onDeleteComment;
  final VoidCallback? onClose;

  const CommentsPanel({
    super.key,
    required this.threads,
    this.stats,
    this.currentUserId,
    this.filter = CommentFilter.all,
    this.isVisible = true,
    this.onFilterChanged,
    this.onCreateComment,
    this.onReplyComment,
    this.onResolveComment,
    this.onEditComment,
    this.onDeleteComment,
    this.onClose,
  });

  @override
  State<CommentsPanel> createState() => _CommentsPanelState();
}

class _CommentsPanelState extends State<CommentsPanel> {
  final TextEditingController _searchController = TextEditingController();
  String? _expandedThreadId;
  String? _replyingToId;

  List<CommentThread> get _filteredThreads {
    var threads = widget.threads;

    // Apply filter
    switch (widget.filter) {
      case CommentFilter.unresolved:
        threads = threads.where((t) => !t.isResolved).toList();
        break;
      case CommentFilter.resolved:
        threads = threads.where((t) => t.isResolved).toList();
        break;
      case CommentFilter.mentions:
        threads = threads.where((t) {
          return t.allComments.any((c) => c.hasMentions);
        }).toList();
        break;
      case CommentFilter.all:
      default:
        break;
    }

    // Apply search
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      threads = threads.where((t) {
        return t.allComments.any((c) =>
            c.content.toLowerCase().contains(searchQuery) ||
            c.userName.toLowerCase().contains(searchQuery));
      }).toList();
    }

    return threads;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final filteredThreads = _filteredThreads;

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context),

          // Stats bar
          if (widget.stats != null) _buildStatsBar(context),

          // Filter tabs
          _buildFilterTabs(context),

          // Search bar
          _buildSearchBar(context),

          // Comments list
          Expanded(
            child: filteredThreads.isEmpty
                ? _buildEmptyState(context)
                : _buildCommentsList(context, filteredThreads),
          ),

          // New comment input
          _buildNewCommentInput(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline, color: theme.primaryColor),
          const SizedBox(width: 12),
          Text(
            'Comments',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onClose,
            tooltip: 'Close comments panel',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context) {
    final stats = widget.stats!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.chat_bubble_outline,
            label: stats.totalComments.toString(),
            sublabel: 'total',
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          _StatChip(
            icon: Icons.warning_amber,
            label: stats.unresolvedComments.toString(),
            sublabel: 'unresolved',
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          _StatChip(
            icon: Icons.check_circle_outline,
            label: stats.resolvedComments.toString(),
            sublabel: 'resolved',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          _FilterTab(
            label: 'All',
            isSelected: widget.filter == CommentFilter.all,
            onTap: () => widget.onFilterChanged?.call(CommentFilter.all),
          ),
          _FilterTab(
            label: 'Unresolved',
            isSelected: widget.filter == CommentFilter.unresolved,
            onTap: () => widget.onFilterChanged?.call(CommentFilter.unresolved),
          ),
          _FilterTab(
            label: 'Resolved',
            isSelected: widget.filter == CommentFilter.resolved,
            onTap: () => widget.onFilterChanged?.call(CommentFilter.resolved),
          ),
          _FilterTab(
            label: 'Mentions',
            isSelected: widget.filter == CommentFilter.mentions,
            onTap: () => widget.onFilterChanged?.call(CommentFilter.mentions),
            icon: Icons.alternate_email,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search comments...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          isDense: true,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildCommentsList(
    BuildContext context,
    List<CommentThread> threads,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: threads.length,
      itemBuilder: (context, index) {
        final thread = threads[index];
        final isExpanded = _expandedThreadId == thread.parent.id;
        final isReplying = _replyingToId == thread.parent.id;

        return Column(
          children: [
            CommentThreadWidget(
              thread: thread,
              currentUserId: widget.currentUserId,
              onReply: () {
                setState(() {
                  _replyingToId =
                      _replyingToId == thread.parent.id ? null : thread.parent.id;
                });
              },
              onResolve: () {
                widget.onResolveComment?.call(thread.parent);
              },
              onEdit: () {
                // TODO: Show edit dialog
              },
              onDelete: () {
                _showDeleteConfirmation(context, thread.parent);
              },
            ),

            // Reply input
            if (isReplying)
              Padding(
                padding: const EdgeInsets.only(left: 48, right: 8, bottom: 12),
                child: CommentInput(
                  hintText: 'Write a reply...',
                  isReply: true,
                  onCancel: () {
                    setState(() => _replyingToId = null);
                  },
                  onSubmit: (content) {
                    widget.onReplyComment?.call(thread.parent, content);
                    setState(() => _replyingToId = null);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    String message;
    IconData icon;

    switch (widget.filter) {
      case CommentFilter.unresolved:
        message = 'No unresolved comments';
        icon = Icons.check_circle_outline;
        break;
      case CommentFilter.resolved:
        message = 'No resolved comments yet';
        icon = Icons.chat_bubble_outline;
        break;
      case CommentFilter.mentions:
        message = 'No mentions found';
        icon = Icons.alternate_email;
        break;
      default:
        message = 'No comments yet';
        icon = Icons.chat_bubble_outline;
    }

    if (_searchController.text.isNotEmpty) {
      message = 'No comments match your search';
      icon = Icons.search_off;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.filter == CommentFilter.all &&
              _searchController.text.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Be the first to comment!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNewCommentInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: CommentInput(
        hintText: 'Add a comment...',
        onSubmit: (content) {
          widget.onCreateComment?.call(content);
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Comment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text(
          'Are you sure you want to delete this comment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onDeleteComment?.call(comment);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Filter tab button
class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? theme.primaryColor : Colors.grey.shade400,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stat chip
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
