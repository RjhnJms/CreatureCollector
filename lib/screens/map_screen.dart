import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../state/game_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/scene.dart';
import 'habitat_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text('World map', style: display(30)),
        Text(
          '${game.totalStars} stars collected',
          style: const TextStyle(color: AppColors.muted, fontSize: 15),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < habitats.length; i++) ...[
          PopIn(
            delay: Duration(milliseconds: 80 * i),
            from: const Offset(0, 24),
            startScale: 0.9,
            child: _HabitatCard(
              index: i,
              habitat: habitats[i],
              unlocked: game.isHabitatUnlocked(habitats[i]),
              lockedReason: habitats[i].comingSoon
                  ? 'Coming soon'
                  : i > 0
                  ? 'Finish ${habitats[i - 1].name} to unlock'
                  : '',
              stars: habitats[i].stageIds.fold(
                0,
                (sum, id) => sum + (game.stars[id] ?? 0),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _HabitatCard extends StatelessWidget {
  const _HabitatCard({
    required this.index,
    required this.habitat,
    required this.unlocked,
    required this.lockedReason,
    required this.stars,
  });

  final int index;
  final Habitat habitat;
  final bool unlocked;
  final String lockedReason;
  final int stars;

  @override
  Widget build(BuildContext context) {
    final maxStars = habitat.stageIds.length * 3;
    final paper = unlocked ? AppColors.cream : const Color(0xFFB9B2C9);
    return PaperCard(
      color: paper,
      tilt: index.isEven ? -0.8 : 0.8,
      seed: index + 20,
      padding: const EdgeInsets.all(8),
      onTap: unlocked
          ? () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HabitatScreen(habitat: habitat),
              ),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: 96,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PaperScene(
                    habitatId: habitat.id,
                    time: habitat.time,
                    animate: unlocked,
                    perches: const [0.82],
                  ),
                  if (!unlocked)
                    Container(
                      color: const Color(0xCC12143A),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: AppColors.muted,
                        size: 32,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habitat.name, style: display(21)),
                const SizedBox(height: 2),
                Text(
                  unlocked ? habitat.blurb : lockedReason,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 14,
                  ),
                ),
                if (unlocked) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: AppColors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text('$stars / $maxStars', style: display(14)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}
