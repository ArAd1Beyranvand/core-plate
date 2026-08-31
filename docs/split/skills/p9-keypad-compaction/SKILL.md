---
name: p9-keypad-compaction
description: "Refactor phase P9 of the plate_number split — collapse PlateKeypad's two near-identical key grids into one _KeyGrid widget and drop its dead copyWith. Use when the user asks to run P9 or work on the keypad."
---

# P9 — Keypad compaction

Follow `CLAUDE.md` working style. Requires **P8** committed (it removes the Persian defaults
this phase would otherwise preserve). Independent of everything else — touches
`lib/widgets/plate_keypad.dart` and nothing else in `lib/`.

This project does not use automated tests — do not write or update anything under `test/`,
and do not run `flutter test`. Finish analyzer-clean, committed; report diffstat and hashes
only.

## Why

`plate_keypad.dart` is **458 lines** (it was 408 when this phase was first written; the
performance pass added `highlightedKeyListenable` and its plumbing), the largest widget file in
the library, and it builds the same thing twice.

The digit pad walks a hardcoded `_rows` (`['1','2','3'] … ['','0','⌫']`) at 3 columns. The
letters pad derives `columns = sqrt(n).ceil()` from the alphabet and walks that. Both then run
the identical nested `Column`/`Row` with 6px gaps, both call `_keyEnabled`, both build a
`_Key` with the same four arguments. ~95 lines of the letters layer and ~35 of the digit layer
are the same loop.

`PlateKeypadTheme.copyWith` is 18 lines and **is never called** — grep both repos before
deleting to confirm it is still true.

### What the performance pass already did here — do not undo it

Three things in this file post-date the original phase text:

- `_slide` is now a `late final` field built once, not a fresh `Tween` + `CurvedAnimation` per
  `build`. Keep it that way.
- `PlateKeypad` takes both `highlightedKey` (a plain `String?`) and `highlightedKeyListenable`
  (a `ValueListenable<String?>`). When the listenable is supplied it wins and `highlightedKey`
  is ignored; each `_Key` subscribes for itself and decides its own lit state, so the grid's
  structure is built once and a press-flash rebuilds one key. The plain field stays for callers
  that do not flash rapidly.
- `_Key` therefore carries both `highlighted` (a bool) and `highlightListenable`, and every call
  site computes `highlighted: widget.highlightedKeyListenable == null && key == widget.highlightedKey`.

`_KeyGrid` must carry **both** inputs through unchanged — a grid that accepts only
`highlightedKey` would silently re-collapse the pad to one rebuild per flash, which is the
regression this file was profiled to remove. Better: give `_KeyGrid` the same pair and let it
pass them to `_Key` exactly as the two loops do today, rather than inventing a third
representation.

## Do

### One grid

```dart
/// A grid of keys built from a flat label list. Both pads are this widget:
/// the digit pad is a fixed 3-column list ending in the backspace key, the
/// letters pad is the active alphabet at a roughly square column count.
///
/// Layout invariant, carried over from the letters pad: [labels] and [columns]
/// alone decide the geometry. Enabledness never removes a key or changes the
/// column count, or the pad would reflow the moment a validation rule fires.
class _KeyGrid extends StatelessWidget {
  const _KeyGrid({
    required this.keys,        // canonical values; '' is a blank spacer
    required this.labels,      // what the user sees, same length as keys
    required this.columns,
    required this.rowHeight,
    required this.direction,
    required this.highlightedKey,         // plain fallback; ignored when the listenable is set
    required this.highlightListenable,    // ValueListenable<String?>?, the flash path
    required this.isEnabled,   // bool Function(String key)
    required this.onKey,
    required this.theme,
  });
  …
}
```

- Digit pad: `keys: ['1'…'9', '', '0', kPlateBackspaceKey]`, `columns: 3`,
  `direction: TextDirection.ltr`, `rowHeight: compact ? 44 : 56`.
- Letters pad: `keys: letterAlphabet.characters` padded to `rowCount * columns` with `''`,
  `columns: sqrt(n).ceil()`, `direction: letterAlphabet.direction` (from P8),
  `rowHeight: (innerHeight - 6 * (rowCount - 1)) / rowCount`.

