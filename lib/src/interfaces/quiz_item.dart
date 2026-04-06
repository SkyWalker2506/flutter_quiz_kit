/// Abstract interface that quiz items must implement.
///
/// Any model class (e.g. Word, Phrase) can participate in quizzes by
/// implementing [QuizItem].
abstract interface class QuizItem {
  /// The primary term shown as a prompt (e.g. English word).
  String get term;

  /// The definition or translation (e.g. Turkish meaning).
  String get definition;
}
