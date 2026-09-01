import 'package:equatable/equatable.dart';
import '../../../core/models/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  final String token;

  const AuthAuthenticated({
    required this.user,
    required this.token,
  });

  @override
  List<Object?> get props => [user, token];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  final AuthErrorType type;

  const AuthError({
    required this.message,
    required this.type,
  });

  @override
  List<Object?> get props => [message, type];
}

enum AuthErrorType {
  invalidCredentials,
  validationError,
  networkError,
  serverError,
  unknown,
}
