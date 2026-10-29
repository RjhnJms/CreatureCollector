import 'dart:math';

import 'package:creature_collector/data/content.dart';
import 'package:creature_collector/data/models.dart';
import 'package:creature_collector/data/partners.dart';
import 'package:creature_collector/data/rewards.dart';
import 'package:creature_collector/state/game_state.dart';
import 'package:creature_collector/state/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('content', () {
    test('every creature has a bank of 10 questions', () {
      for (final c in creatures) {
        expect(questionsFor(c.id).length, 10, reason: c.id);
      }
    });

    test('no two questions share a prompt for the same creature', () {
      for (final c in creatures) {
        final prompts = questionsFor(c.id).map((q) => q.prompt).toList();
        expect(prompts.toSet().length, prompts.length, reason: c.id);
      }
    });

    test('answers point at real options and creatures', () {
      for (final q in questions) {
        expect(
          creatureById.containsKey(q.creatureId),
          isTrue,
          reason: q.prompt,
        );
        switch (q) {
          case ChoiceQuestion():
            expect(
              q.answer,
              inInclusiveRange(0, q.options.length - 1),
              reason: q.prompt,
            );
          case PictureQuestion():
            expect(q.optionIds, contains(q.answerId), reason: q.prompt);
            for (final id in q.optionIds) {
              expect(creatureById.containsKey(id), isTrue, reason: id);
            }
          case SortQuestion():
            for (final bin in q.items.values) {
              expect(
                bin,
                inInclusiveRange(0, q.bins.length - 1),
                reason: q.prompt,
              );
            }
        }
      }
    });

    test('stages reference real creatures in their own habitat', () {
      for (final s in stages) {
        for (final id in s.creatureIds) {
          expect(creatureById[id]!.habitatId, s.habitatId, reason: s.id);
        }
      }
    });
  });

  group('stage session', () {
    final stage = stageById['r2']!;

    StageSession playPerfect() {
      final s = StageSession(stage, random: Random(1));
      while (!s.isFinished) {
        if (s.current is QuestionStep) s.answer(true);
        s.next();
      }
      return s;
    }

    test('a stage asks 5 random questions per creature', () {
      final a = StageSession(stage, random: Random(1));
      final b = StageSession(stage, random: Random(7));
      expect(a.questionCount, 2 * StageSession.questionsPerCreature);
      List<String> prompts(StageSession s) => [
        for (final st in s.steps.whereType<QuestionStep>()) st.question.prompt,
      ];
      expect(prompts(a), isNot(prompts(b)));
    });

    test('a perfect run earns 3 stars and catches both creatures', () {
      final s = playPerfect();
      expect(s.stars, 3);
      expect(s.caught, ['tarsier', 'firefly']);
    });

    test('three mistakes fail the stage', () {
      final s = StageSession(stage, random: Random(1));
      var wrong = 0;
      while (!s.isFinished) {
        if (s.current is QuestionStep) s.answer(wrong++ >= 3);
        if (!s.isFinished) s.next();
      }
      expect(s.failed, isTrue);
      expect(s.stars, 0);
    });

    test('two mistakes on one creature means it escapes', () {
      final s = StageSession(stage, random: Random(1));
      var asked = 0;
      while (!s.isFinished) {
        if (s.current is QuestionStep) s.answer(asked++ >= 2);
        s.next();
      }
      expect(s.caught, ['firefly']);
      expect(s.stars, 1);
    });

    test('boss stage asks 10 questions from its habitat', () {
      final s = StageSession(stageById['o4']!, random: Random(2));
      expect(s.questionCount, StageSession.bossQuestionCount);
      for (final step in s.steps) {
        final q = (step as QuestionStep).question;
        expect(creatureById[q.creatureId]!.habitatId, 'ocean');
      }
    });
  });

  group('game state', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('finishing a habitat unlocks the next one', () async {
      final game = await GameState.load();
      final ocean = habitatById['ocean']!;
      expect(game.isHabitatUnlocked(ocean), isFalse);
      for (final id in habitatById['rainforest']!.stageIds) {
        await game.recordStage(
          StageResult(stageId: id, stars: 3, correct: 8, found: 2, caught: []),
        );
      }
      expect(game.isHabitatUnlocked(ocean), isTrue);
      expect(game.nextStage?.id, 'o1');
    });

    test('first catch earns a badge once', () async {
      final game = await GameState.load();
      final first = await game.recordStage(
        const StageResult(
          stageId: 'r1',
          stars: 2,
          correct: 7,
          found: 2,
          caught: ['eagle'],
        ),
      );
      expect(first.map((a) => a.id), contains('first_catch'));
      final again = await game.recordStage(
        const StageResult(
          stageId: 'r1',
          stars: 3,
          correct: 8,
          found: 2,
          caught: ['eagle'],
        ),
      );
      expect(again.map((a) => a.id), isNot(contains('first_catch')));
    });

    test('streak counts consecutive days', () async {
      final game = await GameState.load();
      final today = DateTime(2026, 10, 12);
      game.playDays = [
        GameState.dayKey(today),
        GameState.dayKey(today.subtract(const Duration(days: 1))),
        GameState.dayKey(today.subtract(const Duration(days: 3))),
      ];
      expect(game.streak(today), 2);
    });
  });

  group('rewards', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('new creatures earn gems, repeats do not', () async {
      final game = await GameState.load();
      await game.recordStage(
        const StageResult(
          stageId: 'r1',
          stars: 1,
          correct: 6,
          found: 2,
          caught: ['eagle'],
        ),
      );
      final afterFirst = game.gems;
      // Replay without finishing the daily mission, which would add gems.
      await game.recordStage(
        const StageResult(
          stageId: 'r1',
          stars: 1,
          correct: 0,
          found: 0,
          caught: ['eagle'],
        ),
      );
      expect(afterFirst, 5 + GameState.gemsPerNewCreature);
      expect(game.gems, afterFirst);
    });

    test('buying needs enough gems, then the item can be worn', () async {
      final game = await GameState.load();
      final hat = rewardById['salakot']!;
      expect(await game.buy(hat), isFalse);
      game.gems = 50;
      expect(await game.buy(hat), isTrue);
      expect(game.gems, 10);
      expect(await game.buy(hat), isFalse, reason: 'already owned');
      await game.equip(hat);
      expect(game.outfitItems, ['salakot']);
      await game.equip(rewardById['golden_salakot']!);
      expect(game.outfitItems, ['salakot'], reason: 'gift not owned yet');
      await game.equip(hat);
      expect(game.outfitItems, isEmpty, reason: 'tapping again takes it off');
    });

    test('moon gifts cannot be bought', () async {
      final game = await GameState.load();
      game.gems = 999;
      expect(await game.buy(rewardById['moon_cape']!), isFalse);
    });

    test('a 3-night streak earns the bituin parols', () async {
      final game = await GameState.load();
      final today = DateTime.now();
      game.playDays = [
        for (var i = 1; i <= 2; i++)
          GameState.dayKey(DateTime(today.year, today.month, today.day - i)),
      ];
      await game.recordStage(
        const StageResult(
          stageId: 'r1',
          stars: 1,
          correct: 6,
          found: 2,
          caught: [],
        ),
      );
      expect(game.owns('bituin'), isTrue);
      expect(game.pendingGifts.map((g) => g.id), ['bituin']);
      expect(game.owns('moon_cape'), isFalse);
    });

    test('3 stars make the stage creatures shiny', () async {
      final game = await GameState.load();
      await game.recordStage(
        const StageResult(
          stageId: 'r2',
          stars: 2,
          correct: 7,
          found: 2,
          caught: ['tarsier', 'firefly'],
        ),
      );
      expect(game.isShiny('tarsier'), isFalse);
      await game.recordStage(
        const StageResult(
          stageId: 'r2',
          stars: 3,
          correct: 8,
          found: 2,
          caught: ['tarsier', 'firefly'],
        ),
      );
      expect(game.isShiny('tarsier'), isTrue);
      expect(game.isShiny('eagle'), isFalse);
    });

    test('every reward with a picture has a painter or parol style', () {
      for (final r in rewards) {
        if (r.kind == RewardKind.parol) {
          expect(parolStyles.containsKey(r.id), isTrue, reason: r.id);
        } else {
          expect(r.slot, isNotNull, reason: r.id);
        }
      }
    });
  });

  group('partners', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('players from before partners keep Tarsi', () async {
      SharedPreferences.setMockInitialValues({'flutter.name': 'Ana'});
      final game = await GameState.load();
      expect(game.partnerId, 'tarsi');
      expect(game.partnerName, 'Tarsi');
    });

    test('the chosen partner and name are saved', () async {
      final game = await GameState.load();
      await game.createProfile(
        'Ana',
        2,
        partner: 'pawi',
        partnerName: 'Bubbles',
      );
      final again = await GameState.load();
      expect(again.partnerId, 'pawi');
      expect(again.partnerName, 'Bubbles');
    });

    test('switching is free, keeps the outfit, and remembers names', () async {
      final game = await GameState.load();
      await game.createProfile(
        'Ana',
        2,
        partner: 'pawi',
        partnerName: 'Bubbles',
      );
      game.gems = 50;
      game.owned.add('glasses');
      await game.equip(rewardById['glasses']!);
      await game.choosePartner('haribon');
      expect(game.gems, 50);
      expect(game.partnerName, 'Haribon');
      expect(game.isWearing('glasses'), isTrue);
      await game.choosePartner('pawi');
      expect(game.partnerName, 'Bubbles');
    });

    test('a blank name goes back to the default', () async {
      final game = await GameState.load();
      await game.createProfile(
        'Ana',
        2,
        partner: 'haribon',
        partnerName: '   ',
      );
      expect(game.partnerName, 'Haribon');
      await game.renamePartner('Bagwis');
      expect(game.partnerName, 'Bagwis');
      await game.renamePartner('');
      expect(game.partnerName, 'Haribon');
    });

    test('every partner has things to say', () {
      for (final p in partners) {
        expect(p.lines, isNotEmpty, reason: p.id);
      }
      expect(partnerOf('nobody').id, defaultPartner);
    });
  });
}
