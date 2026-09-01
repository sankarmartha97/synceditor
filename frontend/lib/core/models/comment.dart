/// Comment model for annotations and discussions
/// Supports threading, mentions, and canvas annotations

import 'package:flutter/material.dart';

/// Comment model
class Comment {
  final String id;
  final String pageId;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userAvatar;
  
  final String content;
  
  // Canvas annotation position (optional)
  final double? positionX;
  final double? positionY;
  
  // Widget reference (optional)
  final String? widgetId;
  
  // Threading
  final String? parentCommentId;
  final int replyCount;
  
  // Status
  final bool resolved;
  final String? resolvedBy;
  final String? resolvedByName;
  final DateTime? resolvedAt;
  
  // Metadata
  final bool edited;
  final DateTime? editedAt;
  final int mentionCount;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.pageId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userAvatar,
    required this.content,
    this.positionX,
    this.positionY,
    this.widgetId,
    this.parentCommentId,
    this.replyCount = 0,
    this.resolved = false,
    this.resolvedBy,
    this.resolvedByName,
    this.resolvedAt,
    this.edited = false,
    this.editedAt,
    this.mentionCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if this is a canvas annotation (has position)
  bool get isAnnotation => positionX != null && positionY != null;

  /// Check if this is a widget comment
  bool get isWidgetComment => widgetId != null;

  /// Check if this is a root comment (not a reply)
  bool get isRootComment => parentCommentId == null;

  /// Check if this is a reply
  bool get isReply => parentCommentId != null;

  /// Check if comment has mentions
  bool get hasMentions => mentionCount > 0;

  /// Get position as Offset
  Offset? get position {
    if (positionX != null && positionY != null) {
      return Offset(positionX!, positionY!);
    }
    return null;
  }

  /// Extract mentions from content
  List<String> extractMentions() {
    final mentionRegex = RegExp(r'@(\w+(?:\.\w+)*@?\w*\.?\w*)');
    final matches = mentionRegex.allMatches(content);
    return matches.map((m) => m.group(1)!).toSet().toList();
  }

  /// Render content with styled mentions
  List<InlineSpan> renderContentWithMentions({
    TextStyle? defaultStyle,
    TextStyle? mentionStyle,
  }) {
    final spans = <InlineSpan>[];
    final mentionRegex = RegExp(r'(@\w+(?:\.\w+)*@?\w*\.?\w*)');
    final matches = mentionRegex.allMatches(content);

    int lastIndex = 0;
    for (final match in matches) {
      // Add text before mention
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: content.substring(lastIndex, match.start),
          style: defaultStyle,
        ));
      }

      // Add mention with style
      spans.add(TextSpan(
        text: match.group(0),
        style: mentionStyle ??
            defaultStyle?.copyWith(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
      ));

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastIndex),
        style: defaultStyle,
      ));
    }

    return spans;
  }

  /// Create from JSON
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      pageId: json['page_id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? 'Unknown',
      userEmail: json['user_email'] ?? '',
      userAvatar: json['user_avatar'],
      content: json['content'],
      positionX: json['position_x']?.toDouble(),
      positionY: json['position_y']?.toDouble(),
      widgetId: json['widget_id'],
      parentCommentId: json['parent_comment_id'],
      replyCount: json['reply_count'] ?? 0,
      resolved: json['resolved'] ?? false,
      resolvedBy: json['resolved_by'],
      resolvedByName: json['resolved_by_name'],
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      edited: json['edited'] ?? false,
      editedAt:
          json['edited_at'] != null ? DateTime.parse(json['edited_at']) : null,
      mentionCount: json['mention_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'page_id': pageId,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'user_avatar': userAvatar,
      'content': content,
      'position_x': positionX,
      'position_y': positionY,
      'widget_id': widgetId,
      'parent_comment_id': parentCommentId,
      'reply_count': replyCount,
      'resolved': resolved,
      'resolved_by': resolvedBy,
      'resolved_by_name': resolvedByName,
      'resolved_at': resolvedAt?.toIso8601String(),
      'edited': edited,
      'edited_at': editedAt?.toIso8601String(),
      'mention_count': mentionCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Comment copyWith({
    String? id,
    String? pageId,
    String? userId,
    String? userName,
    String? userEmail,
    String? userAvatar,
    String? content,
    double? positionX,
    double? positionY,
    String? widgetId,
    String? parentCommentId,
    int? replyCount,
    bool? resolved,
    String? resolvedBy,
    String? resolvedByName,
    DateTime? resolvedAt,
    bool? edited,
    DateTime? editedAt,
    int? mentionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      widgetId: widgetId ?? this.widgetId,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replyCount: replyCount ?? this.replyCount,
      resolved: resolved ?? this.resolved,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedByName: resolvedByName ?? this.resolvedByName,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      edited: edited ?? this.edited,
      editedAt: editedAt ?? this.editedAt,
      mentionCount: mentionCount ?? this.mentionCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Comment(id: $id, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}..., userName: $userName, resolved: $resolved)';
  }
}

/// Comment thread with parent and replies
class CommentThread {
  final Comment parent;
  final List<Comment> replies;

  CommentThread({
    required this.parent,
    required this.replies,
  });

  /// Total comments in thread (parent + replies)
  int get totalCount => 1 + replies.length;

  /// Check if thread is resolved
  bool get isResolved => parent.resolved;

  /// Get all comments (parent + replies) sorted by creation time
  List<Comment> get allComments => [parent, ...replies];

  /// Create from JSON
  factory CommentThread.fromJson(Map<String, dynamic> json) {
    return CommentThread(
      parent: Comment.fromJson(json),
      replies: (json['replies'] as List?)
              ?.map((r) => Comment.fromJson(r))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      ...parent.toJson(),
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }
}

/// Comment statistics for a page
class CommentStats {
  final int totalComments;
  final int unresolvedComments;
  final int resolvedComments;
  final int uniqueCommenters;
  final int totalReplies;

  CommentStats({
    required this.totalComments,
    required this.unresolvedComments,
    required this.resolvedComments,
    required this.uniqueCommenters,
    required this.totalReplies,
  });

  /// Create from JSON
  factory CommentStats.fromJson(Map<String, dynamic> json) {
    return CommentStats(
      totalComments: int.parse(json['total_comments'].toString()),
      unresolvedComments: int.parse(json['unresolved_comments'].toString()),
      resolvedComments: int.parse(json['resolved_comments'].toString()),
      uniqueCommenters: int.parse(json['unique_commenters'].toString()),
      totalReplies: int.parse(json['total_replies'].toString()),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'total_comments': totalComments,
      'unresolved_comments': unresolvedComments,
      'resolved_comments': resolvedComments,
      'unique_commenters': uniqueCommenters,
      'total_replies': totalReplies,
    };
  }
}

/// Mention notification
class CommentMention {
  final Comment comment;
  final String mentionedBy;
  final String mentionedByName;
  final bool read;
  final DateTime? readAt;
  final DateTime createdAt;

  CommentMention({
    required this.comment,
    required this.mentionedBy,
    required this.mentionedByName,
    this.read = false,
    this.readAt,
    required this.createdAt,
  });

  /// Create from JSON
  factory CommentMention.fromJson(Map<String, dynamic> json) {
    return CommentMention(
      comment: Comment.fromJson(json),
      mentionedBy: json['user_id'],
      mentionedByName: json['user_name'],
      read: json['mention_read'] ?? false,
      readAt: json['mention_read_at'] != null
          ? DateTime.parse(json['mention_read_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
