import 'package:equatable/equatable.dart';
import 'user_model.dart';

class AuthResponse extends Equatable {
  final int status;
  final String message;
  final AuthData? data;

  const AuthResponse({required this.status, required this.message, this.data});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      status: json['status'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
    );
  }

  @override
  List<Object?> get props => [status, message, data];
}

class AuthData extends Equatable {
  final String? accessToken;
  final String? tokenType;
  final int? expiresIn;
  final User? user;
  final String? userId;
  final String? name;
  final String? email;
  final String? createdAt;

  const AuthData({
    this.accessToken,
    this.tokenType,
    this.expiresIn,
    this.user,
    this.userId,
    this.name,
    this.email,
    this.createdAt,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      accessToken: json['access_token'] as String?,
      tokenType: json['token_type'] as String?,
      expiresIn: json['expires_in'] as int?,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      userId: json['user']?['user_id'] as String?,
      name: json['user']?['name'] as String?,
      email: json['user']?['email'] as String?,
      createdAt: json['user']?['created_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    accessToken,
    tokenType,
    expiresIn,
    user,
    userId,
    name,
    email,
    createdAt,
  ];
}
