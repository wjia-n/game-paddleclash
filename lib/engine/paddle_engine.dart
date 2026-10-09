import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Match phases. The engine owns every phase transition on its own timers;
/// the UI only renders and forwards input. No stuck states by construction.
enum ClashPhase { serve, rally, point, over }

enum ClashDifficulty { easy, medium, hard }

/// One-shot events the UI turns into sound/narration. The engine never
/// touches audio directly.
enum ClashEvent {
  paddleHit,
  wallTick,
  goalBottom,
  goalTop,
  rallyMilestone,
  serve,
  matchOver,
}

/// A juicy particle: position in arena fractions, velocity in fractions/sec.
class HitParticle {
  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final double size;
  HitParticle({
    required this.pos,
    required this.vel,
    required this.life,
    required this.maxLife,
    required this.size,
  });
}

/// Paddle Clash engine: pong with spin vs an AI (3 difficulties) or
/// pass-and-play. Deterministic physics; engine-owned phase machine with a
/// watchdog that recovers any stalled phase.
class PaddleEngine extends ChangeNotifier {
  static const int winScore = 7;
  static const double paddleW = 0.30;
  static const double paddleH = 0.022;
  static const double ballR = 0.020;
  static const double topY = 0.05;
  static const double botY = 0.95;
  static const double _serveDelay = 1.1;
  static const double _pointDelay = 1.5;

  final ClashDifficulty difficulty;
  final bool twoPlayer;
  final String nameBottom;
  final String nameTop;

  final StreamController<ClashEvent> events =
      StreamController<ClashEvent>.broadcast();

  final _rand = Random();
  Timer? _tick;
  Timer? _watchdog;

  // ---- live state ----
  double botX = 0.5;
  double topX = 0.5;
  Offset ball = const Offset(0.5, 0.5);
  Offset vel = Offset.zero;
  double speed = 0.6;
  int scoreBottom = 0;
  int scoreTop = 0;
  int rally = 0;
  int bestRallyMatch = 0;
  ClashPhase phase = ClashPhase.serve;
  bool paused = false;
  double phaseTime = 0;
  String narration = '';
  final List<HitParticle> particles = [];
  final List<Offset> trail = [];
  double shake = 0;
  double hitFlash = 0; // paddle-hit flash 1→0
  Offset hitPos = Offset.zero;
  int scorePopBottom = 0; // bump to animate score chips
  int scorePopTop = 0;
  int serveNumber = 0;

  DateTime _lastBallProgress = DateTime.now();
  double _aiError = 0;
  double _aiErrorTimer = 0;

  PaddleEngine({
    required this.difficulty,
    required this.twoPlayer,
    required this.nameBottom,
    required this.nameTop,
  }) {
    narration = '$nameBottom to serve…';
    _tick = Timer.periodic(
        const Duration(milliseconds: 16), (_) => _step(0.016));
    _watchdog = Timer.periodic(
        const Duration(milliseconds: 500), (_) => _watchdogCheck());
  }

  bool get isOver => phase == ClashPhase.over;
  String get winnerName => scoreBottom > scoreTop ? nameBottom : nameTop;
  bool get bottomWon => scoreBottom > scoreTop;

  // ------------------------------------------------------------ input
  void dragBottom(double fx) {
    if (paused || isOver) return;
    botX = fx.clamp(paddleW / 2, 1 - paddleW / 2);
  }

  void dragTop(double fx) {
    if (paused || isOver || !twoPlayer) return;
    topX = fx.clamp(paddleW / 2, 1 - paddleW / 2);
  }

  void pause() {
    paused = true;
    notifyListeners();
  }

  void resume() {
    paused = false;
    notifyListeners();
  }

  /// Restart the whole match; engine returns to a clean serve phase.
  void restart() {
    scoreBottom = 0;
    scoreTop = 0;
    rally = 0;
    bestRallyMatch = 0;
    botX = 0.5;
    topX = 0.5;
    particles.clear();
    trail.clear();
    shake = 0;
    paused = false;
    serveNumber = 0;
    _setPhase(ClashPhase.serve);
    narration = '$nameBottom to serve…';
    _lastBallProgress = DateTime.now();
    notifyListeners();
  }

  // ------------------------------------------------------------ phases
  void _setPhase(ClashPhase p) {
    phase = p;
    phaseTime = 0;
  }

  void _step(double dt) {
    // Juice always decays so victory/point particles finish animating.
    _decayJuice(dt);
    if (paused || isOver) {
      notifyListeners();
      return;
    }
    phaseTime += dt;

    switch (phase) {
      case ClashPhase.serve:
        if (phaseTime >= _serveDelay) _launch();
        break;
      case ClashPhase.rally:
        _rallyStep(dt);
        break;
      case ClashPhase.point:
        if (phaseTime >= _pointDelay) _afterPoint();
        break;
      case ClashPhase.over:
        break;
    }
    notifyListeners();
  }

