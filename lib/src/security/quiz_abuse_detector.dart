import '../interfaces/quiz_item.dart';
import '../models/quiz_result.dart';

/// Severity of detected abuse.
enum AbuseSeverity {
  /// No suspicious behaviour detected.
  none,

  /// Mildly suspicious — worth logging but not restricting.
  low,

  /// Highly suspicious — account should be flagged.
  high,
}

/// The outcome of [QuizAbuseDetector.analyze].
final class QuizAbuseResult {
  const QuizAbuseResult({required this.severity, this.reason});

  final AbuseSeverity severity;

  /// Machine-readable debug description (English, not shown to users).
  final String? reason;

  bool get isSuspicious => severity != AbuseSeverity.none;
}

/// Thresholds used by [QuizAbuseDetector].
final class QuizAbuseConfig {
  const QuizAbuseConfig({
    this.minSecondsPerQuestion = 1.5,
    this.minSecondsPerQuestionPerfect = 3.0,
    this.minimumQuestions = 3,
  });

  /// Minimum average seconds/question for non-perfect quizzes.
  final double minSecondsPerQuestion;

  /// Stricter threshold applied when the score is 100%.
  final double minSecondsPerQuestionPerfect;

  /// Quizzes with fewer questions than this are skipped.
  final int minimumQuestions;

  /// Default production thresholds.
  static const QuizAbuseConfig defaults = QuizAbuseConfig();
}

/// Stateless quiz-abuse analyser.
abstract final class QuizAbuseDetector {
  /// Analyses [result] against [config] and returns a [QuizAbuseResult].
  static QuizAbuseResult analyze<T extends QuizItem>(
    QuizResult<T> result, {
    QuizAbuseConfig config = QuizAbuseConfig.defaults,
  }) {
    if (result.total < config.minimumQuestions) {
      return const QuizAbuseResult(severity: AbuseSeverity.none);
    }

    final avgSeconds = result.elapsedSeconds / result.total;
    final isPerfect = result.correctCount == result.total;

    // Rule 2: perfect + fast -> high severity
    if (isPerfect && avgSeconds < config.minSecondsPerQuestionPerfect) {
      return QuizAbuseResult(
        severity: AbuseSeverity.high,
        reason: 'Perfect score (${result.total}/${result.total}) in '
            '${result.elapsedSeconds}s '
            '(${avgSeconds.toStringAsFixed(2)}s/q; '
            'threshold ${config.minSecondsPerQuestionPerfect}s/q)',
      );
    }

    // Rule 1: any quiz too fast -> low severity
    if (avgSeconds < config.minSecondsPerQuestion) {
      return QuizAbuseResult(
        severity: AbuseSeverity.low,
        reason: 'Quiz completed too fast: ${result.elapsedSeconds}s '
            'for ${result.total} questions '
            '(${avgSeconds.toStringAsFixed(2)}s/q; '
            'threshold ${config.minSecondsPerQuestion}s/q)',
      );
    }

    return const QuizAbuseResult(severity: AbuseSeverity.none);
  }
}
