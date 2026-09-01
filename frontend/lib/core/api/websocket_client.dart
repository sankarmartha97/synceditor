import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'endpoints.dart';
import 'api_client.dart';

class WebSocketClient {
  static WebSocketClient? _instance;
  IO.Socket? _socket;

  final _connectionStateController =
      StreamController<ConnectionState>.broadcast();
  final _widgetEventController = StreamController<WidgetEvent>.broadcast();
  final _cursorEventController = StreamController<CursorEvent>.broadcast();
  final _userEventController = StreamController<UserEvent>.broadcast();
  final _canvasJoinedController =
      StreamController<CanvasJoinedEvent>.broadcast();

  Stream<ConnectionState> get connectionState =>
      _connectionStateController.stream;
  Stream<WidgetEvent> get widgetEvents => _widgetEventController.stream;
  Stream<CursorEvent> get cursorEvents => _cursorEventController.stream;
  Stream<UserEvent> get userEvents => _userEventController.stream;
  Stream<CanvasJoinedEvent> get canvasJoinedEvents =>
      _canvasJoinedController.stream;

  bool get isConnected => _socket?.connected ?? false;
  String? _currentCanvasId;

  WebSocketClient._internal();

  static WebSocketClient get instance {
    _instance ??= WebSocketClient._internal();
    return _instance!;
  }

