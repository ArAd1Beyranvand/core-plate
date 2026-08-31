---
name: p7.5-district-data
description: "Refactor phase P7.5 of the plate_number split — decide and implement whether GermanPlateValidator checks district codes against docs/districts.json's ~150 real Unterscheidungszeichen, which today it silently ignores. Use when the user asks to run P7.5 or work on district validation."
---

# P7.5 — District data

Follow `CLAUDE.md` working style. Requires **P7** committed (this edits the same
`german_plate_validator.dart` that `ForbiddenByGroup` lands in). This project does not use
automated tests — do not write or update anything under `test/`, and do not run
`flutter test`. Finish analyzer-clean, committed; report diffstat and hash only.

**This phase starts with a decision, not an edit.** Do not write code before the "Decide"
step below has an answer from the user.

## What was found

`german_plate_validator.dart`'s district check is:

```dart
static final RegExp _districtPattern = RegExp(r'^[A-ZÄÖÜ]{1,3}$');
```

Any 1–3 uppercase Latin letters pass. `AA`, `QQ`, `ZZ` — none a real `Unterscheidungszeichen`
— validate as fine today.

`docs/districts.json` sits in the repo, referenced by nothing in `lib/`, with a header comment
identifying exactly what it is:

> German Kennzeichen district codes (Unterscheidungszeichen). 1-3 uppercase Latin letters. Not
> exhaustive of all ~440 current codes — covers major cities and states, sufficient for
> demo/validation purposes.

~150 real codes: `B`, `M`, `K`, `F`, `HH`, `DA`, `TÜ`, and so on — including the multi-letter
extended codes (`HAL`, `HAM`, `MOS`, `NEA`, `ROW`, `TUT`) that a pure length check cannot
distinguish from noise.

Also found: `docs/forbidden.json` holds the same forbidden letter-pairs and numbers already
hardcoded as Dart `const Set`s in the validator, with the identical FZV §8 comment. That part
is a P7 concern (fold the JSON in as the source of truth, or delete the JSON as a stale
duplicate of the Dart — P7 should not leave both). This phase is about the district list
specifically, which — unlike the forbidden pairs — **is not used anywhere at all today**.

## Decide

Ask the user directly; do not guess. The honest options:

1. **Wire it in.** `validate()`'s district check becomes a set-membership test against the 150
   codes instead of a regex. Upside: a plate with `district: 'AA'` — not real — starts failing
   validation, which is more correct. Downside: the list is admittedly non-exhaustive (~150 of
   ~440), so a real code the list omits would now be wrongly rejected — worse than today's
   false-accept in the specific case of a legitimate district this list doesn't cover.
2. **Delete `docs/districts.json`.** If district-format validation (length + charset) is all
   this package ever intends to check — leaving full-list correctness to a server-side
   check — the file is dead weight and documents an intention nobody acted on. Delete it and
   say so in the commit message.
3. **Keep it, wire it in as a *warning* not a hard failure.** Add a second, non-blocking
   signal — e.g. `GermanPlateValidationResult` gains `bool districtRecognized` alongside
   `isValid` — so a host can show "unrecognized district code" without blocking entry the way
   a forbidden letter pair does. This is the option that respects both the list's
   incompleteness and the fact that it is real, useful data currently going to waste.

`docs/split/PLAN.md` does not pick for you; this file does not either. Use `AskUserQuestion`
before writing code.

## Do (once decided)

### If (1) or (3) — wiring in

1. Load `docs/districts.json` at build time via a generated Dart const, not a runtime asset
   read — the country package should not need `rootBundle`/`AssetBundle` for validation data
   that never changes at runtime. Either:
   - hand-transcribe the `codes` array into a `const Set<String> _knownDistricts` in
     `germany_plate`'s validator file (150 short strings — this is the pragmatic choice,
     consistent with how `_forbiddenLetterPairs` is already done), or
   - add a one-time codegen step if the team wants the JSON to stay the single source of
     truth. Do not add a build-time codegen dependency for 150 strings unless the user asks
     for it — that is machinery this plan has otherwise been trying to remove.
2. For (1): `validate()`'s district branch becomes
   `if (!_knownDistricts.contains(d)) return const GermanPlateValidationResult(isValid: false, reason: 'Unrecognized district code.');`
   replacing the regex check (keep a lightweight format assert — length 1–3, uppercase — as a
   cheap pre-check before the set lookup, since a malformed string should fail fast with a
   clearer reason than "not in the list").
3. For (3): add the `districtRecognized` field, compute it alongside but do not let it flip
   `isValid`. Update `PlateValidation`/`GermanPlateValidationResult`'s shape from P7
   accordingly — this touches the same type, so re-read what P7 landed before editing it.
4. Update the doc comment on `GermanPlateValidator` to state plainly that the district list is
   ~150 of ~440 real codes and is not exhaustive — the honesty that is currently only in a JSON
   comment nobody reads needs to be in the Dart doc comment a consumer actually sees.

### If (2) — delete

5. `git rm docs/districts.json`. Note the removal and why in the commit message. Leave the
   regex check as-is.

## Verification (manual — this project does not use automated tests)

- (1)/(3): manually confirm a real code (`'DA'`) passes and a fabricated one (`'QQ'` or similar,
  confirmed absent from the list) fails — or, for (3), reports `districtRecognized: false`
  without failing `isValid`.
- (2): confirm the existing district-format behavior still works unchanged.

## Widgets, not widget functions

`claude.md` §1 forbids widget-returning functions, and from here on every phase enforces it in
the files it already edits — this phase touches a validator, not widgets. Nothing to convert.

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
cd plate-core && flutter analyze
cd ../plate_number_holder && flutter analyze
```

(Do not run `flutter test` — this project does not use automated tests.)

If (1) was chosen, run the tablet demo's German auto-typist script end to end — it types
district `DA`, which is real and must still pass.

Expected: a real decision recorded in the commit message, not just a diff. This phase's value
is closing the gap between data that exists in the repo and behavior that uses it — or
removing the data if it was never going to be used.
