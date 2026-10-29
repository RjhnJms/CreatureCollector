import 'dart:math';

import 'package:flutter/material.dart';

import '../data/partners.dart';
import '../state/game_state.dart';
import '../theme.dart';
import 'common.dart';
import 'partner_art.dart';

/// The partner, doing its own move each time [trigger] changes: Tarsi
/// leaps to a tree trunk and back, Pawi swims up to the surface for a
/// breath of air, and Haribon flaps its wings and hovers. Every move ends
/// back in the same spot.
class PartnerTapMove extends StatefulWidget {
  const PartnerTapMove({
    super.key,
    required this.trigger,
    required this.size,
    this.partnerId,
    this.surfaceRise = 90,
    this.leapX = 0,
    this.leapRise = 0,
    this.sleepy = false,
  });

  /// Napping: eyes closed, for a night animal on the daytime home screen.
  final bool sleepy;

  final Object? trigger;
  final double size;

  /// Shows this partner instead of the kid's own, for the picker.
  final String? partnerId;

  /// How far up Pawi swims so its eyes come out above the water.
  final double surfaceRise;

  /// How far right, and how far up, the tree trunk Tarsi leaps to is. With
  /// no trunk (0), Tarsi just hops.
  final double leapX;
  final double leapRise;

  @override
  State<PartnerTapMove> createState() => _PartnerTapMoveState();
}