  void _decayJuice(double dt) {
    shake = max(0.0, shake - dt * 2.2);
    hitFlash = max(0.0, hitFlash - dt * 3.0);
    for (int i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];
      p.life -= dt;
      if (p.life <= 0) {
        particles.removeAt(i);
        continue;
      }
      p.pos += p.vel * dt;
      p.vel *= (1 - 2.5 * dt); // drag
    }
  }

  /// Launch the ball after a serve countdown. Direction favors the player
  /// who just conceded (gives them the first return).
  void _launch() {
    final towardTop = serveNumber.isOdd;
    final ang = (_rand.nextDouble() - 0.5) * 0.9;
    speed = 0.6;
    ball = const Offset(0.5, 0.5);
    trail.clear();
    vel = Offset(sin(ang) * speed, (towardTop ? -1 : 1) * cos(ang) * speed);
    rally = 0;
    _setPhase(ClashPhase.rally);
    _lastBallProgress = DateTime.now();
    events.add(ClashEvent.serve);
    narration = towardTop ? '$nameTop returns…' : '$nameBottom returns…';
  }

  void _rallyStep(double dt) {
    // AI brain (solo only): track the ball with capped speed + error.
    if (!twoPlayer) _aiStep(dt);

    var bx = ball.dx + vel.dx * dt;
    var by = ball.dy + vel.dy * dt;
    var vx = vel.dx, vy = vel.dy;

    // Side walls.
    if (bx < ballR) {
      bx = ballR;
      vx = vx.abs();
      events.add(ClashEvent.wallTick);
      _burst(Offset(bx, by), 4);
    } else if (bx > 1 - ballR) {
      bx = 1 - ballR;
      vx = -vx.abs();
      events.add(ClashEvent.wallTick);
      _burst(Offset(bx, by), 4);
    }

    // Paddles.
    if (vy < 0 && by - ballR <= topY + paddleH / 2 && by > topY - 0.08) {
      if ((bx - topX).abs() <= paddleW / 2 + ballR) {
        _bounce(top: true, hitOffset: (bx - topX) / (paddleW / 2));
        by = topY + paddleH / 2 + ballR;
        vx = vel.dx;
        vy = vel.dy;
      }
    } else if (vy > 0 &&
        by + ballR >= botY - paddleH / 2 &&
        by < botY + 0.08) {
      if ((bx - botX).abs() <= paddleW / 2 + ballR) {
        _bounce(top: false, hitOffset: (bx - botX) / (paddleW / 2));
        by = botY - paddleH / 2 - ballR;
        vx = vel.dx;
        vy = vel.dy;
      }
    }

    // Goals.
    if (by < -0.06) {
      _goal(bottomScored: true);
      return;
    }
    if (by > 1.06) {
      _goal(bottomScored: false);
      return;
    }

    ball = Offset(bx, by);
    vel = Offset(vx, vy);
    trail.add(ball);
    if (trail.length > 16) trail.removeAt(0);
    _lastBallProgress = DateTime.now();
  }

  /// Spin: where the ball lands on the paddle (-1..1) steers the rebound.
  void _bounce({required bool top, required double hitOffset}) {
    rally++;
    bestRallyMatch = max(bestRallyMatch, rally);
    speed = min(1.3, speed * 1.045);
    final off = hitOffset.clamp(-1.0, 1.0);
    final ang = off * 1.05; // up to ~60° off vertical
    vel = Offset(sin(ang) * speed, (top ? 1 : -1) * cos(ang) * speed);
    hitFlash = 1.0;
    hitPos = Offset(ball.dx, top ? topY : botY);
    shake = max(shake, 0.32);
    _burst(ball, 8);
    events.add(ClashEvent.paddleHit);
    if (rally > 0 && rally % 10 == 0) {
      narration = 'Rally $rally! 🔥';
      events.add(ClashEvent.rallyMilestone);
    } else if (rally >= winScore - 1 && _matchPoint()) {
      narration = 'Match point — $winnerName!';
    }
  }

  bool _matchPoint() =>
      scoreBottom == winScore - 1 || scoreTop == winScore - 1;

  void _goal({required bool bottomScored}) {
    if (bottomScored) {
      scoreBottom++;
      scorePopBottom++;
      narration = '$nameBottom scores! 🎯';
      events.add(ClashEvent.goalBottom);
    } else {
      scoreTop++;
      scorePopTop++;
      narration = '$nameTop scores! 🎯';
      events.add(ClashEvent.goalTop);
    }
    shake = 0.8;
    // Goal explosion at the mouth of the goal.
    final gy = bottomScored ? 0.0 : 1.0;
    for (int i = 0; i < 22; i++) {
      final a = _rand.nextDouble() * 2 * pi;
      final sp = 0.25 + _rand.nextDouble() * 0.5;
      particles.add(HitParticle(
        pos: Offset(ball.dx.clamp(0.05, 0.95), gy),
        vel: Offset(cos(a) * sp, sin(a) * sp * (bottomScored ? 1 : -1).abs()),
        life: 0.7 + _rand.nextDouble() * 0.5,
        maxLife: 1.2,
        size: 3 + _rand.nextDouble() * 5,
      ));
    }
    serveNumber++;
    _setPhase(ClashPhase.point);
  }

  void _afterPoint() {
    if (scoreBottom >= winScore || scoreTop >= winScore) {
      _setPhase(ClashPhase.over);
      narration = '$winnerName takes the match! 🏆';
      events.add(ClashEvent.matchOver);
      return;
    }
    // Next serve goes toward the player who conceded.
    ball = const Offset(0.5, 0.5);
    vel = Offset.zero;
    _setPhase(ClashPhase.serve);
    narration = '${serveNumber.isOdd ? nameTop : nameBottom} to serve…';
  }

  // ------------------------------------------------------------ AI brain
  double get _aiMaxSpeed {
    switch (difficulty) {
      case ClashDifficulty.easy:
        return 0.34;
      case ClashDifficulty.medium:
        return 0.62;
      case ClashDifficulty.hard:
        return 1.0;
    }
  }

  double get _aiErrorAmp {
    switch (difficulty) {
      case ClashDifficulty.easy:
        return 0.17;
      case ClashDifficulty.medium:
        return 0.07;
      case ClashDifficulty.hard:
        return 0.018;
    }
  }

  /// Predict where the ball crosses the AI paddle line, folding wall bounces.
  double _predictX() {
    if (vel.dy >= -0.02) return 0.5; // ball moving away: drift home
    final t = (topY - ball.dy) / vel.dy; // vy < 0 → t > 0
    if (t <= 0 || t > 6) return 0.5;
    double x = ball.dx + vel.dx * t;
    x = x % 2;
    if (x < 0) x += 2;
    return x > 1 ? 2 - x : x;
  }

  void _aiStep(double dt) {
    _aiErrorTimer -= dt;
    if (_aiErrorTimer <= 0) {
      _aiErrorTimer = 0.35;
      _aiError = (_rand.nextDouble() * 2 - 1) * _aiErrorAmp;
    }
    double target;
    if (vel.dy < -0.02) {
      target = difficulty == ClashDifficulty.easy
          ? ball.dx + _aiError // easy: chase the ball, no prediction
          : _predictX() + _aiError;
    } else {
      target = 0.5 + _aiError * 0.5; // drift back to center
    }
    target = target.clamp(paddleW / 2, 1 - paddleW / 2);
    final maxStep = _aiMaxSpeed * dt;
    final diff = target - topX;
    topX += diff.clamp(-maxStep, maxStep);
  }

  // ------------------------------------------------------------ watchdog
  /// Safety net: if any phase runs far past its own timer budget (timer
  /// hiccup, background stall), force it forward. Stuck states impossible.
  void _watchdogCheck() {
    if (paused || isOver) return;
    switch (phase) {
      case ClashPhase.serve:
        if (phaseTime > 5) _launch();
        break;
      case ClashPhase.rally:
        if (DateTime.now().difference(_lastBallProgress).inSeconds > 3) {
          // Ball somehow stalled mid-rally: re-serve cleanly.
          ball = const Offset(0.5, 0.5);
          vel = Offset.zero;
          _setPhase(ClashPhase.serve);
          narration = 'Let\u2019s go again…';
        }
        break;
      case ClashPhase.point:
        if (phaseTime > 5) _afterPoint();
        break;
      case ClashPhase.over:
        break;
    }
  }

  void _burst(Offset at, int count) {
    for (int i = 0; i < count; i++) {
      final a = _rand.nextDouble() * 2 * pi;
      final sp = 0.2 + _rand.nextDouble() * 0.4;
      particles.add(HitParticle(
        pos: at,
        vel: Offset(cos(a) * sp, sin(a) * sp),
        life: 0.35 + _rand.nextDouble() * 0.3,
        maxLife: 0.65,
        size: 2 + _rand.nextDouble() * 4,
      ));
    }
    if (particles.length > 160) {
      particles.removeRange(0, particles.length - 160);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _watchdog?.cancel();
    events.close();
    super.dispose();
  }
}
