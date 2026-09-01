import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class CanvasModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final Color backgroundColor;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CanvasModel({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CanvasModel.fromJson(Map<String, dynamic> json) {
    return CanvasModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      ownerId: json['owner_id'] as String,
      backgroundColor: json['background_color'] != null
          ? Color(int.parse(json['background_color'].toString()))
          : const Color(0xFFF5F5F5),
      isPublic: json['is_public'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'owner_id': ownerId,
      'background_color': backgroundColor.value,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CanvasModel copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    Color? backgroundColor,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CanvasModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        ownerId,
        backgroundColor,
        isPublic,
        createdAt,
        updatedAt,
      ];
}

// Canvas collaborator model
class Collaborator extends Equatable {
  final String userId;
  final String userName;
  final String userEmail;
  final String role; // 'owner', 'editor', 'viewer'
  final DateTime addedAt;

  const Collaborator({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.addedAt,
  });

  factory Collaborator.fromJson(Map<String, dynamic> json) {
    return Collaborator(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userEmail: json['user_email'] as String,
      role: json['role'] as String,
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'role': role,
      'added_at': addedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [userId, userName, userEmail, role, addedAt];
}