  void connect() {
    if (_socket?.connected == true) {
      print('🔌 WebSocket already connected');
      return;
    }

    final token = ApiClient.instance.authToken;
    if (token == null) {
      print('⚠️ Cannot connect WebSocket: No auth token');
      return;
    }

    print('🔌 Connecting to WebSocket: ${ApiEndpoints.wsUrl}');

    _socket = IO.io(
      ApiEndpoints.wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(5)
          .setAuth({'token': token})
          .build(),
    );

    _setupEventListeners();
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      print('✅ WebSocket connected');
      _connectionStateController.add(ConnectionState.connected);

      // Rejoin canvas if we were in one
      if (_currentCanvasId != null) {
        joinCanvas(_currentCanvasId!);
      }
    });

    _socket!.onDisconnect((_) {
      print('❌ WebSocket disconnected');
      _connectionStateController.add(ConnectionState.disconnected);
    });

    _socket!.onConnectError((error) {
      print('❌ WebSocket connection error: $error');
      _connectionStateController.add(ConnectionState.error);
    });

    _socket!.onError((error) {
      print('❌ WebSocket error: $error');
    });

    // Widget events
    _socket!.on('widget:added', (data) {
      print('📦 Widget added from user ${data['userId']}');
      final widget = data['widget'];
      _widgetEventController.add(
        WidgetEvent(
          type: WidgetEventType.added,
          widgetId: widget['id'],
          canvasId: widget['canvas_id'],
          data: widget,
          userId: data['userId'],
        ),
      );
    });

    _socket!.on('widget:updated', (data) {
      print('📦 Widget updated from user ${data['userId']}');
      final widget = data['widget'];
      _widgetEventController.add(
        WidgetEvent(
          type: WidgetEventType.updated,
          widgetId: widget['id'],
          canvasId: widget['canvas_id'],
          data: widget,
          userId: data['userId'],
        ),
      );
    });

    _socket!.on('widget:deleted', (data) {
      print('📦 Widget deleted: ${data['widgetId']}');
      _widgetEventController.add(
        WidgetEvent(
          type: WidgetEventType.deleted,
          widgetId: data['widgetId'],
          canvasId: '', // Not needed for delete
          data: null,
          userId: data['userId'],
        ),
      );
    });

    // Cursor events
    _socket!.on('cursor:updated', (data) {
      _cursorEventController.add(
        CursorEvent(
          userId: data['userId'],
          userName: '', // We'll get this from active users
          position: CursorPosition(
            x: (data['position']['x'] as num).toDouble(),
            y: (data['position']['y'] as num).toDouble(),
          ),
        ),
      );
    });

    // User events
    _socket!.on('user:joined', (data) {
      print('👤 User joined: ${data['user']['name']}');
      _userEventController.add(
        UserEvent(
          type: UserEventType.joined,
          userId: data['user']['userId'],
          userName: data['user']['name'],
          email: data['user']['email'],
          avatarUrl: data['user']['avatarUrl'],
        ),
      );
    });

    _socket!.on('user:left', (data) {
      print('👤 User left: ${data['userId']}');
      _userEventController.add(
        UserEvent(
          type: UserEventType.left,
          userId: data['userId'],
          userName: '',
        ),
      );
    });

    // Acknowledgment handlers
    _socket!.on('error', (data) {
      print('❌ Server error: ${data['message']}');
    });

    // Canvas joined event (with initial activeUsers list)
    _socket!.on('canvas:joined', (data) {
      print('✅ Canvas joined: ${data['canvasId']}');
      print('👥 Active users: ${data['activeUsers']?.length ?? 0}');
      _canvasJoinedController.add(
        CanvasJoinedEvent(
          canvasId: data['canvasId'],
          canvasName: data['canvasName'],
          activeUsers:
              (data['activeUsers'] as List<dynamic>?)
                  ?.map(
                    (u) => {
                      'userId': u['userId'],
                      'name': u['name'],
                      'email': u['email'],
                      'avatarUrl': u['avatarUrl'],
                    },
                  )
                  .toList() ??
              [],
        ),
      );
    });
  }

  // Join a canvas room
  void joinCanvas(String canvasId) {
    if (_socket?.connected != true) {
      print('⚠️ Cannot join canvas: WebSocket not connected');
      return;
    }

    _currentCanvasId = canvasId;
    print('🎨 Joining canvas: $canvasId');

    _socket!.emit('canvas:join', {'canvasId': canvasId});
  }

  // Leave a canvas room
  void leaveCanvas() {
    if (_socket?.connected != true || _currentCanvasId == null) {
      return;
    }

    print('🎨 Leaving canvas: $_currentCanvasId');

    _socket!.emit('canvas:leave', {'canvasId': _currentCanvasId});

    _currentCanvasId = null;
  }

  // Emit widget added event
  void emitWidgetAdded(
    String canvasId,
    String widgetId,
    Map<String, dynamic> widget,
  ) {
    if (_socket?.connected != true) {
      print('⚠️ Cannot emit widget added: WebSocket not connected');
      return;
    }

    _socket!.emit('widget:add', {
      'canvasId': canvasId,
      'widgetId': widgetId,
      'widget': widget,
    });
  }

  // Emit widget updated event
  void emitWidgetUpdated(
    String canvasId,
    String widgetId,
    Map<String, dynamic> updates,
  ) {
    if (_socket?.connected != true) {
      print('⚠️ Cannot emit widget updated: WebSocket not connected');
      return;
    }

    _socket!.emit('widget:update', {
      'canvasId': canvasId,
      'widgetId': widgetId,
      'updates': updates,
    });
  }

  // Emit widget deleted event
  void emitWidgetDeleted(String canvasId, String widgetId) {
    if (_socket?.connected != true) {
      print('⚠️ Cannot emit widget deleted: WebSocket not connected');
      return;
    }

    _socket!.emit('widget:delete', {
      'canvasId': canvasId,
      'widgetId': widgetId,
    });
  }

  // Emit cursor moved event
  void emitCursorMoved(String canvasId, double x, double y) {
    if (_socket?.connected != true) {
      return; // Silent fail for cursor events
    }

    _socket!.emit('cursor:move', {
      'canvasId': canvasId,
      'position': {'x': x, 'y': y},
    });
  }

  // Disconnect
  void disconnect() {
    leaveCanvas();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    print('🔌 WebSocket disconnected and disposed');
  }

  // Dispose
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _widgetEventController.close();
    _cursorEventController.close();
    _userEventController.close();
    _canvasJoinedController.close();
  }
}

// Event models
class CanvasJoinedEvent {
  final String canvasId;
  final String canvasName;
  final List<Map<String, dynamic>> activeUsers;

  CanvasJoinedEvent({
    required this.canvasId,
    required this.canvasName,
    required this.activeUsers,
  });
}

class WidgetEvent {
  final WidgetEventType type;
  final String widgetId;
  final String canvasId;
  final Map<String, dynamic>? data;
  final String userId;

  WidgetEvent({
    required this.type,
    required this.widgetId,
    required this.canvasId,
    required this.data,
    required this.userId,
  });
}

enum WidgetEventType { added, updated, deleted }

class CursorEvent {
  final String userId;
  final String userName;
  final CursorPosition position;

  CursorEvent({
    required this.userId,
    required this.userName,
    required this.position,
  });
}

class CursorPosition {
  final double x;
  final double y;

  CursorPosition({required this.x, required this.y});
}

class UserEvent {
  final UserEventType type;
  final String userId;
  final String userName;
  final String? email;
  final String? avatarUrl;

  UserEvent({
    required this.type,
    required this.userId,
    required this.userName,
    this.email,
    this.avatarUrl,
  });
}

enum UserEventType { joined, left }

enum ConnectionState { connecting, connected, disconnected, error }
