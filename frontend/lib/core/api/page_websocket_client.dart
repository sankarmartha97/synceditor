import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'endpoints.dart';
import 'api_client.dart';
import '../models/page.dart';
import '../models/comment.dart';

/// WebSocket client for real-time page synchronization
class PageWebSocketClient {
  static PageWebSocketClient? _instance;
  IO.Socket? _socket;

  // Stream controllers for different event types
  final _connectionStateController =
      StreamController<PageConnectionState>.broadcast();
  final _pageJoinedController = StreamController<PageJoinedEvent>.broadcast();
  final _pageUserJoinedController = StreamController<PageUserEvent>.broadcast();
  final _pageUserLeftController = StreamController<PageUserEvent>.broadcast();
  final _pagePatchAppliedController =
      StreamController<PagePatchAppliedEvent>.broadcast();
  final _pagePatchReceivedController =
      StreamController<PagePatchReceivedEvent>.broadcast();
  final _pageConflictController =
      StreamController<PageConflictEvent>.broadcast();
  final _pageCursorController = StreamController<PageCursorEvent>.broadcast();
  final _pageSelectionController =
      StreamController<PageSelectionEvent>.broadcast();
  final _commentCreatedController = StreamController<CommentEvent>.broadcast();
  final _commentUpdatedController = StreamController<CommentEvent>.broadcast();
  final _commentDeletedController =
      StreamController<CommentDeletedEvent>.broadcast();
  final _commentResolvedController = StreamController<CommentEvent>.broadcast();
  final _commentMentionController =
      StreamController<CommentMentionEvent>.broadcast();

  // Undo/Redo stream controllers
  final _undoAppliedController =
      StreamController<PageUndoAppliedEvent>.broadcast();
  final _redoAppliedController =
      StreamController<PageRedoAppliedEvent>.broadcast();
  final _undoRedoStateController =
      StreamController<PageUndoRedoStateEvent>.broadcast();
  final _undoErrorController = StreamController<String>.broadcast();
  final _redoErrorController = StreamController<String>.broadcast();

  // Follow feature stream controllers
  final _followStartedController =
      StreamController<PageFollowStartedEvent>.broadcast();
  final _followStoppedController =
      StreamController<PageFollowStoppedEvent>.broadcast();
  final _viewportUpdatedController =
      StreamController<PageViewportUpdatedEvent>.broadcast();
  final _followErrorController = StreamController<String>.broadcast();

  // Public streams
  Stream<PageConnectionState> get connectionState =>
      _connectionStateController.stream;
  Stream<PageJoinedEvent> get pageJoinedEvents => _pageJoinedController.stream;
  Stream<PageUserEvent> get userJoinedEvents =>
      _pageUserJoinedController.stream;
  Stream<PageUserEvent> get userLeftEvents => _pageUserLeftController.stream;
  Stream<PagePatchAppliedEvent> get patchAppliedEvents =>
      _pagePatchAppliedController.stream;
  Stream<PagePatchReceivedEvent> get patchReceivedEvents =>
      _pagePatchReceivedController.stream;
  Stream<PageConflictEvent> get conflictEvents =>
      _pageConflictController.stream;
  Stream<PageCursorEvent> get cursorEvents => _pageCursorController.stream;
  Stream<PageSelectionEvent> get selectionEvents =>
      _pageSelectionController.stream;
  Stream<CommentEvent> get commentCreatedEvents =>
      _commentCreatedController.stream;
  Stream<CommentEvent> get commentUpdatedEvents =>
      _commentUpdatedController.stream;
  Stream<CommentDeletedEvent> get commentDeletedEvents =>
      _commentDeletedController.stream;
  Stream<CommentEvent> get commentResolvedEvents =>
      _commentResolvedController.stream;
  Stream<CommentMentionEvent> get commentMentionEvents =>
      _commentMentionController.stream;

  // Undo/Redo streams
  Stream<PageUndoAppliedEvent> get undoAppliedEvents =>
      _undoAppliedController.stream;
  Stream<PageRedoAppliedEvent> get redoAppliedEvents =>
      _redoAppliedController.stream;
  Stream<PageUndoRedoStateEvent> get undoRedoStateEvents =>
      _undoRedoStateController.stream;
  Stream<String> get undoErrorEvents => _undoErrorController.stream;
  Stream<String> get redoErrorEvents => _redoErrorController.stream;

