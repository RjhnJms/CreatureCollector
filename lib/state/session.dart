import 'dart:math';

import '../data/content.dart';
import '../data/models.dart';

/// One step in a stage: search for a creature, answer a question, or see
/// whether the creature was caught.
sealed class Step {
  const Step();
}

class SearchStep extends Step {
  const SearchStep(this.creature);
  final Creature creature;
}

class QuestionStep extends Step {
  const QuestionStep(this.question);
  final Question question;
}

class CatchStep extends Step {
  const CatchStep(this.creature);
  final Creature creature;
}

/// The rules for playing one stage. Pure Dart so it can be unit tested.
class StageSession {
  StageSession(this.stage, {Random? random}) : _random = random ?? Random() {
    steps = _buildSteps();
    for (final step in steps.whereType<QuestionStep>()) {
      _askedByCreature.update(
        step.question.creatureId,
        (n) => n + 1,
        ifAbsent: () => 1,
      );
    }
  }

  static const startHearts = 3;
  static const startHints = 2;
  static const bossQuestionCount = 10;

  /// Each creature has a bank of questions; a play asks this many of them,
  /// picked at random, so replays feel fresh.
  static const questionsPerCreature = 5;

  final Stage stage;
  final Random _random;
  late final List<Step> steps;

  int index = 0;
  int hearts = startHearts;
  int hints = startHints;
  int mistakes = 0;
  int correct = 0;
  final Map<String, int> _correctByCreature = {};
  final Map<String, int> _askedByCreature = {};
  final List<String> caught = [];

  Step get current => steps[index];
  bool get isFinished => index >= steps.length || failed;
  bool get failed => hearts <= 0;
  int get questionCount => steps.whereType<QuestionStep>().length;
  int get answeredCount => correct + mistakes;

  List<Step> _buildSteps() {
    if (stage.isBoss) {
      final pool =
          questions
              .where(
                (q) => creatureById[q.creatureId]!.habitatId == stage.habitatId,
              )
              .toList()
            ..shuffle(_random);
      return pool.take(bossQuestionCount).map(QuestionStep.new).toList();
    }
    return [
      for (final id in stage.creatureIds) ...[
        SearchStep(creatureById[id]!),
        ...(questionsFor(
          id,
        )..shuffle(_random)).take(questionsPerCreature).map(QuestionStep.new),
        CatchStep(creatureById[id]!),
      ],
    ];
  }

  /// Records an answer to the current question. Returns true if correct.
  bool answer(bool isCorrect) {
    final step = current as QuestionStep;
    if (isCorrect) {
      correct++;
      _correctByCreature.update(
        step.question.creatureId,
        (v) => v + 1,
        ifAbsent: () => 1,
      );
    } else {
      mistakes++;
      hearts--;
    }
    return isCorrect;
  }

  bool useHint() {
    if (hints == 0) return false;
    hints--;
    return true;
  }

  /// A creature is caught when you miss at most one of its questions.
  bool wasCaught(String creatureId) {
    final total = _askedByCreature[creatureId] ?? 0;
    return (_correctByCreature[creatureId] ?? 0) >= total - 1;
  }

  void next() {
    final step = current;
    if (step is CatchStep && wasCaught(step.creature.id)) {
      caught.add(step.creature.id);
    }
    index++;
  }

  /// One star lost per mistake. Losing all hearts means 0 stars (try again).
  int get stars => failed ? 0 : startHearts - mistakes;
}
