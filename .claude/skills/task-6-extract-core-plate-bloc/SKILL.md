---
name: task-6-extract-core-plate-bloc
description: "PlateController refactor — Stage 6 of 7 (BREAKING, 0.4.0): extract a new core_plate_bloc sibling package holding PlateCardBloc/State/events, PlateCardBinding, ShowPlate and PlateText; drop flutter_bloc + bloc from core_plate; delete the deprecated bloc auto-adoption path; flip onSpecChange default to byGroupKey. Invoke when the user runs /task for stage 6."
---

# Stage 6 — extract `core_plate_bloc` (BREAKING, 0.4.0)

**Recommended model: Opus 5, medium reasoning, thinking ON.**
A new package with its own pubspec/example, verbatim code moves across packages, an
export surface change, and a behaviour-flipping default — plus a CHANGELOG a stranger
must be able to migrate from. Breaking release; worth the stronger model.

Run the prompt below in a fresh session. Stage 6 of 7 — this is the 0.4.0 release and it
IS breaking. Previous: `task-5-bloc-becomes-optional`. Next: `task-7-merge-controllers`.
Acceptance check and commit.

---

Repo: /home/aradbeyranvand/StudioProjects/plate. This stage spans the workspace and is
BREAKING — it is the 0.4.0 release.
Read core_plate/CLAUDE.md and follow it for core_plate edits. Read the named files in
full first. Do not create tests in core_plate or core_plate_bloc.

CONTEXT
Stage 6 of 7. After stage 5, `PlateController` is the primary API, `PlateCanvas` works
with no bloc anywhere in the tree, `PlateCardBinding` is the seam for bloc-based hosts,
and NO consumer in this workspace uses `BlocProvider` any more. `core_plate` still
declares `flutter_bloc` and `bloc` as dependencies purely to host the bloc types,
`PlateCardBinding`, `ShowPlate` and `PlateText`.

This stage moves all of that into a new sibling package so `core_plate` has a zero-bloc
dependency, and flips the spec-change default.

FILES YOU MAY TOUCH
  core_plate_bloc/**                                   (new package)
  core_plate/lib/src/bloc/**                           (moved out, then deleted)
  core_plate/lib/src/widgets/show_plate.dart           (moved out, then deleted)
  core_plate/lib/src/widgets/plate_card_binding.dart   (moved out, then deleted)
  core_plate/lib/src/widgets/plate_canvas.dart
  core_plate/lib/core_plate.dart
  core_plate/pubspec.yaml, core_plate/CHANGELOG.md
  palestine_plate/pubspec.yaml + test/golden_test.dart  (only if they still reference any
    moved symbol — they should not after stage 5)
  plate_number_holder/**  (only if it still references a moved symbol)

WHAT TO DO

1. Create `core_plate_bloc` as a sibling package (same layout and conventions as
   `plate_keypad`, which is the workspace's existing example of a package split off from
   core — read its pubspec.yaml and its lib/plate_keypad.dart library doc comment and
   match that style). It depends on `core_plate`, `flutter_bloc` and `bloc`. Move into it,
   unchanged in behaviour:
     PlateCardBloc, PlateCardEvent, ValueIsChanged, RemovePlateCard, SpecIsChanged,
     PlateCardState, PlateCardBinding, ShowPlate, PlateText.
   Note `RemovePlateCard` has no dispatcher anywhere in the workspace — move it anyway,
   and mark it deprecated in the new package rather than deleting it silently.
   `PlateCardBloc.spec` is a dead field after construction (only `PlateCardState.spec` is
   read); delete it as part of the move.

2. Delete the moved files from core_plate, remove `flutter_bloc` and `bloc` from
   core_plate/pubspec.yaml, and remove their exports from core_plate.dart. Update
   core_plate.dart's "State — the bloc a canvas keeps its values in" section: it becomes
   the controller, and the library doc comment's list of things the package deliberately
   does not do gains "it does not choose your state management".

3. Delete `PlateCanvas`'s deprecated auto-adoption of an ancestor bloc (the defensive
   lookup, the bridge install and the debugPrint from stage 5). A host that wants bloc
   wraps the canvas in `PlateCardBinding` from the new package.

4. Flip `PlateCanvas.onSpecChange`'s default from `PlateValuePreservation.none` to
   `PlateValuePreservation.byGroupKey`. Update its doc comment. This changes behaviour for
   anyone who swapped `spec:` and relied on the wipe — it belongs in this release and
   nowhere else.

5. Write core_plate/CHANGELOG.md for 0.4.0: what moved, the one-line migration for a bloc
   host (add `core_plate_bloc`, wrap in `PlateCardBinding(controller: …)`, everything else
   unchanged), the `ShowPlate`→`PlateView` / `PlateText`→`PlateTextView` mapping, and the
   `onSpecChange` default flip. Be specific enough that a consumer can migrate from the
   changelog alone.

CONSTRAINTS
- No country name anywhere in core_plate or core_plate_bloc.
- `PlateInputMachine` still must not change. It has not changed in any stage; that is the
  point.
- Do not use this stage to redesign the bloc. It moves verbatim (minus the dead field).

ACCEPTANCE CHECK
- `core_plate/pubspec.yaml` has no `bloc` or `flutter_bloc` entry, and
  `grep -rn "bloc" core_plate/lib/` returns only prose in changelog-style comments.
- `flutter analyze` clean across all eight packages and all six example apps.
- All six examples still run: core_plate, iran_plate, germany_plate, yemen_plate,
  palestine_plate, plate_keypad — plus the plate_number_holder showcase end to end.
- palestine_plate's tests still pass.
- Add a minimal `core_plate_bloc/example` proving the bloc path still works: a
  `PlateController` + `PlateCardBinding` + `PlateCanvas` with a `BlocBuilder` reading the
  value out. It must run.
Finish with analyzer clean + a git commit.
