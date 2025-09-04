part of 'auth_cubit.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  final AuthStatus status;

  const AuthState({required this.status});

  const AuthState.initial() : status = AuthStatus.initial;

  AuthState copyWith({AuthStatus? status}) {
    return AuthState(status: status ?? this.status);
  }

  @override
  List<Object?> get props => [status];
}
