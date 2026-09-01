import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/api/api_client.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final ApiClient _apiClient = ApiClient.instance;

  AuthBloc({AuthService? authService})
    : _authService = authService ?? AuthService(),
      super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    try {
      final isAuthenticated = await _authService.loadSavedAuth();

      if (isAuthenticated && _authService.currentUser != null) {
        emit(
          AuthAuthenticated(
            user: _authService.currentUser!,
            token: _apiClient.authToken!,
          ),
        );
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      print('⚠️ App start auth check failed: $e');
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final authResponse = await _authService.login(
        email: event.email,
        password: event.password,
      );

      emit(
        AuthAuthenticated(user: authResponse.user, token: authResponse.token),
      );
    } on AuthException catch (e) {
      emit(AuthError(message: e.message, type: _mapAuthExceptionType(e.type)));
    } catch (e) {
      emit(
        const AuthError(
          message: 'An unexpected error occurred',
          type: AuthErrorType.unknown,
        ),
      );
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final authResponse = await _authService.register(
        email: event.email,
        password: event.password,
        name: event.name,
      );

      emit(
        AuthAuthenticated(user: authResponse.user, token: authResponse.token),
      );
    } on AuthException catch (e) {
      emit(AuthError(message: e.message, type: _mapAuthExceptionType(e.type)));
    } catch (e) {
      emit(
        const AuthError(
          message: 'An unexpected error occurred',
          type: AuthErrorType.unknown,
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authService.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      // Even if logout fails, we should unauthenticate locally
      print('⚠️ Logout error: $e');
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (_authService.isAuthenticated && _authService.currentUser != null) {
        // Verify with server
        final user = await _authService.getCurrentUser();

        emit(AuthAuthenticated(user: user, token: _apiClient.authToken!));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      print('⚠️ Auth status check failed: $e');
      emit(const AuthUnauthenticated());
    }
  }

  AuthErrorType _mapAuthExceptionType(AuthExceptionType type) {
    switch (type) {
      case AuthExceptionType.invalidCredentials:
        return AuthErrorType.invalidCredentials;
      case AuthExceptionType.validationError:
        return AuthErrorType.validationError;
      case AuthExceptionType.networkError:
        return AuthErrorType.networkError;
      case AuthExceptionType.serverError:
        return AuthErrorType.serverError;
      case AuthExceptionType.unknown:
        return AuthErrorType.unknown;
    }
  }
}
