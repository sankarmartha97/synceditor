import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/page.dart';

class PageService {
  final ApiClient _apiClient;

  PageService(this._apiClient);

  /// Create a new page
  Future<PageModel> createPage({
    required String name,
    PageMetadata? metadata,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.pages,
        data: {
          'name': name,
          if (metadata != null) 'metadata': metadata.toJson(),
        },
      );

      return PageModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to create page: $e');
    }
  }

  /// Get all pages accessible to user
  Future<List<PageListItem>> getUserPages() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.pages);

      final List<dynamic> pages = response.data['data'];
      return pages.map((page) => PageListItem.fromJson(page)).toList();
    } catch (e) {
      throw Exception('Failed to get pages: $e');
    }
  }

  /// Get specific page by ID
  Future<PageModel> getPageById(String pageId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.pageById(pageId));

      return PageModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to get page: $e');
    }
  }

  /// Update page
  Future<PageModel> updatePage(
    String pageId, {
    String? name,
    PageData? pageData,
  }) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.pageById(pageId),
        data: {
          if (name != null) 'name': name,
          if (pageData != null) 'pageData': pageData.toJson(),
        },
      );

      return PageModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to update page: $e');
    }
  }

  /// Delete page
  Future<void> deletePage(String pageId) async {
    try {
      await _apiClient.delete(ApiEndpoints.pageById(pageId));
    } catch (e) {
      throw Exception('Failed to delete page: $e');
    }
  }

  /// Rename page
  Future<PageModel> renamePage(String pageId, String newName) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.pageName(pageId),
        data: {'name': newName},
      );

      return PageModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to rename page: $e');
    }
  }

  /// Share page with another user
  Future<PagePermission> sharePage({
    required String pageId,
    required String email,
    required PermissionType permissionType,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.pageShare(pageId),
        data: {'email': email, 'permissionType': permissionType.name},
      );

      return PagePermission.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to share page: $e');
    }
  }

  /// Get page permissions
  Future<List<PagePermission>> getPagePermissions(String pageId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.pagePermissions(pageId),
      );

      final List<dynamic> permissions = response.data['data'];
      return permissions.map((perm) => PagePermission.fromJson(perm)).toList();
    } catch (e) {
      throw Exception('Failed to get permissions: $e');
    }
  }

  /// Update user permission
  Future<PagePermission> updatePermission({
    required String pageId,
    required String userId,
    required PermissionType permissionType,
  }) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.pagePermissionForUser(pageId, userId),
        data: {'permissionType': permissionType.name},
      );

      return PagePermission.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to update permission: $e');
    }
  }

  /// Revoke user access
  Future<void> revokeAccess({
    required String pageId,
    required String userId,
  }) async {
    try {
      await _apiClient.delete(
        ApiEndpoints.pagePermissionForUser(pageId, userId),
      );
    } catch (e) {
      throw Exception('Failed to revoke access: $e');
    }
  }
}
