---
name: p1
description: "P1 — build the test suite core_plate has never had, pinning the value/focus/behaviour semantics every later phase will refactor against. No production code changes. Invoke with /p1 in a fresh session."
---

> **Run this in a fresh session** (`/clear` first).
> **Model:** Opus 5 · **reasoning:** high · **extended thinking:** ON
> **Requires:** /p0
> Full index: `/phases` · evidence: `claude/AUDIT_DIAGNOSIS.md` · overview: `claude/REFACTOR_ROADMAP.md`

# P1 — Core test harness

## Context (assume nothing else)

`~/StudioProjects/plate/core_plate` is a Flutter package (version 0.5.0) that renders vehicle licence
plates from `const` data. It is 3,070 lines across 21 files and **has no tests at all**. It declares
`flutter_test` in `dev_dependencies` and ships no `test/` directory.

Everything the rest of this roadmap touches runs through it. The only tests anywhere in the workspace are
542 lines in `palestine_plate/test/`, which exercise Palestinian validators, a serial generator and one
golden image — none of the engine.

The engine's semantics that must be pinned before anything is refactored:

- **`PlateController`** (`lib/src/input/plate_controller.dart`, 408 lines) owns a plate's characters.
  It sanitises writes against each slot's alphabet, exposes per-slot `ValueListenable`s and a `completed`
  flag, and — in `adoptSpec` — migrates values across a spec swap under three
  `PlateValuePreservation` policies. The `byGroupKey` path (lines 331–382) is the subtlest code in the
  package: it pre-fills single-character alphabets, then copies register by register matched on
  `PlateTextGroup.key`, skipping unset source slots rather than carrying gaps.
- **`resolveSlotBehavior`** (`lib/src/model/slot_behavior.dart:38-54`) is a seven-row truth table over
  (mode, alphabet input, input source). Its own doc comment states the table.
- **`PlateSpec`** (`lib/src/model/plate_spec.dart`) derives `effectiveTextGroups`, `groupAt`,
  `renderGroup`, `valueOfGroup`, `nextIndex`, `previousIndex`.
- **`debugValidateSpec`** (`:261-326`) asserts slot/mirror rects fit the canvas, mirrors point at real
  slots, and alphabet ids key content one-to-one — in both directions.
- **`PlateInputMachine`** (`lib/src/input/plate_input_machine.dart`) owns focus nodes and navigation:
  `submitCharacter` → commit + advance, `backspaceCharacter` → clear-or-step-back,
  `advanceFrom` → next slot or `onSheetRequested`, `focusFirstEmptySlot`.

## Scope

**In:** a new `core_plate/test/` directory only.

**Out — frozen. This phase changes no production code.**
- Every file under `core_plate/lib/`. If a test reveals a bug, **write the test, mark it
  `skip: 'BUG: <one line>'`, and report it** — do not fix it here. A phase that both adds tests and
  changes behaviour cannot tell you which one broke something.
- Every other package.
- `pubspec.yaml` — `flutter_test` is already a dev-dependency.

## Steps

Create five files. Use `flutter_test`; only `plate_input_machine_test.dart` and any widget-level test
need `testWidgets` — the rest are plain `test()`.

### 1. `test/plate_spec_test.dart` (~120 lines)

Build small local specs; do not import any country package. Cover:

- `slotCount` tracks `slots.length`; `slotAt` returns null out of range at both ends.
- `effectiveTextGroups` returns `textGroups` when non-empty, and one single-index group per slot in index
  order when empty. Assert the fallback for a 3-slot spec is exactly `[[0],[1],[2]]`.
- `groupAt` finds the containing group; returns null for an index in no group.
- `renderGroup` applies each slot's own alphabet `glyphs` and prepends `prefix`; unset slots render `''`;
  an index past `values.length` renders `''` rather than throwing.
- `valueOfGroup` returns storage form (not glyphs) for a keyed group, and `''` for an absent key.
- `nextIndex`/`previousIndex` return null at the ends and never wrap.
- Equality and `hashCode` are over `id` alone: two structurally different specs with the same id compare equal.

### 2. `test/debug_validate_spec_test.dart` (~90 lines)

`debugValidateSpec` asserts, so use `expect(() => ..., throwsAssertionError)`. Run with asserts enabled
(`flutter test` does this by default).

- A well-formed spec returns true.
- A slot box extending past `canvasWidth` or `canvasHeight`, or with a negative `left`/`top`, throws.
- A mirror box outside the canvas throws; a mirror whose `source` is negative or `>= slots.length` throws.
- **Both directions of the alphabet-id rule:** one id appearing with two different character/glyph pairs
  throws; two distinct ids sharing one character/glyph pair throws.
- Two alphabets with the same `characters` but different `glyphs` and different ids are **legal** — this is
  the case `yemen_plate`'s `ye.digits` / `ye.easternDigits` pair depends on. Assert it does not throw.

### 3. `test/slot_behavior_test.dart` (~60 lines)

Transcribe the table in `slot_behavior.dart:29-37` as a data-driven test over all
`PlateMode` × `AlphabetInput` × `PlateInputSource` combinations — 2 × 2 × 4 = 16 cases, exhaustively:

