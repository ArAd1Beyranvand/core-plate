---
name: p3-input-model
description: "Refactor phase P3 of the plate_number split — delete the deprecated LetterInputMode, collapse PlateSlotItem's nested input branching into one resolved SlotBehavior, and stop building a full ThemeData.light() per typed slot. Use when the user asks to run P3 or work on the input model."
---

# P3 — Input model

Follow `CLAUDE.md` working style. Requires **P2** committed. This project does not use
automated tests — do not write or update anything under `test/`, and do not run
`flutter test`. Finish analyzer-clean, committed; report diffstat and hashes only.

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

**This section has changed since it was first written — read it before acting on memory of it.**
The original finding was that `_buildTypedField` built a full `ThemeData.light()` per typed
slot, up to eight per plate per build. That has already been fixed, by the animation
performance pass rather than by this phase: `plate_slot_item.dart` now opens with a
**library-level mutable cache**

```dart
final Map<Color, ThemeData> _selectionThemes = <Color, ThemeData>{};
ThemeData _selectionTheme(Color active) => _selectionThemes.putIfAbsent(active, () => ...);
```

so the expensive constructor runs two or three times for the life of the process instead of
per slot. The performance problem is gone. What is left is a design one, and it is squarely
this phase's business since you are rewriting the method anyway:

1. A package should not carry a process-wide mutable global that is never evicted. It is small
   and bounded in practice (a plate sees two or three active colours), but it is invisible
   shared state in a library, and the reason it exists is that the `Theme` was built at the
   wrong level of the tree.
2. The right level is the canvas. `theme.activeColor` / `inactiveColor` are resolved once per
   `PlateCanvas.build`, so build the `TextSelectionThemeData` there and wrap the whole slot
   list in **one** `Theme` scope, instead of each slot wrapping itself. Then delete
   `_selectionThemes` and `_selectionTheme` — with one construction per canvas build there is
   nothing left to cache.
3. Settle the light-mode pin while you are there. `ThemeData.light()` forces light on that
   `TextField` regardless of the host app's theme. That is plausibly deliberate — a plate's
   face is always white, so its cursor and selection colours arguably should not follow a dark
   host — but it is undocumented, and reads as an accident of which constructor was nearest.
   Either keep it and write one sentence saying why, or use
   `Theme.of(context).copyWith(textSelectionTheme: ...)` so the host theme still applies to
   everything else. Do not leave it unexplained a second time.

If step 2 turns out to regress the selection colours visually, keep the cache and say so —
but the expected outcome is one `Theme` per plate and no global.

## Widgets, not widget functions

`claude.md` §1 forbids widget-returning functions, and from here on every phase enforces it in
the files it already edits — here that means `PlateSlotItem._buildTypedField` and `_buildChosenSlot`, both of which this phase rewrites anyway. They become `_TypedField` and `_ChosenSlot` widget classes, each taking the resolved `SlotBehavior` — which is what makes the five-arm `switch (behavior)` in `build` read as five widgets rather than five branches of one method.

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

Then exercise all four sources in the holder: mobile (IME), desktop (host controller), tablet
(host + package keypad), and a manual `hardwareKeyboard` run on Linux — type into the Persian
letter slot with a physical keyboard and confirm it still consumes the key and does not open
the sheet. Separately, confirm the `Theme`/`TextSelectionThemeData` change is visually
identical — selection highlight and cursor color on a typed slot, before and after, side by
side.

Expected: ~60 net lines removed across both projects, the nested input branching replaced by
one `switch (behavior)`, and `plate_slot_item.dart`'s library-level `_selectionThemes` global
gone in favour of one `Theme` scope per canvas.
