import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/project.dart';
import '../models/page.dart' show PageListItem, PermissionType;

class ProjectService {
  final ApiClient _api = ApiClient.instance;

  static final ProjectService _instance = ProjectService._internal();
  ProjectService._internal();
  static ProjectService get instance => _instance;

  Future<List<ProjectListItem>> getUserProjects() async {
    final response = await _api.get(ApiEndpoints.projects);
    final List<dynamic> data = response.data['data'] as List<dynamic>;
    return data
        .map((j) => ProjectListItem.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<ProjectListItem> createProject({
    required String name,
    String? description,
  }) async {
    final response = await _api.post(
      ApiEndpoints.projects,
      data: {'name': name, if (description != null) 'description': description},
    );
    return ProjectListItem.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<ProjectListItem?> getProjectById(String projectId) async {
    final response = await _api.get(ApiEndpoints.projectById(projectId));
    if (response.data['data'] == null) return null;
    return ProjectListItem.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<ProjectListItem?> updateProject(
    String projectId, {
    String? name,
    String? description,
  }) async {
    final response = await _api.patch(
      ApiEndpoints.projectById(projectId),
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
      },
    );
    if (response.data['data'] == null) return null;
    return ProjectListItem.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteProject(String projectId) async {
    await _api.delete(ApiEndpoints.projectById(projectId));
  }

  Future<List<PageListItem>> getProjectPages(String projectId) async {
    final response = await _api.get(ApiEndpoints.projectPages(projectId));
    final List<dynamic> data = response.data['data'] as List<dynamic>;
    return data
        .map((j) => PageListItem.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProjectMember>> getMembers(String projectId) async {
    final response = await _api.get(ApiEndpoints.projectMembers(projectId));
    final List<dynamic> data = response.data['data'] as List<dynamic>;
    return data
        .map((j) => ProjectMember.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> addMember({
    required String projectId,
    required String email,
    PermissionType permissionType = PermissionType.edit,
  }) async {
    await _api.post(
      ApiEndpoints.projectMembers(projectId),
      data: {'email': email, 'permissionType': permissionType.name},
    );
  }

  Future<void> removeMember({
    required String projectId,
    required String userId,
  }) async {
    await _api.delete(ApiEndpoints.projectMemberById(projectId, userId));
  }
}
