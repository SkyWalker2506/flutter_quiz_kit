import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/difficulty_level.dart';

const _kQuizAccuracyKey = 'quiz_accuracy_history';

/// Stores the last [kAdaptiveHistorySize] quiz accuracy rates (0.0–1.0).
class QuizAccuracyLocalDataSource {
  QuizAccuracyLocalDataSource(this._prefs);

  final SharedPreferencesAsync _prefs;

  Future<List<double>> getRecentAccuracies() async {
    final raw = await _prefs.getString(_kQuizAccuracyKey);
    if (raw == null) return [];
    final list = json.decode(raw) as List<dynamic>;
    return list.map((e) => (e as num).toDouble()).toList();
  }

  /// Appends [accuracy] and trims to the last [kAdaptiveHistorySize] entries.
  Future<void> addAccuracy(double accuracy) async {
    final recent = await getRecentAccuracies();
    recent.add(accuracy.clamp(0.0, 1.0));
    if (recent.length > kAdaptiveHistorySize) {
      recent.removeRange(0, recent.length - kAdaptiveHistorySize);
    }
    await _prefs.setString(_kQuizAccuracyKey, json.encode(recent));
  }

  /// Average of the stored accuracy values; returns null when no data.
  Future<double?> averageAccuracy() async {
    final recent = await getRecentAccuracies();
    if (recent.isEmpty) return null;
    return recent.reduce((a, b) => a + b) / recent.length;
  }

  Future<void> clearAll() async {
    await _prefs.remove(_kQuizAccuracyKey);
  }
}