Keep the fixed `innerHeight` computation in `build` — it is what stops the pad resizing when
the letters layer appears, and its comment says so.

### Push rendering into the label list

`_Key.digitAlphabet` exists only so a digit key can call `alphabet.render(label)` at paint
time, which is why `_Key` has a `label == '⌫' || digitAlphabet == null` ternary in its `Text`.
Build the display labels when building the list instead:

```dart
final labels = [
  for (final k in keys)
    k == kPlateBackspaceKey ? '⌫' : (k.isEmpty ? '' : digitAlphabet.render(k)),
];
```

That deletes the `digitAlphabet` parameter from `_Key`, its doc comment, and the ternary — and
it removes a real inconsistency: today the backspace key's canonical value is
`kPlateBackspaceKey` but its highlight comparison uses the raw `'⌫'` in `_Key` and `key` in
`_buildDigitKey`. After this change `highlightedKey` is compared against the canonical key
everywhere, which is what the holder passes.

### Keep exactly as-is

Do not touch, simplify or "improve":

- the slide animation (`kPlateKeypadSlide`, the `SlideTransition` + `AnimatedBuilder` +
  `IgnorePointer` stack)
- `_Key`'s three animation durations and the comment explaining why 90/160/180ms differ
- the highlighted-beats-disabled reasoning in `_Key`'s `enabled` doc
- `_keyEnabled`'s fallback from `activeAlphabet` to the pad's own alphabet

These are tuned behaviour, not incidental complexity.

## Do not

Do not move `PlateKeypad` into its own package yet. That is P12, after core exists — moving it
now means moving it twice.

## Widgets, not widget functions

`claude.md` §1 forbids widget-returning functions, and from here on every phase enforces it in
the files it already edits — here that is the whole point of the phase: `_buildDigitKey` and `_buildLettersLayer` are the two widget functions left in the library, and `_KeyGrid` below is their replacement. `_buildLettersLayer` also holds state-dependent layout maths, so hoist that into `_KeyGrid`'s own `build` rather than leaving a function that computes and a class that renders.

Convert each such method into a private `StatelessWidget` (or `StatefulWidget`) class. A real
widget gets its own element and its own rebuild scope, and can take a `const` constructor;
that is why every fix in the project's `ANIMATION_PERF` notes had to start by inventing one.

**Use judgement, and say so in the report.** Convert only where the class is not materially
longer than what it replaces. A three-line helper used once inside a single `build`, or one
that closes over five locals that would each become a constructor field, a `final` and an
argument, is clearer inlined into its caller than promoted to a class — inline it instead.
If a conversion would roughly double the lines it removes and buy no rebuild isolation, leave
it and name it in the report. Do not pad the codebase to satisfy a rule. Builder callbacks
(`BlocBuilder`, `AnimatedBuilder`, `LayoutBuilder`, `ValueListenableBuilder`) are not widget
functions and stay as they are.

## Verify

```
cd plate-core   && flutter analyze
cd ../plate_number_holder && flutter analyze
```

(Do not run `flutter test` — this project does not use automated tests.)

This project has no automated tests, so verification is visual and must be done at both sizes:

1. Tablet demo (full pad, `compact: false`): digit grid geometry unchanged, letters pad slides
   up flush with the digit pad's bottom edge, RTL letter order preserved for Persian and LTR
   for Latin.
2. Mobile demo (`compact: true`): 44px rows, same flush behaviour.
3. Type `8` in the German serial and confirm the second `8` greys out **without the grid
   reflowing** — that is the invariant most at risk in this phase.
4. Backspace key still highlights when the typist presses it — and, with "Highlight repaints"
   on, that flash must repaint the one key, not the grid. The listenable path is the thing most
   easily lost in this refactor and the thing `flutter analyze` will not notice.

Capture before/after screenshots of both pads and attach them to the commit.

Expected: 458 → ~365 lines, ~90 net removed, no behaviour change, and the two remaining
widget functions in the library gone.
