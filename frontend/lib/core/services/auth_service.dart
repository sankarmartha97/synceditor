import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../api/websocket_client.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient.instance;
  final WebSocketClient _wsClient = WebSocketClient.instance;

  static const String _userKey = 'current_user';
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isAuthenticated =>
      _currentUser != null && _apiClient.isAuthenticated;

  // Register new user
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: {'email': email, 'password': password, 'name': name},
      );

      final authResponse = AuthResponse.fromJson(response.data['data']);

      // Save token and user
      await _saveAuthData(authResponse);

      return authResponse;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Login user
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      print('🔍 Login response: ${response.data}');
      final authResponse = AuthResponse.fromJson(response.data['data']);

      // Save token and user
      await _saveAuthData(authResponse);

      print('✅ Login successful, auth data saved');
      return authResponse;
    } catch (e) {
      print('❌ Login error: $e');
      throw _handleAuthError(e);
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      // Call logout endpoint
      await _apiClient.post(ApiEndpoints.logout);
    } catch (e) {
      print('⚠️ Logout endpoint error: $e');
      // Continue with local logout even if API call fails
    } finally {
      // Disconnect WebSocket
      _wsClient.disconnect();

      // Clear local auth data
      await _clearAuthData();
    }
  }

  // Get current user from server
  Future<User> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.currentUser);
      final user = User.fromJson(response.data['data']);

      _currentUser = user;
      await _saveUser(user);

      return user;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Load saved auth data on app start
  Future<bool> loadSavedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson == null || !_apiClient.isAuthenticated) {
        return false;
      }

      // Try to get current user from server to verify token
      try {
        _currentUser = await getCurrentUser();

        // Connect WebSocket if authenticated
        _wsClient.connect();

        return true;
      } catch (e) {
        // Token expired or invalid
        await _clearAuthData();
        return false;
      }
    } catch (e) {
      print('⚠️ Failed to load saved auth: $e');
      return false;
    }
  }

  // Save auth data
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    // Save token
    await _apiClient.setAuthToken(authResponse.token);

    // Save user
    _currentUser = authResponse.user;
    await _saveUser(authResponse.user);

    // Connect WebSocket
    _wsClient.connect();

    print('✅ Auth data saved');
  }

  // Save user to storage
  Future<void> _saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, user.toJson().toString());
    } catch (e) {
      print('⚠️ Failed to save user: $e');
    }
  }

  // Clear auth data
  Future<void> _clearAuthData() async {
    _currentUser = null;
    await _apiClient.clearAuthToken();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      print('⚠️ Failed to clear user data: $e');
    }

    print('✅ Auth data cleared');
  }

  // Handle auth errors
  AuthException _handleAuthError(dynamic error) {
    if (error is ApiException) {
      switch (error.type) {
        case ApiExceptionType.unauthorized:
          return AuthException(
            message: 'Invalid credentials',
            type: AuthExceptionType.invalidCredentials,
          );
        case ApiExceptionType.badRequest:
          return AuthException(
            message: error.message,
            type: AuthExceptionType.validationError,
          );
        case ApiExceptionType.timeout:
          return AuthException(
            message: 'Connection timeout',
            type: AuthExceptionType.networkError,
          );
        default:
          return AuthException(
            message: error.message,
            type: AuthExceptionType.serverError,
          );
      }
    }

    return AuthException(
      message: 'An unexpected error occurred',
      type: AuthExceptionType.unknown,
    );
  }
}

// Auth exception
class AuthException implements Exception {
  final String message;
  final AuthExceptionType type;

  AuthException({required this.message, required this.type});

  @override
  String toString() => 'AuthException: $message';
}

enum AuthExceptionType {
  invalidCredentials,
  validationError,
  networkError,
  serverError,
  unknown,
}
