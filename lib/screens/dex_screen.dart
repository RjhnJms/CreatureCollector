import 'dart:math';

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../services/sounds.dart';
import '../state/game_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/creature_art.dart';
import '../widgets/listen_button.dart';

/// The collection as a sticker album: caught creatures are stuck in as
/// cream paper stickers, missing ones are dark paper silhouettes.
class DexScreen extends StatelessWidget {
  const DexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    var tile = 0;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dex', style: display(30)),
                Text(
                  '${game.caught.length} of ${creatures.length} creatures found',
                  style: const TextStyle(color: AppColors.muted, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Meter(game.caught.length / creatures.length),
              ],
            ),
          ),
        ),
        for (final h in habitats.where((h) => !h.comingSoon)) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            sliver: SliverToBoxAdapter(child: Text(h.name, style: display(20))),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.count(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
              children: [
                for (final c in creatures.where((c) => c.habitatId == h.id))
                  PopIn(
                    delay: Duration(milliseconds: 40 * tile++),
                    startScale: 0.6,
                    child: _DexTile(
                      creature: c,
                      caught: game.caught.contains(c.id),
                      shiny: game.isShiny(c.id),
                      tilt: const [-2.0, 1.5, -1.0, 2.0, -1.5, 1.0][tile % 6],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}

class _DexTile extends StatelessWidget {
  const _DexTile({
    required this.creature,
    required this.caught,
    required this.tilt,
    this.shiny = false,
  });
  final Creature creature;
  final bool caught;
  final double tilt;

  /// Gold-foil card, earned with 3 stars on the creature's stage.
  final bool shiny;

  @override
  Widget build(BuildContext context) {
    final card = PaperCard(
      color: shiny
          ? const Color(0xFFFFE7A3)
          : (caught ? AppColors.cream : AppColors.track),
      tilt: caught ? tilt : 0,
      seed: creature.id.length,
      padding: const EdgeInsets.all(8),
      onTap: caught ? () => _showCard(context) : null,
      child: Column(
        children: [
          Expanded(
            child: FittedBox(
              child: CreatureArt(creature, size: 90, silhouette: !caught),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caught ? creature.name : '???',
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: caught ? AppColors.ink : AppColors.muted,
            ),
          ),
        ],
      ),
    );
    if (!shiny) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned.fill(
          child: IgnorePointer(child: _Foil(tilt: tilt)),
        ),
        const Positioned(
          right: -4,
          top: -6,
          child: Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.orange,
            size: 22,
          ),
        ),
      ],
    );
  }

  void _showCard(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => OnPaper(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopIn(
                startScale: 0.4,
                child: CreatureArt(creature, size: 170, animate: true),
              ),
              const SizedBox(height: 8),
              Text(
                creature.name,
                style: display(27),
                textAlign: TextAlign.center,
              ),
              if (creature.localName.isNotEmpty)
                Text(
                  creature.localName,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  Pill(creature.kind, icon: Icons.pets_rounded),
                  creature.alive
                      ? Pill(
                          creature.time.activeLabel,
                          icon: timeIcon(creature.time),
                        )
                      : const Pill('Not living', icon: Icons.landscape_rounded),
                  if (shiny)
                    const Pill('Shiny card', icon: Icons.auto_awesome_rounded),
                  Pill(switch (creature.rarity) {
                    Rarity.common => 'Common',
                    Rarity.rare => 'Rare',
                    Rarity.legendary => 'Legendary',
                  }, icon: Icons.auto_awesome_rounded),
                ],
              ),
              if (creature.sound case final sound?) ...[
                const SizedBox(height: 14),
                ListenButton(sound),
              ] else if (creature.silentReason case final why?) ...[
                const SizedBox(height: 14),
                _SilentNote(why),
              ],
              const SizedBox(height: 16),
              PaperCard(
                color: const Color(0xFFFFF6E0),
                tilt: -0.6,
                child: Text(
                  creature.fact,
                  style: const TextStyle(fontSize: 17, height: 1.45),
                ),
              ),
              if (creature.sound case final sound?) ...[
                const SizedBox(height: 12),
                Text(
                  sound.credit,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).whenComplete(Sounds.instance.stop);
  }
}

/// A band of light that sweeps across a shiny card now and then.
class _Foil extends StatefulWidget {
  const _Foil({required this.tilt});
  final double tilt;

  @override
  State<_Foil> createState() => _FoilState();
}

class _FoilState extends State<_Foil> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 2600 + Random().nextInt(1200)),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return const SizedBox.shrink();
    }
    return Transform.rotate(
      angle: widget.tilt * pi / 180,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(painter: _FoilPainter(_c.value)),
        ),
      ),
    );
  }
}

class _FoilPainter extends CustomPainter {
  _FoilPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Sweep during the first half of the loop, rest during the second.
    if (t > 0.5) return;
    final x = (t / 0.5) * (size.width + size.height) - size.height;
    final band = Path()
      ..moveTo(x, size.height)
      ..lineTo(x + 18, size.height)
      ..lineTo(x + 18 + size.height, 0)
      ..lineTo(x + size.height, 0)
      ..close();
    canvas.drawPath(
      band,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_FoilPainter old) => old.t != t;
}

/// Shown instead of a Listen button for creatures that make no sound.
class _SilentNote extends StatelessWidget {
  const _SilentNote(this.why);
  final String why;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Silent. $why',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEADCBC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.volume_off_rounded,
              color: AppColors.inkMuted,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Silent  ',
                      style: display(15, color: AppColors.ink),
                    ),
                    TextSpan(text: why),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
