import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/canvas_model.dart';
import '../models/widget_model.dart';

class CanvasService {
  final ApiClient _apiClient = ApiClient.instance;

  // Get all canvases for current user
  Future<List<CanvasModel>> getCanvases() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.canvases);
      final data = response.data['data'] as List;
      return data.map((json) => CanvasModel.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e, 'Failed to fetch canvases');
    }
  }

  // Get canvas by ID
  Future<CanvasModel> getCanvasById(String canvasId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.canvasById(canvasId));
      return CanvasModel.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e, 'Failed to fetch canvas');
    }
  }

  // Create new canvas
  Future<CanvasModel> createCanvas({
    required String name,
    String? description,
    int? backgroundColor,
    bool isPublic = false,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.canvases,
        data: {
          'name': name,
          if (description != null) 'description': description,
          if (backgroundColor != null) 'background_color': backgroundColor,
          'is_public': isPublic,
        },
      );
      return CanvasModel.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e, 'Failed to create canvas');
    }
  }

  // Update canvas
  Future<CanvasModel> updateCanvas({
    required String canvasId,
    String? name,
    String? description,
    int? backgroundColor,
    bool? isPublic,
  }) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.canvasById(canvasId),
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (backgroundColor != null) 'background_color': backgroundColor,
          if (isPublic != null) 'is_public': isPublic,
        },
      );
      return CanvasModel.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e, 'Failed to update canvas');
    }
  }

  // Delete canvas
  Future<void> deleteCanvas(String canvasId) async {
    try {
      await _apiClient.delete(ApiEndpoints.canvasById(canvasId));
    } catch (e) {
      throw _handleError(e, 'Failed to delete canvas');
    }
  }

  // Get canvas collaborators
  Future<List<Collaborator>> getCollaborators(String canvasId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.canvasCollaborators(canvasId),
      );
      final data = response.data['data'] as List;
      return data.map((json) => Collaborator.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e, 'Failed to fetch collaborators');
    }
  }

  // Add collaborator
  Future<void> addCollaborator({
    required String canvasId,
    required String userEmail,
    String role = 'editor',
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.addCollaborator(canvasId),
        data: {'user_email': userEmail, 'role': role},
      );
    } catch (e) {
      throw _handleError(e, 'Failed to add collaborator');
    }
  }

  // Remove collaborator
  Future<void> removeCollaborator({
    required String canvasId,
    required String userId,
  }) async {
    try {
      await _apiClient.delete(
        ApiEndpoints.removeCollaborator(canvasId, userId),
      );
    } catch (e) {
      throw _handleError(e, 'Failed to remove collaborator');
    }
  }

  // Get widgets for canvas
  Future<List<WidgetModel>> getWidgets(String canvasId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.canvasWidgets(canvasId),
      );
      final data = response.data['data'] as List;
      return data.map((json) => WidgetModel.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e, 'Failed to fetch widgets');
    }
  }

  // Create widget
  Future<WidgetModel> createWidget({
    required String canvasId,
    required String type,
    required double x,
    required double y,
    required double width,
    required double height,
    int zIndex = 0,
    Map<String, dynamic>? properties,
  }) async {
    try {
      print('📤 Sending widget create request...');
      final requestData = {
        'type': type,
        'position': {'x': x, 'y': y, 'z_index': zIndex},
        'size': {
          'width': width,
          'height': height,
          'width_unit': 'px',
          'height_unit': 'px',
        },
        if (properties != null) 'properties': properties,
      };
      print('   Request data: $requestData');

      final response = await _apiClient.post(
        ApiEndpoints.canvasWidgets(canvasId),
        data: requestData,
      );

      print('📥 Response received:');
      print('   Status: ${response.statusCode}');
      print('   Data: ${response.data}');
      print('   response.data["data"]: ${response.data['data']}');

      final widget = WidgetModel.fromJson(response.data['data']);
      print('✅ Widget parsed successfully: ${widget.id}');

      return widget;
    } catch (e, stackTrace) {
      print('❌ Widget creation failed: $e');
      print('   Stack trace: $stackTrace');
      throw _handleError(e, 'Failed to create widget');
    }
  }

  // Update widget
  Future<WidgetModel> updateWidget({
    required String canvasId,
    required String widgetId,
    double? x,
    double? y,
    double? width,
    double? height,
    int? zIndex,
    Map<String, dynamic>? properties,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      // Build position object if any position field is provided
      if (x != null || y != null || zIndex != null) {
        data['position'] = {};
        if (x != null) data['position']['x'] = x;
        if (y != null) data['position']['y'] = y;
        if (zIndex != null) data['position']['z_index'] = zIndex;
      }

      // Build size object if any size field is provided
      if (width != null || height != null) {
        data['size'] = {};
        if (width != null) {
          data['size']['width'] = width;
          data['size']['width_unit'] = 'px';
        }
        if (height != null) {
          data['size']['height'] = height;
          data['size']['height_unit'] = 'px';
        }
      }

      // Add properties if provided
      if (properties != null) {
        data['properties'] = properties;
      }

      final response = await _apiClient.put(
        ApiEndpoints.widgetById(canvasId, widgetId),
        data: data,
      );
      return WidgetModel.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e, 'Failed to update widget');
    }
  }

  // Delete widget
  Future<void> deleteWidget({
    required String canvasId,
    required String widgetId,
  }) async {
    try {
      await _apiClient.delete(ApiEndpoints.widgetById(canvasId, widgetId));
    } catch (e) {
      throw _handleError(e, 'Failed to delete widget');
    }
  }

  // Batch update widgets
  Future<List<WidgetModel>> batchUpdateWidgets({
    required String canvasId,
    required List<Map<String, dynamic>> updates,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.batchUpdateWidgets(canvasId),
        data: {'updates': updates},
      );
      final data = response.data['data'] as List;
      return data.map((json) => WidgetModel.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e, 'Failed to batch update widgets');
    }
  }

  // Error handler
  CanvasException _handleError(dynamic error, String message) {
    if (error is ApiException) {
      return CanvasException(message: error.message, originalMessage: message);
    }
    return CanvasException(message: message, originalMessage: error.toString());
  }
}

// Canvas exception
class CanvasException implements Exception {
  final String message;
  final String originalMessage;

  CanvasException({required this.message, required this.originalMessage});

  @override
  String toString() => 'CanvasException: $message';
}
