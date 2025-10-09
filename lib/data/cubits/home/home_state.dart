import 'package:equatable/equatable.dart';

import '../../models/book_model.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeEmpty extends HomeState {}

class HomeLoaded extends HomeState {
  final List<BookModel> books;
  final bool isFromCache;

  const HomeLoaded({required this.books, this.isFromCache = false});

  @override
  List<Object?> get props => [books, isFromCache];
}

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object?> get props => [message];
}

class HomeRedeeming extends HomeState {}

class HomeRedeemSuccess extends HomeState {
  final String message;

  const HomeRedeemSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class HomeRedeemError extends HomeState {
  final String message;

  const HomeRedeemError({required this.message});

  @override
  List<Object?> get props => [message];
}
