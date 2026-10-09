import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/paddle_themes.dart';
import '../theme/paddle_ui.dart';

/// PRO custom theme creator: pick physical colors for every table element.
/// Persisted per color key; preview updates live.
class CustomThemeScreen extends StatelessWidget {
  final ClashAudio audio;
  final ClashSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  static const List<Color> _swatches = [
    Color(0xFF6B4226),
    Color(0xFF8A5A33),
    Color(0xFF3B2416),
    Color(0xFF5A2418),
    Color(0xFF1E4D3B),
    Color(0xFF2E6B52),
    Color(0xFF1F3A52),
    Color(0xFF2F5578),
    Color(0xFF2A3350),
    Color(0xFF1C1A18),
    Color(0xFF4A4A52),
    Color(0xFF6E3B46),
    Color(0xFFC9A227),
    Color(0xFFD4AF37),
    Color(0xFFC0C6D4),
    Color(0xFFC87533),
    Color(0xFFF5EFE0),
    Color(0xFFF8F4E8),
    Color(0xFF2E1D0E),
    Color(0xFFA31621),
    Color(0xFF1D4E9E),
    Color(0xFF1B7A4D),
    Color(0xFFD99A2B),
    Color(0xFF7D3C98),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (_, _) {
        final t = settings.customTheme;
        return Scaffold(
          backgroundColor: t.woodDeep,
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
            title: Text('My Creation',
                style: ClashText.label(17, t: t)),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: () {
                  audio.click();
                  settings.resetCustomColors();
                },
                child: Text('Reset',
                    style: ClashText.label(14,
                        t: t, color: t.accentLight)),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Column(
                children: [
                  // Live preview plaque.
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(colors: [
                        t.tableMid,
                        t.tableDark,
                      ]),
                      border: Border.all(color: t.accent, width: 2),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 16,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: t.paddleTop,
                              border: Border.all(
                                  color: Colors.black26, width: 2),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: t.ball,
                              border: Border.all(
                                  color: Colors.black26, width: 2),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 56,
                            height: 16,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: t.paddleBottom,
                              border: Border.all(
                                  color: Colors.black26, width: 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final key in ClashSettings.customColorLabels)
                    _colorRow(t, key),
                  const SizedBox(height: 16),
                  WoodButton(
                    label: '✓  Use this theme',
                    onTap: () {
                      audio.click();
                      settings.setTheme('custom');
                      Navigator.of(context).pop();
                    },
                    theme: t,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _colorRow(PaddleThemeDef t, String key) {
    final current = Color(settings.customColors[key] ?? 0xFF000000);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: current,
                  border: Border.all(
                      color: t.accent.withValues(alpha: 0.6), width: 2),
                ),
              ),
              const SizedBox(width: 10),
              Text(_pretty(key), style: ClashText.label(14, t: t)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _swatches)
                GestureDetector(
                  onTap: () {
                    audio.click();
                    settings.setCustomColor(key, c.toARGB32());
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c,
                      border: Border.all(
                        color: current.toARGB32() == c.toARGB32()
                            ? t.accentLight
                            : Colors.black.withValues(alpha: 0.3),
                        width: current.toARGB32() == c.toARGB32() ? 3 : 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _pretty(String key) {
    final s = key.replaceAllMapped(
        RegExp(r'[A-Z]'), (m) => ' ${m.group(0)!.toLowerCase()}');
    return s[0].toUpperCase() + s.substring(1);
  }
}
