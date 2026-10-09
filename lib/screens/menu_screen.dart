import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/paddle_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/paddle_themes.dart';
import '../theme/paddle_ui.dart';
import 'custom_theme_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

const _storeUrl =
    'https://play.google.com/store/apps/details?id=com.gameswajiha.paddleclash';

class MenuScreen extends StatefulWidget {
  final ClashAudio audio;
  final ClashSettings settings;
  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final ClashStore _store = ClashStore();
  late final TextEditingController _nameBottom;
  late final TextEditingController _nameTop;

  ClashSettings get _s => widget.settings;
  PaddleThemeDef get _t =>
      PaddleThemes.byId(_s.themeId, custom: _s.customTheme);

  @override
  void initState() {
    super.initState();
    _nameBottom = TextEditingController(text: _s.playerNames[0]);
    _nameTop = TextEditingController(text: _s.playerNames[1]);
    _store.init();
    _store.proPurchased.addListener(_onPro);
    _store.lastThanks.addListener(_onThanks);
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
      _store.lastThanks.value = null;
    }
  }

  void _onPro() {
    if (_store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      _store.proPurchased.value = false;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _store.lastThanks.removeListener(_onThanks);
    _store.proPurchased.removeListener(_onPro);
    _store.dispose();
    _nameBottom.dispose();
    _nameTop.dispose();
    super.dispose();
  }

  /// Real in-app review flow: the Play in-app review sheet when available,
  /// otherwise fall back to opening the store listing. No fake dialogs.
  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  void _play() {
    widget.audio.gameStart();
    final engine = PaddleEngine(
      difficulty: ClashDifficulty.values[_s.difficulty],
      twoPlayer: _s.mode == 'duo',
      nameBottom: _s.playerNames[0],
      nameTop: _s.mode == 'duo' ? _s.playerNames[1] : _aiName(),
    );
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => GameScreen(
        engine: engine,
        audio: widget.audio,
        settings: _s,
      ),
    ))
        .then((_) {
      if (mounted) widget.audio.startMenuMusic();
    });
  }

  String _aiName() {
    // In solo the top seat is the AI; its display name is the saved name.
    return _s.playerNames[1];
  }

  void _openPro() {
    widget.audio.click();
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => ProScreen(
            audio: widget.audio,
            settings: _s,
            store: _store,
          ),
        ))
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return WoodBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _s,
            builder: (_, _) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: t.accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          offset: const Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/paddleclash_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 14),
                  Text('Paddle Clash', style: ClashText.display(44, t: t)),
                  Text('THE ARCADE TABLE DUEL',
                      style: ClashText.label(12,
                          t: t, color: t.accentLight)),
                  const SizedBox(height: 22),
                  WoodButton(label: '▶  Play', onTap: _play, theme: t, width: 260),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _openPro,
                    child: Container(
                      width: 260,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(colors: [
                          t.accent.withValues(alpha: 0.9),
                          t.accentDark,
                        ]),
                        border:
                            Border.all(color: t.accentLight, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _s.isPro ? '✦  PRO ACTIVE' : '✦  Get PRO',
                        style: ClashText.label(17, t: t, color: t.woodDeep),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _ModeCard(theme: t, state: this),
                  const SizedBox(height: 14),
                  _PlayersCard(theme: t, state: this),
                  const SizedBox(height: 14),
                  _StyleCard(theme: t, state: this),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MenuIcon(
                        theme: t,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () async {
                          widget.audio.click();
                          await Share.share(
                              'Play Paddle Clash with me! $_storeUrl');
                        },
                      ),
                      const SizedBox(width: 22),
                      MenuIcon(
                        theme: t,
                        icon: Icons.star_rate,
                        label: 'Rate',
                        onTap: () async {
                          widget.audio.click();
                          await _requestReview();
                        },
                      ),
                      const SizedBox(width: 22),
                      MenuIcon(
                        theme: t,
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () async {
                          widget.audio.click();
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              audio: widget.audio,
                              settings: _s,
                            ),
                          ));
                          if (mounted) setState(() {});
                        },
                      ),
                      const SizedBox(width: 26),
                      MenuIcon(
                        theme: t,
                        icon: Icons.help_outline,
                        label: 'How to Play',
                        onTap: () {
                          widget.audio.click();
                          _showHowTo(context, t);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_s.gamesPlayed > 0)
                    Text(
                      'Wins: ${_s.wins}   •   Matches: ${_s.gamesPlayed}${_s.bestRally > 0 ? '   •   Best rally: ${_s.bestRally}' : ''}',
                      style: ClashText.label(12, t: t),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/wajiha_logo.png',
                          width: 22, height: 22, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Text('Credits: WAJIHA',
                          style: ClashText.label(12, t: t)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHowTo(BuildContext context, PaddleThemeDef t) {
    showDialog(
      context: context,
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('How to Play', style: ClashText.display(24, t: t)),
                const SizedBox(height: 12),
                for (final line in [
                  '• Drag to slide your paddle and smack the ball back.',
                  '• Solo: you are the BOTTOM paddle, the AI guards the top.',
                  '• 2 players: one drags the TOP half, one drags the BOTTOM half.',
                  '• Where the ball hits your paddle adds SPIN — aim with the edges!',
                  '• Every return gets faster. Long rallies feel amazing. 🔥',
                  '• Miss and your rival scores. First to 7 takes the match. 🏆',
                  '• Hard AI, pro themes, paddles and balls unlock with PRO.',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(line, style: ClashText.body(14, t: t)),
                  ),
                const SizedBox(height: 8),
                Center(
                  child: WoodButton(
                    label: 'Got it!',
                    onTap: () => Navigator.of(context).pop(),
                    theme: t,
                    width: 160,
                    small: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- mode card
class _ModeCard extends StatelessWidget {
  final PaddleThemeDef theme;
  final _MenuScreenState state;
  const _ModeCard({required this.theme, required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state._s;
    final t = theme;
    return PlaqueCard(
      theme: t,
      title: 'MATCH SETUP',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _modeBtn(t, s, '🤖  vs AI', 'solo')),
              const SizedBox(width: 10),
              Expanded(child: _modeBtn(t, s, '👥  2 Players', 'duo')),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('AI difficulty', style: ClashText.label(13, t: t)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _diffBtn(t, s, 'Easy', 0)),
              const SizedBox(width: 8),
              Expanded(child: _diffBtn(t, s, 'Medium', 1)),
              const SizedBox(width: 8),
              Expanded(child: _diffBtn(t, s, 'Hard 🔒', 2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeBtn(PaddleThemeDef t, ClashSettings s, String label, String mode) {
    final active = s.mode == mode;
    return GestureDetector(
      onTap: () {
        state.widget.audio.click();
        s.setMode(mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: active ? t.accent : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
              color: active ? t.accentLight : t.accent.withValues(alpha: 0.4)),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: ClashText.label(14,
                t: t, color: active ? t.woodDeep : t.ivory)),
      ),
    );
  }

  Widget _diffBtn(PaddleThemeDef t, ClashSettings s, String label, int d) {
    final active = s.difficulty == d;
    final locked = d == 2 && !s.isPro;
    return GestureDetector(
      onTap: () {
        if (locked) {
          state._openPro();
          return;
        }
        state.widget.audio.click();
        s.setDifficulty(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: active ? t.accent : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
              color: active ? t.accentLight : t.accent.withValues(alpha: 0.4)),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: ClashText.label(13,
                t: t,
                color: active
                    ? t.woodDeep
                    : t.ivory.withValues(alpha: locked ? 0.55 : 0.9))),
      ),
    );
  }
}

// ------------------------------------------------------------- players card
class _PlayersCard extends StatelessWidget {
  final PaddleThemeDef theme;
  final _MenuScreenState state;
  const _PlayersCard({required this.theme, required this.state});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final s = state._s;
    final solo = s.mode == 'solo';
    return PlaqueCard(
      theme: t,
      title: 'PLAYERS',
      child: Column(
        children: [
          _nameField(t, s, 0, solo ? 'You (bottom paddle)' : 'Bottom player',
              state._nameBottom),
          const SizedBox(height: 10),
          _nameField(t, s, 1, solo ? 'AI rival (top paddle)' : 'Top player',
              state._nameTop),
        ],
      ),
    );
  }

  Widget _nameField(PaddleThemeDef t, ClashSettings s, int index, String hint,
      TextEditingController ctl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(color: t.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctl,
              maxLength: 14,
              style: ClashText.body(15, t: t),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: ClashText.body(13,
                    t: t, color: t.ivory.withValues(alpha: 0.45)),
                border: InputBorder.none,
                counterText: '',
              ),
              onChanged: (v) => s.setPlayerName(index, v),
            ),
          ),
          Icon(Icons.edit, size: 16, color: t.accent.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- style card
class _StyleCard extends StatelessWidget {
  final PaddleThemeDef theme;
  final _MenuScreenState state;
  const _StyleCard({required this.theme, required this.state});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final s = state._s;
    return PlaqueCard(
      theme: t,
      title: 'TABLE & GEAR',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Theme', style: ClashText.label(13, t: t)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final th in PaddleThemes.all)
                _swatch(t, s, th.id, th.name, th.tableMid, th.accent,
                    locked: th.isPro && !s.isPro,
                    selected: s.themeId == th.id,
                    onTap: () => s.setTheme(th.id)),
              _swatch(t, s, 'custom', 'My Creation', s.customTheme.tableMid,
                  s.customTheme.accent,
                  locked: !s.isPro,
                  selected: s.themeId == 'custom',
                  onTap: () async {
                    if (!s.isPro) {
                      state._openPro();
                      return;
                    }
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CustomThemeScreen(
                        audio: state.widget.audio,
                        settings: s,
                      ),
                    ));
                  }),
            ],
          ),
          const SizedBox(height: 14),
          Text('Paddle style', style: ClashText.label(13, t: t)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final ps in PaddleStyles.all)
                _chip(t, s, ps.name,
                    locked: ps.isPro && !s.isPro,
                    selected: s.paddleStyleId == ps.id,
                    onTap: () => s.setPaddleStyle(ps.id)),
            ],
          ),
          const SizedBox(height: 14),
          Text('Ball style', style: ClashText.label(13, t: t)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final bs in BallStyles.all)
                _chip(t, s, bs.name,
                    locked: bs.isPro && !s.isPro,
                    selected: s.ballStyleId == bs.id,
                    onTap: () => s.setBallStyle(bs.id)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _swatch(
      PaddleThemeDef t,
      ClashSettings s,
      String id,
      String name,
      Color mid,
      Color accent,
      {required bool locked,
      required bool selected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        if (locked) {
          state._openPro();
          return;
        }
        state.widget.audio.click();
        onTap();
      },
      child: Container(
        width: 74,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: mid,
          border: Border.all(
              color: selected ? t.accentLight : accent.withValues(alpha: 0.4),
              width: selected ? 3 : 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                border: Border.all(
                    color: Colors.black.withValues(alpha: 0.3), width: 2),
              ),
              child: locked
                  ? const Icon(Icons.lock, size: 14, color: Colors.black54)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(name,
                style: ClashText.label(9, t: t),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _chip(PaddleThemeDef t, ClashSettings s, String name,
      {required bool locked,
      required bool selected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        if (locked) {
          state._openPro();
          return;
        }
        state.widget.audio.click();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? t.accent : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
              color: selected
                  ? t.accentLight
                  : t.accent.withValues(alpha: 0.4)),
        ),
        child: Text(
          locked ? '🔒 $name' : name,
          style: ClashText.label(12,
              t: t, color: selected ? t.woodDeep : t.ivory),
        ),
      ),
    );
  }
}