  // Follow feature streams
  Stream<PageFollowStartedEvent> get followStartedEvents =>
      _followStartedController.stream;
  Stream<PageFollowStoppedEvent> get followStoppedEvents =>
      _followStoppedController.stream;
  Stream<PageViewportUpdatedEvent> get viewportUpdatedEvents =>
      _viewportUpdatedController.stream;
  Stream<String> get followErrorEvents => _followErrorController.stream;

  bool get isConnected => _socket?.connected ?? false;
  String? _currentPageId;
  String? get currentPageId => _currentPageId;

  PageWebSocketClient._internal();

  static PageWebSocketClient get instance {
    _instance ??= PageWebSocketClient._internal();
    return _instance!;
  }

  /// Connect to WebSocket server
  void connect() {
    if (_socket?.connected == true) {
      print('🔌 Page WebSocket already connected');
      return;
    }

    final token = ApiClient.instance.authToken;
    if (token == null) {
      print('⚠️ Cannot connect: No auth token');
      return;
    }

    print('🔌 Connecting to Page WebSocket: ${ApiEndpoints.wsUrl}');

    _socket = IO.io(
      ApiEndpoints.wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect() // Changed: manually control connection
          .enableReconnection()
          .setReconnectionDelay(2000) // Increased from 1000
          .setReconnectionDelayMax(10000) // Increased from 5000
          .setReconnectionAttempts(3) // Reduced from 5
          .setAuth({'token': token})
          .build(),
    );

    _setupEventListeners();
    _socket!.connect(); // Manually connect after setup
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    // ==================== CONNECTION EVENTS ====================

    _socket!.onConnect((_) {
      print('✅ Page WebSocket connected');
      _connectionStateController.add(PageConnectionState.connected);

      // Rejoin page if we were in one
      if (_currentPageId != null) {
        joinPage(_currentPageId!);
      }
    });

    _socket!.onDisconnect((_) {
      print('❌ Page WebSocket disconnected');
      _connectionStateController.add(PageConnectionState.disconnected);
    });

    _socket!.on('connect_error', (error) {
      print('❌ Page WebSocket connection error: $error');
      _connectionStateController.add(PageConnectionState.error);
    });

    // ==================== PAGE EVENTS ====================

    _socket!.on('page:joined', (data) {
      print('📄 Joined page: ${data['pageId']}');
      // Don't update _currentPageId here - it's already set in joinPage()

      _pageJoinedController.add(
        PageJoinedEvent(
          pageId: data['pageId'],
          pageName: data['pageName'],
          pageData: PageData.fromJson(data['pageData']),
          version: data['version'],
          permission: _parsePermission(data['permission']),
          activeUsers:
              (data['activeUsers'] as List?)
                  ?.map((u) => ActiveUser.fromJson(u))
                  .toList() ??
              [],
        ),
      );
    });

    _socket!.on('page:user:joined', (data) {
      print('👤 User joined page: ${data['user']['name']}');
      _pageUserJoinedController.add(
        PageUserEvent(
          user: ActiveUser.fromJson(data['user']),
          timestamp: DateTime.parse(data['timestamp']),
        ),
      );
    });

    _socket!.on('page:user:left', (data) {
      print('👤 User left page: ${data['userId']}');
      _pageUserLeftController.add(
        PageUserEvent.left(
          userId: data['userId'],
          timestamp: DateTime.parse(data['timestamp']),
        ),
      );
    });

    _socket!.on('page:patch:applied', (data) {
      print('✅ Patch applied: version ${data['version']}');
      _pagePatchAppliedController.add(
        PagePatchAppliedEvent(
          pageId: data['pageId'],
          patches: List<Map<String, dynamic>>.from(data['patches']),
          version: data['version'],
          timestamp: DateTime.parse(data['timestamp']),
        ),
      );
    });

    _socket!.on('page:patch:received', (data) {
      print('🔄 Patch received from user ${data['userId']}');
      _pagePatchReceivedController.add(
        PagePatchReceivedEvent(
          pageId: data['pageId'],
          userId: data['userId'],
          patches: List<Map<String, dynamic>>.from(data['patches']),
          version: data['version'],
          timestamp: DateTime.parse(data['timestamp']),
        ),
      );
    });

    _socket!.on('page:conflict', (data) {
      print(
        '⚠️ Version conflict: client=${data['clientVersion']}, server=${data['serverVersion']}',
      );
      _pageConflictController.add(
        PageConflictEvent(
          clientVersion: data['clientVersion'],
          serverVersion: data['serverVersion'],
          message: data['message'],
        ),
      );
    });

    _socket!.on('page:cursor:updated', (data) {
      _pageCursorController.add(
        PageCursorEvent(
          userId: data['userId'],
          userName: data['userName'],
          userColor: data['userColor'],
          position: Offset(
            (data['position']['x'] as num).toDouble(),
            (data['position']['y'] as num).toDouble(),
          ),
          timestamp: DateTime.parse(data['timestamp']),
        ),
      );
    });

    _socket!.on('page:selection:updated', (data) {
      _pageSelectionController.add(
        PageSelectionEvent(
          userId: data['userId'],
          userName: data['userName'],
          widgetId: data['widgetId'],
          timestamp: DateTime.parse(data['timestamp']),
        ),
      );
    });

    _socket!.on('page:patch:error', (data) {
      print('❌ Patch error: ${data['message']}');
    });

    _socket!.on('connection:error', (data) {
      print('❌ Connection error: ${data['message']}');
    });

    // ==================== COMMENT EVENTS ====================

    _socket!.on('comment:created', (data) {
      print('💬 Comment created: ${data['comment']['id']}');
      _commentCreatedController.add(CommentEvent.fromJson(data));
    });

    _socket!.on('comment:updated', (data) {
      print('✏️ Comment updated: ${data['comment']['id']}');
      _commentUpdatedController.add(CommentEvent.fromJson(data));
    });

    _socket!.on('comment:deleted', (data) {
      print('🗑️ Comment deleted: ${data['commentId']}');
      _commentDeletedController.add(CommentDeletedEvent.fromJson(data));
    });

    _socket!.on('comment:resolved', (data) {
      print(
        '${data['resolved'] ? '✅' : '🔓'} Comment ${data['resolved'] ? 'resolved' : 'reopened'}: ${data['comment']['id']}',
      );
      _commentResolvedController.add(CommentEvent.fromJson(data));
    });

    _socket!.on('comment:mention', (data) {
      print('🔔 You were mentioned in a comment: ${data['comment']['id']}');
      _commentMentionController.add(CommentMentionEvent.fromJson(data));
    });

    // ==================== UNDO/REDO EVENTS ====================

    _socket!.on('page:undo:applied', (data) {
      print('↩️ Undo applied: version ${data['version']}');
      _undoAppliedController.add(
        PageUndoAppliedEvent(
          pageId: data['pageId'],
          patches: List<Map<String, dynamic>>.from(data['patches']),
          version: data['version'],
          operationDescription: data['operationDescription'],
          canUndo: data['canUndo'] ?? false,
          canRedo: data['canRedo'] ?? false,
          timestamp: DateTime.parse(data['timestamp']),
        ),
      );
    });

    _socket!.on('page:redo:applied', (data) {
      print('↪️ Redo applied: version ${data['version']}');
      _redoAppliedController.add(
        PageRedoAppliedEvent(
          pageId: data['pageId'],
          patches: List<Map<String, dynamic>>.from(data['patches']),
          version: data['version'],
          operationDescription: data['operationDescription'],
          canUndo: data['canUndo'] ?? false,
          canRedo: data['canRedo'] ?? false,
          timestamp: DateTime.parse(data['timestamp']),
        ),
      );
    });

    _socket!.on('page:undo:state', (data) {
      print(
        '🔄 Undo/Redo state: canUndo=${data['canUndo']}, canRedo=${data['canRedo']}',
      );
      _undoRedoStateController.add(
        PageUndoRedoStateEvent(
          canUndo: data['canUndo'] ?? false,
          canRedo: data['canRedo'] ?? false,
        ),
      );
    });

    _socket!.on('page:undo:error', (data) {
      print('❌ Undo error: ${data['message']}');
      _undoErrorController.add(data['message'] ?? 'Undo failed');
    });

    _socket!.on('page:redo:error', (data) {
      print('❌ Redo error: ${data['message']}');
      _redoErrorController.add(data['message'] ?? 'Redo failed');
    });

    // ==================== FOLLOW FEATURE EVENTS ====================

    _socket!.on('page:follow:started', (data) {
      print('👁️ Follow started: ${data['targetUserName']}');
      _followStartedController.add(
        PageFollowStartedEvent(
          pageId: data['pageId'],
          targetUserId: data['targetUserId'],
          targetUserName: data['targetUserName'],
          initialViewport: data['initialViewport'],
          timestamp: DateTime.parse(data['timestamp']),
        ),
      );
    });

    _socket!.on('page:follow:stopped', (data) {
      print('👁️‍🗨️ Follow stopped');
      _followStoppedController.add(
        PageFollowStoppedEvent(
          pageId: data['pageId'],
          timestamp: DateTime.parse(data['timestamp']),
        ),
      );
    });

    _socket!.on('page:viewport:updated', (data) {
      _viewportUpdatedController.add(
        PageViewportUpdatedEvent(
          userId: data['userId'],
          userName: data['userName'],
          viewport: data['viewport'],
          timestamp: DateTime.parse(data['timestamp']),
        ),
      );
    });

    _socket!.on('page:follow:error', (data) {
      print('❌ Follow error: ${data['message']}');
      _followErrorController.add(data['message'] ?? 'Follow failed');
    });
  }

