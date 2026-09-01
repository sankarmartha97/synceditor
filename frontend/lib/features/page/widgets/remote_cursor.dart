import 'package:flutter/material.dart';

/// Widget that displays a remote user's cursor position
/// Shows a colored dot with the user's name
class RemoteCursor extends StatefulWidget {
  final String userId;
  final String userName;
  final Color userColor;
  final Offset position;
  final bool isAnimated;

  const RemoteCursor({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userColor,
    required this.position,
    this.isAnimated = true,
  }) : super(key: key);

  @override
  State<RemoteCursor> createState() => _RemoteCursorState();
}

class _RemoteCursorState extends State<RemoteCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _positionAnimation;
  Offset _currentPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.position;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _positionAnimation = Tween<Offset>(
      begin: _currentPosition,
      end: widget.position,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(RemoteCursor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.position != widget.position && widget.isAnimated) {
      // Animate to new position
      _positionAnimation = Tween<Offset>(
        begin: _currentPosition,
        end: widget.position,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));

      _animationController.forward(from: 0.0).then((_) {
        setState(() {
          _currentPosition = widget.position;
        });
      });
    } else if (!widget.isAnimated) {
      _currentPosition = widget.position;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _positionAnimation,
      builder: (context, child) {
        final displayPosition =
            widget.isAnimated ? _positionAnimation.value : _currentPosition;

        return Positioned(
          left: displayPosition.dx,
          top: displayPosition.dy,
          child: _buildCursorWidget(),
        );
      },
    );
  }

  Widget _buildCursorWidget() {
    return IgnorePointer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cursor dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: widget.userColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // User name label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: widget.userColor,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              widget.userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple cursor indicator without animation (for performance)
class SimpleCursor extends StatelessWidget {
  final String userId;
  final String userName;
  final Color userColor;
  final Offset position;

  const SimpleCursor({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userColor,
    required this.position,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: IgnorePointer(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: userColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Model for remote cursor data
class RemoteCursorData {
  final String userId;
  final String userName;
  final Color userColor;
  final Offset position;
  final DateTime timestamp;

  RemoteCursorData({
    required this.userId,
    required this.userName,
    required this.userColor,
    required this.position,
    required this.timestamp,
  });

  RemoteCursorData copyWith({
    String? userId,
    String? userName,
    Color? userColor,
    Offset? position,
    DateTime? timestamp,
  }) {
    return RemoteCursorData(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userColor: userColor ?? this.userColor,
      position: position ?? this.position,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Check if cursor is stale (not updated in last 30 seconds)
  bool get isStale {
    return DateTime.now().difference(timestamp).inSeconds > 30;
  }

  /// Parse color from hex string
  static Color parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.blue; // Default color
    }
  }

  /// Create from WebSocket data
  factory RemoteCursorData.fromJson(Map<String, dynamic> json) {
    return RemoteCursorData(
      userId: json['userId'] as String,
      userName: json['userName'] as String? ?? 'Unknown',
      userColor: parseColor(json['userColor'] as String? ?? '#3B82F6'),
      position: Offset(
        (json['position']['x'] as num?)?.toDouble() ?? 0.0,
        (json['position']['y'] as num?)?.toDouble() ?? 0.0,
      ),
      timestamp: DateTime.parse(
        json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userColor': '#${userColor.value.toRadixString(16).substring(2)}',
      'position': {
        'x': position.dx,
        'y': position.dy,
      },
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'RemoteCursorData(userId: $userId, userName: $userName, position: $position)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RemoteCursorData &&
        other.userId == userId &&
        other.userName == userName &&
        other.userColor == userColor &&
        other.position == position;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        userName.hashCode ^
        userColor.hashCode ^
        position.hashCode;
  }
}
