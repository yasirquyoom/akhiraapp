import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
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

  @override
  List<Object?> get props => [
    questions,
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
  String? _currentBookId; // track current book for score refreshes

  QuizCubit(this._repository) : super(QuizInitial());

  Future<void> loadQuizzesFromApi({required String bookId}) async {
    // Remember current book id to enable score refreshes after submit
    _currentBookId = bookId;
    emit(QuizLoading());

    try {
      // Fetch score first to know completion state immediately
      try {
        final scoreResp = await _repository.getScore(bookId: bookId);
        final data = scoreResp.data['data'];
        // Temporarily emit a loaded state with score-only to avoid flicker
        emit(
          QuizLoaded(
            questions: const [],
            score: data['correct_answers'] ?? 0,
            totalAttempted: data['questions_attempted'] ?? 0,
            totalPossibleMarks: data['total_possible_marks'] ?? 0,
            marksEarned: data['marks_earned'] ?? 0,
            percentage: (data['percentage'] ?? 0).toDouble(),
            remainingQuestions: data['remaining_questions'] ?? 0,
            totalQuestionsFromApi: data['total_questions'] ?? 0,
          ),
        );
      } catch (_) {}

      final response = await _repository.getBookQuizzes(bookId: bookId);

      if (response.status == 200 && response.data != null) {
        final questions = <QuizQuestion>[];

        for (final quiz in response.data!.quizzes) {
          final question = QuizQuestion(
            id: quiz.quizId,
            question: quiz.question,
            options: _parseQuizOptions(quiz),
            correctAnswerId: quiz.correctOption,
          );
          questions.add(question);
        }

        if (questions.isNotEmpty) {
          // Merge with any existing score data already emitted
          final prev = state is QuizLoaded ? state as QuizLoaded : null;
          emit(
            QuizLoaded(
              questions: questions,
              totalAttempted: prev?.totalAttempted ?? 0,
              totalPossibleMarks: prev?.totalPossibleMarks ?? 0,
              marksEarned: prev?.marksEarned ?? 0,
              percentage: prev?.percentage ?? 0,
              remainingQuestions: prev?.remainingQuestions ?? 0,
              totalQuestionsFromApi:
                  prev?.totalQuestionsFromApi ?? questions.length,
            ),
          );
        } else {
          emit(QuizInitial());
        }
      } else {
        emit(QuizError(message: response.message));
      }
    } catch (e) {
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

    // Show submitting loader
    emit(currentState.copyWith(isSubmitting: true));

    // Optimistic update for instant UX
    final isCorrect = selected == currentState.currentQuestion.correctAnswerId;
    final optimisticAnswer = QuizAnswer(
      questionId: currentState.currentQuestion.id,
      selectedOptionId: selected,
      isCorrect: isCorrect,
      answeredAt: DateTime.now(),
    );
    final optimisticAnswers = [...currentState.answers, optimisticAnswer];
    emit(
      currentState.copyWith(
        answers: optimisticAnswers,
        selectedOptionId: null,
        score: optimisticAnswers.where((a) => a.isCorrect).length,
        // Optimistically update marks and attempts for immediate UI feedback
        marksEarned: currentState.marksEarned + (isCorrect ? 1 : 0),
        totalAttempted: currentState.totalAttempted + 1,
        // Keep percentage/remainingQuestions driven by server to avoid mismatch
        isSubmitting: true,
      ),
    );

    // Send to API, then refresh score
    _repository
        .submitAnswer(
          quizId: currentState.currentQuestion.id,
          userAnswer: selected,
        )
        .then((_) => _refreshScore())
        .whenComplete(() {
          // Hide submitting loader
          final s = state;
          if (s is QuizLoaded) {
            emit(s.copyWith(isSubmitting: false));
          }
        })
        .catchError((_) => null);
  }

  // Atomic: submit and advance to next question in one action
  void submitAndAdvance({required String bookId}) {
    if (state is! QuizLoaded) return;
    final currentState = state as QuizLoaded;
    final selected = currentState.selectedOptionId;
    if (selected == null) return;

    // Show submitting loader
    emit(currentState.copyWith(isSubmitting: true));

    // Optimistic update
    final isCorrect = selected == currentState.currentQuestion.correctAnswerId;
    final optimisticAnswer = QuizAnswer(
      questionId: currentState.currentQuestion.id,
      selectedOptionId: selected,
      isCorrect: isCorrect,
      answeredAt: DateTime.now(),
    );
    final optimisticAnswers = [...currentState.answers, optimisticAnswer];
    emit(
      currentState.copyWith(
        answers: optimisticAnswers,
        selectedOptionId: null,
        score: optimisticAnswers.where((a) => a.isCorrect).length,
        // Optimistically update marks and attempts for immediate UI feedback
        marksEarned: currentState.marksEarned + (isCorrect ? 1 : 0),
        totalAttempted: currentState.totalAttempted + 1,
        // Keep percentage/remainingQuestions driven by server to avoid mismatch
        isSubmitting: true,
      ),
    );

    // Fire API and score refresh, then advance
    _repository
        .submitAnswer(
          quizId: currentState.currentQuestion.id,
          userAnswer: selected,
        )
        .then((_) => refreshBookScore(bookId))
        .whenComplete(() {
          // Advance question index if possible
          final s = state;
          if (s is QuizLoaded) {
            if (!s.isLastQuestion) {
              final nextQuestionIndex = s.currentQuestionIndex + 1;
              final nextQuestion = s.questions[nextQuestionIndex];
              final existingAnswer = s.answers
                  .where((a) => a.questionId == nextQuestion.id)
                  .firstOrNull;
              emit(
                s.copyWith(
                  currentQuestionIndex: nextQuestionIndex,
                  selectedOptionId: existingAnswer?.selectedOptionId,
                  isSubmitting: false,
                ),
              );
            } else {
              // Last question: just stop submitting; UI will show score card
              emit(s.copyWith(isSubmitting: false));
            }
          }
        })
        .catchError((_) {
          final s = state;
          if (s is QuizLoaded) {
            emit(s.copyWith(isSubmitting: false));
          }
        });
  }

  Future<void> _refreshScore() async {
    if (state is! QuizLoaded) return;
    final bookId = _currentBookId;
    if (bookId == null || bookId.isEmpty) return;
    try {
      final resp = await _repository.getScore(bookId: bookId);
      final data = resp.data['data'];
      final currentState = state as QuizLoaded;
      emit(
        currentState.copyWith(
          score: data['correct_answers'] ?? currentState.score,
          totalAttempted:
              data['questions_attempted'] ?? currentState.totalAttempted,
          totalPossibleMarks:
              data['total_possible_marks'] ?? currentState.totalPossibleMarks,
          marksEarned: data['marks_earned'] ?? currentState.marksEarned,
          percentage:
              (data['percentage'] ?? currentState.percentage).toDouble(),
          remainingQuestions:
              data['remaining_questions'] ?? currentState.remainingQuestions,
          totalQuestionsFromApi:
              data['total_questions'] ?? currentState.totalQuestionsFromApi,
        ),
      );
    } catch (_) {
      // ignore
    }
  }

  Future<void> refreshBookScore(String bookId) async {
    if (state is! QuizLoaded) return;
    try {
      final resp = await _repository.getScore(bookId: bookId);
      final data = resp.data['data'];
      final currentState = state as QuizLoaded;
      emit(
        currentState.copyWith(
          score: data['correct_answers'] ?? currentState.score,
          totalAttempted:
              data['questions_attempted'] ?? currentState.totalAttempted,
          totalPossibleMarks:
              data['total_possible_marks'] ?? currentState.totalPossibleMarks,
          marksEarned: data['marks_earned'] ?? currentState.marksEarned,
          percentage:
              (data['percentage'] ?? currentState.percentage).toDouble(),
          remainingQuestions:
              data['remaining_questions'] ?? currentState.remainingQuestions,
          totalQuestionsFromApi:
              data['total_questions'] ?? currentState.totalQuestionsFromApi,
        ),
      );
    } catch (_) {
      // ignore
    }
  }

  Future<void> resetBookAnswers(String bookId) async {
    try {
      // Remember current book id
      _currentBookId = bookId;
      // Show resetting loader
      if (state is QuizLoaded) {
        emit((state as QuizLoaded).copyWith(isResetting: true));
      }
      await _repository.resetAnswers(bookId: bookId);
      // After reset, reload quizzes and score so the quiz appears again
      await loadQuizzesFromApi(bookId: bookId);
    } catch (_) {
    } finally {
      if (state is QuizLoaded) {
        emit((state as QuizLoaded).copyWith(isResetting: false));
      }
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
      if (!currentState.isFirstQuestion) {
        // Get the selected option for the previous question if it was already answered
        final prevQuestionIndex = currentState.currentQuestionIndex - 1;
        final prevQuestion = currentState.questions[prevQuestionIndex];
        final existingAnswer =
            currentState.answers
                .where((answer) => answer.questionId == prevQuestion.id)
                .firstOrNull;

        emit(
          currentState.copyWith(
            currentQuestionIndex: prevQuestionIndex,
            selectedOptionId: existingAnswer?.selectedOptionId,
          ),
        );
      }
    }
  }

  void restartQuiz() {
    emit(QuizInitial());
  }
}
