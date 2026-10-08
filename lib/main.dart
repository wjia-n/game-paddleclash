import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const PaddleClashApp());

class PaddleClashApp extends StatelessWidget {
  const PaddleClashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.cozyPaper,
      title: 'Paddle Clash',
      tagline: 'The original arcade duel, now with spin and power shots!',
      emoji: '🏓',
      slug: 'paddleclash',
      howToPlay:
          '• Drag your paddle left and right to smack the ball back.\n• Solo: you\'re the bottom paddle, the bot guards the top.\n• 2 players: one drags the TOP half, one drags the BOTTOM half.\n• Where the ball hits your paddle adds SPIN — aim with the edges!\n• Miss and your rival scores. First to 7 takes the match. 🏆',
      playerOptions: const [1, 2],
      supportsBots: true,
      gameBuilder: (ctx, players, cb) => PaddleClashScreen(players: players, callbacks: cb),
    );
  }
}
