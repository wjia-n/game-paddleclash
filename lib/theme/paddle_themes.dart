import 'package:flutter/material.dart';

/// Theme, paddle-style and ball-style catalogs for Paddle Clash.
///
/// The art direction is a physical table-tennis hall: polished wood tables,
/// rubber-faced wooden paddles, cork/leather balls, brass trim. Variety comes
/// from different woods, felt linings, rubber tints and metal accents —
/// never neon, never cyberpunk.
class PaddleThemeDef {
  final String id;
  final String name;
  final bool isPro;
  final Color tableDark;
  final Color tableMid;
  final Color tableLine;
  final Color tableEdge;
  final Color accent;
  final Color accentLight;
  final Color accentDark;
  final Color woodDeep;
  final Color ivory;
  final Color paddleBottom;
  final Color paddleTop;
  final Color ball;

  const PaddleThemeDef({
    required this.id,
    required this.name,
    this.isPro = false,
    required this.tableDark,
    required this.tableMid,
    required this.tableLine,
    required this.tableEdge,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.woodDeep,
    required this.ivory,
    required this.paddleBottom,
    required this.paddleTop,
    required this.ball,
  });
}

class PaddleThemes {
  /// First 4 are FREE. The rest are PRO.
  static const List<String> freeThemeIds = [
    'classic',
    'mahogany',
    'emerald',
    'midnight',
  ];

