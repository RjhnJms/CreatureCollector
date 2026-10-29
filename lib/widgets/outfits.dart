import 'dart:math';

import 'package:flutter/material.dart';

/// Draws outfit items on Tarsi, on the same 100 x 100 grid as its body:
/// head at (50, 49) radius 28, eyes at (38.5, 47) and (61.5, 47), ears at
/// x 25 and 75, body centered at (50, 76).
typedef OutfitPainter = void Function(Canvas c);

final _shadow = Paint()
  ..color = Colors.black.withValues(alpha: 0.3)
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.1);

void _piece(Canvas c, Path p, Color color) {
  c.drawPath(p.shift(const Offset(0.5, 1.6)), _shadow);
  c.drawPath(p, Paint()..color = color);
}

void _line(Canvas c, Path p, Color color, double width) {
  c.drawPath(
    p,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = color,
  );
}

final Map<String, OutfitPainter> outfitPainters = {
  'salakot': (c) =>
      _salakot(c, const Color(0xFFC99A52), const Color(0xFF9C7238)),
  'golden_salakot': (c) =>
      _salakot(c, const Color(0xFFF2C14E), const Color(0xFFC9932A)),
  'flower_crown': _flowerCrown,
  'glasses': (c) => _glasses(c, star: false),
  'star_glasses': (c) => _glasses(c, star: true),
  'scarf': _scarf,
  'bowtie': _bowtie,
  'barong': _barong,
  'moon_cape': _moonCape,
};

void _salakot(Canvas c, Color color, Color dark) {
  final brim = Path()
    ..moveTo(14, 26)
    ..quadraticBezierTo(50, 34, 86, 26)
    ..quadraticBezierTo(50, 20, 14, 26)
    ..close();
  final cone = Path()
    ..moveTo(20, 26)
    ..quadraticBezierTo(42, 6, 50, 2)
    ..quadraticBezierTo(58, 6, 80, 26)
    ..quadraticBezierTo(50, 32, 20, 26)
    ..close();
  _piece(c, brim, dark);
  _piece(c, cone, color);
  // Woven rings
  for (final y in [10.0, 16.0, 22.0]) {
    final half = (y - 2) * 1.25;
    _line(
      c,
      Path()
        ..moveTo(50 - half, y + 2)
        ..quadraticBezierTo(50, y + 5, 50 + half, y + 2),
      dark,
      0.8,
    );
  }
  c.drawCircle(const Offset(50, 3), 2, Paint()..color = dark);
}

void _flowerCrown(Canvas c) {
  _line(
    c,
    Path()
      ..moveTo(24, 30)
      ..quadraticBezierTo(50, 14, 76, 30),
    const Color(0xFF3A9563),
    2.4,
  );
  const flowers = [
    (Offset(28, 26), Color(0xFFFFFFFF)),
    (Offset(39, 20), Color(0xFFE5574A)),
    (Offset(50, 18), Color(0xFFFFFFFF)),
    (Offset(61, 20), Color(0xFFF2B23C)),
    (Offset(72, 26), Color(0xFFFFFFFF)),
  ];
  for (final (o, color) in flowers) {
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * pi / 5;
      _piece(
        c,
        Path()..addOval(
          Rect.fromCircle(
            center: o + Offset(cos(a), sin(a)) * 2.8,
            radius: 2.6,
          ),
        ),
        color,
      );
    }
    c.drawCircle(o, 1.8, Paint()..color = const Color(0xFFF2B23C));
  }
  _piece(
    c,
    Path()
      ..moveTo(45, 22)
      ..quadraticBezierTo(41, 14, 46, 12)
      ..quadraticBezierTo(48, 17, 45, 22)
      ..close(),
    const Color(0xFF5BB174),
  );
}

