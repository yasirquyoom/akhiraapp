import 'package:dio/dio.dart';
import '../api/endpoints.dart';
import '../helper/dio_client.dart';
import '../models/auth_response.dart';
import '../models/forgot_password_request.dart';
import '../models/forgot_password_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository(this._dioClient);

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dioClient.post(
        Endpoints.register,
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data!);

      // If registration is successful, save user data
      if (authResponse.status == 201 && authResponse.data != null) {
        final user = User(
          userId: authResponse.data!.userId!,
          name: authResponse.data!.name!,
          email: authResponse.data!.email!,
          createdAt: authResponse.data!.createdAt!,
        );
        await StorageService.saveUser(user);
      }

      return authResponse;
    } on DioException catch (e) {
      if (e.response?.data != null) {
        try {
          return AuthResponse.fromJson(e.response!.data);
        } catch (_) {
          return AuthResponse(
            status: e.response?.statusCode ?? 500,
            message: e.response?.data?['message'] ?? 'Registration failed',
          );
        }
      }
      throw Exception('Network error occurred');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dioClient.post(
        Endpoints.login,
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data!);

      // If login is successful, save auth data
      if (authResponse.status == 200 && authResponse.data != null) {
        final authData = authResponse.data!;

        // Save access token
        if (authData.accessToken != null) {
          await StorageService.saveAccessToken(authData.accessToken!);
          await _dioClient.updateAccessToken('Bearer ${authData.accessToken}');
        }

        // Save user data
        if (authData.user != null) {
          await StorageService.saveUser(authData.user!);
        }

        // Set logged in status
        await StorageService.setLoggedIn(true);
      }

      return authResponse;
    } on DioException catch (e) {
      if (e.response?.data != null) {
        try {
          return AuthResponse.fromJson(e.response!.data);
        } catch (_) {
          return AuthResponse(
            status: e.response?.statusCode ?? 500,
            message: e.response?.data?['message'] ?? 'Login failed',
          );
        }
      }
      throw Exception('Network error occurred');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<ForgotPasswordResponse> forgotPassword(
    ForgotPasswordRequest request,
  ) async {
    try {
      final response = await _dioClient.post(
        Endpoints.forgotPassword,
        data: request.toJson(),
      );

      return ForgotPasswordResponse.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.data != null) {
        try {
          return ForgotPasswordResponse.fromJson(e.response!.data);
        } catch (_) {
          return ForgotPasswordResponse(
            status: e.response?.statusCode ?? 500,
            message:
                e.response?.data?['message'] ?? 'Failed to send reset link',
          );
        }
      }
      throw Exception('Network error occurred');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<void> logout() async {
    await StorageService.clearAuthData();
    await _dioClient.updateAccessToken(null);
  }

  Future<bool> isLoggedIn() async {
    return await StorageService.isLoggedIn();
  }

  Future<User?> getCurrentUser() async {
    return await StorageService.getUser();
  }

  Future<String?> getAccessToken() async {
    return await StorageService.getAccessToken();
  }
}
