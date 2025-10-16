import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../repositories/quiz_repository.dart';
import '../../models/quiz_response.dart';

// Quiz Models
class QuizQuestion extends Equatable {
  final String id;
  final String question;
  final List<QuizOption> options;
  final String correctAnswerId;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerId,
  });

  @override
  List<Object?> get props => [id, question, options, correctAnswerId];
}

class QuizOption extends Equatable {
  final String id;
  final String text;
  final String letter; // A, B, C, D

  const QuizOption({
    required this.id,
    required this.text,
    required this.letter,
  });

  @override
  List<Object?> get props => [id, text, letter];
}

class QuizAnswer extends Equatable {
  final String questionId;
  final String selectedOptionId;
  final bool isCorrect;
  final DateTime answeredAt;

  const QuizAnswer({
    required this.questionId,
    required this.selectedOptionId,
    required this.isCorrect,
    required this.answeredAt,
  });

  @override
  List<Object?> get props => [
    questionId,
    selectedOptionId,
    isCorrect,
    answeredAt,
  ];
}

// States
abstract class QuizState extends Equatable {
  const QuizState();

  @override
  List<Object?> get props => [];
}

class QuizInitial extends QuizState {}

class QuizLoading extends QuizState {}

class QuizLoaded extends QuizState {
  final List<QuizQuestion> questions;
  final List<Quiz>
  originalQuizzes; // Store original quiz data with is_attempted field
  final int currentQuestionIndex;
  final List<QuizAnswer> answers;
  final String? selectedOptionId;
  final int score;
  final int totalAttempted;
  final int totalPossibleMarks;
  final int marksEarned;
  final double percentage;
  final int remainingQuestions;
  final int totalQuestionsFromApi;
  final bool isSubmitting; // submitting an answer
  final bool isResetting; // resetting all answers

  const QuizLoaded({
    required this.questions,
    this.originalQuizzes = const [],
    this.currentQuestionIndex = 0,
    this.answers = const [],
    this.selectedOptionId,
    this.score = 0,
    this.totalAttempted = 0,
    this.totalPossibleMarks = 0,
    this.marksEarned = 0,
    this.percentage = 0,
    this.remainingQuestions = 0,
    this.totalQuestionsFromApi = 0,
    this.isSubmitting = false,
    this.isResetting = false,
  });

  QuizLoaded copyWith({
    List<QuizQuestion>? questions,
    List<Quiz>? originalQuizzes,
    int? currentQuestionIndex,
    List<QuizAnswer>? answers,
    String? selectedOptionId,
    int? score,
    int? totalAttempted,
    int? totalPossibleMarks,
    int? marksEarned,
    double? percentage,
    int? remainingQuestions,
    int? totalQuestionsFromApi,
    bool? isSubmitting,
    bool? isResetting,
  }) {
    return QuizLoaded(
      questions: questions ?? this.questions,
      originalQuizzes: originalQuizzes ?? this.originalQuizzes,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      score: score ?? this.score,
      totalAttempted: totalAttempted ?? this.totalAttempted,
      totalPossibleMarks: totalPossibleMarks ?? this.totalPossibleMarks,
      marksEarned: marksEarned ?? this.marksEarned,
      percentage: percentage ?? this.percentage,
      remainingQuestions: remainingQuestions ?? this.remainingQuestions,
      totalQuestionsFromApi:
          totalQuestionsFromApi ?? this.totalQuestionsFromApi,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isResetting: isResetting ?? this.isResetting,
    );
  }

  QuizQuestion get currentQuestion => questions[currentQuestionIndex];
  bool get isLastQuestion => currentQuestionIndex == questions.length - 1;
  bool get isFirstQuestion => currentQuestionIndex == 0;
  int get totalQuestions => questions.length;
  int get correctAnswers => answers.where((answer) => answer.isCorrect).length;

  // Calculate actual current question number based on total progress
  // e.g., if 2 questions attempted out of 5, current question is 3
  int get actualCurrentQuestionNumber => totalAttempted + 1;

  @override
  List<Object?> get props => [
    questions,
    originalQuizzes,
    currentQuestionIndex,
    answers,
    selectedOptionId,
    score,
    totalAttempted,
    totalPossibleMarks,
    marksEarned,
    percentage,
    remainingQuestions,
    totalQuestionsFromApi,
    isSubmitting,
    isResetting,
  ];
}

class QuizCompleted extends QuizState {
  final List<QuizQuestion> questions;
  final List<QuizAnswer> answers;
  final int score;
  final int totalQuestions;

