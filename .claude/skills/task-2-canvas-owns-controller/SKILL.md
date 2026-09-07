---
name: task-2-canvas-owns-controller
description: "PlateController refactor — Stage 2 of 7: make _PlateCanvasState hold a PlateController as writer of record, add a private two-way bridge keeping the still-required ancestor PlateCardBloc in sync, and stop capturing BuildContext in long-lived closures. Invoke when the user runs /task for stage 2."
---

# Stage 2 — canvas owns a controller; bloc becomes a mirror

**Recommended model: Opus 5, high reasoning, thinking ON.**
This is the riskiest stage: a two-way bloc/controller bridge with an echo guard, plus
controller ownership and lifecycle. It ships alone precisely so a regression here is
isolatable. Take the time.

Run the prompt below in a fresh session. Stage 2 of 7. Previous: `task-1-add-controller`.
Next: `task-3-bindings-read-controller`. Do the acceptance check and commit.

---

Repo: /home/aradbeyranvand/StudioProjects/plate. Working in `core_plate`.
Read core_plate/CLAUDE.md and follow it. Read the files named below in full first (this
task names them, so the "don't survey" rule is satisfied). Never create or edit files
under any `test/` directory; do not run `flutter test`.

CONTEXT
Stage 2 of 7 of moving core_plate off a mandatory bloc. Stage 1 added
`PlateController extends PlateInputController` (lib/src/input/plate_controller.dart) — a
value-owning controller with per-slot `ValueListenable`s — plus `PlateSelector`. Nothing
is wired to it yet.

This stage makes `_PlateCanvasState` hold a `PlateController` internally and become the
writer of record, while the ancestor `PlateCardBloc` stays required and stays in sync in
BOTH directions. Behaviour must be pixel- and rebuild-identical afterwards. The widget
bindings still read the bloc — do not touch them; that is stage 3.

FILES YOU MAY TOUCH
  core_plate/lib/src/widgets/plate_canvas.dart
  core_plate/lib/src/input/plate_controller.dart   (only if a genuine gap appears)

READ FIRST (do not edit)
  core_plate/lib/src/input/plate_input_machine.dart
  core_plate/lib/src/input/plate_input_controller.dart
  core_plate/lib/src/bloc/plate_card_bloc.dart (and its two `part` files)

WHAT TO DO

1. `_PlateCanvasState` gains `PlateController _controller` and a `bool _ownsController`.
   In initState: if `widget.controller is PlateController`, adopt it and set
   `_ownsController = false`; otherwise construct `PlateController(spec: widget.spec)`
   and set `_ownsController = true`. Dispose it in `dispose()` only when owned. Handle a
   changed `widget.controller` in `didUpdateWidget` (dispose an owned one you are
   replacing; never dispose the host's).

2. Seed the controller from the bloc's current values on first build, so an existing host
   that provided a pre-populated bloc still renders its plate.

3. Replace the two closures in `_installMachine` (currently
   `readValues: () => context.read<PlateCardBloc>()...` and
   `commit: (i,v) => context.read<PlateCardBloc>().add(...)`) with
   `readValues: () => _controller.values` and `commit: _controller.setAt`.
   This is the point of the stage: those closures outlive the build that created them and
   currently capture BuildContext. After this change nothing long-lived holds a context.
   Do the same for `_probeValidation` (read `_controller.values`) and `_openPicker`
   (write `_controller.setAt(index, chosen)` instead of `bloc.add(ValueIsChanged(...))`).

4. Add a private two-way bridge so the bloc stays authoritative for hosts that write to it
   directly. Two real consumers do exactly that and must keep working unchanged:
   `plate_number_holder/lib/showcase/plate_typist.dart` dispatches
   `bloc.add(ValueIsChanged(...))` at three sites, and
   `plate_number_holder/lib/showcase/device_stage.dart` drives a second plate from
   `_bloc.stream`. Read both before writing the bridge.
   The bridge: controller listener → dispatch `ValueIsChanged` for each changed slot;
   bloc subscription → `_controller.setValues(state.plateNumber.values)`. Guard the echo
   with a re-entrancy flag so one write settles in a single pass and never loops. Put it
   in a private class in plate_canvas.dart; it is not public API this stage.

5. `didUpdateWidget`'s spec-change branch keeps dispatching `SpecIsChanged` for now AND
   additionally re-founds the controller for the new spec. Do not change what a spec swap
   does to the value — it still clears. That is stage 4.

CONSTRAINTS
- The bindings `_FrameBinding`, `_SlotBinding`, `_MirrorBinding` and `_ValidationBinding`
  keep reading the bloc via `context.select` / `BlocSelector`. Untouched this stage.
- `plate_input_machine.dart` must not change. Its independence from bloc is the seam this
  whole refactor rests on.
- No public API change. `PlateCanvas`'s constructor and parameter types are unchanged.
- No country name anywhere in core_plate.
- Note: `_SlotBinding.build` calls `machine.syncController(index, value)` from inside
  build, and that is load-bearing ordering — leave it exactly where it is.

ACCEPTANCE CHECK
- `flutter analyze` clean across core_plate and every sibling package and example app.
- These apps must still run and behave identically — typing, focus advance, backspace,
  the character picker, and the completed-plate border shift:
    core_plate/example, iran_plate/example, yemen_plate/example,
    palestine_plate/example, plate_number_holder (the showcase, whose auto-typist writes
    straight to the bloc — verify the plate still fills in and the second stacked plate
    still mirrors).
- `grep -n 'context\.read\|context\.select' core_plate/lib/src/widgets/plate_canvas.dart`
  must show NO hits inside `_installMachine`, `_probeValidation` or `_openPicker`.
Finish with analyzer clean + a git commit.
