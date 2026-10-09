import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/paddle_themes.dart';
import '../theme/paddle_ui.dart';

/// Settings: music/SFX toggles, volume, stats reset.
class SettingsScreen extends StatelessWidget {
  final ClashAudio audio;
  final ClashSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  PaddleThemeDef get _t =>
      PaddleThemes.byId(settings.themeId, custom: settings.customTheme);

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
            icon: Icon(Icons.arrow_back, color: t.ivory),
            onPressed: () {
              audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Settings', style: ClashText.label(17, t: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: settings,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Column(
                children: [
                  PlaqueCard(
                    theme: t,
                    title: '🔊  AUDIO',
                    child: Column(
                      children: [
                        _toggle(t, 'Music', settings.musicOn, (v) {
                          settings.setMusic(v);
                          audio.configure(
                              musicOn: v,
                              sfxOn: settings.sfxOn,
                              volume: settings.volume);
                          if (v) {
                            audio.startMenuMusic();
                          } else {
                            audio.stopMusic();
                          }
                        }),
                        _toggle(t, 'Sound effects', settings.sfxOn, (v) {
                          settings.setSfx(v);
                          audio.configure(
                              musicOn: settings.musicOn,
                              sfxOn: v,
                              volume: settings.volume);
                          if (v) audio.click();
                        }),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.volume_up,
                                color: t.accentLight, size: 22),
                            Expanded(
                              child: Slider(
                                value: settings.volume,
                                onChanged: (v) {
                                  settings.setVolume(v);
                                  audio.configure(
                                      musicOn: settings.musicOn,
                                      sfxOn: settings.sfxOn,
                                      volume: v);
                                },
                                activeColor: t.accent,
                                inactiveColor:
                                    t.accent.withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  PlaqueCard(
                    theme: t,
                    title: '📊  STATS',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Matches played: ${settings.gamesPlayed}',
                            style: ClashText.body(14, t: t)),
                        const SizedBox(height: 4),
                        Text('Matches won: ${settings.wins}',
                            style: ClashText.body(14, t: t)),
                        const SizedBox(height: 4),
                        Text(
                            'Best rally: ${settings.bestRally > 0 ? settings.bestRally : '—'}',
                            style: ClashText.body(14, t: t)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            audio.click();
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: t.tableDark,
                                title: Text('Reset stats?',
                                    style: ClashText.label(16, t: t)),
                                content: Text(
                                    'Wins, matches and best rally go back to zero.',
                                    style: ClashText.body(14, t: t)),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text('Cancel',
                                        style: ClashText.label(14,
                                            t: t,
                                            color: t.accentLight)),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: Text('Reset',
                                        style: ClashText.label(14,
                                            t: t,
                                            color:
                                                const Color(0xFFE08080))),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) settings.resetStats();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFE08080), width: 1.5),
                            ),
                            child: Text('Reset stats',
                                style: ClashText.label(14,
                                    t: t,
                                    color: const Color(0xFFE08080))),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
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
                  const SizedBox(height: 8),
                  Text('Paddle Clash v2.0.0 • by Wajiha',
                      style: ClashText.body(12,
                          t: t, color: t.ivory.withValues(alpha: 0.55))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggle(PaddleThemeDef t, String label, bool value,
      ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: ClashText.body(15, t: t))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: t.accentLight,
          activeTrackColor: t.accentDark,
        ),
      ],
    );
  }
}
