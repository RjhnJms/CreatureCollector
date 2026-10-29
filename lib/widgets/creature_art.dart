import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/rewards.dart';
import 'common.dart';
import 'outfits.dart';

/// Draws a creature as a cut-paper puppet: layered paper pieces, glossy
/// eyes, and warm parol light. With [animate] on, it bobs and blinks.
class CreatureArt extends StatefulWidget {
  const CreatureArt(
    this.creature, {
    super.key,
    this.size = 120,
    this.silhouette = false,
    this.animate = false,
    this.shadow = true,
    this.gaze = Offset.zero,
    this.blinkNow = false,
    this.outfit = const [],
    this.limb = 0,
  });

  /// How far flippers or wings are swung, from -1 to 1. Partners use it to
  /// paddle and flap; other creatures ignore it.
  final double limb;

  /// Outfit item ids to dress the creature in (used for Tarsi).
  final List<String> outfit;

  final Creature creature;
  final double size;

  /// Where the creature is looking, each axis from -1 to 1. Used to make
  /// eyes follow the flashlight.
  final Offset gaze;

  /// Close the eyes right now, for example when a light shines in them.
  final bool blinkNow;

  /// Draw as a dark shape only, for creatures not caught yet.
  final bool silhouette;
  final bool animate;
  final bool shadow;

  @override
  State<CreatureArt> createState() => _CreatureArtState();
}

class _CreatureArtState extends State<CreatureArt>
    with SingleTickerProviderStateMixin {
  AmbientClock? _breath;
  Timer? _blinkTimer;
  bool _blink = false;
  final _rnd = Random();

  @override
  void initState() {
    super.initState();
    if (widget.animate) _start();
  }

  @override
  void didUpdateWidget(CreatureArt old) {
    super.didUpdateWidget(old);
    if (widget.animate && _breath == null) _start();
  }

  void _start() {
    // One full breath, in and out, at the ambient frame rate.
    _breath = AmbientClock(
      vsync: this,
      period: Duration(milliseconds: 2 * (2200 + _rnd.nextInt(600))),
    )..start();
    _scheduleBlink();
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(Duration(milliseconds: 1800 + _rnd.nextInt(3200)), () {
      if (!mounted) return;
      setState(() => _blink = true);
      _blinkTimer = Timer(const Duration(milliseconds: 140), () {
        if (!mounted) return;
        setState(() => _blink = false);
        _scheduleBlink();
      });
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _breath?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final breath = _breath;
    final painter = CustomPaint(
      painter: _CreaturePainter(
        widget.creature,
        silhouette: widget.silhouette,
        shadow: widget.shadow && !widget.silhouette,
        breathClock: still ? null : breath,
        blink: (_blink || widget.blinkNow) && !widget.silhouette,
        gaze: widget.gaze,
        limb: widget.limb,
        outfit: widget.silhouette ? const [] : widget.outfit,
      ),
    );
    return SizedBox.square(dimension: widget.size, child: painter);
  }
}

class _Pose {
  const _Pose({required this.blink, this.gaze = Offset.zero, this.limb = 0});
  final bool blink;
  final Offset gaze;
  final double limb;
}

/// How many times any creature has painted, for performance tests.
@visibleForTesting
int debugCreaturePaints = 0;

class _CreaturePainter extends CustomPainter {
  _CreaturePainter(
    this.creature, {
    required this.silhouette,
    required this.shadow,
    this.breathClock,
    required this.blink,
    this.gaze = Offset.zero,
    this.limb = 0,
    this.outfit = const [],
  }) : super(repaint: breathClock);

  final Creature creature;
  final bool silhouette;
  final bool shadow;
  final Offset gaze;
  final double limb;
  final List<String> outfit;

  /// Drives the breathing bob; null keeps the creature still.
  final ValueListenable<double>? breathClock;

  /// 0..1, how far into a breath the creature is: in, then out again.
  double get breath {
    final v = breathClock?.value;
    if (v == null) return 0;
    return Curves.easeInOut.transform(1 - (2 * v - 1).abs());
  }

  final bool blink;

  @override
  void paint(Canvas canvas, Size size) {
    debugCreaturePaints++;
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    if (shadow) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(50, 95), width: 62, height: 9),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    if (silhouette) {
      canvas.saveLayer(
        const Rect.fromLTWH(-10, -10, 120, 120),
        Paint()
          ..colorFilter = const ColorFilter.mode(
            Color(0xFF2A3370),
            BlendMode.srcIn,
          ),
      );
    }

    // Paper-puppet bob: rise a little and rock from the feet.
    canvas.translate(50, 96);
    canvas.translate(0, -breath * 3);
    canvas.rotate((breath - 0.5) * 0.05);
    canvas.translate(-50, -96);

    if (!silhouette) {
      canvas.saveLayer(const Rect.fromLTWH(-10, -10, 120, 120), Paint());
    }
    final draw = _drawers[creature.id] ?? _blob;
    draw(canvas, creature.color, _Pose(blink: blink, gaze: gaze, limb: limb));
    // Clothes stack body first, then neck, face, and head.
    final items = [...outfit]
      ..sort(
        (a, b) => (rewardById[b]?.slot?.index ?? 0).compareTo(
          rewardById[a]?.slot?.index ?? 0,
        ),
      );
    for (final id in items) {
      outfitPainters[id]?.call(canvas);
    }
    if (!silhouette) {
      // Warm parol light falling on the creature from the upper left.
      canvas.drawRect(
        const Rect.fromLTWH(-10, -10, 120, 120),
        Paint()
          ..blendMode = BlendMode.srcATop
          ..shader = const RadialGradient(
            center: Alignment(-0.7, -0.8),
            radius: 1.1,
            colors: [Color(0x55FFB35C), Color(0x00FFB35C)],
          ).createShader(const Rect.fromLTWH(-10, -10, 120, 120)),
      );
      canvas.restore();
    }

    if (silhouette) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CreaturePainter old) =>
      old.creature != creature ||
      old.silhouette != silhouette ||
      old.breathClock != breathClock ||
      old.breath != breath ||
      old.blink != blink ||
      old.gaze != gaze ||
      old.limb != limb ||
      old.outfit.join() != outfit.join();
}

typedef _Drawer = void Function(Canvas canvas, Color color, _Pose pose);

final Map<String, _Drawer> _drawers = {
  'tarsier': _tarsier,
  'civet': _civet,
  'colugo': _colugo,
  'eagle': _eagle,
  'rafflesia': _rafflesia,
  'firefly': _firefly,
  'whaleshark': _whaleshark,
  'dugong': _dugong,
  'clownfish': _clownfish,
  'clam': _clam,
  'turtle': _turtle,
  'seastar': _seastar,
  'rice': _rice,
  'carabao': _carabao,
  'birdwing': _birdwing,
  'bleedingheart': _bleedingheart,
  'sailfin': _sailfin,
  'cloudrat': _cloudrat,
  'mudskipper': _mudskipper,
  'fiddlercrab': _fiddlercrab,
  'mangrovetree': _mangrovetree,
  'kingfisher': _kingfisher,
  'monitor': _monitor,
  'catsnake': _catsnake,
  'fruitbat': _fruitbat,
  'swiftlet': _swiftlet,
  'cavecricket': _cavecricket,
  'whipspider': _whipspider,
  'cavecrab': _cavecrab,
  'stalactite': _stalactite,
  'partner_pawi': _partnerPawi,
  'partner_haribon': _partnerHaribon,
};

// Helpers -------------------------------------------------------------------

Color _shade(Color c, double amount) =>
    Color.lerp(c, const Color(0xFF0A0610), amount) ?? c;

Color _tint(Color c, double amount) => Color.lerp(c, Colors.white, amount) ?? c;

Path _oval(Offset center, double w, double h) =>
    Path()..addOval(Rect.fromCenter(center: center, width: w, height: h));

Path _circ(Offset center, double r) =>
    Path()..addOval(Rect.fromCircle(center: center, radius: r));

final _paths = <String, Path>{};

/// A shape from SVG-style path data, using absolute M, L, Q, C and Z, so
/// shapes drawn in the design mockups carry over as-is. Parsed once.
Path _p(String d) => _paths.putIfAbsent(d, () {
  final tokens = RegExp(r'[MLQCZ]|-?\d*\.?\d+')
      .allMatches(d)
      .map((m) => m.group(0)!)
      .toList();
  final path = Path();
  var i = 0;
  var cmd = 'M';
  double n() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    if (RegExp(r'^[MLQCZ]$').hasMatch(tokens[i])) {
      cmd = tokens[i++];
      if (cmd == 'Z') {
        path.close();
        continue;
      }
    }
    switch (cmd) {
      case 'M':
        path.moveTo(n(), n());
        cmd = 'L';
      case 'L':
        path.lineTo(n(), n());
      case 'Q':
        path.quadraticBezierTo(n(), n(), n(), n());
      case 'C':
        path.cubicTo(n(), n(), n(), n(), n(), n());
    }
  }
  return path;
});

final _paperShadow = Paint()
  ..color = Colors.black.withValues(alpha: 0.32)
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.1);

/// A cut-paper piece: flat color with a soft shadow underneath, so pieces
/// stacked on top of each other look layered. [outline] adds a thin, darker
/// cut edge; [light] and [dark] are kept for callers that tune contrast.
void _part(
  Canvas c,
  Path p,
  Color color, {
  bool outline = true,
  double light = 0.28,
  double dark = 0.3,
}) {
  c.drawPath(p.shift(const Offset(0.5, 1.8)), _paperShadow);
  c.drawPath(p, Paint()..color = color);
  if (outline) {
    c.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = _shade(color, 0.35).withValues(alpha: 0.5),
    );
  }
}

void _stroke(Canvas c, Path p, Color color, double width) {
  c.drawPath(
    p,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color,
  );
}