  // ==================== PUBLIC METHODS ====================

  /// Join a page for editing
  void joinPage(String pageId) {
    if (_socket?.connected != true) {
      print('⚠️ Cannot join page: Socket not connected');
      return;
    }

    // Prevent rejoining the same page
    if (_currentPageId == pageId) {
      print('⚠️ Already in page: $pageId');
      return;
    }

    print('📄 Joining page: $pageId');
    _currentPageId = pageId;
    _socket!.emit('page:join', {'pageId': pageId});
  }

  /// Leave current page
  void leavePage() {
    if (_currentPageId == null) return;

    print('📤 Leaving page: $_currentPageId');
    _socket!.emit('page:leave', {'pageId': _currentPageId});
    _currentPageId = null;
  }

  /// Send JSON Patch update
  void sendPatch({
    required String pageId,
    required List<Map<String, dynamic>> patches,
    required int clientVersion,
  }) {
    if (_socket?.connected != true) {
      print('⚠️ Cannot send patch: Socket not connected');
      return;
    }

    print('🔄 Sending patch: ${patches.length} operations');
    _socket!.emit('page:patch', {
      'pageId': pageId,
      'patches': patches,
      'clientVersion': clientVersion,
    });
  }

  /// Send cursor position
  void sendCursorPosition({required String pageId, required Offset position}) {
    if (_socket?.connected != true) return;

    _socket!.emit('page:cursor', {
      'pageId': pageId,
      'position': {'x': position.dx, 'y': position.dy},
    });
  }

