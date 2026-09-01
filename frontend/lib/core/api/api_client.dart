import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'endpoints.dart';

class ApiClient {
  late final Dio _dio;
  static ApiClient? _instance;
  String? _authToken;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          print('🌐 ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('❌ ${error.response?.statusCode} ${error.requestOptions.path}');
          print('   Error: ${error.message}');
          
          // Handle 401 Unauthorized - token expired
          if (error.response?.statusCode == 401) {
            await _handleUnauthorized();
          }
          
          return handler.next(error);
        },
      ),
    );

    // Load stored token
    _loadToken();
  }

  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
      if (_authToken != null) {
        print('🔑 Auth token loaded from storage');
      }
    } catch (e) {
      print('⚠️ Failed to load auth token: $e');
    }
  }

  Future<void> setAuthToken(String token) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('🔑 Auth token saved to storage');
    } catch (e) {
      print('⚠️ Failed to save auth token: $e');
    }
  }

  Future<void> clearAuthToken() async {
    _authToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      print('🔑 Auth token cleared from storage');
    } catch (e) {
      print('⚠️ Failed to clear auth token: $e');
    }
  }

  Future<void> _handleUnauthorized() async {
    await clearAuthToken();
    // TODO: Navigate to login screen
    print('🚫 Unauthorized - token cleared');
  }

  String? get authToken => _authToken;
  bool get isAuthenticated => _authToken != null;

  // GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handler
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          statusCode: 0,
          type: ApiExceptionType.timeout,
        );
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final message = error.response?.data?['message'] ?? 
                       error.response?.data?['error'] ?? 
                       'Something went wrong';
        
        return ApiException(
          message: message,
          statusCode: statusCode,
          type: _getExceptionType(statusCode),
          data: error.response?.data,
        );
      
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request cancelled',
          statusCode: 0,
          type: ApiExceptionType.cancel,
        );
      
      default:
        return ApiException(
          message: error.message ?? 'Network error occurred',
          statusCode: 0,
          type: ApiExceptionType.network,
        );
    }
  }

  ApiExceptionType _getExceptionType(int statusCode) {
    if (statusCode >= 500) return ApiExceptionType.server;
    if (statusCode == 401) return ApiExceptionType.unauthorized;
    if (statusCode == 403) return ApiExceptionType.forbidden;
    if (statusCode == 404) return ApiExceptionType.notFound;
    if (statusCode >= 400) return ApiExceptionType.badRequest;
    return ApiExceptionType.unknown;
  }
}

// Custom exception class
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final ApiExceptionType type;
  final dynamic data;

  ApiException({
    required this.message,
    required this.statusCode,
    required this.type,
    this.data,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

enum ApiExceptionType {
  timeout,
  unauthorized,
  forbidden,
  notFound,
  badRequest,
  server,
  network,
  cancel,
  unknown,
}
