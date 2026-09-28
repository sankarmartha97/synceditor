import 'package:hive/hive.dart';
import 'page.dart' show PermissionType;

part 'project.g.dart';

@HiveType(typeId: 8)
class ProjectListItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String ownerId;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final PermissionType permission;

  @HiveField(5)
  final DateTime updatedAt;

  @HiveField(6)
  final DateTime createdAt;

  ProjectListItem({
    required this.id,
    required this.name,
    required this.ownerId,
    this.description,
    required this.permission,
    required this.updatedAt,
    required this.createdAt,
  });

  bool get isOwner => permission == PermissionType.owner;
  bool get canEdit =>
      permission == PermissionType.owner || permission == PermissionType.edit;

  factory ProjectListItem.fromJson(Map<String, dynamic> json) {
    return ProjectListItem(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['ownerId'] as String,
      description: json['description'] as String?,
      permission: _permissionFromString(json['permission'] as String? ?? 'view'),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ownerId': ownerId,
    'description': description,
    'permission': permission.name,
    'updatedAt': updatedAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };
}

@HiveType(typeId: 9)
class ProjectMember extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String? avatarUrl;

  @HiveField(4)
  final PermissionType permission;

  @HiveField(5)
  final DateTime grantedAt;

  ProjectMember({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.permission,
    required this.grantedAt,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      permission: _permissionFromString(json['permission'] as String? ?? 'view'),
      grantedAt: DateTime.parse(json['grantedAt'] as String),
    );
  }
}

PermissionType _permissionFromString(String value) {
  switch (value) {
    case 'owner':   return PermissionType.owner;
    case 'edit':    return PermissionType.edit;
    case 'comment': return PermissionType.comment;
    default:        return PermissionType.view;
  }
}
