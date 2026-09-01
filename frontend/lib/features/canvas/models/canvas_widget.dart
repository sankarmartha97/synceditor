import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CanvasWidget {
  final String id;
  final String type;
  final Offset position;
  final Size size;
  final Color backgroundColor;
  final String? text;
  final double borderRadius;
  final double opacity;
  final double rotation; // in degrees
  final int zIndex; // for layer ordering

  CanvasWidget({
    String? id,
    required this.type,
    required this.position,
    required this.size,
    required this.backgroundColor,
    this.text,
    this.borderRadius = 8.0,
    this.opacity = 1.0,
    this.rotation = 0.0,
    this.zIndex = 0,
  }) : id = id ?? const Uuid().v4();

  CanvasWidget copyWith({
    Offset? position,
    Size? size,
    Color? backgroundColor,
    String? text,
    double? borderRadius,
    double? opacity,
    double? rotation,
    int? zIndex,
  }) {
    return CanvasWidget(
      id: id,
      type: type,
      position: position ?? this.position,
      size: size ?? this.size,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      text: text ?? this.text,
      borderRadius: borderRadius ?? this.borderRadius,
      opacity: opacity ?? this.opacity,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CanvasWidget && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
