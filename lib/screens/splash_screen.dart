import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/paddle_themes.dart';
import '../theme/paddle_ui.dart';
import 'menu_screen.dart';

/// Launch splash, two moments in one flow:
/// 1. WAJIHA company moment (official logo, gentle fade) — ~1.3 s.
/// 2. Game splash: game logo + name, animated loading line, audio prewarm,
///    "Credits: WAJIHA" with the company logo.
class SplashScreen extends StatefulWidget {
  final ClashAudio audio;
  final ClashSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _companyPhase = true;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Company moment: official WAJIHA logo on dark wood.
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() => _companyPhase = false);
    // Game splash: prewarm audio, start menu music, run the loading line.
    widget.audio.prewarm();
    widget.audio.startMenuMusic();
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaddleThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return Scaffold(
      backgroundColor: theme.woodDeep,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: _companyPhase ? _companyMoment() : _gameSplash(theme),
      ),
    );
  }

  /// Moment 1: the official WAJIHA company logo, untouched.
  Widget _companyMoment() {
    return Center(
      key: const ValueKey('company'),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 700),
        builder: (_, v, child) => Opacity(opacity: v, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/wajiha_logo.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 18),
            Text(
              'W A J I H A',
              style: ClashText.label(
                22,
                t: PaddleThemes.byId('classic'),
                color: const Color(0xFFE8CE7A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Moment 2: game logo + name + animated loading line + credits.
  Widget _gameSplash(PaddleThemeDef theme) {
    return WoodBackdrop(
      key: const ValueKey('game'),
      theme: theme,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.accent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: const Offset(0, 10),
                    blurRadius: 24,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/paddleclash_logo.png',
                  fit: BoxFit.cover),
            ),
            const SizedBox(height: 22),
            Text('Paddle Clash', style: ClashText.display(46, t: theme)),
            const SizedBox(height: 6),
            Text(
              'THE ARCADE TABLE DUEL',
              style: ClashText.label(13, t: theme, color: theme.accentLight),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: _loader,
                builder: (_, _) => Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.black.withValues(alpha: 0.45),
                        border: Border.all(
                            color: theme.accent.withValues(alpha: 0.5)),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _loader.value.clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              colors: [theme.accentLight, theme.accent],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _loader.value < 1
                          ? 'Chalking the paddles…'
                          : 'Ready!',
                      style: ClashText.body(13,
                          t: theme,
                          color: theme.ivory.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 44),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/wajiha_logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text('Credits: WAJIHA',
                    style: ClashText.label(14, t: theme)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
