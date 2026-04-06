/// Adaptive quiz difficulty derived from the user's recent accuracy.
enum DifficultyLevel { easy, medium, hard }

/// Parameters applied to a quiz based on difficulty.
class DifficultyParams {
  const DifficultyParams({
    required this.choiceCount,
    required this.timeLimitSeconds,
  });

  /// Number of multiple-choice options shown per question.
  final int choiceCount;

  /// Per-question time limit in seconds. 0 = no limit.
  final int timeLimitSeconds;

  static const Map<DifficultyLevel, DifficultyParams> _defaults = {
    DifficultyLevel.easy: DifficultyParams(choiceCount: 3, timeLimitSeconds: 0),
    DifficultyLevel.medium:
        DifficultyParams(choiceCount: 4, timeLimitSeconds: 30),
    DifficultyLevel.hard:
        DifficultyParams(choiceCount: 6, timeLimitSeconds: 15),
  };

  static DifficultyParams forLevel(DifficultyLevel level) => _defaults[level]!;

  /// Default params when adaptive mode is off or no data is available.
  static const DifficultyParams defaultParams =
      DifficultyParams(choiceCount: 4, timeLimitSeconds: 0);
}

/// Number of recent quiz results used for adaptive difficulty calculation.
const kAdaptiveHistorySize = 10;

/// Progressive quiz difficulty tier — maps level ranges to quiz parameters.
class ProgressiveTier {
  const ProgressiveTier({
    required this.minLevel,
    required this.maxLevel,
    required this.choiceCount,
    required this.timeLimitSeconds,
    required this.hintsAllowed,
    required this.xpMultiplier,
  });

  final int minLevel;
  final int maxLevel;
  final int choiceCount;
  final int timeLimitSeconds; // 0 = no limit
  final int hintsAllowed;
  final double xpMultiplier;

  bool containsLevel(int level) => level >= minLevel && level <= maxLevel;

  static const List<ProgressiveTier> tiers = [
    ProgressiveTier(
        minLevel: 1,
        maxLevel: 10,
        choiceCount: 3,
        timeLimitSeconds: 0,
        hintsAllowed: 2,
        xpMultiplier: 0.5),
    ProgressiveTier(
        minLevel: 11,
        maxLevel: 25,
        choiceCount: 4,
        timeLimitSeconds: 30,
        hintsAllowed: 1,
        xpMultiplier: 1.0),
    ProgressiveTier(
        minLevel: 26,
        maxLevel: 50,
        choiceCount: 4,
        timeLimitSeconds: 20,
        hintsAllowed: 0,
        xpMultiplier: 1.5),
    ProgressiveTier(
        minLevel: 51,
        maxLevel: 75,
        choiceCount: 6,
        timeLimitSeconds: 15,
        hintsAllowed: 0,
        xpMultiplier: 2.0),
    ProgressiveTier(
        minLevel: 76,
        maxLevel: 100,
        choiceCount: 6,
        timeLimitSeconds: 10,
        hintsAllowed: 0,
        xpMultiplier: 3.0),
  ];

  static ProgressiveTier forLevel(int level) =>
      tiers.firstWhere((t) => t.containsLevel(level), orElse: () => tiers.last);

  /// Checkpoint every N levels — user can resume from last checkpoint.
  static const int checkpointInterval = 10;

  /// Maximum lives in progressive mode.
  static const int maxLives = 3;
}

/// Derives a [DifficultyLevel] from the average accuracy of recent quizzes.
///
/// * accuracy >= 0.80  -> [DifficultyLevel.hard]
/// * accuracy < 0.50   -> [DifficultyLevel.easy]
/// * otherwise         -> [DifficultyLevel.medium]
DifficultyLevel difficultyFromAccuracy(double accuracy) {
  if (accuracy >= 0.80) return DifficultyLevel.hard;
  if (accuracy < 0.50) return DifficultyLevel.easy;
  return DifficultyLevel.medium;
}