  /// Send widget selection
  void sendSelection({required String pageId, String? widgetId}) {
    if (_socket?.connected != true) return;

    _socket!.emit('page:selection', {'pageId': pageId, 'widgetId': widgetId});
  }

  /// Send comment create
  void sendCommentCreate({
    required String pageId,
    required String content,
    double? positionX,
    double? positionY,
    String? widgetId,
    String? parentCommentId,
  }) {
    if (_socket?.connected != true) return;

    _socket!.emit('comment:create', {
      'pageId': pageId,
      'content': content,
      if (positionX != null) 'positionX': positionX,
      if (positionY != null) 'positionY': positionY,
      if (widgetId != null) 'widgetId': widgetId,
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
    });
  }

  /// Send comment update
  void sendCommentUpdate({required String commentId, required String content}) {
    if (_socket?.connected != true) return;

    _socket!.emit('comment:update', {
      'commentId': commentId,
      'content': content,
    });
  }

  /// Send comment delete
  void sendCommentDelete({required String commentId, required String pageId}) {
    if (_socket?.connected != true) return;

    _socket!.emit('comment:delete', {'commentId': commentId, 'pageId': pageId});
  }

  /// Send comment resolve
  void sendCommentResolve({
    required String commentId,
    required String pageId,
    required bool resolved,
  }) {
    if (_socket?.connected != true) return;

    _socket!.emit('comment:resolve', {
      'commentId': commentId,
      'pageId': pageId,
      'resolved': resolved,
    });
  }

  /// Send undo request
  void sendUndo({required String pageId}) {
    if (_socket?.connected != true) {
      print('⚠️ Cannot send undo: Socket not connected');
      return;
    }

    print('↩️ Requesting undo for page: $pageId');
    _socket!.emit('page:undo', {'pageId': pageId});
  }

  /// Send redo request
  void sendRedo({required String pageId}) {
    if (_socket?.connected != true) {
      print('⚠️ Cannot send redo: Socket not connected');
      return;
    }

    print('↪️ Requesting redo for page: $pageId');
    _socket!.emit('page:redo', {'pageId': pageId});
  }