/// A glossy eye. When blinking, it's covered by a lid of [lid] color with a
/// little closed-eye curve.
void _eye(
  Canvas c,
  Offset at,
  double r,
  _Pose pose, {
  required Color lid,
  Color iris = const Color(0xFF1A1208),
  double lidR = 0,
}) {
  if (pose.blink) {
    c.drawCircle(at, max(r, lidR) + 0.4, Paint()..color = lid);
    _stroke(
      c,
      Path()
        ..moveTo(at.dx - r, at.dy)
        ..quadraticBezierTo(at.dx, at.dy + r * 0.7, at.dx + r, at.dy),
      _shade(lid, 0.6),
      max(1.2, r * 0.22),
    );
    return;
  }
  // Look toward the gaze direction, staying inside the eye.
  at +=
      Offset(pose.gaze.dx.clamp(-1.0, 1.0), pose.gaze.dy.clamp(-1.0, 1.0)) *
      r *
      0.35;
  c.drawCircle(
    at,
    r,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        colors: [_tint(iris, 0.18), iris],
      ).createShader(Rect.fromCircle(center: at, radius: r)),
  );
  c.drawCircle(
    at + Offset(r * 0.34, -r * 0.36),
    r * 0.34,
    Paint()..color = Colors.white,
  );
  c.drawCircle(
    at + Offset(-r * 0.32, r * 0.34),
    r * 0.14,
    Paint()..color = Colors.white.withValues(alpha: 0.75),
  );
}

