---
name: p3-input-model
description: "Refactor phase P3 of the plate_number split — delete the deprecated LetterInputMode, collapse PlateSlotItem's nested input branching into one resolved SlotBehavior, and stop building a full ThemeData.light() per typed slot. Use when the user asks to run P3 or work on the input model."
---

# P3 — Input model

Follow `CLAUDE.md` working style. Requires **P2** committed. Finish analyzer-clean, tests
green, committed; report diffstat and hashes only.

## Why

Two problems, same area.

**One concept spelled twice.** `LetterInputMode` (`picker` / `keyboard` / `hostKeypad`) and
`PlateInputSource` (`system` / `hardwareKeyboard` / `packageKeypad` / `host`) describe the
same thing. The library ships both, plus `defaultLetterInputMode()`,
`inputSourceFromLetterMode()`, a `@Deprecated` `PlateCanvas.letterInputMode` parameter, a
`_letterInputMode` field, and a branch in `_resolveInputSource`. `PlateSlotItem.letterInputMode`
is declared and documented but **never read in its body** — verify this yourself with a grep
before deleting, then delete it.

**The same question asked five times.** "Is the IME suppressed for this slot?" is re-derived
in `_buildTypedField` (`readOnly`), again for `showCursor`, again for `keyboardType`, again as
a three-clause `if` in `_buildChosenSlot`, and again as a three-clause `onPressed` condition in
`plate_canvas.dart`. The answer depends on three inputs and never changes within a build.

## Do

### Delete the old mode

1. `lib/model/plate_number.dart`: delete `LetterInputMode` and `defaultLetterInputMode()`.
   Keep `PlateNumber` and `PlateMode`.
2. `lib/model/plate_input_source.dart`: delete `inputSourceFromLetterMode`. Keep
   `PlateInputSource` and `defaultInputSource()`.
3. `lib/widgets/plate_canvas.dart`: delete the `letterInputMode` parameter, the
   `_letterInputMode` field, both assignments to it, and the `letterInputMode != null` branch
   in `_resolveInputSource` — which then reduces to
   `widget.inputSource ?? defaultInputSource()`.
4. `lib/widgets/plate_slot_item.dart`: delete the `letterInputMode` parameter and field.
5. `plate_number_holder`: `lib/widgets/plate_display.dart` drops its `letterInputMode` field
   and the argument it forwards; remove the four remaining references across
   `showcase/` and `screens/`.

### Resolve behaviour once

6. New file `lib/model/slot_behavior.dart`:

```dart
/// What a slot does about input, resolved once from the three things that
/// decide it. Every rendering and gesture decision in [PlateSlotItem] is a
/// switch on this — none of them re-derives it from [PlateInputSource].
enum SlotBehavior {
  /// Read-only glyph. No focus node, no gestures. [PlateMode.display].
  glyph,

  /// TextField with the platform IME.
  imeField,

  /// TextField with the IME suppressed; physical key events are consumed.
  hardwareField,

  /// Focusable slot whose characters arrive from outside (package keypad or
  /// host). IME suppressed, cursor shown on focus, taps only claim focus.
  externalField,

  /// Tapping opens the character picker. Chosen alphabets under
  /// [PlateInputSource.system].
  sheet,
}

SlotBehavior resolveSlotBehavior({
  required PlateMode mode,
  required AlphabetInput input,
  required PlateInputSource source,
}) { … }
```

The mapping is exactly what the current code does, so port it rather than reasoning it out
fresh:

| mode | alphabet input | source | behavior |
|---|---|---|---|
| display | any | any | `glyph` |
| input | typed | system | `imeField` |
| input | typed | hardwareKeyboard | `hardwareField` |
| input | typed | packageKeypad / host | `externalField` |
| input | chosen | system | `sheet` |
| input | chosen | hardwareKeyboard | `hardwareField` |
| input | chosen | packageKeypad / host | `externalField` |

Note the row that is easy to lose: a **typed** slot under `hardwareKeyboard` today gets
`keyboardType: TextInputType.none` but stays a `TextField`, while a **chosen** slot under
`hardwareKeyboard` becomes a `Focus` with an `onKeyEvent` handler. Keep that difference —
`hardwareField` therefore still branches on `input` at the widget level. Do not "simplify" it
away; typing into a `TextField` with the IME suppressed is not the same as consuming raw key
events.

7. `PlateSlotItem` takes `required SlotBehavior behavior` in place of `mode` and
   `inputSource`. Its `build` becomes a single `switch (behavior)` with five arms and no
   nested ternaries. `readOnly`, `showCursor` and `keyboardType` each read the behavior
   directly.
8. `PlateCanvas` resolves the behavior per slot in `build` and passes it down. Its `onPressed`
   argument becomes `behavior == SlotBehavior.sheet ? () => _openPicker(i) : null`, and
   `_advance`'s picker branch uses the same call.

### While you are rewriting `_buildTypedField` anyway

`_buildTypedField` currently wraps its `TextField` in:

```dart
Theme(
  data: ThemeData.light().copyWith(
    textSelectionTheme: TextSelectionThemeData(...),
  ),
  child: ...
)
```

`ThemeData.light()` builds a complete Material theme — every color role, every component
theme, every default — to change three selection-related colors. This runs **per typed slot**,
so up to eight times per plate, on every rebuild that reaches a typed field. It also silently
forces light mode on that one `TextField` regardless of the host app's actual `Theme`, which is
plausibly deliberate (a plate's face is always white, so its cursor/selection colors
arguably shouldn't follow a dark host theme) but is currently undocumented as a decision — it
reads as an accident of "which constructor was easiest to reach for."

Fix both at once: build the `TextSelectionThemeData` override once, in `PlateCanvas.build`
(it depends only on `theme.activeColor`/`inactiveColor`, resolved once per canvas build, not
once per slot), and wrap the whole slot list in one `Theme` scope instead of each
`PlateSlotItem` wrapping itself. If keeping the light-mode pin is intentional, wrap with
`Theme(data: Theme.of(context).copyWith(textSelectionTheme: ...))` if the host theme should
still apply everywhere else, or keep `ThemeData.light()` but say why in a doc comment — don't
leave it unexplained. Either way, one `Theme` widget per plate instead of one per slot.

### Tests

9. New `test/slot_behavior_test.dart` covering the full table above — seven cases, no widget
   pumping. This is the point of the phase: the decision becomes testable.
10. `test/plate_canvas_test.dart` may construct `PlateSlotItem` directly — update it.

## Verify

```
cd plate-number-upgrade   && flutter analyze && flutter test
cd ../plate_number_holder && flutter analyze && flutter test
```

Then exercise all four sources in the holder: mobile (IME), desktop (host controller), tablet
(host + package keypad), and a manual `hardwareKeyboard` run on Linux — type into the Persian
letter slot with a physical keyboard and confirm it still consumes the key and does not open
the sheet. Separately, confirm the `Theme`/`TextSelectionThemeData` change is visually
identical — selection highlight and cursor color on a typed slot, before and after, side by
side.

Expected: ~60 net lines removed across both projects, and one `ThemeData.light()` construction
instead of up to eight.
