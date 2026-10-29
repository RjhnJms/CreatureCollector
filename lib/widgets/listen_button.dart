import 'package:flutter/material.dart';

import '../data/models.dart';
import '../services/sounds.dart';
import '../state/settings.dart';
import '../theme.dart';
import 'common.dart';

/// Plays a creature's real call. Shows "Playing…" while it plays; tap again
/// to stop. [compact] is a round speaker button for tight spots.
class ListenButton extends StatelessWidget {
  const ListenButton(this.sound, {super.key, this.compact = false});
  final CreatureSound sound;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final sounds = Sounds.instance;
    if (!Settings.instance.animalCalls) return const SizedBox.shrink();
    return ValueListenableBuilder(
      valueListenable: sounds.playing,
      builder: (context, now, _) {
        final on = now == sound;
        void toggle() => on ? sounds.stop() : sounds.play(sound);
        if (compact) {
          return Semantics(
            label: on ? 'Stop sound' : 'Listen to its call',
            button: true,
            excludeSemantics: true,
            child: Squish(
              onTap: toggle,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: on
                      ? AppColors.orange
                      : AppColors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  on ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                  color: on ? AppColors.cream : AppColors.orange,
                  size: 22,
                ),
              ),
            ),
          );
        }
        return PaperButton(
          label: on ? 'Playing…' : 'Listen',
          icon: on ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
          onPressed: toggle,
          expand: false,
          size: 17,
        );
      },
    );
  }
}