Path _star(
  Offset center,
  double outer,
  double inner,
  int points, {
  double rotate = 0,
}) {
  final path = Path();
  for (var i = 0; i < points * 2; i++) {
    final r = i.isEven ? outer : inner;
    final a = -pi / 2 + rotate + i * pi / points;
    final p = center + Offset(cos(a) * r, sin(a) * r);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

void _cheeks(Canvas c, List<Offset> at, double r) {
  for (final o in at) {
    c.drawCircle(
      o,
      r,
      Paint()
        ..color = const Color(0xFFFF8FA3).withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
  }
}

// Creatures -----------------------------------------------------------------

void _blob(Canvas c, Color color, _Pose pose) {
  _part(c, _circ(const Offset(50, 60), 32), color);
  _eye(c, const Offset(40, 55), 5, pose, lid: color);
  _eye(c, const Offset(60, 55), 5, pose, lid: color);
}

void _tarsier(Canvas c, Color color, _Pose pose) {
  final body = _shade(color, 0.18);
  // The tail swings from its base while leaping.
  c.save();
  c.translate(72, 84);
  c.rotate(-pose.limb * 0.3);
  c.translate(-72, -84);
  _stroke(
    c,
    Path()
      ..moveTo(72, 84)
      ..cubicTo(92, 80, 98, 62, 90, 44),
    _shade(color, 0.3),
    4.5,
  );
  c.drawCircle(const Offset(90, 44), 3.4, Paint()..color = _shade(color, 0.3));
  c.restore();
  _part(c, _oval(const Offset(50, 76), 46, 36), body);
  _part(
    c,
    _oval(const Offset(50, 81), 26, 22),
    _tint(color, 0.35),
    outline: false,
  );
  for (final x in [25.0, 75.0]) {
    _part(c, _oval(Offset(x, 26), 20, 27), color);
    c.drawOval(
      Rect.fromCenter(center: Offset(x, 28), width: 10, height: 16),
      Paint()..color = const Color(0xFFE09A8A),
    );
  }
  _part(c, _circ(const Offset(50, 49), 28), color);
  for (final x in [38.5, 61.5]) {
    if (!pose.blink) {
      _part(
        c,
        _circ(Offset(x, 47), 12.5),
        const Color(0xFFF0C85A),
        light: 0.4,
        dark: 0.2,
      );
    }
    _eye(
      c,
      Offset(x, 47.5),
      8,
      pose,
      lid: color,
      iris: const Color(0xFF120D08),
      lidR: 12.5,
    );
  }
  c.drawOval(
    Rect.fromCenter(center: const Offset(50, 59.5), width: 4.5, height: 3),
    Paint()..color = _shade(color, 0.6),
  );
  _stroke(
    c,
    Path()
      ..moveTo(46, 63)
      ..quadraticBezierTo(50, 66, 54, 63),
    _shade(color, 0.6),
    1.4,
  );
  _cheeks(c, const [Offset(30, 58), Offset(70, 58)], 4);
  for (final x in [37.0, 63.0]) {
    _part(c, _circ(Offset(x, 91), 4.5), color);
  }
}

void _civet(Canvas c, Color color, _Pose pose) {
  final body = _tint(color, 0.12);
  final head = _tint(color, 0.25);
  final dark = _shade(color, 0.45);
  // Plain dark tail: Asian palm civets have no rings on it.
  _part(
    c,
    _p('M64 78 C88 79 93 53 78 46 C73 44 70 49 75 52 C82 56 80 70 64 70Z'),
    dark,
  );
  _part(c, _oval(const Offset(50, 70), 38, 34), body);
  _part(
    c,
    _oval(const Offset(50, 75), 20, 20),
    _tint(color, 0.4),
    outline: false,
  );
  // Rows of dark spots on its coat
  final spot = Paint()..color = dark.withValues(alpha: 0.8);
  for (final o in const [
    Offset(36, 64),
    Offset(39, 71),
    Offset(64, 64),
    Offset(61, 71),
    Offset(35, 78),
    Offset(65, 78),
  ]) {
    c.drawOval(Rect.fromCenter(center: o, width: 4, height: 3), spot);
  }
  for (final x in [41.0, 59.0]) {
    _part(c, _oval(Offset(x, 86), 11, 7), dark);
  }
  _part(c, _p('M33 32 L35 13 L47 26Z'), head);
  _part(c, _p('M67 32 L65 13 L53 26Z'), head);
  final inner = Paint()..color = dark;
  c.drawPath(_p('M36 29 L36.5 19 L43 27Z'), inner);
  c.drawPath(_p('M64 29 L63.5 19 L57 27Z'), inner);
  _part(c, _oval(const Offset(50, 40), 40, 34), head);
  // Dark mask with white spots above and below the eyes
  c.drawPath(
    _p('M31 38 Q50 29 69 38 Q70 47 60 46 Q50 43 40 46 Q30 47 31 38Z'),
    inner,
  );
  final white = Paint()..color = const Color(0xFFEEE6D4);
  for (final (o, w, h) in const [
    (Offset(41, 31), 6.0, 3.5),
    (Offset(59, 31), 6.0, 3.5),
    (Offset(40, 48.5), 7.0, 4.0),
    (Offset(60, 48.5), 7.0, 4.0),
  ]) {
    c.drawOval(Rect.fromCenter(center: o, width: w, height: h), white);
  }
  for (final x in [42.0, 58.0]) {
    if (!pose.blink) {
      _part(
        c,
        _circ(Offset(x, 39), 4.5),
        const Color(0xFFE8B83A),
        outline: false,
      );
    }
    _eye(c, Offset(x, 39.5), 2.8, pose, lid: dark, lidR: 4.5);
  }
  _part(
    c,
    _oval(const Offset(50, 51), 12, 8),
    _tint(color, 0.45),
    outline: false,
  );
  const nose = Color(0xFF2A201A);
  c.drawOval(
    Rect.fromCenter(center: const Offset(50, 49), width: 4.5, height: 3.2),
    Paint()..color = nose,
  );
  _stroke(c, _p('M47.5 53 Q50 55 52.5 53'), nose, 1);
  _cheeks(c, const [Offset(35, 52), Offset(65, 52)], 2.5);
}

void _colugo(Canvas c, Color color, _Pose pose) {
  final cape = _shade(color, 0.08);
  // The gliding skin, stretched from its arms to its legs
  _part(
    c,
    _p(
      'M50 39 C35 35 15 36 7 49 L11 52 L9 58 L15 60 L14 67 L22 68 L23 75 '
      'L31 75 L34 81 L42 79 L50 85 L58 79 L66 81 L69 75 L77 75 L78 68 '
      'L86 67 L85 60 L91 58 L89 52 L93 49 C85 36 65 35 50 39Z',
    ),
    cape,
  );
  // Mottled, lichen-like speckles that hide it on tree bark
  final speck = Paint()..color = _tint(color, 0.5).withValues(alpha: 0.85);
  for (final (o, r) in const [
    (Offset(18, 52), 1.5),
    (Offset(25, 59), 1.2),
    (Offset(20, 63), 1.0),
    (Offset(30, 67), 1.5),
    (Offset(32, 54), 1.0),
    (Offset(37, 74), 1.2),
  ]) {
    c.drawCircle(o, r, speck);
    c.drawCircle(Offset(100 - o.dx, o.dy), r, speck);
  }
  final claw = _shade(color, 0.6);
  for (final s in [-1.0, 1.0]) {
    final x = 50 + s * 43;
    _stroke(
      c,
      Path()
        ..moveTo(x, 49)
        ..lineTo(x + s * 2.5, 47)
        ..moveTo(x, 49)
        ..lineTo(x + s * 3, 50),
      claw,
      1,
    );
  }
  _part(c, _oval(const Offset(50, 60), 30, 36), color);
  _part(
    c,
    _oval(const Offset(50, 64), 18, 22),
    _tint(color, 0.45),
    outline: false,
  );
  final head = _tint(color, 0.08);
  for (final x in [37.0, 63.0]) {
    _part(c, _circ(Offset(x, 26), 4.5), cape);
  }
  _part(c, _oval(const Offset(50, 38), 36, 32), head);
  _part(
    c,
    _oval(const Offset(50, 44), 22, 15),
    _tint(color, 0.4),
    outline: false,
  );
  // Big eyes for gliding at night
  _eye(c, const Offset(43, 36.5), 5.8, pose, lid: head);
  _eye(c, const Offset(57, 36.5), 5.8, pose, lid: head);
  final ink = _shade(color, 0.7);
  c.drawOval(
    Rect.fromCenter(center: const Offset(50, 43.2), width: 4.4, height: 2.8),
    Paint()..color = ink,
  );
  _stroke(c, _p('M47.5 47 Q50 49 52.5 47'), ink, 1);
  _cheeks(c, const [Offset(36, 44), Offset(64, 44)], 2.6);
}

void _eagle(Canvas c, Color color, _Pose pose) {
  const cream = Color(0xFFEADCC0);
  const buff = Color(0xFFD9BD8A);
  final wing = _shade(color, 0.22);
  // Shaggy crest: the Philippine eagle's famous "mane"
  _part(c, _star(const Offset(50, 30), 30, 18, 9), _tint(color, 0.25));
  _part(
    c,
    _star(const Offset(50, 31), 24, 15, 9, rotate: pi / 9),
    buff,
    outline: false,
  );
  // Folded wings
  for (final (x, a) in const [(29.0, 0.18), (71.0, -0.18)]) {
    c.save();
    c.translate(x, 70);
    c.rotate(a);
    _part(c, _oval(Offset.zero, 18, 38), wing);
    for (var i = 0; i < 3; i++) {
      _stroke(
        c,
        Path()
          ..moveTo(-5, -2 + i * 7.0)
          ..quadraticBezierTo(0, 2 + i * 7.0, 5, -2 + i * 7.0),
        _shade(color, 0.5),
        1,
      );
    }
    c.restore();
  }
  _part(c, _oval(const Offset(50, 72), 40, 36), color);
  _part(c, _oval(const Offset(50, 76), 24, 24), cream, outline: false);
  for (final x in [42.0, 58.0]) {
    for (final dx in [-2.5, 0.0, 2.5]) {
      _stroke(
        c,
        Path()
          ..moveTo(x, 88)
          ..lineTo(x + dx, 93),
        const Color(0xFFE8B83A),
        2,
      );
    }
  }
  _part(c, _circ(const Offset(50, 42), 21), cream);
  // Brown streaks on the crown
  for (final dx in [-6.0, 0.0, 6.0]) {
    _stroke(
      c,
      Path()
        ..moveTo(50 + dx, 23)
        ..lineTo(50 + dx * 1.2, 30),
      _shade(buff, 0.35),
      1.4,
    );
  }
  for (final x in [41.0, 59.0]) {
    if (!pose.blink) {
      _part(
        c,
        _circ(Offset(x, 40), 7.5),
        const Color(0xFFFFF8E6),
        outline: false,
      );
    }
    _eye(
      c,
      Offset(x, 40.5),
      5,
      pose,
      lid: cream,
      iris: const Color(0xFF3E64A0),
      lidR: 7.5,
    );
  }
  // Big hooked blue-gray beak
  _part(
    c,
    _p('M44 47 Q50 43 56 47 L54 54 Q51.5 59 47.5 56.5 Q50 55 49.5 52 L45 51Z'),
    const Color(0xFF61779A),
  );
  _cheeks(c, const [Offset(33, 49), Offset(67, 49)], 3);
}

void _rafflesia(Canvas c, Color color, _Pose pose) {
  // The vine it grows on
  _stroke(
    c,
    Path()
      ..moveTo(0, 92)
      ..quadraticBezierTo(40, 84, 100, 94),
    const Color(0xFF5A3A22),
    5,
  );
  final spot = Paint()..color = _tint(color, 0.78);
  const center = Offset(50, 54);
  final petal = _p('M-14 -10 C-20 -30 -10 -42 0 -42 C10 -42 20 -30 14 -10Z');
  for (var i = 0; i < 5; i++) {
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(i * 2 * pi / 5);
    _part(c, petal, color);
    // Its warty, spotted petals
    for (final (o, r) in const [
      (Offset(-6, -30), 2.6),
      (Offset(5, -33), 2.2),
      (Offset(0, -22), 2.8),
      (Offset(-9, -19), 1.8),
      (Offset(8, -21), 2.0),
    ]) {
      c.drawCircle(o, r, spot);
    }
    c.restore();
  }
  final disc = _shade(color, 0.3);
  _part(c, _circ(center, 17), disc);
  for (var i = 0; i < 12; i++) {
    final a = i * pi / 6;
    c.drawCircle(
      center + Offset(cos(a) * 14, sin(a) * 14),
      1.1,
      Paint()..color = _tint(color, 0.45),
    );
  }
  for (final x in [44.0, 56.0]) {
    if (!pose.blink) {
      _part(
        c,
        _circ(Offset(x, 51), 4.4),
        const Color(0xFFFFF4DC),
        outline: false,
      );
    }
    _eye(c, Offset(x, 51.3), 3, pose, lid: disc, lidR: 4.4);
  }
  // The flower's opening, as a little "o"
  c.drawOval(
    Rect.fromCenter(center: const Offset(50, 60), width: 7, height: 5),
    Paint()..color = _shade(color, 0.75),
  );
  _cheeks(c, const [Offset(38.5, 58), Offset(61.5, 58)], 2.6);
}

void _firefly(Canvas c, Color color, _Pose pose) {
  // Glow from its lantern tail
  c.drawCircle(
    const Offset(50, 76),
    26,
    Paint()
      ..color = color.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
  );
  const body = Color(0xFF3A3530);
  const shield = Color(0xFFE07A3A);
  final wing = Paint()..color = const Color(0x99DDE6FF);
  final vein = Paint()
    ..color = const Color(0x77FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  for (final (x, a) in const [(33.0, -0.35), (67.0, 0.35)]) {
    c.save();
    c.translate(x, 58);
    c.rotate(a);
    final r = Rect.fromCenter(center: Offset.zero, width: 22, height: 36);
    c.drawOval(r, wing);
    c.drawOval(r.deflate(4), vein);
    c.restore();
  }
  for (final dx in [-1.0, 1.0]) {
    for (final y in [60.0, 67.0]) {
      _stroke(
        c,
        Path()
          ..moveTo(50 + dx * 9, y)
          ..lineTo(50 + dx * 15, y + 5),
        body,
        1.4,
      );
    }
  }
  _part(c, _oval(const Offset(50, 62), 24, 28), body);
  _part(c, _oval(const Offset(50, 79), 22, 18), color);
  c.drawOval(
    Rect.fromCenter(center: const Offset(47, 77), width: 9, height: 6),
    Paint()..color = Colors.white.withValues(alpha: 0.75),
  );
  // The orange shield behind its head, like real fireflies
  _part(c, _oval(const Offset(50, 47), 30, 13), shield);
  for (final dx in [-1.0, 1.0]) {
    _stroke(
      c,
      Path()
        ..moveTo(50 + dx * 5, 22)
        ..quadraticBezierTo(50 + dx * 8, 10, 50 + dx * 15, 8),
      body,
      1.6,
    );
    c.drawCircle(Offset(50 + dx * 15, 8), 2.4, Paint()..color = shield);
  }
  _part(c, _circ(const Offset(50, 33), 15), body);
  for (final x in [44.0, 56.0]) {
    if (!pose.blink) {
      _part(
        c,
        _circ(Offset(x, 32), 5.6),
        const Color(0xFFF6EAD0),
        outline: false,
      );
    }
    _eye(c, Offset(x, 32.4), 3.8, pose, lid: body, lidR: 5.6);
  }
  _stroke(c, _p('M47.5 39.5 Q50 41.5 52.5 39.5'), const Color(0xFFF6EAD0), 1.1);
  _cheeks(c, const [Offset(39, 38), Offset(61, 38)], 2.6);
}

void _whaleshark(Canvas c, Color color, _Pose pose) {
  final fin = _shade(color, 0.15);
  _part(
    c,
    _p('M80 54 Q90 40 98 30 Q95 48 93 56 Q95 66 98 80 Q89 68 80 60Z'),
    fin,
  );
  _part(c, _p('M50 36 Q56 24 62 20 Q64 30 66 38Z'), fin);
  final body = _p(
    'M6 58 C6 40 24 32 48 34 C66 35 80 46 86 56 C80 66 66 76 46 76 '
    'C22 76 6 70 6 58Z',
  );
  _part(c, body, color);
  c.save();
  c.clipPath(body);
  c.drawPath(
    _oval(const Offset(40, 76), 84, 24),
    Paint()..color = _tint(color, 0.6),
  );
  // Gill slits, then its checkerboard of pale spots
  for (var i = 0; i < 3; i++) {
    _stroke(
      c,
      Path()
        ..moveTo(28 + i * 3.5, 42)
        ..lineTo(27 + i * 3.5, 60),
      _shade(color, 0.3),
      1,
    );
  }
  final spot = Paint()..color = _tint(color, 0.85);
  for (var row = 0; row < 4; row++) {
    for (var x = 40.0 + (row % 2) * 3.5; x < 82; x += 7) {
      c.drawCircle(Offset(x, 41 + row * 6.0), 1.4, spot);
    }
  }
  c.restore();
  _part(c, _p('M34 66 Q30 80 40 84 Q42 76 44 68Z'), fin);
  // A wide, friendly mouth for filtering tiny plankton
  _stroke(c, _p('M8 62 Q16 67 26 63'), _shade(color, 0.55), 1.8);
  _eye(c, const Offset(19, 51), 3.4, pose, lid: color);
  _cheeks(c, const [Offset(23, 58)], 2.8);
}

void _dugong(Canvas c, Color color, _Pose pose) {
  final dark = _shade(color, 0.12);
  final body = _tint(color, 0.1);
  final head = _tint(color, 0.18);
  // A flat, whale-like fluke, not a fish tail
  _part(
    c,
    _p('M79 52 C85 50 91 48 98 45 C96 50 96 54 99 60 C92 59 86 58 79 59Z'),
    dark,
  );
  _part(
    c,
    _p(
      'M20 56 C20 40 40 34 60 37 C75 39 83 47 83 56 C83 67 70 74 50 74 '
      'C32 74 20 69 20 56Z',
    ),
    body,
  );
  c.drawPath(
    _p('M24 63 C35 71 65 73 80 62 C75 71 63 74 50 74 C38 74 28 70 24 63Z'),
    Paint()..color = _tint(color, 0.4),
  );
  c.save();
  c.translate(48, 67);
  c.rotate(0.49);
  _part(c, _oval(Offset.zero, 15, 7), dark);
  c.restore();
  _part(c, _oval(const Offset(25, 53), 26, 24), head);
  // The bristly snout it grazes seagrass with
  _part(c, _oval(const Offset(20, 60), 17, 12), _tint(color, 0.3));
  final dot = Paint()..color = _shade(color, 0.35);
  for (final o in const [
    Offset(16, 59),
    Offset(18.5, 61.5),
    Offset(21.5, 59),
    Offset(23.5, 62),
    Offset(17, 63.5),
  ]) {
    c.drawCircle(o, 0.6, dot);
  }
  _stroke(c, _p('M15 64 Q9 73 13 85'), const Color(0xFF4F9A66), 2.5);
  _stroke(c, _p('M19 65 Q21 75 16 87'), const Color(0xFF5BB174), 2.2);
  _eye(c, const Offset(31, 46), 2.8, pose, lid: head);
  _cheeks(c, const [Offset(33, 53)], 2.5);
}

void _clownfish(Canvas c, Color color, _Pose pose) {
  const edge = Color(0xFF1A1208);
  final finEdge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..color = edge;
  // Fins have thin black edges, like a real clownfish
  void fin(Path p) {
    _part(c, p, color);
    c.drawPath(p, finEdge);
  }

  fin(_p('M70 56 Q80 40 94 38 Q98 56 94 74 Q80 72 70 60Z'));
  fin(_p('M30 36 Q44 20 64 32 Q60 38 56 40 L34 42Z'));
  fin(_p('M40 74 Q42 86 52 86 Q54 80 52 72Z'));
  final body = _oval(const Offset(44, 56), 66, 46);
  _part(c, body, color);
  c.save();
  c.clipPath(body);
  for (final (x, w) in const [(27.0, 9.0), (47.0, 10.0), (69.0, 7.0)]) {
    c.drawRect(
      Rect.fromLTWH(x - w / 2 - 1.6, 20, w + 3.2, 80),
      Paint()..color = edge,
    );
    c.drawRect(
      Rect.fromLTWH(x - w / 2, 20, w, 80),
      Paint()..color = Colors.white,
    );
  }
  c.restore();
  fin(_oval(const Offset(47, 66), 12, 8));
  _eye(c, const Offset(18, 50), 4.8, pose, lid: color);
  _stroke(c, _p('M10 60 Q13 63 17 61'), _shade(color, 0.55), 1.3);
  _cheeks(c, const [Offset(18, 58)], 2.6);
}

void _clam(Canvas c, Color color, _Pose pose) {
  const shellTop = Color(0xFFF1E8D4);
  const shell = Color(0xFFE9DFC8);
  // The upper shell and mantle sit a little higher, so the mantle shows.
  c.save();
  c.translate(0, -7);
  _part(
    c,
    _p(
      'M14 56 L20 42 L27 51 L35 39 L43 49 L50 37 L57 49 L65 39 L73 51 '
      'L80 42 L86 56 C75 50 25 50 14 56Z',
    ),
    shellTop,
  );
  // Its bright mantle, where it farms algae in the sunlight
  final mantle = _p(
    'M16 58 C28 46 72 46 84 58 C76 63 65 62 50 63 C35 62 24 63 16 58Z',
  );
  c.drawPath(mantle.shift(const Offset(0.5, 1.8)), _paperShadow);
  c.drawPath(
    mantle,
    Paint()
      ..shader = LinearGradient(
        colors: [
          _tint(color, 0.1),
          const Color(0xFF3C8FD6),
          const Color(0xFF6E5BD0),
        ],
      ).createShader(const Rect.fromLTWH(16, 46, 68, 17)),
  );
  for (final o in const [
    Offset(28, 55),
    Offset(38, 52),
    Offset(62, 52),
    Offset(72, 55),
    Offset(50, 51),
  ]) {
    c.drawCircle(o, 1.2, Paint()..color = const Color(0xFFA8F0E6));
  }
  for (final o in const [
    Offset(33, 57),
    Offset(45, 55),
    Offset(55, 55),
    Offset(67, 57),
  ]) {
    c.drawCircle(o, 0.9, Paint()..color = const Color(0xFFF2D16B));
  }
  c.restore();
  _part(
    c,
    _p(
      'M15 60 L21 53 L28 61 L36 52 L44 61 L50 51 L56 61 L64 52 L72 61 '
      'L79 53 L85 60 C85 76 70 86 50 86 C30 86 15 76 15 60Z',
    ),
    shell,
  );
  for (final d in const [
    'M21 54 Q30 75 48 85',
    'M36 53 Q40 73 49 85',
    'M64 53 Q60 73 51 85',
    'M79 54 Q70 75 52 85',
  ]) {
    _stroke(c, _p(d), const Color(0xFFCDBF9E), 1);
  }
  _eye(c, const Offset(42, 70), 3, pose, lid: shell);
  _eye(c, const Offset(58, 70), 3, pose, lid: shell);
  _stroke(c, _p('M47 75 Q50 77.5 53 75'), const Color(0xFF1A120A), 0.9);
  _cheeks(c, const [Offset(36, 75), Offset(64, 75)], 2.5);
}

void _turtle(Canvas c, Color color, _Pose pose) {
  final skin = _tint(color, 0.35);
  // Back flippers behind the shell
  for (final (o, w, a) in const [
    (Offset(82, 70), 18.0, -0.5),
    (Offset(66, 74), 26.0, 0.5),
  ]) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(a);
    _part(c, _oval(Offset.zero, w, 10), _shade(skin, 0.08));
    c.restore();
  }
  _part(
    c,
    _p(
      'M26 60 C26 40 44 30 60 30 C78 30 92 42 92 58 C92 64 88 66 82 66 '
      'L34 66 C28 66 26 64 26 60Z',
    ),
    color,
  );
  final plate = Paint()..color = _tint(color, 0.22);
  c.drawPath(_hexagon(const Offset(59, 45), 8), plate);
  c.drawPath(_hexagon(const Offset(42, 52), 6.5), plate);
  c.drawPath(_hexagon(const Offset(76, 52), 6.5), plate);
  // The rim of the shell
  _part(
    c,
    _p('M24 62 L94 62 C94 68 90 70 84 70 L32 70 C26 70 24 68 24 62Z'),
    _shade(color, 0.2),
  );
  // Big front flipper for swimming
  c.save();
  c.translate(38, 75);
  c.rotate(0.55);
  _part(c, _oval(Offset.zero, 30, 11), skin);
  c.restore();
  _part(c, _circ(const Offset(18, 50), 14), skin);
  final spot = Paint()..color = _shade(skin, 0.12);
  for (final (o, r) in const [
    (Offset(14, 40), 1.8),
    (Offset(22, 39), 1.4),
    (Offset(26, 46), 1.2),
  ]) {
    c.drawCircle(o, r, spot);
  }
  _eye(c, const Offset(15, 48), 4.2, pose, lid: skin);
  _stroke(c, _p('M7 56 Q11 59 15 57'), _shade(skin, 0.55), 1.3);
  _cheeks(c, const [Offset(21, 56)], 2.6);
}

void _seastar(Canvas c, Color color, _Pose pose) {
  final body = _star(const Offset(50, 55), 41, 18, 5);
  // A wide round stroke softens the arm tips.
  Paint round(Color col) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 9
    ..strokeJoin = StrokeJoin.round
    ..color = col;
  final shadowPath = body.shift(const Offset(0.5, 1.8));
  c.drawPath(shadowPath, _paperShadow);
  c.drawPath(
    shadowPath,
    round(_paperShadow.color)..maskFilter = _paperShadow.maskFilter,
  );
  c.drawPath(body, round(color));
  c.drawPath(body, Paint()..color = color);
  c.drawCircle(const Offset(50, 55), 15, Paint()..color = _tint(color, 0.14));
  // Bumpy little tube-feet dots along each arm
  final dot = Paint()..color = _tint(color, 0.5);
  for (var i = 0; i < 5; i++) {
    final a = -pi / 2 + i * 2 * pi / 5;
    for (final r in [19.0, 27.0, 35.0]) {
      c.drawCircle(Offset(50 + cos(a) * r, 55 + sin(a) * r), 1.9, dot);
    }
  }
  _eye(c, const Offset(44, 52), 3.6, pose, lid: color);
  _eye(c, const Offset(56, 52), 3.6, pose, lid: color);
  _stroke(
    c,
    Path()
      ..moveTo(46.5, 60)
      ..quadraticBezierTo(50, 63, 53.5, 60),
    _shade(color, 0.55),
    1.3,
  );
  _cheeks(c, const [Offset(39, 59), Offset(61, 59)], 3);
}

// Rice terraces --------------------------------------------------------------

void _rice(Canvas c, Color color, _Pose pose) {
  // A patch of flooded field
  _part(c, _oval(const Offset(50, 88), 70, 14), const Color(0xFF7A5A3A));
  c.drawOval(
    Rect.fromCenter(center: const Offset(50, 86), width: 56, height: 7),
    Paint()..color = const Color(0xFF9FD3E6).withValues(alpha: 0.7),
  );
  // Long leaves fanning out
  final leaf = _shade(color, 0.12);
  for (final (dx, tipX, tipY) in const [
    (-6.0, 18.0, 22.0),
    (-3.0, 30.0, 12.0),
    (3.0, 70.0, 12.0),
    (6.0, 82.0, 22.0),
    (0.0, 50.0, 8.0),
  ]) {
    _stroke(
      c,
      Path()
        ..moveTo(50 + dx, 80)
        ..quadraticBezierTo(50 + dx * 3, 40, tipX, tipY),
      leaf,
      3.4,
    );
  }
  // Drooping golden grain heads
  const gold = Color(0xFFE2B84A);
  for (final (start, mid, end) in const [
    (Offset(46, 80), Offset(36, 20), Offset(22, 40)),
    (Offset(54, 80), Offset(64, 18), Offset(78, 38)),
  ]) {
    final stem = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
    _stroke(c, stem, _shade(color, 0.3), 1.6);
    final m = stem.computeMetrics().first;
    for (var d = m.length * 0.55; d < m.length; d += 3.6) {
      final t = m.getTangentForOffset(d)!;
      _part(c, _oval(t.position, 4.4, 3), gold, outline: false);
    }
  }
  // A round clump with a face at the base
  _part(c, _oval(const Offset(50, 74), 30, 22), color);
  _eye(c, const Offset(44, 72), 3, pose, lid: color);
  _eye(c, const Offset(56, 72), 3, pose, lid: color);
  _stroke(c, _p('M47 78 Q50 80.5 53 78'), _shade(color, 0.6), 1);
  _cheeks(c, const [Offset(39, 77), Offset(61, 77)], 2.4);
}

void _carabao(Canvas c, Color color, _Pose pose) {
  final dark = _shade(color, 0.3);
  const horn = Color(0xFFD8CCB0);
  for (final x in [32.0, 44.0, 56.0, 68.0]) {
    _part(
      c,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 4, 76, 8, 16),
          const Radius.circular(3),
        ),
      ),
      dark,
    );
  }
  _part(c, _oval(const Offset(50, 72), 60, 34), color);
  // Mud on its legs from a cool mud bath
  for (final x in [32.0, 44.0, 56.0, 68.0]) {
    c.drawOval(
      Rect.fromCenter(center: Offset(x, 89), width: 9, height: 5),
      Paint()..color = const Color(0xFF7A5A3A),
    );
  }
  // Big horns that sweep out and back
  _part(c, _p('M38 34 C22 32 8 22 10 8 C18 20 30 24 42 26Z'), horn);
  _part(c, _p('M62 34 C78 32 92 22 90 8 C82 20 70 24 58 26Z'), horn);
  for (final (x, a) in const [(27.0, 0.5), (73.0, -0.5)]) {
    c.save();
    c.translate(x, 42);
    c.rotate(a);
    _part(c, _oval(Offset.zero, 14, 7), color);
    c.restore();
  }
  _part(c, _oval(const Offset(50, 45), 38, 32), _tint(color, 0.08));
  // Wide muzzle with nostrils
  _part(c, _oval(const Offset(50, 56), 24, 14), _tint(color, 0.35));
  final nose = Paint()..color = _shade(color, 0.6);
  c.drawOval(
    Rect.fromCenter(center: const Offset(45.5, 56), width: 3.2, height: 2.2),
    nose,
  );
  c.drawOval(
    Rect.fromCenter(center: const Offset(54.5, 56), width: 3.2, height: 2.2),
    nose,
  );
  _eye(c, const Offset(42, 42), 3.6, pose, lid: _tint(color, 0.08));
  _eye(c, const Offset(58, 42), 3.6, pose, lid: _tint(color, 0.08));
  _cheeks(c, const [Offset(36, 50), Offset(64, 50)], 2.8);
}

