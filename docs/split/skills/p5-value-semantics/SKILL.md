---
name: p5-value-semantics
description: "Refactor phase P5 of the plate_number split — put equality where it is load-bearing (fixing a real context.select rebuild bug), collapse hand-written == and hashCode, and drop single-field copyWith. Use when the user asks to run P5 or work on value semantics."
---

# P5 — Value semantics

Follow `CLAUDE.md` working style. Requires **P4** committed. Finish analyzer-clean, tests
green, committed; report diffstat and hashes only.

## Why

Equality in this library is exactly backwards: it is hand-written at length where it does not
matter, and absent where the framework depends on it.

**Absent where it matters.** `PlateNumber` and `PlateCardState` have no `==`. So
`plate_canvas.dart`'s

```dart
final plate = context.select<PlateCardBloc, PlateNumber>((b) => b.state.plateNumber);
```

compares two `PlateNumber` instances by identity, which are never identical after a
`copyWith`. **`select` rebuilds the whole canvas on every bloc emission and has never done
anything.** Same for `PlateAlphabet`, which has no `==` — so
`plate_keypad.dart`'s `letterAlphabet == PlateAlphabet.persianPlateLetters` is an identity
check that silently fails for any caller who builds an equal alphabet inline. (P8 deletes
that comparison, but `activeAlphabet` comparisons remain.)

**Written at length where it does not.** `PlateSlot` (removed in P1), `PlateCountry` and
`PlateTheme` carry ~120 lines of field-by-field `==` and `hashCode`, and `PlateCountry` ships
its own `_listEquals` because `package:flutter/foundation.dart`'s was not imported.

## Do

### Add equality where the framework needs it

1. `lib/model/plate_number.dart` — `PlateNumber` gets `==`/`hashCode` over `values`
   (`listEquals` from `foundation`, `Object.hashAll`). Delete `copyWith`. It has one field and
   **two** call sites — grep before you delete, both must move in this commit:
   - `lib/bloc/plate_card_bloc.dart`, the production call, becomes `PlateNumber(values: values)`.
   - `test/bloc_test.dart:25-27` also calls it directly, inside a `seed:` block:
     `PlateCardState.empty(PlateSpecs.deCar).plateNumber.copyWith(values: ...)`. Rewrite that
     to a direct `PlateNumber(values: List<String?>.filled(PlateSpecs.deCar.slotCount, null)..[0] = 'D')`
     or equivalent. Missing this one leaves the test suite failing to compile, not just
     failing — verify with `flutter test` before considering the phase done, not just
     `flutter analyze`, since analyze alone does not run `test/`.
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

## Measure the bug you just fixed

Before and after, run the holder with a rebuild counter (`debugPrint` in
`PlateCanvas.build`) and type a full Iranian plate. Record both counts in the commit message.
The `select` fix should cut canvas rebuilds roughly in half — every `ValueIsChanged` that the
bloc drops as a no-op currently still rebuilds.

## Do not

- Do not add `==` to `PlateSpec`. It is `id`-based on purpose and specs are const singletons.
- Do not reach for `equatable` or `freezed`. Two `_props` getters is less machinery than a
  code generator, and this package's dependency list is something P10 is trying to shrink.

## Verify

```
cd plate-number-upgrade   && flutter analyze && flutter test
cd ../plate_number_holder && flutter analyze && flutter test
```

Expected: ~85 net lines removed from `lib/`, one dependency dropped, one real rebuild bug
fixed.
