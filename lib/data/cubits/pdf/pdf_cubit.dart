import 'package:akhira/data/models/pdf_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// States
abstract class PdfState extends Equatable {
  const PdfState();

  @override
  List<Object?> get props => [];
}

class PdfInitial extends PdfState {}

class PdfLoading extends PdfState {}

class PdfLoaded extends PdfState {
  final PdfModel pdf;

  const PdfLoaded({required this.pdf});

  @override
  List<Object?> get props => [pdf];
}

class PdfError extends PdfState {
  final String message;

  const PdfError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Cubit
class PdfCubit extends Cubit<PdfState> {
  PdfCubit() : super(PdfInitial()) {
    _loadPdf();
  }

  void _loadPdf() {
    emit(PdfLoading());

    // Sample PDF - using a reliable PDF URL
    const pdf = PdfModel(
      pdfUrl:
          'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    );

    emit(PdfLoaded(pdf: pdf));
  }

  void reloadPdf() {
    _loadPdf();
  }
}
