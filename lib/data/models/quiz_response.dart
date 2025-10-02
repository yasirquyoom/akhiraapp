import 'package:akhira/data/models/book_content_response.dart';

class QuizResponse {
  final int status;
  final String message;
  final QuizData? data;

  const QuizResponse({required this.status, required this.message, this.data});

  factory QuizResponse.fromJson(Map<String, dynamic> json) {
    return QuizResponse(
      status: json['status'] as int,
      message: json['message'] as String,
      data: json['data'] != null ? QuizData.fromJson(json['data']) : null,
    );
  }
}

class QuizData {
  final BookDetails bookDetails;
  final List<Quiz> quizzes;
  final int total;
  final int skip;
  final int limit;

  const QuizData({
    required this.bookDetails,
    required this.quizzes,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory QuizData.fromJson(Map<String, dynamic> json) {
    return QuizData(
      bookDetails: BookDetails.fromJson(json['book_details']),
      quizzes:
          (json['quizzes'] as List<dynamic>)
              .map((quiz) => Quiz.fromJson(quiz))
              .toList(),
      total: json['total'] as int,
      skip: json['skip'] as int,
      limit: json['limit'] as int,
    );
  }
}

class Quiz {
  final String quizId;
  final String bookId;
  final String question;
  final String? option1;
  final String? option2;
  final String? option3;
  final String? option4;
  final String correctOption;
  final int marks;
  final int quizNumber;
  final String createdAt;
  final String? updatedAt;

  const Quiz({
    required this.quizId,
    required this.bookId,
    required this.question,
    this.option1,
    this.option2,
    this.option3,
    this.option4,
    required this.correctOption,
    required this.marks,
    required this.quizNumber,
    required this.createdAt,
    this.updatedAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      quizId: json['quiz_id'] as String,
      bookId: json['book_id'] as String,
      question: json['question'] as String,
      option1: json['option1'] as String?,
      option2: json['option2'] as String?,
      option3: json['option3'] as String?,
      option4: json['option4'] as String?,
      correctOption: json['correct_option'] as String,
      marks: json['marks'] as int,
      quizNumber: json['quiz_number'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
