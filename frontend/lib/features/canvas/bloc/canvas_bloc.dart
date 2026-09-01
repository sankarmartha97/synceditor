import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'canvas_event.dart';
import 'canvas_state.dart';
import '../models/canvas_widget.dart';
import '../widgets/user_presence_indicator.dart';
import '../../../core/services/canvas_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/api/websocket_client.dart';
import '../../../core/models/widget_model.dart';

class CanvasBloc extends Bloc<CanvasEvent, CanvasState> {
  final CanvasService _canvasService;
  final SyncService _syncService;
  final WebSocketClient _wsClient = WebSocketClient.instance;

  StreamSubscription? _widgetEventSubscription;
  StreamSubscription<UserEvent>? _userEventSubscription;
  final _uuid = const Uuid();

  // Expose sync service for UI
  SyncService get syncService => _syncService;

  CanvasBloc({CanvasService? canvasService, SyncService? syncService})
    : _canvasService = canvasService ?? CanvasService(),
      _syncService = syncService ?? SyncService(),
      super(const CanvasState()) {
    on<AddWidgetToCanvas>(_onAddWidget);
    on<UpdateWidgetPosition>(_onUpdatePosition);
    on<UpdateWidgetSize>(_onUpdateSize);
    on<UpdateWidgetColor>(_onUpdateColor);
    on<SelectWidget>(_onSelectWidget);
    on<DeleteWidget>(_onDeleteWidget);
    on<UpdateWidgetText>(_onUpdateText);
    on<UpdateWidgetBorderRadius>(_onUpdateBorderRadius);
    on<UpdateWidgetOpacity>(_onUpdateOpacity);
    on<UpdateWidgetRotation>(_onUpdateRotation);
    on<BringWidgetToFront>(_onBringToFront);
    on<SendWidgetToBack>(_onSendToBack);
    on<UndoAction>(_onUndo);
    on<RedoAction>(_onRedo);
    on<UserJoined>(_onUserJoined);
    on<UserLeft>(_onUserLeft);
    on<UpdateActiveUsers>(_onUpdateActiveUsers);
    on<UpdateCursorPosition>(_onUpdateCursorPosition);
    on<RemoveCursor>(_onRemoveCursor);
    on<LoadCanvas>(_onLoadCanvas);
    on<CreateNewCanvas>(_onCreateCanvas);
    on<RemoteWidgetAdded>(_onRemoteWidgetAdded);
    on<RemoteWidgetUpdated>(_onRemoteWidgetUpdated);
    on<RemoteWidgetDeleted>(_onRemoteWidgetDeleted);

    // Listen to WebSocket widget events
    _widgetEventSubscription = _wsClient.widgetEvents.listen((event) {
      _handleWidgetEvent(event);
    });

    // Listen to WebSocket user events
    _userEventSubscription = _wsClient.userEvents.listen((event) {
      _handleUserEvent(event);
    });

    // Listen to canvas joined events
    _wsClient.canvasJoinedEvents.listen((event) {
      final users = event.activeUsers.map((u) {
        return ActiveUser(
          userId: u['userId'],
          name: u['name'],
          email: u['email'],
          avatarUrl: u['avatarUrl'],
        );
      }).toList();
      add(UpdateActiveUsers(users));
    });

    // Listen to cursor events
    _wsClient.cursorEvents.listen((event) {
      // Look up user name from active users
      final user = state.activeUsers.firstWhere(
        (u) => u.userId == event.userId,
        orElse: () =>
            ActiveUser(userId: event.userId, name: 'Unknown', email: ''),
      );
      add(
        UpdateCursorPosition(
          event.userId,
          user.name,
          Offset(event.position.x, event.position.y),
        ),
      );
    });
  }

  // Handle WebSocket user events
  void _handleUserEvent(UserEvent event) {
    switch (event.type) {
      case UserEventType.joined:
        add(
          UserJoined(
            event.userId,
            event.userName,
            email: event.email,
            avatarUrl: event.avatarUrl,
          ),
        );
        break;
      case UserEventType.left:
        add(UserLeft(event.userId));
        break;
    }
  }

