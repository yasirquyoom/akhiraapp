import 'package:equatable/equatable.dart';

class ForgotPasswordRequest extends Equatable {
  final String email;

  const ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }

  @override
  List<Object?> get props => [email];
}
