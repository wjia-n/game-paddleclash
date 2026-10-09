import 'dart:math';
import 'package:flutter/material.dart';
import '../engine/paddle_engine.dart';
import '../theme/paddle_themes.dart';

/// Paints the physical Paddle Clash arena: polished wood table with grain,
/// engraved lines, wooden paddles with rubber faces, and a shaded ball.
/// No neon, no glow-dashboard looks — real materials, weight and shadow.
class ArenaPainter extends CustomPainter {
  final PaddleEngine engine;
  final PaddleThemeDef theme;
  final PaddleStyleDef paddleStyle;
  final BallStyleDef ballStyle;
  final bool twoPlayer;

  ArenaPainter({
    required this.engine,
    required this.theme,
    required this.paddleStyle,
    required this.ballStyle,
    required this.twoPlayer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintTable(canvas, size);
    _paintPaddle(canvas, size, engine.topX, PaddleEngine.topY, theme.paddleTop, up: true);
    _paintPaddle(canvas, size, engine.botX, PaddleEngine.botY, theme.paddleBottom, up: false);
    _paintTrail(canvas, size);
    _paintBall(canvas, size);
    _paintParticles(canvas, size);
    _paintHitFlash(canvas, size);
  }

  void _paintTable(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(18),
    );
    // Table body: vertical wood blend.
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.tableMid, theme.tableDark, theme.tableMid],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect.outerRect),
    );
    // Wood grain: faint horizontal streaks.
    final grain = Paint()
      ..color = theme.tableEdge.withValues(alpha: 0.18)
      ..strokeWidth = 1.5;
    for (int i = 1; i < 9; i++) {
      final y = size.height * i / 9 + sin(i * 2.3) * 4;
      canvas.drawLine(Offset(10, y), Offset(size.width - 10, y), grain);
    }
    // Edge band.
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = theme.tableEdge,
    );
    // Brass inner trim.
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, 12, size.width - 24, size.height - 24),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = theme.accent.withValues(alpha: 0.8),
    );
    // Center line.
    final cy = size.height / 2;
    final linePaint = Paint()
      ..color = theme.tableLine.withValues(alpha: 0.9)
      ..strokeWidth = 3;
    var x = 18.0;
    while (x < size.width - 18) {
      canvas.drawLine(Offset(x, cy), Offset(min(x + 14, size.width - 18), cy), linePaint);
      x += 24;
    }
    // Center circle.
    canvas.drawCircle(
      Offset(size.width / 2, cy),
      size.width * 0.10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = theme.tableLine.withValues(alpha: 0.7),
    );
    // Two-player touch-zone hint.
    if (twoPlayer) {
      canvas.drawLine(
        Offset(18, cy),
        Offset(size.width - 18, cy),
        Paint()
          ..color = theme.tableLine.withValues(alpha: 0.25)
          ..strokeWidth = 1,
      );
    }
  }

  void _paintPaddle(
      Canvas canvas, Size size, double cxFrac, double yFrac, Color rubber,
      {required bool up}) {
    final pw = PaddleEngine.paddleW * paddleStyle.widthScale * size.width;
    final ph = PaddleEngine.paddleH * size.height + 12;
    final cx = cxFrac * size.width;
    final cy = yFrac * size.height;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: pw, height: ph);

    // Drop shadow — weight.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(const Offset(0, 5)), Radius.circular(ph / 2)),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // Wooden blade.
    final wood = Paint()..color = theme.tableEdge;
    final face = Paint()..color = rubber;
    final radius = Radius.circular(ph / 2 * paddleStyle.corner + 2);
    if (paddleStyle.oval) {
      canvas.drawOval(rect, wood);
      canvas.drawOval(rect.deflate(4), face);
    } else if (paddleStyle.arc) {
      final path = Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + 6)
        ..quadraticBezierTo(cx, rect.top - 8, rect.right, rect.top + 6)
        ..lineTo(rect.right, rect.bottom)
        ..quadraticBezierTo(cx, rect.bottom + 4, rect.left, rect.bottom)
        ..close();
      canvas.drawPath(path, wood);
      canvas.save();
      canvas.clipPath(path);
      canvas.drawRect(rect.deflate(4), face);
      canvas.restore();
    } else {
      final blade = RRect.fromRectAndRadius(rect, radius);
      canvas.drawRRect(blade, wood);
      canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(4), radius), face);
    }

    // Rubber highlight — sheen across the face.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + 6, rect.top + 3, rect.width - 12, ph * 0.28),
        const Radius.circular(6),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );

    // Handle.
    if (paddleStyle.handle) {
      final hw = pw * 0.18;
      final hh = ph * 1.1;
      final hx = cx - hw / 2;
      final hy = up ? rect.top - hh + 4 : rect.bottom - 4;
      final handleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(hx, hy, hw, hh),
        Radius.circular(hw / 2),
      );
      canvas.drawRRect(handleRect.shift(const Offset(0, 3)),
          Paint()..color = Colors.black.withValues(alpha: 0.3));
      canvas.drawRRect(
        handleRect,
        Paint()
          ..shader = LinearGradient(
            colors: [theme.tableMid, theme.tableDark],
          ).createShader(handleRect.outerRect),
      );
    }
  }

  Color _ballBaseColor() {
    switch (ballStyle.id) {
      case 'red':
        return const Color(0xFFC0392B);
      case 'cork':
        return const Color(0xFFC89B5E);
      case 'leather':
        return const Color(0xFF9C6B3C);
      case 'marble':
        return const Color(0xFFEDE8DA);
      case 'wood':
        return const Color(0xFF8A5A33);
      case 'gold':
        return const Color(0xFFD4AF37);
      case 'comet':
        return const Color(0xFFFFF6E0);
      case 'classic':
      default:
        return theme.ball;
    }
  }

  void _paintTrail(Canvas canvas, Size size) {
    if (ballStyle.id != 'comet' || engine.trail.length < 2) return;
    final base = _ballBaseColor();
    for (int i = 0; i < engine.trail.length; i++) {
      final p = engine.trail[i];
      final t = i / engine.trail.length;
      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height),
        PaddleEngine.ballR * size.width * t,
        Paint()..color = base.withValues(alpha: 0.35 * t),
      );
    }
  }

  void _paintBall(Canvas canvas, Size size) {
    if (engine.phase == ClashPhase.serve && engine.phaseTime < 0.05) return;
    final c = Offset(engine.ball.dx * size.width, engine.ball.dy * size.height);
    final r = PaddleEngine.ballR * size.width;
    final base = _ballBaseColor();

    // Contact shadow on the table.
    canvas.drawEllipse(
      Rect.fromCenter(center: c + Offset(r * 0.25, r * 0.55), width: r * 2.1, height: r * 0.9),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    // Shaded sphere: radial light from top-left.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 1.1,
          colors: [
            Color.lerp(base, Colors.white, 0.55)!,
            base,
            Color.lerp(base, Colors.black, 0.35)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Material detail.
    if (ballStyle.id == 'cork') {
      final sp = Paint()..color = const Color(0xFF8A5A2A).withValues(alpha: 0.7);
      for (int i = 0; i < 7; i++) {
        final a = i * 0.9;
        canvas.drawCircle(
            c + Offset(cos(a) * r * 0.45, sin(a) * r * 0.45), r * 0.09, sp);
      }
    } else if (ballStyle.id == 'marble') {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.7),
        0.4,
        2.2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.18
          ..color = const Color(0xFF8E8E96).withValues(alpha: 0.8),
      );
    }
  }

  void _paintParticles(Canvas canvas, Size size) {
    for (final p in engine.particles) {
      final t = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(p.pos.dx * size.width, p.pos.dy * size.height),
        p.size * t,
        Paint()..color = theme.accentLight.withValues(alpha: 0.85 * t),
      );
    }
  }

  void _paintHitFlash(Canvas canvas, Size size) {
    if (engine.hitFlash <= 0) return;
    final c = Offset(engine.hitPos.dx * size.width, engine.hitPos.dy * size.height);
    canvas.drawCircle(
      c,
      (1 - engine.hitFlash) * 44 + 10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = theme.accentLight.withValues(alpha: engine.hitFlash),
    );
  }

  @override
  bool shouldRepaint(covariant ArenaPainter old) => true;
}
