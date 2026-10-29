import 'package:creature_collector/widgets/partner_move.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where the partner's body is moved to right now.
Offset _offset(WidgetTester tester) {
  final moves = tester.widgetList<Transform>(
    find.descendant(
      of: find.byType(PartnerTapMove),
      matching: find.byType(Transform),
    ),
  );
  final v = moves.first.transform.getTranslation();
  return Offset(v.x, v.y);
}

/// How far up the partner's body is lifted right now.
double _lift(WidgetTester tester) => -_offset(tester).dy;

Future<void> _pump(WidgetTester tester, String id, int trigger) =>
    tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: PartnerTapMove(
            trigger: trigger,
            size: 150,
            partnerId: id,
            surfaceRise: 90,
            leapX: 120,
            leapRise: 70,
          ),
        ),
      ),
    );

void main() {
  testWidgets('Pawi swims up to the surface and back down', (tester) async {
    await _pump(tester, 'pawi', 0);
    await _pump(tester, 'pawi', 1);
    await tester.pump(const Duration(milliseconds: 1056)); // t = 0.44
    expect(_lift(tester), closeTo(90, 1));
    expect(find.text('puff!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(_lift(tester), 0);
    expect(find.text('puff!'), findsNothing);
  });

  testWidgets('Haribon lifts off and lands', (tester) async {
    await _pump(tester, 'haribon', 0);
    await _pump(tester, 'haribon', 1);
    await tester.pump(const Duration(milliseconds: 480)); // t = 0.30
    expect(_lift(tester), closeTo(58 * 150 / 120, 1));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(_lift(tester), 0);
  });

  testWidgets('Tarsi leaps to the trunk, clings, and leaps back', (
    tester,
  ) async {
    await _pump(tester, 'tarsi', 0);
    await _pump(tester, 'tarsi', 1);
    await tester.pump(const Duration(milliseconds: 1200)); // t = 0.5, clinging
    expect(_offset(tester).dx, closeTo(120, 0.5));
    expect(_lift(tester), closeTo(70, 0.5));
    await tester.pump(const Duration(milliseconds: 1300));
    expect(_offset(tester), Offset.zero);
  });
}
