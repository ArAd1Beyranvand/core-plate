---
name: task-4-spec-swap-keeps-value
description: "PlateController refactor — Stage 4 of 7: add PlateCanvas.onSpecChange so swapping spec: on a live canvas carries the value across via adoptSpec, fix PlateText's bounds bug, update five doc warnings in yemen_plate/palestine_plate, and delete the _switchTo workaround in palestine_plate/example. Invoke when the user runs /task for stage 4."
---

# Stage 4 — spec swap keeps the value

**Recommended model: Sonnet 5, medium reasoning, thinking ON.**
The wiring is straightforward; the judgement is in rewriting the doc warnings and
confirming the migration behaves better than the deleted workaround.

Run the prompt below in a fresh session. Stage 4 of 7 — the first user-visible payoff,
lands before any breaking change. Previous: `task-3-bindings-read-controller`. Next:
`task-5-bloc-becomes-optional`. Acceptance check and commit.

---

Repo: /home/aradbeyranvand/StudioProjects/plate. Working in `core_plate`, plus doc-only
edits in `yemen_plate` and `palestine_plate` and one real edit in
`palestine_plate/example`.
Read core_plate/CLAUDE.md and follow it for core_plate. Read the named files in full
first. Never create or edit files under any `test/` directory; do not run `flutter test`.

CONTEXT
Stage 4 of 7. `PlateController` (lib/src/input/plate_controller.dart) already owns the
plate's values and already implements `adoptSpec(next, {preserve})` with a
`PlateValuePreservation` enum (none / byIndex / byGroupKey). `PlateCanvas` already holds a
controller and its bindings already read it.

THE BUG THIS FIXES. Swapping `spec:` on a live `PlateCanvas` wipes the plate.
`PlateCanvas.didUpdateWidget` dispatches `SpecIsChanged` when `spec.id` changes, and
`PlateCardBloc`'s handler emits `PlateCardState.empty(event.spec)` unconditionally. Five
consumer doc comments warn users about this, and one example app carries a post-frame
re-seed workaround to paper over it:
  yemen_plate/lib/src/northern_plates.dart  (~line 1108)
  yemen_plate/lib/src/unified_plates.dart   (~lines 29, 864)
  palestine_plate/lib/src/west_bank_plates.dart (~lines 217, 251)
  palestine_plate/example/lib/main.dart     (the comment block and `_switchTo`, ~180-221)

FILES YOU MAY TOUCH
  core_plate/lib/src/widgets/plate_canvas.dart
  core_plate/lib/src/widgets/show_plate.dart
  core_plate/lib/src/input/plate_controller.dart   (only if adoptSpec has a real gap)
  yemen_plate/lib/src/northern_plates.dart         (doc comments only)
  yemen_plate/lib/src/unified_plates.dart          (doc comments only)
  palestine_plate/lib/src/west_bank_plates.dart    (doc comments only)
  palestine_plate/example/lib/main.dart

WHAT TO DO

1. Add to `PlateCanvas`:
     final PlateValuePreservation onSpecChange;
   defaulting to `PlateValuePreservation.none` — today's behaviour, so this stage breaks
   nobody. Document that the default will change to `byGroupKey` in 0.4.0.

2. In `didUpdateWidget`'s `spec.id` branch, call
   `_controller.adoptSpec(widget.spec, preserve: widget.onSpecChange)` instead of
   dispatching `SpecIsChanged` from the canvas. The bloc bridge from stage 2 mirrors the
   resulting values out, so a bloc-holding host sees the migrated plate. Keep disposing
   and rebuilding the `PlateInputMachine` exactly as it does now — a machine belongs to
   one spec and its focus nodes cannot be reindexed.

3. Fix the latent range bug in `PlateText` (show_plate.dart): it indexes `values[i]`
   directly for every group index while `PlateSpec.renderGroup` bounds-checks. During a
   spec change the value list can be shorter than the new spec's group indices and this
   throws. Guard it the same way `renderGroup` does.

4. Rewrite the five doc warnings listed above. They currently tell users to pick the spec
   before entry begins because a swap resets the bloc. The new text: a swap carries the
   value across per `PlateCanvas.onSpecChange`, and `byGroupKey` is what lets e.g. a
   change of serial length keep the serial and truncate only what no longer fits. Do not
   name the mechanism as "the bloc" — it is the controller now.

5. In palestine_plate/example/lib/main.dart, DELETE the `_switchTo` post-frame re-seed
   workaround (the `WidgetsBinding.instance.addPostFrameCallback` block that replays old
   values as `ValueIsChanged`) and the 14-line comment above it explaining why it exists,
   and pass `onSpecChange: PlateValuePreservation.byGroupKey` to the canvas instead. The
   app must behave BETTER than before: switching scheme or usage mid-entry now keeps the
   serial rather than re-seeding it positionally.

CONSTRAINTS
- `SpecIsChanged` and its handler stay in place; nothing else dispatches it, but removing
  a public event is a breaking change reserved for stage 6.
- No country name anywhere in core_plate — the doc edits in yemen_plate/palestine_plate
  are in those packages, which is fine.
- No pubspec changes.

ACCEPTANCE CHECK
- `flutter analyze` clean across core_plate and every sibling package and example app.
- palestine_plate/example: type a plate, switch region/scheme/usage/form-factor — the
  serial survives, and a character the new alphabet refuses is dropped rather than forced.
- yemen_plate/example: switch between the unified and northern plates mid-entry and
  confirm the governorate and serial land in the right registers, not positionally.
- palestine_plate's existing tests under test/ must still COMPILE and pass unchanged; do
  not edit them.
- core_plate/example and iran_plate/example still run.
Finish with analyzer clean + a git commit.
