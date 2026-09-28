// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PageMetadataAdapter extends TypeAdapter<PageMetadata> {
  @override
  final int typeId = 3;

  @override
  PageMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PageMetadata(
      width: fields[0] as double,
      height: fields[1] as double,
      backgroundColor: fields[2] as String,
      gridSize: fields[3] as double,
      showGrid: fields[4] as bool,
      snapToGrid: fields[5] as bool,
      zoom: fields[6] as double,
      createdAt: fields[7] as String?,
      updatedAt: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PageMetadata obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.width)
      ..writeByte(1)
      ..write(obj.height)
      ..writeByte(2)
      ..write(obj.backgroundColor)
      ..writeByte(3)
      ..write(obj.gridSize)
      ..writeByte(4)
      ..write(obj.showGrid)
      ..writeByte(5)
      ..write(obj.snapToGrid)
      ..writeByte(6)
      ..write(obj.zoom)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PageWidgetAdapter extends TypeAdapter<PageWidget> {
  @override
  final int typeId = 4;

  @override
  PageWidget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PageWidget(
      id: fields[0] as String,
      type: fields[1] as String,
      position: fields[2] as Offset,
      size: fields[3] as Size,
      properties: (fields[4] as Map).cast<String, dynamic>(),
      parentId: fields[5] as String?,
      childrenIds: (fields[6] as List?)?.cast<String>(),
      isContainer: fields[7] as bool?,
      zIndex: fields[8] as int,
      positionMode: fields[9] as PositionMode,
      isDefaultContainer: fields[10] as bool,
      createdAt: fields[11] as String?,
      createdBy: fields[12] as String?,
      updatedAt: fields[13] as String?,
      updatedBy: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PageWidget obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.position)
      ..writeByte(3)
      ..write(obj.size)
      ..writeByte(4)
      ..write(obj.properties)
      ..writeByte(5)
      ..write(obj.parentId)
      ..writeByte(6)
      ..write(obj.childrenIds)
      ..writeByte(7)
      ..write(obj.isContainer)
      ..writeByte(8)
      ..write(obj.zIndex)
      ..writeByte(9)
      ..write(obj.positionMode)
      ..writeByte(10)
      ..write(obj.isDefaultContainer)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.createdBy)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.updatedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageWidgetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PageDataAdapter extends TypeAdapter<PageData> {
  @override
  final int typeId = 5;

  @override
  PageData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PageData(
      pageId: fields[0] as String,
      name: fields[1] as String,
      version: fields[2] as int,
      metadata: fields[3] as PageMetadata,
      widgets: (fields[4] as Map).cast<String, PageWidget>(),
    );
  }

  @override
  void write(BinaryWriter writer, PageData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.pageId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.version)
      ..writeByte(3)
      ..write(obj.metadata)
      ..writeByte(4)
      ..write(obj.widgets);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PageModelAdapter extends TypeAdapter<PageModel> {
  @override
  final int typeId = 6;

  @override
  PageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PageModel(
      id: fields[0] as String,
      name: fields[1] as String,
      ownerId: fields[2] as String,
      pageData: fields[3] as PageData,
      version: fields[4] as int,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      deletedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PageModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.ownerId)
      ..writeByte(3)
      ..write(obj.pageData)
      ..writeByte(4)
      ..write(obj.version)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PermissionTypeAdapter extends TypeAdapter<PermissionType> {
  @override
  final int typeId = 2;

  @override
  PermissionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PermissionType.owner;
      case 1:
        return PermissionType.edit;
      case 2:
        return PermissionType.comment;
      case 3:
        return PermissionType.view;
      default:
        return PermissionType.owner;
    }
  }

  @override
  void write(BinaryWriter writer, PermissionType obj) {
    switch (obj) {
      case PermissionType.owner:
        writer.writeByte(0);
        break;
      case PermissionType.edit:
        writer.writeByte(1);
        break;
      case PermissionType.comment:
        writer.writeByte(2);
        break;
      case PermissionType.view:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermissionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
