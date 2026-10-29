import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../services/sfx.dart';
import '../theme.dart';

bool _still(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

// ---------------------------------------------------------------------------
// Ambient motion
// ---------------------------------------------------------------------------

/// A looping 0..1 clock for slow background motion (drifting clouds,
/// swaying leaves, breathing creatures). It updates about [fps] times a
/// second instead of every frame, and painters listen to it directly, so
/// nothing gets rebuilt. Like any ticker, it pauses on hidden screens.
class AmbientClock extends ValueNotifier<double> {
  AmbientClock({
    required TickerProvider vsync,
    required this.period,
    this.fps = 30,
    double start = 0,
  }) : _start = start,
       super(start) {
    _ticker = vsync.createTicker(_tick);
  }

  final Duration period;
  final double fps;
  final double _start;
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  void start() {
    if (!_ticker.isActive) _ticker.start();
  }

  void _tick(Duration elapsed) {
    if (elapsed - _last < Duration(microseconds: (1e6 / fps).round() - 500)) {
      return;
    }
    _last = elapsed;
    value = (_start + elapsed.inMicroseconds / period.inMicroseconds) % 1.0;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Paper surfaces
// ---------------------------------------------------------------------------

/// A sheet of cut paper with slightly uneven corners and a hard drop shadow.
/// Text and icons inside default to ink.
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.color = AppColors.cream,
    this.tilt = 0,
    this.padding = const EdgeInsets.all(14),
    this.seed = 1,
    this.onTap,
  });

  final Widget child;
  final Color color;

  /// Rotation in degrees, for a hand-placed look.
  final double tilt;
  final EdgeInsets padding;

  /// Picks the corner wobble, so neighbors don't look identical.
  final int seed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = color.computeLuminance() < 0.35;
    Widget card = CustomPaint(
      painter: PaperShapePainter(color: color, seed: seed),
      child: Padding(
        padding: padding,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: dark ? AppColors.text : AppColors.ink),
          child: IconTheme.merge(
            data: IconThemeData(color: dark ? AppColors.text : AppColors.ink),
            child: child,
          ),
        ),
      ),
    );
    if (tilt != 0) card = Transform.rotate(angle: tilt * pi / 180, child: card);
    if (onTap != null) card = Squish(onTap: onTap, child: card);
    return card;
  }
}

class PaperShapePainter extends CustomPainter {
  PaperShapePainter({required this.color, this.seed = 1, this.shadow = true});
  final Color color;
  final int seed;
  final bool shadow;

  Path shape(Size s) {
    final r = Random(seed);
    double j() => r.nextDouble() * 3;
    return Path()
      ..moveTo(j(), j())
      ..lineTo(s.width - j(), j())
      ..lineTo(s.width - j(), s.height - j())
      ..lineTo(j(), s.height - j())
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = shape(size);
    if (shadow) {
      canvas.drawPath(
        p.shift(const Offset(3, 5)),
        Paint()..color = Colors.black.withValues(alpha: 0.35),
      );
    }
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(PaperShapePainter old) =>
      old.color != color || old.seed != seed || old.shadow != shadow;
}

/// Wraps content shown on a cream sheet (bottom sheets, dialogs) so text
/// defaults to ink.
class OnPaper extends StatelessWidget {
  const OnPaper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    style: const TextStyle(color: AppColors.ink),
    child: IconTheme.merge(
      data: const IconThemeData(color: AppColors.ink),
      child: child,
    ),
  );
}

/// Shrinks a little while pressed, then springs back. Plays a light tap.
class Squish extends StatefulWidget {
  const Squish({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Squish> createState() => _SquishState();
}

class _SquishState extends State<Squish> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                Sfx.tap.play();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.94 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutBack,
          child: widget.child,
        ),
      ),
    );
  }
}

/// The main call to action: an orange paper tag that squishes when pressed.
class PaperButton extends StatelessWidget {
  const PaperButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.orange,
    this.textColor = AppColors.cream,
    this.expand = true,
    this.size = 19,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final bool expand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = enabled ? textColor : AppColors.muted;
    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: fg, size: size + 3),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            style: display(size, color: fg),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
    return Squish(
      onTap: onPressed,
      child: CustomPaint(
        painter: PaperShapePainter(
          color: enabled ? color : AppColors.track,
          seed: label.length,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Center(widthFactor: expand ? null : 1, child: row),
          ),
        ),
      ),
    );
  }
}

class StarRow extends StatelessWidget {
  const StarRow(this.stars, {super.key, this.size = 16, this.max = 3});
  final int stars;
  final int max;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < stars
                ? AppColors.gold
                : AppColors.muted.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}

/// Small paper chip, like a label stuck on the scene.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.icon, this.iconColor});
  final String text;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PaperShapePainter(color: AppColors.cream, seed: text.length + 3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor ?? AppColors.orange),
              const SizedBox(width: 4),
            ],
            Text(text, style: display(14, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}

/// Orange progress bar on a navy track.
class Meter extends StatelessWidget {
  const Meter(
    this.value, {
    super.key,
    this.height = 8,
    this.track = AppColors.track,
  });
  final double value;
  final double height;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, 1)),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          backgroundColor: track,
          color: AppColors.orange,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Backgrounds
// ---------------------------------------------------------------------------

