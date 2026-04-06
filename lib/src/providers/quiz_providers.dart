import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quiz_accuracy_local_datasource.dart';
import '../models/difficulty_level.dart';
import '../services/quiz_sound_service.dart';

/// Must be overridden in [ProviderScope] before use.
final quizPrefsProvider = Provider<SharedPreferencesAsync>((ref) {
  throw UnimplementedError('Override quizPrefsProvider in ProviderScope');
});

final quizAccuracyDataSourceProvider = Provider<QuizAccuracyLocalDataSource>(
  (ref) => QuizAccuracyLocalDataSource(ref.read(quizPrefsProvider)),
);

/// Provides the average accuracy (0.0–1.0) of the last [kAdaptiveHistorySize]
/// quizzes. Returns null when no quiz history is available.
final recentAverageAccuracyProvider = FutureProvider<double?>((ref) async {
  return ref.read(quizAccuracyDataSourceProvider).averageAccuracy();
});

/// Provides adaptive [DifficultyParams] derived from recent quiz accuracy.
/// Falls back to [DifficultyParams.defaultParams] when no data is available.
final adaptiveDifficultyParamsProvider =
    FutureProvider<DifficultyParams>((ref) async {
  final avg = await ref.watch(recentAverageAccuracyProvider.future);
  if (avg == null) return DifficultyParams.defaultParams;
  final level = difficultyFromAccuracy(avg);
  return DifficultyParams.forLevel(level);
});

/// Riverpod provider that exposes the [QuizSoundService] singleton.
final quizSoundServiceProvider = Provider<QuizSoundService>(
  (ref) => QuizSoundService.instance,
);