void _birdwing(Canvas c, Color color, _Pose pose) {
  const black = Color(0xFF2A2420);
  final vein = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8
    ..color = const Color(0xFF6A6058);
  for (final s in [-1.0, 1.0]) {
    c.save();
    // Mirror the right side
    if (s > 0) {
      c.translate(100, 0);
      c.scale(-1, 1);
    }
    // Back wing: gold with a blue-green shimmer and black edge spots
    final back = _p('M47 60 C28 60 12 70 16 84 C22 95 40 90 48 70Z');
    _part(c, back, color);
    c.drawPath(
      back,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0x0000C2A8), Color(0x664FD6C8), Color(0x0000C2A8)],
        ).createShader(const Rect.fromLTWH(14, 58, 36, 36)),
    );
    for (final o in const [Offset(20, 84), Offset(27, 89), Offset(18, 76)]) {
      c.drawCircle(o, 2.2, Paint()..color = black);
    }
    // Front wing: black with pale veins
    final front = _p('M47 52 C32 22 6 22 8 44 C10 58 30 62 47 58Z');
    _part(c, front, black);
    for (final d in const [
      'M44 52 Q28 36 12 38',
      'M44 54 Q26 46 10 48',
      'M44 56 Q30 54 14 56',
    ]) {
      c.drawPath(_p(d), vein);
    }
    c.restore();
  }
  // Body, head, and antennae
  _part(c, _oval(const Offset(50, 64), 9, 34), black);
  for (final dx in [-1.0, 1.0]) {
    _stroke(
      c,
      Path()
        ..moveTo(50 + dx * 3, 26)
        ..quadraticBezierTo(50 + dx * 6, 12, 50 + dx * 13, 8),
      black,
      1.4,
    );
    c.drawCircle(Offset(50 + dx * 13, 8), 2.2, Paint()..color = color);
  }
  _part(c, _circ(const Offset(50, 35), 11), black);
  for (final x in [45.5, 54.5]) {
    if (!pose.blink) {
      _part(
        c,
        _circ(Offset(x, 34), 4.2),
        const Color(0xFFF6EAD0),
        outline: false,
      );
    }
    _eye(c, Offset(x, 34.3), 2.8, pose, lid: black, lidR: 4.2);
  }
  _stroke(c, _p('M47.5 40 Q50 42 52.5 40'), const Color(0xFFF6EAD0), 1);
  _cheeks(c, const [Offset(42, 39), Offset(58, 39)], 2.2);
}

