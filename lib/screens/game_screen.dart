import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/paddle_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/paddle_themes.dart';
import '../theme/paddle_ui.dart';
import '../widgets/arena_painter.dart';

const _storeUrl =
    'https://play.google.com/store/apps/details?id=com.gameswajiha.paddleclash';

/// Engine-driven match screen. The engine owns all state and phases; this
/// widget renders, forwards drag input, and maps engine events to audio.
class GameScreen extends StatefulWidget {
  final PaddleEngine engine;
  final ClashAudio audio;
  final ClashSettings settings;
  const GameScreen({
    super.key,
    required this.engine,
    required this.audio,
    required this.settings,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  StreamSubscription<ClashEvent>? _events;
  bool _matchRecorded = false;

  PaddleEngine get _e => widget.engine;
  ClashSettings get _s => widget.settings;
  PaddleThemeDef get _t =>
      PaddleThemes.byId(_s.themeId, custom: _s.customTheme);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.audio.startGameMusic();
    _events = _e.events.listen(_onEvent);
  }

  void _onEvent(ClashEvent e) {
    final a = widget.audio;
    switch (e) {
      case ClashEvent.paddleHit:
        a.paddleHit();
        break;
      case ClashEvent.wallTick:
        a.wallTick();
        break;
      case ClashEvent.goalBottom:
      case ClashEvent.goalTop:
        a.goal();
        break;
      case ClashEvent.rallyMilestone:
        a.rallyMilestone();
        break;
      case ClashEvent.serve:
        a.click();
        break;
      case ClashEvent.matchOver:
        _onMatchOver();
        break;
    }
  }

  Future<void> _onMatchOver() async {
    if (_matchRecorded) return;
    _matchRecorded = true;
    // In solo the human is the bottom seat; in duo both seats are human.
    final humanWon = _e.twoPlayer || _e.bottomWon;
    await _s.recordMatch(
        humanWon: humanWon, rally: _e.bestRallyMatch);
    if (humanWon && _e.bottomWon) {
      await widget.audio.win();
    } else if (!_e.bottomWon && !_e.twoPlayer) {
      await widget.audio.lose();
    }
    // Sensible review moment: every 3rd human win. Graceful when not from Play.
    if (humanWon && _s.wins % 3 == 0 && mounted) {
      try {
        final review = InAppReview.instance;
        if (await review.isAvailable()) {
          await review.requestReview();
        }
      } catch (_) {}
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Freeze the engine when the app is interrupted; the watchdog plus the
    // phase timers make resume safe — no stuck states.
    if (state == AppLifecycleState.paused) {
      _e.pause();
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _events?.cancel();
    _e.dispose();
    super.dispose();
  }

  void _drag(DragUpdateDetails d, Size arena) {
    final fx = (d.localPosition.dx / arena.width)
        .clamp(PaddleEngine.paddleW / 2, 1 - PaddleEngine.paddleW / 2);
    final isTopHalf = d.localPosition.dy < arena.height / 2;
    if (_e.twoPlayer) {
      if (isTopHalf) {
        _e.dragTop(fx);
      } else {
        _e.dragBottom(fx);
      }
    } else {
      _e.dragBottom(fx);
    }
  }

  Future<void> _pauseMenu() async {
    _e.pause();
    widget.audio.click();
    final t = _t;
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: [
              t.tableMid,
              t.tableDark,
            ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            border: Border.all(color: t.accent, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Paused', style: ClashText.display(30, t: t)),
              const SizedBox(height: 18),
              WoodButton(
                  label: '▶  Resume',
                  onTap: () => Navigator.of(context).pop('resume'),
                  theme: t,
                  width: 220,
                  small: true),
              const SizedBox(height: 10),
              WoodButton(
                  label: '↻  Restart',
                  onTap: () => Navigator.of(context).pop('restart'),
                  theme: t,
                  width: 220,
                  small: true),
              const SizedBox(height: 10),
              WoodButton(
                  label: '🏠  Quit to Menu',
                  onTap: () => Navigator.of(context).pop('quit'),
                  theme: t,
                  width: 220,
                  small: true),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'resume':
        _e.resume();
        break;
      case 'restart':
        widget.audio.gameStart();
        _matchRecorded = false;
        _e.restart();
        break;
      case 'quit':
        Navigator.of(context).pop();
        break;
      default:
        _e.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return WoodBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.pause, color: t.ivory),
            onPressed: _pauseMenu,
          ),
          title: Text('First to ${PaddleEngine.winScore}',
              style: ClashText.label(15, t: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _e,
            builder: (_, _) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                children: [
                  _scoreRow(t),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 26,
                    child: Text(
                      _e.narration,
                      style: ClashText.body(14,
                          t: t, color: t.accentLight),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(child: _arena(t)),
                  const SizedBox(height: 8),
                  Text(
                    _e.twoPlayer
                        ? 'Top half = ${_e.nameTop}  •  Bottom half = ${_e.nameBottom}'
                        : 'Drag anywhere to slide your paddle 👆',
                    style: ClashText.body(13,
                        t: t, color: t.ivory.withValues(alpha: 0.7)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoreRow(PaddleThemeDef t) {
    return Row(
      children: [
        Expanded(
            child: _scoreChip(
                t, _e.nameTop, _e.scoreTop, _e.scorePopTop, false)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _rallyBadge(t),
        ),
        Expanded(
            child: _scoreChip(
                t, _e.nameBottom, _e.scoreBottom, _e.scorePopBottom, true)),
      ],
    );
  }

  Widget _rallyBadge(PaddleThemeDef t) {
    final show = _e.rally >= 3;
    return AnimatedOpacity(
      opacity: show ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _e.rally >= 10
              ? t.accent
              : Colors.black.withValues(alpha: 0.4),
          border: Border.all(color: t.accentLight),
        ),
        child: Text(
          '🔥 ${_e.rally}',
          style: ClashText.label(14,
              t: t,
              color: _e.rally >= 10 ? t.woodDeep : t.accentLight),
        ),
      ),
    );
  }

  Widget _scoreChip(PaddleThemeDef t, String name, int score, int popKey,
      bool isBottom) {
    final leading = isBottom
        ? _e.scoreBottom > _e.scoreTop
        : _e.scoreTop > _e.scoreBottom;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [
          t.tableMid,
          t.tableDark,
        ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        border: Border.all(
            color: leading ? t.accentLight : t.accent.withValues(alpha: 0.4),
            width: leading ? 2.5 : 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(name,
                style: ClashText.label(13, t: t),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          AnimatedScale(
            key: ValueKey(popKey),
            scale: 1.0,
            duration: const Duration(milliseconds: 180),
            child: Text('$score',
                style: ClashText.display(24, t: t)),
          ),
        ],
      ),
    );
  }

  Widget _arena(PaddleThemeDef t) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final arena = Size(c.maxWidth, c.maxHeight);
        final shake = _e.shake;
        final now = DateTime.now().millisecondsSinceEpoch / 28.0;
        final dx = shake > 0 ? sin(now) * shake * 10 : 0.0;
        final dy = shake > 0 ? cos(now * 1.3) * shake * 7 : 0.0;
        return GestureDetector(
          onPanUpdate: (d) => _drag(d, arena),
          onPanStart: (d) => _drag(
              DragUpdateDetails(
                  globalPosition: d.globalPosition,
                  localPosition: d.localPosition),
              arena),
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size.infinite,
                      painter: ArenaPainter(
                        engine: _e,
                        theme: t,
                        paddleStyle:
                            PaddleStyles.byId(_s.paddleStyleId),
                        ballStyle: BallStyles.byId(_s.ballStyleId),
                        twoPlayer: _e.twoPlayer,
                      ),
                    ),
                    if (_e.phase == ClashPhase.serve && !_e.isOver)
                      _centerOverlay(t, '⚡ get ready…'),
                    if (_e.phase == ClashPhase.over)
                      _victoryOverlay(t),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _centerOverlay(PaddleThemeDef t, String text) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withValues(alpha: 0.62),
          border: Border.all(color: t.accent, width: 2),
        ),
        child: Text(text, style: ClashText.display(22, t: t)),
      ),
    );
  }

  Widget _victoryOverlay(PaddleThemeDef t) {
    final bottomWon = _e.bottomWon;
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(colors: [
              t.tableMid,
              t.tableDark,
            ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            border: Border.all(color: t.accent, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏆', style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 8),
              Text(_e.winnerName,
                  style: ClashText.display(30, t: t),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                '${_e.scoreBottom} – ${_e.scoreTop}  •  Best rally ${_e.bestRallyMatch}',
                style: ClashText.label(15, t: t, color: t.accentLight),
              ),
              const SizedBox(height: 6),
              Text(
                bottomWon
                    ? (_e.twoPlayer
                        ? 'Champion of the table!'
                        : 'You smashed the AI! 🎉')
                    : (_e.twoPlayer
                        ? 'What a duel — rematch?'
                        : 'The AI sends its regards. Rematch?'),
                style: ClashText.body(14, t: t),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              WoodButton(
                label: '↻  Rematch',
                onTap: () {
                  widget.audio.gameStart();
                  _matchRecorded = false;
                  _e.restart();
                },
                theme: t,
                width: 220,
                small: true,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _smallBtn(t, Icons.share, () async {
                    widget.audio.click();
                    await Share.share(
                        'I just played Paddle Clash — your turn! $_storeUrl');
                  }),
                  const SizedBox(width: 12),
                  _smallBtn(t, Icons.home, () {
                    widget.audio.click();
                    Navigator.of(context).pop();
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallBtn(PaddleThemeDef t, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [t.tableMid, t.tableDark]),
          border: Border.all(color: t.accent, width: 2),
        ),
        child: Icon(icon, color: t.accentLight, size: 24),
      ),
    );
  }
}
