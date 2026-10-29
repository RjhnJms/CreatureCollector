import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/rewards.dart';
import '../theme.dart';
import 'common.dart';

/// Which part of a scene to paint, so creatures can sit between the
/// background and the leaves in front.
enum SceneLayer { back, front, all }

/// Where a creature can rest in a scene, as fractions of the scene height.
abstract final class Perches {
  static const home = [0.86];
  static const search = [0.42, 0.8];
}

/// A cut-paper habitat at night: sky, moon, drifting clouds, swaying parols,
/// layered hills, branches, and tropical leaves that sway. The ocean version
/// has paper waves, light rays, coral, seaweed, and rising bubbles.
class PaperScene extends StatefulWidget {
  const PaperScene({
    super.key,
    required this.habitatId,
    this.time = ActiveTime.night,
    this.layer = SceneLayer.all,
    this.animate = true,
    this.parols = false,
    this.hanging = false,
    this.midLeaves = false,
    this.perches = const [],
    this.parolStyle,
    this.skyLine,
    this.trunk,
  });

  final String habitatId;

  /// Forest only: an upright tree trunk at this fraction of the width, for
  /// Tarsi to leap to.
  final double? trunk;

  /// Ocean only: where the water starts, as a fraction of the height. Above
  /// it is the night sky, where the parols hang. Null keeps the scene all
  /// underwater, as in the ocean stages.
  final double? skyLine;
  final ActiveTime time;
  final SceneLayer layer;
  final bool animate;

  /// The kid's chosen parol design. Defaults to the classic colors.
  final ParolStyle? parolStyle;

  /// A string of swaying parols across the top.
  final bool parols;

  /// Leaves hanging down from the canopy.
  final bool hanging;

  /// Extra leaves behind the perch, for the home scene.
  final bool midLeaves;

  /// Branch heights as fractions of the scene, see [Perches].
  final List<double> perches;

  @override
  State<PaperScene> createState() => _PaperSceneState();
}

class _PaperSceneState extends State<PaperScene>
    with SingleTickerProviderStateMixin {
  late final _clock = AmbientClock(
    vsync: this,
    period: const Duration(seconds: 24),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _clock.start();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final moving = widget.animate && !still;
    final painter = ScenePainter(
      habitatId: widget.habitatId,
      time: widget.time,
      layer: widget.layer,
      fixedT: 0.3,
      clock: moving ? _clock : null,
      parols: widget.parols,
      hanging: widget.hanging,
      midLeaves: widget.midLeaves,
      perches: widget.perches,
      parolStyle: widget.parolStyle ?? parolStyleOf(defaultParol),
      skyLine: widget.skyLine,
      trunk: widget.trunk,
    );
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(painter: painter, size: Size.infinite),
      ),
    );
  }
}

class ScenePainter extends CustomPainter {
  ScenePainter({
    required this.habitatId,
    required this.time,
    required this.layer,
    this.fixedT = 0,
    this.clock,
    required this.parols,
    required this.hanging,
    required this.midLeaves,
    required this.perches,
    required this.parolStyle,
    this.skyLine,
    this.trunk,
  }) : super(repaint: clock);

  final ParolStyle parolStyle;
  final double? skyLine;
  final double? trunk;

  final String habitatId;
  final ActiveTime time;
  final SceneLayer layer;

  /// Loop position 0..1 for ambient motion: from [clock] while it runs,
  /// otherwise fixed.
  double get t => clock?.value ?? fixedT;
  final double fixedT;
  final ValueListenable<double>? clock;
  final bool parols;
  final bool hanging;
  final bool midLeaves;
  final List<double> perches;

  double get _phase => t * 2 * pi;
  late double _k;

  /// How many times any scene has painted, for performance tests.
  @visibleForTesting
  static int debugPaints = 0;

  bool get _back => layer != SceneLayer.front;
  bool get _front => layer != SceneLayer.back;

  @override
  void paint(Canvas canvas, Size size) {
    debugPaints++;
    _k = min(size.width, size.height) / 300;
    canvas.clipRect(Offset.zero & size);
    if (habitatId == 'ocean') {
      if (_back) {
        final sky = skyLine;
        if (sky == null) {
          _oceanBack(canvas, size);
        } else {
          _skyOverWater(canvas, size, size.height * sky);
        }
      }
      if (_front) _oceanFront(canvas, size);
    } else if (habitatId == 'cave') {
      if (_back) _caveBack(canvas, size);
      if (_front) _caveFront(canvas, size);
    } else if (habitatId == 'mangrove') {
      if (_back) _mangroveBack(canvas, size);
      if (_front) _mangroveFront(canvas, size);
    } else if (habitatId == 'terraces') {
      if (_back) _terracesBack(canvas, size);
      if (_front) _terracesFront(canvas, size);
    } else {
      if (_back) {
        _forestBack(canvas, size);
        _butterflies(canvas, size);
      }
      if (_front) {
        _forestFront(canvas, size);
        _forestFlowers(canvas, size);
      }
    }
  }

  // Paper helpers -------------------------------------------------------------

  bool get _day => time == ActiveTime.day;

