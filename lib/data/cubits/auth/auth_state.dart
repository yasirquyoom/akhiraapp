part of 'auth_cubit.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  registerSuccess,
  loginSuccess,
  forgotPasswordSuccess,
  failure,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final String? message;
  final String? errorMessage;
  final User? user;

  const AuthState({
    required this.status,
    this.message,
    this.errorMessage,
    this.user,
  });

  const AuthState.initial()
    : status = AuthStatus.initial,
      message = null,
      errorMessage = null,
      user = null;

  AuthState copyWith({
    AuthStatus? status,
    String? message,
    String? errorMessage,
    User? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      message: message ?? this.message,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [status, message, errorMessage, user];
}
