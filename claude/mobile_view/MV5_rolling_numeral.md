---
name: mv5-rolling-numeral
description: MV5 — replace the deck's static outlined "09" with RollingNumeral — an odometer column that charges with the 4 s dwell, rolls on advance, rewinds on wrap. Repaint-only, no per-frame rebuilds.
model: Opus 5.5, medium reasoning with thinking
---

# MV5 — Rolling outlined numeral ("Charge & Roll")

Read `mobile/feature_deck.dart` (only `_DeckNumeral` and the controller), tokens, and
`design/rolling_numeral_preview.html` (open it in a browser — it is the motion reference).

## The motion — four beats

| Beat | When | What |
|---|---|---|
| **Charge** | during the 4 s dwell | The **ones digit** fills from its baseline upward with accent @ ~14 % opacity, level = dwell progress. A 1.5 px accent **waterline** rides the fill level, clipped to the glyph, so only the outline segments at that height light up. The tens digit does not charge. |
| **Roll** | index +1 | Ones column rolls **up**: old digit exits to −0.62 h with opacity → 0, new digit enters from +0.62 h. 520 ms, `Curves.easeOutBack` (small overshoot, the outline "lands"). Fill resets to 0 under the new digit. |
| **Sweep** | during any roll | A diagonal light band (angle = the slashed-zero's slash, ≈ 62°) travels across the **stroke only** of both digits, left → right, via `ShaderMask(blendMode: srcATop)` with a moving `LinearGradient`. When it crosses the `0`, the slash glints. Echoes the poster's `SweepLight`. |
| **Rewind** | wrap n → 1 | Column spins **down** through every digit (9 → 8 → … → 1), 760 ms `Curves.easeInOutCubic` — a counter rewinding, not a jump. Backward taps (index −1) roll **down** with the same 520 ms spring. |

Extras: long-press pause → charge freezes and the waterline breathes (opacity 0.5 ↔ 1, 1.6 s).
`MediaQuery.disableAnimationsOf(context)` → 150 ms crossfade, no charge, no sweep.

## Generic, not "the second digit"
Format is `value.toString().padLeft(width, '0')` with `width = max(2, digits(n))`. Each column rolls
only when **its** digit changes, so 9 features animate only the ones column (the request), and 12 features
also roll the tens on 09 → 10. Charge always lives on the last column.

## Implementation — `mobile/rolling_numeral.dart`
- `RollingNumeral({required int value, required int count, required ValueListenable<double> dwell,
  required TextStyle style, bool paused})` — `StatefulWidget`, one `AnimationController` for the roll,
  one for the breathe (created lazily, only while paused).
- Per column a `double position`; the roll animates it from old to new digit (rewind: 9.0 → 1.0 straight
  down). Painter draws `floor(position)` and `ceil(position)` at the fractional offset, clipped to one
  row height.
- `_NumeralPainter extends CustomPainter` with `super(repaint: Listenable.merge([roll, dwell, breathe]))`
  — **the widget does not rebuild per frame**; only paint runs.
- **Cache 20 `TextPainter`s** (digits 0–9 × stroke/fill) laid out once in `didChangeDependencies` /
  when `style` or text scale changes. Never call `layout()` in `paint`.
- Stroke: `Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4` (take exact width from spec),
  colour = accent @ ~35 %. Slashed zero via `fontFeatures: [FontFeature.slashedZero()]` — if the spec's
  font lacks the feature, fall back to drawing the slash in the painter for `'0'` only.
- Charge clip: `canvas.clipRect(Rect.fromLTRB(0, h * (1 - p), w, h))` then paint the fill painter.
  Waterline: `clipRect` a 1.5 px band at that height, paint the stroke painter in full accent.
- Sweep: paint the stroke layer inside `saveLayer` + gradient `Paint(blendMode: srcATop)` — or wrap
  only the stroke layer in `ShaderMask`; keep whichever needs no tree-shape change.
- Wrap the whole thing in `RepaintBoundary`. Tree shape identical every frame, paused or not.

## Wiring (the only edit outside the new file)
In `feature_deck.dart`, `_DeckNumeral`'s body becomes `RollingNumeral(...)`, fed from the deck's
existing dwell controller (`controller.view` is already a `ValueListenable<double>`) and pause state.

## Out
Everything else in the deck. Progress bar, copy, sync.

## Verify
`flutter analyze`. Run in profile mode on Linux: through 3 advances + 1 wrap, the numeral contributes
no `build` time per frame in DevTools (paint only). Reduced-motion toggle → crossfade. Commit.

(SEE IF NEW BRANCH NEEDED OR NOT, IN BOTH SITUATIONS COMMIT YOUR WORK!)
