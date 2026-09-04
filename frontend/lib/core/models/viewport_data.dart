import 'package:equatable/equatable.dart';

/// Viewport data for follow feature
/// Represents a user's current view of the canvas
class ViewportData extends Equatable {
  final double scrollX;
  final double scrollY;
  final double zoom;
  final double centerX;
  final double centerY;
  final double width;
  final double height;
  final DateTime timestamp;

  const ViewportData({
    required this.scrollX,
    required this.scrollY,
    required this.zoom,
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.height,
    required this.timestamp,
  });

  /// Create from JSON
  factory ViewportData.fromJson(Map<String, dynamic> json) {
    return ViewportData(
      scrollX: (json['scrollX'] as num?)?.toDouble() ?? 0.0,
      scrollY: (json['scrollY'] as num?)?.toDouble() ?? 0.0,
      zoom: (json['zoom'] as num?)?.toDouble() ?? 1.0,
      centerX: (json['centerX'] as num?)?.toDouble() ?? 0.0,
      centerY: (json['centerY'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'scrollX': scrollX,
      'scrollY': scrollY,
      'zoom': zoom,
      'centerX': centerX,
      'centerY': centerY,
      'width': width,
      'height': height,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  ViewportData copyWith({
    double? scrollX,
    double? scrollY,
    double? zoom,
    double? centerX,
    double? centerY,
    double? width,
    double? height,
    DateTime? timestamp,
  }) {
    return ViewportData(
      scrollX: scrollX ?? this.scrollX,
      scrollY: scrollY ?? this.scrollY,
      zoom: zoom ?? this.zoom,
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      width: width ?? this.width,
      height: height ?? this.height,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
        scrollX,
        scrollY,
        zoom,
        centerX,
        centerY,
        width,
        height,
        timestamp,
      ];

  @override
  String toString() {
    return 'ViewportData(scroll: ($scrollX, $scrollY), zoom: $zoom, center: ($centerX, $centerY), size: ${width}x$height)';
  }
}