  // Handle WebSocket widget events
  void _handleWidgetEvent(WidgetEvent event) {
    switch (event.type) {
      case WidgetEventType.added:
        add(
          RemoteWidgetAdded(widgetId: event.widgetId, widgetData: event.data!),
        );
        break;
      case WidgetEventType.updated:
        add(
          RemoteWidgetUpdated(widgetId: event.widgetId, updates: event.data!),
        );
        break;
      case WidgetEventType.deleted:
        add(RemoteWidgetDeleted(event.widgetId));
        break;
    }
  }

  // Load canvas from backend
  Future<void> _onLoadCanvas(
    LoadCanvas event,
    Emitter<CanvasState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      // Fetch canvas and widgets from backend
      final canvas = await _canvasService.getCanvasById(event.canvasId);
      final widgetModels = await _canvasService.getWidgets(event.canvasId);

      // Convert WidgetModel to CanvasWidget
      final canvasWidgets = widgetModels
          .map(
            (wm) => CanvasWidget(
              id: wm.id,
              type: wm.type,
              position: wm.position,
              size: wm.size,
              backgroundColor: wm.backgroundColor,
              text: wm.text,
              borderRadius:
                  (wm.properties['borderRadius'] as num?)?.toDouble() ?? 8.0,
              opacity: (wm.properties['opacity'] as num?)?.toDouble() ?? 1.0,
              rotation: (wm.properties['rotation'] as num?)?.toDouble() ?? 0.0,
              zIndex: wm.zIndex,
            ),
          )
          .toList();

      print('📦 Loaded ${canvasWidgets.length} widgets');

      // Join WebSocket room for this canvas
      _wsClient.joinCanvas(event.canvasId);

      emit(
        state.copyWith(
          widgets: canvasWidgets,
          currentCanvasId: event.canvasId,
          canvasBackgroundColor: canvas.backgroundColor,
          isLoading: false,
          clearSelection: true,
        ),
      );
    } catch (e) {
      print('❌ Failed to load canvas: $e');
      emit(
        state.copyWith(isLoading: false, error: 'Failed to load canvas: $e'),
      );
    }
  }

  // Create new canvas
  Future<void> _onCreateCanvas(
    CreateNewCanvas event,
    Emitter<CanvasState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      // Create PUBLIC canvas so all users can collaborate
      final canvas = await _canvasService.createCanvas(
        name: event.name,
        description: event.description,
        isPublic: true, // ✨ Make canvas public for multi-user collaboration
      );

      print('✅ Created PUBLIC canvas: ${canvas.id}');
      print('   All users can now join and collaborate!');

      // Join WebSocket room
      _wsClient.joinCanvas(canvas.id);

      // activeUsers will be populated by canvas:joined event
      emit(
        state.copyWith(
          widgets: [],
          currentCanvasId: canvas.id,
          canvasBackgroundColor: canvas.backgroundColor,
          isLoading: false,
          clearSelection: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, error: 'Failed to create canvas: $e'),
      );
    }
  }

  // Add widget (optimistic update + sync)
  void _onAddWidget(AddWidgetToCanvas event, Emitter<CanvasState> emit) async {
    print('🎨 Adding widget to canvas: ${event.widget.type}');
    print('   Current canvas ID: ${state.currentCanvasId}');
    print('   Temporary widget ID: ${event.widget.id}');

    // Save history before making changes
    _saveToHistory(emit);

    // Optimistic UI update with temporary ID
    final updatedWidgets = List<CanvasWidget>.from(state.widgets)
      ..add(event.widget);
    emit(
      state.copyWith(
        widgets: updatedWidgets,
        selectedWidgetId: event.widget.id,
      ),
    );

    // Save to database and get real ID
    if (state.currentCanvasId != null) {
      print('✅ Canvas ID exists, saving to database...');

      try {
        // Create widget via API
        final createdWidget = await _canvasService.createWidget(
          canvasId: state.currentCanvasId!,
          type: event.widget.type,
          x: event.widget.position.dx,
          y: event.widget.position.dy,
          width: event.widget.size.width,
          height: event.widget.size.height,
          zIndex: 0,
          properties: {
            'backgroundColor': event.widget.backgroundColor.value,
            if (event.widget.text != null) 'text': event.widget.text,
          },
        );

        print('✅ Widget saved! Real DB ID: ${createdWidget.id}');

        // Replace temporary widget with real one from database
        final finalWidgets = state.widgets.map((w) {
          if (w.id == event.widget.id) {
            // Replace with widget that has real database ID
            return CanvasWidget(
              id: createdWidget.id, // ← Real database ID!
              type: createdWidget.type,
              position: Offset(createdWidget.x, createdWidget.y),
              size: Size(createdWidget.width, createdWidget.height),
              backgroundColor: createdWidget.backgroundColor,
              text: createdWidget.text,
            );
          }
          return w;
        }).toList();

        emit(
          state.copyWith(
            widgets: finalWidgets,
            selectedWidgetId: createdWidget.id, // Update selection too
          ),
        );
      } catch (e) {
        print('❌ Failed to save widget: $e');
        // Remove the optimistic widget since it failed
        final rollbackWidgets = state.widgets
            .where((w) => w.id != event.widget.id)
            .toList();
        emit(state.copyWith(widgets: rollbackWidgets, clearSelection: true));
      }
    } else {
      print('❌ No canvas ID! Widget will NOT be saved to database!');
    }
  }

  // Update widget position (optimistic update + sync)
  void _onUpdatePosition(
    UpdateWidgetPosition event,
    Emitter<CanvasState> emit,
  ) {
    final updatedWidgets = state.widgets.map((widget) {
      if (widget.id == event.widgetId) {
        return widget.copyWith(position: event.position);
      }
      return widget;
    }).toList();

    emit(state.copyWith(widgets: updatedWidgets));

    // Queue sync operation
    if (state.currentCanvasId != null) {
      _syncService.queueOperation(
        SyncOperation(
          id: _uuid.v4(),
          type: SyncOperationType.widgetUpdated,
          data: {
            'canvasId': state.currentCanvasId!,
            'widgetId': event.widgetId,
            'x': event.position.dx,
            'y': event.position.dy,
          },
        ),
      );
    }
  }

  // Update widget size (optimistic update + sync)
  void _onUpdateSize(UpdateWidgetSize event, Emitter<CanvasState> emit) {
    final updatedWidgets = state.widgets.map((widget) {
      if (widget.id == event.widgetId) {
        return widget.copyWith(size: event.size);
      }
      return widget;
    }).toList();

    emit(state.copyWith(widgets: updatedWidgets));

    // Queue sync operation
    if (state.currentCanvasId != null) {
      _syncService.queueOperation(
        SyncOperation(
          id: _uuid.v4(),
          type: SyncOperationType.widgetUpdated,
          data: {
            'canvasId': state.currentCanvasId!,
            'widgetId': event.widgetId,
            'width': event.size.width,
            'height': event.size.height,
          },
        ),
      );
    }
  }

  // Update widget color (optimistic update + sync)
  void _onUpdateColor(UpdateWidgetColor event, Emitter<CanvasState> emit) {
    final updatedWidgets = state.widgets.map((widget) {
      if (widget.id == event.widgetId) {
        return widget.copyWith(backgroundColor: event.color);
      }
      return widget;
    }).toList();

    emit(state.copyWith(widgets: updatedWidgets));

    // Queue sync operation
    if (state.currentCanvasId != null) {
      _syncService.queueOperation(
        SyncOperation(
          id: _uuid.v4(),
          type: SyncOperationType.widgetUpdated,
          data: {
            'canvasId': state.currentCanvasId!,
            'widgetId': event.widgetId,
            'properties': {'backgroundColor': event.color.value},
          },
        ),
      );
    }
  }

  void _onSelectWidget(SelectWidget event, Emitter<CanvasState> emit) {
    emit(
      state.copyWith(
        selectedWidgetId: event.widgetId,
        clearSelection: event.widgetId == null,
      ),
    );
  }

  // Delete widget (optimistic update + sync)
  void _onDeleteWidget(DeleteWidget event, Emitter<CanvasState> emit) async {
    print('🗑️  Deleting widget: ${event.widgetId}');

    // Save history before making changes
    _saveToHistory(emit);

    // Optimistic UI update - remove immediately
    final updatedWidgets = state.widgets
        .where((w) => w.id != event.widgetId)
        .toList();
    emit(state.copyWith(widgets: updatedWidgets, clearSelection: true));

    // Delete from database
    if (state.currentCanvasId != null) {
      try {
        await _canvasService.deleteWidget(
          canvasId: state.currentCanvasId!,
          widgetId: event.widgetId,
        );
        print('✅ Widget deleted from database');
      } catch (e) {
        print('❌ Failed to delete widget: $e');
        // Optionally: restore widget if deletion fails
      }
    }
  }

  // Handle remote widget added
  void _onRemoteWidgetAdded(
    RemoteWidgetAdded event,
    Emitter<CanvasState> emit,
  ) {
    // Check if widget already exists
    if (state.widgets.any((w) => w.id == event.widgetId)) {
      print('⚠️ Widget ${event.widgetId} already exists, skipping');
      return;
    }

    print('✅ Adding remote widget: ${event.widgetId}');
    final widgetData = event.widgetData;

    // Parse position from backend format {x, y, z_index}
    final position = widgetData['position'] as Map<String, dynamic>;
    final size = widgetData['size'] as Map<String, dynamic>;
    final properties = widgetData['properties'] as Map<String, dynamic>?;

    final widget = CanvasWidget(
      id: event.widgetId,
      type: widgetData['type'],
      position: Offset(
        (position['x'] as num).toDouble(),
        (position['y'] as num).toDouble(),
      ),
      size: Size(
        (size['width'] as num).toDouble(),
        (size['height'] as num).toDouble(),
      ),
      backgroundColor: properties?['backgroundColor'] != null
          ? Color(properties!['backgroundColor'] as int)
          : const Color(0xFFCCCCCC),
      text: properties?['text'],
      zIndex: (position['z_index'] as num?)?.toInt() ?? 0,
    );

    final updatedWidgets = List<CanvasWidget>.from(state.widgets)..add(widget);
    emit(state.copyWith(widgets: updatedWidgets));
  }

  // Handle remote widget updated
  void _onRemoteWidgetUpdated(
    RemoteWidgetUpdated event,
    Emitter<CanvasState> emit,
  ) {
    print('🔄 Updating remote widget: ${event.widgetId}');
    final widgetData = event.updates;

    final updatedWidgets = state.widgets.map((widget) {
      if (widget.id == event.widgetId) {
        // Parse position and size from backend format
        final position = widgetData['position'] as Map<String, dynamic>?;
        final size = widgetData['size'] as Map<String, dynamic>?;
        final properties = widgetData['properties'] as Map<String, dynamic>?;

        return widget.copyWith(
          position: position != null
              ? Offset(
                  (position['x'] as num).toDouble(),
                  (position['y'] as num).toDouble(),
                )
              : null,
          size: size != null
              ? Size(
                  (size['width'] as num).toDouble(),
                  (size['height'] as num).toDouble(),
                )
              : null,
          backgroundColor: properties?['backgroundColor'] != null
              ? Color(properties!['backgroundColor'] as int)
              : null,
          text: properties?['text'],
          zIndex: position?['z_index'] != null
              ? (position!['z_index'] as num).toInt()
              : null,
        );
      }
      return widget;
    }).toList();

    emit(state.copyWith(widgets: updatedWidgets));
  }

  // Handle remote widget deleted
  void _onRemoteWidgetDeleted(
    RemoteWidgetDeleted event,
    Emitter<CanvasState> emit,
  ) {
    final updatedWidgets = state.widgets
        .where((w) => w.id != event.widgetId)
        .toList();
    emit(state.copyWith(widgets: updatedWidgets));
  }

  @override
  Future<void> close() {
    _widgetEventSubscription?.cancel();
    _userEventSubscription?.cancel();
    _wsClient.leaveCanvas();
    return super.close();
  }

  // Handle user joined event
  void _onUserJoined(UserJoined event, Emitter<CanvasState> emit) {
    print('👤 User joined: ${event.userName}');

    // Add user to active users list
    final newUser = ActiveUser(
      userId: event.userId,
      name: event.userName,
      email: event.email ?? '${event.userName.toLowerCase()}@example.com',
      avatarUrl: event.avatarUrl,
    );

    final updatedUsers = List<ActiveUser>.from(state.activeUsers);
    if (!updatedUsers.any((u) => u.userId == event.userId)) {
      updatedUsers.add(newUser);
    }

    emit(state.copyWith(activeUsers: updatedUsers));
  }

  // Handle user left event
  void _onUserLeft(UserLeft event, Emitter<CanvasState> emit) {
    print('👋 User left: ${event.userId}');

    // Remove user from active users list
    final updatedUsers = state.activeUsers
        .where((u) => u.userId != event.userId)
        .toList();

    // Remove cursor
    final updatedCursors = Map<String, RemoteCursor>.from(state.remoteCursors);
    updatedCursors.remove(event.userId);

    emit(
      state.copyWith(activeUsers: updatedUsers, remoteCursors: updatedCursors),
    );
  }

  // Update active users list (from canvas join response)
  void _onUpdateActiveUsers(
    UpdateActiveUsers event,
    Emitter<CanvasState> emit,
  ) {
    print('👥 Updating active users: ${event.activeUsers.length} users');
    emit(state.copyWith(activeUsers: event.activeUsers));
  }

  // Update cursor position
  void _onUpdateCursorPosition(
    UpdateCursorPosition event,
    Emitter<CanvasState> emit,
  ) {
    final cursors = Map<String, RemoteCursor>.from(state.remoteCursors);

    if (cursors.containsKey(event.userId)) {
      // Update existing cursor position
      cursors[event.userId] = cursors[event.userId]!.copyWith(
        position: event.position,
      );
    } else {
      // Add new cursor with color based on userId
      cursors[event.userId] = RemoteCursor(
        userId: event.userId,
        userName: event.userName,
        position: event.position,
        color: _getColorForUser(event.userId),
      );
    }

    emit(state.copyWith(remoteCursors: cursors));
  }

  // Remove cursor when user leaves
  void _onRemoveCursor(RemoveCursor event, Emitter<CanvasState> emit) {
    final cursors = Map<String, RemoteCursor>.from(state.remoteCursors);
    cursors.remove(event.userId);
    emit(state.copyWith(remoteCursors: cursors));
  }

  // Helper to get consistent color for user
  Color _getColorForUser(String userId) {
    final hash = userId.hashCode;
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.red,
      Colors.cyan,
      Colors.amber,
      Colors.lime,
    ];
    return colors[hash.abs() % colors.length];
  }

  // Update widget text
  void _onUpdateText(UpdateWidgetText event, Emitter<CanvasState> emit) async {
    final updatedWidgets = state.widgets.map((w) {
      if (w.id == event.widgetId) {
        return w.copyWith(text: event.text);
      }
      return w;
    }).toList();
    emit(state.copyWith(widgets: updatedWidgets));
    // TODO: Sync to database
  }

  // Update widget border radius
  void _onUpdateBorderRadius(
    UpdateWidgetBorderRadius event,
    Emitter<CanvasState> emit,
  ) async {
    final updatedWidgets = state.widgets.map((w) {
      if (w.id == event.widgetId) {
        return w.copyWith(borderRadius: event.borderRadius);
      }
      return w;
    }).toList();
    emit(state.copyWith(widgets: updatedWidgets));
    // TODO: Sync to database
  }

  // Update widget opacity
  void _onUpdateOpacity(
    UpdateWidgetOpacity event,
    Emitter<CanvasState> emit,
  ) async {
    final updatedWidgets = state.widgets.map((w) {
      if (w.id == event.widgetId) {
        return w.copyWith(opacity: event.opacity);
      }
      return w;
    }).toList();
    emit(state.copyWith(widgets: updatedWidgets));
    // TODO: Sync to database
  }

  // Update widget rotation
  void _onUpdateRotation(
    UpdateWidgetRotation event,
    Emitter<CanvasState> emit,
  ) async {
    final updatedWidgets = state.widgets.map((w) {
      if (w.id == event.widgetId) {
        return w.copyWith(rotation: event.rotation);
      }
      return w;
    }).toList();
    emit(state.copyWith(widgets: updatedWidgets));
    // TODO: Sync to database
  }

  // Bring widget to front
  void _onBringToFront(BringWidgetToFront event, Emitter<CanvasState> emit) {
    final maxZIndex = state.widgets.fold<int>(
      0,
      (max, w) => w.zIndex > max ? w.zIndex : max,
    );

    final updatedWidgets = state.widgets.map((w) {
      if (w.id == event.widgetId) {
        return w.copyWith(zIndex: maxZIndex + 1);
      }
      return w;
    }).toList();

    emit(state.copyWith(widgets: updatedWidgets));
  }

  // Send widget to back
  void _onSendToBack(SendWidgetToBack event, Emitter<CanvasState> emit) {
    final minZIndex = state.widgets.fold<int>(
      0,
      (min, w) => w.zIndex < min ? w.zIndex : min,
    );

    final updatedWidgets = state.widgets.map((w) {
      if (w.id == event.widgetId) {
        return w.copyWith(zIndex: minZIndex - 1);
      }
      return w;
    }).toList();

    emit(state.copyWith(widgets: updatedWidgets));
  }

  // Undo action
  void _onUndo(UndoAction event, Emitter<CanvasState> emit) {
    if (state.undoHistory.isEmpty) {
      print('⏪ Cannot undo: history is empty');
      return;
    }

    print('⏪ Undo action');

    // Save current state to redo history
    final redoHistory = List<List<CanvasWidget>>.from(state.redoHistory)
      ..add(List.from(state.widgets));

    // Restore previous state from undo history
    final undoHistory = List<List<CanvasWidget>>.from(state.undoHistory);
    final previousState = undoHistory.removeLast();

    emit(
      state.copyWith(
        widgets: previousState,
        undoHistory: undoHistory,
        redoHistory: redoHistory,
        clearSelection: true,
      ),
    );
  }

  // Redo action
  void _onRedo(RedoAction event, Emitter<CanvasState> emit) {
    if (state.redoHistory.isEmpty) {
      print('⏩ Cannot redo: no actions to redo');
      return;
    }

    print('⏩ Redo action');

    // Save current state to undo history
    final undoHistory = List<List<CanvasWidget>>.from(state.undoHistory)
      ..add(List.from(state.widgets));

    // Restore next state from redo history
    final redoHistory = List<List<CanvasWidget>>.from(state.redoHistory);
    final nextState = redoHistory.removeLast();

    emit(
      state.copyWith(
        widgets: nextState,
        undoHistory: undoHistory,
        redoHistory: redoHistory,
        clearSelection: true,
      ),
    );
  }

  // Helper method to save current state to history before making changes
  void _saveToHistory(Emitter<CanvasState> emit) {
    final maxHistorySize = 50; // Limit history to 50 states
    final undoHistory = List<List<CanvasWidget>>.from(state.undoHistory);

    // Add current state to history
    undoHistory.add(List.from(state.widgets));

    // Keep only last N states
    if (undoHistory.length > maxHistorySize) {
      undoHistory.removeAt(0);
    }

    // Clear redo history when new action is performed
    emit(state.copyWith(undoHistory: undoHistory, redoHistory: []));
  }
}
