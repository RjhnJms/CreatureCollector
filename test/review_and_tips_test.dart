import 'package:creature_collector/data/content.dart';
import 'package:creature_collector/screens/stage/search_view.dart';
import 'package:creature_collector/state/game_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('review mistakes', () {
    setUp(
      () => SharedPreferences.setMockInitialValues({'flutter.name': 'Ana'}),
    );

    test('wrong answers are saved and right answers clear them', () async {
      final game = await GameState.load();
      final q1 = questionsFor('tarsier')[0];
      final q2 = questionsFor('tarsier')[1];
      await game.noteAnswer(q1, false);
      await game.noteAnswer(q2, false);
      expect(game.reviewQuestions, [q2, q1]);

      await game.noteAnswer(q1, true);
      expect(game.reviewQuestions, [q2]);

      // Missing the same question twice keeps one copy.
      await game.noteAnswer(q2, false);
      expect(game.toReview.length, 1);

      // It survives a restart.
      final again = await GameState.load();
      expect(again.reviewQuestions, [q2]);
    });

    test('a practice round pays gems for each fix', () async {
      final game = await GameState.load();
      final before = game.gems;
      await game.finishReview(3);
      expect(game.gems, before + 3 * GameState.gemsPerFix);
    });

    test('the review list stays a manageable size', () async {
      final game = await GameState.load();
      for (final q in questions.take(GameState.reviewCap + 5)) {
        await game.noteAnswer(q, false);
      }
      expect(game.toReview.length, GameState.reviewCap);
    });
  });

  group('search tutorial', () {
    Future<GameState> pump(WidgetTester tester, {bool seen = false}) async {
      SharedPreferences.setMockInitialValues({
        'flutter.name': 'Ana',
        if (seen) 'flutter.seenTips': ['search_flashlight'],
      });
      final game = (await tester.runAsync(GameState.load))!;
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GameScope(
          state: game,
          child: MaterialApp(
            home: Scaffold(
              body: SearchView(
                creature: creatureById['tarsier']!,
                onFound: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      return game;
    }

    Future<void> finish(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    }

    testWidgets('shows the first time, then goes away on drag', (tester) async {
      final game = await pump(tester);
      expect(find.byIcon(Icons.touch_app_rounded), findsOneWidget);
      expect(find.textContaining('Drag your finger'), findsOneWidget);

      await tester.dragFrom(const Offset(200, 500), const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byIcon(Icons.touch_app_rounded), findsNothing);
      expect(game.hasSeenTip('search_flashlight'), isTrue);
      await finish(tester);
    });

    testWidgets('does not show again once seen', (tester) async {
      await pump(tester, seen: true);
      expect(find.byIcon(Icons.touch_app_rounded), findsNothing);
      await finish(tester);
    });
  });
}
