import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/forgot_password_request.dart';
import '../../models/login_request.dart';
import '../../models/register_request.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(const AuthState.initial());

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final request = RegisterRequest(
        name: name,
        email: email,
        password: password,
      );

      final response = await _authRepository.register(request);

      if (response.status == 201) {
        emit(
          state.copyWith(
            status: AuthStatus.registerSuccess,
            message: response.message,
            user: response.data?.user,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            errorMessage: response.message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final request = LoginRequest(email: email, password: password);

      final response = await _authRepository.login(request);

      if (response.status == 200) {
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            message: response.message,
            user: response.data?.user,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            errorMessage: response.message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> forgotPassword({required String email}) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final request = ForgotPasswordRequest(email: email);

      final response = await _authRepository.forgotPassword(request);

      if (response.status == 200) {
        emit(
          state.copyWith(
            status: AuthStatus.forgotPasswordSuccess,
            message: response.message,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            errorMessage: response.message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      final user = await _authRepository.getCurrentUser();

      if (isLoggedIn && user != null) {
        emit(state.copyWith(status: AuthStatus.authenticated, user: user));
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  void clearError() {
    emit(
      state.copyWith(
        status: AuthStatus.initial,
        errorMessage: null,
        message: null,
      ),
    );
  }
}
