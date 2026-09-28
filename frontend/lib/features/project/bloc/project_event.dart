import 'package:equatable/equatable.dart';
import '../../../core/models/page.dart' show PermissionType;

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

class LoadProjects extends ProjectEvent {
  const LoadProjects();
}

class CreateProject extends ProjectEvent {
  final String name;
  final String? description;

  const CreateProject({required this.name, this.description});

  @override
  List<Object?> get props => [name, description];
}

class UpdateProject extends ProjectEvent {
  final String projectId;
  final String? name;
  final String? description;

  const UpdateProject({required this.projectId, this.name, this.description});

  @override
  List<Object?> get props => [projectId, name, description];
}

class DeleteProject extends ProjectEvent {
  final String projectId;

  const DeleteProject(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class LoadProjectPages extends ProjectEvent {
  final String projectId;

  const LoadProjectPages(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class LoadProjectMembers extends ProjectEvent {
  final String projectId;

  const LoadProjectMembers(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class AddProjectMember extends ProjectEvent {
  final String projectId;
  final String email;
  final PermissionType permissionType;

  const AddProjectMember({
    required this.projectId,
    required this.email,
    this.permissionType = PermissionType.edit,
  });

  @override
  List<Object?> get props => [projectId, email, permissionType];
}

class RemoveProjectMember extends ProjectEvent {
  final String projectId;
  final String userId;

  const RemoveProjectMember({required this.projectId, required this.userId});

  @override
  List<Object?> get props => [projectId, userId];
}