  static const List<PaddleThemeDef> all = [
    PaddleThemeDef(
      id: 'classic',
      name: 'Classic Oak',
      tableDark: Color(0xFF6B4226),
      tableMid: Color(0xFF8A5A33),
      tableLine: Color(0xFFF5EFE0),
      tableEdge: Color(0xFF3E2412),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      woodDeep: Color(0xFF241309),
      ivory: Color(0xFFF5EFE0),
      paddleBottom: Color(0xFFA31621),
      paddleTop: Color(0xFF1D4E9E),
      ball: Color(0xFFF8F4E8),
    ),
    PaddleThemeDef(
      id: 'mahogany',
      name: 'Royal Mahogany',
      tableDark: Color(0xFF5A2418),
      tableMid: Color(0xFF7A3626),
      tableLine: Color(0xFFF8F1E2),
      tableEdge: Color(0xFF351410),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      accentDark: Color(0xFF96702A),
      woodDeep: Color(0xFF2B1009),
      ivory: Color(0xFFF8F1E2),
      paddleBottom: Color(0xFFC0392B),
      paddleTop: Color(0xFF7D3C98),
      ball: Color(0xFFF6EFDD),
    ),
    PaddleThemeDef(
      id: 'emerald',
      name: 'Emerald Club',
      tableDark: Color(0xFF1E4D3B),
      tableMid: Color(0xFF2E6B52),
      tableLine: Color(0xFFF2EFE2),
      tableEdge: Color(0xFF12291F),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      woodDeep: Color(0xFF0E1F17),
      ivory: Color(0xFFF2EFE2),
      paddleBottom: Color(0xFF1B7A4D),
      paddleTop: Color(0xFFD99A2B),
      ball: Color(0xFFF8F4E8),
    ),
    PaddleThemeDef(
      id: 'midnight',
      name: 'Midnight Library',
      tableDark: Color(0xFF2A3350),
      tableMid: Color(0xFF3D4A6E),
      tableLine: Color(0xFFEDE8D8),
      tableEdge: Color(0xFF171C30),
      accent: Color(0xFFC0C6D4),
      accentLight: Color(0xFFE8ECF5),
      accentDark: Color(0xFF7E8698),
      woodDeep: Color(0xFF101424),
      ivory: Color(0xFFEDE8D8),
      paddleBottom: Color(0xFFD64545),
      paddleTop: Color(0xFF4A90D9),
      ball: Color(0xFFF4EFE0),
    ),
    // ---- PRO themes ----
    PaddleThemeDef(
      id: 'walnut',
      name: 'Black Walnut',
      isPro: true,
      tableDark: Color(0xFF3B2A1E),
      tableMid: Color(0xFF54402E),
      tableLine: Color(0xFFF0E8D6),
      tableEdge: Color(0xFF211510),
      accent: Color(0xFFB08D57),
      accentLight: Color(0xFFD9BC85),
      accentDark: Color(0xFF7A5F36),
      woodDeep: Color(0xFF170F0A),
      ivory: Color(0xFFF0E8D6),
      paddleBottom: Color(0xFF8C2F2F),
      paddleTop: Color(0xFF2F5D8C),
      ball: Color(0xFFF2EBD8),
    ),
    PaddleThemeDef(
      id: 'maple',
      name: 'Honey Maple',
      isPro: true,
      tableDark: Color(0xFF9C6B3C),
      tableMid: Color(0xFFB98A52),
      tableLine: Color(0xFF2E1D0E),
      tableEdge: Color(0xFF6E4A26),
      accent: Color(0xFF8A5A1E),
      accentLight: Color(0xFFC99A55),
      accentDark: Color(0xFF5E3C12),
      woodDeep: Color(0xFF2E1D0E),
      ivory: Color(0xFF2E1D0E),
      paddleBottom: Color(0xFFB03A2E),
      paddleTop: Color(0xFF1F6F8B),
      ball: Color(0xFFFFFBF0),
    ),
    PaddleThemeDef(
      id: 'cherry',
      name: 'Cherry Blossom',
      isPro: true,
      tableDark: Color(0xFF6E3B46),
      tableMid: Color(0xFF8F5560),
      tableLine: Color(0xFFF9EFE8),
      tableEdge: Color(0xFF42222A),
      accent: Color(0xFFD9A5A0),
      accentLight: Color(0xFFF2CFC8),
      accentDark: Color(0xFF9A6E68),
      woodDeep: Color(0xFF33161C),
      ivory: Color(0xFFF9EFE8),
      paddleBottom: Color(0xFFB03060),
      paddleTop: Color(0xFF4A6FA5),
      ball: Color(0xFFFBF3EA),
    ),
    PaddleThemeDef(
      id: 'ebony',
      name: 'Piano Ebony',
      isPro: true,
      tableDark: Color(0xFF1C1A18),
      tableMid: Color(0xFF2E2A26),
      tableLine: Color(0xFFE8E0CC),
      tableEdge: Color(0xFF0C0B0A),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      woodDeep: Color(0xFF080707),
      ivory: Color(0xFFE8E0CC),
      paddleBottom: Color(0xFFC0392B),
      paddleTop: Color(0xFF2980B9),
      ball: Color(0xFFF5F0E0),
    ),
    PaddleThemeDef(
      id: 'ocean',
      name: 'Deep Ocean',
      isPro: true,
      tableDark: Color(0xFF1F3A52),
      tableMid: Color(0xFF2F5578),
      tableLine: Color(0xFFF0EDE2),
      tableEdge: Color(0xFF122335),
      accent: Color(0xFF7FB3D5),
      accentLight: Color(0xFFAED6F1),
      accentDark: Color(0xFF4A7BA6),
      woodDeep: Color(0xFF0D1826),
      ivory: Color(0xFFF0EDE2),
      paddleBottom: Color(0xFFE67E22),
      paddleTop: Color(0xFF1ABC9C),
      ball: Color(0xFFF6F2E6),
    ),
    PaddleThemeDef(
      id: 'forest',
      name: 'Pine Forest',
      isPro: true,
      tableDark: Color(0xFF2E4028),
      tableMid: Color(0xFF465C3A),
      tableLine: Color(0xFFF2EEDC),
      tableEdge: Color(0xFF1A2416),
      accent: Color(0xFFD4A24E),
      accentLight: Color(0xFFF0C97E),
      accentDark: Color(0xFF96682E),
      woodDeep: Color(0xFF121A0E),
      ivory: Color(0xFFF2EEDC),
      paddleBottom: Color(0xFFA93226),
      paddleTop: Color(0xFF7D6608),
      ball: Color(0xFFF7F1DE),
    ),
    PaddleThemeDef(
      id: 'copper',
      name: 'Copper Workshop',
      isPro: true,
      tableDark: Color(0xFF5C3A28),
      tableMid: Color(0xFF7C5238),
      tableLine: Color(0xFFF5ECDC),
      tableEdge: Color(0xFF38220F),
      accent: Color(0xFFC87533),
      accentLight: Color(0xFFE8A56B),
      accentDark: Color(0xFF8A4F20),
      woodDeep: Color(0xFF241408),
      ivory: Color(0xFFF5ECDC),
      paddleBottom: Color(0xFF943126),
      paddleTop: Color(0xFF2E6B62),
      ball: Color(0xFFF6EFDD),
    ),
    PaddleThemeDef(
      id: 'marble',
      name: 'Marble Hall',
      isPro: true,
      tableDark: Color(0xFF4A4A52),
      tableMid: Color(0xFF64646E),
      tableLine: Color(0xFFF6F2E6),
      tableEdge: Color(0xFF2C2C33),
      accent: Color(0xFFD4C9A8),
      accentLight: Color(0xFFF0EAD6),
      accentDark: Color(0xFF948B6E),
      woodDeep: Color(0xFF17171B),
      ivory: Color(0xFFF6F2E6),
      paddleBottom: Color(0xFF7B2D26),
      paddleTop: Color(0xFF2C5F7C),
      ball: Color(0xFFFBF8EE),
    ),
  ];