void _bleedingheart(Canvas c, Color color, _Pose pose) {
  const chest = Color(0xFFF4EFE6);
  const red = Color(0xFFD23B3B);
  const leg = Color(0xFFE59AA0);
  for (final x in [44.0, 56.0]) {
    _stroke(
      c,
      Path()
        ..moveTo(x, 84)
        ..lineTo(x, 93),
      leg,
      2.2,
    );
    for (final dx in [-2.5, 0.0, 2.5]) {
      _stroke(
        c,
        Path()
          ..moveTo(x, 93)
          ..lineTo(x + dx, 95),
        leg,
        1.4,
      );
    }
  }
  // Wings at its sides, with a green sheen
  for (final (x, a) in const [(30.0, 0.2), (70.0, -0.2)]) {
    c.save();
    c.translate(x, 68);
    c.rotate(a);
    _part(c, _oval(Offset.zero, 16, 32), _shade(color, 0.2));
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, -6), width: 10, height: 14),
      Paint()..color = const Color(0xFF5BB18A).withValues(alpha: 0.45),
    );
    c.restore();
  }
  _part(c, _oval(const Offset(50, 68), 42, 38), color);
  _part(c, _oval(const Offset(50, 72), 28, 28), chest, outline: false);
  // The "bleeding heart": a red patch of feathers
  _part(
    c,
    _p(
      'M50 58 C56 58 58 64 54 68 C52 70 51 72 50 76 C49 72 48 70 46 68 C42 64 44 58 50 58Z',
    ),
    red,
    outline: false,
  );
  c.drawOval(
    Rect.fromCenter(center: const Offset(48.6, 62.5), width: 3.5, height: 2.5),
    Paint()..color = Colors.white.withValues(alpha: 0.5),
  );
  _part(c, _circ(const Offset(50, 37), 17), _tint(color, 0.1));
  // Shiny green-gray cap
  c.drawPath(
    _p('M35 33 Q50 14 65 33 Q50 26 35 33Z'),
    Paint()..color = const Color(0xFF7FA39A).withValues(alpha: 0.7),
  );
  _part(c, _p('M47 42 L53 42 L50 47Z'), const Color(0xFF2A2420));
  _eye(c, const Offset(43.5, 36), 3.6, pose, lid: _tint(color, 0.1));
  _eye(c, const Offset(56.5, 36), 3.6, pose, lid: _tint(color, 0.1));
  _cheeks(c, const [Offset(38, 43), Offset(62, 43)], 2.6);
}

void _sailfin(Canvas c, Color color, _Pose pose) {
  final dark = _shade(color, 0.3);
  final belly = Color.lerp(color, const Color(0xFFE6E08A), 0.55)!;
  // Long tail with its tall striped sail
  _part(c, _p('M58 66 C74 66 86 70 98 80 C86 78 74 76 58 76Z'), color);
  final sail = _p('M58 66 Q66 38 80 46 Q88 52 92 72 Q78 66 58 66Z');
  _part(c, sail, _tint(color, 0.25));
  c.save();
  c.clipPath(sail);
  for (var x = 62.0; x < 94; x += 6) {
    _stroke(
      c,
      Path()
        ..moveTo(x, 40)
        ..lineTo(x + 2, 72),
      dark,
      1,
    );
  }
  c.restore();
  // Legs
  for (final x in [30.0, 44.0, 56.0]) {
    _part(
      c,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 3, 72, 6, 16),
          const Radius.circular(3),
        ),
      ),
      dark,
    );
    for (final dx in [-3.0, 0.0, 3.0]) {
      _stroke(
        c,
        Path()
          ..moveTo(x, 88)
          ..lineTo(x + dx - 1.5, 91),
        dark,
        1.4,
      );
    }
  }
  _part(c, _oval(const Offset(46, 68), 40, 18), color);
  _part(c, _oval(const Offset(44, 73), 30, 7), belly, outline: false);
  // Spiky crest down its back
  for (var x = 32.0; x < 60; x += 5) {
    c.drawPath(
      Path()
        ..moveTo(x - 2, 60)
        ..lineTo(x, 55)
        ..lineTo(x + 2, 60)
        ..close(),
      Paint()..color = dark,
    );
  }
  // Big head
  _part(c, _oval(const Offset(22, 56), 32, 26), _tint(color, 0.08));
  _part(c, _oval(const Offset(16, 62), 18, 9), belly, outline: false);
  _eye(c, const Offset(22, 52), 4.4, pose, lid: _tint(color, 0.08));
  _stroke(c, _p('M8 60 Q13 63 18 61'), _shade(color, 0.6), 1.2);
  c.drawCircle(const Offset(9, 55), 0.9, Paint()..color = _shade(color, 0.6));
  _cheeks(c, const [Offset(27, 60)], 2.6);
}

void _cloudrat(Canvas c, Color color, _Pose pose) {
  const patch = Color(0xFF5A4A3E);
  // Long, bushy dark tail curling up behind
  _stroke(c, _p('M64 84 C90 86 98 60 88 40 C84 32 78 30 76 36'), patch, 9);
  _stroke(
    c,
    _p('M64 84 C90 86 98 60 88 40 C84 32 78 30 76 36'),
    _tint(patch, 0.15),
    5,
  );
  // Fluffy body: a scalloped edge for its long fur
  final fluff = Path()
    ..addOval(
      Rect.fromCenter(center: const Offset(50, 70), width: 46, height: 40),
    );
  for (var i = 0; i < 14; i++) {
    final a = i * 2 * pi / 14;
    fluff.addOval(
      Rect.fromCircle(
        center: Offset(50 + cos(a) * 22, 70 + sin(a) * 19),
        radius: 5,
      ),
    );
  }
  _part(c, fluff, color);
  _part(
    c,
    _oval(const Offset(50, 74), 24, 22),
    _tint(color, 0.4),
    outline: false,
  );
  // Dark patches on its shoulders
  for (final x in [34.0, 66.0]) {
    c.drawOval(
      Rect.fromCenter(center: Offset(x, 62), width: 12, height: 16),
      Paint()..color = patch.withValues(alpha: 0.8),
    );
  }
  for (final x in [41.0, 59.0]) {
    _part(c, _oval(Offset(x, 90), 12, 7), _tint(patch, 0.2));
  }
  for (final x in [32.0, 68.0]) {
    _part(c, _circ(Offset(x, 26), 6.5), patch);
    c.drawCircle(Offset(x, 26), 3.5, Paint()..color = const Color(0xFFE09A8A));
  }
  _part(c, _circ(const Offset(50, 40), 19), _tint(color, 0.15));
  // Dark mask around its eyes
  for (final x in [42.0, 58.0]) {
    c.drawOval(
      Rect.fromCenter(center: Offset(x, 38), width: 13, height: 11),
      Paint()..color = patch,
    );
  }
  _eye(c, const Offset(42, 38), 3.8, pose, lid: patch);
  _eye(c, const Offset(58, 38), 3.8, pose, lid: patch);
  c.drawOval(
    Rect.fromCenter(center: const Offset(50, 47), width: 5, height: 3.6),
    Paint()..color = const Color(0xFFE08A9A),
  );
  _stroke(c, _p('M47 50.5 Q50 53 53 50.5'), patch, 1);
  _cheeks(c, const [Offset(37, 48), Offset(63, 48)], 2.6);
}

