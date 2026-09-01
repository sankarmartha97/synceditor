import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/comment.dart';

/// Comments service for API communication
/// Handles all comment CRUD operations via REST API

class CommentsService {
  final ApiClient _apiClient;

  CommentsService(this._apiClient);

  /// Create a new comment
  Future<Comment> createComment({
    required String pageId,
    required String content,
    double? positionX,
    double? positionY,
    String? widgetId,
    String? parentCommentId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/pages/$pageId/comments',
        data: {
          'content': content,
          if (positionX != null) 'positionX': positionX,
          if (positionY != null) 'positionY': positionY,
          if (widgetId != null) 'widgetId': widgetId,
          if (parentCommentId != null) 'parentCommentId': parentCommentId,
        },
      );

      return Comment.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e, 'create comment');
    }
  }

  /// Get all comments for a page
  Future<List<Comment>> getPageComments({
    required String pageId,
    bool includeResolved = true,
    String? widgetId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/pages/$pageId/comments',
        queryParameters: {
          'includeResolved': includeResolved.toString(),
          if (widgetId != null) 'widgetId': widgetId,
        },
      );

      final List<dynamic> data = response.data['data'];
      return data.map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e, 'get comments');
    }
  }

  /// Get comment thread (parent + all replies)
  Future<CommentThread> getCommentThread(String commentId) async {
    try {
      final response = await _apiClient.get('/api/comments/$commentId/thread');

      return CommentThread.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e, 'get thread');
    }
  }

  /// Update a comment
  Future<Comment> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      final response = await _apiClient.put(
        '/api/comments/$commentId',
        data: {'content': content},
      );

      return Comment.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e, 'update comment');
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      await _apiClient.delete('/api/comments/$commentId');
    } catch (e) {
      throw _handleError(e, 'delete comment');
    }
  }

  /// Resolve or unresolve a comment
  Future<Comment> resolveComment({
    required String commentId,
    required bool resolved,
  }) async {
    try {
      final response = await _apiClient.put(
        '/api/comments/$commentId/resolve',
        data: {'resolved': resolved},
      );

      return Comment.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e, 'resolve comment');
    }
  }

  /// Get user mentions
  Future<List<CommentMention>> getUserMentions({
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/users/me/mentions',
        queryParameters: {'unreadOnly': unreadOnly.toString()},
      );

      final List<dynamic> data = response.data['data'];
      return data.map((json) => CommentMention.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e, 'get mentions');
    }
  }

  /// Mark mention as read
  Future<void> markMentionAsRead(String commentId) async {
    try {
      await _apiClient.put('/api/comments/$commentId/mentions/read');
    } catch (e) {
      throw _handleError(e, 'mark mention as read');
    }
  }

  /// Get comment statistics for a page
  Future<CommentStats> getPageCommentStats(String pageId) async {
    try {
      final response = await _apiClient.get(
        '/api/pages/$pageId/comments/stats',
      );

      return CommentStats.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e, 'get stats');
    }
  }

  /// Handle API errors
  Exception _handleError(Object error, String operation) {
    if (error is ApiException) {
      return Exception('Failed to $operation: ${error.message}');
    }
    return Exception('Failed to $operation: $error');
  }
}
