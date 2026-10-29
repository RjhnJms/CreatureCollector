import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/rewards.dart';
import '../theme.dart';
import 'common.dart';
import 'scene.dart';
import 'partner_art.dart';

/// The developers, credited on the startup screen.
const developers = ['Rejohn James Ballenas', 'Jay Rhanz Mabaquiao'];

/// Startup screen. The developer credits pop out first (each developer's
/// parol drops in and their name tag pops on), then the title, Tarsi, and a
/// string of parols fade in and light up one by one while the app loads.
class StartupLoader extends StatefulWidget {
  const StartupLoader({super.key, this.onFinished});

  /// Called once the credits have popped out and every parol is lit, so
  /// the app never cuts the intro short on a slow first frame.
  final VoidCallback? onFinished;

  @override
  State<StartupLoader> createState() => _StartupLoaderState();
}

class _StartupLoaderState extends State<StartupLoader>
    with TickerProviderStateMixin {
  static const _intro = Duration(milliseconds: 1900);
  static const _lightUp = Duration(milliseconds: 1500);

  /// Drives the parols lighting up, after the intro.
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: _lightUp,
  );

  /// Ambient sway and the loading dots.
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(_intro, () async {
      if (!mounted) return;
      await _progress.forward();
      // Let the last parol glow for a moment before moving on.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (mounted) widget.onFinished?.call();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _progress.dispose();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = min(box.maxWidth, 420.0);
        return Center(
          child: SizedBox(
            width: w,
            child: Column(
              children: [
                const SizedBox(height: 28),
                _FadeIn(
                  delay: const Duration(milliseconds: 1500),
                  child: Column(
                    children: [
                      Text(
                        'Creature Collector',
                        textAlign: TextAlign.center,
                        style: display(32).copyWith(
                          shadows: const [
                            Shadow(
                              color: Color(0x88000000),
                              offset: Offset(2, 3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'A Night Ranger adventure',
                        style: TextStyle(color: AppColors.muted, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _FadeIn(
                    delay: const Duration(milliseconds: 1500),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_progress, _idle]),
                      builder: (context, _) => _ParolString(
                        progress: _progress.value,
                        sway: _idle.value,
                      ),
                    ),
                  ),
                ),
                _FadeIn(
                  delay: const Duration(milliseconds: 1500),
                  child: AnimatedBuilder(
                    animation: _idle,
                    builder: (_, _) {
                      // One, two, three dots, cycling every 1.2 seconds.
                      final dots = 1 + (_idle.value * 3).floor() % 3;
                      return Text(
                        'Loading${'.' * dots}${' ' * (3 - dots)}',
                        style: display(20),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 26),
                const _Credits(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Five parols on a string over Tarsi's branch. [progress] 0..1 lights them
/// in turn, and Tarsi looks toward the next one.
class _ParolString extends StatelessWidget {
  const _ParolString({required this.progress, required this.sway});
  final double progress;
  final double sway;

  @override
  Widget build(BuildContext context) {
    final lit = (progress * 5 + 0.0001).floor().clamp(0, 5);
    // Look toward the next parol to light up, a little up and to the side.
    final look = (min(lit, 4) - 2) / 2;
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _StringPainter(lit: lit, sway: sway),
              ),
            ),
            Positioned(
              left: box.maxWidth / 2 - 65,
              top: h * 0.78 - 125,
              child: PartnerArt(size: 130, gaze: Offset(look * 0.8, -0.7)),
            ),
          ],
        );
      },
    );
  }
}

class _StringPainter extends CustomPainter {
  _StringPainter({required this.lit, required this.sway});
  final int lit;
  final double sway;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    Offset on(double t) {
      // The string's curve: a quadratic dipping in the middle.
      final p0 = Offset(-10, h * 0.1),
          p1 = Offset(w / 2, h * 0.32),
          p2 = Offset(w + 10, h * 0.08);
      return p0 * ((1 - t) * (1 - t)) + p1 * (2 * (1 - t) * t) + p2 * (t * t);
    }

    final string = Path()..moveTo(on(0).dx, on(0).dy);
    for (var t = 0.05; t <= 1.0001; t += 0.05) {
      string.lineTo(on(t).dx, on(t).dy);
    }
    canvas.drawPath(
      string,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF3A2A1C),
    );

    final style = parolStyleOf(defaultParol);
    const colors = [
      AppColors.red,
      AppColors.gold,
      AppColors.orange,
      AppColors.pink,
      AppColors.gold,
    ];
    for (var i = 0; i < 5; i++) {
      final swing = sin(sway * 2 * pi + i * 1.3) * 0.05;
      drawParol(
        canvas,
        on(0.15 + i * 0.175),
        15,
        colors[i],
        swing: swing,
        lit: i < lit,
        style: style,
      );
    }

    canvas.drawPath(
      Path()
        ..moveTo(-10, h * 0.78)
        ..quadraticBezierTo(w / 2, h * 0.72, w + 10, h * 0.8),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF7A4E2A),
    );
  }

  @override
  bool shouldRepaint(_StringPainter old) => old.lit != lit || old.sway != sway;
}

/// "Developed by" with a parol and name tag for each developer. They pop
/// out first, before anything else on the screen.
class _Credits extends StatelessWidget {
  const _Credits();

  @override
  Widget build(BuildContext context) {
    const parolColors = [AppColors.red, AppColors.gold];
    return Semantics(
      label: 'Developed by ${developers.join(' and ')}',
      child: ExcludeSemantics(
        child: Column(
          children: [
            const _FadeIn(
              delay: Duration(milliseconds: 100),
              duration: Duration(milliseconds: 350),
              child: Text(
                'DEVELOPED BY',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < developers.length; i++) ...[
                  if (i > 0) const SizedBox(width: 16),
                  SizedBox(
                    width: 132,
                    child: PopIn(
                      delay: Duration(milliseconds: 250 + i * 250),
                      from: const Offset(0, -70),
                      startScale: 0.4,
                      startTilt: -12,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 48,
                            height: 60,
                            child: _SwayingParol(
                              color: parolColors[i],
                              phase: i * 1.4,
                            ),
                          ),
                          PopIn(
                            delay: Duration(milliseconds: 650 + i * 250),
                            startScale: 0.2,
                            startTilt: -14,
                            child: PaperCard(
                              tilt: i.isEven ? -2 : 2,
                              seed: i + 40,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Text(
                                developers[i],
                                textAlign: TextAlign.center,
                                style: display(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwayingParol extends StatefulWidget {
  const _SwayingParol({required this.color, required this.phase});
  final Color color;
  final double phase;

  @override
  State<_SwayingParol> createState() => _SwayingParolState();
}

class _SwayingParolState extends State<_SwayingParol>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        painter: _OneParolPainter(
          widget.color,
          still ? 0 : sin(_c.value * 2 * pi + widget.phase) * 0.1,
        ),
      ),
    );
  }
}

class _OneParolPainter extends CustomPainter {
  _OneParolPainter(this.color, this.swing);
  final Color color;
  final double swing;

  @override
  void paint(Canvas canvas, Size size) {
    drawParol(
      canvas,
      Offset(size.width / 2, 0),
      15,
      color,
      swing: swing,
      style: parolStyleOf(defaultParol),
    );
  }

  @override
  bool shouldRepaint(_OneParolPainter old) =>
      old.swing != swing || old.color != color;
}

/// Fades and slides its child in after [delay].
class _FadeIn extends StatefulWidget {
  const _FadeIn({
    required this.delay,
    required this.child,
    this.duration = const Duration(milliseconds: 700),
  });
  final Duration delay;
  final Duration duration;
  final Widget child;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final v = Curves.easeOut.transform(_c.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - v)),
            child: child,
          ),
        );
      },
    );
  }
}
