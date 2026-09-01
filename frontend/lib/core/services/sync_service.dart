import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import '../api/websocket_client.dart';
import '../models/widget_model.dart';
import 'canvas_service.dart';

class SyncService {
  final CanvasService _canvasService;
  final WebSocketClient _wsClient = WebSocketClient.instance;

  final Queue<SyncOperation> _pendingOperations = Queue();
  final Map<String, SyncOperation> _inProgressOperations = {};

  bool _isSyncing = false;
  Timer? _syncTimer;

  final _syncStateController = StreamController<SyncState>.broadcast();
  Stream<SyncState> get syncState => _syncStateController.stream;

  SyncState _currentState = SyncState.synced;
  SyncState get currentState => _currentState;

  SyncService({CanvasService? canvasService})
    : _canvasService = canvasService ?? CanvasService();

  // Queue a sync operation
  void queueOperation(SyncOperation operation) {
    print('📝 Queuing sync operation: ${operation.type} - ${operation.id}');
    print('   Data: ${operation.data}');
    _pendingOperations.add(operation);
    _updateState(SyncState.pending);
    _debouncedSync();
  }

  // Debounced sync - waits 500ms before syncing
  void _debouncedSync() {
    _syncTimer?.cancel();
    print('⏱️  Starting 500ms debounce timer...');
    _syncTimer = Timer(const Duration(milliseconds: 500), () {
      print('⏰ Timer fired! Processing pending operations...');
      _processPendingOperations();
    });
  }

  // Process all pending operations
  Future<void> _processPendingOperations() async {
    if (_isSyncing || _pendingOperations.isEmpty) {
      print(
        '⏸️  Skip processing: syncing=$_isSyncing, pending=${_pendingOperations.isEmpty}',
      );
      return;
    }

    print(
      '🔄 Starting sync... ${_pendingOperations.length} operations pending',
    );
    _isSyncing = true;
    _updateState(SyncState.syncing);

    while (_pendingOperations.isNotEmpty) {
      final operation = _pendingOperations.removeFirst();
      await _processOperation(operation);
    }

    _isSyncing = false;
    _updateState(SyncState.synced);
    print('✅ All sync operations completed!');
  }

  // Process a single operation
  Future<void> _processOperation(SyncOperation operation) async {
    _inProgressOperations[operation.id] = operation;

    try {
      switch (operation.type) {
        case SyncOperationType.widgetAdded:
          await _syncWidgetAdded(operation);
          break;
        case SyncOperationType.widgetUpdated:
          await _syncWidgetUpdated(operation);
          break;
        case SyncOperationType.widgetDeleted:
          await _syncWidgetDeleted(operation);
          break;
        case SyncOperationType.batchUpdate:
          await _syncBatchUpdate(operation);
          break;
      }

      _inProgressOperations.remove(operation.id);
      print('✅ Sync operation completed: ${operation.id}');
    } catch (e) {
      print('❌ Sync operation failed: ${operation.id} - $e');
      _inProgressOperations.remove(operation.id);

      // Retry logic
      if (operation.retryCount < 3) {
        operation.retryCount++;
        _pendingOperations.add(operation);
        print('🔄 Retrying operation (${operation.retryCount}/3)');
      } else {
        _updateState(SyncState.failed);
        print('⚠️ Operation failed after 3 retries');
      }
    }
  }

  // Sync widget added
  Future<void> _syncWidgetAdded(SyncOperation operation) async {
    final data = operation.data as Map<String, dynamic>;

    print('🔍 Attempting to create widget via REST API...');
    print('   Canvas ID: ${data['canvasId']}');
    print('   Widget type: ${data['type']}');

    try {
      final widget = await _canvasService.createWidget(
        canvasId: data['canvasId'],
        type: data['type'],
        x: data['x'],
        y: data['y'],
        width: data['width'],
        height: data['height'],
        zIndex: data['zIndex'] ?? 0,
        properties: data['properties'],
      );

      print('✅ Widget created successfully via REST API: ${widget.id}');
      print('   Broadcasting via WebSocket will be handled by backend');

      // NOTE: Don't emit WebSocket event here - the backend will broadcast
      // the widget creation to other users automatically
      // _wsClient.emitWidgetAdded() is NOT needed
    } catch (e, stackTrace) {
      print('❌ Widget creation error details: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Sync widget updated
  Future<void> _syncWidgetUpdated(SyncOperation operation) async {
    final data = operation.data as Map<String, dynamic>;

    await _canvasService.updateWidget(
      canvasId: data['canvasId'],
      widgetId: data['widgetId'],
      x: data['x'],
      y: data['y'],
      width: data['width'],
      height: data['height'],
      zIndex: data['zIndex'],
      properties: data['properties'],
    );

    // NOTE: Backend REST API will handle broadcasting
  }

  // Sync widget deleted
  Future<void> _syncWidgetDeleted(SyncOperation operation) async {
    final data = operation.data as Map<String, dynamic>;

    await _canvasService.deleteWidget(
      canvasId: data['canvasId'],
      widgetId: data['widgetId'],
    );

    // NOTE: Backend REST API will handle broadcasting
  }

  // Sync batch update
  Future<void> _syncBatchUpdate(SyncOperation operation) async {
    final data = operation.data as Map<String, dynamic>;

    await _canvasService.batchUpdateWidgets(
      canvasId: data['canvasId'],
      updates: data['updates'],
    );
  }

  // Update sync state
  void _updateState(SyncState state) {
    _currentState = state;
    _syncStateController.add(state);
  }

  // Force sync now (no debounce)
  Future<void> syncNow() async {
    _syncTimer?.cancel();
    await _processPendingOperations();
  }

  // Clear pending operations
  void clearPending() {
    _pendingOperations.clear();
    _inProgressOperations.clear();
    _updateState(SyncState.synced);
  }

  // Dispose
  void dispose() {
    _syncTimer?.cancel();
    _syncStateController.close();
  }
}

// Sync operation model
class SyncOperation {
  final String id;
  final SyncOperationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  int retryCount;

  SyncOperation({
    required this.id,
    required this.type,
    required this.data,
    DateTime? timestamp,
    this.retryCount = 0,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum SyncOperationType {
  widgetAdded,
  widgetUpdated,
  widgetDeleted,
  batchUpdate,
}

enum SyncState { synced, pending, syncing, failed }