  static PaddleThemeDef byId(String id, {PaddleThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }

  static bool isProTheme(String id) =>
      id != 'custom' && byId(id).isPro;
}

/// Paddle (racket) style catalog. Drawn physically: wooden blade, rubber
/// face, edge band, handle. Last 4 are PRO.
class PaddleStyleDef {
  final String id;
  final String name;
  final bool isPro;
  final bool oval;
  final bool arc;
  final double corner; // 0 sharp .. 1 fully round
  final double widthScale;
  final bool handle;

  const PaddleStyleDef({
    required this.id,
    required this.name,
    this.isPro = false,
    this.oval = false,
    this.arc = false,
    this.corner = 0.5,
    this.widthScale = 1.0,
    this.handle = false,
  });
}

class PaddleStyles {
  static const List<PaddleStyleDef> all = [
    PaddleStyleDef(id: 'classic', name: 'Classic Blade', corner: 0.45),
    PaddleStyleDef(id: 'defender', name: 'Wide Defender', corner: 0.6, widthScale: 1.15),
    PaddleStyleDef(id: 'striker', name: 'Slim Striker', corner: 0.3, widthScale: 0.85),
    PaddleStyleDef(id: 'vintage', name: 'Vintage Oval', oval: true, handle: true),
    PaddleStyleDef(id: 'arc', name: 'Curved Arc', isPro: true, arc: true, corner: 0.5),
    PaddleStyleDef(id: 'wing', name: 'Aero Wing', isPro: true, corner: 0.15, widthScale: 1.1),
    PaddleStyleDef(id: 'carbon', name: 'Carbon Edge', isPro: true, corner: 0.1, widthScale: 0.95),
    PaddleStyleDef(id: 'gold', name: 'Golden Grand', isPro: true, oval: true, handle: true, widthScale: 1.05),
  ];

  static const List<String> names = [
    'Classic Blade', 'Wide Defender', 'Slim Striker', 'Vintage Oval',
    'Curved Arc', 'Aero Wing', 'Carbon Edge', 'Golden Grand',
  ];

  static PaddleStyleDef byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return all.first;
  }

  static bool isPro(String id) => byId(id).isPro;
}

/// Ball style catalog. Drawn physically with radial shading. Last 4 are PRO.
class BallStyleDef {
  final String id;
  final String name;
  final bool isPro;
  const BallStyleDef({required this.id, required this.name, this.isPro = false});
}

class BallStyles {
  static const List<BallStyleDef> all = [
    BallStyleDef(id: 'classic', name: 'Classic White'),
    BallStyleDef(id: 'red', name: 'Red Rubber'),
    BallStyleDef(id: 'cork', name: 'Natural Cork'),
    BallStyleDef(id: 'leather', name: 'Tan Leather'),
    BallStyleDef(id: 'marble', name: 'Swirl Marble', isPro: true),
    BallStyleDef(id: 'wood', name: 'Polished Wood', isPro: true),
    BallStyleDef(id: 'gold', name: 'Golden Trophy', isPro: true),
    BallStyleDef(id: 'comet', name: 'Comet Trail', isPro: true),
  ];

  static const List<String> names = [
    'Classic White', 'Red Rubber', 'Natural Cork', 'Tan Leather',
    'Swirl Marble', 'Polished Wood', 'Golden Trophy', 'Comet Trail',
  ];

  static BallStyleDef byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return all.first;
  }

  static bool isPro(String id) => byId(id).isPro;
}
