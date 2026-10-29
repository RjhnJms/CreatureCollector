import 'dart:io';

import 'package:creature_collector/data/content.dart';
import 'package:creature_collector/services/sfx.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every creature sound is bundled and credited', () {
    final withSound = creatures.where((c) => c.sound != null).toList();
    expect(withSound, isNotEmpty);
    for (final c in withSound) {
      final sound = c.sound!;
      expect(
        File('assets/sounds/${sound.file}').existsSync(),
        isTrue,
        reason: '${c.name}: assets/sounds/${sound.file} is missing',
      );
      expect(sound.credit, contains('CC'), reason: '${c.name} needs a license');
    }
  });

  test('every sound effect file is bundled', () {
    for (final sfx in Sfx.values) {
      expect(
        File('assets/${sfx.file}').existsSync(),
        isTrue,
        reason: 'assets/${sfx.file} is missing',
      );
    }
  });

  test('silent creatures say why, and have no recording', () {
    final silent = creatures.where((c) => c.silentReason != null).toList();
    expect(silent, hasLength(12));
    for (final c in silent) {
      expect(c.sound, isNull, reason: '${c.name} is silent but has a sound');
      expect(c.silentReason, isNotEmpty, reason: c.name);
    }
  });
}
