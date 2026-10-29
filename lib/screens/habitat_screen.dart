import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../data/rewards.dart';
import '../state/game_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/creature_art.dart';
import '../widgets/scene.dart';
import 'stage/stage_screen.dart';

/// A habitat's stages as parols along a winding trail, stage 1 at the
/// bottom. Finished parols glow, the next one pulses, and locked ones are
/// dark paper. Tap a parol to swing it and see the stage. After finishing a
/// stage, the trail lights up dot by dot and the next parol bursts alight.
class HabitatScreen extends StatefulWidget {
  const HabitatScreen({super.key, required this.habitat});
  final Habitat habitat;

  @override
  State<HabitatScreen> createState() => _HabitatScreenState();
}

class _HabitatScreenState extends State<HabitatScreen>
    with SingleTickerProviderStateMixin {
  static const _rowHeight = 140.0;

  late final AnimationController _trail = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  double _from = 0;
  double _to = 0;
  bool _animating = false;

  /// Bumped each time a parol should light up; the parol watches it.
  int _igniteToken = 0;
  int? _igniteIndex;
  Timer? _bannerTimer;
  String? _banner;

  Habitat get habitat => widget.habitat;

  @override
  void dispose() {
    _trail.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  /// Picks up a just-finished stage and plays the trail animation once.
  void _maybeCelebrate(GameState game, int doneCount) {
    final from = game.pendingTrail.remove(habitat.id);
    if (from == null || from >= doneCount) return;
    _from = from.toDouble();
    _to = doneCount.toDouble();
    _animating = true;
    final ids = habitat.stageIds;
    _igniteIndex = doneCount < ids.length ? doneCount : null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _trail.value = 1;
      } else {
        await _trail.forward(from: 0);
      }
      if (!mounted) return;
      final i = _igniteIndex;
      setState(() {
        _animating = false;
        if (i != null) {
          _igniteToken++;
          final st = stageById[ids[i]]!;
          _banner = st.isBoss
              ? 'Review unlocked!'
              : 'Stage ${st.number} unlocked!';
        }
      });
      _bannerTimer = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _banner = null);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final ids = habitat.stageIds;
    _maybeCelebrate(game, ids.where(game.isStageDone).length);
    final stars = ids.fold(0, (sum, id) => sum + (game.stars[id] ?? 0));
    final height = ids.length * _rowHeight + 140;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          PaperScene(habitatId: habitat.id, time: habitat.time),
          // A soft dark fade behind the header keeps cream text readable on
          // a bright daytime sky.
          if (habitat.time == ActiveTime.day)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 150,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xB312143A), Color(0x0012143A)],
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.text,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habitat.name,
                              style: display(24).copyWith(
                                shadows: const [
                                  Shadow(
                                    color: Color(0x88000000),
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${ids.length - 1} stages · 1 review',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Pill(
                        '$stars/${ids.length * 3}',
                        icon: Icons.star_rounded,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: _banner == null
                      ? null
                      : PopIn(
                          key: ValueKey(_banner),
                          startScale: 0,
                          startTilt: -15,
                          child: Pill(
                            _banner!,
                            icon: Icons.auto_awesome_rounded,
                          ),
                        ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    reverse: true,
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final points = [
                          for (var i = 0; i < ids.length; i++)
                            Offset(
                              box.maxWidth * (i.isEven ? 0.3 : 0.7),
                              height - 150 - i * _rowHeight,
                            ),
                        ];
                        final doneCount = ids.where(game.isStageDone).length;
                        return SizedBox(
                          height: height,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _trail,
                                  builder: (_, _) => CustomPaint(
                                    painter: _TrailPainter(
                                      points,
                                      _animating || _trail.isAnimating
                                          ? _from + (_to - _from) * _trail.value
                                          : doneCount.toDouble(),
                                    ),
                                  ),
                                ),
                              ),
                              for (var i = 0; i < ids.length; i++)
                                Positioned(
                                  left: points[i].dx - 50,
                                  top: points[i].dy - 30,
                                  width: 100,
                                  height: 120,
                                  child: _ParolStage(
                                    stage: stageById[ids[i]]!,
                                    stars: game.stars[ids[i]] ?? 0,
                                    unlocked: game.isStageUnlocked(
                                      stageById[ids[i]]!,
                                    ),
                                    isNext: game.nextStage?.id == ids[i],
                                    color: game.parolStyle.colorAt(i),
                                    style: game.parolStyle,
                                    // Stay dark until the trail reaches it.
                                    waitingToIgnite:
                                        _animating && _igniteIndex == i,
                                    igniteToken: _igniteIndex == i
                                        ? _igniteToken
                                        : 0,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter(this.points, this.lit);
  final List<Offset> points;

  /// How many trail segments are lit; fractional while animating.
  final double lit;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final pts = [for (final p in points) p + const Offset(0, 40)];
    final dim = Paint()..color = AppColors.track;
    final gold = Paint()..color = AppColors.gold;
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i], b = pts[i + 1];
      final midY = (a.dy + b.dy) / 2;
      final seg = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
      final litPart = (lit - i).clamp(0.0, 1.0);
      for (final m in seg.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 14) {
          final t = m.getTangentForOffset(d);
          if (t == null) continue;
          final on = d / m.length < litPart;
          canvas.drawCircle(t.position, on ? 3.4 : 3, on ? gold : dim);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.lit != lit || old.points != points;
}

/// One stage as a parol that sways gently, pulses if it's next, and swings
/// when tapped.
class _ParolStage extends StatefulWidget {
  const _ParolStage({
    required this.stage,
    required this.stars,
    required this.unlocked,
    required this.isNext,
    required this.color,
    this.style,
    this.waitingToIgnite = false,
    this.igniteToken = 0,
  });

  final ParolStyle? style;

  final Stage stage;
  final int stars;
  final bool unlocked;
  final bool isNext;
  final Color color;

  /// Shown dark while the trail animation travels toward it.
  final bool waitingToIgnite;

  /// When this changes, the parol bursts alight and swings.
  final int igniteToken;

  @override
  State<_ParolStage> createState() => _ParolStageState();
}

class _ParolStageState extends State<_ParolStage>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 3000 + widget.stage.number * 400),
  )..repeat();
  late final AnimationController _swing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didUpdateWidget(_ParolStage old) {
    super.didUpdateWidget(old);
    if (widget.igniteToken != old.igniteToken && widget.igniteToken > 0) {
      HapticFeedback.mediumImpact();
      _swing.forward(from: 0);
      _burst.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _swing.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _tap() {
    HapticFeedback.selectionClick();
    _swing.forward(from: 0);
    if (widget.unlocked) _showSheet();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    final lit =
        widget.unlocked &&
        (widget.stars > 0 || widget.isNext) &&
        !widget.waitingToIgnite;
    return GestureDetector(
      onTap: _tap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        label: widget.stage.isBoss
            ? widget.stage.title
            : 'Stage ${widget.stage.number}',
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _swing, _burst]),
          builder: (_, _) {
            final idle = still ? 0.0 : sin(_idle.value * 2 * pi) * 0.07;
            final s = _swing.value;
            final kick = s == 0 ? 0.0 : sin(s * pi * 4) * 0.4 * (1 - s);
            final pulse = widget.isNext && !still
                ? 1 + sin(_idle.value * 2 * pi * 2) * 0.06
                : 1.0;
            return CustomPaint(
              painter: _ParolPainter(
                color: widget.color,
                style: widget.style,
                lit: lit,
                swing: idle + kick,
                scale: (widget.isNext ? 1.25 : 1.0) * pulse,
                label: widget.stage.isBoss ? '★' : '${widget.stage.number}',
                locked: !widget.unlocked || widget.waitingToIgnite,
                stars: widget.stars,
                burst: _burst.value,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSheet() {
    final stage = widget.stage;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => OnPaper(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stage.isBoss
                    ? stage.title
                    : 'Stage ${stage.number}: ${stage.title}',
                style: display(23),
              ),
              const SizedBox(height: 2),
              Text(
                stage.topic,
                style: const TextStyle(color: AppColors.inkMuted, fontSize: 15),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Pill(
                    stage.isBoss
                        ? '10 questions'
                        : '${stage.creatureIds.length * 4} questions',
                  ),
                  if (!stage.isBoss)
                    Pill(
                      '${stage.creatureIds.length} creatures hiding',
                      icon: Icons.flashlight_on_rounded,
                    ),
                  const Pill('About 5 min', icon: Icons.schedule_rounded),
                ],
              ),
              if (!stage.isBoss) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final id in stage.creatureIds)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: CreatureArt(
                          creatureById[id]!,
                          size: 60,
                          silhouette: !GameScope.of(context).caught
                              .contains(id),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              PaperButton(
                label: widget.stars > 0
                    ? 'Play again'
                    : 'Start with flashlight',
                icon: Icons.flashlight_on_rounded,
                onPressed: () {
                  Navigator.of(sheet).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StageScreen(stage: stage),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParolPainter extends CustomPainter {
  _ParolPainter({
    required this.color,
    this.style,
    required this.lit,
    required this.swing,
    required this.scale,
    required this.label,
    required this.locked,
    required this.stars,
    this.burst = 0,
  });

  final double burst;
  final Color color;
  final ParolStyle? style;
  final bool lit;
  final double swing;
  final double scale;
  final String label;
  final bool locked;
  final int stars;

  @override
  void paint(Canvas canvas, Size size) {
    final hang = Offset(size.width / 2, 0);
    final s = 22.0 * scale * (1 + sin(burst * pi) * 0.25);
    if (burst > 0 && burst < 1) {
      // A ring of light bursting out as the parol ignites.
      canvas.drawCircle(
        hang + Offset(0, s * 1.05),
        s * (1.2 + burst * 2.4),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * (1 - burst)
          ..color = AppColors.gold.withValues(alpha: 1 - burst),
      );
    }
    drawParol(canvas, hang, s, color, swing: swing, lit: lit, style: style);

    // Label in the parol's center, swinging with it.
    canvas.save();
    canvas.translate(hang.dx, hang.dy);
    canvas.rotate(swing);
    final center = Offset(0, s * 1.05);
    final tp = TextPainter(
      text: TextSpan(
        text: locked ? '' : label,
        style: display(s * 0.62, color: AppColors.ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    if (locked) {
      final icon = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.lock_rounded.codePoint),
          style: TextStyle(
            fontFamily: Icons.lock_rounded.fontFamily,
            package: Icons.lock_rounded.fontPackage,
            fontSize: s * 0.55,
            color: AppColors.muted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      icon.paint(canvas, center - Offset(icon.width / 2, icon.height / 2));
    }
    canvas.restore();

    if (stars > 0) {
      final starText = TextPainter(
        text: TextSpan(
          text: '★' * stars + '☆' * (3 - stars),
          style: TextStyle(
            fontSize: 15,
            color: AppColors.gold,
            shadows: const [
              Shadow(color: Color(0x99000000), offset: Offset(1, 1)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      starText.paint(
        canvas,
        Offset(size.width / 2 - starText.width / 2, size.height - 18),
      );
    }
  }

  @override
  bool shouldRepaint(_ParolPainter old) =>
      old.swing != swing ||
      old.scale != scale ||
      old.lit != lit ||
      old.stars != stars ||
      old.burst != burst ||
      old.locked != locked;
}
