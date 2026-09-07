---
name: task-3-bindings-read-controller
description: "PlateController refactor — Stage 3 of 7: move PlateCanvas's four bindings (_SlotBinding, _MirrorBinding, _FrameBinding, _ValidationBinding) off the bloc onto controller listenables, preserving the per-slot rebuild-narrowing property. Invoke when the user runs /task for stage 3."
---

# Stage 3 — bindings read the controller

**Recommended model: Sonnet 5, medium reasoning, thinking ON.**
Mechanical swap once stage 2 proved the controller carries the same values — but the
per-slot narrowing invariant must be verified empirically, so don't rush the check.

Run the prompt below in a fresh session. Stage 3 of 7. Previous:
`task-2-canvas-owns-controller`. Next: `task-4-spec-swap-keeps-value`. Acceptance check
and commit before stopping.

---

Repo: /home/aradbeyranvand/StudioProjects/plate. Working in `core_plate`.
Read core_plate/CLAUDE.md and follow it. Read the named files in full first. Never create
or edit files under any `test/` directory; do not run `flutter test`.

CONTEXT
Stage 3 of 7. Stage 1 added `PlateController` with per-slot `ValueListenable<String?>
slot(int)`, a `ValueListenable<bool> completed`, and a `PlateSelector<T>` widget. Stage 2
made `_PlateCanvasState` own a `PlateController` and made it the writer of record, with a
private two-way bridge keeping the ancestor `PlateCardBloc` in sync. The widget bindings
still read the bloc.

This stage moves the four bindings onto the controller. After it, the only thing in the
widget layer that talks to bloc is the bridge from stage 2.

FILES YOU MAY TOUCH
  core_plate/lib/src/widgets/plate_canvas.dart

READ FIRST (do not edit)
  core_plate/lib/src/input/plate_controller.dart
  core_plate/lib/src/widgets/plate_selector.dart
  core_plate/lib/src/validators/plate_validator.dart
  core_plate/lib/src/input/plate_input_machine.dart

WHAT TO DO — the rebuild-narrowing property is the whole point; preserve it exactly.
The long NOTE comment in `PlateCanvas.build` (it begins "this build deliberately does NOT
watch the plate value") states the invariant: one keystroke rebuilds one slot plus any
mirrors pointed at it, and nothing else. Read it, keep it true, and update its wording to
describe listenables instead of `context.select`.

1. `_SlotBinding`: replace `context.select<PlateCardBloc, String?>` with
   `ValueListenableBuilder<String?>(valueListenable: controller.slot(index), …)`.
   Pass the controller in as a field. `machine.syncController(index, value)` must stay
   INSIDE that builder and ABOVE `PlateSlotItem` — it mutates a TextEditingController
   during build and only works because it runs before that slot's TextField builds in the
   same frame. `onChanged` becomes `(v) => controller.setAt(index, v)`; drop the
   `context.read<PlateCardBloc>()`.

2. `_MirrorBinding`: identical treatment —
   `ValueListenableBuilder<String?>(valueListenable: controller.slot(mirror.source), …)`.
   It owns no focus node and no text controller, so there is no sync call. If
   `_MirrorBinding` is not present in your checkout, a concurrent workstream is adding it
   (a read-only projection of one slot's value, subscribed like `_SlotBinding`) — in that
   case skip this step and say so in the commit message, and DO NOT restructure
   `_SlotBinding` in a way that would make the same treatment awkward for it later.

3. `_FrameBinding`: replace `context.select<PlateCardBloc, bool>` with
   `ValueListenableBuilder<bool>(valueListenable: controller.completed, …)`.

4. `_ValidationBinding`: replace the `BlocSelector<PlateCardBloc, PlateCardState,
   PlateValidation>` with `PlateSelector<PlateValidation>` over the controller, selecting
   `validate(controller.values)`. `PlateValidation` compares by `reason`, so the builder
   must still run only on a valid⇄invalid flip, not per keystroke. `_VerdictListener` is
   unchanged — keep publishing the verdict from its lifecycle callbacks, never from build.

5. Delete any `flutter_bloc` import from the binding classes if nothing else in the file
   needs it. The bridge from stage 2 still does, so the file-level import probably stays.

CONSTRAINTS
- Public API unchanged. No pubspec change. `plate_input_machine.dart` unchanged.
- No country name anywhere in core_plate.
- Do not "simplify" by having the canvas rebuild on the whole controller — that is
  precisely the regression the NOTE comment exists to prevent.

ACCEPTANCE CHECK
- `flutter analyze` clean across core_plate and every sibling package and example app.
- Run plate_number_holder's showcase and yemen_plate/example and type into a plate: the
  plate fills in normally, the frame only shifts when the last slot lands, and a plate
  with mirrors keeps its echoes in step.
- Verify narrowing empirically before committing: temporarily add a debugPrint in
  `_SlotBinding.build` and confirm one keystroke prints once, not once per slot. REMOVE
  the debugPrint before committing.
Finish with analyzer clean + a git commit.
