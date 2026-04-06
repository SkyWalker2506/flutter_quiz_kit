import '../interfaces/quiz_item.dart';
import '../models/difficulty_level.dart';
import '../models/quiz_question.dart';
import '../usecases/stt_matches.dart';

class QuizResult<T extends QuizItem> {
  QuizResult({
    required this.questions,
    required this.userAnswers,
    required this.mode,
    required this.elapsedSeconds,
    this.hintsUsed = const {},
    this.quizDifficulty,
  });

  final List<QuizQuestion<T>> questions;
  final List<String> userAnswers; // same length as questions
  final QuizMode mode;
  final int elapsedSeconds;
  final Set<int> hintsUsed; // indexes of questions where hint was used

  /// Adaptive difficulty at the time this quiz was taken.
  /// Null when difficulty is not applicable.
  final DifficultyLevel? quizDifficulty;

  int get total => questions.length;

  int get correctCount {
    var count = 0;
    for (var i = 0; i < questions.length; i++) {
      if (_isCorrect(i)) count++;
    }
    return count;
  }

  bool _isCorrect(int i) {
    if (mode == QuizMode.pronunciationQuiz) {
      return sttRecognizedMatchesExpected(userAnswers[i], questions[i].answer);
    }
    if (mode == QuizMode.speakChoice) {
      final recognized = userAnswers[i];
      final matched = questions[i].choices.firstWhere(
        (c) => sttRecognizedMatchesExpected(recognized, c),
        orElse: () => '',
      );
      return matched.isNotEmpty && matched == questions[i].answer;
    }
    final expected = questions[i].answer.trim().toLowerCase();
    final given = userAnswers[i].trim().toLowerCase();
    return expected == given;
  }

  bool isCorrectAt(int i) => _isCorrect(i);

  List<int> get wrongIndexes => [
        for (var i = 0; i < questions.length; i++)
          if (!_isCorrect(i)) i,
      ];
}
