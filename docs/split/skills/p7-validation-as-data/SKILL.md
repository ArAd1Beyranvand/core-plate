---
name: p7-validation-as-data
description: "Refactor phase P7 of the plate_number split — introduce a PlateValidator interface in core, reduce GermanPlateValidator to two forbidden sets, and delete the 35-line barred-key derivation the host app was forced to write. Use when the user asks to run P7 or work on validation."
---

# P7 — Validation as data

Follow `CLAUDE.md` working style. Requires **P6** committed (it uses
`PlateSpec.effectiveTextGroups`). This project does not use automated tests — do not write or
update anything under `test/`, and do not run `flutter test`. Finish analyzer-clean, committed
in both repos; report diffstat and hashes only.

## Why

Three things are wrong with validation today, and they are the same thing.

**Core has no idea validation exists.** `GermanPlateValidator` is a bare static class in a
country-neutral package. `PlateCanvas` and `PlateKeypad` cannot ask for one — `unavailableKeys`
arrives as a pre-computed `Set<String>` from the host.

**So the host does the library's work.** `plate_number_holder/lib/showcase/device_stage.dart`
carries `_unavailableKeysFor` — 35 lines that find the text group containing the active slot,
concatenate the values typed before it, and ask the validator what to bar next. Nothing in it
is app-specific. Every consumer wanting validated input rewrites it.

**And Germany's validator is 90 % generic.** `barredNextDigits` and `barredNextLetters` are
the same function over different sets:

```dart
{ for (final n in _forbidden)
    if (n.startsWith(prefix) && n.length == prefix.length + 1) n[prefix.length] }
```

That is a five-line core utility, not two 8-line methods in a country package.

## Do

### `lib/validators/plate_validator.dart` (new, core)

```dart
@immutable
class PlateValidation {
  const PlateValidation.valid() : reason = null;
  const PlateValidation.invalid(String this.reason);
  final String? reason;
  bool get isValid => reason == null;
}

/// Everything a validator needs about a plate mid-entry.
@immutable
class PlateEntry {
  const PlateEntry({required this.spec, required this.values, this.activeIndex});
  final PlateSpec spec;
  final List<String?> values;
  final int? activeIndex;

  /// Canonical value of the group with [key], or '' if no group has it.
  String group(String key);

  /// The group containing [activeIndex], or null.
  PlateTextGroup? get activeGroup;

  /// Canonical characters already set in [activeGroup] at positions before
  /// [activeIndex]. The prefix a "what may I type next" rule works from.
  String get activePrefix;
}

abstract class PlateValidator {
  const PlateValidator();

  /// Whole-plate verdict. Return valid for an in-progress plate rather than
  /// flagging every keystroke.
  PlateValidation validate(PlateEntry entry);

  /// Characters that would complete a forbidden value if entered next at
  /// [PlateEntry.activeIndex]. Default: none.
  Set<String> barredNext(PlateEntry entry) => const {};
}

/// Characters that extend [prefix] into a member of [forbidden] in one step.
Set<String> completionsOf(Set<String> forbidden, String prefix) => { … };
```

`PlateEntry.group`, `activeGroup` and `activePrefix` are the 35 lines from the holder, moved
in. Build them on `PlateSpec.effectiveTextGroups` and `valueOfGroup` from P6.

Add a small mixin so a country validator that only bars by group needs no logic at all:

```dart
/// A validator whose only per-keystroke rule is "these strings are forbidden
/// in these named groups". Supply the table; the walk is done for you.
mixin ForbiddenByGroup on PlateValidator {
  Map<String, Set<String>> get forbiddenByGroup;

  @override
  Set<String> barredNext(PlateEntry entry) {
    final key = entry.activeGroup?.key;
    final set = key == null ? null : forbiddenByGroup[key];
    return set == null ? const {} : completionsOf(set, entry.activePrefix);
  }
}
```

### `lib/validators/german_plate_validator.dart`

1. `GermanPlateValidator extends PlateValidator with ForbiddenByGroup`, `const`-constructible,
   with a `const GermanPlateValidator()` singleton.
2. `forbiddenByGroup` is a two-entry map: `'letters'` → the Nazi-abbreviation pairs,
   `'serial'` → `{'88', '18', '14'}`. Keep the existing comments explaining what those sets
   are and the caveat that this is not an exhaustive municipal ban list — that caveat is the
   most important text in the file.

   **Found while reading the repo:** `docs/forbidden.json` already holds this exact data —
   same letter pairs, same numbers, same FZV §8 rationale in its `_comment` field — and
   nothing in `lib/` reads it; it is a hand-duplicated JSON shadow of the Dart consts. Resolve
   the duplication in this same commit rather than leaving both to drift:
   - if the JSON was meant to be the source of truth, transcribe `forbiddenByGroup` from it
     and delete the JSON's role as documentation-only (or keep the JSON and note in the Dart
     doc comment that it is generated from `docs/forbidden.json` by hand — pick one framing
     and state it), or
   - if the Dart consts are and always were the real source, `git rm docs/forbidden.json` and
     say so in the commit message.

   Do not leave a second phase to clean this up — it is a two-minute decision once you are
   already editing this file for `ForbiddenByGroup`, and leaving it duplicated is exactly the
   kind of thing this refactor exists to stop doing. (This is separate from
   `docs/districts.json`, which is unused *data* rather than a duplicated shadow — that is
   **P7.5**, and is a real decision, not a two-minute one.)
