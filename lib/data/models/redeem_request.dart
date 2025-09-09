import 'package:equatable/equatable.dart';

class RedeemRequest extends Equatable {
  final String code;

  const RedeemRequest({required this.code});

  Map<String, dynamic> toJson() {
    return {'code': code};
  }

  @override
  List<Object?> get props => [code];
}
