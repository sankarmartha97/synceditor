import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/remote_cursor.dart';

/// Manages remote cursor rendering and lifecycle
class CursorManager {
  final Map<String, dynamic> _cursors =
      {}; // Use dynamic to avoid web type issues
  final StreamController<Map<String, RemoteCursorData>>
  _cursorStreamController =
      StreamController<Map<String, RemoteCursorData>>.broadcast();

  Timer? _cleanupTimer;

  CursorManager() {
    // Start periodic cleanup of stale cursors
    _startCleanupTimer();
  }

  /// Stream of cursor updates
  Stream<Map<String, RemoteCursorData>> get cursorStream =>
      _cursorStreamController.stream;

  /// Get all active cursors
  Map<String, RemoteCursorData> get cursors {
    return Map<String, RemoteCursorData>.fromEntries(
      _cursors.entries
          .where((e) => e.value is RemoteCursorData)
          .map((e) => MapEntry(e.key, e.value as RemoteCursorData)),
    );
  }

  /// Update or add a cursor
  void updateCursor(RemoteCursorData cursor) {
    _cursors[cursor.userId] = cursor;
    _cursorStreamController.add(cursors);
  }

  /// Remove a cursor
  void removeCursor(String userId) {
    if (_cursors.remove(userId) != null) {
      _cursorStreamController.add(cursors);
    }
  }

  /// Clear all cursors
  void clearAll() {
    _cursors.clear();
    _cursorStreamController.add({});
  }

  /// Get cursor for specific user
  RemoteCursorData? getCursor(String userId) {
    final cursor = _cursors[userId];
    return cursor is RemoteCursorData ? cursor : null;
  }

  /// Check if user has an active cursor
  bool hasCursor(String userId) {
    return _cursors.containsKey(userId) && _cursors[userId] is RemoteCursorData;
  }

  /// Get count of active cursors
  int get cursorCount => _cursors.values.whereType<RemoteCursorData>().length;

  /// Start cleanup timer to remove stale cursors
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _cleanupStaleCursors();
    });
  }

  /// Remove cursors that haven't been updated in 30+ seconds
  void _cleanupStaleCursors() {
    final staleCursors = <String>[];

    _cursors.forEach((userId, cursor) {
      if (cursor is RemoteCursorData && cursor.isStale) {
        staleCursors.add(userId);
      }
    });

    if (staleCursors.isNotEmpty) {
      staleCursors.forEach(_cursors.remove);
      _cursorStreamController.add(cursors);
      print('🧹 Cleaned up ${staleCursors.length} stale cursor(s)');
    }
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _cursorStreamController.close();
    _cursors.clear();
  }
}

/// Widget that renders all remote cursors
class CursorOverlay extends StatelessWidget {
  final CursorManager cursorManager;
  final bool showAnimations;

  const CursorOverlay({
    Key? key,
    required this.cursorManager,
    this.showAnimations = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, RemoteCursorData>>(
      stream: cursorManager.cursorStream,
      initialData: cursorManager.cursors,
      builder: (context, snapshot) {
        final cursors = snapshot.data ?? {};

        if (cursors.isEmpty) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: cursors.values.map((cursor) {
            if (showAnimations) {
              return RemoteCursor(
                key: ValueKey(cursor.userId),
                userId: cursor.userId,
                userName: cursor.userName,
                userColor: cursor.userColor,
                position: cursor.position,
              );
            } else {
              return SimpleCursor(
                key: ValueKey(cursor.userId),
                userId: cursor.userId,
                userName: cursor.userName,
                userColor: cursor.userColor,
                position: cursor.position,
              );
            }
          }).toList(),
        );
      },
    );
  }
}