  // Softer shadows in daylight.
  Paint get _shadowPaint => Paint()
    ..color = Colors.black.withValues(alpha: _day ? 0.22 : 0.4)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.2 * _k);

  /// By day, plants and bark catch the sun: lighter and a little warmer.
  Color _sunlit(Color c) =>
      _day ? Color.lerp(c, const Color(0xFFE6F2A0), 0.3)! : c;

  /// Fills [p] like a piece of cut paper with a shadow below it.
  void _paper(Canvas c, Path p, Color color, {double lift = 3.5}) {
    c.drawPath(p.shift(Offset(0, lift * _k)), _shadowPaint);
    c.drawPath(p, Paint()..color = color);
  }

  void _paperStroke(Canvas c, Path p, Color color, double width) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    c.drawPath(
      p.shift(Offset(0, 3 * _k)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * _k),
    );
    c.drawPath(p, stroke..color = color);
  }

  /// The top edge of [_wavyBand], as an open line.
  Path _wavyLine(Size s, double y, double amp, double freq, double shift) {
    final p = Path()
      ..moveTo(-10, y + sin(-10 / s.width * pi * freq + shift) * amp);
    for (var x = -2.0; x <= s.width + 10; x += 8) {
      p.lineTo(x, y + sin(x / s.width * pi * freq + shift) * amp);
    }
    return p;
  }

  Path _wavyBand(Size s, double y, double amp, double freq, double shift) {
    final p = Path()..moveTo(-10, s.height + 10);
    for (var x = -10.0; x <= s.width + 10; x += 8) {
      p.lineTo(x, y + sin(x / s.width * pi * freq + shift) * amp);
    }
    return p
      ..lineTo(s.width + 10, s.height + 10)
      ..close();
  }

  // Sky -----------------------------------------------------------------------

  void _sky(Canvas c, Size s) {
    final look = TimeLook.of(time);
    final rect = Offset.zero & s;
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [look.top, look.bottom],
        ).createShader(rect),
    );
    final rnd = Random(11);
    final starAlpha = switch (time) {
      ActiveTime.night || ActiveTime.dayAndNight => 0.9,
      ActiveTime.dusk => 0.55,
      ActiveTime.dawn => 0.2,
      ActiveTime.day => 0.0,
    };
    for (var i = 0; i < (s.width * s.height / 2600).round(); i++) {
      final p = Offset(
        rnd.nextDouble() * s.width,
        rnd.nextDouble() * s.height * 0.55,
      );
      final tw = 0.5 + 0.5 * sin(_phase * 6 + i);
      c.drawCircle(
        p,
        (rnd.nextDouble() * 1.1 + 0.4) * _k,
        Paint()
          ..color = AppColors.text.withValues(
            alpha: starAlpha * (0.35 + 0.65 * tw),
          ),
      );
    }
    // Moon, a low sun at dawn, or a high sun by day
    final dawn = time == ActiveTime.dawn;
    final day = time == ActiveTime.day;
    // With parols, the top is busy with the string, so the moon sits low on
    // the left instead. The sun goes right, clear of the speech bubble.
    final center = Offset(
      s.width *
          (parols && !day
              ? 0.15
              : day && parols
              ? 0.7
              : 0.78),
      s.height *
          (dawn
              ? 0.5
              : time == ActiveTime.dusk
              ? 0.3
              : day
              ? (parols ? 0.4 : 0.16)
              : parols
              ? 0.47
              : 0.2),
    );
    final r =
        (dawn
            ? 40
            : day
            ? 26
            : 22) *
        _k;
    final color = dawn
        ? const Color(0xFFFFC77A)
        : day
        ? const Color(0xFFFFD36E)
        : const Color(0xFFFFF1C2);
    if (day) {
      // Paper sun rays, turning slowly
      final ray = Paint()..color = const Color(0xFFFFE19A);
      for (var i = 0; i < 10; i++) {
        final a = i * pi / 5 + _phase * 0.4;
        final dir = Offset(cos(a), sin(a));
        final side = Offset(-dir.dy, dir.dx) * r * 0.22;
        c.drawPath(
          Path()
            ..moveTo(
              center.dx + dir.dx * r * 1.15 + side.dx,
              center.dy + dir.dy * r * 1.15 + side.dy,
            )
            ..lineTo(center.dx + dir.dx * r * 1.6, center.dy + dir.dy * r * 1.6)
            ..lineTo(
              center.dx + dir.dx * r * 1.15 - side.dx,
              center.dy + dir.dy * r * 1.15 - side.dy,
            )
            ..close(),
          ray,
        );
      }
    }
    c.drawCircle(
      center,
      r * 3,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.32), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: r * 3)),
    );
    _paper(
      c,
      Path()..addOval(Rect.fromCircle(center: center, radius: r)),
      color,
      lift: 2,
    );
    if (!dawn && !day) {
      final crater = Paint()..color = const Color(0xFFE9DBA8);
      c.drawCircle(center + Offset(-r * 0.3, -r * 0.2), r * 0.22, crater);
      c.drawCircle(center + Offset(r * 0.35, r * 0.25), r * 0.15, crater);
    }
    // Drifting paper clouds
    for (var i = 0; i < 2; i++) {
      final speed = i == 0 ? 1.0 : 0.6;
      final x = ((t * speed + i * 0.5) % 1.0) * (s.width + 160 * _k) - 80 * _k;
      final y = s.height * (0.18 + i * 0.16);
      _paper(
        c,
        _cloud(Offset(x, y), (i == 0 ? 1 : 0.8) * _k),
        day ? Colors.white : AppColors.track,
        lift: 2.5,
      );
    }
  }

  Path _circ(Offset c, double r) =>
      Path()..addOval(Rect.fromCircle(center: c, radius: r));

  Path _cloud(Offset at, double k) => Path()
    ..addOval(Rect.fromCenter(center: at, width: 46 * k, height: 18 * k))
    ..addOval(
      Rect.fromCenter(
        center: at + Offset(-12 * k, -6 * k),
        width: 24 * k,
        height: 18 * k,
      ),
    )
    ..addOval(
      Rect.fromCenter(
        center: at + Offset(8 * k, -9 * k),
        width: 28 * k,
        height: 22 * k,
      ),
    );

  // Parols ----------------------------------------------------------------------

  void _parols(Canvas c, Size s) {
    if (_day) return _banderitas(c, s);
    final string = Path()
      ..moveTo(-10, s.height * 0.12)
      ..quadraticBezierTo(
        s.width / 2,
        s.height * 0.32,
        s.width + 10,
        s.height * 0.1,
      );
    c.drawPath(
      string,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * _k
        ..color = const Color(0xFF3A2A1C),
    );
    final metric = string.computeMetrics().first;
    for (var i = 0; i < 3; i++) {
      // Keep the left side clear for the greeting text.
      final hang = metric
          .getTangentForOffset(metric.length * (0.42 + i * 0.23))!
          .position;
      final swing = sin(_phase * (5 + i) + i * 1.7) * 0.09;
      drawParol(
        c,
        hang,
        (i == 1 ? 17 : 15) * _k,
        parolStyle.colorAt(i),
        swing: swing,
        style: parolStyle,
      );
    }
  }

  /// By day the parols come down and fiesta flags go up: triangles of
  /// colored paper on the same string. They mix the chosen parol colors
  /// with fiesta blue, green, and pink.
  void _banderitas(Canvas c, Size s) {
    final string = Path()
      ..moveTo(-10, s.height * 0.12)
      ..quadraticBezierTo(
        s.width / 2,
        s.height * 0.3,
        s.width + 10,
        s.height * 0.1,
      );
    c.drawPath(
      string,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * _k
        ..color = const Color(0xFF6B4A2E),
    );
    const fiesta = [Color(0xFF3A9BC8), Color(0xFF5BB174), Color(0xFFF2A7B5)];
    final metric = string.computeMetrics().first;
    final count = max(8, (s.width / (34 * _k)).round());
    final step = metric.length / count;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.2 * _k);
    for (var i = 0; i < count; i++) {
      final a = metric.getTangentForOffset(step * (i + 0.08))!.position;
      final b = metric.getTangentForOffset(step * (i + 0.92))!.position;
      final mid = metric.getTangentForOffset(step * (i + 0.5))!.position;
      final sway = sin(_phase * 5 + i * 1.7) * 2.5 * _k;
      final tip = mid + Offset(sway, 24 * _k);
      final flag = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(tip.dx, tip.dy)
        ..close();
      final color = i.isEven
          ? parolStyle.colorAt(i ~/ 2)
          : fiesta[(i ~/ 2) % fiesta.length];
      c.drawPath(flag.shift(Offset(1.5 * _k, 2.5 * _k)), shadow);
      c.drawPath(flag, Paint()..color = color);
      // A little cut-out diamond, like papel de japon flags
      final d = mid + Offset(sway * 0.4, 9 * _k);
      final r = 2.6 * _k;
      c.drawPath(
        Path()
          ..moveTo(d.dx, d.dy - r)
          ..lineTo(d.dx + r, d.dy)
          ..lineTo(d.dx, d.dy + r)
          ..lineTo(d.dx - r, d.dy)
          ..close(),
        Paint()..color = const Color(0xFFFFFAEB).withValues(alpha: 0.75),
      );
    }
  }

  // Forest ----------------------------------------------------------------------

  void _forestBack(Canvas c, Size s) {
    final w = s.width, h = s.height;
    _sky(c, s);
    final day = time == ActiveTime.day;
    _paper(
      c,
      _wavyBand(s, h * 0.6, 14 * _k, 2.2, 0.4),
      day ? const Color(0xFF8CCB8E) : AppColors.hill,
    );
    if (midLeaves) {
      _leaf(
        c,
        Offset(w + 4 * _k, h * 0.84),
        -152,
        106,
        46,
        AppColors.leaf3,
        _Kind.monstera,
        3,
      );
      _fern(c, Offset(-4 * _k, h * 0.79), -38, 99, AppColors.leaf3);
    }
    _paper(
      c,
      _wavyBand(s, h * 0.74, 12 * _k, 2.6, 2.1),
      day ? const Color(0xFF4F9A66) : const Color(0xFF1F5A4A),
    );
    if (day) _sunbeams(c, s);
    final trunkX = trunk;
    if (trunkX != null) _trunk(c, s, s.width * trunkX);
    if (parols) _parols(c, s);
    for (final y in perches) {
      _paperStroke(
        c,
        Path()
          ..moveTo(-10, h * y)
          ..quadraticBezierTo(w * 0.5, h * (y - 0.07), w + 10, h * (y + 0.03)),
        _sunlit(const Color(0xFF7A4E2A)),
        12 * _k,
      );
    }
    _fireflies(c, s);
  }

  /// Soft shafts of daylight slanting down through the canopy.
  void _sunbeams(Canvas c, Size s) {
    final w = s.width, h = s.height;
    for (var i = 0; i < 3; i++) {
      final x = w * (0.18 + i * 0.3) + sin(_phase * 2 + i) * 8 * _k;
      final top = 22 * _k + i * 6 * _k;
      final beam = Path()
        ..moveTo(x, 0)
        ..lineTo(x + top, 0)
        ..lineTo(x + top + w * 0.22, h * 0.9)
        ..lineTo(x + w * 0.12, h * 0.9)
        ..close();
      c.drawPath(
        beam,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFF6D0).withValues(alpha: 0.32),
              const Color(0xFFFFF6D0).withValues(alpha: 0),
            ],
          ).createShader(beam.getBounds()),
      );
    }
  }

  void _forestFront(Canvas c, Size s) {
    final w = s.width, h = s.height;
    if (hanging) {
      _leaf(
        c,
        Offset(w * 0.1, -8),
        76,
        104,
        19,
        AppColors.leaf2,
        _Kind.banana,
        4,
      );
      _leaf(
        c,
        Offset(w * 0.87, -8),
        104,
        96,
        42,
        AppColors.leaf2,
        _Kind.monstera,
        3,
      );
      _leaf(
        c,
        Offset(w * 0.5, -8),
        90,
        62,
        15,
        AppColors.leaf3,
        _Kind.plain,
        4,
      );
      _fern(c, Offset(w * 0.68, -6), 72, 84, AppColors.leaf3);
      _fern(c, Offset(w * 0.3, -6), 108, 70, AppColors.leaf2);
    }
    final b = h + 6 * _k;
    _leaf(
      c,
      Offset(-12 * _k, b),
      -58,
      147,
      24,
      AppColors.leaf2,
      _Kind.banana,
      3,
    );
    _fern(c, Offset(w * 0.07, b), -96, 106, AppColors.leaf4);
    _leaf(
      c,
      Offset(-8 * _k, b - 4 * _k),
      -24,
      106,
      46,
      AppColors.leaf1,
      _Kind.monstera,
      3,
    );
    _leaf(
      c,
      Offset(w + 12 * _k, b),
      -124,
      138,
      23,
      AppColors.leaf2,
      _Kind.banana,
      3,
    );
    _leaf(
      c,
      Offset(w, b - 4 * _k),
      -158,
      97,
      44,
      AppColors.leaf1,
      _Kind.monstera,
      3,
    );
    _leaf(
      c,
      Offset(w * 0.89, b),
      -100,
      74,
      17,
      AppColors.leaf4,
      _Kind.plain,
      4,
    );
  }

  void _fireflies(Canvas c, Size s) {
    if (time == ActiveTime.dawn || time == ActiveTime.day) return;
    final r = Random(5);
    for (var i = 0; i < 8; i++) {
      final bx = r.nextDouble() * s.width;
      final by = s.height * (0.35 + r.nextDouble() * 0.5);
      final a = _phase * 3 + r.nextDouble() * 2 * pi;
      final p = Offset(bx + sin(a) * 12 * _k, by + cos(a * 2) * 8 * _k);
      final glow = 0.35 + 0.65 * sin(a * 2).abs();
      c.drawCircle(
        p,
        7 * _k,
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.35 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * _k),
      );
      c.drawCircle(
        p,
        2 * _k,
        Paint()..color = const Color(0xFFFFF3B0).withValues(alpha: glow),
      );
    }
  }

  // Leaves ------------------------------------------------------------------------

  /// One tropical leaf growing from [base] at [angle] degrees. Lengths are
  /// in scene units and scale with the scene.
  void _leaf(
    Canvas c,
    Offset base,
    double angle,
    double len,
    double width,
    Color color,
    _Kind kind,
    double swayDeg,
  ) {
    color = _sunlit(color);
    final seed = (base.dx * 7 + base.dy * 13 + angle).abs();
    final sway = sin(_phase * 4 + seed) * swayDeg * pi / 180;
    final rot = angle * pi / 180 + sway;
    final L = len * _k, W = width * _k;

    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(rot);

    final outline = Path()
      ..moveTo(0, 0)
      ..cubicTo(L * .18, -W, L * .72, -W * .98, L, 0)
      ..cubicTo(L * .72, W * .98, L * .18, W, 0, 0)
      ..close();
    final upper = Path()
      ..moveTo(0, 0)
      ..cubicTo(L * .18, -W, L * .72, -W * .98, L, 0)
      ..quadraticBezierTo(L * .5, W * .08, 0, 0)
      ..close();

    // Shadow falls straight down on screen, whatever the leaf's angle.
    final down = Offset(sin(rot), cos(rot)) * 3.5 * _k;
    c.drawPath(outline.shift(down), _shadowPaint);

    final dark = Color.lerp(color, Colors.black, 0.3)!;
    final light = Color.lerp(color, Colors.white, 0.14)!;
    final vein = Color.lerp(color, Colors.white, 0.32)!;
    _stroke(
      c,
      Path()
        ..moveTo(-L * 0.12, 0)
        ..lineTo(0, 0),
      dark,
      max(2, W * 0.14),
    );

    final bounds = Rect.fromLTRB(-4, -W * 1.4, L + 4, W * 1.4);
    c.saveLayer(bounds, Paint());
    c.drawPath(outline, Paint()..color = light);
    c.drawPath(upper, Paint()..color = dark.withValues(alpha: 0.55));
    final n = kind == _Kind.banana ? 10 : 5;
    final veins = Path();
    for (var i = 1; i <= n; i++) {
      final tt = i / (n + 1), vx = L * tt, vs = sin(pi * tt) * W * 0.82;
      veins
        ..moveTo(vx, 0)
        ..quadraticBezierTo(vx + L * .06, -vs * .5, vx + L * .13, -vs)
        ..moveTo(vx, 0)
        ..quadraticBezierTo(vx + L * .06, vs * .5, vx + L * .13, vs);
    }
    _stroke(c, veins, vein.withValues(alpha: 0.55), max(0.8, W * 0.045));
    _stroke(
      c,
      Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(L * .5, -W * .06, L * .97, 0),
      vein,
      max(1.2, W * 0.08),
    );

    final cut = Paint()..blendMode = BlendMode.clear;
    if (kind == _Kind.monstera) {
      for (var i = 1; i <= 4; i++) {
        final tt = i / 5.4, x = L * tt, sw = sin(pi * tt) * W;
        c.drawPath(
          Path()
            ..moveTo(x, -sw * 1.2)
            ..lineTo(x + L * .05, -sw * .32)
            ..lineTo(x + L * .1, -sw * 1.2)
            ..close(),
          cut,
        );
        c.drawPath(
          Path()
            ..moveTo(x + L * .03, sw * 1.2)
            ..lineTo(x + L * .08, sw * .32)
            ..lineTo(x + L * .13, sw * 1.2)
            ..close(),
          cut,
        );
        if (i < 4) {
          c.drawOval(
            Rect.fromCenter(
              center: Offset(x + L * .09, -sw * .2),
              width: L * .05,
              height: W * .16,
            ),
            cut,
          );
        }
      }
    } else if (kind == _Kind.banana) {
      const tears = [.28, .43, .55, .7, .82];
      for (var i = 0; i < tears.length; i++) {
        final x = L * tears[i], sw = sin(pi * tears[i]) * W;
        final side = i.isOdd ? 1.0 : -1.0;
        c.drawPath(
          Path()
            ..moveTo(x, side * sw * 1.2)
            ..lineTo(x + 1.6 * _k, side * sw * .25)
            ..lineTo(x + 3.4 * _k, side * sw * 1.2)
            ..close(),
          cut,
        );
      }
    }
    c.restore();
    c.restore();
  }

  /// A fern frond: a curved stem with leaflets shrinking toward the tip.
  void _fern(Canvas c, Offset base, double angle, double len, Color color) {
    color = _sunlit(color);
    final seed = (base.dx * 5 + base.dy * 11 + angle).abs();
    final rot = angle * pi / 180 + sin(_phase * 4 + seed) * 5 * pi / 180;
    final L = len * _k;
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(rot);
    final light = Color.lerp(color, Colors.white, 0.14)!;
    final dark = Color.lerp(color, Colors.black, 0.25)!;
    final leaflets = Path();
    final shade = Path();
    for (var i = 1; i <= 11; i++) {
      final tt = i / 12.5;
      final x = L * tt;
      final y = -L * .12 * 2 * tt * (1 - tt) - L * .05 * tt * tt;
      final sz = L * .2 * (1 - tt * .75);
      for (final side in [-1.0, 1.0]) {
        final a = side * 62 * pi / 180;
        final tip = Offset(x + cos(a) * sz, y + sin(a) * sz);
        final p = side < 0 ? leaflets : shade;
        p
          ..moveTo(x, y)
          ..quadraticBezierTo(
            x + cos(a - side * .5) * sz * .6,
            y + sin(a - side * .5) * sz * .6,
            tip.dx,
            tip.dy,
          )
          ..quadraticBezierTo(
            x + cos(a + side * .5) * sz * .6,
            y + sin(a + side * .5) * sz * .6,
            x,
            y,
          );
      }
    }
    final down = Offset(sin(rot), cos(rot)) * 3 * _k;
    c.drawPath(leaflets.shift(down), _shadowPaint);
    c.drawPath(shade.shift(down), _shadowPaint);
    c.drawPath(leaflets, Paint()..color = light);
    c.drawPath(shade, Paint()..color = dark);
    _stroke(
      c,
      Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(L * .5, -L * .12, L, -L * .05),
      dark,
      2.4 * _k,
    );
    c.restore();
  }

  void _stroke(Canvas c, Path p, Color color, double width) {
    c.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  /// A cut-paper tree trunk standing straight up at [x], with bark marks
  /// and a small leafy twig.
  void _trunk(Canvas c, Size s, double x) {
    final h = s.height, half = 15 * _k;
    final trunk = Path()
      ..moveTo(x - half * 0.85, -10)
      ..lineTo(x + half * 0.85, -10)
      ..quadraticBezierTo(x + half * 1.1, h * 0.6, x + half * 1.3, h + 10)
      ..lineTo(x - half * 1.3, h + 10)
      ..quadraticBezierTo(x - half * 1.1, h * 0.6, x - half * 0.85, -10)
      ..close();
    _paper(c, trunk, _sunlit(const Color(0xFF5B3A1F)));
    for (final (fy, dx) in const [
      (0.18, -4.0),
      (0.36, 5.0),
      (0.55, -3.0),
      (0.74, 4.0),
    ]) {
      _paperStroke(
        c,
        Path()
          ..moveTo(x + (dx - 5) * _k, h * fy)
          ..quadraticBezierTo(
            x + dx * _k,
            h * fy + 3 * _k,
            x + (dx + 5) * _k,
            h * fy,
          ),
        _sunlit(const Color(0xFF7A4E2A)),
        2.2 * _k,
      );
    }
    c.drawOval(
      Rect.fromCenter(
        center: Offset(x + 2 * _k, h * 0.45),
        width: 7 * _k,
        height: 9 * _k,
      ),
      Paint()..color = const Color(0xFF3E2714),
    );
    final twig = Path()
      ..moveTo(x - half, h * 0.28)
      ..quadraticBezierTo(
        x - half - 14 * _k,
        h * 0.25,
        x - half - 22 * _k,
        h * 0.2,
      );
    _paperStroke(c, twig, _sunlit(const Color(0xFF5B3A1F)), 3 * _k);
    final sway = sin(_phase * 4) * 0.08;
    for (final (o, a) in [
      (Offset(x - half - 22 * _k, h * 0.2), -0.6 + sway),
      (Offset(x - half - 14 * _k, h * 0.235), 0.4 + sway),
    ]) {
      c.save();
      c.translate(o.dx, o.dy);
      c.rotate(a);
      _paper(
        c,
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(6 * _k, -7 * _k, 0, -15 * _k)
          ..quadraticBezierTo(-6 * _k, -7 * _k, 0, 0)
          ..close(),
        _sunlit(AppColors.leaf2),
        lift: 1.5,
      );
      c.restore();
    }
  }

  // Rice terraces -------------------------------------------------------------

  /// Misty mountains, then curved rice terrace steps cut into the slope. The
  /// flooded steps catch the light, and earth paths (the perches) run across.
  void _terracesBack(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final day = _day;
    _sky(c, s);
    _paper(
      c,
      _wavyBand(s, h * 0.27, 20 * _k, 1.6, 0.8),
      day ? const Color(0xFF8DB9A0) : const Color(0xFF2A3A7A),
    );
    _paper(
      c,
      _wavyBand(s, h * 0.33, 14 * _k, 2.2, 2.4),
      day ? const Color(0xFF6FA582) : const Color(0xFF243466),
    );
    if (day) _sunbeams(c, s);
    const greens = [
      Color(0xFFB5D77A),
      Color(0xFF9BCB6E),
      Color(0xFF8BC260),
      Color(0xFF79B653),
      Color(0xFF6CAB4A),
    ];
    const nightGreens = [
      Color(0xFF2F5C50),
      Color(0xFF2D5A4E),
      Color(0xFF285046),
      Color(0xFF22463E),
      Color(0xFF1E4038),
    ];
    final wall = day ? const Color(0xFF6E8F44) : const Color(0xFF173630);
    final tuft = day ? const Color(0xFF4F8A3A) : const Color(0xFF1B3D33);
    final shine = (day ? const Color(0xFFDFF4FF) : const Color(0xFF7A9CC8))
        .withValues(alpha: day ? 0.7 : 0.35);
    for (var i = 0; i < 5; i++) {
      final y = h * (0.38 + i * 0.12);
      final shift = i * 0.9;
      _paper(
        c,
        _wavyBand(s, y, 6 * _k, 1.4, shift),
        day ? greens[i] : nightGreens[i],
        lift: 2,
      );
      _paperStroke(c, _wavyLine(s, y, 6 * _k, 1.4, shift), wall, 3 * _k);
      double yAt(double x) => y + sin(x / w * pi * 1.4 + shift) * 6 * _k;
      if (i.isOdd) {
        // A flooded step, with streaks of light on the water
        for (var x = 18.0 * _k; x < w; x += 46 * _k) {
          final yy = yAt(x) + 9 * _k;
          c.drawLine(
            Offset(x, yy),
            Offset(x + 18 * _k, yy),
            Paint()
              ..color = shine
              ..strokeWidth = 2 * _k
              ..strokeCap = StrokeCap.round,
          );
        }
      } else {
        // Rows of young rice
        final blade = Paint()
          ..color = tuft
          ..strokeWidth = 1.4 * _k
          ..strokeCap = StrokeCap.round;
        for (var x = 10.0 * _k; x < w; x += 20 * _k) {
          final b = Offset(x, yAt(x) + 12 * _k);
          for (final dx in [-3.0, 0.0, 3.0]) {
            c.drawLine(b, b + Offset(dx * _k, -7 * _k), blade);
          }
        }
      }
    }
    // Raised earth paths between the fields, where creatures stand
    for (final y in perches) {
      _paperStroke(
        c,
        Path()
          ..moveTo(-10, h * y)
          ..quadraticBezierTo(w * 0.5, h * (y - 0.05), w + 10, h * (y + 0.02)),
        day ? const Color(0xFF9A7448) : const Color(0xFF4A3826),
        10 * _k,
      );
    }
    _fireflies(c, s);
  }

  /// Big rice plants up close, with drooping golden grain heads.
  void _terracesFront(Canvas c, Size s) {
    final w = s.width, h = s.height;
    _riceClump(c, Offset(w * 0.05, h + 4 * _k), 1);
    _riceClump(c, Offset(w * 0.95, h + 4 * _k), -1);
  }

  void _riceClump(Canvas c, Offset base, double flip) {
    Color tone(Color col) =>
        _day ? _sunlit(col) : Color.lerp(col, const Color(0xFF0B1435), 0.45)!;
    final sway = sin(_phase * 4 + base.dx) * 4 * _k;
    final blade = tone(const Color(0xFF4F9A3E));
    for (var i = 0; i < 7; i++) {
      final a = (-0.5 + i / 6) * 0.9;
      final len = (70 + (i % 3) * 18) * _k;
      final tip = base + Offset(sin(a) * len + sway * flip, -cos(a) * len);
      _paperStroke(
        c,
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(
            base.dx + sin(a) * len * 0.4,
            base.dy - len * 0.6,
            tip.dx,
            tip.dy,
          ),
        blade,
        3.2 * _k,
      );
    }
    final grain = Paint()..color = tone(const Color(0xFFE2B84A));
    for (var j = 0; j < 3; j++) {
      final top =
          base + Offset((j - 1) * 14 * _k * flip + sway, -(90 + j * 8) * _k);
      final stem = Path()
        ..moveTo(base.dx + (j - 1) * 4 * _k, base.dy)
        ..quadraticBezierTo(
          top.dx,
          top.dy - 20 * _k,
          top.dx + 16 * _k * flip,
          top.dy + 10 * _k,
        );
      _paperStroke(c, stem, tone(const Color(0xFF8A9A3E)), 1.8 * _k);
      final m = stem.computeMetrics().first;
      for (var d = m.length * 0.55; d < m.length; d += 5 * _k) {
        final t = m.getTangentForOffset(d)!;
        c.drawOval(
          Rect.fromCenter(
            center: t.position + Offset(3 * _k * flip, 0),
            width: 5 * _k,
            height: 3.2 * _k,
          ),
          grain,
        );
      }
    }
  }

  // Mangrove ------------------------------------------------------------------

  /// Where the forest meets the sea: a far shore of bushy mangroves, calm
  /// water with little fish, and mangrove trees standing on arching stilt
  /// roots. At night the trees twinkle with fireflies.
  void _mangroveBack(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final day = _day;
    _sky(c, s);
    final waterTop = h * 0.5;
    // Far shore of rounded mangrove treetops
    final shore = Path()
      ..addRect(Rect.fromLTRB(-10, h * 0.4, w + 10, waterTop + 4 * _k));
    for (var i = 0; i <= 8; i++) {
      shore.addOval(
        Rect.fromCircle(
          center: Offset(w * i / 8, h * 0.41 + sin(i * 1.7) * 6 * _k),
          radius: (24 + (i % 3) * 8) * _k,
        ),
      );
    }
    _paper(
      c,
      shore,
      day ? const Color(0xFF7DBF8E) : const Color(0xFF1F3F3A),
      lift: 2,
    );
    if (day) _sunbeams(c, s);
    // Calm water
    final water = Rect.fromLTRB(0, waterTop, w, h);
    c.drawRect(
      water,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: day
              ? const [Color(0xFF8ADAD0), Color(0xFF3E9BA8)]
              : const [Color(0xFF1D4E66), Color(0xFF0F2E45)],
        ).createShader(water),
    );
    // The sun or moon shimmering on the water
    final glow = day ? const Color(0xFFFFF4C2) : const Color(0xFFFFF1C2);
    for (var i = 0; i < 6; i++) {
      final y = waterTop + (6 + i * 9) * _k;
      final half = (26 - i * 3.0) * _k + sin(_phase * 4 + i) * 3 * _k;
      c.drawLine(
        Offset(w * 0.78 - half, y),
        Offset(w * 0.78 + half, y),
        Paint()
          ..color = glow.withValues(alpha: day ? 0.55 : 0.4)
          ..strokeWidth = 2.2 * _k
          ..strokeCap = StrokeCap.round,
      );
    }
    // Ripples drifting on the water
    final ripple = Paint()
      ..color = (day ? Colors.white : const Color(0xFF8FB4D8)).withValues(
        alpha: day ? 0.55 : 0.28,
      )
      ..strokeWidth = 1.6 * _k
      ..strokeCap = StrokeCap.round;
    final rr = Random(9);
    for (var i = 0; i < 14; i++) {
      final x = rr.nextDouble() * w;
      final y = waterTop + 10 * _k + rr.nextDouble() * (h - waterTop - 20 * _k);
      final dx = sin(_phase * 3 + i) * 6 * _k;
      c.drawLine(Offset(x + dx, y), Offset(x + dx + 14 * _k, y), ripple);
    }
    _fishes(c, s, waterTop);
    _mangroveTree(c, Offset(w * 0.13, waterTop + 10 * _k), 1.0);
    _mangroveTree(c, Offset(w * 0.86, waterTop + 4 * _k), 0.82);
    // Perches: a branch up high, a shiny mudflat down low
    for (final y in perches) {
      if (y < 0.6) {
        final branch = Path()
          ..moveTo(-10, h * y)
          ..quadraticBezierTo(w * 0.5, h * (y - 0.06), w + 10, h * (y + 0.02));
        _paperStroke(c, branch, _sunlit(const Color(0xFF6E4A2C)), 10 * _k);
        // Thin roots hanging down from the branch
        final m = branch.computeMetrics().first;
        for (final f in const [0.18, 0.34, 0.66, 0.82]) {
          final p = m.getTangentForOffset(m.length * f)!.position;
          _paperStroke(
            c,
            Path()
              ..moveTo(p.dx, p.dy)
              ..quadraticBezierTo(
                p.dx + 3 * _k,
                p.dy + 18 * _k,
                p.dx - 2 * _k,
                p.dy + 34 * _k,
              ),
            _sunlit(const Color(0xFF7A5534)),
            1.8 * _k,
          );
        }
      } else {
        _mudflat(c, s, h * y);
      }
    }
    if (!day) _treeFireflies(c, s);
    _fireflies(c, s);
  }

  /// A mangrove tree on arching stilt roots, with seed pods hanging down.
  void _mangroveTree(Canvas c, Offset base, double scale) {
    final k = _k * scale;
    final bark = _day
        ? _sunlit(const Color(0xFF6E4A2C))
        : const Color(0xFF3E2A1A);
    final top = base + Offset(0, -92 * k);
    // Stilt roots arching down into the water
    for (final dx in [-46.0, -28.0, -10.0, 12.0, 30.0, 48.0]) {
      final from = base + Offset(dx * 0.15 * k, -34 * k);
      final to = base + Offset(dx * k, 0);
      _paperStroke(
        c,
        Path()
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo(
            from.dx + dx * 0.7 * k,
            from.dy - 6 * k,
            to.dx,
            to.dy,
          ),
        bark,
        3.4 * k,
      );
    }
    _paper(
      c,
      Path()
        ..moveTo(base.dx - 6 * k, base.dy - 30 * k)
        ..lineTo(base.dx - 4 * k, top.dy + 10 * k)
        ..lineTo(base.dx + 4 * k, top.dy + 10 * k)
        ..lineTo(base.dx + 6 * k, base.dy - 30 * k)
        ..close(),
      bark,
      lift: 2,
    );
    // Seed pods: mangrove seeds sprout while still on the tree
    final pod = Paint()
      ..color = _day ? const Color(0xFF6E9A3A) : const Color(0xFF2D4A2A)
      ..strokeWidth = 2.4 * k
      ..strokeCap = StrokeCap.round;
    for (final dx in [-30.0, -12.0, 16.0, 34.0]) {
      final sway = sin(_phase * 4 + dx) * 2 * k;
      final p0 = top + Offset(dx * k, 16 * k);
      c.drawLine(p0, p0 + Offset(sway, 20 * k), pod);
    }
    // Leafy crown
    final dark = _day ? const Color(0xFF3F9A63) : const Color(0xFF1C4A38);
    final light = _day ? const Color(0xFF6CC27E) : const Color(0xFF24563F);
    for (final (o, r) in const [
      (Offset(-28, 6), 24.0),
      (Offset(26, 6), 24.0),
      (Offset(0, -8), 30.0),
      (Offset(-18, -18), 20.0),
      (Offset(18, -16), 22.0),
    ]) {
      _paper(c, _circ(top + o * k, r * k), dark, lift: 2);
    }
    for (final (o, r) in const [
      (Offset(-10, -16), 12.0),
      (Offset(14, -6), 10.0),
      (Offset(-24, 2), 8.0),
    ]) {
      c.drawCircle(top + o * k, r * k, Paint()..color = light);
    }
  }

  /// Fireflies gathered in the mangrove trees, blinking together.
  void _treeFireflies(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final r = Random(17);
    for (final (cx, cy, k) in [
      (w * 0.13, h * 0.5 - 82 * _k, 1.0),
      (w * 0.86, h * 0.5 - 72 * _k, 0.82),
    ]) {
      for (var i = 0; i < 14; i++) {
        final p = Offset(
          cx + (r.nextDouble() - 0.5) * 80 * _k * k,
          cy + (r.nextDouble() - 0.5) * 52 * _k * k,
        );
        final on = 0.3 + 0.7 * (0.5 + 0.5 * sin(_phase * 8 + i * 0.4));
        c.drawCircle(
          p,
          5 * _k,
          Paint()
            ..color = AppColors.gold.withValues(alpha: 0.3 * on)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * _k),
        );
        c.drawCircle(
          p,
          1.6 * _k,
          Paint()..color = const Color(0xFFFFF3B0).withValues(alpha: on),
        );
      }
    }
  }

  /// Little fish swimming back and forth in the shallows.
  void _fishes(Canvas c, Size s, double waterTop) {
    final w = s.width, h = s.height;
    final colors = _day
        ? const [Color(0xFFF2B23C), Color(0xFFF08A3C), Color(0xFFFFF4DC)]
        : const [Color(0xFF4A6E8A), Color(0xFF4A6E8A), Color(0xFF4A6E8A)];
    for (var i = 0; i < 3; i++) {
      final dir = i.isEven ? 1.0 : -1.0;
      final x =
          ((t * (0.6 + i * 0.2) + i * 0.33) % 1.0) * (w + 60 * _k) - 30 * _k;
      final fx = dir > 0 ? x : w - x;
      final fy = waterTop + (h - waterTop) * (0.3 + i * 0.18);
      c.save();
      c.translate(fx, fy + sin(_phase * 6 + i) * 2 * _k);
      c.scale(dir * _k, _k);
      final paint = Paint()..color = colors[i];
      c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 16, height: 9),
        paint,
      );
      c.drawPath(
        Path()
          ..moveTo(-7, 0)
          ..lineTo(-13, -5)
          ..lineTo(-13, 5)
          ..close(),
        paint,
      );
      c.drawCircle(
        const Offset(4, -1),
        1.3,
        Paint()..color = const Color(0xFF1A1208),
      );
      c.restore();
    }
  }

  /// A shiny mudflat with crab holes, where mudskippers and crabs live.
  void _mudflat(Canvas c, Size s, double y) {
    final w = s.width;
    _paper(
      c,
      _wavyBand(s, y, 4 * _k, 2, 1),
      _day ? const Color(0xFF9A7A54) : const Color(0xFF3E2E22),
      lift: 2,
    );
    final hole = Paint()
      ..color = _day ? const Color(0xFF5E4630) : const Color(0xFF221810);
    final wet = Paint()
      ..color = Colors.white.withValues(alpha: _day ? 0.35 : 0.12);
    final r = Random(4);
    for (var i = 0; i < 9; i++) {
      final x = r.nextDouble() * w;
      final yy = y + (10 + r.nextDouble() * 26) * _k;
      c.drawOval(
        Rect.fromCenter(center: Offset(x, yy), width: 7 * _k, height: 3 * _k),
        hole,
      );
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x + 18 * _k, yy + 6 * _k),
          width: 12 * _k,
          height: 2 * _k,
        ),
        wet,
      );
    }
  }

  /// Stilt roots arching up from the bottom corners, and leafy branches
  /// hanging from the top.
  void _mangroveFront(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final bark = _day
        ? _sunlit(const Color(0xFF5B3A1F))
        : const Color(0xFF2E1F14);
    for (final (x, flip) in [(0.0, 1.0), (w, -1.0)]) {
      for (var i = 0; i < 3; i++) {
        final from = Offset(x + flip * (6 + i * 16) * _k, h + 6 * _k);
        final to = Offset(x + flip * (40 + i * 22) * _k, h + 6 * _k);
        _paperStroke(
          c,
          Path()
            ..moveTo(from.dx, from.dy)
            ..quadraticBezierTo(
              (from.dx + to.dx) / 2,
              h - (44 + i * 10) * _k,
              to.dx,
              to.dy,
            ),
          bark,
          4.5 * _k,
        );
      }
    }
    if (hanging) {
      for (final (x, a) in [(w * 0.08, 70.0), (w * 0.92, 110.0)]) {
        _leaf(c, Offset(x, -8), a, 70, 22, AppColors.leaf2, _Kind.plain, 4);
        _leaf(
          c,
          Offset(x, -8),
          a + 22,
          58,
          18,
          AppColors.leaf3,
          _Kind.plain,
          4,
        );
      }
    }
  }

  // Cave ----------------------------------------------------------------------

  /// Inside a cave: layered rock walls, stalactites, glowworms twinkling on
  /// the ceiling, crystals, an underground river, and light spilling in
  /// from the cave mouth (blue sky by day, the moon at night).
  void _caveBack(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final day = _day;
    final rect = Offset.zero & s;
    c.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E2846), Color(0xFF1A1628)],
        ).createShader(rect),
    );
    // The cave mouth, high on the right, with the world outside
    final mouthC = Offset(w * 0.74, h * 0.2);
    final mouthR = Rect.fromCenter(
      center: mouthC,
      width: 112 * _k,
      height: 86 * _k,
    );
    final mouth = Path()..addOval(mouthR);
    c.save();
    c.clipPath(mouth);
    c.drawRect(
      mouthR,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: day
              ? const [Color(0xFF9FD8F0), Color(0xFFE4F4E4)]
              : const [Color(0xFF1B1E4B), Color(0xFF2C3170)],
        ).createShader(mouthR),
    );
    if (day) {
      c.drawCircle(
        mouthC + Offset(26 * _k, -18 * _k),
        11 * _k,
        Paint()..color = const Color(0xFFFFD36E),
      );
    } else {
      c.drawCircle(
        mouthC + Offset(26 * _k, -18 * _k),
        9 * _k,
        Paint()..color = const Color(0xFFFFF1C2),
      );
      for (final o in const [
        Offset(-30, -20),
        Offset(-10, -30),
        Offset(4, -8),
      ]) {
        c.drawCircle(
          mouthC + o * _k,
          1 * _k,
          Paint()..color = Colors.white.withValues(alpha: 0.8),
        );
      }
    }
    c.drawPath(
      Path()..addOval(
        Rect.fromCenter(
          center: mouthC + Offset(0, 44 * _k),
          width: 150 * _k,
          height: 50 * _k,
        ),
      ),
      Paint()..color = day ? const Color(0xFF6FAF7E) : const Color(0xFF1F3F3A),
    );
    c.restore();
    // Light spilling in from the mouth
    final light = day ? const Color(0xFFFFF4D6) : const Color(0xFFB8C8F0);
    c.drawPath(
      Path()
        ..moveTo(mouthC.dx - 40 * _k, mouthC.dy + 20 * _k)
        ..lineTo(mouthC.dx + 30 * _k, mouthC.dy + 30 * _k)
        ..lineTo(w * 0.62, h)
        ..lineTo(w * 0.18, h)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            light.withValues(alpha: day ? 0.22 : 0.1),
            light.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
    // Rock walls, layer on layer
    _paper(
      c,
      Path()
        ..moveTo(-10, -10)
        ..lineTo(w * 0.3, -10)
        ..quadraticBezierTo(w * 0.16, h * 0.3, w * 0.24, h * 0.55)
        ..quadraticBezierTo(w * 0.1, h * 0.7, -10, h * 0.72)
        ..close(),
      const Color(0xFF3B3352),
    );
    _paper(
      c,
      Path()
        ..moveTo(w + 10, h * 0.32)
        ..quadraticBezierTo(w * 0.86, h * 0.48, w * 0.9, h * 0.7)
        ..lineTo(w + 10, h * 0.74)
        ..close(),
      const Color(0xFF453C5E),
    );
    // Ceiling with stalactites
    final ceiling = Path()..moveTo(-10, -10);
    for (var i = 0; i <= 12; i++) {
      final x = w * i / 12;
      final drop = (12 + (i * 37 % 5) * 7) * _k;
      ceiling
        ..lineTo(x - 7 * _k, 10 * _k)
        ..lineTo(x, 10 * _k + drop)
        ..lineTo(x + 7 * _k, 10 * _k);
    }
    ceiling
      ..lineTo(w + 10, -10)
      ..close();
    c.save();
    c.clipPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(rect)
        ..addOval(mouthR),
    );
    _paper(c, ceiling, const Color(0xFF3B3352));
    c.restore();
    // Glowworms twinkling on the ceiling
    final gr = Random(23);
    for (var i = 0; i < 22; i++) {
      final p = Offset(
        gr.nextDouble() * w * 0.62,
        (8 + gr.nextDouble() * 50) * _k,
      );
      final tw = 0.35 + 0.65 * (0.5 + 0.5 * sin(_phase * 7 + i * 1.3));
      c.drawCircle(
        p,
        4 * _k,
        Paint()
          ..color = const Color(0xFF7FE8FF).withValues(alpha: 0.25 * tw)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * _k),
      );
      c.drawCircle(
        p,
        1.3 * _k,
        Paint()..color = const Color(0xFFCFF8FF).withValues(alpha: tw),
      );
    }
    _crystals(c, Offset(w * 0.12, h * 0.6), 1);
    _crystals(c, Offset(w * 0.9, h * 0.66), 0.8);
    // Bats resting upside down
    for (final (x, y) in [(0.36, 0.13), (0.44, 0.16)]) {
      _hangingBat(c, Offset(w * x, h * y));
    }
    // The underground river
    final river = Rect.fromLTRB(0, h * 0.88, w, h);
    c.drawRect(
      river,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2F7F9A), Color(0xFF1C4A66)],
        ).createShader(river),
    );
    final glint = Paint()
      ..color = const Color(0xFF9FE6F2).withValues(alpha: 0.55)
      ..strokeWidth = 1.6 * _k
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final x = (w * i / 6 + sin(_phase * 3 + i) * 8 * _k) % w;
      final y = h * 0.92 + (i % 2) * 6 * _k;
      c.drawLine(Offset(x, y), Offset(x + 14 * _k, y), glint);
    }
    // Perches: a rock ledge up high, the rocky cave floor down low
    for (final y in perches) {
      if (y < 0.6) {
        _paperStroke(
          c,
          Path()
            ..moveTo(-10, h * y)
            ..quadraticBezierTo(
              w * 0.5,
              h * (y - 0.04),
              w + 10,
              h * (y + 0.02),
            ),
          const Color(0xFF5E5578),
          11 * _k,
        );
      } else {
        _paper(
          c,
          Path()
            ..moveTo(-10, h * y)
            ..quadraticBezierTo(w * 0.3, h * (y - 0.03), w * 0.55, h * y)
            ..quadraticBezierTo(w * 0.8, h * (y + 0.02), w + 10, h * (y - 0.01))
            ..lineTo(w + 10, h * 0.9)
            ..lineTo(-10, h * 0.9)
            ..close(),
          const Color(0xFF4A4166),
          lift: 2,
        );
        final pebble = Paint()..color = const Color(0xFF5E5578);
        final pr = Random(7);
        for (var i = 0; i < 8; i++) {
          c.drawOval(
            Rect.fromCenter(
              center: Offset(
                pr.nextDouble() * w,
                h * y + (8 + pr.nextDouble() * 14) * _k,
              ),
              width: 8 * _k,
              height: 4 * _k,
            ),
            pebble,
          );
        }
      }
    }
  }

  /// A cluster of glinting cave crystals.
  void _crystals(Canvas c, Offset base, double scale) {
    final k = _k * scale;
    const colors = [Color(0xFF9B7FD6), Color(0xFF6FC4C8), Color(0xFFB59BE8)];
    for (final (i, (dx, hgt, a)) in const [
      (-10.0, 26.0, -0.35),
      (0.0, 36.0, 0.0),
      (10.0, 22.0, 0.4),
    ].indexed) {
      c.save();
      c.translate(base.dx + dx * k, base.dy);
      c.rotate(a);
      final shard = Path()
        ..moveTo(-5 * k, 0)
        ..lineTo(-5 * k, -hgt * 0.7 * k)
        ..lineTo(0, -hgt * k)
        ..lineTo(5 * k, -hgt * 0.7 * k)
        ..lineTo(5 * k, 0)
        ..close();
      _paper(c, shard, colors[i], lift: 1.5);
      c.drawLine(
        Offset(-1.5 * k, -hgt * 0.65 * k),
        Offset(-1.5 * k, -hgt * 0.2 * k),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = 1.4 * k,
      );
      c.restore();
    }
    // A little twinkle
    final tw = 0.5 + 0.5 * sin(_phase * 6 + base.dx);
    final star = Paint()
      ..color = Colors.white.withValues(alpha: tw)
      ..strokeWidth = 1.2 * k
      ..strokeCap = StrokeCap.round;
    final sp = base + Offset(4 * k, -34 * k);
    c.drawLine(sp + Offset(-4 * k, 0), sp + Offset(4 * k, 0), star);
    c.drawLine(sp + Offset(0, -4 * k), sp + Offset(0, 4 * k), star);
  }

  /// A small bat hanging upside down, wings wrapped like a cloak.
  void _hangingBat(Canvas c, Offset at) {
    final k = _k;
    final sway = sin(_phase * 3 + at.dx) * 0.06;
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(sway);
    final bat = Paint()..color = const Color(0xFF1A1626);
    c.drawLine(
      Offset.zero,
      Offset(0, 6 * k),
      Paint()
        ..color = const Color(0xFF1A1626)
        ..strokeWidth = 1.4 * k,
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(0, 14 * k), width: 11 * k, height: 18 * k),
      bat,
    );
    c.drawCircle(Offset(0, 24 * k), 4.5 * k, bat);
    for (final dx in [-1.0, 1.0]) {
      c.drawPath(
        Path()
          ..moveTo(dx * 1.5 * k, 27 * k)
          ..lineTo(dx * 4 * k, 31 * k)
          ..lineTo(dx * 3.5 * k, 26 * k)
          ..close(),
        bat,
      );
    }
    c.restore();
  }

  /// Stalactites hanging from the top edge, stalagmites rising from the
  /// bottom corners, and a few crystals up close.
  void _caveFront(Canvas c, Size s) {
    final w = s.width, h = s.height;
    const rock = Color(0xFF2A2440);
    for (final (x, len) in [(0.04, 46.0), (0.16, 30.0), (0.92, 40.0)]) {
      _paper(
        c,
        Path()
          ..moveTo(w * x - 12 * _k, -6)
          ..lineTo(w * x + 12 * _k, -6)
          ..lineTo(w * x, len * _k)
          ..close(),
        rock,
      );
      // A drip of water about to fall
      final drip = (t * 3 + x) % 1.0;
      c.drawCircle(
        Offset(w * x, (len + 4 + drip * 18) * _k),
        1.8 * _k,
        Paint()..color = const Color(0xFF9FE6F2).withValues(alpha: 1 - drip),
      );
    }
    for (final (x, hgt) in [
      (0.0, 60.0),
      (0.07, 36.0),
      (1.0, 52.0),
      (0.94, 30.0),
    ]) {
      _paper(
        c,
        Path()
          ..moveTo(w * x - 16 * _k, h + 6)
          ..lineTo(w * x + 16 * _k, h + 6)
          ..lineTo(w * x, h - hgt * _k)
          ..close(),
        rock,
      );
    }
    _crystals(c, Offset(w * 0.2, h + 2 * _k), 0.9);
  }

  // Lively touches for the rainforest and ocean -------------------------------

  /// Butterflies fluttering over the forest by day.
  void _butterflies(Canvas c, Size s) {
    if (!_day) return;
    final w = s.width, h = s.height;
    const colors = [Color(0xFFF08A3C), Color(0xFF4FA3D9), Color(0xFFF2A7B5)];
    for (var i = 0; i < 3; i++) {
      final a = t * 2 * pi * (1 + i * 0.3) + i * 2;
      final p = Offset(
        w * (0.25 + i * 0.25) + sin(a) * 30 * _k,
        h * (0.3 + i * 0.08) + sin(a * 2) * 12 * _k,
      );
      final flap = 0.35 + 0.65 * sin(_phase * 30 + i).abs();
      final wing = Paint()..color = colors[i];
      c.save();
      c.translate(p.dx, p.dy);
      for (final side in [-1.0, 1.0]) {
        c.save();
        c.scale(side * flap, 1);
        c.drawOval(Rect.fromLTWH(0, -10 * _k, 12 * _k, 10 * _k), wing);
        c.drawOval(Rect.fromLTWH(0, 0, 9 * _k, 7 * _k), wing);
        c.restore();
      }
      c.drawLine(
        Offset(0, -8 * _k),
        Offset(0, 7 * _k),
        Paint()
          ..color = const Color(0xFF2A2420)
          ..strokeWidth = 1.6 * _k
          ..strokeCap = StrokeCap.round,
      );
      c.restore();
    }
  }

  /// Bright tropical flowers in the bottom corners, and glowing mushrooms
  /// on the forest floor at night.
  void _forestFlowers(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final day = _day;
    Color dim(Color col) =>
        day ? col : Color.lerp(col, const Color(0xFF12143A), 0.45)!;
    // Hibiscus: five round red petals around a yellow center
    for (final (o, r) in [
      (Offset(w * 0.16, h * 0.88), 11.0),
      (Offset(w * 0.84, h * 0.9), 10.0),
    ]) {
      for (var i = 0; i < 5; i++) {
        final a = i * 2 * pi / 5 + _phase * 0.2;
        _paper(
          c,
          _circ(o + Offset(cos(a), sin(a)) * r * 0.7 * _k, r * 0.62 * _k),
          dim(const Color(0xFFE5574A)),
          lift: 1.5,
        );
      }
      c.drawCircle(
        o,
        r * 0.32 * _k,
        Paint()..color = dim(const Color(0xFFF2D16B)),
      );
    }
    // Little pink orchids
    for (final o in [Offset(w * 0.26, h * 0.93), Offset(w * 0.74, h * 0.95)]) {
      for (var i = 0; i < 3; i++) {
        final a = -pi / 2 + (i - 1) * 0.9;
        _paper(
          c,
          _circ(o + Offset(cos(a), sin(a)) * 5 * _k, 4.2 * _k),
          dim(const Color(0xFFF2A7B5)),
          lift: 1,
        );
      }
      c.drawCircle(o, 2.4 * _k, Paint()..color = dim(const Color(0xFFD45A8C)));
    }
    if (!day) {
      // Glowing mushrooms, like the real glowing fungi of Philippine forests
      for (final (o, k) in [
        (Offset(w * 0.3, h * 0.97), 1.0),
        (Offset(w * 0.34, h * 0.98), 0.7),
        (Offset(w * 0.69, h * 0.97), 0.85),
      ]) {
        final glow = 0.6 + 0.4 * sin(_phase * 5 + o.dx);
        c.drawCircle(
          o + Offset(0, -8 * _k * k),
          12 * _k * k,
          Paint()
            ..color = const Color(0xFF9CF2B8).withValues(alpha: 0.3 * glow)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * _k),
        );
        c.drawLine(
          o,
          o + Offset(0, -8 * _k * k),
          Paint()
            ..color = const Color(0xFFCFF8DA)
            ..strokeWidth = 2.2 * _k * k,
        );
        c.drawArc(
          Rect.fromCenter(
            center: o + Offset(0, -8 * _k * k),
            width: 14 * _k * k,
            height: 10 * _k * k,
          ),
          pi,
          pi,
          true,
          Paint()
            ..color = const Color(0xFF9CF2B8)
                .withValues(alpha: 0.6 + 0.4 * glow),
        );
      }
    }
  }

  /// Fish in little schools, bobbing jellyfish, sea stars on the sand, and
  /// at night, sparkling plankton.
  void _oceanLife(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final day = _day || time == ActiveTime.dawn;
    // A school of blue tangs and yellow fish
    final schools = [
      (0.32, 1.0, const Color(0xFF3A7FD5), const Color(0xFFF2C14E)),
      (0.55, -1.0, const Color(0xFFF2C14E), const Color(0xFFF08A3C)),
    ];
    for (final (si, (depth, dir, body, tail)) in schools.indexed) {
      final x0 =
          ((t * (0.5 + si * 0.2) + si * 0.4) % 1.0) * (w + 120 * _k) - 60 * _k;
      final cx = dir > 0 ? x0 : w - x0;
      for (var j = 0; j < 4; j++) {
        final o = Offset(
          cx - dir * (j % 2) * 14 * _k - dir * (j ~/ 2) * 22 * _k,
          h * depth + ((j % 2) * 10 - 5) * _k + sin(_phase * 6 + j) * 2 * _k,
        );
        c.save();
        c.translate(o.dx, o.dy);
        c.scale(dir * _k, _k);
        final b = Paint()
          ..color = day
              ? body
              : Color.lerp(body, const Color(0xFF0B1435), 0.5)!;
        final tl = Paint()
          ..color = day
              ? tail
              : Color.lerp(tail, const Color(0xFF0B1435), 0.5)!;
        c.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 15, height: 9),
          b,
        );
        c.drawPath(
          Path()
            ..moveTo(-6, 0)
            ..lineTo(-12, -5)
            ..lineTo(-12, 5)
            ..close(),
          tl,
        );
        c.drawCircle(
          const Offset(4, -1),
          1.2,
          Paint()..color = const Color(0xFF1A1208),
        );
        c.restore();
      }
    }
    // Jellyfish bobbing up and down
    for (final (i, x) in [(0, 0.78), (1, 0.18)]) {
      final bob = sin(_phase * 3 + i * 2) * 8 * _k;
      final o = Offset(w * x, h * (0.42 + i * 0.12) + bob);
      final jelly = const Color(0xFFF2A7D8).withValues(alpha: day ? 0.75 : 0.9);
      if (!day) {
        c.drawCircle(
          o,
          16 * _k,
          Paint()
            ..color = const Color(0xFFF2A7D8).withValues(alpha: 0.25)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * _k),
        );
      }
      final tent = Paint()
        ..color = jelly
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * _k
        ..strokeCap = StrokeCap.round;
      for (var k = -1; k <= 1; k++) {
        final sx = o.dx + k * 4 * _k;
        c.drawPath(
          Path()
            ..moveTo(sx, o.dy)
            ..quadraticBezierTo(
              sx + sin(_phase * 5 + k) * 4 * _k,
              o.dy + 10 * _k,
              sx,
              o.dy + 20 * _k,
            ),
          tent,
        );
      }
      c.drawArc(
        Rect.fromCenter(center: o, width: 22 * _k, height: 18 * _k),
        pi,
        pi,
        true,
        Paint()..color = jelly,
      );
      c.drawCircle(
        o + Offset(-4 * _k, -4 * _k),
        2 * _k,
        Paint()..color = Colors.white.withValues(alpha: 0.6),
      );
    }
    // Sea stars resting on the sand
    for (final (o, col) in [
      (Offset(w * 0.3, h * 0.93), const Color(0xFFE5703F)),
      (Offset(w * 0.68, h * 0.95), const Color(0xFF9B7FD6)),
    ]) {
      final star = Path();
      for (var i = 0; i < 10; i++) {
        final r = (i.isEven ? 8 : 3.5) * _k;
        final a = -pi / 2 + i * pi / 5;
        final p = o + Offset(cos(a) * r, sin(a) * r);
        i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
      }
      _paper(
        c,
        star..close(),
        day ? col : Color.lerp(col, const Color(0xFF0B1435), 0.4)!,
        lift: 1,
      );
    }
    if (!day) {
      // Glowing plankton sparkling in the dark water
      final pr = Random(31);
      for (var i = 0; i < 18; i++) {
        final p = Offset(
          pr.nextDouble() * w,
          h * (0.2 + pr.nextDouble() * 0.6),
        );
        final tw = 0.5 + 0.5 * sin(_phase * 9 + i * 1.7);
        c.drawCircle(
          p,
          1.3 * _k,
          Paint()..color = const Color(0xFF9FF0FF).withValues(alpha: 0.8 * tw),
        );
      }
    }
  }

  // Ocean -----------------------------------------------------------------------

  /// Night sky with the parols down to [waterY], then the sea below it, so
  /// a partner can swim up to the surface.
  void _skyOverWater(Canvas c, Size s, double waterY) {
    final w = s.width;
    final skyRect = Rect.fromLTWH(0, 0, w, waterY);
    final day = _day;
    c.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: day
              ? const [Color(0xFF8FCDEB), Color(0xFFCDEBF2)]
              : const [Color(0xFF141638), Color(0xFF2A2F6E)],
        ).createShader(skyRect),
    );
    if (day) {
      // A small sun and a white cloud over the sea
      final sun = Offset(w * 0.85, waterY * 0.62);
      c.drawCircle(
        sun,
        30 * _k,
        Paint()..color = const Color(0xFFFFD36E).withValues(alpha: 0.3),
      );
      _paper(c, _circ(sun, 14 * _k), const Color(0xFFFFD36E), lift: 1.5);
      _paper(
        c,
        _cloud(Offset(w * 0.2, waterY * 0.66), 0.8 * _k),
        Colors.white,
        lift: 2,
      );
    } else {
      final star = Paint()..color = Colors.white.withValues(alpha: 0.7);
      final sr = Random(21);
      for (var i = 0; i < 18; i++) {
        final twinkle = 0.6 + 0.4 * sin(_phase * 6 + i);
        c.drawCircle(
          Offset(sr.nextDouble() * w, sr.nextDouble() * waterY * 0.9),
          (0.6 + sr.nextDouble()) * _k * twinkle,
          star,
        );
      }
      c.drawCircle(
        Offset(w * 0.12, waterY * 0.3),
        13 * _k,
        Paint()..color = const Color(0xFFF6E3A8),
      );
    }
    if (parols) _parols(c, s);
    // The sea, drawn in its own space starting at the water line. Its top
    // waves become the surface.
    c.save();
    c.clipRect(Rect.fromLTWH(0, waterY, w, s.height - waterY));
    c.translate(0, waterY);
    _oceanBack(c, Size(w, s.height - waterY));
    c.restore();
  }

  void _oceanBack(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final rect = Offset.zero & s;
    final (top, bottom) = switch (time) {
      ActiveTime.dawn => (const Color(0xFF3F8FB8), const Color(0xFF123A66)),
      ActiveTime.dusk => (const Color(0xFF5A5A9E), const Color(0xFF14204F)),
      ActiveTime.night || ActiveTime.dayAndNight => (
        const Color(0xFF1E3A70),
        const Color(0xFF0B1435),
      ),
      ActiveTime.day => (const Color(0xFF5BC0D6), const Color(0xFF1C6F8F)),
    };
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(rect),
    );
    // Light rays from the surface
    for (var i = 0; i < 5; i++) {
      final x = w * (0.08 + i * 0.22) + sin(_phase * 3 + i) * 10 * _k;
      final ray = Path()
        ..moveTo(x - 8 * _k, 0)
        ..lineTo(x + 16 * _k, 0)
        ..lineTo(x + 56 * _k, h * 0.85)
        ..lineTo(x + 10 * _k, h * 0.85)
        ..close();
      c.drawPath(
        ray,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.12 + 0.05 * sin(_phase * 6 + i)),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(ray.getBounds()),
      );
    }
    // Paper waves at the surface
    for (var i = 0; i < 3; i++) {
      final y = (6 + i * 9) * _k;
      final band = Path()..moveTo(-10, -10);
      for (var x = -10.0; x <= w + 10; x += 8) {
        band.lineTo(x, y + sin(x / (24 * _k) + _phase * 4 + i) * 3 * _k);
      }
      band
        ..lineTo(w + 10, -10)
        ..close();
      _paper(c, band, Color.lerp(top, Colors.white, 0.25 - i * 0.07)!, lift: 2);
    }
    // Far reef and sand
    _paper(
      c,
      _wavyBand(s, h * 0.72, 12 * _k, 3, 1),
      Color.lerp(bottom, Colors.black, 0.2)!,
    );
    _paper(c, _wavyBand(s, h * 0.86, 5 * _k, 4, 0.5), const Color(0xFF8C7A5B));
    final rnd = Random(4);
    const coral = [Color(0xFFE5704F), Color(0xFFD45A8C), Color(0xFFE9A23B)];
    for (var i = 0; i < 4; i++) {
      _coral(
        c,
        Offset(w * (0.1 + i * 0.27) + rnd.nextDouble() * 16 * _k, h * 0.88),
        (24 + rnd.nextDouble() * 14) * _k,
        coral[i % 3],
      );
    }
    for (var i = 0; i < 6; i++) {
      _seaweed(
        c,
        Offset(w * (0.05 + i * 0.18), h * 0.9),
        h * (0.22 + (i % 3) * 0.08),
        i,
      );
    }
    // Rising bubbles
    final bubble = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * _k;
    final br = Random(9);
    for (var i = 0; i < 14; i++) {
      final x = br.nextDouble() * w;
      final speed = 2 + br.nextDouble() * 2;
      final y = h - ((t * speed + br.nextDouble()) % 1) * h;
      c.drawCircle(
        Offset(x + sin(_phase * 8 + i) * 4 * _k, y),
        (1.5 + br.nextDouble() * 4) * _k,
        bubble,
      );
    }
    _oceanLife(c, s);
  }

  void _oceanFront(Canvas c, Size s) {
    final w = s.width, h = s.height;
    _seaweed(
      c,
      Offset(w * 0.02, h + 4),
      h * 0.42,
      7,
      color: const Color(0xFF1F6B4A),
    );
    _seaweed(
      c,
      Offset(w * 0.1, h + 4),
      h * 0.3,
      8,
      color: const Color(0xFF2E8A5C),
    );
    _seaweed(
      c,
      Offset(w * 0.96, h + 4),
      h * 0.38,
      9,
      color: const Color(0xFF1F6B4A),
    );
    _coral(c, Offset(w * 0.86, h + 6), 40 * _k, const Color(0xFFE5704F));
    _coral(c, Offset(w * 0.18, h + 6), 32 * _k, const Color(0xFFD45A8C));
  }

  void _seaweed(Canvas c, Offset base, double height, int i, {Color? color}) {
    final sway = sin(_phase * 4 + i * 0.8) * 12 * _k;
    final p = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(
        base.dx - 14 * _k + sway * .3,
        base.dy - height / 3,
        base.dx + 14 * _k + sway * .7,
        base.dy - height * 2 / 3,
        base.dx + sway,
        base.dy - height,
      );
    _paperStroke(c, p, _sunlit(color ?? const Color(0xFF2E7A55)), 7 * _k);
  }

  void _coral(Canvas c, Offset base, double size, Color color) {
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * _k);
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round;
    void branch(
      Offset from,
      double angle,
      double len,
      int depth,
      bool isShadow,
    ) {
      final to = from + Offset(cos(angle) * len, sin(angle) * len);
      final p = isShadow ? shadow : paint;
      p.strokeWidth = (2 + depth * 1.6) * _k;
      final shift = isShadow ? Offset(0, 3 * _k) : Offset.zero;
      c.drawLine(from + shift, to + shift, p);
      if (depth == 0) {
        if (!isShadow) {
          c.drawCircle(
            to,
            2.6 * _k,
            Paint()..color = Color.lerp(color, Colors.white, 0.35)!,
          );
        }
        return;
      }
      branch(to, angle - 0.45, len * 0.7, depth - 1, isShadow);
      branch(to, angle + 0.45, len * 0.7, depth - 1, isShadow);
    }

    branch(base, -pi / 2, size * 0.45, 2, true);
    branch(base, -pi / 2, size * 0.45, 2, false);
  }

  @override
  bool shouldRepaint(ScenePainter old) =>
      old.clock != clock ||
      old.t != t ||
      old.habitatId != habitatId ||
      old.time != time ||
      old.layer != layer ||
      old.skyLine != skyLine ||
      old.trunk != trunk ||
      old.parolStyle != parolStyle;
}