  const QuizCompleted({
    required this.questions,
    required this.answers,
    required this.score,
    required this.totalQuestions,
  });

  @override
  List<Object?> get props => [questions, answers, score, totalQuestions];
}

class QuizError extends QuizState {
  final String message;

  const QuizError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Cubit
class QuizCubit extends Cubit<QuizState> {
  final QuizRepository _repository;
  String? _currentBookId;

  QuizCubit(this._repository) : super(QuizInitial());

  // Normalize various API representations (e.g., 'A', 'a', '1', 'option1')
  // into the option key format we use in state: 'option1'..'option4'.
  String _normalizeToOptionKey(String value) {
    final v = value.trim().toLowerCase();
    switch (v) {
      case 'a':
      case '1':
      case 'option1':
        return 'option1';
      case 'b':
      case '2':
      case 'option2':
        return 'option2';
      case 'c':
      case '3':
      case 'option3':
        return 'option3';
      case 'd':
      case '4':
      case 'option4':
        return 'option4';
      default:
        return value; // fallback to original if unknown
    }
  }

  // Map our internal option key ('option1'..'option4') to the API payload format.
  // Send option1, option2, etc. as requested by the API.
  String _mapOptionKeyToApiAnswer(String optionKey) {
    switch (optionKey.toLowerCase()) {
      case 'option1':
        return 'option1';
      case 'option2':
        return 'option2';
      case 'option3':
        return 'option3';
      case 'option4':
        return 'option4';
      default:
        return optionKey; // fallback: send as-is if unknown
    }
  }

  Future<void> loadQuizzesFromApi({
    required String bookId,
    bool isRefresh = false,
  }) async {
    _currentBookId = bookId;
    debugPrint(
      '📚 [QUIZ CUBIT] Loading quizzes for bookId: $bookId (isRefresh: $isRefresh)',
    );

    // Only show loading state on initial load, not on refresh
    if (!isRefresh) {
      emit(QuizLoading());
    }

    try {
      // Always fetch fresh quiz data - no caching
      final response = await _repository.getBookQuizzes(bookId: bookId);
      debugPrint(
        '📚 [QUIZ CUBIT] Quiz API Response Status: ${response.status}',
      );

      if (response.status == 200 && response.data != null) {
        final originalQuizzes = response.data!.quizzes;
        debugPrint(
          '📚 [QUIZ CUBIT] Total quizzes from API: ${originalQuizzes.length}',
        );

        // Parse ONLY unattempted questions
        final questions = <QuizQuestion>[];
        for (final quiz in originalQuizzes) {
          debugPrint(
            '   - Quiz ${quiz.quizId}: is_attempted=${quiz.isAttempted}',
          );

          // Only add unattempted questions to the list
          if (!quiz.isAttempted) {
            final question = QuizQuestion(
              id: quiz.quizId,
              question: quiz.question,
              options: _parseQuizOptions(quiz),
              correctAnswerId: _normalizeToOptionKey(quiz.correctOption),
            );
            questions.add(question);
          }
        }

        debugPrint(
          '📚 [QUIZ CUBIT] Unattempted questions: ${questions.length}',
        );

        // Always fetch fresh score data - no caching
        try {
          final scoreResp = await _repository.getScore(bookId: bookId);
          final data = scoreResp.data['data'];

          debugPrint('📊 [QUIZ CUBIT] Score API Response:');
          debugPrint('   - total_questions: ${data['total_questions']}');
          debugPrint(
            '   - questions_attempted: ${data['questions_attempted']}',
          );
          debugPrint('   - correct_answers: ${data['correct_answers']}');
          debugPrint('   - marks_earned: ${data['marks_earned']}');
          debugPrint(
            '   - total_possible_marks: ${data['total_possible_marks']}',
          );
          debugPrint('   - percentage: ${data['percentage']}');
          debugPrint(
            '   - remaining_questions: ${data['remaining_questions']}',
          );

          if (questions.isEmpty) {
            debugPrint('📚 [QUIZ CUBIT] Quiz completed! Showing score card.');
          }

          emit(
            QuizLoaded(
              questions: questions,
              originalQuizzes: originalQuizzes,
              score: data['correct_answers'] ?? 0,
              totalAttempted: data['questions_attempted'] ?? 0,
              totalPossibleMarks: data['total_possible_marks'] ?? 0,
              marksEarned: data['marks_earned'] ?? 0,
              percentage: (data['percentage'] ?? 0).toDouble(),
              remainingQuestions: data['remaining_questions'] ?? 0,
              totalQuestionsFromApi:
                  data['total_questions'] ?? originalQuizzes.length,
            ),
          );
        } catch (e) {
          debugPrint('❌ [QUIZ CUBIT] Score API Error: $e');
          // If score API fails, check if quiz is completed
          if (questions.isEmpty) {
            debugPrint('📚 [QUIZ CUBIT] Quiz completed but score API failed');
          }
          emit(
            QuizLoaded(
              questions: questions,
              originalQuizzes: originalQuizzes,
              totalAttempted: 0,
              totalPossibleMarks: originalQuizzes.length,
              marksEarned: 0,
              percentage: 0.0,
              remainingQuestions: questions.length,
              totalQuestionsFromApi: originalQuizzes.length,
            ),
          );
        }
      } else {
        debugPrint('❌ [QUIZ CUBIT] Quiz API Error: ${response.message}');
        emit(QuizError(message: response.message));
      }
    } catch (e) {
      debugPrint('❌ [QUIZ CUBIT] Exception: $e');
      emit(QuizError(message: e.toString()));
    }
  }

