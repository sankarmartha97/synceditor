// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectListItemAdapter extends TypeAdapter<ProjectListItem> {
  @override
  final int typeId = 8;

  @override
  ProjectListItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectListItem(
      id: fields[0] as String,
      name: fields[1] as String,
      ownerId: fields[2] as String,
      description: fields[3] as String?,
      permission: fields[4] as PermissionType,
      updatedAt: fields[5] as DateTime,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectListItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.ownerId)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.permission)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectListItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProjectMemberAdapter extends TypeAdapter<ProjectMember> {
  @override
  final int typeId = 9;

  @override
  ProjectMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectMember(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      avatarUrl: fields[3] as String?,
      permission: fields[4] as PermissionType,
      grantedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectMember obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.avatarUrl)
      ..writeByte(4)
      ..write(obj.permission)
      ..writeByte(5)
      ..write(obj.grantedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
