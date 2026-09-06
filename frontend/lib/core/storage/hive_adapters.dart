import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Custom Hive adapter for Flutter's Offset class
class OffsetAdapter extends TypeAdapter<Offset> {
  @override
  final int typeId = 100; // High number to avoid conflicts

  @override
  Offset read(BinaryReader reader) {
    final dx = reader.readDouble();
    final dy = reader.readDouble();
    return Offset(dx, dy);
  }

  @override
  void write(BinaryWriter writer, Offset obj) {
    writer.writeDouble(obj.dx);
    writer.writeDouble(obj.dy);
  }
}

/// Custom Hive adapter for Flutter's Size class
class SizeAdapter extends TypeAdapter<Size> {
  @override
  final int typeId = 101; // High number to avoid conflicts

  @override
  Size read(BinaryReader reader) {
    final width = reader.readDouble();
    final height = reader.readDouble();
    return Size(width, height);
  }

  @override
  void write(BinaryWriter writer, Size obj) {
    writer.writeDouble(obj.width);
    writer.writeDouble(obj.height);
  }
}

/// Custom Hive adapter for dynamic Map<String, dynamic>
/// This is needed for PageWidget properties
class DynamicMapAdapter extends TypeAdapter<Map<String, dynamic>> {
  @override
  final int typeId = 102;

  @override
  Map<String, dynamic> read(BinaryReader reader) {
    final length = reader.readInt();
    final map = <String, dynamic>{};
    
    for (var i = 0; i < length; i++) {
      final key = reader.readString();
      final value = reader.read(); // Read dynamic value
      map[key] = value;
    }
    
    return map;
  }

  @override
  void write(BinaryWriter writer, Map<String, dynamic> obj) {
    writer.writeInt(obj.length);
    
    for (final entry in obj.entries) {
      writer.writeString(entry.key);
      writer.write(entry.value); // Write dynamic value
    }
  }
}