  List<QuizOption> _parseQuizOptions(Quiz quiz) {
    final options = <QuizOption>[];

    // Add option1 if it has meaningful content
    if (quiz.option1 != null && quiz.option1!.trim().isNotEmpty) {
      options.add(QuizOption(id: 'option1', text: quiz.option1!, letter: 'A'));
    }

    // Add option2 if it has meaningful content
    if (quiz.option2 != null && quiz.option2!.trim().isNotEmpty) {
      options.add(QuizOption(id: 'option2', text: quiz.option2!, letter: 'B'));
    }

    // Add option3 if it has meaningful content
    if (quiz.option3 != null && quiz.option3!.trim().isNotEmpty) {
      options.add(QuizOption(id: 'option3', text: quiz.option3!, letter: 'C'));
    }

    // Add option4 if it has meaningful content
    if (quiz.option4 != null && quiz.option4!.trim().isNotEmpty) {
      options.add(QuizOption(id: 'option4', text: quiz.option4!, letter: 'D'));
    }

    return options;
  }

  void selectOption(String optionId) {
    if (state is QuizLoaded) {
      final currentState = state as QuizLoaded;
      // If clicking the same option, deselect it
      if (currentState.selectedOptionId == optionId) {
        emit(currentState.copyWith(selectedOptionId: null));
      } else {
        // Select the new option
        emit(currentState.copyWith(selectedOptionId: optionId));
      }
    }
  }

  void submitAnswer() {
    if (state is! QuizLoaded) return;
    final currentState = state as QuizLoaded;
    final selected = currentState.selectedOptionId;
    if (selected == null) return;

    debugPrint(
      '✅ [QUIZ CUBIT] Submitting answer for question: ${currentState.currentQuestion.id}',
    );
    debugPrint('   - Selected option: $selected');

    // Show submitting loader
    emit(currentState.copyWith(isSubmitting: true));

    // Send to API and refresh data
    _repository
        .submitAnswer(
          quizId: currentState.currentQuestion.id,
          userAnswer: _mapOptionKeyToApiAnswer(selected),
        )
        .then((response) async {
          final responseData = response.data;
          final status = responseData?['status'];

          debugPrint('✅ [QUIZ CUBIT] Submit Answer Response Status: $status');
          debugPrint('   - Response: $responseData');

          if (status == 201 || status == 200) {
            // Submission successful - fetch fresh data (isRefresh: true keeps questions visible)
            if (_currentBookId != null) {
              await loadQuizzesFromApi(
                bookId: _currentBookId!,
                isRefresh: true,
              );
            }

            // Move to first question (which will be the next unattempted one)
            final s = state;
            if (s is QuizLoaded) {
              emit(
                s.copyWith(
                  currentQuestionIndex: 0,
                  selectedOptionId: null,
                  isSubmitting: false,
                ),
              );
            }
          } else {
            // Submission failed
            debugPrint(
              '❌ [QUIZ CUBIT] Submit failed: ${responseData?['message']}',
            );
            emit(currentState.copyWith(isSubmitting: false));
          }
        })
        .catchError((error) {
          debugPrint('❌ [QUIZ CUBIT] Submit error: $error');
          emit(currentState.copyWith(isSubmitting: false));
        });
  }

