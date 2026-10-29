import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../services/sfx.dart';
import '../state/game_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Every badge, with the gems it pays. Earned badges have a Claim button
/// until their gems are collected.
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  /// The badge just claimed and a counter, to replay its confetti.
  String? _burstId;
  int _burst = 0;

  Future<void> _claim(GameState game, Achievement a) async {
    final got = await game.claimBadge(a);
    if (got == 0 || !mounted) return;
    Sfx.gem.play();
    HapticFeedback.mediumImpact();
    setState(() {
      _burstId = a.id;
      _burst++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final waiting = achievements.where(game.canClaim).toList();
    final waitingGems = waiting.fold(0, (sum, a) => sum + a.gems);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Badges', style: display(30)),
                  Text(
                    '${game.unlocked.length} of ${achievements.length} earned',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Pill(
              '${game.gems}',
              icon: Icons.diamond_rounded,
              iconColor: const Color(0xFF3A9BC8),
            ),
          ],
        ),
        if (waitingGems > 0) ...[
          const SizedBox(height: 12),
          PopIn(
            child: PaperCard(
              color: AppColors.gold,
              tilt: -0.6,
              seed: 77,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  const Icon(Icons.redeem_rounded, color: AppColors.ink),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$waitingGems gems waiting! Tap Claim on your '
                      'new ${waiting.length == 1 ? 'badge' : 'badges'}.',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        for (final (i, a) in achievements.indexed) ...[
          PopIn(
            delay: Duration(milliseconds: 40 * i),
            from: const Offset(0, 20),
            startScale: 0.9,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _BadgeCard(
                  achievement: a,
                  index: i,
                  game: game,
                  onClaim: () => _claim(game, a),
                ),
                if (_burstId == a.id)
                  Positioned(
                    right: 10,
                    top: -40,
                    width: 140,
                    height: 140,
                    child: IgnorePointer(
                      child: ConfettiBurst(
                        key: ValueKey(_burst),
                        count: 22,
                        power: 0.7,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.achievement,
    required this.index,
    required this.game,
    required this.onClaim,
  });

  final Achievement achievement;
  final int index;
  final GameState game;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final earned = game.unlocked.contains(a.id);
    final hidden = a.secret && !earned;
    final Widget reward;
    if (game.canClaim(a)) {
      reward = PaperButton(
        label: 'Claim +${a.gems}',
        icon: Icons.diamond_rounded,
        onPressed: onClaim,
        expand: false,
        size: 14,
      );
    } else if (earned) {
      reward = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: AppColors.rightInk,
          ),
          const SizedBox(width: 4),
          Text('+${a.gems}', style: display(15, color: AppColors.inkMuted)),
        ],
      );
    } else {
      reward = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('+${a.gems}', style: display(15, color: AppColors.muted)),
          const SizedBox(width: 3),
          Icon(
            Icons.diamond_rounded,
            size: 16,
            color: const Color(0xFF3A9BC8).withValues(alpha: 0.7),
          ),
        ],
      );
    }
    return PaperCard(
      color: earned ? AppColors.cream : AppColors.track,
      tilt: earned ? (index.isEven ? -0.8 : 0.8) : 0,
      seed: index + 90,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: earned ? AppColors.gold : AppColors.deep,
              border: Border.all(
                color: earned ? AppColors.orange : AppColors.hill,
                width: 3,
              ),
            ),
            child: Icon(
              hidden
                  ? Icons.question_mark_rounded
                  : earned
                  ? Icons.emoji_events_rounded
                  : Icons.lock_outline_rounded,
              color: earned ? AppColors.ink : AppColors.muted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hidden ? 'Secret badge' : a.title,
                  style: display(
                    18,
                    color: earned ? AppColors.ink : AppColors.text,
                  ),
                ),
                Text(
                  hidden ? 'Keep exploring to find out' : a.description,
                  style: TextStyle(
                    color: earned ? AppColors.inkMuted : AppColors.muted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          reward,
        ],
      ),
    );
  }
}
