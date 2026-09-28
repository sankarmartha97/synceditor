import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'position_mode.dart';

part 'page.g.dart';

/// Permission types for page sharing
@HiveType(typeId: 2)
enum PermissionType {
  @HiveField(0)
  owner,

  @HiveField(1)
  edit,

  @HiveField(2)
  comment,

  @HiveField(3)
  view,
}

/// Page metadata
@HiveType(typeId: 3)
class PageMetadata {
  @HiveField(0)
  final double width;

  @HiveField(1)
  final double height;

  @HiveField(2)
  final String backgroundColor;

  @HiveField(3)
  final double gridSize;

  @HiveField(4)
  final bool showGrid;

  @HiveField(5)
  final bool snapToGrid;

  @HiveField(6)
  final double zoom;

  @HiveField(7)
  final String? createdAt;

  @HiveField(8)
  final String? updatedAt;

  PageMetadata({
    this.width = 2000,
    this.height = 2000,
    this.backgroundColor = '#FFFFFF',
    this.gridSize = 10,
    this.showGrid = true,
    this.snapToGrid = false,
    this.zoom = 1.0,
    this.createdAt,
    this.updatedAt,
  });

  factory PageMetadata.fromJson(Map<String, dynamic> json) {
    return PageMetadata(
      width: (json['width'] ?? 2000).toDouble(),
      height: (json['height'] ?? 2000).toDouble(),
      backgroundColor: json['backgroundColor'] ?? '#FFFFFF',
      gridSize: (json['gridSize'] ?? 10).toDouble(),
      showGrid: json['showGrid'] ?? true,
      snapToGrid: json['snapToGrid'] ?? false,
      zoom: (json['zoom'] ?? 1.0).toDouble(),
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'backgroundColor': backgroundColor,
      'gridSize': gridSize,
      'showGrid': showGrid,
      'snapToGrid': snapToGrid,
      'zoom': zoom,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  PageMetadata copyWith({
    double? width,
    double? height,
    String? backgroundColor,
    double? gridSize,
    bool? showGrid,
    bool? snapToGrid,
    double? zoom,
  }) {
    return PageMetadata(
      width: width ?? this.width,
      height: height ?? this.height,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gridSize: gridSize ?? this.gridSize,
      showGrid: showGrid ?? this.showGrid,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      zoom: zoom ?? this.zoom,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Widget in a page
@HiveType(typeId: 4)
class PageWidget {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final Offset position;

  @HiveField(3)
  final Size size;

  @HiveField(4)
  final Map<String, dynamic> properties;

  // ✨ NEW: Nesting support fields
  @HiveField(5)
  final String? parentId;

  @HiveField(6)
  final List<String> childrenIds;

  @HiveField(7)
  final bool isContainer;

  @HiveField(8)
  final int zIndex;

  @HiveField(9)
  final PositionMode positionMode;

  @HiveField(10)
  final bool isDefaultContainer; // ✨ NEW: Mark the top-level default container

  @HiveField(11)
  final String? createdAt;

  @HiveField(12)
  final String? createdBy;

  @HiveField(13)
  final String? updatedAt;

  @HiveField(14)
  final String? updatedBy;

  PageWidget({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    required this.properties,
    this.parentId,
    List<String>? childrenIds,
    bool? isContainer,
    this.zIndex = 0,
    this.positionMode = PositionMode.absolute,
    this.isDefaultContainer = false, // ✨ NEW: Default to false
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  }) : childrenIds = childrenIds ?? [],
       isContainer = isContainer ?? _isContainerType(type);

  // Helper to detect container types
  static bool _isContainerType(String type) {
    const containerTypes = ['Container', 'Card', 'Row', 'Column', 'Stack'];
    return containerTypes.contains(type);
  }

  factory PageWidget.fromJson(Map<String, dynamic> json) {
    final position = json['position'] as Map<String, dynamic>;
    final size = json['size'] as Map<String, dynamic>;

    return PageWidget(
      id: json['id'],
      type: json['type'],
      position: Offset(
        (position['x'] as num).toDouble(),
        (position['y'] as num).toDouble(),
      ),
      size: Size(
        (size['width'] as num).toDouble(),
        (size['height'] as num).toDouble(),
      ),
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      // ✨ NEW: Parse nesting fields
      parentId: json['parentId'],
      childrenIds: json['childrenIds'] != null
          ? List<String>.from(json['childrenIds'])
          : null,
      isContainer: json['isContainer'],
      zIndex: json['zIndex'] ?? 0,
      positionMode: PositionModeExtension.fromString(json['positionMode']),
      isDefaultContainer: json['isDefaultContainer'] ?? false, // ✨ NEW
      createdAt: json['createdAt'],
      createdBy: json['createdBy'],
      updatedAt: json['updatedAt'],
      updatedBy: json['updatedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'position': {'x': position.dx, 'y': position.dy},
      'size': {'width': size.width, 'height': size.height},
      'properties': properties,
      // ✨ NEW: Include nesting fields
      'parentId': parentId,
      'childrenIds': childrenIds,
      'isContainer': isContainer,
      'zIndex': zIndex,
      'positionMode': positionMode.toJsonString(),
      'isDefaultContainer': isDefaultContainer, // ✨ NEW
      if (createdAt != null) 'createdAt': createdAt,
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (updatedBy != null) 'updatedBy': updatedBy,
    };
  }

  PageWidget copyWith({
    String? id,
    String? type,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? parentId,
    List<String>? childrenIds,
    bool? isContainer,
    int? zIndex,
    PositionMode? positionMode,
    bool? isDefaultContainer, // ✨ NEW
    bool clearParent = false,
  }) {
    return PageWidget(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      // ✨ NEW: Copy nesting fields
      parentId: clearParent ? null : (parentId ?? this.parentId),
      childrenIds: childrenIds ?? this.childrenIds,
      isContainer: isContainer ?? this.isContainer,
      zIndex: zIndex ?? this.zIndex,
      positionMode: positionMode ?? this.positionMode,
      isDefaultContainer:
          isDefaultContainer ?? this.isDefaultContainer, // ✨ NEW
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }
}

/// Page data (single JSON document)
@HiveType(typeId: 5)
class PageData {
  @HiveField(0)
  final String pageId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int version;

  @HiveField(3)
  final PageMetadata metadata;

  // Keyed by widget id for O(1) lookup/update instead of a linear scan.
  // A plain Dart Map literal / fromEntries is insertion-ordered (LinkedHashMap
  // under the hood), and updating an existing key does NOT move it -- so
  // `.values` reproduces the same order as the wire-format JSON array this
  // was built from, which patch path indices (/widgets/<index>/...) rely on.
  @HiveField(4)
  final Map<String, PageWidget> widgets;

  PageData({
    required this.pageId,
    required this.name,
    required this.version,
    required this.metadata,
    required this.widgets,
  });

  /// Widgets in wire order -- use this wherever an index into the JSON Patch
  /// path space is needed (e.g. building a patch to send to the server).
  List<PageWidget> get widgetList => widgets.values.toList();

  factory PageData.fromJson(Map<String, dynamic> json) {
    final widgetList = (json['widgets'] as List?)
            ?.map((w) => PageWidget.fromJson(w))
            .toList() ??
        [];
    return PageData(
      pageId: json['pageId'] ?? '',
      name: json['name'] ?? '',
      version: json['version'] ?? 1,
      metadata: PageMetadata.fromJson(json['metadata'] ?? {}),
      widgets: {for (final w in widgetList) w.id: w},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pageId': pageId,
      'name': name,
      'version': version,
      'metadata': metadata.toJson(),
      'widgets': widgets.values.map((w) => w.toJson()).toList(),
    };
  }

  PageData copyWith({
    String? pageId,
    String? name,
    int? version,
    PageMetadata? metadata,
    Map<String, PageWidget>? widgets,
  }) {
    return PageData(
      pageId: pageId ?? this.pageId,
      name: name ?? this.name,
      version: version ?? this.version,
      metadata: metadata ?? this.metadata,
      widgets: widgets ?? this.widgets,
    );
  }
}

/// Complete page model
@HiveType(typeId: 6)
class PageModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String ownerId;

  @HiveField(3)
  final PageData pageData;

  @HiveField(4)
  final int version;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  @HiveField(7)
  final DateTime? deletedAt;

  PageModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.pageData,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      id: json['id'],
      name: json['name'],
      ownerId: json['ownerId'],
      pageData: PageData.fromJson(json['pageData']),
      version: json['version'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'pageData': pageData.toJson(),
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
    };
  }
}

/// Page list item (for dashboard)
class PageListItem {
  final String id;
  final String name;
  final String ownerId;
  final int version;
  final PermissionType permission;
  final DateTime updatedAt;
  final DateTime createdAt;

  PageListItem({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.version,
    required this.permission,
    required this.updatedAt,
    required this.createdAt,
  });

  factory PageListItem.fromJson(Map<String, dynamic> json) {
    return PageListItem(
      id: json['id'],
      name: json['name'],
      ownerId: json['ownerId'],
      version: json['version'],
      permission: _parsePermission(json['permission']),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static PermissionType _parsePermission(String permission) {
    switch (permission.toLowerCase()) {
      case 'owner':
        return PermissionType.owner;
      case 'edit':
        return PermissionType.edit;
      case 'comment':
        return PermissionType.comment;
      case 'view':
        return PermissionType.view;
      default:
        return PermissionType.view;
    }
  }

  bool get canEdit =>
      permission == PermissionType.owner || permission == PermissionType.edit;
  bool get isOwner => permission == PermissionType.owner;
}

/// Page permission
class PagePermission {
  final String id;
  final String pageId;
  final String userId;
  final PermissionType permissionType;
  final DateTime grantedAt;
  final String grantedBy;
  final DateTime updatedAt;
  final String? userName;
  final String? userEmail;

  PagePermission({
    required this.id,
    required this.pageId,
    required this.userId,
    required this.permissionType,
    required this.grantedAt,
    required this.grantedBy,
    required this.updatedAt,
    this.userName,
    this.userEmail,
  });

  factory PagePermission.fromJson(Map<String, dynamic> json) {
    return PagePermission(
      id: json['id'],
      pageId: json['page_id'],
      userId: json['user_id'],
      permissionType: PageListItem._parsePermission(json['permission_type']),
      grantedAt: DateTime.parse(json['granted_at']),
      grantedBy: json['granted_by'],
      updatedAt: DateTime.parse(json['updated_at']),
      userName: json['user_name'],
      userEmail: json['user_email'],
    );
  }
}
