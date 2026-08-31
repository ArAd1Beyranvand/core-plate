---
name: p5-value-semantics
description: "Refactor phase P5 of the plate_number split — put equality where it is load-bearing (fixing a real context.select rebuild bug), collapse hand-written == and hashCode, and drop single-field copyWith. Use when the user asks to run P5 or work on value semantics."
---

# P5 — Value semantics

Follow `CLAUDE.md` working style. Requires **P4** committed. This project does not use
automated tests — do not write or update anything under `test/`, and do not run
`flutter test`. Finish analyzer-clean, committed; report diffstat and hashes only.

## Why

Equality in this library is exactly backwards: it is hand-written at length where it does not
matter, and absent where the framework depends on it.

**Absent where it matters.** This was the phase's headline finding and **half of it has already
been fixed elsewhere** — check the tree before you write the commit message.

`PlateNumber` now has `==`/`hashCode` over `values` (`listEquals` + `Object.hashAll`), added by
the animation performance pass along with the deeper fix: `PlateCanvas.build` no longer
`context.select`s the whole `PlateNumber` at all. `_FrameBinding` selects `isCompleted` and
`_SlotBinding` selects its own `String?`, so a keystroke rebuilds one slot. Both the equality
and the rebuild bug are done. **Do not re-add `PlateNumber.==`, do not reintroduce a
whole-value `select`, and do not claim the rebuild fix in this phase's commit message.**

What is left of the finding is real and untouched:

- `PlateCardState` still has no `==` (step 2).
- `PlateAlphabet` still has no `==` (step 3) — so
  `plate_keypad.dart`'s `letterAlphabet == PlateAlphabet.persianPlateLetters` is an identity
  check that silently fails for any caller who builds an equal alphabet inline. (P8 deletes
  that comparison, but `activeAlphabet` comparisons remain.)
- `PlateNumber.copyWith` still exists and still has its two call sites (step 1).

**Written at length where it does not.** `PlateSlot` (removed in P1), `PlateCountry` and
`PlateTheme` carry ~120 lines of field-by-field `==` and `hashCode`, and `PlateCountry` ships
its own `_listEquals` because `package:flutter/foundation.dart`'s was not imported.

## Do

### Add equality where the framework needs it

1. `lib/model/plate_number.dart` — `PlateNumber`'s `==`/`hashCode` over `values` are **already
   there**; leave them, including the doc comment explaining what they fixed. The remaining work
   in this file is deleting `copyWith`. It has one field and
   **two** call sites — grep before you delete, both must move in this commit:
   - `lib/bloc/plate_card_bloc.dart`, the production call, becomes `PlateNumber(values: values)`.
     This project does not use automated tests, so there is no `test/` call site to update —
     just confirm with a grep that `PlateNumber.copyWith` has no other production callers before
     deleting it.
2. `lib/bloc/plate_card_state.dart` — `PlateCardState` gets `==`/`hashCode` over
   `(plateNumber, spec)`. `PlateSpec` equality is `id`-based, so this is cheap.
3. `lib/model/plate_alphabet.dart` — add `final String id;` as the first required field and
   define `==`/`hashCode` on `id` alone. Give the four constants their obvious ids
   (`'latin.digits'`, `'fa.digits'`, `'fa.plateLetters'`, `'latin.upper'`). Document that ids
   must be unique, the same contract `PlateSpec.id` already carries.

   Add an `assert` in `debugValidateSpec` that no two distinct alphabet ids in one spec share
   a `characters` list, and no one id appears with two different character lists.

### Collapse the equality that is left

4. `lib/model/plate_country.dart` — replace the field-by-field `==`, the `hashCode` and
   `_listEquals` with `==`/`hashCode` on `code`. Delete `_listEquals` entirely.
5. `lib/theme/plate_theme.dart` — `PlateTheme` genuinely needs structural `==`
   (`PlateThemeScope.updateShouldNotify`, `_PlateFramePainter.shouldRepaint`). Keep it, but
   express it once:

```dart
List<Object?> get _props => [
      plateBackground, plateBorder, ink, dividerColor,
      borderWidthRatio, plateRadiusRatio, activeColor, inactiveColor,
    ];

@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is PlateTheme && listEquals(other._props, _props);

@override
int get hashCode => Object.hashAll(_props);
```

   `copyWith` stays — it has a real caller (`PlateCanvas` applying
   `borderWidthRatioOverride`).

### Cheap wins in the same pass

6. `lib/model/plate_alphabet.dart` — `isNumeric` walks `characters` on every call and is
   called from `PlateSlotItem`'s build path. Make it a stored field computed in the
   constructor, or keep the getter but have callers hold it. Prefer the stored field: these
   are all `const`, so it costs nothing at runtime.
7. `pubspec.yaml` — remove `bloc_concurrency`. Grep first to confirm it is still unreferenced;
   it was at the time this plan was written.
8. `lib/bloc/plate_card_bloc.dart` — all three `on<...>((Event event, Emitter emit) { ... })`
   handlers take a raw, ungenericized `Emitter`. Should be `Emitter<PlateCardState>`. This
   compiles today without complaint only because `analysis_options.yaml` includes stock
   `flutter_lints` with no project-specific rules — nothing currently enforces
   `strict-raw-type`-style checks that would catch a bare generic. Two-line fix
   (`on<ValueIsChanged>((event, Emitter<PlateCardState> emit) { ... })` for each of the three),
   folded in here since you are already touching this file's neighbor for the state equality
   work in step 2 and it costs nothing extra to fix while the file is open.

## What used to be here

An earlier version of this phase ended with a "measure the bug you just fixed" step: count
`PlateCanvas.build` calls before and after, expecting the `select` fix to halve them. That fix
landed in the performance pass instead, so there is nothing left here to measure — the counter
would read the same before and after this phase. Removed rather than left as a step that
produces a meaningless number.

If you want a rebuild count for the record, the useful one now is per-slot: a keystroke should
rebuild exactly one `_SlotBinding`, and `PlateCardState`'s new `==` (step 2) should stop the
bloc's no-op emissions from waking any of them.

## Do not

- Do not add `==` to `PlateSpec`. It is `id`-based on purpose and specs are const singletons.
- Do not reach for `equatable` or `freezed`. Two `_props` getters is less machinery than a
  code generator, and this package's dependency list is something P10 is trying to shrink.

## Widgets, not widget functions

`claude.md` §1 forbids widget-returning functions, and from here on every phase enforces it in
the files it already edits — this phase touches models, not widgets, so there is nothing to convert. Named here only so the rule is not re-litigated per phase.

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

Expected: ~85 net lines removed from `lib/`, one dependency dropped, one real rebuild bug
fixed.
