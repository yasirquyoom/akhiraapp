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

  const QuizLoaded({
    required this.questions,
    this.currentQuestionIndex = 0,
    this.answers = const [],
    this.selectedOptionId,
    this.score = 0,
  });

  QuizLoaded copyWith({
    List<QuizQuestion>? questions,
    int? currentQuestionIndex,
    List<QuizAnswer>? answers,
    String? selectedOptionId,
    int? score,
  }) {
    return QuizLoaded(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      score: score ?? this.score,
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

  QuizCubit(this._repository) : super(QuizInitial());

  Future<void> loadQuizzesFromApi({required String bookId}) async {
    emit(QuizLoading());

    try {
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
          emit(QuizLoaded(questions: questions));
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

    // Add option1
    options.add(QuizOption(id: 'option1', text: quiz.option1, letter: 'A'));

    // Add option2
    options.add(QuizOption(id: 'option2', text: quiz.option2, letter: 'B'));

    // Add option3
    options.add(QuizOption(id: 'option3', text: quiz.option3, letter: 'C'));

    // Add option4
    options.add(QuizOption(id: 'option4', text: quiz.option4, letter: 'D'));

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
    if (state is QuizLoaded) {
      final currentState = state as QuizLoaded;
      if (currentState.selectedOptionId == null) return;

      final isCorrect =
          currentState.selectedOptionId ==
          currentState.currentQuestion.correctAnswerId;
      final newAnswer = QuizAnswer(
        questionId: currentState.currentQuestion.id,
        selectedOptionId: currentState.selectedOptionId!,
        isCorrect: isCorrect,
        answeredAt: DateTime.now(),
      );

      final updatedAnswers = [...currentState.answers, newAnswer];
      final newScore =
          updatedAnswers.where((answer) => answer.isCorrect).length;

      emit(
        currentState.copyWith(
          answers: updatedAnswers,
          selectedOptionId: null,
          score: newScore,
        ),
      );
    }
  }

  void nextQuestion() {
    if (state is QuizLoaded) {
      final currentState = state as QuizLoaded;
      if (currentState.isLastQuestion) {
        emit(
          QuizCompleted(
            questions: currentState.questions,
            answers: currentState.answers,
            score: currentState.score,
            totalQuestions: currentState.totalQuestions,
          ),
        );
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
