import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class WidgetModel extends Equatable {
  final String id;
  final String canvasId;
  final String type;
  final double x;
  final double y;
  final double width;
  final double height;
  final int zIndex;
  final Map<String, dynamic> properties;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WidgetModel({
    required this.id,
    required this.canvasId,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.zIndex = 0,
    this.properties = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory WidgetModel.fromJson(Map<String, dynamic> json) {
    try {
      // Handle nested position/size format from backend
      final position = json['position'] as Map<String, dynamic>?;
      final size = json['size'] as Map<String, dynamic>?;

      print('🔍 Parsing WidgetModel.fromJson:');
      print('   json keys: ${json.keys.toList()}');
      print('   id: ${json['id']}');
      print('   position: $position');
      print('   size: $size');

      return WidgetModel(
        id: json['id'] as String,
        canvasId: json['canvas_id'] as String,
        type: json['type'] as String,
        x: position != null
            ? (position['x'] as num).toDouble()
            : (json['x'] as num?)?.toDouble() ?? 0.0,
        y: position != null
            ? (position['y'] as num).toDouble()
            : (json['y'] as num?)?.toDouble() ?? 0.0,
        width: size != null
            ? (size['width'] as num).toDouble()
            : (json['width'] as num?)?.toDouble() ?? 100.0,
        height: size != null
            ? (size['height'] as num).toDouble()
            : (json['height'] as num?)?.toDouble() ?? 100.0,
        zIndex: position != null
            ? (position['z_index'] as int? ?? 0)
            : (json['z_index'] as int? ?? 0),
        properties: json['properties'] as Map<String, dynamic>? ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
    } catch (e, stackTrace) {
      print('❌ WidgetModel.fromJson failed!');
      print('   Error: $e');
      print('   JSON: $json');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'canvas_id': canvasId,
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'z_index': zIndex,
      'properties': properties,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Convert to/from CanvasWidget (our local model)
  Offset get position => Offset(x, y);
  Size get size => Size(width, height);

  Color get backgroundColor {
    if (properties['backgroundColor'] != null) {
      return Color(properties['backgroundColor'] as int);
    }
    return Colors.grey[300]!;
  }

  String? get text => properties['text'] as String?;

  WidgetModel copyWith({
    String? id,
    String? canvasId,
    String? type,
    double? x,
    double? y,
    double? width,
    double? height,
    int? zIndex,
    Map<String, dynamic>? properties,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WidgetModel(
      id: id ?? this.id,
      canvasId: canvasId ?? this.canvasId,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      zIndex: zIndex ?? this.zIndex,
      properties: properties ?? this.properties,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    canvasId,
    type,
    x,
    y,
    width,
    height,
    zIndex,
    properties,
    createdAt,
    updatedAt,
  ];
}

// Helper class to create widget from local CanvasWidget
extension WidgetModelExtension on WidgetModel {
  static WidgetModel fromCanvasWidget({
    required String id,
    required String canvasId,
    required String type,
    required Offset position,
    required Size size,
    required Color backgroundColor,
    String? text,
    int zIndex = 0,
  }) {
    return WidgetModel(
      id: id,
      canvasId: canvasId,
      type: type,
      x: position.dx,
      y: position.dy,
      width: size.width,
      height: size.height,
      zIndex: zIndex,
      properties: {
        'backgroundColor': backgroundColor.value,
        if (text != null) 'text': text,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
