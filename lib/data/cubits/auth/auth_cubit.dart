import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState.initial());

  Future<void> login({required String email, required String password}) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      // TODO: Call auth API via DI
      await Future.delayed(const Duration(milliseconds: 600));
      emit(state.copyWith(status: AuthStatus.authenticated));
    } catch (_) {
      emit(state.copyWith(status: AuthStatus.failure));
    }
  }

  void logout() {
    emit(state.copyWith(status: AuthStatus.unauthenticated));
  }
}
