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
  String? _currentBookId; // track current book for score refreshes
  final Set<String> _answeredQuestionIds =
      {}; // track locally answered questions

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

  Future<void> loadQuizzesFromApi({required String bookId}) async {
    // Remember current book id to enable score refreshes after submit
    _currentBookId = bookId;

    // Check if quiz is already completed to avoid unnecessary loading
    if (state is QuizLoaded) {
      final currentState = state as QuizLoaded;
      final isCompleted =
          currentState.remainingQuestions == 0 &&
          (currentState.totalQuestionsFromApi > 0 ||
              currentState.totalAttempted > 0);
      if (isCompleted) {
        return;
      }
    }

    // Also check completion by making a quick score API call first
    try {
      final scoreResp = await _repository.getScore(bookId: bookId);
      final data = scoreResp.data['data'];
      final remainingQuestions = data['remaining_questions'] ?? 0;
      final totalQuestions = data['total_questions'] ?? 0;
      final questionsAttempted = data['questions_attempted'] ?? 0;

      // If quiz is completed, just emit the completed state and return
      if (remainingQuestions == 0 &&
          totalQuestions > 0 &&
          questionsAttempted > 0) {
        emit(
          QuizLoaded(
            questions: const [],
            originalQuizzes: const [],
            score: data['correct_answers'] ?? 0,
            totalAttempted: questionsAttempted,
            totalPossibleMarks: data['total_possible_marks'] ?? 0,
            marksEarned: data['marks_earned'] ?? 0,
            percentage: (data['percentage'] ?? 0).toDouble(),
            remainingQuestions: remainingQuestions,
            totalQuestionsFromApi: totalQuestions,
          ),
        );
        return;
      }
    } catch (_) {
      // If score API fails, continue with normal loading
    }

    emit(QuizLoading());

    try {
      final response = await _repository.getBookQuizzes(bookId: bookId);

      if (response.status == 200 && response.data != null) {
        final questions = <QuizQuestion>[];
        final originalQuizzes =
            response.data!.quizzes; // Store original quiz data

        // Load ALL questions (both attempted and unattempted)
        for (final quiz in originalQuizzes) {
          final question = QuizQuestion(
            id: quiz.quizId,
            question: quiz.question,
            options: _parseQuizOptions(quiz),
            // Normalize to 'option#' style to match our selectedOption ids
            correctAnswerId: _normalizeToOptionKey(quiz.correctOption),
          );
          questions.add(question);
        }

        if (questions.isNotEmpty) {
          // Get fresh score data to ensure correct remainingQuestions
          try {
            final scoreResp = await _repository.getScore(bookId: bookId);
            final data = scoreResp.data['data'];
            emit(
              QuizLoaded(
                questions: questions,
                originalQuizzes: originalQuizzes,
                totalAttempted: data['questions_attempted'] ?? 0,
                totalPossibleMarks: data['total_possible_marks'] ?? 0,
                marksEarned: data['marks_earned'] ?? 0,
                percentage: (data['percentage'] ?? 0).toDouble(),
                remainingQuestions:
                    data['remaining_questions'] ?? questions.length,
                totalQuestionsFromApi:
                    data['total_questions'] ?? questions.length,
              ),
            );
          } catch (_) {
            // If score API fails, use fallback values
            emit(
              QuizLoaded(
                questions: questions,
                originalQuizzes: originalQuizzes,
                totalAttempted: 0,
                totalPossibleMarks: questions.length,
                marksEarned: 0,
                percentage: 0.0,
                remainingQuestions: questions.length,
                totalQuestionsFromApi: questions.length,
              ),
            );
          }
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
        // Keep percentage/remainingQuestions driven by server to avoid mismatch
        isSubmitting: true,
      ),
    );

    // Send to API, then refresh score and quiz data
    _repository
        .submitAnswer(
          quizId: currentState.currentQuestion.id,
          // Send option1, option2, etc. as requested by the API
          userAnswer: _mapOptionKeyToApiAnswer(selected),
        )
        .then((response) async {
          // Check if submission was successful by looking at response body status
          final responseData = response.data;
          final status = responseData?['status'];

          if (status == 201 || status == 200) {
            // Track this question as answered locally to prevent duplicate submissions
            _answeredQuestionIds.add(currentState.currentQuestion.id);

            // Refresh score first
            await _refreshScore();
            // Then refresh quiz data to get updated questions (this will filter out attempted questions)
            if (_currentBookId != null) {
              await loadQuizzesFromApi(bookId: _currentBookId!);
            }

            // After refreshing, the quiz list will only contain unattempted questions
            // The current question will be automatically filtered out, so we start from index 0
            final s = state;
            if (s is QuizLoaded) {
              if (s.questions.isNotEmpty) {
                // Move to the first unattempted question (index 0 after filtering)
                final firstQuestion = s.questions[0];
                final existingAnswer =
                    s.answers
                        .where((a) => a.questionId == firstQuestion.id)
                        .firstOrNull;
                emit(
                  s.copyWith(
                    currentQuestionIndex: 0,
                    selectedOptionId: existingAnswer?.selectedOptionId,
                    isSubmitting: false,
                  ),
                );
              } else {
                // No more unattempted questions: quiz is completed, just stop submitting
                // The UI will show the score card based on the completion logic
                emit(s.copyWith(isSubmitting: false));
              }
            }
          } else {
            // Submission failed, revert optimistic update
            print('Quiz submission failed: ${responseData?['message']}');
            print(
              'Reverting optimistic update - keeping question at index: ${currentState.currentQuestionIndex}',
            );
            emit(
              currentState.copyWith(
                answers: currentState.answers,
                selectedOptionId: selected,
                score: currentState.score,
                marksEarned: currentState.marksEarned,
                isSubmitting: false,
              ),
            );
          }
        })
        .whenComplete(() {
          // Hide submitting loader
          final s = state;
          if (s is QuizLoaded) {
            emit(s.copyWith(isSubmitting: false));
          }
        })
        .catchError((error) {
          // Revert optimistic update on error
          emit(
            currentState.copyWith(
              answers: currentState.answers,
              selectedOptionId: selected,
              score: currentState.score,
              marksEarned: currentState.marksEarned,
              isSubmitting: false,
            ),
          );
        });
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
        // Keep percentage/remainingQuestions driven by server to avoid mismatch
        isSubmitting: true,
      ),
    );

    // Fire API and score refresh, then advance
    _repository
        .submitAnswer(
          quizId: currentState.currentQuestion.id,
          // Send option1, option2, etc. as requested by the API
          userAnswer: _mapOptionKeyToApiAnswer(selected),
        )
        .then((response) async {
          // Check if submission was successful by looking at response body status
          final responseData = response.data;
          final status = responseData?['status'];

          if (status == 201 || status == 200) {
            // Track this question as answered locally to prevent duplicate submissions
            _answeredQuestionIds.add(currentState.currentQuestion.id);

            // Refresh score first (force refresh after submission)
            await _forceRefreshScore(bookId);
            // Then refresh quiz data to get updated questions (this will filter out attempted questions)
            if (_currentBookId != null) {
              await _forceLoadQuizzesFromApi(bookId: _currentBookId!);
            }

            // After refreshing, find the next unattempted question
            final s = state;
            if (s is QuizLoaded) {
              if (s.questions.isNotEmpty) {
                // Find the next unattempted question
                int nextUnattemptedIndex = -1;
                for (int i = 0; i < s.questions.length; i++) {
                  final question = s.questions[i];
                  final isAttempted =
                      question.id == currentState.currentQuestion.id ||
                      _answeredQuestionIds.contains(question.id);
                  if (!isAttempted) {
                    nextUnattemptedIndex = i;
                    break;
                  }
                }

                if (nextUnattemptedIndex != -1) {
                  // Move to the next unattempted question
                  final nextQuestion = s.questions[nextUnattemptedIndex];
                  final existingAnswer =
                      s.answers
                          .where((a) => a.questionId == nextQuestion.id)
                          .firstOrNull;
                  emit(
                    s.copyWith(
                      currentQuestionIndex: nextUnattemptedIndex,
                      selectedOptionId: existingAnswer?.selectedOptionId,
                      isSubmitting: false,
                    ),
                  );
                } else {
                  // No more unattempted questions: quiz is completed
                  emit(s.copyWith(isSubmitting: false));
                }
              } else {
                // No questions available
                emit(s.copyWith(isSubmitting: false));
              }
            }
          } else {
            // Submission failed, revert optimistic update
            print('Quiz submission failed: ${responseData?['message']}');
            print(
              'Reverting optimistic update - keeping question at index: ${currentState.currentQuestionIndex}',
            );
            emit(
              currentState.copyWith(
                answers: currentState.answers,
                selectedOptionId: selected,
                score: currentState.score,
                marksEarned: currentState.marksEarned,
                isSubmitting: false,
              ),
            );
          }
        })
        .whenComplete(() {
          // Ensure submitting loader is hidden
          final s = state;
          if (s is QuizLoaded && s.isSubmitting) {
            emit(s.copyWith(isSubmitting: false));
          }
        })
        .catchError((error) {
          // Revert optimistic update on error
          emit(
            currentState.copyWith(
              answers: currentState.answers,
              selectedOptionId: selected,
              score: currentState.score,
              marksEarned: currentState.marksEarned,
              isSubmitting: false,
            ),
          );
        });
  }

  Future<void> _refreshScore() async {
    if (state is! QuizLoaded) return;
    final currentState = state as QuizLoaded;

    // Check if quiz is already completed to avoid unnecessary refreshes
    final isCompleted =
        currentState.remainingQuestions == 0 &&
        (currentState.totalQuestionsFromApi > 0 ||
            currentState.totalAttempted > 0);
    if (isCompleted) {
      return;
    }

    final bookId = _currentBookId;
    if (bookId == null || bookId.isEmpty) return;
    try {
      final resp = await _repository.getScore(bookId: bookId);
      final data = resp.data['data'];
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
    final currentState = state as QuizLoaded;

    // Check if quiz is already completed to avoid unnecessary refreshes
    final isCompleted =
        currentState.remainingQuestions == 0 &&
        (currentState.totalQuestionsFromApi > 0 ||
            currentState.totalAttempted > 0);
    if (isCompleted) {
      return;
    }

    try {
      final resp = await _repository.getScore(bookId: bookId);
      final data = resp.data['data'];
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

  // Force refresh score without completion checks (used after submission)
  Future<void> _forceRefreshScore(String bookId) async {
    if (state is! QuizLoaded) return;
    final currentState = state as QuizLoaded;

    try {
      final resp = await _repository.getScore(bookId: bookId);
      final data = resp.data['data'];
      print(
        'Force Refresh Score: API data - remainingQuestions=${data['remaining_questions']}, totalAttempted=${data['questions_attempted']}',
      );
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

  // Force load quizzes without completion checks (used after submission)
  Future<void> _forceLoadQuizzesFromApi({required String bookId}) async {
    _currentBookId = bookId;

    emit(QuizLoading());

    try {
      final response = await _repository.getBookQuizzes(bookId: bookId);

      if (response.status == 200 && response.data != null) {
        final questions = <QuizQuestion>[];
        final originalQuizzes =
            response.data!.quizzes; // Store original quiz data

        // Load ALL questions (both attempted and unattempted)
        for (final quiz in originalQuizzes) {
          final question = QuizQuestion(
            id: quiz.quizId,
            question: quiz.question,
            options: _parseQuizOptions(quiz),
            // Normalize to 'option#' style to match our selectedOption ids
            correctAnswerId: _normalizeToOptionKey(quiz.correctOption),
          );
          questions.add(question);
        }

        if (questions.isNotEmpty) {
          // Get fresh score data to ensure correct remainingQuestions
          try {
            final scoreResp = await _repository.getScore(bookId: bookId);
            final data = scoreResp.data['data'];
            emit(
              QuizLoaded(
                questions: questions,
                originalQuizzes: originalQuizzes,
                totalAttempted: data['questions_attempted'] ?? 0,
                totalPossibleMarks: data['total_possible_marks'] ?? 0,
                marksEarned: data['marks_earned'] ?? 0,
                percentage: (data['percentage'] ?? 0).toDouble(),
                remainingQuestions:
                    data['remaining_questions'] ?? questions.length,
                totalQuestionsFromApi:
                    data['total_questions'] ?? questions.length,
              ),
            );
          } catch (_) {
            // If score API fails, use fallback values
            emit(
              QuizLoaded(
                questions: questions,
                originalQuizzes: originalQuizzes,
                totalAttempted: 0,
                totalPossibleMarks: questions.length,
                marksEarned: 0,
                percentage: 0.0,
                remainingQuestions: questions.length,
                totalQuestionsFromApi: questions.length,
              ),
            );
          }
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

  Future<void> resetBookAnswers(String bookId) async {
    // Remember current book id
    _currentBookId = bookId;

    // Clear local tracking of answered questions
    _answeredQuestionIds.clear();

    // Show resetting loader
    if (state is QuizLoaded) {
      emit((state as QuizLoaded).copyWith(isResetting: true));
    }

    try {
      // 1) Call reset API to clear current quiz data
      await _repository.resetAnswers(bookId: bookId);

      // 2) Force reload quiz data after reset (bypass completion checks)
      await _loadQuizzesFromApiAfterReset(bookId: bookId);
    } catch (e) {
      // Handle API errors appropriately by surfacing an error state
      final message = e.toString();
      // Ensure loader is hidden before emitting error
      final s = state;
      if (s is QuizLoaded) {
        emit(s.copyWith(isResetting: false));
      }
      emit(QuizError(message: message));
      return;
    }

    // 6) Maintain consistent state throughout the reset process
    // Hide resetting loader when done
    final s = state;
    if (s is QuizLoaded) {
      emit(s.copyWith(isResetting: false));
    }
  }

  Future<void> _loadQuizzesFromApiAfterReset({required String bookId}) async {
    // Remember current book id
    _currentBookId = bookId;

    emit(QuizLoading());

    try {
      final response = await _repository.getBookQuizzes(bookId: bookId);

      if (response.status == 200 && response.data != null) {
        final questions = <QuizQuestion>[];
        final originalQuizzes =
            response.data!.quizzes; // Store original quiz data

        // After reset, all questions should be unattempted, so load all of them
        for (final quiz in originalQuizzes) {
          final question = QuizQuestion(
            id: quiz.quizId,
            question: quiz.question,
            options: _parseQuizOptions(quiz),
            // Normalize to 'option#' style to match our selectedOption ids
            correctAnswerId: _normalizeToOptionKey(quiz.correctOption),
          );
          questions.add(question);
        }

        if (questions.isNotEmpty) {
          // Get fresh score data after reset
          try {
            final scoreResp = await _repository.getScore(bookId: bookId);
            final data = scoreResp.data['data'];
            print('Score API Response After Reset: $data');
            final remainingQuestions =
                data['remaining_questions'] ?? questions.length;
            final totalQuestionsFromApi =
                data['total_questions'] ?? questions.length;
            final totalAttempted = data['questions_attempted'] ?? 0;

            print(
              'Cubit State After Reset: remainingQuestions=$remainingQuestions, totalQuestionsFromApi=$totalQuestionsFromApi, totalAttempted=$totalAttempted, questions.length=${questions.length}',
            );

            emit(
              QuizLoaded(
                questions: questions,
                originalQuizzes: originalQuizzes,
                totalAttempted: totalAttempted,
                totalPossibleMarks: data['total_possible_marks'] ?? 0,
                marksEarned: data['marks_earned'] ?? 0,
                percentage: (data['percentage'] ?? 0).toDouble(),
                remainingQuestions: remainingQuestions,
                totalQuestionsFromApi: totalQuestionsFromApi,
              ),
            );
          } catch (_) {
            // If score API fails, emit with default values
            print(
              'Cubit State After Reset (Fallback): remainingQuestions=${questions.length}, totalQuestionsFromApi=${questions.length}, totalAttempted=0, questions.length=${questions.length}',
            );
            emit(
              QuizLoaded(
                questions: questions,
                originalQuizzes: originalQuizzes,
                totalAttempted: 0,
                totalPossibleMarks: questions.length,
                marksEarned: 0,
                percentage: 0.0,
                remainingQuestions: questions.length,
                totalQuestionsFromApi: questions.length,
              ),
            );
          }
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
    // Clear local tracking of answered questions
    _answeredQuestionIds.clear();
    emit(QuizInitial());
  }
}
