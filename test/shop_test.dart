import 'package:creature_collector/data/rewards.dart';
import 'package:creature_collector/screens/shop_screen.dart';
import 'package:creature_collector/state/game_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final hat = rewards.firstWhere(
    (r) => r.kind == RewardKind.outfit && r.price != null,
  );

  group('shop preview', () {
    test('tries on an item you do not own yet', () {
      expect(shopPreviewOutfit({}, hat, owned: false), [hat.id]);
    });

    test('shows an owned item only while it is worn', () {
      expect(shopPreviewOutfit({hat.slot!.name: hat.id}, hat, owned: true), [
        hat.id,
      ]);
      // Taken off: the preview must not keep showing it.
      expect(shopPreviewOutfit({}, hat, owned: true), isEmpty);
    });
  });

  test('equipping a worn item takes it off', () async {
    SharedPreferences.setMockInitialValues({'flutter.name': 'Ana'});
    final game = await GameState.load();
    game.gems = hat.price!;
    expect(await game.buy(hat), isTrue);

    await game.equip(hat);
    expect(game.isWearing(hat.id), isTrue);

    await game.equip(hat);
    expect(game.isWearing(hat.id), isFalse);
    expect(game.outfitItems, isNot(contains(hat.id)));

    // It stays off after a restart.
    final again = await GameState.load();
    expect(again.isWearing(hat.id), isFalse);
  });
}
