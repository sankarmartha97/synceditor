// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_mode.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PositionModeAdapter extends TypeAdapter<PositionMode> {
  @override
  final int typeId = 7;

  @override
  PositionMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PositionMode.absolute;
      case 1:
        return PositionMode.relative;
      case 2:
        return PositionMode.fixed;
      default:
        return PositionMode.absolute;
    }
  }

  @override
  void write(BinaryWriter writer, PositionMode obj) {
    switch (obj) {
      case PositionMode.absolute:
        writer.writeByte(0);
        break;
      case PositionMode.relative:
        writer.writeByte(1);
        break;
      case PositionMode.fixed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PositionModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