3. Delete `barredNextDigits` and `barredNextLetters`.
4. `validate(PlateEntry)` keeps the regex format checks and the 8-character cap, reading
   groups via `entry.group('district' | 'letters' | 'serial')`. Keep the "empty letters group
   is valid" early return — an in-progress plate must not be flagged.
5. Keep the standalone
   `validate({required district, required identifierLetters, required identifierDigits})`
   as a static — it is genuinely useful without a spec, independent of tests.
   `validate(PlateEntry)` delegates to it.
6. `GermanPlateValidationResult` collapses into core's `PlateValidation`. Keep a
   `typedef GermanPlateValidationResult = PlateValidation;` for one release and note it in
   `CHANGELOG.md`.

### Wire it through core

7. `PlateCanvas` takes `this.validator` (`PlateValidator?`). It already has the spec, the
   values and the active index, so it can build a `PlateEntry` per build.
8. `PlateInputController` exposes `PlateValidation? get validation` and
   `Set<String> get barredKeys`, both derived from the attached machine's entry, notifying on
   change. That is what a host keypad should read.
9. `PlateKeypad.unavailableKeys` stays as a parameter — the pad must remain usable standalone
   — but the holder now feeds it `controller.barredKeys` instead of computing it.

### `plate_number_holder`

10. Delete `_unavailableKeysFor` entirely from `lib/showcase/device_stage.dart`. It is index-based
    since P1 (`final index = _activeIndex;`), so it maps onto `PlateEntry.activeIndex` directly —
    the group walk moves in unchanged.
11. `_validateGermanPlate` and `_blocSub` collapse into reading
    `_plateInput.validation` — `PlateInputController` is a `ChangeNotifier`, so the
    `StreamSubscription<PlateCardState>` and its re-subscribe-on-swap dance go away too.
    Keep `DemoConfig.showsValidation` gating.

    **Two things in this method are load-bearing and post-date the original draft of this
    phase — preserve both.** The performance pass narrowed it so that `setState` fires only when
    `isValid` actually flips, rather than on every bloc emission (before that, the tablet
    rebuilt a whole `DeviceFrame`, a fresh page on the glass and a fresh keypad once per
    character). Whatever replaces the subscription must keep that: notify on a change of
    verdict, not on every notification from the controller. Related, the full keypad now sits
    under a `BlocBuilder<PlateCardBloc, PlateCardState>` scoped to itself, because the barred-key
    set genuinely does track the typed value while the rest of the stage does not. Keep that
    scoping — feeding it `controller.barredKeys` is a change of *source*, not a licence to hoist
    the rebuild back up to the stage.
12. Pass `validator: const GermanPlateValidator()` for the tablet device only, from
    `DemoConfig` — add a `PlateValidator? validator` field to `DemoConfig` so it stays
    variation-as-data (`claude.md` §2) rather than a `device == tablet` branch.

This project does not use automated tests. Verify `activeGroup`/`activePrefix` and
`barredNext` manually instead, including the edge the holder code had to handle: an active
index at the **start** of a group yields an empty prefix, and an index outside every keyed
group yields a null group.

## Widgets, not widget functions

`claude.md` §1 forbids widget-returning functions, and from here on every phase enforces it in
the files it already edits — here that is the holder's `device_stage.dart`, whose `_buildDevice` is a ~40-line widget function this phase already reaches into. Converting it to a `_DeviceBody` widget class is worthwhile *if* it comes out at a similar length — it closes over a lot of stage state, so if hoisting those into constructor fields balloons the file, leave `_buildDevice` alone and say so. Do not let this hold up the validation work, which is the phase.

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

Then run the tablet demo and watch the auto-typist's German sequence: `DA` → `X` → `88` must
still turn the plate red, the keypad must still grey out the second `8` for interactive taps
while the scripted typist commits it anyway (that tension is deliberate and commented in
`device_stage.dart` — preserve it), backspace must clear the red, and `1953` must finish clean.

Expected: ~60 lines out of `lib/`, ~35 out of the holder, and validation becomes a thing core
supports rather than a thing every consumer reimplements.