// Mangrove -------------------------------------------------------------------

void _mudskipper(Canvas c, Color color, _Pose pose) {
  final dark = _shade(color, 0.2);
  // Tail fin
  _part(c, _p('M86 62 Q98 52 99 64 Q98 76 86 68Z'), dark);
  // Its colorful back fin, raised to show off
  final fin = _p('M42 50 Q46 26 60 28 Q70 32 70 54Z');
  _part(c, fin, const Color(0xFF6FB6D9));
  for (final o in const [
    Offset(52, 36),
    Offset(60, 40),
    Offset(50, 46),
    Offset(63, 48),
  ]) {
    c.drawCircle(o, 1.8, Paint()..color = const Color(0xFF2E5A8A));
  }
  _part(
    c,
    _p(
      'M12 62 C12 48 30 44 46 48 C66 52 80 58 92 64 C80 70 66 74 46 74 '
      'C26 76 12 72 12 62Z',
    ),
    color,
  );
  _part(
    c,
    _oval(const Offset(42, 70), 44, 8),
    _tint(color, 0.45),
    outline: false,
  );
  for (final o in const [
    Offset(40, 56),
    Offset(52, 58),
    Offset(64, 62),
    Offset(46, 64),
  ]) {
    c.drawCircle(o, 1.4, Paint()..color = dark);
  }
  // Front fin used like an arm
  _part(c, _p('M30 66 Q24 80 34 84 Q40 78 40 68Z'), dark);
  // Eyes poking up on top of its head
  for (final (x, y) in const [(22.0, 44.0), (34.0, 42.0)]) {
    _part(c, _circ(Offset(x, y), 6.5), _tint(color, 0.1));
    _eye(c, Offset(x, y - 0.5), 4.4, pose, lid: _tint(color, 0.1));
  }
  _stroke(c, _p('M12 62 Q16 66 22 64'), _shade(color, 0.6), 1.3);
  _cheeks(c, const [Offset(24, 57)], 2.6);
}

void _fiddlercrab(Canvas c, Color color, _Pose pose) {
  final leg = _shade(color, 0.2);
  for (var i = 0; i < 4; i++) {
    for (final s in [-1.0, 1.0]) {
      _stroke(
        c,
        Path()
          ..moveTo(50 + s * 20, 64 + i * 4.0)
          ..quadraticBezierTo(
            50 + s * 32,
            62 + i * 4.0,
            50 + s * 38,
            74 + i * 5.0,
          ),
        leg,
        2.4,
      );
    }
  }
  // The giant claw and its small partner
  _stroke(c, _p('M68 60 Q76 56 80 48'), leg, 4);
  _part(
    c,
    _p('M74 50 C70 30 88 18 96 30 C100 38 94 44 86 42 C90 48 88 54 80 54Z'),
    const Color(0xFFF2C14E),
  );
  _stroke(c, _p('M86 42 Q82 36 78 38'), const Color(0xFFB8862E), 1.2);
  _stroke(c, _p('M32 60 Q26 56 24 50'), leg, 3);
  _part(c, _oval(const Offset(23, 47), 9, 8), color);
  // Eyes up on stalks
  for (final x in [42.0, 58.0]) {
    _stroke(
      c,
      Path()
        ..moveTo(x, 52)
        ..lineTo(x + (x < 50 ? -2 : 2), 38),
      leg,
      2.2,
    );
    final at = Offset(x + (x < 50 ? -2 : 2), 35);
    if (!pose.blink) {
      _part(c, _circ(at, 4.6), const Color(0xFFFFF8E6), outline: false);
    }
    _eye(c, at, 3, pose, lid: color, lidR: 4.6);
  }
  _part(c, _oval(const Offset(50, 62), 48, 30), color);
  _part(
    c,
    _oval(const Offset(50, 56), 32, 10),
    _tint(color, 0.3),
    outline: false,
  );
  _stroke(c, _p('M45 66 Q50 70 55 66'), _shade(color, 0.6), 1.3);
  _cheeks(c, const [Offset(36, 64), Offset(64, 64)], 2.8);
}

void _mangrovetree(Canvas c, Color color, _Pose pose) {
  const bark = Color(0xFF7A5534);
  // Water and mud at its feet
  _part(c, _oval(const Offset(50, 90), 80, 12), const Color(0xFF6FC4BE));
  // Arching stilt roots
  for (final (x, cx) in const [
    (16.0, 30.0),
    (30.0, 38.0),
    (70.0, 62.0),
    (84.0, 70.0),
  ]) {
    _stroke(
      c,
      Path()
        ..moveTo(50, 70)
        ..quadraticBezierTo(cx, 62, x, 90),
      bark,
      3.4,
    );
  }
  _part(
    c,
    Path()..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(41, 40, 18, 40),
        const Radius.circular(6),
      ),
    ),
    bark,
  );
  // Long seed pods hanging from the crown
  final pod = Paint()
    ..color = const Color(0xFF6E9A3A)
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round;
  for (final x in [24.0, 34.0, 66.0, 76.0]) {
    c.drawLine(Offset(x, 40), Offset(x, 54), pod);
  }
  // Leafy crown
  for (final (o, r) in const [
    (Offset(30, 34), 15.0),
    (Offset(70, 34), 15.0),
    (Offset(50, 22), 18.0),
    (Offset(38, 18), 12.0),
    (Offset(62, 18), 12.0),
  ]) {
    _part(c, _circ(o, r), color);
  }
  for (final (o, r) in const [
    (Offset(44, 14), 6.0),
    (Offset(28, 30), 5.0),
    (Offset(64, 28), 5.0),
  ]) {
    c.drawCircle(o, r, Paint()..color = _tint(color, 0.3));
  }
  // A friendly face on the trunk
  _eye(c, const Offset(45.5, 56), 2.8, pose, lid: bark);
  _eye(c, const Offset(54.5, 56), 2.8, pose, lid: bark);
  _stroke(c, _p('M47 63 Q50 65.5 53 63'), _shade(bark, 0.5), 1.1);
  _cheeks(c, const [Offset(43, 61), Offset(57, 61)], 2.2);
}

void _kingfisher(Canvas c, Color color, _Pose pose) {
  const white = Color(0xFFF6F2E8);
  const mask = Color(0xFF1E2A3A);
  // Little feet and short tail
  for (final x in [44.0, 56.0]) {
    _part(c, _oval(Offset(x, 90), 7, 4), const Color(0xFF3A3530));
  }
  _part(c, _p('M44 82 L56 82 L50 94Z'), _shade(color, 0.2));
  // Turquoise wings
  for (final (x, a) in const [(30.0, 0.18), (70.0, -0.18)]) {
    c.save();
    c.translate(x, 66);
    c.rotate(a);
    _part(c, _oval(Offset.zero, 17, 34), _shade(color, 0.12));
    for (var i = 0; i < 3; i++) {
      _stroke(
        c,
        Path()
          ..moveTo(-5, -2 + i * 7.0)
          ..quadraticBezierTo(0, 2 + i * 7.0, 5, -2 + i * 7.0),
        _shade(color, 0.45),
        1,
      );
    }
    c.restore();
  }
  _part(c, _oval(const Offset(50, 68), 38, 34), white);
  _part(c, _circ(const Offset(50, 38), 19), color);
  // The white collar it's named for
  _part(c, _oval(const Offset(50, 55), 36, 9), white, outline: false);
  // Dark stripe through the eyes
  c.drawPath(
    _p('M32 37 Q50 31 68 37 L68 42 Q50 36 32 42Z'),
    Paint()..color = mask,
  );
  for (final x in [43.0, 57.0]) {
    if (!pose.blink) _part(c, _circ(Offset(x, 38), 4.8), white, outline: false);
    _eye(c, Offset(x, 38.3), 3.2, pose, lid: color, lidR: 4.8);
  }
  // Big, strong beak
  _part(c, _p('M45 44 Q50 41 55 44 L50 57Z'), const Color(0xFF2A2A30));
  c.drawPath(
    _p('M47.5 50 L52.5 50 L50 57Z'),
    Paint()..color = const Color(0xFFD9CFC0),
  );
  _cheeks(c, const [Offset(37, 46), Offset(63, 46)], 2.6);
}

void _monitor(Canvas c, Color color, _Pose pose) {
  const spot = Color(0xFFE8C95A);
  final dark = _shade(color, 0.3);
  _stroke(c, _p('M66 70 C82 72 92 82 98 74'), color, 8);
  for (final o in const [Offset(76, 74), Offset(86, 78), Offset(94, 76)]) {
    c.drawCircle(o, 1.6, Paint()..color = spot);
  }
  for (final x in [32.0, 44.0, 60.0, 70.0]) {
    _part(
      c,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 3.2, 72, 6.4, 16),
          const Radius.circular(3),
        ),
      ),
      dark,
    );
    for (final dx in [-3.0, 0.0, 3.0]) {
      _stroke(
        c,
        Path()
          ..moveTo(x, 88)
          ..lineTo(x + dx - 1.5, 91),
        dark,
        1.3,
      );
    }
  }
  _part(
    c,
    _p(
      'M26 64 C26 54 42 52 56 54 C68 56 76 62 76 68 C76 74 68 78 54 78 C38 78 26 74 26 64Z',
    ),
    color,
  );
  // Rows of yellow spots
  for (final o in const [
    Offset(40, 58),
    Offset(50, 57),
    Offset(60, 59),
    Offset(68, 63),
    Offset(36, 66),
    Offset(46, 66),
    Offset(56, 67),
    Offset(66, 70),
  ]) {
    c.drawCircle(o, 1.9, Paint()..color = spot);
  }
  _part(
    c,
    _p('M34 60 C26 50 14 52 10 60 C12 66 22 70 34 70Z'),
    _tint(color, 0.12),
  );
  // Forked tongue, for smelling the air
  _stroke(
    c,
    Path()
      ..moveTo(11, 62)
      ..lineTo(5, 62)
      ..moveTo(5, 62)
      ..lineTo(1.5, 59.5)
      ..moveTo(5, 62)
      ..lineTo(1.5, 64.5),
    const Color(0xFFE5574A),
    1.3,
  );
  _eye(c, const Offset(21, 57), 3.8, pose, lid: _tint(color, 0.12));
  c.drawCircle(const Offset(12, 59), 0.9, Paint()..color = dark);
  _cheeks(c, const [Offset(26, 64)], 2.6);
}