/// Starry navy background with a faint paper grain, shared by every screen.
class NightSky extends StatelessWidget {
  const NightSky({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(child: CustomPaint(painter: _StarsPainter())),
        child,
      ],
    );
  }
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.sky);
    final rnd = Random(7);
    final grain = Paint();
    for (var i = 0; i < (size.width * size.height / 140).round(); i++) {
      grain.color = (rnd.nextBool() ? Colors.white : Colors.black).withValues(
        alpha: 0.035,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          rnd.nextDouble() * size.width,
          rnd.nextDouble() * size.height,
          1.5,
          1.5,
        ),
        grain,
      );
    }
    final star = Paint();
    for (var i = 0; i < (size.width * size.height / 6000).round(); i++) {
      star.color = AppColors.text.withValues(
        alpha: 0.2 + rnd.nextDouble() * 0.5,
      );
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        rnd.nextDouble() * 1.2 + 0.4,
        star,
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Effects
// ---------------------------------------------------------------------------

/// A one-shot burst of paper confetti from the center of its box. Give it a
/// new key to play it again.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.count = 28, this.power = 1});
  final int count;
  final double power;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..forward();
  late final List<_Bit> _bits;

  static const _colors = [
    AppColors.red,
    AppColors.gold,
    AppColors.orange,
    AppColors.pink,
    AppColors.right,
    AppColors.blue,
    AppColors.cream,
  ];

  @override
  void initState() {
    super.initState();
    final r = Random();
    _bits = List.generate(widget.count, (i) {
      final a = r.nextDouble() * 2 * pi;
      final v = (90 + r.nextDouble() * 150) * widget.power;
      return _Bit(
        velocity: Offset(cos(a) * v, sin(a) * v - 140 * widget.power),
        spin: (r.nextDouble() - 0.5) * 14,
        color: _colors[i % _colors.length],
        size: Size(6 + r.nextDouble() * 5, 8 + r.nextDouble() * 6),
        triangle: i % 3 == 0,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_still(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_bits, _c.value),
        ),
      ),
    );
  }
}

class _Bit {
  _Bit({
    required this.velocity,
    required this.spin,
    required this.color,
    required this.size,
    required this.triangle,
  });
  final Offset velocity;
  final double spin;
  final Color color;
  final Size size;
  final bool triangle;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.bits, this.t);
  final List<_Bit> bits;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final secs = t * 1.3;
    final fade = (1 - t).clamp(0.0, 1.0);
    for (final b in bits) {
      final p = center + b.velocity * secs + Offset(0, 420 * secs * secs);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(b.spin * secs);
      final paint = Paint()..color = b.color.withValues(alpha: fade);
      final w = b.size.width, h = b.size.height;
      if (b.triangle) {
        canvas.drawPath(
          Path()
            ..moveTo(0, -h / 2)
            ..lineTo(w / 2, h / 2)
            ..lineTo(-w / 2, h / 2)
            ..close(),
          paint,
        );
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Shakes its child side to side whenever [trigger] changes.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});
  final Object? trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !_still(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final dx = sin(_c.value * pi * 5) * 9 * (1 - _c.value);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// Scales in with a springy bounce after [delay]. Also slides in from
/// [from] if given, like a paper tag dropping into place.
class PopIn extends StatefulWidget {
  const PopIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.from = Offset.zero,
    this.startScale = 0.3,
    this.startTilt = 0,
  });

  final Widget child;
  final Duration delay;
  final Offset from;
  final double startScale;

  /// Starting rotation in degrees.
  final double startTilt;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_still(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.elasticOut.transform(_c.value);
        final fade = Curves.easeOut.transform((_c.value * 3).clamp(0, 1));
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: widget.from * (1 - t),
            child: Transform.rotate(
              angle: widget.startTilt * pi / 180 * (1 - t),
              child: Transform.scale(
                scale: widget.startScale + (1 - widget.startScale) * t,
                child: child,
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Slowly turning sunburst, used behind catches and rewards.
class SpinningRays extends StatefulWidget {
  const SpinningRays({super.key, this.color = AppColors.gold});
  final Color color;

  @override
  State<SpinningRays> createState() => _SpinningRaysState();
}

class _SpinningRaysState extends State<SpinningRays>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _RaysPainter(_still(context) ? 0 : _c.value, widget.color),
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.longestSide * 0.7;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(t * 2 * pi);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    for (var i = 0; i < 18; i++) {
      final a = i * 2 * pi / 18;
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(cos(a - 0.08) * r, sin(a - 0.08) * r)
          ..lineTo(cos(a + 0.08) * r, sin(a + 0.08) * r)
          ..close(),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.t != t;
}

/// Makes its child hop with a squash and stretch when [trigger] changes.
class Hop extends StatefulWidget {
  const Hop({super.key, required this.trigger, required this.child});
  final Object? trigger;
  final Widget child;

  @override
  State<Hop> createState() => _HopState();
}

class _HopState extends State<Hop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didUpdateWidget(Hop old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !_still(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = _c.value;
        if (t == 0 || t == 1) return child!;
        final up = sin(t * pi);
        final squash = t < 0.15
            ? sin(t / 0.15 * pi) * 0.12
            : t > 0.85
            ? sin((t - 0.85) / 0.15 * pi) * 0.08
            : -up * 0.06;
        return Transform.translate(
          offset: Offset(0, -up * 36),
          child: Transform.scale(
            scaleX: 1 + squash,
            scaleY: 1 - squash,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
