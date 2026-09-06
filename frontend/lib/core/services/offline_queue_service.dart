import 'dart:async';
import '../storage/storage_service.dart';
import '../api/api_client.dart';

/// Operation types that can be queued
enum OperationType {
  createWidget,
  updateWidget,
  deleteWidget,
  updatePage,
  createPage,
  deletePage,
}

/// Extension to convert operation type to/from string
extension OperationTypeExtension on OperationType {
  String toJsonString() {
    return toString().split('.').last;
  }

  static OperationType fromString(String value) {
    return OperationType.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => OperationType.updateWidget,
    );
  }
}

/// Service for managing offline operations queue
/// Queues operations when offline and syncs them when back online
class OfflineQueueService {
  final StorageService _storage = StorageService.instance;
  final ApiClient _apiClient = ApiClient.instance;

  static OfflineQueueService? _instance;
  
  bool _isSyncing = false;
  StreamController<int>? _queueCountController;

  OfflineQueueService._internal();

  static OfflineQueueService get instance {
    _instance ??= OfflineQueueService._internal();
    return _instance!;
  }

  /// Stream of queue count updates
  Stream<int> get queueCountStream {
    _queueCountController ??= StreamController<int>.broadcast();
    return _queueCountController!.stream;
  }

  /// Queue an operation for later execution
  Future<void> queueOperation({
    required OperationType type,
    required String pageId,
    String? widgetId,
    Map<String, dynamic>? data,
  }) async {
    final operation = {
      'type': type.toJsonString(),
      'pageId': pageId,
      'widgetId': widgetId,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'retryCount': 0,
    };

    await _storage.queueOperation(operation);
    _notifyQueueUpdate();
    
    print('⏳ Queued ${type.toJsonString()} operation for page $pageId');
  }

  /// Get count of pending operations
  int getPendingCount() {
    return _storage.getOperationQueueCount();
  }

  /// Check if there are pending operations
  bool hasPendingOperations() {
    return getPendingCount() > 0;
  }

  /// Sync all queued operations with the server
  Future<SyncResult> syncQueue() async {
    if (_isSyncing) {
      print('⏳ Sync already in progress...');
      return SyncResult(success: 0, failed: 0, skipped: 0);
    }

    _isSyncing = true;
    
    try {
      final operations = _storage.getQueuedOperations();
      
      if (operations.isEmpty) {
        print('✅ No operations to sync');
        return SyncResult(success: 0, failed: 0, skipped: 0);
      }

      print('🔄 Syncing ${operations.length} queued operations...');

      int successCount = 0;
      int failedCount = 0;
      int skippedCount = 0;

      // Sort operations by timestamp to maintain order
      operations.sort((a, b) => 
        (a['timestamp'] as int).compareTo(b['timestamp'] as int)
      );

      for (final operation in operations) {
        final timestamp = operation['timestamp'] as int;
        
        try {
          final result = await _executeOperation(operation);
          
          if (result) {
            // Remove from queue on success
            await _storage.removeOperation(timestamp);
            successCount++;
            print('✅ Synced ${operation['type']} operation');
          } else {
            // Increment retry count
            final retryCount = (operation['retryCount'] as int? ?? 0) + 1;
            
            if (retryCount >= 3) {
              // Skip after 3 retries
              await _storage.removeOperation(timestamp);
              skippedCount++;
              print('⏭️ Skipped ${operation['type']} after 3 retries');
            } else {
              operation['retryCount'] = retryCount;
              failedCount++;
              print('⚠️ Failed ${operation['type']}, will retry (attempt $retryCount)');
            }
          }
        } catch (e) {
          failedCount++;
          print('❌ Error syncing ${operation['type']}: $e');
        }

        // Small delay between operations
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _notifyQueueUpdate();

      print('✅ Sync complete: $successCount success, $failedCount failed, $skippedCount skipped');
      return SyncResult(
        success: successCount,
        failed: failedCount,
        skipped: skippedCount,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Execute a single operation
  Future<bool> _executeOperation(Map<String, dynamic> operation) async {
    final type = OperationTypeExtension.fromString(operation['type']);
    final pageId = operation['pageId'] as String;
    final widgetId = operation['widgetId'] as String?;
    final data = operation['data'] as Map<String, dynamic>?;

    try {
      switch (type) {
        case OperationType.createWidget:
          await _apiClient.post(
            '/api/pages/$pageId/widgets',
            data: data,
          );
          return true;

        case OperationType.updateWidget:
          await _apiClient.patch(
            '/api/pages/$pageId/widgets/$widgetId',
            data: data,
          );
          return true;

        case OperationType.deleteWidget:
          await _apiClient.delete(
            '/api/pages/$pageId/widgets/$widgetId',
          );
          return true;

        case OperationType.updatePage:
          await _apiClient.patch(
            '/api/pages/$pageId',
            data: data,
          );
          return true;

        case OperationType.createPage:
          await _apiClient.post(
            '/api/pages',
            data: data,
          );
          return true;

        case OperationType.deletePage:
          await _apiClient.delete('/api/pages/$pageId');
          return true;
      }
    } catch (e) {
      print('⚠️ Failed to execute ${type.toJsonString()}: $e');
      return false;
    }
  }

  /// Clear all queued operations
  Future<void> clearQueue() async {
    await _storage.clearOperationQueue();
    _notifyQueueUpdate();
    print('🗑️ Cleared operation queue');
  }

  /// Get all pending operations (for debugging)
  List<Map<String, dynamic>> getPendingOperations() {
    return _storage.getQueuedOperations();
  }

  /// Notify listeners of queue count change
  void _notifyQueueUpdate() {
    _queueCountController?.add(getPendingCount());
  }

  /// Dispose resources
  void dispose() {
    _queueCountController?.close();
  }

  /// Print queue statistics
  void printQueueStats() {
    final operations = getPendingOperations();
    
    if (operations.isEmpty) {
      print('📊 Operation Queue: Empty');
      return;
    }

    final typeCount = <String, int>{};
    for (final op in operations) {
      final type = op['type'] as String;
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }

    print('📊 Operation Queue Statistics:');
    print('   Total operations: ${operations.length}');
    print('   By type:');
    typeCount.forEach((type, count) {
      print('     $type: $count');
    });
  }
}

/// Result of a sync operation
class SyncResult {
  final int success;
  final int failed;
  final int skipped;

  SyncResult({
    required this.success,
    required this.failed,
    required this.skipped,
  });

  int get total => success + failed + skipped;
  bool get hasFailures => failed > 0;
  bool get isComplete => failed == 0 && skipped == 0;

  @override
  String toString() {
    return 'SyncResult(success: $success, failed: $failed, skipped: $skipped)';
  }
}
