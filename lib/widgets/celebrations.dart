import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../data/rewards.dart';
import '../state/game_state.dart';
import '../theme.dart';
import 'common.dart';
import 'creature_art.dart';
import 'scene.dart';
import 'partner_art.dart';

bool _still(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Plays its child after [delay]. Handy for staggering one-shot effects.
class Delayed extends StatefulWidget {
  const Delayed({super.key, required this.delay, required this.child});
  final Duration delay;
  final Widget child;

  @override
  State<Delayed> createState() => _DelayedState();
}

class _DelayedState extends State<Delayed> {
  bool _show = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(widget.delay, () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _show ? widget.child : const SizedBox.shrink();
}

/// Rank title for a ranger level.
String rankName(int level) {
  if (level >= 10) return 'Parol Master';
  if (level >= 6) return 'Moon Ranger';
  if (level >= 3) return 'Star Ranger';
  return 'Night Ranger';
}

// ---------------------------------------------------------------------------
// 5. Paper hearts that tear
// ---------------------------------------------------------------------------

Path heartPath(Size s) {
  final sx = s.width / 56, sy = s.height / 52;
  Offset p(double x, double y) => Offset(x * sx, y * sy);
  return Path()
    ..moveTo(28 * sx, 50 * sy)
    ..cubicTo(28 * sx, 50 * sy, 2 * sx, 34 * sy, 2 * sx, 16 * sy)
    ..arcToPoint(p(28, 10), radius: Radius.elliptical(13 * sx, 13 * sy))
    ..arcToPoint(p(54, 16), radius: Radius.elliptical(13 * sx, 13 * sy))
    ..cubicTo(54 * sx, 34 * sy, 28 * sx, 50 * sy, 28 * sx, 50 * sy)
    ..close();
}

Path _tearSide(Size s, {required bool left}) {
  final sx = s.width / 56, sy = s.height / 52;
  const zig = [
    (28.0, -10.0),
    (28.0, 10.0),
    (24.0, 18.0),
    (30.0, 26.0),
    (24.0, 34.0),
    (30.0, 42.0),
    (28.0, 62.0),
  ];
  final p = Path()..moveTo(left ? -20 : 80 * sx, -10 * sy);
  for (final (x, y) in zig) {
    p.lineTo(x * sx, y * sy);
  }
  return p
    ..lineTo(left ? -20 : 80 * sx, 62 * sy)
    ..close();
}

/// A row of paper hearts. When one is lost it shakes, tears in two, and
/// leaves a dotted outline behind.
class HeartsRow extends StatefulWidget {
  const HeartsRow({
    super.key,
    required this.hearts,
    this.max = 3,
    this.size = 24,
  });
  final int hearts;
  final int max;
  final double size;

  @override
  State<HeartsRow> createState() => _HeartsRowState();
}

class _HeartsRowState extends State<HeartsRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  int? _tearing;

  @override
  void didUpdateWidget(HeartsRow old) {
    super.didUpdateWidget(old);
    if (widget.hearts < old.hearts && !_still(context)) {
      _tearing = widget.hearts;
      _c.forward(from: 0);
    } else if (widget.hearts > old.hearts) {
      _tearing = null;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Size(widget.size, widget.size * 52 / 56);
    return Semantics(
      label: '${widget.hearts} of ${widget.max} hearts left',
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.max; i++)
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: CustomPaint(
                  size: s,
                  painter: _HeartPainter(
                    full: i < widget.hearts,
                    tear: i == _tearing && _c.isAnimating ? _c.value : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeartPainter extends CustomPainter {
  _HeartPainter({required this.full, this.tear});
  final bool full;

  /// 0..1 while tearing, null otherwise.
  final double? tear;

  static const _color = AppColors.heart;

  void _dotted(Canvas c, Path p, double alpha) {
    final paint = Paint()
      ..color = _color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (final m in p.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 5) {
        c.drawPath(m.extractPath(d, min(d + 2.2, m.length)), paint);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final heart = heartPath(size);
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.35);
    if (full) {
      canvas.drawPath(heart.shift(const Offset(1, 2)), shadow);
      canvas.drawPath(heart, Paint()..color = _color);
      return;
    }
    final t = tear;
    if (t == null) {
      _dotted(canvas, heart, 0.6);
      return;
    }
    // Shake first, then tear apart and fall.
    if (t < 0.3) {
      final k = t / 0.3;
      canvas.save();
      canvas.translate(sin(k * pi * 5) * 3 * (1 - k), 0);
      canvas.drawPath(heart, Paint()..color = _color);
      canvas.restore();
      return;
    }
    final u = (t - 0.3) / 0.7;
    _dotted(canvas, heart, 0.6 * u);
    for (final left in [true, false]) {
      final dir = left ? -1.0 : 1.0;
      canvas.save();
      final pivot = Offset(size.width / 2, size.height);
      canvas.translate(
        pivot.dx + dir * size.width * 0.45 * u,
        pivot.dy + size.height * 2.2 * u * u,
      );
      canvas.rotate(dir * 1.2 * u);
      canvas.translate(-pivot.dx, -pivot.dy);
      canvas.clipPath(_tearSide(size, left: left));
      canvas.drawPath(
        heart,
        Paint()
          ..color = (left ? _color : const Color(0xFFFF8466)).withValues(
            alpha: 1 - u,
          ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_HeartPainter old) => old.full != full || old.tear != tear;
}

// ---------------------------------------------------------------------------
// 9. Moon phases for the streak
// ---------------------------------------------------------------------------

/// A moon that waxes from new to [fill] (0 = new, 1 = full) after [delay].
/// With [celebrate], it flashes and pulses once it's full.
class MoonPhase extends StatefulWidget {
  const MoonPhase({
    super.key,
    required this.fill,
    this.delay = Duration.zero,
    this.celebrate = false,
    this.size = 18,
  });

  final double fill;
  final Duration delay;
  final bool celebrate;
  final double size;

  @override
  State<MoonPhase> createState() => _MoonPhaseState();
}

class _MoonPhaseState extends State<MoonPhase> with TickerProviderStateMixin {
  late final AnimationController _wax = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(widget.delay, () async {
      if (!mounted) return;
      await _wax.forward();
      if (mounted && widget.celebrate) {
        HapticFeedback.lightImpact();
        _glow.forward();
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _wax.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = _still(context);
    return AnimatedBuilder(
      animation: Listenable.merge([_wax, _glow]),
      builder: (_, _) {
        final g = _glow.value;
        final scale = g == 0 ? 1.0 : 1 + sin(min(g * 2, 1) * pi) * 0.3;
        return Transform.scale(
          scale: scale,
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _MoonPainter(
              progress: still
                  ? widget.fill
                  : widget.fill * Curves.easeInOut.transform(_wax.value),
              glow: g,
            ),
          ),
        );
      },
    );
  }
}

class _MoonPainter extends CustomPainter {
  _MoonPainter({required this.progress, required this.glow});
  final double progress;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    if (glow > 0 && glow < 1) {
      canvas.drawCircle(
        c,
        r + glow * 14,
        Paint()
          ..color = AppColors.gold.withValues(alpha: (1 - glow) * 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * (1 - glow),
      );
    }
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    if (progress > 0) {
      canvas.drawCircle(c, r, Paint()..color = AppColors.gold);
      // The shadow slides off to the side as the moon waxes.
      canvas.drawCircle(
        c + Offset(progress * r * 2.2, 0),
        r,
        Paint()..color = AppColors.cream,
      );
    }
    canvas.restore();
    canvas.drawCircle(
      c,
      r - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.ink,
    );
  }

  @override
  bool shouldRepaint(_MoonPainter old) =>
      old.progress != progress || old.glow != glow;
}

// ---------------------------------------------------------------------------
// 10. Loading: the partner hops along under the parols
// ---------------------------------------------------------------------------

class LoadingTarsi extends StatefulWidget {
  const LoadingTarsi({super.key, this.label = 'Loading'});
  final String label;

  @override
  State<LoadingTarsi> createState() => _LoadingTarsiState();
}

class _LoadingTarsiState extends State<LoadingTarsi>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  // (time, x fraction, height above the branch)
  static const _keys = [
    (0.0, 0.15, 0.0),
    (0.16, 0.27, 46.0),
    (0.33, 0.42, 0.0),
    (0.5, 0.57, 46.0),
    (0.66, 0.72, 0.0),
    (0.83, 0.43, 70.0),
    (1.0, 0.15, 0.0),
  ];

  (double, double) _at(double t) {
    for (var i = 0; i < _keys.length - 1; i++) {
      final a = _keys[i], b = _keys[i + 1];
      if (t <= b.$1) {
        final k = Curves.easeInOut.transform((t - a.$1) / (b.$1 - a.$1));
        return (a.$2 + (b.$2 - a.$2) * k, a.$3 + (b.$3 - a.$3) * k);
      }
    }
    return (_keys.last.$2, _keys.last.$3);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = min(box.maxWidth, 420.0);
        const h = 300.0;
        return Center(
          child: SizedBox(
            width: w,
            height: h + 40,
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) {
                final t = _c.value;
                final (fx, up) = _at(t);
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _LoadingPainter(
                          t,
                          GameScope.maybeOf(context)?.parolStyle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: fx * w - 45,
                      top: h * 0.72 - 88 - up,
                      child: const PartnerArt(size: 90),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: h + 4,
                      child: Text(
                        '${widget.label}${'.' * (1 + (t * 6).floor() % 3)}',
                        textAlign: TextAlign.center,
                        style: display(20),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _LoadingPainter extends CustomPainter {
  _LoadingPainter(this.t, this.style);
  final double t;
  final ParolStyle? style;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const h = 300.0;
    canvas.drawPath(
      Path()
        ..moveTo(0, 40)
        ..quadraticBezierTo(w / 2, 90, w, 40),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF3A2A1C),
    );
    final st = style ?? parolStyleOf(defaultParol);
    for (var i = 0; i < 3; i++) {
      final x = w * (0.27 + i * 0.23);
      final y = 40 + sin(x / w * pi) * 25;
      final glow = max(0.0, 1 - (t - (0.16 + i * 0.33)).abs() * 7);
      drawParol(
        canvas,
        Offset(x, y),
        14,
        st.colorAt(i),
        swing: sin(t * 2 * pi + i) * 0.08,
        lit: glow > 0.05,
        style: st,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(-10, h * 0.72)
        ..quadraticBezierTo(w / 2, h * 0.66, w + 10, h * 0.74),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF7A4E2A),
    );
  }

  @override
  bool shouldRepaint(_LoadingPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// 8. Page turn between screens
// ---------------------------------------------------------------------------

/// New screens swing in like a journal page turning from the left edge,
/// with a shadow that lifts as the page lands.
class PageTurnTransitionsBuilder extends PageTransitionsBuilder {
  const PageTurnTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: child,
      builder: (context, child) {
        if (_still(context)) return child!;
        final v = Curves.easeOutCubic.transform(animation.value);
        final behind = secondaryAnimation.value;
        final angle = (1 - v) * -pi / 2.2;
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(angle),
              child: child,
            ),
            IgnorePointer(
              child: Opacity(
                opacity: ((1 - v) * 0.55 + behind * 0.3).clamp(0, 1),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x00000000), Color(0xCC000000)],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 1 and 2. Full-screen celebrations
// ---------------------------------------------------------------------------

Future<void> showCelebration(BuildContext context, Widget child) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0xCC0A0B22),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, _, _) => SafeArea(
      child: Material(type: MaterialType.transparency, child: child),
    ),
    transitionBuilder: (_, a, _, child) =>
        FadeTransition(opacity: a, child: child),
  );
}

/// Level up: paper fireworks, spinning rays, and a ribbon with the new level.
class LevelUpView extends StatelessWidget {
  const LevelUpView({super.key, required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: SpinningRays()),
        for (final (align, ms) in const [
          (Alignment(0, -0.2), 200),
          (Alignment(-0.6, -0.5), 600),
          (Alignment(0.6, -0.45), 900),
          (Alignment(0, -0.6), 1300),
        ])
          Align(
            alignment: align,
            child: Delayed(
              delay: Duration(milliseconds: ms),
              child: const SizedBox(
                width: 300,
                height: 300,
                child: ConfettiBurst(count: 30, power: 1.1),
              ),
            ),
          ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopIn(
                delay: const Duration(milliseconds: 250),
                startScale: 0,
                startTilt: -20,
                child: Transform.rotate(
                  angle: -3 * pi / 180,
                  child: CustomPaint(
                    painter: _RibbonPainter(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 44,
                        vertical: 14,
                      ),
                      child: Text(
                        'Level $level!',
                        style: display(40, color: AppColors.ink),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              PopIn(
                delay: const Duration(milliseconds: 900),
                from: const Offset(0, 16),
                child: Text(
                  // Only announce a title when it actually changes.
                  rankName(level) != rankName(level - 1)
                      ? "You're now a ${rankName(level)}!"
                      : 'Keep exploring, ${rankName(level)}!',
                  textAlign: TextAlign.center,
                  style: display(20).copyWith(color: AppColors.text),
                ),
              ),
              const SizedBox(height: 28),
              PopIn(
                delay: const Duration(milliseconds: 1300),
                child: PaperButton(
                  label: 'Yay!',
                  expand: false,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, notch = w * 0.07;
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w - notch, h / 2)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..lineTo(notch, h / 2)
      ..close();
    canvas.drawPath(
      p.shift(const Offset(3, 5)),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawPath(p, Paint()..color = AppColors.cream);
  }

  @override
  bool shouldRepaint(_RibbonPainter oldDelegate) => false;
}

/// New habitat: its paper layers stand up one by one like a pop-up book,
/// then a banner unrolls.
class HabitatUnlockView extends StatefulWidget {
  const HabitatUnlockView({super.key, required this.habitat});
  final Habitat habitat;

  @override
  State<HabitatUnlockView> createState() => _HabitatUnlockViewState();
}

class _HabitatUnlockViewState extends State<HabitatUnlockView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ocean = widget.habitat.id == 'ocean';
    final layers = ocean ? _oceanLayers : _forestLayers;
    final still = _still(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final t = still ? 1.0 : _c.value;
              final banner = Curves.elasticOut.transform(
                ((t - 0.55) / 0.35).clamp(0, 1),
              );
              return SizedBox(
                width: 320,
                height: 280,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: ocean
                              ? const Color(0xFF16406F)
                              : AppColors.sky,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              offset: Offset(4, 6),
                            ),
                          ],
                        ),
                      ),
                    ),
                    for (var i = 0; i < layers.length; i++)
                      Positioned.fill(
                        child: Builder(
                          builder: (_) {
                            final start = 0.06 * i;
                            final k = ((t - start) / 0.4).clamp(0.0, 1.0);
                            final up = Curves.elasticOut.transform(k);
                            return Transform(
                              alignment: Alignment.bottomCenter,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.002)
                                ..rotateX((1 - up) * 1.45),
                              child: Opacity(
                                opacity: k == 0 ? 0 : 1,
                                child: CustomPaint(
                                  painter: _PopLayerPainter(layers[i]),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 18,
                      child: Center(
                        child: Transform.scale(
                          scaleX: banner,
                          child: CustomPaint(
                            painter: _RibbonPainter(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 8,
                              ),
                              child: Text(
                                '${widget.habitat.name} unlocked!',
                                style: display(24, color: AppColors.ink),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          PopIn(
            delay: const Duration(milliseconds: 1800),
            from: const Offset(0, 16),
            child: Text(
              widget.habitat.blurb,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.text, fontSize: 17),
            ),
          ),
          const SizedBox(height: 22),
          PopIn(
            delay: const Duration(milliseconds: 2100),
            child: PaperButton(
              label: "Let's explore!",
              expand: false,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _LayerDraw = void Function(Canvas c, Size s);

void _paperFill(Canvas c, Path p, Color color) {
  c.drawPath(
    p.shift(const Offset(0, 4)),
    Paint()..color = Colors.black.withValues(alpha: 0.35),
  );
  c.drawPath(p, Paint()..color = color);
}

Path _band(Size s, double y, double amp, double freq, double phase) {
  final p = Path()..moveTo(0, s.height);
  for (var x = 0.0; x <= s.width; x += 8) {
    p.lineTo(x, y + sin(x / s.width * pi * freq + phase) * amp);
  }
  return p
    ..lineTo(s.width, s.height)
    ..close();
}

final List<_LayerDraw> _oceanLayers = [
  (c, s) => _paperFill(
    c,
    _band(s, s.height * 0.42, 12, 3, 0),
    const Color(0xFF4E8FC2),
  ),
  (c, s) => _paperFill(
    c,
    _band(s, s.height * 0.6, 12, 2.4, 1),
    const Color(0xFF1D4F86),
  ),
  (c, s) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final base = s.height * 0.92;
    c.drawPath(
      Path()
        ..moveTo(s.width * 0.18, base)
        ..lineTo(s.width * 0.18, base - 40)
        ..moveTo(s.width * 0.18, base - 40)
        ..lineTo(s.width * 0.14, base - 56)
        ..moveTo(s.width * 0.18, base - 40)
        ..lineTo(s.width * 0.23, base - 58),
      stroke..color = const Color(0xFFE5704F),
    );
    c.drawPath(
      Path()
        ..moveTo(s.width * 0.8, base)
        ..lineTo(s.width * 0.8, base - 48)
        ..moveTo(s.width * 0.8, base - 48)
        ..lineTo(s.width * 0.75, base - 62)
        ..moveTo(s.width * 0.8, base - 48)
        ..lineTo(s.width * 0.85, base - 64),
      stroke..color = const Color(0xFFD45A8C),
    );
    for (final x in [0.34, 0.66]) {
      c.drawPath(
        Path()
          ..moveTo(s.width * x, base)
          ..quadraticBezierTo(
            s.width * x - 12,
            base - 40,
            s.width * x + 4,
            base - 80,
          ),
        stroke..color = const Color(0xFF2E8A5C),
      );
    }
  },
  (c, s) {
    final fish = creatureById['clownfish']!;
    c.save();
    c.translate(s.width * 0.5 - 40, s.height * 0.38);
    c.scale(0.8);
    _drawCreatureIcon(c, fish);
    c.restore();
  },
  (c, s) => _paperFill(
    c,
    _band(s, s.height * 0.86, 4, 4, 2),
    const Color(0xFF8C7A5B),
  ),
];

final List<_LayerDraw> _forestLayers = [
  (c, s) =>
      _paperFill(c, _band(s, s.height * 0.5, 14, 2.2, 0.4), AppColors.hill),
  (c, s) => _paperFill(
    c,
    _band(s, s.height * 0.66, 12, 2.6, 2),
    const Color(0xFF1F5A4A),
  ),
  (c, s) {
    for (final (x, r) in [
      (0.15, 34.0),
      (0.42, 28.0),
      (0.7, 36.0),
      (0.92, 26.0),
    ]) {
      _paperFill(
        c,
        Path()..addOval(
          Rect.fromCircle(
            center: Offset(s.width * x, s.height * 0.7),
            radius: r,
          ),
        ),
        AppColors.leaf2,
      );
    }
  },
  (c, s) => _paperFill(c, _band(s, s.height * 0.86, 6, 3, 1), AppColors.leaf1),
];

void _drawCreatureIcon(Canvas c, Creature creature) {
  // Tiny paper fish, drawn directly so the layer stays a single painter.
  final body = Path()..addOval(const Rect.fromLTWH(0, 0, 70, 40));
  c.drawPath(
    Path()
      ..moveTo(62, 20)
      ..lineTo(92, 2)
      ..lineTo(92, 38)
      ..close(),
    Paint()..color = creature.color,
  );
  _paperFill(c, body, creature.color);
  c.save();
  c.clipPath(body);
  for (final x in [18.0, 40.0]) {
    c.drawRect(Rect.fromLTWH(x, 0, 9, 40), Paint()..color = Colors.white);
  }
  c.restore();
  c.drawCircle(
    const Offset(10, 16),
    4,
    Paint()..color = const Color(0xFF1A1208),
  );
}

class _PopLayerPainter extends CustomPainter {
  _PopLayerPainter(this.draw);
  final _LayerDraw draw;

  @override
  void paint(Canvas canvas, Size size) => draw(canvas, size);

  @override
  bool shouldRepaint(_PopLayerPainter old) => false;
}

// ---------------------------------------------------------------------------
// 7. The escape leap
// ---------------------------------------------------------------------------

/// The creature squashes, leaps off its branch into the leaves, and is
/// gone. Calls [onDone] when finished.
class EscapeScene extends StatefulWidget {
  const EscapeScene({super.key, required this.creature, required this.onDone});
  final Creature creature;
  final VoidCallback onDone;

  @override
  State<EscapeScene> createState() => _EscapeSceneState();
}

class _EscapeSceneState extends State<EscapeScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      await _c.forward();
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 220,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final t = _c.value;
          double seg(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
          // Squash, then leap along an arc to the right and up into the leaves.
          final squash = sin(seg(0, 0.15) * pi) * 0.14;
          final leap = Curves.easeIn.transform(seg(0.12, 0.75));
          final dx = leap * 210;
          final dy = -sin(leap * pi * 0.8) * 90 - leap * 30;
          final rot = leap * 0.9;
          final scale = 1 - leap * 0.4;
          final rustle = seg(0.55, 0.95);
          final leafAngle = sin(rustle * pi * 3) * 0.22 * (1 - rustle);
          final q = Curves.elasticOut.transform(seg(0.75, 1));
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _EscapeBackPainter()),
              ),
              Positioned(
                left: 30 + dx,
                top: 40 + dy,
                child: Opacity(
                  opacity: 1 - seg(0.7, 0.8),
                  child: Transform.rotate(
                    angle: rot,
                    child: Transform.scale(
                      scaleX: (1 + squash) * scale,
                      scaleY: (1 - squash) * scale,
                      alignment: Alignment.bottomCenter,
                      child: CreatureArt(
                        widget.creature,
                        size: 130,
                        animate: true,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(painter: _EscapeLeavesPainter(leafAngle)),
              ),
              Positioned(
                right: 26,
                top: 30,
                child: Transform.rotate(
                  angle: 0.2 * q,
                  child: Transform.scale(
                    scale: q,
                    child: Text('?', style: display(46, color: AppColors.gold)),
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

class _EscapeBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(-20, size.height * 0.8)
        ..quadraticBezierTo(
          size.width / 2,
          size.height * 0.7,
          size.width + 20,
          size.height * 0.82,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF7A4E2A),
    );
  }

  @override
  bool shouldRepaint(_EscapeBackPainter oldDelegate) => false;
}

class _EscapeLeavesPainter extends CustomPainter {
  _EscapeLeavesPainter(this.angle);
  final double angle;

  void _leaf(Canvas c, Offset base, double rot, double len, Color color) {
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(rot);
    final p = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(len * 0.5, -len * 0.3, len, 0)
      ..quadraticBezierTo(len * 0.5, len * 0.3, 0, 0)
      ..close();
    c.drawPath(
      p.shift(const Offset(0, 3)),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    c.drawPath(p, Paint()..color = color);
    c.drawLine(
      Offset.zero,
      Offset(len * 0.9, 0),
      Paint()
        ..color = Color.lerp(color, Colors.white, 0.3)!
        ..strokeWidth = 1.5,
    );
    c.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final b = Offset(size.width - 10, size.height * 0.82);
    _leaf(canvas, b, -2.2 + angle, 110, AppColors.leaf2);
    _leaf(
      canvas,
      b + const Offset(10, 4),
      -2.7 - angle * 0.8,
      90,
      AppColors.leaf1,
    );
    _leaf(
      canvas,
      b + const Offset(-6, 0),
      -1.7 + angle * 1.2,
      80,
      AppColors.leaf3,
    );
  }

  @override
  bool shouldRepaint(_EscapeLeavesPainter old) => old.angle != angle;
}

// ---------------------------------------------------------------------------
// 3. Dex book target
// ---------------------------------------------------------------------------

/// A little open book that bounces when a sticker lands in it.
class DexBook extends StatelessWidget {
  const DexBook({super.key, this.bounce = 0, this.size = 54});

  /// 0..1 bounce progress.
  final double bounce;
  final double size;

  @override
  Widget build(BuildContext context) {
    final squash = sin(bounce * pi) * 0.3;
    return Transform.scale(
      scaleX: 1 + squash,
      scaleY: 1 - squash * 0.7,
      alignment: Alignment.bottomCenter,
      child: CustomPaint(
        size: Size(size, size * 0.85),
        painter: _BookPainter(),
      ),
    );
  }
}

class _BookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final left = Path()
      ..moveTo(w * 0.04, h * 0.13)
      ..quadraticBezierTo(w * 0.26, 0, w * 0.5, h * 0.17)
      ..lineTo(w * 0.5, h * 0.96)
      ..quadraticBezierTo(w * 0.26, h * 0.78, w * 0.04, h * 0.91)
      ..close();
    final right = Path()
      ..moveTo(w * 0.96, h * 0.13)
      ..quadraticBezierTo(w * 0.74, 0, w * 0.5, h * 0.17)
      ..lineTo(w * 0.5, h * 0.96)
      ..quadraticBezierTo(w * 0.74, h * 0.78, w * 0.96, h * 0.91)
      ..close();
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.35);
    canvas.drawPath(left.shift(const Offset(2, 3)), shadow);
    canvas.drawPath(right.shift(const Offset(2, 3)), shadow);
    canvas.drawPath(left, Paint()..color = AppColors.orange);
    canvas.drawPath(right, Paint()..color = AppColors.red);
    canvas.drawLine(
      Offset(w * 0.5, h * 0.17),
      Offset(w * 0.5, h * 0.96),
      Paint()
        ..color = AppColors.ink
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_BookPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Moon gifts
// ---------------------------------------------------------------------------

/// A streak milestone gift: the partner tries on the new item (or the new parols
/// light up) under spinning rays. [onUse] puts it on right away.
class GiftView extends StatelessWidget {
  const GiftView({
    super.key,
    required this.gift,
    required this.outfit,
    required this.onUse,
  });
  final Reward gift;

  /// What the partner is wearing now, so the gift is shown with the rest.
  final List<String> outfit;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final isParol = gift.kind == RewardKind.parol;
    return Stack(
      children: [
        const Positioned.fill(child: SpinningRays()),
        const Align(
          alignment: Alignment(0, -0.3),
          child: SizedBox(
            width: 300,
            height: 300,
            child: ConfettiBurst(count: 40, power: 1.1),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopIn(
                startScale: 0.4,
                child: Text(
                  'Moon gift!',
                  style: display(36, color: AppColors.gold),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'For your ${gift.giftStreak}-night streak',
                style: const TextStyle(color: AppColors.text, fontSize: 17),
              ),
              const SizedBox(height: 16),
              PopIn(
                delay: const Duration(milliseconds: 250),
                startScale: 0,
                startTilt: -25,
                child: PaperCard(
                  tilt: -3,
                  seed: 99,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    children: [
                      if (isParol)
                        CustomPaint(
                          size: const Size(150, 150),
                          painter: _GiftParolPainter(gift.id),
                        )
                      else
                        PartnerArt(
                          size: 150,
                          outfit: [
                            ...outfit.where(
                              (id) => rewardById[id]?.slot != gift.slot,
                            ),
                            gift.id,
                          ],
                        ),
                      Text(gift.name, style: display(22)),
                      SizedBox(
                        width: 220,
                        child: Text(
                          gift.blurb,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.inkMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              PopIn(
                delay: const Duration(milliseconds: 800),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    PaperButton(
                      label: isParol ? 'Hang them now' : 'Wear it now',
                      expand: false,
                      onPressed: () {
                        onUse();
                        Navigator.of(context).pop();
                      },
                    ),
                    PaperButton(
                      label: 'Later',
                      expand: false,
                      color: AppColors.track,
                      textColor: AppColors.text,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GiftParolPainter extends CustomPainter {
  _GiftParolPainter(this.id);
  final String id;

  @override
  void paint(Canvas canvas, Size size) {
    final style = parolStyleOf(id);
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.sky);
    drawParol(
      canvas,
      Offset(size.width / 2, 8),
      36,
      style.colorAt(0),
      style: style,
    );
  }

  @override
  bool shouldRepaint(_GiftParolPainter old) => old.id != id;
}
