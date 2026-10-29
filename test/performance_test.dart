import 'package:creature_collector/data/content.dart';
import 'package:creature_collector/widgets/creature_art.dart';
import 'package:creature_collector/widgets/scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps one second at 60 frames a second.
Future<void> oneSecond(WidgetTester tester) async {
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(microseconds: 16667));
  }
}

void main() {
  testWidgets('a scene redraws about 30 times a second, not every frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: PaperScene(habitatId: 'rainforest'),
      ),
    );
    ScenePainter.debugPaints = 0;
    await oneSecond(tester);
    final paints = ScenePainter.debugPaints;
    // ignore: avoid_print
    print('scene paints in 1 s at 60 fps: $paints');
    expect(paints, inInclusiveRange(28, 31));
  });

  testWidgets('a breathing creature redraws about 30 times a second', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CreatureArt(creatureById['tarsier']!, animate: true),
      ),
    );
    debugCreaturePaints = 0;
    await oneSecond(tester);
    // ignore: avoid_print
    print('creature paints in 1 s at 60 fps: $debugCreaturePaints');
    expect(debugCreaturePaints, inInclusiveRange(28, 32));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('scenes stay still with reduced motion', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: PaperScene(habitatId: 'ocean'),
        ),
      ),
    );
    ScenePainter.debugPaints = 0;
    await oneSecond(tester);
    expect(ScenePainter.debugPaints, 0);
  });
}
