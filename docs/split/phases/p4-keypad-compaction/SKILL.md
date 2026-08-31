---
name: p4-keypad-compaction
description: "Phase P4 of the plate split (second edition) — collapse PlateKeypad's two hand-written grids into one _KeyGrid widget, carrying both highlight paths and the layout invariant through. Use when the user asks to run P4 or work on the keypad."
---

# P4 — Keypad compaction

Follow `CLAUDE.md` working style. **Requires P2 and P3 committed** — P2 removes
`unavailableKeys` (so the grid does not have to carry it) and P3 removes the Persian defaults
and the RTL sniff (so the grid does not re-introduce them). Running this before either means
doing the work twice.

This project does not use automated tests: do not write or update anything under `test/`, and
do not run `flutter test`. Finish analyzer-clean in both repos, committed; report diffstat and
hashes only.

**One file.** `lib/widgets/plate_keypad.dart`. If this phase touches a second file in `lib/`,
something is wrong — report it rather than following the thread.

## Why

`plate_keypad.dart` is ~460 lines and builds two grids that differ in data, not in kind:

| | digits | letters |
|---|---|---|
| built by | `_buildDigitKey` (widget function) | `_buildLettersLayer` (widget function) |
| source list | a fixed layout including `'⌫'` | `letterAlphabet.characters`, padded to a rectangle |
| columns | fixed | `sqrt(n).ceil()` |
| rendering | labels go through `digitAlphabet` | labels verbatim |
| direction | LTR | from the alphabet (after P3) |

Both then build the same `_Key` with the same enabled/highlight logic. `claude.md` §2 —
variation is data, not code — says that is one widget parameterised by a record, and §1 says it
is not a function.

## Do

1. **`_KeyGrid`**, a private `StatelessWidget`, replaces both. Give it exactly the parameters
   the table above says differ: the list of key labels (already padded with `''` spacers by the
   caller, or padded internally — pick one and be consistent), the column count, the row height
   or the inner height to divide, the `TextDirection`, the optional `PlateAlphabet` that labels
   render through (null = verbatim), plus the theme and the callbacks. Nothing else.

2. **Carry both highlight paths through.** This is the part that is easy to get wrong.
   `_Key` currently accepts *either* a plain `highlighted` bool *or* a
   `highlightListenable` + `highlightKey` pair, and picks between them:

   ```dart
   highlighted: widget.highlightedKeyListenable == null &&
       rawLabel.isNotEmpty && key == widget.highlightedKey,
   highlightListenable: widget.highlightedKeyListenable,
   highlightKey: key,
   ```

   The listenable path exists so a rapid press-flash rebuilds one key instead of the grid — it
   came out of the animation performance pass and **must not be collapsed into the simpler
   path for tidiness.** `_KeyGrid` passes both through unchanged. If the resulting constructor
   looks redundant, that redundancy is the optimisation.

3. **Keep the layout invariant, and keep it stated.** `_buildLettersLayer` carries a comment
   (rewritten in P2) explaining that `columns`/`rowCount` derive from
   `letterAlphabet.characters.length` alone, and that `activeAlphabet` must never narrow the
   list the grid is built from — it only affects whether an already-placed key renders enabled
   — or the pad reflows when the active slot changes. That comment moves onto `_KeyGrid`, where
   it now governs both grids. It is the single most load-bearing sentence in the file.

4. **Keep the spacer behaviour.** The final letters row is padded with `''` entries so every
   row has the same width, and `_Key` returns `SizedBox.shrink()` for an empty label *before*
   subscribing to anything, so spacer cells never listen. Preserve both halves.

5. **Keep the tuned durations.** 90 ms highlight in, 160 ms out, 180 ms for the
   enabled↔disabled fade. These are deliberate. Do not "simplify" them to one value, and do not
   change the `AnimatedScale` 0.94 press scale.

6. **`_keyEnabled` stays as P2 left it** — backspace always enabled, everything else
   `(activeAlphabet ?? ownAlphabet).accepts(key)`. There is no validation input any more. If
   you find one, P2 was not run.

7. `PlateKeypadTheme.copyWith` is dead (never called anywhere) but **it is P6's**, not this
   phase's — `claude.md` §5, scope. Note it in the report if you like; do not delete it here.

8. Do not change the public API. `PlateKeypad`'s constructor parameters, `PlateKeypadTheme`,
   `kPlateBackspaceKey` and `kPlateKeypadSlide` are the contract, and P7 moves them into their
   own package unchanged. This phase is internal only.

## Widgets, not widget functions

Per `PLAN.md` §5. This phase is the one where the rule pays for itself: `_buildDigitKey` and
`_buildLettersLayer` are both widget functions and `_KeyGrid` is their replacement, so the
conversion is not an aside — it is the phase. If any *other* helper in this file is a widget
function, apply the judgement rule to it and say in the report what you converted and what you
deliberately left inline.

## Verify

```
cd plate-core            && flutter analyze
cd ../plate_number_holder && flutter analyze
```

(Do not run `flutter test`.)

Then run the showcase and check the keypad specifically — a compaction that changes layout is
a failed compaction:

1. **Full pad (tablet).** Digit grid and letter grid end flush with each other, same as before.
   Count the letter columns: a 26-letter alphabet must still lay out `sqrt(26).ceil() = 6`
   columns.
2. **Compact pad (bicycle).** Persian digits, RTL letters, still flush.
3. **Press flash.** Hold a key: only that key scales and lightens; the grid does not flicker.
   If the whole pad visibly rebuilds on a press, the listenable path was collapsed — step 2.
4. **Alphabet narrowing.** Move the active slot from a digit slot to a letter slot and back.
   Keys outside the active alphabet grey out **in place**. If the grid reflows or changes
   column count, the invariant in step 3 was lost.
5. Nothing goes red and nothing is barred — that is P2's behaviour and this phase must not
   disturb it.

Expected: ~90 lines out of `plate_keypad.dart`, two widget functions gone, no visual or
behavioural change whatsoever.