class _PartnerTapMoveState extends State<PartnerTapMove>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  String get _id =>
      widget.partnerId ??
      GameScope.maybeOf(context)?.partnerId ??
      defaultPartner;

  static const _tarsiMs = 2400;
  static const _pawiMs = 2400;
  static const _haribonMs = 1600;

  @override
  void didUpdateWidget(PartnerTapMove old) {
    super.didUpdateWidget(old);
    if (old.trigger == widget.trigger) return;
    if (MediaQuery.of(context).disableAnimations) return;
    final ms = switch (_id) {
      'pawi' => _pawiMs,
      'haribon' => _haribonMs,
      _ => widget.leapX == 0 ? 0 : _tarsiMs,
    };
    if (ms == 0) return;
    _c.duration = Duration(milliseconds: ms);
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = _id;
    final leaps = id != 'pawi' && id != 'haribon' && widget.leapX != 0;
    if (id != 'pawi' && id != 'haribon' && !leaps) {
      return Hop(
        trigger: widget.trigger,
        child: PartnerArt(
          partnerId: widget.partnerId,
          size: widget.size,
          blinkNow: widget.sleepy,
        ),
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.isAnimating ? _c.value : 0.0;
        return switch (id) {
          'pawi' => _pawi(t),
          'haribon' => _haribon(t),
          _ => _tarsi(t),
        };
      },
    );
  }

  /// Trunk cling: crouch, leap across to the tree trunk, cling on and look
  /// left and right, then leap back. Real tarsiers cling to upright trunks
  /// and leap from tree to tree.
  Widget _tarsi(double t) {
    final s = widget.size, dx = widget.leapX, rise = widget.leapRise;
    final arc = rise + s * 0.2;
    final x = _keys(t, [
      (0, 0),
      (0.09, 0),
      (0.22, dx * 0.5),
      (0.34, dx),
      (0.70, dx),
      (0.80, dx * 0.5),
      (0.92, 0),
      (1, 0),
    ]);
    double up(double t) => _keys(t, [
      (0, 0),
      (0.09, -4),
      (0.22, arc),
      (0.34, rise - 4),
      (0.38, rise),
      (0.64, rise),
      (0.70, rise - 4),
      (0.80, arc),
      (0.92, -3),
      (1, 0),
    ]);
    final tilt = _keys(t, [
      (0, 0),
      (0.09, 0),
      (0.22, 0.31),
      (0.34, 0.1),
      (0.38, 0.07),
      (0.64, 0.07),
      (0.70, 0.03),
      (0.80, -0.31),
      (0.92, 0),
      (1, 0),
    ]);
    // Crouch before each leap and squash on each landing; stretch in the air.
    final squash =
        0.12 * _bump(t, 0, 0.16) +
        0.05 * _bump(t, 0.30, 0.40) +
        0.1 * _bump(t, 0.62, 0.72) +
        0.12 * _bump(t, 0.86, 1) -
        0.08 * _bump(t, 0.12, 0.30) -
        0.08 * _bump(t, 0.72, 0.88);
    final look = _keys(t, [
      (0, 0),
      (0.38, 0),
      (0.44, -1),
      (0.50, -1),
      (0.56, 1),
      (0.62, 1),
      (0.66, 0),
      (1, 0),
    ]);
    final flying = (t > 0.12 && t < 0.36) || (t > 0.70 && t < 0.92);
    final tail = flying ? sin(t * _tarsiMs / 500 * 2 * pi) : 0.0;
    return SizedBox.square(
      dimension: s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _body(up(t), squash, tail, dx: x, tilt: tilt, gaze: Offset(look, 0)),
          if (t > 0)
            Positioned.fill(
              child: CustomPaint(
                painter: _LeavesPainter(
                  t: t,
                  size: s,
                  at: Offset(s / 2 + dx, s * 0.25 - rise),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Up for air: paddle up, poke out at the surface with a "puff!", and
  /// glide back down.
  Widget _pawi(double t) {
    final s = widget.size, rise = widget.surfaceRise;
    double up(double t) => _keys(t, [
      (0, 0),
      (0.08, -4),
      (0.38, rise * 0.94),
      (0.44, rise),
      (0.62, rise * 0.96),
      (0.92, -2),
      (1, 0),
    ]);
    final atSurface = t > 0.40 && t < 0.62;
    final paddling = t > 0 && t < 0.95 && !atSurface;
    final limb = paddling ? sin(t * _pawiMs / 320 * 2 * pi) : 0.0;
    final squash = 0.06 * _bump(t, 0, 0.16) + 0.05 * _bump(t, 0.84, 1);
    final surfaceY = s * 0.505 - rise;
    final puff = _window(t, 0.42, 0.82);
    return SizedBox.square(
      dimension: s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _body(up(t), squash, limb),
          if (t > 0)
            Positioned.fill(
              child: CustomPaint(
                painter: _BubblesPainter(
                  t: t,
                  size: s,
                  upAt: up,
                  surfaceY: surfaceY,
                ),
              ),
            ),
          if (puff > 0)
            Positioned(
              left: s * 0.66,
              top: surfaceY - 38,
              child: Opacity(
                opacity: puff < 0.75 ? 1 : (1 - puff) / 0.25,
                child: Transform.scale(
                  scale: puff < 0.2 ? 0.3 + puff / 0.2 * 0.85 : 1,
                  child: Text(
                    'puff!',
                    style: display(18).copyWith(
                      shadows: const [
                        Shadow(color: Color(0x66000000), offset: Offset(2, 2)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Flap and hover: wings beat, lift off, hover, and land. A feather or
  /// two drifts down.
  Widget _haribon(double t) {
    final s = widget.size, k = s / 120;
    double up(double t) => _keys(t, [
      (0, 0),
      (0.10, -3 * k),
      (0.30, 58 * k),
      (0.48, 48 * k),
      (0.66, 58 * k),
      (0.90, -2 * k),
      (1, 0),
    ]);
    final flapping = t > 0.06 && t < 0.88;
    final limb = flapping ? (1 - cos(t * _haribonMs / 240 * 2 * pi)) / 2 : 0.0;
    final squash = 0.07 * _bump(t, 0, 0.18) + 0.06 * _bump(t, 0.82, 1);
    return SizedBox.square(
      dimension: s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _body(up(t), squash, limb),
          if (t > 0)
            Positioned.fill(
              child: CustomPaint(
                painter: _FeathersPainter(t: t, size: s, upAt: up),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(
    double up,
    double squash,
    double limb, {
    double dx = 0,
    double tilt = 0,
    Offset gaze = Offset.zero,
  }) {
    return Transform.translate(
      offset: Offset(dx, -up),
      child: Transform.rotate(
        angle: tilt,
        alignment: Alignment.bottomCenter,
        child: Transform.scale(
          scaleX: 1 + squash,
          scaleY: 1 - squash,
          alignment: Alignment.bottomCenter,
          child: PartnerArt(
            partnerId: widget.partnerId,
            size: widget.size,
            limb: limb,
            gaze: gaze,
            blinkNow: widget.sleepy,
          ),
        ),
      ),
    );
  }
}

/// Eases between (time, value) keyframes.
double _keys(double t, List<(double, double)> keys) {
  for (var i = 1; i < keys.length; i++) {
    final (t1, v1) = keys[i];
    if (t <= t1) {
      final (t0, v0) = keys[i - 1];
      final f = Curves.easeInOut.transform(((t - t0) / (t1 - t0)).clamp(0, 1));
      return v0 + (v1 - v0) * f;
    }
  }
  return keys.last.$2;
}

/// A smooth 0 → 1 → 0 bump between [a] and [b].
double _bump(double t, double a, double b) =>
    t > a && t < b ? sin((t - a) / (b - a) * pi) : 0;

/// How far through the window [a]..[b] we are, 0 outside it.
double _window(double t, double a, double b) =>
    t > a && t < b ? (t - a) / (b - a) : 0;

class _BubblesPainter extends CustomPainter {
  _BubblesPainter({
    required this.t,
    required this.size,
    required this.upAt,
    required this.surfaceY,
  });
  final double t;
  final double size;
  final double Function(double) upAt;
  final double surfaceY;

  @override
  void paint(Canvas c, Size _) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    // A trail of bubbles on the way up, rising from where Pawi was.
    for (var i = 0; i < 5; i++) {
      final start = 0.04 + i * 0.075;
      final age = (t - start) / 0.45;
      if (age <= 0 || age >= 1) continue;
      final y = size * 0.4 - upAt(start) - age * size * 0.7;
      if (y < surfaceY) continue;
      final x = size * (0.5 + (i.isEven ? -0.18 : 0.16)) + sin(age * 6 + i) * 4;
      ring.color = const Color(0xFFA0E1F0).withValues(alpha: 0.85 * (1 - age));
      c.drawCircle(Offset(x, y), 3.0 + (i % 3) * 2, ring);
    }
    // Ripples where Pawi's head comes out of the water.
    for (final start in const [0.40, 0.48]) {
      final age = (t - start) / 0.32;
      if (age <= 0 || age >= 1) continue;
      final w = size * 0.32 * (1 + age * 2.6);
      ring.color = const Color(0xFFC8F0FA).withValues(alpha: 0.9 * (1 - age));
      c.drawOval(
        Rect.fromCenter(
          center: Offset(size / 2, surfaceY),
          width: w,
          height: w * 0.22,
        ),
        ring,
      );
    }
  }

  @override
  bool shouldRepaint(_BubblesPainter old) => old.t != t;
}

class _FeathersPainter extends CustomPainter {
  _FeathersPainter({required this.t, required this.size, required this.upAt});
  final double t;
  final double size;
  final double Function(double) upAt;

  @override
  void paint(Canvas c, Size _) {
    for (var i = 0; i < 2; i++) {
      final start = 0.32 + i * 0.14;
      final age = (t - start) / 0.52;
      if (age <= 0 || age >= 1) continue;
      final x = size * (0.38 + i * 0.24) + sin(age * 2 * pi) * size * 0.08;
      final y = size * 0.62 - upAt(start) + age * size * 0.75;
      c.save();
      c.translate(x, y);
      c.rotate(sin(age * 2 * pi) * 0.7);
      c.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size * 0.1,
          height: size * 0.04,
        ),
        Paint()..color = const Color(0xFFD9BD8A).withValues(alpha: 1 - age),
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_FeathersPainter old) => old.t != t;
}

/// A few leaves shaken loose when Tarsi lands on the trunk.
class _LeavesPainter extends CustomPainter {
  _LeavesPainter({required this.t, required this.size, required this.at});
  final double t;
  final double size;
  final Offset at;

  @override
  void paint(Canvas c, Size _) {
    for (var i = 0; i < 3; i++) {
      final age = (t - 0.34 - i * 0.03) / 0.4;
      if (age <= 0 || age >= 1) continue;
      final x =
          at.dx + (i - 1) * size * 0.1 + sin(age * 2 * pi + i) * size * 0.06;
      final y = at.dy + (i % 2) * size * 0.05 + age * size * 0.55;
      c.save();
      c.translate(x, y);
      c.rotate(age * 3.5 + i);
      c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(size * 0.035, -size * 0.03, 0, -size * 0.07)
          ..quadraticBezierTo(-size * 0.035, -size * 0.03, 0, 0)
          ..close(),
        Paint()..color = AppColors.leaf2.withValues(alpha: 1 - age),
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_LeavesPainter old) => old.t != t;
}
