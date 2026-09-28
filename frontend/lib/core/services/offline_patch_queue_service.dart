import 'dart:async';
import '../storage/storage_service.dart';
import '../api/page_websocket_client.dart';

/// Queues JSON-Patch operations that couldn't be sent because the page
/// socket was disconnected, and replays them once it reconnects.
///
/// This is a deliberately small, purpose-built replacement for the old
/// OfflineQueueService, which targeted REST widget endpoints
/// (`POST /api/pages/:id/widgets` etc.) that don't exist in this API. The
/// real protocol is a single socket event, `page:patch`, so this queue
/// stores exactly what that event needs -- pageId, the JSON Patch ops, and
/// the client version they were generated against -- and replays them
/// through PageWebSocketClient.sendPatch on reconnect.
///
/// Replay relies on the server's existing Operational Transformation path
/// (page.handler.js) to reconcile a stale clientVersion against whatever
/// landed while this client was offline. That only works if the server
/// still has the patches between clientVersion and its current version --
/// if the retention job (database/prune-old-patches.js) has pruned them, or
/// the client was offline long enough that this can't be reconciled, the
/// server responds with page:conflict and replay stops, leaving the rest of
/// the queue intact rather than guessing.
///
/// Delivery is at-least-once, not exactly-once: if the connection drops in
/// the narrow window after the server applies a patch but before its ack
/// reaches this client, replay will resend it on the next reconnect. There
/// is no dedupe for that case -- it's a known, accepted gap, not an
/// oversight.
class OfflinePatchQueueService {
  final StorageService _storage = StorageService.instance;

  static OfflinePatchQueueService? _instance;
  OfflinePatchQueueService._internal();
  static OfflinePatchQueueService get instance {
    _instance ??= OfflinePatchQueueService._internal();
    return _instance!;
  }

  bool _isReplaying = false;
  bool get isReplaying => _isReplaying;

  int get queueLength => _storage.getOperationQueueCount();

  /// Queue a patch batch for later replay.
  Future<void> enqueue({
    required String pageId,
    required List<Map<String, dynamic>> patches,
    required int clientVersion,
  }) async {
    await _storage.queueOperation({
      'kind': 'page_patch',
      'pageId': pageId,
      'patches': patches,
      'clientVersion': clientVersion,
    });
    print('📥 Queued offline patch for page $pageId (${patches.length} ops)');
  }

  /// Replay every queued patch for [pageId], in the order they were
  /// enqueued, over [wsClient]. Stops at the first failure (conflict, patch
  /// error, or ack timeout) so later patches -- which may assume the
  /// document state left by earlier ones -- aren't sent out of order.
  ///
  /// Returns the number of patches successfully replayed.
  Future<int> replay(String pageId, PageWebSocketClient wsClient) async {
    if (_isReplaying) return 0;
    _isReplaying = true;

    int replayed = 0;
    try {
      final entries = _storage.getQueuedOperationEntries()
        ..sort((a, b) => a.key.compareTo(b.key));

      for (final entry in entries) {
        final op = entry.value;
        if (op['pageId'] != pageId || op['kind'] != 'page_patch') continue;
        if (!wsClient.isConnected) break;

        final patches = List<Map<String, dynamic>>.from(
          (op['patches'] as List).map((p) => Map<String, dynamic>.from(p)),
        );
        final clientVersion = op['clientVersion'] as int;

        final ok = await _sendAndAwaitAck(
          wsClient,
          pageId: pageId,
          patches: patches,
          clientVersion: clientVersion,
        );

        if (!ok) {
          print('⚠️ Offline queue replay stopped for page $pageId');
          break;
        }

        await _storage.removeOperation(entry.key);
        replayed++;
      }
    } finally {
      _isReplaying = false;
    }

    if (replayed > 0) {
      print('✅ Replayed $replayed queued patch(es) for page $pageId');
    }
    return replayed;
  }

  Future<bool> _sendAndAwaitAck(
    PageWebSocketClient wsClient, {
    required String pageId,
    required List<Map<String, dynamic>> patches,
    required int clientVersion,
  }) async {
    final completer = Completer<bool>();
    final subs = <StreamSubscription>[];
    void finish(bool result) {
      if (!completer.isCompleted) completer.complete(result);
    }

    subs.add(wsClient.patchAppliedEvents.listen((_) => finish(true)));
    subs.add(wsClient.conflictEvents.listen((_) => finish(false)));
    subs.add(wsClient.patchErrorEvents.listen((_) => finish(false)));

    final sent = wsClient.sendPatch(
      pageId: pageId,
      patches: patches,
      clientVersion: clientVersion,
    );
    if (!sent) {
      for (final s in subs) {
        await s.cancel();
      }
      return false;
    }

    bool result;
    try {
      result = await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
    } finally {
      for (final s in subs) {
        await s.cancel();
      }
    }
    return result;
  }

  Future<void> clear() => _storage.clearOperationQueue();
}