void _catsnake(Canvas c, Color color, _Pose pose) {
  const band = Color(0xFFF2C94A);
  // Coils, stacked like a cozy pile
  for (final (o, w, h) in const [
    (Offset(50, 84), 66.0, 16.0),
    (Offset(50, 74), 52.0, 14.0),
    (Offset(50, 65), 40.0, 12.0),
  ]) {
    final coil = _oval(o, w, h);
    _part(c, coil, color);
    c.save();
    c.clipPath(coil);
    for (var x = o.dx - w / 2 + 6; x < o.dx + w / 2; x += 10) {
      c.drawRect(Rect.fromLTWH(x, o.dy - h, 3.2, h * 2), Paint()..color = band);
    }
    c.restore();
    // Shine on the glossy scales
    c.drawOval(
      Rect.fromCenter(
        center: o + Offset(-w * 0.2, -h * 0.25),
        width: w * 0.3,
        height: h * 0.18,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );
  }
  // Neck rising up to the head
  final neck = _p('M58 62 C70 52 62 42 52 38');
  _stroke(c, neck, color, 10);
  final m = neck.computeMetrics().first;
  for (final f in const [0.35, 0.7]) {
    final tg = m.getTangentForOffset(m.length * f)!;
    final n = Offset(-tg.vector.dy, tg.vector.dx) * 5;
    _stroke(
      c,
      Path()
        ..moveTo(tg.position.dx - n.dx, tg.position.dy - n.dy)
        ..lineTo(tg.position.dx + n.dx, tg.position.dy + n.dy),
      band,
      3,
    );
  }
  _part(c, _oval(const Offset(48, 30), 28, 22), color);
  // Yellow lips and chin
  c.drawPath(_p('M35 32 Q48 44 61 32 Q48 38 35 32Z'), Paint()..color = band);
  for (final x in [41.5, 54.5]) {
    if (!pose.blink) _part(c, _circ(Offset(x, 27), 5), band, outline: false);
    _eye(c, Offset(x, 27.3), 3.4, pose, lid: color, lidR: 5);
  }
  _stroke(
    c,
    Path()
      ..moveTo(48, 40)
      ..lineTo(48, 45)
      ..moveTo(48, 45)
      ..lineTo(46.5, 47.5)
      ..moveTo(48, 45)
      ..lineTo(49.5, 47.5),
    const Color(0xFFE5574A),
    1.1,
  );
  _cheeks(c, const [Offset(37, 33), Offset(59, 33)], 2.6);
}

// Cave -----------------------------------------------------------------------

void _fruitbat(Canvas c, Color color, _Pose pose) {
  final wing = _shade(color, 0.3);
  final bone = _shade(color, 0.5);
  for (final s in [-1.0, 1.0]) {
    c.save();
    if (s > 0) {
      c.translate(100, 0);
      c.scale(-1, 1);
    }
    _part(
      c,
      _p(
        'M42 50 C28 36 8 40 4 58 C10 56 14 60 16 68 C20 63 25 65 28 72 '
        'C32 66 37 66 42 70Z',
      ),
      wing,
    );
    // Long finger bones holding up the wing
    for (final d in const ['M42 52 L8 52', 'M42 56 L16 66', 'M42 60 L28 70']) {
      _stroke(c, _p(d), bone, 1);
    }
    c.restore();
  }
  for (final x in [44.0, 56.0]) {
    _part(c, _oval(Offset(x, 90), 6, 5), wing);
  }
  _part(c, _oval(const Offset(50, 68), 28, 34), color);
  _part(
    c,
    _oval(const Offset(50, 72), 16, 20),
    _tint(color, 0.35),
    outline: false,
  );
  // A ripe mango to munch
  _part(c, _oval(const Offset(50, 78), 16, 11), const Color(0xFFF2B23C));
  _part(c, _p('M50 72 Q54 66 59 68 Q55 72 50 72Z'), const Color(0xFF5BB174));
  // Pointed ears and a fox-like face
  final head = _tint(color, 0.1);
  _part(c, _p('M36 32 L36 16 L46 28Z'), head);
  _part(c, _p('M64 32 L64 16 L54 28Z'), head);
  _part(c, _circ(const Offset(50, 40), 16), head);
  _part(c, _oval(const Offset(50, 49), 13, 9), _tint(color, 0.35));
  c.drawOval(
    Rect.fromCenter(center: const Offset(50, 46.5), width: 4.4, height: 3),
    Paint()..color = _shade(color, 0.7),
  );
  _eye(c, const Offset(43.5, 38), 4, pose, lid: head);
  _eye(c, const Offset(56.5, 38), 4, pose, lid: head);
  _stroke(c, _p('M47.5 51 Q50 53 52.5 51'), _shade(color, 0.7), 1);
  _cheeks(c, const [Offset(38, 46), Offset(62, 46)], 2.6);
}

void _swiftlet(Canvas c, Color color, _Pose pose) {
  final dark = _shade(color, 0.3);
  // Long, pointed wings crossing behind
  _part(c, _p('M40 58 L8 78 L42 66Z'), dark);
  _part(c, _p('M60 58 L92 78 L58 66Z'), dark);
  _part(c, _oval(const Offset(50, 62), 36, 26), color);
  _part(c, _circ(const Offset(50, 44), 15), _tint(color, 0.08));
  _part(
    c,
    _oval(const Offset(50, 52), 14, 8),
    _tint(color, 0.45),
    outline: false,
  );
  for (final x in [44.0, 56.0]) {
    if (!pose.blink) {
      _part(
        c,
        _circ(Offset(x, 42), 4.6),
        const Color(0xFFF6F2E8),
        outline: false,
      );
    }
    _eye(c, Offset(x, 42.3), 3, pose, lid: _tint(color, 0.08), lidR: 4.6);
  }
  _part(c, _p('M47.5 48 L52.5 48 L50 51.5Z'), const Color(0xFF2A2420));
  _cheeks(c, const [Offset(39, 49), Offset(61, 49)], 2.4);
  // Its cup-shaped nest, made of hardened spit
  const nest = Color(0xFFF1E8D4);
  _part(c, _p('M26 70 Q50 64 74 70 Q72 92 50 94 Q28 92 26 70Z'), nest);
  for (final d in const [
    'M30 74 Q50 70 70 74',
    'M32 80 Q50 76 68 80',
    'M36 86 Q50 83 64 86',
  ]) {
    _stroke(c, _p(d), const Color(0xFFD9CDB0), 1);
  }
}

void _cavecricket(Canvas c, Color color, _Pose pose) {
  final dark = _shade(color, 0.3);
  // Super-long feelers
  _stroke(c, _p('M20 54 C8 30 28 10 58 8'), dark, 1.2);
  _stroke(c, _p('M23 54 C22 26 52 4 92 14'), dark, 1.2);
  // Thin legs
  for (final (x, dx) in const [(32.0, -6.0), (42.0, -2.0), (52.0, 2.0)]) {
    _stroke(
      c,
      Path()
        ..moveTo(x, 70)
        ..quadraticBezierTo(x + dx, 80, x + dx * 1.6, 90),
      dark,
      1.6,
    );
  }
  _part(
    c,
    _p('M28 62 C30 44 52 38 70 46 C82 52 86 62 84 70 C72 74 44 74 28 70Z'),
    color,
  );
  // The humped back's stripes
  for (final d in const [
    'M46 44 Q50 58 48 72',
    'M58 44 Q62 58 60 72',
    'M70 48 Q73 60 71 72',
  ]) {
    _stroke(c, _p(d), _shade(color, 0.15), 1.2);
  }
  // Big jumping leg
  _part(
    c,
    _p('M62 62 C72 40 92 42 94 50 C84 52 76 60 68 70Z'),
    _tint(color, 0.15),
  );
  _stroke(c, _p('M93 50 L86 89'), dark, 2);
  _stroke(c, _p('M86 89 L80 90'), dark, 1.6);
  _part(c, _oval(const Offset(25, 62), 22, 20), _tint(color, 0.1));
  _eye(c, const Offset(22, 58), 4.2, pose, lid: _tint(color, 0.1));
  _stroke(c, _p('M14 66 Q18 69 22 67'), _shade(color, 0.6), 1.1);
  _cheeks(c, const [Offset(27, 66)], 2.4);
}

void _whipspider(Canvas c, Color color, _Pose pose) {
  final leg = _shade(color, 0.25);
  // The long whip legs, used as feelers
  _stroke(c, _p('M42 46 C30 30 20 22 4 12'), leg, 1.1);
  _stroke(c, _p('M58 46 C70 30 80 22 96 12'), leg, 1.1);
  // Six walking legs, bent at the knee
  for (final s in [-1.0, 1.0]) {
    for (final (kx, ky, fx, fy) in const [
      (20.0, 50.0, 10.0, 66.0),
      (18.0, 66.0, 10.0, 84.0),
      (26.0, 80.0, 20.0, 94.0),
    ]) {
      _stroke(
        c,
        Path()
          ..moveTo(50 + s * 12, 62)
          ..lineTo(50 + s * (50 - kx), ky)
          ..lineTo(50 + s * (50 - fx), fy),
        leg,
        2,
      );
    }
  }
  _part(c, _oval(const Offset(50, 74), 30, 30), color);
  for (final y in [66.0, 72.0, 78.0, 84.0]) {
    _stroke(
      c,
      Path()
        ..moveTo(40, y)
        ..quadraticBezierTo(50, y + 2, 60, y),
      _shade(color, 0.15),
      1,
    );
  }
  // Spiny grabbing arms, folded in front
  for (final s in [-1.0, 1.0]) {
    _stroke(
      c,
      Path()
        ..moveTo(50 + s * 6, 46)
        ..quadraticBezierTo(50 + s * 20, 34, 50 + s * 12, 26),
      leg,
      3.2,
    );
    for (final (x, y) in const [(15.0, 36.0), (17.0, 31.0)]) {
      _stroke(
        c,
        Path()
          ..moveTo(50 + s * x, y)
          ..lineTo(50 + s * (x - 4), y - 1),
        leg,
        1,
      );
    }
  }
  _part(c, _oval(const Offset(50, 52), 30, 22), _tint(color, 0.12));
  for (final x in [44.5, 55.5]) {
    if (!pose.blink) {
      _part(
        c,
        _circ(Offset(x, 50), 4.6),
        const Color(0xFFF6EAD0),
        outline: false,
      );
    }
    _eye(c, Offset(x, 50.3), 3, pose, lid: _tint(color, 0.12), lidR: 4.6);
  }
  _stroke(c, _p('M47.5 57 Q50 59 52.5 57'), _shade(color, 0.6), 1);
  _cheeks(c, const [Offset(39, 56), Offset(61, 56)], 2.4);
}

void _cavecrab(Canvas c, Color color, _Pose pose) {
  final leg = _shade(color, 0.2);
  // Long, spindly legs for feeling around in the dark
  for (var i = 0; i < 4; i++) {
    for (final s in [-1.0, 1.0]) {
      _stroke(
        c,
        Path()
          ..moveTo(50 + s * 18, 64 + i * 3.0)
          ..lineTo(50 + s * 34, 56 + i * 4.0)
          ..lineTo(50 + s * 44, 78 + i * 4.0),
        leg,
        1.8,
      );
    }
  }
  // Two matching claws
  for (final s in [-1.0, 1.0]) {
    _stroke(
      c,
      Path()
        ..moveTo(50 + s * 16, 58)
        ..lineTo(50 + s * 26, 46),
      leg,
      3,
    );
    _part(c, _oval(Offset(50 + s * 28, 42), 12, 9), _tint(color, 0.1));
    _stroke(
      c,
      Path()
        ..moveTo(50 + s * 33, 40)
        ..lineTo(50 + s * 27, 42),
      leg,
      1,
    );
  }
  // Small eyes on short stalks
  for (final x in [44.0, 56.0]) {
    _stroke(
      c,
      Path()
        ..moveTo(x, 54)
        ..lineTo(x, 46),
      leg,
      2,
    );
    if (!pose.blink) {
      _part(
        c,
        _circ(Offset(x, 44), 3.6),
        const Color(0xFFFFF8E6),
        outline: false,
      );
    }
    _eye(c, Offset(x, 44.2), 2.4, pose, lid: color, lidR: 3.6);
  }
  _part(c, _oval(const Offset(50, 64), 40, 26), color);
  _part(
    c,
    _oval(const Offset(50, 59), 26, 8),
    _tint(color, 0.35),
    outline: false,
  );
  _stroke(c, _p('M46 68 Q50 71 54 68'), _shade(color, 0.55), 1.2);
  _cheeks(c, const [Offset(38, 66), Offset(62, 66)], 2.6);
}

void _stalactite(Canvas c, Color color, _Pose pose) {
  // Not alive, so no face: just rock, water, and sparkle.
  final rock = _shade(color, 0.25);
  _part(c, _p('M0 0 L100 0 L100 14 Q50 20 0 14Z'), rock);
  _part(c, _p('M34 14 Q50 18 66 14 L52 72 Q50 76 48 72Z'), color);
  _part(c, _p('M14 13 L26 14 L20 40Z'), _tint(color, 0.08));
  _part(c, _p('M74 15 L86 14 L81 34Z'), _tint(color, 0.08));
  // Shiny wet streaks
  final shine = Paint()
    ..color = Colors.white.withValues(alpha: 0.55)
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;
  c.drawLine(const Offset(44, 22), const Offset(48, 56), shine);
  c.drawLine(const Offset(19, 18), const Offset(20, 30), shine);
  // A drop of water, and the stalagmite it is building below
  _part(
    c,
    _p('M50 78 Q53 83 50 85 Q47 83 50 78Z'),
    const Color(0xFF9FE6F2),
    outline: false,
  );
  _part(c, _oval(const Offset(50, 94), 50, 8), const Color(0xFF6FC4C8));
  _part(c, _p('M40 94 L50 86 L60 94Z'), color);
  // A twinkle
  final tw = Paint()
    ..color = Colors.white
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;
  c.drawLine(const Offset(62, 40), const Offset(70, 40), tw);
  c.drawLine(const Offset(66, 36), const Offset(66, 44), tw);
}

// Partners ------------------------------------------------------------------
// Drawn facing forward on Tarsi's layout (head at (50, 49), eyes at x 38.5
// and 61.5, body at (50, 76)) so every outfit fits all three partners.

Path _hexagon(Offset center, double r) {
  final p = Path();
  for (var i = 0; i < 6; i++) {
    final a = i * pi / 3;
    final pt = center + Offset(cos(a) * r, sin(a) * r);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

void _partnerPawi(Canvas c, Color color, _Pose pose) {
  final skin = _tint(color, 0.15);
  final flipper = _shade(color, 0.08);
  for (final x in [35.0, 65.0]) {
    _part(c, _oval(Offset(x, 92), 16, 8), flipper);
  }
  // Front flippers swing from the shoulders when paddling.
  for (final (o, a, side) in const [
    (Offset(22, 76), -0.5, -1.0),
    (Offset(78, 76), 0.5, 1.0),
  ]) {
    final shoulder = Offset(50 + side * 19, 72);
    c.save();
    c.translate(shoulder.dx, shoulder.dy);
    c.rotate(-side * pose.limb * 0.45);
    c.translate(o.dx - shoulder.dx, o.dy - shoulder.dy);
    c.rotate(a);
    _part(c, _oval(Offset.zero, 26, 11), flipper);
    c.restore();
  }
  // Shell, with its plates
  _part(c, _oval(const Offset(50, 78), 54, 36), const Color(0xFF2F6E4A));
  _part(
    c,
    _oval(const Offset(50, 77), 45, 28),
    const Color(0xFF4F9A66),
    outline: false,
  );
  final plate = Paint()..color = _tint(color, 0.05);
  c.drawPath(_hexagon(const Offset(50, 79), 7), plate);
  c.drawPath(_hexagon(const Offset(36.5, 78), 5), plate);
  c.drawPath(_hexagon(const Offset(63.5, 78), 5), plate);
  _part(c, _oval(const Offset(50, 66), 22, 14), skin, outline: false);
  _part(c, _circ(const Offset(50, 48), 27), skin);
  final spot = Paint()..color = _shade(skin, 0.12);
  for (final (o, r) in const [
    (Offset(41, 27), 2.6),
    (Offset(56, 24.5), 2.0),
    (Offset(63, 30), 1.6),
  ]) {
    c.drawCircle(o, r, spot);
  }
  for (final x in [38.5, 61.5]) {
    if (!pose.blink) {
      _part(
        c,
        _circ(Offset(x, 47), 10.5),
        const Color(0xFFF6EAD0),
        light: 0.4,
        dark: 0.2,
      );
    }
    _eye(c, Offset(x, 47.5), 7, pose, lid: skin, lidR: 10.5);
  }
  final ink = _shade(color, 0.6);
  c.drawCircle(const Offset(48, 57), 0.9, Paint()..color = ink);
  c.drawCircle(const Offset(52, 57), 0.9, Paint()..color = ink);
  _stroke(
    c,
    Path()
      ..moveTo(44.5, 61)
      ..quadraticBezierTo(50, 65.5, 55.5, 61),
    ink,
    1.4,
  );
  _cheeks(c, const [Offset(29, 57), Offset(71, 57)], 4);
}

void _partnerHaribon(Canvas c, Color color, _Pose pose) {
  const cream = Color(0xFFEFE0BF);
  final wing = _shade(color, 0.2);
  // Shaggy crest behind the head, the Philippine eagle's famous "mane"
  _part(c, _star(const Offset(50, 42), 37, 23, 9), _tint(color, 0.2));
  _part(
    c,
    _star(const Offset(50, 42), 31, 21, 9, rotate: pi / 9),
    const Color(0xFFD9BD8A),
    outline: false,
  );
  // Wings lift out from the shoulders when flapping (limb 0 to 1).
  final lift = pose.limb.clamp(0.0, 1.0) * 1.5;
  for (final (o, a, side) in const [
    (Offset(27, 76), 0.3, -1.0),
    (Offset(73, 76), -0.3, 1.0),
  ]) {
    final shoulder = Offset(50 + side * 17, 62);
    c.save();
    c.translate(shoulder.dx, shoulder.dy);
    c.rotate(-side * lift);
    c.translate(o.dx - shoulder.dx, o.dy - shoulder.dy);
    c.rotate(a);
    _part(c, _oval(Offset.zero, 18, 36), wing);
    for (var i = 0; i < 3; i++) {
      _stroke(
        c,
        Path()
          ..moveTo(-5, -2 + i * 7.0)
          ..quadraticBezierTo(0, 2 + i * 7.0, 5, -2 + i * 7.0),
        _shade(color, 0.5),
        1,
      );
    }
    c.restore();
  }
  _part(c, _oval(const Offset(50, 76), 44, 36), color);
  _part(
    c,
    _oval(const Offset(50, 81), 26, 22),
    const Color(0xFFF1E2C4),
    outline: false,
  );
  const talon = Color(0xFFE8B83A);
  for (final x in [40.0, 60.0]) {
    for (final dx in [-3.0, 0.0, 3.0]) {
      _stroke(
        c,
        Path()
          ..moveTo(x, 89)
          ..lineTo(x + dx, 94),
        talon,
        2.2,
      );
    }
  }
  _part(c, _circ(const Offset(50, 49), 27), cream);
  for (final x in [38.5, 61.5]) {
    if (!pose.blink) {
      _part(
        c,
        _circ(Offset(x, 47), 10),
        const Color(0xFFFFF8E6),
        light: 0.4,
        dark: 0.2,
      );
    }
    _eye(
      c,
      Offset(x, 47.5),
      6.5,
      pose,
      lid: cream,
      iris: const Color(0xFF3E64A0),
      lidR: 10,
    );
  }
  // Big hooked blue-gray beak
  _part(
    c,
    Path()
      ..moveTo(43, 55)
      ..quadraticBezierTo(50, 50, 57, 55)
      ..lineTo(54.5, 63)
      ..quadraticBezierTo(51.5, 68.5, 47, 65.5)
      ..quadraticBezierTo(50, 64, 49.5, 60.5)
      ..lineTo(44.5, 59)
      ..close(),
    const Color(0xFF61779A),
  );
  _cheeks(c, const [Offset(29, 58), Offset(71, 58)], 3.5);
}
