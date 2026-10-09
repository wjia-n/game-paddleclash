import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/paddle_themes.dart';

/// Persisted settings + stats for Paddle Clash. Survives app restarts.
///
/// Stores: audio toggles, player names (2 seats), mode + difficulty, theme /
/// paddle / ball appearance choices (incl. custom theme colors), Pro unlock
/// state, and lifetime stats.
class ClashSettings extends ChangeNotifier {
  static const _kMusic = 'paddleclash_music_on';
  static const _kSfx = 'paddleclash_sfx_on';
  static const _kVolume = 'paddleclash_volume';
  static const _kMode = 'paddleclash_mode'; // 'solo' | 'duo'
  static const _kDifficulty = 'paddleclash_bot_difficulty'; // 0/1/2
  static const _kNames = 'paddleclash_player_names'; // legacy unordered key
  /// Order-safe player-name storage: a single JSON string. Android's
  /// SharedPreferences stores StringLists as an unordered StringSet, so the
  /// old key scrambled name order on every app restart. Never use a
  /// StringList for ordered data on Android.
  static const _kNamesJson = 'paddleclash_player_names_json';
  static const _kTheme = 'paddleclash_theme_id';
  static const _kPaddle = 'paddleclash_paddle_style';
  static const _kBall = 'paddleclash_ball_style';
  static const _kWins = 'paddleclash_wins';
  static const _kGames = 'paddleclash_games_played';
  static const _kBestRally = 'paddleclash_best_rally';
  static const _kIsPro = 'paddleclash_is_pro';
  static const _kCustomPrefix = 'paddleclash_custom_';

  static const defaultNames = ['Ace', 'Blitz'];

  /// Encode the 2 player names as one JSON string (order-preserving).
  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  static String _cleanName(int i, Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultNames[i] : s;
  }

  /// Decode persisted names; falls back to defaults on missing/corrupt data.
  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return List.of(defaultNames);
    try {
      final d = jsonDecode(raw);
      if (d is List && d.length == 2) {
        return [for (int i = 0; i < 2; i++) _cleanName(i, d[i])];
      }
    } catch (_) {}
    return List.of(defaultNames);
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  String mode = 'solo'; // 'solo' = vs AI, 'duo' = pass-and-play
  int difficulty = 1; // 0 easy, 1 medium, 2 hard (Pro)
  List<String> playerNames = List.of(defaultNames);
  String themeId = 'classic';
  String paddleStyleId = 'classic';
  String ballStyleId = 'classic';
  int wins = 0;
  int gamesPlayed = 0;
  int bestRally = 0; // longest rally ever (0 = none yet)
  bool isPro = false;

  /// Custom theme colors (ARGB ints). Defaults mirror Classic Oak.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'tableDark': 0xFF6B4226,
    'tableMid': 0xFF8A5A33,
    'tableLine': 0xFFF5EFE0,
    'tableEdge': 0xFF3E2412,
    'accent': 0xFFC9A227,
    'accentLight': 0xFFE8CE7A,
    'accentDark': 0xFF8A6D1A,
    'woodDeep': 0xFF241309,
    'ivory': 0xFFF5EFE0,
    'paddleBottom': 0xFFA31621,
    'paddleTop': 0xFF1D4E9E,
    'ball': 0xFFF8F4E8,
  };

  static const List<String> customColorLabels = [
    'tableDark',
    'tableMid',
    'tableLine',
    'tableEdge',
    'accent',
    'accentLight',
    'accentDark',
    'woodDeep',
    'ivory',
    'paddleBottom',
    'paddleTop',
    'ball',
  ];

  /// Builds the user-designed custom theme from stored colors.
  PaddleThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return PaddleThemeDef(
      id: 'custom',
      name: 'My Creation',
      tableDark: c('tableDark'),
      tableMid: c('tableMid'),
      tableLine: c('tableLine'),
      tableEdge: c('tableEdge'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      accentDark: c('accentDark'),
      woodDeep: c('woodDeep'),
      ivory: c('ivory'),
      paddleBottom: c('paddleBottom'),
      paddleTop: c('paddleTop'),
      ball: c('ball'),
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    mode = p.getString(_kMode) == 'duo' ? 'duo' : 'solo';
    difficulty = (p.getInt(_kDifficulty) ?? 1).clamp(0, 2);
    // Player names: prefer the order-safe JSON key. Fall back to the legacy
    // StringList key once (one-time migration); it may already be scrambled
    // on Android, which is exactly the bug this replaces.
    final namesRaw = p.getString(_kNamesJson);
    if (namesRaw != null) {
      playerNames = decodePlayerNames(namesRaw);
    } else {
      final legacy = p.getStringList(_kNames);
      playerNames = (legacy != null && legacy.length == 2)
          ? [for (int i = 0; i < 2; i++) _cleanName(i, legacy[i])]
          : List.of(defaultNames);
    }
    themeId = p.getString(_kTheme) ?? 'classic';
    paddleStyleId = p.getString(_kPaddle) ?? 'classic';
    ballStyleId = p.getString(_kBall) ?? 'classic';
    wins = p.getInt(_kWins) ?? 0;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    bestRally = p.getInt(_kBestRally) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] = p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setString(_kMode, mode);
    await p.setInt(_kDifficulty, difficulty);
    await p.setString(_kNamesJson, encodePlayerNames(playerNames));
    await p.remove(_kNames); // drop the legacy unordered key for good
    await p.setString(_kTheme, themeId);
    await p.setString(_kPaddle, paddleStyleId);
    await p.setString(_kBall, ballStyleId);
    await p.setInt(_kWins, wins);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kBestRally, bestRally);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || PaddleThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (PaddleStyles.isPro(paddleStyleId)) {
      paddleStyleId = 'classic';
      changed = true;
    }
    if (BallStyles.isPro(ballStyleId)) {
      ballStyleId = 'classic';
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setMode(String m) async {
    mode = m == 'duo' ? 'duo' : 'solo';
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int d) async {
    d = d.clamp(0, 2);
    if (!isPro && d > 1) return; // Hard is a Pro feature
    difficulty = d;
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(int index, String name) async {
    if (index < 0 || index > 1) return;
    final clean = name.trim();
    playerNames[index] = clean.isEmpty ? defaultNames[index] : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || PaddleThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setPaddleStyle(String id) async {
    if (!isPro && PaddleStyles.isPro(id)) return;
    paddleStyleId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setBallStyle(String id) async {
    if (!isPro && BallStyles.isPro(id)) return;
    ballStyleId = id;
    notifyListeners();
    await _save();
  }

  /// Record a finished match. [humanWon] true if the bottom human won;
  /// [rally] is the longest rally of this match.
  Future<void> recordMatch({required bool humanWon, required int rally}) async {
    gamesPlayed++;
    if (humanWon) wins++;
    if (rally > bestRally) bestRally = rally;
    notifyListeners();
    await _save();
  }

  Future<void> resetStats() async {
    wins = 0;
    gamesPlayed = 0;
    bestRally = 0;
    notifyListeners();
    await _save();
  }
}
