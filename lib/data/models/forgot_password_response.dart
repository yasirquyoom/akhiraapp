import 'package:equatable/equatable.dart';

class ForgotPasswordResponse extends Equatable {
  final int status;
  final String message;
  final ForgotPasswordData? data;

  const ForgotPasswordResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      status: json['status'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      data:
          json['data'] != null
              ? ForgotPasswordData.fromJson(json['data'])
              : null,
    );
  }

  @override
  List<Object?> get props => [status, message, data];
}

class ForgotPasswordData extends Equatable {
  final String? resetLink;
  final bool? emailSent;
  final String? message;

  const ForgotPasswordData({this.resetLink, this.emailSent, this.message});

  factory ForgotPasswordData.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordData(
      resetLink: json['reset_link'] as String?,
      emailSent: json['email_sent'] as bool?,
      message: json['message'] as String?,
    );
  }

  @override
  List<Object?> get props => [resetLink, emailSent, message];
}
