---
name: task-7-merge-controllers
description: "PlateController refactor — Stage 7 of 7 (0.5.0): fold PlateInputController's members into PlateController, replace the old class with a @Deprecated typedef alias, add activeSlot and deprecate activeSlotIn, widen PlateCanvas.controller to PlateController?. Invoke when the user runs /task for stage 7."
---

# Stage 7 — merge the two controllers (0.5.0)

**Recommended model: Sonnet 5, low reasoning, thinking ON.**
Mechanical rename-and-merge with no behaviour change; the deprecation typedef and
CHANGELOG are the only judgement calls. A light model is enough — keep thinking on to
catch type-annotation fallout across consumers.

Run the prompt below in a fresh session. Stage 7 of 7 — the 0.5.0 release, deprecation
only. Previous: `task-6-extract-core-plate-bloc`. Acceptance check and commit.

---

Repo: /home/aradbeyranvand/StudioProjects/plate. Working mostly in `core_plate`.
Read core_plate/CLAUDE.md and follow it. Read the named files in full first. Do not
create tests.

CONTEXT
Stage 7 of 7, the 0.5.0 release. `PlateController` has been the primary API since 0.3.0
and currently `extends PlateInputController` — a compatibility shape chosen so that every
existing `PlateCanvas(controller: …)` call site kept compiling through the migration.
That job is done: no consumer in this workspace passes a bare `PlateInputController` any
more. Two objects where hosts think of one is now just a wart.

FILES YOU MAY TOUCH
  core_plate/lib/src/input/plate_controller.dart
  core_plate/lib/src/input/plate_input_controller.dart
  core_plate/lib/src/widgets/plate_canvas.dart
  core_plate/lib/core_plate.dart
  core_plate/CHANGELOG.md
  plate_number_holder/lib/showcase/demo_config.dart   (doc comment only)
  plate_number_holder/lib/showcase/plate_typist.dart  (doc comment only)
  any consumer file whose type annotations need widening

WHAT TO DO

1. Fold `PlateInputController`'s members into `PlateController`: the `PlateInputTarget`
   plumbing (`attach`, `detach`, `installValidation`, `reportValidation`,
   `notifyActiveSlotChanged`), the host-facing focus API (`activeIndex`, `activeSlotIn`,
   `isAttached`, `validation`, `submit`, `backspace`, `focusFirstEmpty`, `focusSlot`) and
   their doc comments, which are good and should survive intact.

2. Keep `PlateInputTarget` exactly as it is. It is the interface `PlateInputMachine`
   implements and it is what keeps the machine independent of everything else. The machine
   file must not change in this stage either.

3. Replace the old class with
   `@Deprecated('Renamed to PlateController in 0.5.0; will be removed in 0.6.0.')
    typedef PlateInputController = PlateController;`
   so existing annotations still compile with a warning.

4. `PlateController.activeSlotIn(PlateSpec spec)` is now redundant — the controller knows
   its own spec. Add `PlateSlot? get activeSlot` and deprecate `activeSlotIn`, pointing at
   it. Do the same for any other member the merge made spec-redundant.

5. Widen `PlateCanvas.controller` to `PlateController?` and simplify the
   `is PlateController` feature-detection that stage 2 introduced — there is one type now,
   so the canvas either got a controller or it makes one. Keep the
   `TextField`/`TextEditingController` ownership semantics exactly: owned when created,
   never disposed when the host's.

6. Update the doc comments in plate_number_holder that reference `PlateInputController`
   by name.

7. CHANGELOG.md for 0.5.0: the rename, the deprecated typedef, the `activeSlotIn` →
   `activeSlot` mapping, and the 0.6.0 removal date.

CONSTRAINTS
- No country name anywhere in core_plate.
- `plate_input_machine.dart` unchanged.
- Do not change any behaviour. This is a rename and a merge.

ACCEPTANCE CHECK
- `flutter analyze` clean across all eight packages and all six example apps, with no
  deprecation warnings in this workspace's own code (the typedef exists for external
  consumers; nothing here should still use the old name).
- All six examples run, plus plate_number_holder's showcase end to end: device cycling,
  the auto-typist, the stacked mirror plate, the tablet keypad, the laptop deck keys.
- palestine_plate's tests still pass.
Finish with analyzer clean + a git commit.