- `display` + anything → `glyph` (all 8 combinations).
- `input`/`typed`/`system` → `imeField`; `input`/`chosen`/`system` → `sheet`.
- `input`/either/`hardwareKeyboard` → `hardwareField`.
- `input`/either/`packageKeypad` or `host` → `externalField`.

Also assert `defaultInputSource()` returns `hardwareKeyboard` for windows/linux/macOS and `system`
otherwise, driving it with `debugDefaultTargetPlatformOverride`.

### 4. `test/plate_controller_test.dart` (~200 lines) — the important one

- **Construction:** `PlateController(spec:)` fills `values` with nulls to `slotCount`; a `values:` argument
  longer than the plate is truncated, shorter is padded with null, and a character the slot's alphabet
  refuses lands as null.
- **`fromText`:** skips characters no slot accepts rather than consuming a slot — assert that
  `fromText(spec, '12 AB')` on a digit-digit-letter-letter plate yields `['1','2','A','B']`, the space
  costing nothing.
- **`setAt`:** stores an accepted character; `''` and `null` clear; a refused character is a **no-op that
  leaves the existing value intact** (the guard at `:92`), not a clear.
- **`setValues`:** writes every slot and notifies **once** — count notifications with a listener.
- **`setGroup`:** writes across a keyed group in group order, stops at the shorter of value and group,
  clears trailing slots, and is a no-op for an unknown key.
- **Listenables:** `slot(i)` fires only for writes to `i`; `slot(-1)` and `slot(slotCount)` return a
  listenable that is null forever and never notifies; `completed` fires only on the flip, so N-1 keystrokes
  on an N-slot plate produce zero `completed` notifications and the Nth produces one.
- **`text()`:** joins `effectiveTextGroups` with the separator and renders through glyphs.
- **`adoptSpec` — cover all three policies:**
  - `none` → every slot null.
  - `byIndex` → copied positionally, sanitised against the *new* spec's alphabets, truncated or
    null-padded by length.
  - `byGroupKey` (the default) → registers matched by key regardless of position. Build the exact case
    this exists for: a spec with `serial` at indices `[1,2,3,4]` adopting one with `serial` at `[0,1,2,3]`,
    and assert the four digits land in the new positions. Then assert a **half-typed** register carries as
    far as it got with gaps closed, not preserved. Then assert a single-character alphabet slot in the
    target is pre-filled from its own alphabet, and that a matched group covering that slot still wins.
    Then assert that when neither spec has keyed groups, `byGroupKey` falls back to positional.
  - After `adoptSpec`, `slot(i)` handles from before the swap are stale-but-alive: they do not throw and
    do not update. Pin that.
- **Lifecycle:** `dispose` disposes every slot notifier and `completed`; a second `dispose` is the standard
  `ChangeNotifier` error, not a silent pass.
- **Validation plumbing:** `validation` is null with no probe installed; `installValidation(null)` clears it;
  `reportValidation` notifies on a **change of verdict** and not on a repeat of the same verdict — assert
  by counting notifications across two identical `PlateValidation.invalid('x')` reports.

### 5. `test/plate_input_machine_test.dart` (~110 lines)

The machine needs a `TickerProvider`-free environment but does create `FocusNode`s, so use `testWidgets`
and pump a minimal `Focus` host, or construct it directly and assert on `activeIndex` without requesting
focus where possible.

- Constructor seeds `activeIndex` to 0 for a non-empty spec and null for an empty one, and does **not**
  announce it (`onActiveIndexChanged` is not called from the constructor).
- `controllerAt` is a `TextEditingController` for a `typed` slot and null for a `chosen` one;
  `focusNodeAt` is never null.
- `submitCharacter` commits and advances; a character the active slot refuses is a no-op with no commit
  and no advance.
- `backspaceCharacter` clears a non-empty active slot in place; on an already-empty slot it steps back and
  clears the previous one; at index 0 with an empty slot it is a no-op.
- `advanceFrom` on the last slot unfocuses rather than wrapping.
- `advanceFrom` onto a slot that resolves to `SlotBehavior.sheet` calls `onSheetRequested` with that index
  and does **not** request focus.
- `syncController` is a no-op when the text already matches, and sets a collapsed selection at the end
  otherwise.
- `dispose` removes the focus listener before disposing each node.

## Verification

```bash
cd ~/StudioProjects/plate/core_plate
flutter test                       # all green, or green with explicitly-marked `skip:` bugs
flutter test --coverage
lcov --summary coverage/lcov.info  # if lcov is available

flutter analyze --no-fatal-infos   # unchanged from the P0 baseline
git status --porcelain lib/        # MUST be empty — no production file changed
```

**Success:**
- `core_plate/test/` holds five files and every test passes or is `skip:`-marked with a one-line bug note.
- Line coverage of `lib/src/input/` and `lib/src/model/` is above 85%.
- `git status --porcelain lib/` is empty.
- Any skipped test is listed in the final report with the suspected bug.

## Dependencies

P0 (the workspace must resolve, and the baseline must be recorded).

## Line estimate

+530 (five new test files). Zero production lines changed.
