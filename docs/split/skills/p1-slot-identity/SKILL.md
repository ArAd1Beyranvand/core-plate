---
name: p1-slot-identity
description: "Refactor phase P1 of the plate_number split — delete PlateSlot.index and PlateSlot.next, deriving slot position and focus order from list order. Use when the user asks to run P1, start the plate_number refactor, or work on slot identity."
---

# P1 — Slot identity

> **Status: landed**, though not as its own commit — the work arrived inside the animation
> performance pass (see the project's `ANIMATION_PERF` notes) rather than through this prompt.
> Verified in the tree as of the `plate-core` rename:
>
> - `PlateSlot` has no `index` and no `next`, and no `operator ==` / `hashCode`.
> - `PlateSpec` carries `slotAt`, `nextIndex` and `previousIndex` exactly as steps 3–4 specify.
> - `debugValidateSpec` is down to the canvas-bounds assertion alone.
> - `_focusNodes` / `_controllers` are `List<FocusNode>` / `List<TextEditingController?>`
>   (step 7), and `_advance`, `backspaceCharacter`, `focusFirstEmptySlot` and `focusSlot` are
>   all index-based.
> - `PlateInputTarget.activeIndex`, `PlateInputController.activeIndex` and `activeSlotIn(spec)`
>   all exist (steps 12–13); `PlateCanvas.onActiveIndexChanged` is `ValueChanged<int?>`.
> - Holder side: `plate_display.dart` forwards `onActiveIndexChanged`; `device_stage.dart` holds
>   `int? _activeIndex` / `_setActiveIndex`, and the typist wrapper is the one-liner
>   `onSlotChanged: config.showsValidation ? _setActiveIndex : null` step 16 asked for.
>
> **Not** verified, because it left no trace: whether the new `nextIndex`/`previousIndex` checks
> from the old step 17 were added. This project does not use automated tests, so there is
> nothing to add here — this loose end is closed.
>
> Everything below is kept as the record of what changed and why. Do not re-run the phase.

Follow `CLAUDE.md` working style: no repo survey, no narration, edit only the files named
below. This project does not use automated tests — do not write or update anything under
`test/`, and do not run `flutter test`. Finish with `flutter analyze` clean in both projects,
and a `git commit` in each repo you touched. Report the diffstat and the commit hashes only.

## Why

`PlateSlot` carries `index` (position in `PlateNumber.values`) and `next` (the index focus
advances to). Both are redundant in every spec that exists:

```
irCar        slots= 8   index==position: True   next==index+1: True
irBicycle    slots= 8   index==position: True   next==index+1: True
deCar        slots= 7   index==position: True   next==index+1: True
```

They are hand-maintained duplicates of list order, and ~70 lines of the library exist only to
defend them: a duplicate-index assertion, a `next`-resolves assertion, a cycle-detection walk,
a reverse-scan `_previousSlot`, and a linear `slotAt`.

## Do

### `lib/model/plate_spec.dart`

1. Delete `PlateSlot.index` and `PlateSlot.next` and their doc comments.
2. Delete `PlateSlot.operator ==` and `PlateSlot.hashCode`. They exist only to support
   `PlateSpec` equality, which is already `id`-based. Nothing else compares slots.
3. `PlateSpec.slotAt(int index)` becomes a bounds-checked list read:
   `index >= 0 && index < slots.length ? slots[index] : null`. Keep the null return —
   callers rely on it.
4. Add `int? nextIndex(int index)` and `int? previousIndex(int index)` to `PlateSpec`,
   returning `index + 1` / `index - 1` bounded by `slots.length`, or null at the ends.
   These are the replacement for `PlateSlot.next` and for `_PlateCanvasState._previousSlot`.
5. `debugValidateSpec` drops the duplicate-index check, the `next`-resolves check and the
   cycle walk. Keep only the canvas-bounds assertion, with its message intact. It should end
   at roughly 18 lines.
6. Remove `index:` and `next:` from every `PlateSlot(...)` literal in `PlateSpecs`.

### `lib/widgets/plate_canvas.dart`

7. `_focusNodes` and `_controllers` are declared `Map<int, FocusNode>` /
   `Map<int, TextEditingController>` keyed by `slot.index` — but once slot identity is list
   position, an integer-keyed map over a dense `0..n` range is just a list with extra hashing.
   Change both to `List<FocusNode>` and `List<TextEditingController?>` (null entries for chosen
   slots), built with `for (var i = 0; i < widget.spec.slots.length; i++)`. Every `_focusNodes[i]`
   read becomes `_focusNodes[i]` on a list — same call shape, cheaper structure, and it makes the
   positional-identity invariant this whole phase establishes visible in the type itself rather
   than asserted by convention.
8. `_advance(PlateSlot slot)` becomes `_advance(int index)` and uses `spec.nextIndex(index)`.
9. Delete `_previousSlot`; `backspaceCharacter` uses `spec.previousIndex(...)`.
10. `_handleFocusChange` tracks an `int? _activeIndex` instead of a `PlateSlot? _activeSlot`.
    Keep the existing cheap-comparison intent — it is now free.
11. In `build`, the `for (final s in spec.slots)` loop becomes an indexed loop so `s.index`
    reads become the loop variable.

    **Do not attempt to fix `didUpdateWidget`'s missing `spec`-change handling in this phase.**
    `_focusNodes`/`_controllers` are still built once in `initState` and still go stale if
    `widget.spec` changes without a fresh `State` — switching `Map<int,X>` to `List<X>` in this
    phase does not touch that. It is real, it is live (see below), and it is **P4**'s fix, not
    this one's. Making it here would tangle two unrelated changes into one commit.

### `lib/input/plate_input_controller.dart`

12. `PlateInputTarget.activeSlot` → `int? get activeIndex`. `submitCharacter`,
    `backspaceCharacter`, `focusFirstEmptySlot`, `focusSlot` are unchanged.
13. `PlateInputController.activeSlot` → `int? get activeIndex`, and add
    `PlateSlot? activeSlotIn(PlateSpec spec) => spec.slotAt(activeIndex ?? -1)` as the
    convenience for hosts that need the slot itself (they know their spec).
14. `PlateCanvas.onActiveSlotChanged` becomes `ValueChanged<int?>? onActiveIndexChanged`.

### `plate_number_holder`

This is the larger half of the phase. `device_stage.dart` is the single heaviest consumer of
`PlateSlot.index` and `ValueChanged<PlateSlot?>` outside the library itself — read it in full
before editing, not just the four call sites a grep for `.index` turns up.

15. `lib/widgets/plate_display.dart`: `onActiveSlotChanged` is `ValueChanged<PlateSlot?>?`,
    forwarded straight to `PlateCanvas`. Rename to `onActiveIndexChanged` of type
    `ValueChanged<int?>?`, matching step 14's `PlateCanvas` change. It threads through three
    wrapper widgets (`PlateDisplay` → `_PlateDisplayBody` → `_PlateInputSurface`) before
    reaching `PlateCanvas` — all three constructors carry the field name, rename it in each.

16. `lib/showcase/device_stage.dart` — the full set, in order:

    - `PlateSlot? _activeSlot;` → `int? _activeIndex;`
    - `void _setActiveSlot(PlateSlot? slot)` → `void _setActiveIndex(int? index)`. The body's
      `_activeSlot?.index == slot?.index` guard becomes the direct `_activeIndex == index` —
      simpler than before, since there is no `.index` indirection left to compare through.
    - `_unavailableKeysFor`: `final slot = _activeSlot; if (slot == null) return const {};`
      becomes `final index = _activeIndex; if (index == null) return const {};`. Every
      `slot.index` read in `groupContaining` (`g.indices.contains(slot.index)`) and
      `valueBeforeActive` (`if (i >= slot.index) continue`) becomes `index` directly.
    - `_activeAlphabet` (computed in `_buildDevice` as `_activeSlot?.alphabet`) can no longer
      read `.alphabet` off a bare index. Resolve it explicitly:
      `_activeIndex == null ? null : demoConfigs[_contentDevice]!.spec.slotAt(_activeIndex!)?.alphabet`.
    - **The typist wrapper simplifies, it does not just get renamed.** Today's `_runTyping`
      passes:
      ```dart
      onSlotChanged: config.showsValidation
          ? (i) => _setActiveSlot(i == null ? null : specFor(_contentDevice).slotAt(i))
          : null,
      ```
      with the comment "the typist still reports a bare index; resolve it to the matching
      PlateSlot so `_setActiveSlot` sees the same type the canvas callback now delivers." Check
      `plate_typist.dart`: `PlateTypist.run`'s `onSlotChanged` parameter is already
      `ValueChanged<int?>?` — the typist has spoken in plain indices the whole time. Once
      `_setActiveIndex` also takes a plain `int?`, this whole resolve-to-slot wrapper is
      unnecessary. Replace it with:
      ```dart
      onSlotChanged: config.showsValidation ? _setActiveIndex : null,
      ```
      and delete the now-stale comment along with it. This is the one place in the whole phase
      where deleting `PlateSlot.index` makes the *holder* shorter, not just the library — call
      it out in the commit message.
    - `GermanPlateValidator.barredNextDigits`/`barredNextLetters` calls inside
      `_unavailableKeysFor` are untouched by this phase — they still take/return `String`/`Set`,
      nothing about their signature depends on `PlateSlot.index`. P7 is what changes their
      shape.

17. Grep both `lib/` and the holder one more time after editing, before considering the phase
    done:
    ```bash
    grep -rn "\.index\b" plate-core/lib plate_number_holder/lib
    ```
    Every remaining hit should be something unrelated to `PlateSlot` (a `List.indexOf`, a loop
    variable literally named `index`, etc.) — if a `PlateSlot`-typed `.index` read survives
    anywhere, the phase is incomplete, not just the library side of it.

### A bug this phase does not fix, but should not paper over

`_PlateCanvasState`'s focus/controller lifecycle is reused across incompatible specs on every
device-cycle transition in this exact app — confirmed live, not theoretical (see
`docs/split/PLAN.md` §1, "A confirmed, live bug"). Nothing in `DeviceFrame` → `PlateDisplay` →
`PlateCanvas` passes a `Key`, so Flutter keeps the same `_PlateCanvasState` across spec swaps.
This phase's List-instead-of-Map change (step 7) does not fix it, and must not accidentally
paper over it — do not add a `Key` here as a quick fix. P4 owns the real fix (rebuilding the
input machine when `widget.spec` changes identity) and needs the bug reproducible in its
"before" state to verify against. If you notice the showcase behaving oddly after a device
swap while testing this phase, that is this bug, not something P1 introduced — confirm by
checking whether it also happens on the unmodified `main` branch before assuming a regression.

## Do not

- Do not introduce a `focusOrder` field on `PlateSpec` "for later". If a future plate ever
  needs a non-sequential order, that is the phase that adds it.
- Do not touch geometry fields (`left`/`top`/`width`/`height`) — that is P2.

## Widgets, not widget functions

`claude.md` §1 forbids widget-returning functions, and from here on every phase enforces it in
the files it already edits — nothing in this phase's files is a widget function today, so this is a check, not work: confirm none has appeared.

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

Then run the holder app and confirm all three demo devices still type and advance correctly,
including backspace stepping back across a slot boundary. Cycle through all three devices at
least twice — the pre-existing state-reuse bug above may show as a wrong keypad, a wrong
focused field, or nothing visible at all, depending on luck of which specs land adjacent to
each other. Do not chase it in this phase; confirm it behaves the same as it did before your
changes (i.e. you introduced no new symptom) and move on. P4 fixes it properly.

Expected: ~70 net lines removed from `lib/`, plus a small net removal in the holder from the
typist wrapper simplification.
