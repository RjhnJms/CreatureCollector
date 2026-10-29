import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../data/partners.dart';
import '../state/game_state.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../widgets/celebrations.dart';
import '../widgets/common.dart';
import '../widgets/scene.dart';
import 'review_screen.dart';
import 'settings_screen.dart';
import 'stage/stage_screen.dart';
import '../widgets/partner_move.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenMap});
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        _Hero(game: game),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MoonStreak(game: game),
              const SizedBox(height: 16),
              _Mission(game: game),
              const SizedBox(height: 18),
              _Continue(game: game, onOpenMap: onOpenMap),
              if (game.toReview.isNotEmpty) ...[
                const SizedBox(height: 16),
                _Practice(count: game.toReview.length),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown when there are missed questions to practice.
class _Practice extends StatelessWidget {
  const _Practice({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      seed: 31,
      tilt: 0.6,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const ReviewScreen())),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE2DDF2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.replay_rounded, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Practice time', style: display(18)),
                Text(
                  count == 1
                      ? '1 question to review · +${GameState.gemsPerFix} gems'
                      : '$count questions to review · '
                            '+${GameState.gemsPerFix} gems each',
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}

/// The home screen's clock, swapped out in tests to preview day and night.
@visibleForTesting
DateTime Function() homeClock = DateTime.now;

/// Whether the home scene is sunny: by the clock (6 am to 6 pm), unless
/// Settings says always day or always night.
bool get _isDay => Settings.instance.isDay(homeClock());

String _greeting() {
  final h = homeClock().hour;
  if (h < 12) return 'Magandang umaga';
  if (h < 18) return 'Magandang hapon';
  return 'Magandang gabi';
}

/// The partner's home scene: sunny with banderitas by day, starry with parols
/// at night. Tap the partner to make it hop and talk.
class _Hero extends StatefulWidget {
  const _Hero({required this.game});
  final GameState game;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  int _hops = 0;
  int _line = 0;
  bool _talking = false;

  /// The partner's first line greets the player by name; taps after that
  /// cycle through its fun facts.
  bool _greeted = false;
  Timer? _hide;

  /// Woken up by a tap. Night animals nap on the daytime home screen.
  bool _awake = false;

  bool get _day => _isDay;
  bool get _sleepy => _day && widget.game.partner.art.time == ActiveTime.night;

  @override
  void initState() {
    super.initState();
    // Say hello shortly after the screen opens, then hand out any moon
    // gifts earned since last time.
    _hide = Timer(const Duration(milliseconds: 900), () => _say(hop: false));
    _giftTimer = Timer(const Duration(milliseconds: 1600), _showGifts);
  }

  Timer? _giftTimer;

  Future<void> _showGifts() async {
    final game = widget.game;
    while (mounted && game.pendingGifts.isNotEmpty) {
      final gift = game.pendingGifts.removeAt(0);
      await showCelebration(
        context,
        GiftView(
          gift: gift,
          outfit: game.outfitItems,
          onUse: () => game.equip(gift),
        ),
      );
    }
  }

  void _say({bool hop = true}) {
    if (!mounted) return;
    if (hop) HapticFeedback.lightImpact();
    setState(() {
      if (hop) {
        _hops++;
        // The first tap shows the first fun fact, not the second.
        if (_greeted) {
          _line = (_line + 1) % widget.game.partner.lines.length;
        }
        _greeted = true;
        _awake = true;
      }
      _talking = true;
    });
    _hide?.cancel();
    _hide = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() {
          _talking = false;
          _awake = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    _giftTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    const height = 330.0;
    const art = 150.0;
    // Each partner sits in its own home: Pawi in the sea under the parols,
    // the others on the forest branch.
    final home = game.partner.home;
    final water = home.skyLine;
    final branchY = height * (water == null ? Perches.home.first : home.rest);
    final artTop = branchY - art * 0.95;
    return ListenableBuilder(
      listenable: Settings.instance,
      builder: (context, _) =>
          _scene(game, height, art, branchY, artTop, water, home),
    );
  }

  Widget _scene(
    GameState game,
    double height,
    double art,
    double branchY,
    double artTop,
    double? water,
    PartnerHome home,
  ) {
    final time = _day ? ActiveTime.day : ActiveTime.night;
    final snoring = _sleepy && !_awake;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          // Tarsi gets a tree trunk on the right to leap to.
          final trunkX = game.partnerId == 'tarsi' ? w - 50 : null;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: PaperScene(
                  key: ValueKey(home.habitatId),
                  habitatId: home.habitatId,
                  time: time,
                  layer: SceneLayer.back,
                  parols: true,
                  parolStyle: game.parolStyle,
                  midLeaves: true,
                  perches: water == null ? Perches.home : const [],
                  skyLine: water,
                  trunk: trunkX == null ? null : trunkX / w,
                ),
              ),
              Positioned(
                left: w / 2 - art / 2,
                top: artTop,
                child: GestureDetector(
                  onTap: _say,
                  child: PartnerTapMove(
                    trigger: _hops,
                    size: art,
                    surfaceRise: water == null
                        ? 0
                        : artTop + art * 0.505 - height * water,
                    leapX: trunkX == null ? 0 : trunkX - w / 2,
                    leapRise: art * 0.47,
                    sleepy: snoring,
                  ),
                ),
              ),
              Positioned.fill(
                child: PaperScene(
                  key: ValueKey('front-${home.habitatId}'),
                  habitatId: home.habitatId,
                  time: time,
                  layer: SceneLayer.front,
                ),
              ),
              if (snoring)
                Positioned(
                  left: w / 2 - 6,
                  top: artTop - 52,
                  child: const IgnorePointer(child: _Snore()),
                ),
              Positioned(
                left: 14,
                top: 16,
                right: 100,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _RankChip(
                    '${rankName(game.level)} · Lv ${game.level}',
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 14,
                child: Row(
                  children: [
                    const _SettingsButton(),
                    const SizedBox(width: 8),
                    Pill(
                      '${game.gems}',
                      icon: Icons.diamond_rounded,
                      iconColor: const Color(0xFF3A9BC8),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: max(12, w / 2 - art / 2 - 150),
                top: branchY - art * 0.95,
                width: 150,
                child: IgnorePointer(
                  child: AnimatedScale(
                    scale: _talking ? 1 : 0.3,
                    alignment: Alignment.bottomRight,
                    duration: const Duration(milliseconds: 320),
                    curve: _talking ? Curves.elasticOut : Curves.easeIn,
                    child: AnimatedOpacity(
                      opacity: _talking ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: _SpeechBubble(
                        _greeted
                            ? game.partner.lines[_line %
                                  game.partner.lines.length]
                            : _sleepy
                            ? '${_greeting()}, ${game.name}! '
                                  'Zzz… I nap by day.'
                            : '${_greeting()}, ${game.name}!',
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Center(
                  child: Text(
                    'Tap ${game.partnerName}',
                    style: TextStyle(
                      color: (_day ? AppColors.ink : AppColors.text).withValues(
                        alpha: 0.6,
                      ),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Little Z's drifting up from a napping partner.
class _Snore extends StatefulWidget {
  const _Snore();

  @override
  State<_Snore> createState() => _SnoreState();
}

class _SnoreState extends State<_Snore> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return SizedBox(
      width: 80,
      height: 76,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          children: [
            for (var i = 0; i < 3; i++)
              Builder(
                builder: (context) {
                  // Small to big along a diagonal, each drifting up a
                  // little and fading in turn.
                  final t = still ? 0.5 : (_c.value + i / 3) % 1;
                  return Positioned(
                    left: 4 + i * 18 + t * 8,
                    bottom: i * 16 + t * 12,
                    child: Opacity(
                      opacity: still ? 1 : 0.35 + 0.65 * sin(t * pi),
                      child: Text(
                        'Z',
                        style:
                            display(
                              13 + i * 4.0,
                              color: const Color(0xFF3E4F8A),
                            ).copyWith(
                              shadows: const [
                                Shadow(color: Color(0xCCFFFFFF), blurRadius: 3),
                              ],
                            ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Opens Settings.
class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Settings',
      button: true,
      excludeSemantics: true,
      child: Squish(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.deep.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.muted.withValues(alpha: 0.25)),
          ),
          child: const Icon(
            Icons.settings_rounded,
            size: 18,
            color: AppColors.gold,
          ),
        ),
      ),
    );
  }
}

/// The player's rank, a small dark chip in the corner of the scene.
class _RankChip extends StatelessWidget {
  const _RankChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.deep.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PaperCard(
          tilt: -2,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Text(text, style: const TextStyle(fontSize: 13, height: 1.3)),
        ),
        Positioned(
          right: -9,
          bottom: 12,
          child: CustomPaint(size: const Size(12, 12), painter: _TailPainter()),
        ),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height / 2)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = AppColors.cream,
    );
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => false;
}

/// This week's streak as moon phases. Played days wax to full one after
/// another; today shows a half moon until played. When today's play just
/// grew the streak, tonight's moon flashes and "+1 night" pops up.
class _MoonStreak extends StatefulWidget {
  const _MoonStreak({required this.game});
  final GameState game;

  @override
  State<_MoonStreak> createState() => _MoonStreakState();
}

class _MoonStreakState extends State<_MoonStreak> {
  late final bool _celebrate;

  @override
  void initState() {
    super.initState();
    // Read the flag first, then clear it so we celebrate only once.
    _celebrate = widget.game.streakBumped;
    widget.game.streakBumped = false;
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final streak = game.streak();
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final playedDays = [
      for (var i = 0; i < 7; i++) game.playedOn(monday.add(Duration(days: i))),
    ];
    var order = 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PaperCard(
          tilt: -1,
          seed: 4,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(switch (streak) {
                      0 => 'Start a streak',
                      1 => '1-night streak',
                      _ => '$streak-night streak',
                    }, style: display(17)),
                    Text(
                      game.playedOn(today)
                          ? 'See you tomorrow'
                          : 'Play today to keep it',
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < 7; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Builder(
                    builder: (_) {
                      final isToday = monday.add(Duration(days: i)) == today;
                      final played = playedDays[i];
                      final fill = played ? 1.0 : (isToday ? 0.5 : 0.0);
                      final delay = Duration(
                        milliseconds: 250 + (fill > 0 ? order++ : 0) * 180,
                      );
                      return Column(
                        children: [
                          MoonPhase(
                            fill: fill,
                            delay: delay,
                            celebrate: _celebrate && isToday && played,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            letters[i],
                            style: TextStyle(
                              fontSize: 11,
                              color: isToday
                                  ? AppColors.red
                                  : AppColors.inkMuted,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        if (_celebrate)
          Positioned(
            right: 8,
            top: -16,
            child: Delayed(
              delay: Duration(
                milliseconds: 600 + playedDays.where((p) => p).length * 180,
              ),
              child: const PopIn(
                startScale: 0,
                startTilt: -20,
                child: Pill('+1 night', icon: Icons.nightlight_round),
              ),
            ),
          ),
      ],
    );
  }
}

class _Mission extends StatelessWidget {
  const _Mission({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    final tasks = [
      (
        'Find ${GameState.missionCatches} creatures',
        game.missionFound,
        GameState.missionCatches,
      ),
      (
        'Get ${GameState.missionAnswers} answers right',
        game.missionAnswered,
        GameState.missionAnswers,
      ),
      ('Finish a stage', game.missionStagesDone, GameState.missionStages),
    ];
    return PaperCard(
      tilt: 0.8,
      seed: 9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text("Tonight's mission", style: display(18))),
              Text(
                game.missionRewarded ? 'Done! +30 gems' : '+30 gems',
                style: display(14, color: AppColors.red),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final (label, have, need) in tasks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: have >= need
                          ? AppColors.leaf2
                          : Colors.transparent,
                      border: Border.all(
                        color: have >= need ? AppColors.leaf2 : AppColors.ink,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: have >= need
                        ? const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        color: have >= need
                            ? AppColors.inkMuted
                            : AppColors.ink,
                        decoration: have >= need
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  Text(
                    '${have.clamp(0, need)}/$need',
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The big orange Continue tag. It gives a little wiggle now and then to
/// invite a tap.
class _Continue extends StatefulWidget {
  const _Continue({required this.game, required this.onOpenMap});
  final GameState game;
  final VoidCallback onOpenMap;

  @override
  State<_Continue> createState() => _ContinueState();
}

class _ContinueState extends State<_Continue>
    with SingleTickerProviderStateMixin {
  // The wiggle itself is short. It plays every few seconds and sits idle
  // in between, so the card isn't redrawn the rest of the time.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final Timer _every;

  @override
  void initState() {
    super.initState();
    _every = Timer.periodic(
      const Duration(milliseconds: 3200),
      (_) => _c.forward(from: 0),
    );
  }

  @override
  void dispose() {
    _every.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Stage? next = widget.game.nextStage;
    final habitat = next == null ? null : habitatById[next.habitatId]!;
    final still = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final v = _c.value;
        final wiggle = _c.isAnimating && !still ? sin(v * pi * 3) * 0.03 : 0.0;
        return Transform.rotate(angle: wiggle, child: child);
      },
      child: Squish(
        onTap: next == null
            ? widget.onOpenMap
            : () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => StageScreen(stage: next)),
              ),
        child: CustomPaint(
          painter: PaperShapePainter(color: AppColors.orange, seed: 12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        next == null ? 'All done' : 'Continue',
                        style: const TextStyle(
                          color: AppColors.cream,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        next == null
                            ? 'Replay for 3 stars'
                            : next.isBoss
                            ? '${habitat!.name} · Review'
                            : '${habitat!.name} · Stage ${next.number}',
                        style: display(20, color: AppColors.cream),
                      ),
                      if (next != null)
                        Text(
                          next.title,
                          style: const TextStyle(
                            color: AppColors.cream,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  next == null ? Icons.map_rounded : Icons.play_arrow_rounded,
                  color: AppColors.cream,
                  size: 40,
                  semanticLabel: next == null ? 'Open map' : 'Play',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