  // Submit and advance to next question in one action
  void submitAndAdvance({required String bookId}) {
    if (state is! QuizLoaded) return;
    final currentState = state as QuizLoaded;
    final selected = currentState.selectedOptionId;
    if (selected == null) return;

    debugPrint(
      '✅ [QUIZ CUBIT] Submit and advance for question: ${currentState.currentQuestion.id}',
    );

    emit(currentState.copyWith(isSubmitting: true));

    _repository
        .submitAnswer(
          quizId: currentState.currentQuestion.id,
          userAnswer: _mapOptionKeyToApiAnswer(selected),
        )
        .then((response) async {
          final responseData = response.data;
          final status = responseData?['status'];

          debugPrint(
            '✅ [QUIZ CUBIT] Submit & Advance Response Status: $status',
          );

          if (status == 201 || status == 200) {
            // Fetch fresh data (isRefresh: true keeps questions visible)
            if (_currentBookId != null) {
              await loadQuizzesFromApi(
                bookId: _currentBookId!,
                isRefresh: true,
              );
            }

            // Move to first question
            final s = state;
            if (s is QuizLoaded) {
              emit(
                s.copyWith(
                  currentQuestionIndex: 0,
                  selectedOptionId: null,
                  isSubmitting: false,
                ),
              );
            }
          } else {
            debugPrint('❌ [QUIZ CUBIT] Submit & Advance failed');
            emit(currentState.copyWith(isSubmitting: false));
          }
        })
        .catchError((error) {
          debugPrint('❌ [QUIZ CUBIT] Submit & Advance error: $error');
          emit(currentState.copyWith(isSubmitting: false));
        });
  }

  Future<void> refreshBookScore(String bookId) async {
    debugPrint('🔄 [QUIZ CUBIT] Refreshing score for bookId: $bookId');
    if (_currentBookId != null) {
      await loadQuizzesFromApi(bookId: _currentBookId!, isRefresh: true);
    }
  }

  Future<void> resetBookAnswers(String bookId) async {
    _currentBookId = bookId;
    debugPrint('🔄 [QUIZ CUBIT] Resetting quiz for bookId: $bookId');

    // Show resetting loader
    if (state is QuizLoaded) {
      emit((state as QuizLoaded).copyWith(isResetting: true));
    }

    try {
      // Call reset API
      await _repository.resetAnswers(bookId: bookId);
      debugPrint('✅ [QUIZ CUBIT] Reset API call successful');

      // Reload fresh quiz data after reset
      await loadQuizzesFromApi(bookId: bookId);

      // Hide loader
      final s = state;
      if (s is QuizLoaded) {
        emit(s.copyWith(isResetting: false));
      }
    } catch (e) {
      debugPrint('❌ [QUIZ CUBIT] Reset error: $e');
      final s = state;
      if (s is QuizLoaded) {
        emit(s.copyWith(isResetting: false));
      }
      emit(QuizError(message: e.toString()));
    }
  }

  void nextQuestion() {
    if (state is QuizLoaded) {
      final currentState = state as QuizLoaded;
      if (currentState.isLastQuestion) {
        // Do not emit a separate completed state; UI will show
        // the score card based on API score/remaining_questions.
        return;
      } else {
        // Get the selected option for the next question if it was already answered
        final nextQuestionIndex = currentState.currentQuestionIndex + 1;
        final nextQuestion = currentState.questions[nextQuestionIndex];
        final existingAnswer =
            currentState.answers
                .where((answer) => answer.questionId == nextQuestion.id)
                .firstOrNull;

        emit(
          currentState.copyWith(
            currentQuestionIndex: nextQuestionIndex,
            selectedOptionId: existingAnswer?.selectedOptionId,
          ),
        );
      }
    }
  }

  void previousQuestion() {
    if (state is QuizLoaded) {
      final currentState = state as QuizLoaded;
      if (currentState.currentQuestionIndex > 0) {
        final previousQuestionIndex = currentState.currentQuestionIndex - 1;
        final previousQuestion = currentState.questions[previousQuestionIndex];
        final existingAnswer =
            currentState.answers
                .where((answer) => answer.questionId == previousQuestion.id)
                .firstOrNull;

        emit(
          currentState.copyWith(
            currentQuestionIndex: previousQuestionIndex,
            selectedOptionId: existingAnswer?.selectedOptionId,
          ),
        );
      }
    }
  }

  void restartQuiz() {
    debugPrint('🔄 [QUIZ CUBIT] Restarting quiz');
    emit(QuizInitial());
  }
}
