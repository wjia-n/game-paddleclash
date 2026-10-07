import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Paddle Clash — Pong with spin. Solo vs bot, or 2-player drag duel.
class PaddleClashScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const PaddleClashScreen({super.key, required this.players, required this.callbacks});

  @override
  State<PaddleClashScreen> createState() => _PaddleClashScreenState();
}

class _PaddleClashScreenState extends State<PaddleClashScreen> {
  static const _winScore = 7;
  static const _paddleW = 0.30; // fraction of arena width
  static const _paddleH = 0.022;
  static const _ballR = 0.020;

  final _rand = Random();
  Timer? _timer;

  // Positions as fractions of arena size.
  double topX = 0.5; // top paddle center-x
  double botX = 0.5; // bottom paddle center-x
  Offset ball = const Offset(0.5, 0.5);
  Offset vel = Offset.zero; // per-second, fraction units
  double ballSpeed = 0.55;
  int rally = 0;
  bool over = false;
  bool serving = true;
  double _botError = 0;

  bool get _solo => widget.players.length == 1 || widget.players[1].isBot;
  bool get _botIsTop => _solo; // bot always guards the top in solo

  @override
  void initState() {
    super.initState();
    widget.players[0].score = 0;
    if (widget.players.length > 1) widget.players[1].score = 0;
    widget.callbacks.refreshHud();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _step(0.016));
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && !over) setState(() => serving = false);
      _serve();
    });
  }

  void _serve() {
    if (over || !mounted) return;
    final up = _rand.nextBool();
    final ang = (_rand.nextDouble() - 0.5) * 0.9; // radians off vertical
    setState(() {
      ball = const Offset(0.5, 0.5);
      ballSpeed = 0.55;
      rally = 0;
      vel = Offset(sin(ang) * ballSpeed, (up ? -1 : 1) * cos(ang) * ballSpeed);
    });
  }

  void _step(double dt) {
    if (over || serving || !mounted) return;

    // Bot brain: track the ball with capped speed + occasional wobble.
    if (_botIsTop) {
      _botError += (_rand.nextDouble() - 0.5) * 0.06;
      _botError = _botError.clamp(-0.14, 0.14);
      final target = (ball.dx + _botError).clamp(_paddleW / 2, 1 - _paddleW / 2);
      const maxStep = 0.42 * 0.016; // capped speed
      final diff = target - topX;
      topX += diff.clamp(-maxStep, maxStep);
    }

    var bx = ball.dx + vel.dx * dt;
    var by = ball.dy + vel.dy * dt;
    var vx = vel.dx, vy = vel.dy;

    // Side walls.
    if (bx < _ballR) { bx = _ballR; vx = vx.abs(); Sfx.tap(); }
    if (bx > 1 - _ballR) { bx = 1 - _ballR; vx = -vx.abs(); Sfx.tap(); }

    // Paddles (top at y~0.04, bottom at y~0.96).
    const topY = 0.05, botY = 0.95;
    if (vy < 0 && by - _ballR <= topY + _paddleH / 2 && by > topY - 0.06) {
      if ((bx - topX).abs() <= _paddleW / 2 + _ballR) {
        _bounce(top: true, hitOffset: (bx - topX) / (_paddleW / 2));
        by = topY + _paddleH / 2 + _ballR;
        vx = vel.dx; vy = vel.dy; bx = ball.dx + vx * dt;
      }
    }
    if (vy > 0 && by + _ballR >= botY - _paddleH / 2 && by < botY + 0.06) {
      if ((bx - botX).abs() <= _paddleW / 2 + _ballR) {
        _bounce(top: false, hitOffset: (bx - botX) / (_paddleW / 2));
        by = botY - _paddleH / 2 - _ballR;
        vx = vel.dx; vy = vel.dy; bx = ball.dx + vx * dt;
      }
    }

    // Goals.
    if (by < -0.05) {
      _point(0); // bottom player (index 0) scores
      return;
    }
    if (by > 1.05) {
      _point(1); // top player scores
      return;
    }

    setState(() {
      ball = Offset(bx, by);
      vel = Offset(vx, vy);
    });
  }

  /// Spin: hit position (-1..1 across the paddle) steers the rebound angle.
  void _bounce({required bool top, required double hitOffset}) {
    rally++;
    ballSpeed = min(1.05, ballSpeed * 1.045);
    final off = hitOffset.clamp(-1.0, 1.0);
    final ang = off * 1.05; // up to ~60° off vertical
    vel = Offset(sin(ang) * ballSpeed, (top ? 1 : -1) * cos(ang) * ballSpeed);
    if (rally >= 6) {
      Sfx.win();
    } else {
      Sfx.move();
    }
  }

  void _point(int scorer) {
    if (over) return;
    final p = widget.players[scorer];
    p.score += 1;
    widget.callbacks.refreshHud();
    Sfx.click();
    if (p.score >= _winScore) {
      _endMatch(scorer);
      return;
    }
    setState(() => serving = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || over) return;
      setState(() => serving = false);
      _serve();
    });
  }

  void _endMatch(int winnerIdx) {
    setState(() => over = true);
    _timer?.cancel();
    final w = widget.players[winnerIdx];
    final loser = widget.players.length > 1 ? widget.players[1 - winnerIdx].score : 0;
    Sfx.win();
    widget.callbacks.finish(
      winner: w,
      headline: '${w.name} smashes it ${w.score}–$loser! 🏓',
      subline: w.isBot ? 'The bot sends its regards. Rematch?' : 'Champion of the table!',
    );
  }

  void _drag(DragUpdateDetails d, Size arena) {
    if (over) return;
    final fx = (d.localPosition.dx / arena.width).clamp(_paddleW / 2, 1 - _paddleW / 2);
    final isTopHalf = d.localPosition.dy < arena.height / 2;
    setState(() {
      if (_solo) {
        botX = fx; // human always owns the bottom in solo
      } else {
        if (isTopHalf) {
          topX = fx;
        } else {
          botX = fx;
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final top = widget.players.length > 1 ? widget.players[1] : widget.players[0];
    final bot = widget.players[0];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          ScoreChips(players: widget.players, activeIndex: 0),
          const SizedBox(height: 8),
          Text('First to $_winScore takes the match ⚡',
              style: TextStyle(color: t.muted, fontSize: 13)),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, c) {
                final arena = Size(c.maxWidth, c.maxHeight);
                return GestureDetector(
                  onPanUpdate: (d) => _drag(d, arena),
                  onPanStart: (d) => _drag(
                      DragUpdateDetails(globalPosition: d.globalPosition, localPosition: d.localPosition), arena),
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: t.radius,
                      boxShadow: [
                        BoxShadow(
                          color: t.primary.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: t.radius,
                      child: CustomPaint(
                        painter: _PongPainter(
                          topX: topX,
                          botX: botX,
                          ball: ball,
                          topColor: top.color,
                          botColor: bot.color,
                          ballColor: t.accent,
                          lineColor: t.muted,
                          serving: serving,
                          twoPlayer: !_solo,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _solo ? 'Drag anywhere to slide your paddle 👆' : 'Top half = ${top.name} · Bottom half = ${bot.name}',
            style: TextStyle(color: t.muted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _PongPainter extends CustomPainter {
  final double topX, botX;
  final Offset ball;
  final Color topColor, botColor, ballColor, lineColor;
  final bool serving;
  final bool twoPlayer;

  _PongPainter({
    required this.topX,
    required this.botX,
    required this.ball,
    required this.topColor,
    required this.botColor,
    required this.ballColor,
    required this.lineColor,
    required this.serving,
    required this.twoPlayer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const topY = 0.05, botY = 0.95;
    const pw = 0.30, ph = 0.022, br = 0.020;

    // center dashed line
    final dash = Paint()
      ..color = lineColor.withValues(alpha: 0.5)
      ..strokeWidth = 2;
    const dashW = 12.0, gap = 10.0;
    var x = 12.0;
    final cy = size.height / 2;
    while (x < size.width - 12) {
      canvas.drawLine(Offset(x, cy), Offset(min(x + dashW, size.width - 12), cy), dash);
      x += dashW + gap;
    }
    // center circle
    canvas.drawCircle(
      Offset(size.width / 2, cy),
      size.width * 0.09,
      Paint()
        ..color = lineColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // touch zones hint for 2P
    if (twoPlayer) {
      canvas.drawLine(
        Offset(0, cy),
        Offset(size.width, cy),
        Paint()
          ..color = lineColor.withValues(alpha: 0.25)
          ..strokeWidth = 1,
      );
    }

    // paddles with glow
    void paddle(double cx, double fy, Color c) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx * size.width, fy * size.height),
          width: pw * size.width,
          height: ph * size.height + 8,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = c.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawRRect(rect, Paint()..color = c);
    }

    paddle(topX, topY, topColor);
    paddle(botX, botY, botColor);

    // ball with trail glow
    final bc = Offset(ball.dx * size.width, ball.dy * size.height);
    canvas.drawCircle(
      bc,
      br * size.width * 1.8,
      Paint()
        ..color = ballColor.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(bc, br * size.width, Paint()..color = ballColor);

    if (serving) {
      final tp = TextPainter(
        text: const TextSpan(
          text: '⚡ get ready…',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width / 2, cy), width: tp.width + 30, height: tp.height + 20),
        const Radius.circular(16),
      );
      canvas.drawRRect(bgRect, Paint()..color = Colors.black54);
      tp.paint(canvas, Offset((size.width - tp.width) / 2, cy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _PongPainter old) =>
      old.topX != topX || old.botX != botX || old.ball != ball || old.serving != serving;
}