enum _Kind { plain, monstera, banana }

/// Paints a parol (Filipino star lantern) hanging from [hang], swinging by
/// [swing] radians. [lit] parols glow; unlit ones are dark paper.
void drawParol(
  Canvas c,
  Offset hang,
  double size,
  Color color, {
  double swing = 0,
  bool lit = true,
  ParolStyle? style,
}) {
  final s = size;
  c.save();
  c.translate(hang.dx, hang.dy);
  c.rotate(swing);
  final center = Offset(0, s * 1.05);
  if (lit) {
    c.drawCircle(
      center,
      s * 1.5,
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.8),
    );
  }
  c.drawLine(
    Offset.zero,
    center + Offset(0, -s * 0.95),
    Paint()
      ..color = const Color(0xFF3A2A1C)
      ..strokeWidth = 1.4,
  );
  Path star(double outer, double inner) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -pi / 2 + i * pi / 5;
      final pt = center + Offset(cos(a) * r, sin(a) * r);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  final tailColor = lit
      ? (style?.tail ?? AppColors.cream)
      : const Color(0xFF5A5F92);
  final tail = Paint()
    ..color = tailColor
    ..strokeWidth = s * 0.12
    ..strokeCap = StrokeCap.round;
  for (final (dx, len) in [(-0.35, 1.1), (0.0, 1.35), (0.35, 1.1)]) {
    final from = center + Offset(dx * s, s * 0.62);
    c.drawLine(from, from + Offset(dx * s * 0.45, len * s), tail);
  }
  final body = star(s, s * 0.45);
  c.drawPath(
    body.shift(Offset(0, s * 0.18)),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.12),
  );
  c.drawPath(body, Paint()..color = lit ? color : const Color(0xFF3A3F80));
  if (lit && style != null && style.rainbow) {
    // Each point its own color.
    for (var i = 0; i < 5; i++) {
      final a = -pi / 2 + i * 2 * pi / 5;
      final tip = center + Offset(cos(a) * s, sin(a) * s);
      final l =
          center +
          Offset(cos(a - pi / 5) * s * 0.45, sin(a - pi / 5) * s * 0.45);
      final r =
          center +
          Offset(cos(a + pi / 5) * s * 0.45, sin(a + pi / 5) * s * 0.45);
      c.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(l.dx, l.dy)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(r.dx, r.dy)
          ..close(),
        Paint()..color = style.colorAt(i),
      );
    }
  }
  if (lit && style != null && style.capiz) {
    // Pearly shell panels: fine lines from the middle and a soft sheen.
    final line = Paint()
      ..color = const Color(0xFFB9A57E).withValues(alpha: 0.6)
      ..strokeWidth = s * 0.03;
    for (var i = 0; i < 10; i++) {
      final a = -pi / 2 + i * pi / 5;
      final r = i.isEven ? s : s * 0.45;
      c.drawLine(center, center + Offset(cos(a) * r, sin(a) * r), line);
    }
    c.drawCircle(
      center + Offset(-s * 0.25, -s * 0.3),
      s * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
  }
  c.drawCircle(
    center,
    s * 0.32,
    Paint()..color = lit ? (style?.center ?? AppColors.cream) : AppColors.track,
  );
  c.drawPath(
    star(s * 0.62, s * 0.3),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.06
      ..color = tailColor,
  );
  c.restore();
}
