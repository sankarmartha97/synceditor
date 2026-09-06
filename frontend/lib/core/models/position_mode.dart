import 'package:hive/hive.dart';

part 'position_mode.g.dart';

/// Position mode for widgets in the canvas
@HiveType(typeId: 7)
enum PositionMode {
  /// Position relative to canvas (absolute coordinates)
  @HiveField(0)
  absolute,

  /// Position relative to parent widget
  @HiveField(1)
  relative,

  /// Fixed position (doesn't move with parent)
  @HiveField(2)
  fixed,
}

/// Extension methods for PositionMode
extension PositionModeExtension on PositionMode {
  String toJsonString() {
    switch (this) {
      case PositionMode.absolute:
        return 'absolute';
      case PositionMode.relative:
        return 'relative';
      case PositionMode.fixed:
        return 'fixed';
    }
  }

  static PositionMode fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'absolute':
        return PositionMode.absolute;
      case 'relative':
        return PositionMode.relative;
      case 'fixed':
        return PositionMode.fixed;
      default:
        return PositionMode.absolute;
    }
  }
}
