import 'dart:async';
import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models.dart';
import '../../services/sfx.dart';
import '../../state/game_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/creature_art.dart';
import '../../widgets/scene.dart';

/// Kids search a paper forest (or sea) for the hidden creature. Night
/// creatures hide in the dark and are found with a flashlight; day creatures
/// hide behind a sunny haze and are found with a magnifying glass. Holding
/// the light or lens on it for a moment counts as finding it.
class SearchView extends StatefulWidget {
  const SearchView({super.key, required this.creature, required this.onFound});

  final Creature creature;
  final VoidCallback onFound;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView>
    with SingleTickerProviderStateMixin {
  static const beamRadius = 95.0;
  static const lensRadius = 64.0;
  static const lensZoom = 1.35;
  static const artSize = 110.0;
  static const holdToFind = Duration(milliseconds: 650);
  static const hintAfter = Duration(seconds: 12);

  /// Where the creature hides: one of the perches, at a random spot along it.
  late final Offset _spot;

  /// The scene's time. Creatures out day and night get a random one.
  late final ActiveTime _time;
  Offset? _light;
  Size _scene = Size.zero;
  Duration _held = Duration.zero;
  Duration _elapsed = Duration.zero;
  bool _found = false;
  Timer? _timer;

  bool get _magnifier => _time == ActiveTime.day;

  // First-time tutorial: the light (or lens) moves on its own with a hand
  // on it until the kid touches the scene. Shown once per tool.
  bool? _demo;
  late final AnimationController _demoC =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2600),
      )..addListener(() {
        if (_demo == true) setState(() {});
      });

  String get _tipId => 'search_${_magnifier ? 'magnifier' : 'flashlight'}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_demo != null) return;
    final game = GameScope.maybeOf(context);
    _demo = game != null && !game.hasSeenTip(_tipId);
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_demo! && !still) _demoC.repeat();
  }

  /// Where the demo light is: sweeping back and forth near its start, on
  /// the far side from the creature.
  Offset _demoLight(Offset start, Size size) {
    final t = _demoC.value * 2 * pi;
    return Offset(
      (start.dx + sin(t) * size.width * 0.2).clamp(40, size.width - 40),
      // Below the tip card, and clear of the bottom so the hand under it
      // stays on screen.
      (start.dy + sin(t * 2) * 12).clamp(140, size.height - 84),
    );
  }

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    final perch = Perches.search[rnd.nextInt(Perches.search.length)];
    _spot = Offset(0.22 + rnd.nextDouble() * 0.56, perch);
    final t = widget.creature.time;
    // Caves are dark inside at any hour, so it's always the flashlight.
    _time = widget.creature.habitatId == 'cave'
        ? ActiveTime.night
        : t == ActiveTime.dayAndNight
        ? (rnd.nextBool() ? ActiveTime.day : ActiveTime.night)
        : t;
    _timer = Timer.periodic(const Duration(milliseconds: 100), _tick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _demoC.dispose();
    super.dispose();
  }

  /// Center of the creature's art. It stands on the branch, so its middle
  /// sits about half its height above the perch line.
  Offset get _creatureCenter => Offset(
    _spot.dx * _scene.width,
    _spot.dy * _scene.height - artSize * 0.42,
  );

  void _tick(Timer t) {
    if (_found || _scene == Size.zero) return;
    const step = Duration(milliseconds: 100);
    final light = _light;
    final onTarget =
        light != null && (light - _creatureCenter).distance < beamRadius * 0.6;
    final hintBefore = _elapsed >= hintAfter;
    final heldBefore = _held;
    _elapsed += step;
    _held = onTarget ? _held + step : Duration.zero;
    if (_held >= holdToFind) {
      _found = true;
      Sfx.found.play();
      HapticFeedback.mediumImpact();
    }
    // Only rebuild when something on screen changes: the "Hold still"
    // label, finding the creature, or the hint sparkle appearing.
    if (_found ||
        _held != heldBefore ||
        (_elapsed >= hintAfter) != hintBefore) {
      setState(() {});
    }
  }

  void _move(Offset p) {
    if (_found) return;
    if (_demo == true) {
      _demo = false;
      _demoC.stop();
      GameScope.maybeOf(context)?.markTipSeen(_tipId);
    }
    final wasNear =
        _light != null &&
        (_light! - _creatureCenter).distance < beamRadius * 1.4;
    final isNear = (p - _creatureCenter).distance < beamRadius * 1.4;
    if (isNear && !wasNear) HapticFeedback.selectionClick();
    setState(() => _light = p);
  }

  String get _hint {
    final c = widget.creature;
    final tool = _magnifier ? 'magnifying glass' : 'flashlight';
    if (c.time == ActiveTime.dayAndNight && c.alive) {
      return "It's out day and night, and right now it's "
          "${_magnifier ? 'daytime' : 'night'}! Drag the $tool to search.";
    }
    final place = switch (c.habitatId) {
      'ocean' => 'water',
      'terraces' => 'fields',
      'mangrove' => 'roots',
      'cave' => 'cave',
      _ => 'trees',
    };
    return 'Drag the $tool around to search the $place.';
  }

  /// The scene with the creature in it. Drawn twice by day: once normally
  /// and once magnified inside the lens.
  Widget _sceneWith(Offset light, Offset center) {
    final c = widget.creature;
    return Stack(
      children: [
        Positioned.fill(
          child: PaperScene(
            habitatId: c.habitatId,
            time: _time,
            layer: SceneLayer.back,
            perches: c.habitatId == 'ocean' ? const [] : Perches.search,
          ),
        ),
        Positioned(
          left: center.dx - artSize / 2,
          top: center.dy - artSize / 2,
          child: Hop(
            trigger: _found,
            child: CreatureArt(
              c,
              size: artSize,
              animate: true,
              // Its eyes follow the light or lens, and it blinks when the
              // light shines right in its face.
              gaze: _gazeToward(light, center),
              blinkNow: !_found && (light - center).distance < 28,
            ),
          ),
        ),
        Positioned.fill(
          child: PaperScene(
            habitatId: c.habitatId,
            time: _time,
            layer: SceneLayer.front,
            hanging: c.habitatId != 'ocean',
          ),
        ),
      ],
    );
  }

  /// What hides the scene: darkness and a flashlight at night, a sunny haze
  /// and a magnifying glass by day.
  Widget _cover(Offset light, Offset center) {
    final hidden = TimeLook.of(_time).darkness;
    if (!_magnifier) {
      return Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DarknessPainter(light: light, darkness: hidden),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _FlashlightPainter(light: light)),
          ),
        ],
      );
    }
    final zoom = Matrix4.translationValues(light.dx, light.dy, 0)
      ..multiply(Matrix4.diagonal3Values(lensZoom, lensZoom, 1))
      ..multiply(Matrix4.translationValues(-light.dx, -light.dy, 0));
    return Stack(
      children: [
        // Frosted paper: the sunny scene shows through as soft color, but
        // the creature blurs into the background until the lens finds it.
        Positioned.fill(
          child: ClipPath(
            clipper: _HazeClip(light),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: CustomPaint(
                painter: _HazePainter(light: light, haze: hidden),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ClipPath(
            clipper: _LensClip(light),
            child: Transform(transform: zoom, child: _sceneWith(light, center)),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _LensPainter(light: light)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.creature;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              c.alive
                  ? Pill(c.time.label, icon: timeIcon(c.time))
                  : const Pill('Not living', icon: Icons.landscape_rounded),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _found ? 'You found it!' : 'Something is hiding…',
                  key: ValueKey(_found),
                  style: display(27),
                ),
              ),
              Text(
                _found ? c.name : _hint,
                style: const TextStyle(color: AppColors.muted, fontSize: 16),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(color: Color(0x59000000), offset: Offset(3, 5)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LayoutBuilder(
                  builder: (context, box) {
                    _scene = box.biggest;
                    // Start the light on the far side from the creature so
                    // it always takes a little searching.
                    final start = Offset(
                      box.maxWidth * (_spot.dx > 0.5 ? 0.18 : 0.82),
                      box.maxHeight * (_spot.dy > 0.6 ? 0.2 : 0.88),
                    );
                    final demo = _demo == true && !_found;
                    final light = demo
                        ? _demoLight(start, box.biggest)
                        : _light ?? start;
                    final center = _creatureCenter;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (d) => _move(d.localPosition),
                      onPanUpdate: (d) => _move(d.localPosition),
                      child: Stack(
                        children: [
                          Positioned.fill(child: _sceneWith(light, center)),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedOpacity(
                                opacity: _found ? 0 : 1,
                                duration: const Duration(milliseconds: 700),
                                child: _cover(light, center),
                              ),
                            ),
                          ),
                          if (_found)
                            Positioned(
                              left: center.dx - 100,
                              top: center.dy - 100,
                              width: 200,
                              height: 200,
                              child: const ConfettiBurst(count: 24, power: 0.8),
                            ),
                          if (!_found && _elapsed >= hintAfter)
                            Positioned(
                              left: center.dx - 14,
                              top: center.dy - artSize / 2 - 30,
                              child: const _Sparkle(),
                            ),
                          if (demo) ...[
                            Positioned(
                              // Fingertip on the light
                              left: light.dx - 22,
                              top: light.dy - 4,
                              child: const IgnorePointer(
                                child: Icon(
                                  Icons.touch_app_rounded,
                                  size: 52,
                                  color: AppColors.cream,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x99000000),
                                      offset: Offset(2, 3),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 12,
                              right: 12,
                              top: 12,
                              child: IgnorePointer(
                                child: PopIn(
                                  child: PaperCard(
                                    seed: 41,
                                    tilt: -0.8,
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      10,
                                      12,
                                      10,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _magnifier
                                              ? Icons.search_rounded
                                              : Icons.flashlight_on_rounded,
                                          color: AppColors.orange,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _magnifier
                                                ? 'Drag your finger to move '
                                                      'the magnifying glass. '
                                                      'Hold it over the '
                                                      'creature to find it!'
                                                : 'Drag your finger to move '
                                                      'the flashlight. Hold '
                                                      'the light on the '
                                                      'creature to find it!',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (!_found && _held > Duration.zero)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 16,
                              child: Center(
                                child: Pill(
                                  'Hold still…',
                                  icon: _magnifier
                                      ? Icons.search_rounded
                                      : Icons.flashlight_on_rounded,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, a) =>
                ScaleTransition(scale: a, child: child),
            child: _found
                ? PaperButton(
                    key: const ValueKey('go'),
                    label: 'Answer its questions',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: widget.onFound,
                  )
                : const SizedBox(height: 54, key: ValueKey('wait')),
          ),
        ),
      ],
    );
  }
}

/// Direction from [from] to [to], scaled so far-off lights give a full look
/// and nearby ones a smaller glance.
Offset _gazeToward(Offset to, Offset from) {
  final d = to - from;
  final dist = d.distance;
  if (dist < 1) return Offset.zero;
  return d / dist * min(1.0, dist / 70);
}

/// Darkness everywhere except a soft warm circle around the flashlight.
class _DarknessPainter extends CustomPainter {
  _DarknessPainter({required this.light, required this.darkness});
  final Offset light;
  final double darkness;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = const Color(0xFF080A1E).withValues(alpha: darkness);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader =
            RadialGradient(
              colors: [Colors.transparent, Colors.transparent, dark],
              stops: const [0, 0.55, 1],
            ).createShader(
              Rect.fromCircle(
                center: light,
                radius: _SearchViewState.beamRadius,
              ),
            ),
    );
    canvas.drawCircle(
      light,
      _SearchViewState.beamRadius * 0.7,
      Paint()..color = const Color(0xFFFFC878).withValues(alpha: 0.1),
    );
  }

  @override
  bool shouldRepaint(_DarknessPainter old) =>
      old.light != light || old.darkness != darkness;
}

/// A paper flashlight held below the beam, pointing at it, with a faint
/// cone of light between them.
class _FlashlightPainter extends CustomPainter {
  _FlashlightPainter({required this.light});
  final Offset light;

  @override
  void paint(Canvas canvas, Size size) {
    // The flashlight sits toward the bottom middle, like it's in your hand.
    final hand = Offset(size.width / 2, size.height + 60);
    var dir = hand - light;
    if (dir.distance < 1) dir = const Offset(0, 1);
    dir = dir / dir.distance;
    final head = light + dir * 118;
    final side = Offset(-dir.dy, dir.dx);
    const r = _SearchViewState.beamRadius;

    // Cone from the lens to the lit circle
    final cone = Path()
      ..moveTo(head.dx + side.dx * 11, head.dy + side.dy * 11)
      ..lineTo(light.dx + side.dx * r * 0.5, light.dy + side.dy * r * 0.5)
      ..lineTo(light.dx - side.dx * r * 0.5, light.dy - side.dy * r * 0.5)
      ..lineTo(head.dx - side.dx * 11, head.dy - side.dy * 11)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(
            (head.dx / size.width) * 2 - 1,
            (head.dy / size.height) * 2 - 1,
          ),
          end: Alignment(
            (light.dx / size.width) * 2 - 1,
            (light.dy / size.height) * 2 - 1,
          ),
          colors: [
            const Color(0xFFFFE6A8).withValues(alpha: 0.28),
            const Color(0xFFFFE6A8).withValues(alpha: 0.04),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.save();
    canvas.translate(head.dx, head.dy);
    // Local +y points away from the beam, down the handle.
    canvas.rotate(atan2(dir.dy, dir.dx) - pi / 2);
    void part(RRect r, Color color) {
      canvas.drawRRect(
        r.shift(const Offset(3, 4)),
        Paint()..color = Colors.black.withValues(alpha: 0.35),
      );
      canvas.drawRRect(r, Paint()..color = color);
    }

    // Body, then the wider head with its glowing lens
    part(
      RRect.fromLTRBR(-10, 8, 10, 60, const Radius.circular(5)),
      const Color(0xFFE5704F),
    );
    canvas.drawRect(
      const Rect.fromLTRB(-10, 40, 10, 46),
      Paint()..color = const Color(0xFFB8502F),
    );
    part(
      RRect.fromLTRBR(-14, 0, 14, 14, const Radius.circular(4)),
      AppColors.cream,
    );
    canvas.drawCircle(
      const Offset(0, 24),
      3.5,
      Paint()..color = const Color(0xFFFFE6A8),
    );
    canvas.drawOval(
      const Rect.fromLTRB(-11, -3, 11, 4),
      Paint()..color = const Color(0xFFFFF3C4),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FlashlightPainter old) => old.light != light;
}

/// A sunny cream haze, like tracing paper, over everything but the lens.
class _HazePainter extends CustomPainter {
  _HazePainter({required this.light, required this.haze});
  final Offset light;
  final double haze;

  @override
  void paint(Canvas canvas, Size size) {
    final cover = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(
        Rect.fromCircle(center: light, radius: _SearchViewState.lensRadius),
      );
    canvas.drawPath(
      cover,
      Paint()..color = const Color(0xFFF8EED6).withValues(alpha: haze),
    );
  }

  @override
  bool shouldRepaint(_HazePainter old) =>
      old.light != light || old.haze != haze;
}

/// Everywhere except the lens.
class _HazeClip extends CustomClipper<Path> {
  _HazeClip(this.light);
  final Offset light;

  @override
  Path getClip(Size size) => Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Offset.zero & size)
    ..addOval(
      Rect.fromCircle(center: light, radius: _SearchViewState.lensRadius),
    );

  @override
  bool shouldReclip(_HazeClip old) => old.light != light;
}

class _LensClip extends CustomClipper<Path> {
  _LensClip(this.light);
  final Offset light;

  @override
  Path getClip(Size size) => Path()
    ..addOval(
      Rect.fromCircle(center: light, radius: _SearchViewState.lensRadius),
    );

  @override
  bool shouldReclip(_LensClip old) => old.light != light;
}

/// The magnifying glass: a wooden rim with a glint on the glass and a handle
/// reaching down to the right.
class _LensPainter extends CustomPainter {
  _LensPainter({required this.light});
  final Offset light;

  @override
  void paint(Canvas canvas, Size size) {
    const r = _SearchViewState.lensRadius;
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.3);

    // Handle, angled down and to the right
    canvas.save();
    canvas.translate(light.dx, light.dy);
    canvas.rotate(-pi / 4);
    final handle = RRect.fromLTRBR(
      -7,
      r + 2,
      7,
      r + 58,
      const Radius.circular(7),
    );
    final collar = RRect.fromLTRBR(
      -9,
      r - 2,
      9,
      r + 12,
      const Radius.circular(3),
    );
    canvas.drawRRect(handle.shift(const Offset(3, 4)), shadow);
    canvas.drawRRect(handle, Paint()..color = const Color(0xFF6B4226));
    canvas.drawRRect(
      RRect.fromLTRBR(-3, r + 16, -1, r + 52, const Radius.circular(1)),
      Paint()..color = const Color(0xFF8A5A3A),
    );
    canvas.drawRRect(collar, Paint()..color = const Color(0xFFC8963E));
    canvas.restore();

    // Rim
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(light + const Offset(3, 4), r, rim..color = shadow.color);
    canvas.drawCircle(light, r, rim..color = const Color(0xFF8A5A3A));
    canvas.drawCircle(
      light,
      r - 3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFC89A6A),
    );

    // A glint on the glass
    final glint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5
      ..color = Colors.white.withValues(alpha: 0.55);
    canvas.drawArc(
      Rect.fromCircle(center: light, radius: r - 12),
      pi * 1.08,
      pi * 0.32,
      false,
      glint,
    );
    canvas.drawCircle(
      light +
          Offset(cos(pi * 1.5) * (r - 12), sin(pi * 1.5) * (r - 12)) +
          const Offset(8, 0),
      2.5,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_LensPainter old) => old.light != light;
}

class _Sparkle extends StatefulWidget {
  const _Sparkle();

  @override
  State<_Sparkle> createState() => _SparkleState();
}

class _SparkleState extends State<_Sparkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
      child: const Icon(Icons.auto_awesome, color: AppColors.gold, size: 28),
    );
  }
}
