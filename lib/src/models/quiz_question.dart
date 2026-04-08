import 'dart:math';

import '../interfaces/quiz_item.dart';

enum QuizMode {
  multipleChoice,
  typeAnswer,
  pronunciationQuiz,
  speakChoice,
  progressive,
  sprint,
  timeAttack,
  dailyChallenge,
}

enum QuizDirection { enToTr, trToEn, mixed }

class QuizQuestion<T extends QuizItem> {
  QuizQuestion({
    required this.item,
    required this.choices,
    required this.direction,
  });

  final T item;
  final List<String> choices; // populated for multipleChoice/speakChoice; empty for typeAnswer
  final QuizDirection direction;

  String get prompt =>
      direction == QuizDirection.enToTr ? item.term : item.definition;

  String get answer =>
      direction == QuizDirection.enToTr ? item.definition : item.term;

  static List<QuizQuestion<T>> generate<T extends QuizItem>({
    required List<T> items,
    required QuizMode mode,
    required QuizDirection direction,
    required int count,
    int choiceCount = 4,
    Random? random,

    /// Optional ordered pool. When provided, the first [count] items from this
    /// pool become the questions (then shuffled for variety). The full [items]
    /// list is still used as the distractor pool for multiple-choice modes.
    List<T>? questionPool,
  }) {
    assert(items.length >= 4, 'Need at least 4 items');
    final rng = random ?? Random();
    final List<T> picked;
    if (questionPool != null && questionPool.isNotEmpty) {
      picked = List<T>.from(questionPool.take(count))..shuffle(rng);
    } else {
      final shuffled = List<T>.from(items)..shuffle(rng);
      picked = shuffled.take(count).toList();
    }
    // Clamp choice count to available items (minimum 2, maximum items.length).
    final effectiveChoiceCount = choiceCount.clamp(2, items.length);

    return picked.map((w) {
      final List<String> choices;
      // pronunciationQuiz and speakChoice always use trToEn direction
      // mixed randomly picks enToTr or trToEn per question
      final effectiveDirection =
          (mode == QuizMode.pronunciationQuiz || mode == QuizMode.speakChoice)
              ? QuizDirection.trToEn
              : direction == QuizDirection.mixed
                  ? (rng.nextBool()
                      ? QuizDirection.enToTr
                      : QuizDirection.trToEn)
                  : direction;
      if (mode == QuizMode.multipleChoice ||
          mode == QuizMode.progressive ||
          mode == QuizMode.sprint ||
          mode == QuizMode.timeAttack ||
          mode == QuizMode.dailyChallenge) {
        final correct = effectiveDirection == QuizDirection.enToTr
            ? w.definition
            : w.term;
        final distractors = items
            .where((d) => d.term != w.term)
            .map((d) => effectiveDirection == QuizDirection.enToTr
                ? d.definition
                : d.term)
            .toSet()
            .toList()
          ..shuffle(rng);
        choices = ([correct] + distractors.take(effectiveChoiceCount - 1).toList())
          ..shuffle(rng);
      } else if (mode == QuizMode.speakChoice) {
        // 3 choices: 1 correct + 2 distractors
        final correct = effectiveDirection == QuizDirection.enToTr
            ? w.definition
            : w.term;
        final distractors = items
            .where((d) => d.term != w.term)
            .map((d) => effectiveDirection == QuizDirection.enToTr
                ? d.definition
                : d.term)
            .toSet()
            .toList()
          ..shuffle(rng);
        choices = ([correct] + distractors.take(2).toList())..shuffle(rng);
      } else {
        choices = [];
      }
      return QuizQuestion<T>(
          item: w, choices: choices, direction: effectiveDirection);
    }).toList();
  }
}
