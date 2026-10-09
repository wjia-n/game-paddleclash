import 'package:flutter/material.dart';
import 'paddle_themes.dart';

/// Shared text + widget styles for Paddle Clash. Everything physical:
/// wood plaques, brass buttons, engraved labels. No neon anywhere.
class ClashText {
  static TextStyle display(double size, {required PaddleThemeDef t}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: t.ivory,
        letterSpacing: 0.5,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.55),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      );

  static TextStyle label(double size, {required PaddleThemeDef t, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? t.ivory.withValues(alpha: 0.92),
        letterSpacing: 1.1,
      );

  static TextStyle body(double size, {required PaddleThemeDef t, Color? color}) =>
      TextStyle(
        fontSize: size,
        color: color ?? t.ivory.withValues(alpha: 0.85),
        height: 1.5,
      );
}

/// Physical room backdrop: deep wood with a subtle vignette.
class WoodBackdrop extends StatelessWidget {
  final PaddleThemeDef theme;
  final Widget child;
  const WoodBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.woodDeep,
            Color.lerp(theme.woodDeep, theme.tableEdge, 0.55)!,
            theme.woodDeep,
          ],
        ),
      ),
      child: child,
    );
  }
}

/// Brass-and-wood primary button.
class WoodButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final PaddleThemeDef theme;
  final double width;
  final bool small;
  const WoodButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.theme,
    this.width = 260,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(vertical: small ? 9 : 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.accentLight, theme.accent, theme.accentDark],
          ),
          border: Border.all(color: theme.ivory.withValues(alpha: 0.35), width: 2),
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
          label,
          style: ClashText.label(small ? 14 : 18, t: theme, color: theme.woodDeep),
        ),
      ),
    );
  }
}

/// Wood plaque card used on the menu.
class PlaqueCard extends StatelessWidget {
  final PaddleThemeDef theme;
  final String title;
  final Widget child;
  const PlaqueCard({super.key, required this.theme, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.tableMid, theme.tableDark],
        ),
        border: Border.all(color: theme.accent.withValues(alpha: 0.65), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ClashText.label(15, t: theme, color: theme.accentLight)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Small round icon button for the menu row.
class MenuIcon extends StatelessWidget {
  final PaddleThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const MenuIcon({
    super.key,
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.tableMid, theme.tableDark],
              ),
              border: Border.all(color: theme.accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(0, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Icon(icon, color: theme.accentLight, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: ClashText.label(11, t: theme)),
        ],
      ),
    );
  }
}
