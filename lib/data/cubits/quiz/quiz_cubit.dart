import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

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

abstract class QuizState extends Equatable {
  const QuizState();

  @override
  List<Object?> get props => [];
}

class QuizInitial extends QuizState {}

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

class QuizCubit extends Cubit<QuizState> {
  QuizCubit() : super(QuizInitial());

  void loadQuizFromApi(List<dynamic> quizData) {
    if (quizData.isEmpty) {
      emit(QuizInitial());
      return;
    }

    try {
      final questions = <QuizQuestion>[];

      for (final quiz in quizData) {
        // Parse quiz data from the real API structure
        final question = QuizQuestion(
          id: quiz['quiz_id'] ?? 'unknown',
          question: quiz['question'] ?? 'Quiz Question',
          options: _parseQuizOptions(quiz),
          correctAnswerId: quiz['correct_option'] ?? 'option1',
        );
        questions.add(question);
      }

      if (questions.isNotEmpty) {
        emit(QuizLoaded(questions: questions));
      } else {
        emit(QuizInitial());
      }
    } catch (e) {
      debugPrint('Error parsing quiz data: $e');
      emit(QuizInitial());
    }
  }

  List<QuizOption> _parseQuizOptions(dynamic quiz) {
    // Parse options from the real API structure
    final options = <QuizOption>[];

    // Add option1
    if (quiz['option1'] != null) {
      options.add(
        QuizOption(id: 'option1', text: quiz['option1'], letter: 'A'),
      );
    }

    // Add option2
    if (quiz['option2'] != null) {
      options.add(
        QuizOption(id: 'option2', text: quiz['option2'], letter: 'B'),
      );
    }

    // Add option3
    if (quiz['option3'] != null) {
      options.add(
        QuizOption(id: 'option3', text: quiz['option3'], letter: 'C'),
      );
    }

    // Add option4
    if (quiz['option4'] != null) {
      options.add(
        QuizOption(id: 'option4', text: quiz['option4'], letter: 'D'),
      );
    }

    return options;
  }

  void _loadQuiz() {
    final questions = [
      const QuizQuestion(
        id: '1',
        question: 'Qui est le dernier prophète envoyé par Dieu en islam ?',
        options: [
          QuizOption(
            id: 'a',
            text: 'Muhammad (paix et bénédictions sur lui)',
            letter: 'A',
          ),
          QuizOption(
            id: 'b',
            text: "'Îsâ (que la paix soit sur lui)",
            letter: 'B',
          ),
          QuizOption(
            id: 'c',
            text: 'Yûsuf (que la paix soit sur lui)',
            letter: 'C',
          ),
          QuizOption(
            id: 'd',
            text: 'Mûsâ (que la paix soit sur lui)',
            letter: 'D',
          ),
        ],
        correctAnswerId: 'a',
      ),
      const QuizQuestion(
        id: '2',
        question: 'Quel est le premier livre révélé au Prophète Muhammad ?',
        options: [
          QuizOption(id: 'a', text: 'Al-Fatiha', letter: 'A'),
          QuizOption(id: 'b', text: 'Al-Iqra', letter: 'B'),
          QuizOption(id: 'c', text: 'Al-Baqarah', letter: 'C'),
          QuizOption(id: 'd', text: 'An-Nas', letter: 'D'),
        ],
        correctAnswerId: 'b',
      ),
      const QuizQuestion(
        id: '3',
        question: 'Combien de sourates contient le Coran ?',
        options: [
          QuizOption(id: 'a', text: '114', letter: 'A'),
          QuizOption(id: 'b', text: '113', letter: 'B'),
          QuizOption(id: 'c', text: '115', letter: 'C'),
          QuizOption(id: 'd', text: '112', letter: 'D'),
        ],
        correctAnswerId: 'a',
      ),
      const QuizQuestion(
        id: '4',
        question: 'Quel est le nom de la première femme du Prophète Muhammad ?',
        options: [
          QuizOption(id: 'a', text: 'Aïcha', letter: 'A'),
          QuizOption(id: 'b', text: 'Khadija', letter: 'B'),
          QuizOption(id: 'c', text: 'Fatima', letter: 'C'),
          QuizOption(id: 'd', text: 'Zaynab', letter: 'D'),
        ],
        correctAnswerId: 'b',
      ),
      const QuizQuestion(
        id: '5',
        question: 'Dans quelle ville le Prophète Muhammad est-il né ?',
        options: [
          QuizOption(id: 'a', text: 'Médine', letter: 'A'),
          QuizOption(id: 'b', text: 'La Mecque', letter: 'B'),
          QuizOption(id: 'c', text: 'Damas', letter: 'C'),
          QuizOption(id: 'd', text: 'Bagdad', letter: 'D'),
        ],
        correctAnswerId: 'b',
      ),
    ];

    emit(QuizLoaded(questions: questions));
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
    _loadQuiz();
  }
}
