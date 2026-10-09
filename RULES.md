# Paddle Clash — RULES.md

_The authoritative source of truth for Paddle Clash rules. If the
implementation conflicts with this document, fix the implementation._

## 1. Objective

Score points by smashing the ball past your rival's paddle. The first player
to reach **7 points** wins the match.

## 2. Setup

- The arena is a vertical table. Bottom paddle belongs to Player 1, top
  paddle belongs to Player 2 (AI rival in solo, second human in pass-and-play).
- Both paddles start centered. The ball starts at the center of the table.
- Player names are editable in the menu and persist between sessions.

## 3. Turn order

- There are no turns. Play is continuous and real-time.
- Each rally begins with a short "get ready" serve countdown (~1.1 s), then
  the ball launches toward the player who conceded the previous point.

## 4. Legal moves

- Drag (touch) to slide your paddle horizontally along its end of the table.
- In solo mode you control only the bottom paddle; the AI controls the top.
- In 2-player mode the top half of the screen drives the top paddle and the
  bottom half drives the bottom paddle.

## 5. Illegal moves

- Paddles cannot leave their end of the table or move vertically.
- Paddles cannot cross the center line.
- No input is accepted while the match is paused or over.

## 6. Captures

- Not applicable — there are no captures. A missed ball scores for the rival.

## 7. Special rules

- **Spin:** where the ball strikes the paddle steers the rebound. Hitting
  with the paddle's edge bends the shot up to ~60° off vertical; hitting
  dead-center returns it straight.
- **Rally speed-up:** every paddle return makes the ball ~4.5% faster, up to
  a hard cap. Long rallies get genuinely dangerous.
- **Rally milestones:** every 10th consecutive return triggers a fanfare.

## 8. Scoring

- If the ball exits the TOP of the table, the BOTTOM player scores 1 point.
- If the ball exits the BOTTOM of the table, the TOP player scores 1 point.
- After each goal there is a ~1.5 s celebration, then the next serve.

## 9. Winning conditions

- First player to **7 points** wins the match immediately.
- There is no deuce and no win-by-two: 7–6 is a legal final score.

## 10. Draw conditions

- Draws are impossible: every rally ends with exactly one goal, and play
  continues until someone reaches 7.

## 11. AI strategy

Three difficulties, all fully visible on the top paddle:

- **Easy:** chases the ball's current position with a slow capped speed and
  a large aim error. Beatable by angled shots.
- **Medium:** predicts the ball's arrival point at its paddle line with a
  moderate error, tracks at medium speed, and drifts home when the ball
  moves away.
- **Hard (PRO):** near-instant prediction including wall-bounce folding,
  very fast tracking, tiny error. Punishes lazy returns.

## 12. Edge cases

- Ball hitting a paddle exactly at its edge: counts as a return with maximum
  spin; never passes through.
- Ball hitting a side wall and a paddle in the same tick: the wall bounce is
  resolved first, then the paddle check.
- App backgrounded mid-rally: the engine freezes; on return the player
  resumes manually from the pause state — the watchdog guarantees the phase
  machine is never left in a half-advanced state.
- Ball stalled (no movement for 3 s during a rally, e.g. after a timer
  hiccup): the watchdog re-serves cleanly instead of freezing.

## 13. Test cases

1. Serve launches within ~1.1 s of match start and after every goal.
2. Ball rebounds off both side walls with a tick sound and particles.
3. Edge hits produce visibly angled returns; center hits go straight.
4. Ball speed increases with each return and never exceeds the cap.
5. Missing the ball awards the point to the rival and shows the celebration.
6. Score 7 ends the match; the victory overlay offers Rematch and Menu.
7. Pause → Resume continues the exact rally; Pause → Restart resets to 0–0.
8. Easy AI misses angled shots regularly; Hard AI returns almost everything.
9. Renamed players persist after app restart, in the correct seats.
10. Backgrounding the app mid-rally never freezes or crashes the match.