  // ==================== FOLLOW FEATURE METHODS ====================

  /// Start following a user's viewport
  void startFollowing(String pageId, String targetUserId) {
    if (_socket?.connected != true) {
      print('⚠️ Cannot start following: Socket not connected');
      return;
    }

    print('👁️ Starting to follow user: $targetUserId');
    _socket!.emit('page:follow:start', {
      'pageId': pageId,
      'targetUserId': targetUserId,
    });
  }

  /// Stop following user
  void stopFollowing(String pageId) {
    if (_socket?.connected != true) {
      print('⚠️ Cannot stop following: Socket not connected');
      return;
    }

    print('👁️‍🗨️ Stopping follow');
    _socket!.emit('page:follow:stop', {'pageId': pageId});
  }

  /// Send viewport update to followers
  void sendViewportUpdate(String pageId, dynamic viewport) {
    if (_socket?.connected != true) return;

    _socket!.emit('page:viewport:update', {
      'pageId': pageId,
      'viewport': viewport,
    });
  }

  /// Disconnect from server
  void disconnect() {
    if (_currentPageId != null) {
      leavePage();
    }

    _socket?.disconnect();
    _socket = null;
    _connectionStateController.add(PageConnectionState.disconnected);
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _pageJoinedController.close();
    _pageUserJoinedController.close();
    _pageUserLeftController.close();
    _pagePatchAppliedController.close();
    _pagePatchReceivedController.close();
    _pageConflictController.close();
    _pageCursorController.close();
    _pageSelectionController.close();
    _commentCreatedController.close();
    _commentUpdatedController.close();
    _commentDeletedController.close();
    _commentResolvedController.close();
    _commentMentionController.close();
    _undoAppliedController.close();
    _redoAppliedController.close();
    _undoRedoStateController.close();
    _undoErrorController.close();
    _redoErrorController.close();
    _followStartedController.close();
    _followStoppedController.close();
    _viewportUpdatedController.close();
    _followErrorController.close();
  }

  PermissionType _parsePermission(String permission) {
    switch (permission.toLowerCase()) {
      case 'owner':
        return PermissionType.owner;
      case 'edit':
        return PermissionType.edit;
      case 'comment':
        return PermissionType.comment;
      case 'view':
        return PermissionType.view;
      default:
        return PermissionType.view;
    }
  }
}

// ==================== EVENT CLASSES ====================

enum PageConnectionState { connected, disconnected, error }

class PageJoinedEvent {
  final String pageId;
  final String pageName;
  final PageData pageData;
  final int version;
  final PermissionType permission;
  final List<ActiveUser> activeUsers;

  PageJoinedEvent({
    required this.pageId,
    required this.pageName,
    required this.pageData,
    required this.version,
    required this.permission,
    required this.activeUsers,
  });
}

class PageUserEvent {
  final ActiveUser? user;
  final String? userId;
  final DateTime timestamp;
  final bool isJoin;

  PageUserEvent({required this.user, required this.timestamp})
    : userId = null,
      isJoin = true;

  PageUserEvent.left({required this.userId, required this.timestamp})
    : user = null,
      isJoin = false;
}

class PagePatchAppliedEvent {
  final String pageId;
  final List<Map<String, dynamic>> patches;
  final int version;
  final DateTime timestamp;

  PagePatchAppliedEvent({
    required this.pageId,
    required this.patches,
    required this.version,
    required this.timestamp,
  });
}

class PagePatchReceivedEvent {
  final String pageId;
  final String userId;
  final List<Map<String, dynamic>> patches;
  final int version;
  final DateTime timestamp;

  PagePatchReceivedEvent({
    required this.pageId,
    required this.userId,
    required this.patches,
    required this.version,
    required this.timestamp,
  });
}

class PageConflictEvent {
  final int clientVersion;
  final int serverVersion;
  final String message;

  PageConflictEvent({
    required this.clientVersion,
    required this.serverVersion,
    required this.message,
  });
}

class PageCursorEvent {
  final String userId;
  final String? userName;
  final String? userColor;
  final Offset position;
  final DateTime timestamp;

  PageCursorEvent({
    required this.userId,
    this.userName,
    this.userColor,
    required this.position,
    required this.timestamp,
  });
}

class PageSelectionEvent {
  final String userId;
  final String? userName;
  final String? widgetId;
  final DateTime timestamp;

  PageSelectionEvent({
    required this.userId,
    this.userName,
    required this.widgetId,
    required this.timestamp,
  });
}