void _glasses(Canvas c, {required bool star}) {
  const frame = Color(0xFF3B2A14);
  for (final x in [38.5, 61.5]) {
    final o = Offset(x, 47);
    if (star) {
      final p = Path();
      for (var i = 0; i < 10; i++) {
        final r = i.isEven ? 15.0 : 9.0;
        final a = -pi / 2 + i * pi / 5;
        final pt = o + Offset(cos(a) * r, sin(a) * r);
        i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      p.close();
      c.drawPath(p, Paint()..color = const Color(0x40FFE36B));
      _line(c, p, const Color(0xFFF2B23C), 2);
    } else {
      c.drawCircle(o, 13.5, Paint()..color = const Color(0x2A9FD3E6));
      c.drawCircle(
        o,
        13.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = frame,
      );
    }
  }
  _line(
    c,
    Path()
      ..moveTo(47, 45)
      ..quadraticBezierTo(50, 42, 53, 45),
    star ? const Color(0xFFF2B23C) : frame,
    2,
  );
}

void _scarf(Canvas c) {
  const red = Color(0xFFE5574A);
  final band = Path()
    ..moveTo(30, 64)
    ..quadraticBezierTo(50, 74, 70, 64)
    ..lineTo(70, 70)
    ..quadraticBezierTo(50, 80, 30, 70)
    ..close();
  _piece(c, band, red);
  final tail = Path()
    ..moveTo(56, 70)
    ..lineTo(66, 88)
    ..lineTo(58, 86)
    ..lineTo(52, 74)
    ..close();
  _piece(c, tail, const Color(0xFFC9443A));
  for (final x in [36.0, 44.0, 52.0, 60.0]) {
    c.drawCircle(
      Offset(x, 69 + (x - 50).abs() * -0.12),
      1,
      Paint()..color = const Color(0xFFF6EAD0),
    );
  }
}

void _bowtie(Canvas c) {
  const color = Color(0xFFE5574A);
  _piece(
    c,
    Path()
      ..moveTo(50, 68)
      ..lineTo(40, 62)
      ..lineTo(40, 74)
      ..close(),
    color,
  );
  _piece(
    c,
    Path()
      ..moveTo(50, 68)
      ..lineTo(60, 62)
      ..lineTo(60, 74)
      ..close(),
    color,
  );
  _piece(
    c,
    Path()..addOval(
      Rect.fromCenter(center: const Offset(50, 68), width: 6, height: 7),
    ),
    const Color(0xFFC9443A),
  );
  c.drawCircle(
    const Offset(43, 66),
    1,
    Paint()..color = const Color(0xFFF6EAD0),
  );
  c.drawCircle(
    const Offset(57, 70),
    1,
    Paint()..color = const Color(0xFFF6EAD0),
  );
}

void _barong(Canvas c) {
  final shirt = Path()
    ..moveTo(30, 66)
    ..quadraticBezierTo(50, 72, 70, 66)
    ..quadraticBezierTo(78, 80, 72, 92)
    ..lineTo(28, 92)
    ..quadraticBezierTo(22, 80, 30, 66)
    ..close();
  c.drawPath(shirt.shift(const Offset(0.5, 1.5)), _shadow);
  c.drawPath(shirt, Paint()..color = const Color(0xDDF8F1E0));
  const thread = Color(0xFFB9A57E);
  _line(
    c,
    Path()
      ..moveTo(50, 70)
      ..lineTo(50, 90),
    thread,
    0.8,
  );
  for (var y = 74.0; y < 90; y += 4) {
    _line(
      c,
      Path()
        ..moveTo(44, y)
        ..quadraticBezierTo(47, y - 2, 50, y)
        ..quadraticBezierTo(53, y - 2, 56, y),
      thread,
      0.7,
    );
  }
  for (final o in const [Offset(50, 74), Offset(50, 80), Offset(50, 86)]) {
    c.drawCircle(o, 1, Paint()..color = thread);
  }
}

void _moonCape(Canvas c) {
  final cape = Path()
    ..moveTo(28, 66)
    ..quadraticBezierTo(50, 72, 72, 66)
    ..quadraticBezierTo(86, 84, 82, 96)
    ..quadraticBezierTo(50, 88, 18, 96)
    ..quadraticBezierTo(14, 84, 28, 66)
    ..close();
  _piece(c, cape, const Color(0xFF2C3170));
  for (final o in const [
    Offset(26, 86),
    Offset(36, 80),
    Offset(66, 82),
    Offset(76, 90),
    Offset(50, 90),
  ]) {
    c.drawCircle(o, 1.2, Paint()..color = const Color(0xFFFFF4DC));
  }
  // Crescent clasp
  c.drawCircle(
    const Offset(50, 69),
    4,
    Paint()..color = const Color(0xFFF2B23C),
  );
  c.drawCircle(
    const Offset(52, 68),
    3.4,
    Paint()..color = const Color(0xFF2C3170),
  );
}