class ActiveUser {
  final String userId;
  final String name;
  final String email;
  final String? avatarUrl;
  final PermissionType permission;
  final DateTime? joinedAt;

  ActiveUser({
    required this.userId,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.permission,
    this.joinedAt,
  });

  factory ActiveUser.fromJson(Map<String, dynamic> json) {
    return ActiveUser(
      userId: json['userId'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      permission: _parsePermission(json['permission']),
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : null,
    );
  }

  static PermissionType _parsePermission(String permission) {
    switch (permission.toLowerCase()) {
      case 'owner':
        return PermissionType.owner;
      case 'edit':
        return PermissionType.edit;
      case 'comment':
        return PermissionType.comment;
      case 'view':
        return PermissionType.view;
      default:
        return PermissionType.view;
    }
  }
}

// ==================== COMMENT EVENT CLASSES ====================

/// Comment event (created, updated, resolved)
class CommentEvent {
  final Map<String, dynamic> comment;
  final bool isOwn;
  final DateTime timestamp;

  CommentEvent({
    required this.comment,
    required this.isOwn,
    required this.timestamp,
  });

  factory CommentEvent.fromJson(Map<String, dynamic> json) {
    return CommentEvent(
      comment: json['comment'] as Map<String, dynamic>,
      isOwn: json['isOwn'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Comment deleted event
class CommentDeletedEvent {
  final String commentId;
  final bool isOwn;
  final DateTime timestamp;

  CommentDeletedEvent({
    required this.commentId,
    required this.isOwn,
    required this.timestamp,
  });

  factory CommentDeletedEvent.fromJson(Map<String, dynamic> json) {
    return CommentDeletedEvent(
      commentId: json['commentId'],
      isOwn: json['isOwn'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Comment mention event
class CommentMentionEvent {
  final Map<String, dynamic> comment;
  final Map<String, dynamic> mentionedBy;
  final DateTime timestamp;

  CommentMentionEvent({
    required this.comment,
    required this.mentionedBy,
    required this.timestamp,
  });

  factory CommentMentionEvent.fromJson(Map<String, dynamic> json) {
    return CommentMentionEvent(
      comment: json['comment'] as Map<String, dynamic>,
      mentionedBy: json['mentionedBy'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

// ==================== UNDO/REDO EVENT CLASSES ====================

/// Undo applied event
class PageUndoAppliedEvent {
  final String pageId;
  final List<Map<String, dynamic>> patches;
  final int version;
  final String? operationDescription;
  final bool canUndo;
  final bool canRedo;
  final DateTime timestamp;

  PageUndoAppliedEvent({
    required this.pageId,
    required this.patches,
    required this.version,
    this.operationDescription,
    required this.canUndo,
    required this.canRedo,
    required this.timestamp,
  });
}

/// Redo applied event
class PageRedoAppliedEvent {
  final String pageId;
  final List<Map<String, dynamic>> patches;
  final int version;
  final String? operationDescription;
  final bool canUndo;
  final bool canRedo;
  final DateTime timestamp;

  PageRedoAppliedEvent({
    required this.pageId,
    required this.patches,
    required this.version,
    this.operationDescription,
    required this.canUndo,
    required this.canRedo,
    required this.timestamp,
  });
}

/// Undo/Redo state update event
class PageUndoRedoStateEvent {
  final bool canUndo;
  final bool canRedo;

  PageUndoRedoStateEvent({required this.canUndo, required this.canRedo});
}

// ==================== FOLLOW FEATURE EVENT CLASSES ====================

/// Follow started event
class PageFollowStartedEvent {
  final String pageId;
  final String targetUserId;
  final String targetUserName;
  final dynamic initialViewport;
  final DateTime timestamp;

  PageFollowStartedEvent({
    required this.pageId,
    required this.targetUserId,
    required this.targetUserName,
    this.initialViewport,
    required this.timestamp,
  });
}

/// Follow stopped event
class PageFollowStoppedEvent {
  final String pageId;
  final DateTime timestamp;

  PageFollowStoppedEvent({required this.pageId, required this.timestamp});
}

/// Viewport updated event (from followed user)
class PageViewportUpdatedEvent {
  final String userId;
  final String userName;
  final dynamic viewport;
  final DateTime timestamp;

  PageViewportUpdatedEvent({
    required this.userId,
    required this.userName,
    required this.viewport,
    required this.timestamp,
  });
}
