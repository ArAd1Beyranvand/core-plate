---
name: task-5-bloc-becomes-optional
description: "PlateController refactor — Stage 5 of 7: make the ancestor PlateCardBloc optional, ship PlateCardBinding + PlateView + PlateTextView in core_plate, and migrate every consumer and all six example apps off BlocProvider, dropping flutter_bloc from five consumer pubspecs. Invoke when the user runs /task for stage 5."
---

# Stage 5 — the bloc becomes optional

**Recommended model: Opus 5, medium reasoning, thinking ON.**
Broad, workspace-wide migration touching ~20 files across six packages and six example
apps. No single edit is hard, but the coordination and the "nothing looks different"
constraint reward a capable model.

Run the prompt below in a fresh session. Stage 5 of 7 — still non-breaking. Previous:
`task-4-spec-swap-keeps-value`. Next: `task-6-extract-core-plate-bloc` (breaking, 0.4.0).
Acceptance check and commit.

---

Repo: /home/aradbeyranvand/StudioProjects/plate. This stage spans the whole workspace.
Read core_plate/CLAUDE.md and follow it for core_plate edits. Read the named files in
full first. Do not create or edit files under core_plate/test (there is none and there
must not be); palestine_plate's existing tests you WILL edit — see below.

CONTEXT
Stage 5 of 7. `PlateController` owns the plate's values; `PlateCanvas` holds one and its
bindings read it; a private bridge inside plate_canvas.dart mirrors an ancestor
`PlateCardBloc` in both directions. The bloc is still REQUIRED: without a
`BlocProvider<PlateCardBloc>` above it the canvas throws on first build.

This stage makes it optional and migrates every consumer. Nothing breaks: a canvas with a
bloc above it still works.

FILES YOU MAY TOUCH
  core_plate/lib/src/widgets/plate_canvas.dart
  core_plate/lib/src/widgets/plate_card_binding.dart   (new)
  core_plate/lib/src/widgets/plate_view.dart           (new)
  core_plate/lib/core_plate.dart
  core_plate/example/lib/main.dart, core_plate/example/pubspec.yaml
  iran_plate/example/lib/main.dart, iran_plate/example/pubspec.yaml
  germany_plate/example/lib/main.dart, germany_plate/example/pubspec.yaml
  yemen_plate/example/lib/main.dart, yemen_plate/example/lib/gallery.dart,
    yemen_plate/example/pubspec.yaml
  palestine_plate/example/lib/main.dart, palestine_plate/example/lib/gallery.dart,
    palestine_plate/example/pubspec.yaml
  palestine_plate/pubspec.yaml, palestine_plate/test/golden_test.dart
  plate_number_holder/lib/minimal/main.dart
  plate_number_holder/lib/widgets/plate_display.dart
  plate_number_holder/lib/showcase/device_stage.dart
  plate_number_holder/lib/showcase/plate_typist.dart
  plate_number_holder/pubspec.yaml

WHAT TO DO

1. In `PlateCanvas`, make the ancestor bloc optional. Look it up defensively (a failed
   lookup is not an error); when one is present, install the existing bridge and emit a
   `debugPrint` deprecation notice once per canvas saying the host should hand the canvas
   a `PlateController` and, if it needs bloc, wrap it in `PlateCardBinding`. When none is
   present, run controller-only.

2. Ship `PlateCardBinding` (new file): a StatefulWidget taking
   `{required PlateController controller, PlateCardBloc? bloc, required Widget child}`.
   It creates and owns a bloc when given none, provides it to the subtree with
   `BlocProvider.value`, and runs the same two-way mirror with the same echo guard. Move
   the bridge logic out of plate_canvas.dart into it and have the canvas's
   deprecated auto-adoption path reuse it. This is the public migration seam for
   bloc-based hosts and it is what moves to its own package in stage 6.

3. Ship `PlateView` and `PlateTextView` (new file plate_view.dart): controller-driven
   equivalents of `ShowPlate` and `PlateText`. `PlateView` takes
   `{required PlateController controller, PlateTheme? theme, Widget? emptyPlate}` and
   renders `PlateCanvas(mode: PlateMode.display)` — note it takes a theme, which
   `ShowPlate` does not; two consumers have local reimplementations solely for that
   reason (yemen_plate/example/lib/main.dart `_ShowPlateLike` and
   plate_number_holder's `_SecondaryPlate`), and both should collapse onto `PlateView`.
   `PlateTextView` mirrors `PlateText`, bounds-checked. Leave `ShowPlate`/`PlateText`
   in place and untouched; they move out in stage 6. Export the new widgets.

4. Migrate every consumer off `BlocProvider`. In each case the replacement is either a
   `PlateController` the host holds, or nothing at all where the canvas can own its own:
   - core_plate/example, iran_plate/example, germany_plate/example, minimal/main.dart:
     delete the provider entirely, leaving a bare `PlateCanvas(spec: …)`. Delete
     `flutter_bloc` from those pubspecs. These four are the "developer-friendliness bar" —
     after this stage the minimal example is a widget and a spec, nothing else.
   - yemen_plate/example and palestine_plate/example galleries: one `PlateController` per
     tile, or none where the tile only displays.
   - yemen_plate/example `_ShowPlateLike` and the seeded `ValueIsChanged` loop:
     `PlateController.fromValues(spec, values)` + `PlateView`.
   - palestine_plate/example/lib/main.dart: the top-level provider and the `BlocBuilder`
     become a host-held `PlateController` + `ListenableBuilder`; line ~502's provider +
     seed loop + `ShowPlate` becomes `PlateController.fromValues` + `PlateView`.
   - palestine_plate/test/golden_test.dart: seed a `PlateController` and render
     `PlateView` instead of bloc + `BlocProvider.value` + `ShowPlate`. Then delete the
     `flutter_bloc` dev-dependency and its explanatory comment from
     palestine_plate/pubspec.yaml — that dep exists ONLY for this test.
   - plate_number_holder/lib/widgets/plate_display.dart: rename `bloc:` → `controller:`
     (`PlateController?`) and `secondaryBloc:` → `secondaryController:`; delete both
     `BlocProvider`s and the `BlocProvider.value` in `_SecondaryPlate`; collapse
     `_SecondaryPlate` onto `PlateView`.
   - plate_number_holder/lib/showcase/device_stage.dart: `_bloc` and `_secondaryBloc`
     become `PlateController`s; the `StreamSubscription<PlateCardState> _mirror` becomes
     a controller listener that calls `mirrorByGroup` and writes with `setValues`. The
     existing comment explaining why the mirror is a subscription rather than a
     BlocListener still applies — keep its substance.
   - plate_number_holder/lib/showcase/plate_typist.dart: DELETE the `bloc:` parameter from
     `run`, `_runStep` and `_pickLetter` (four signatures) and replace the three
     `bloc.add(ValueIsChanged(index:…, value:…))` calls with `controller.setAt(…)`. This
     is the visible payoff of the merge: the typist now takes one object where it took
     two.
   - Delete `flutter_bloc` from plate_number_holder/pubspec.yaml and its comment.

CONSTRAINTS
- `core_plate`'s pubspec still lists flutter_bloc this stage — `PlateCardBinding`,
  `ShowPlate` and `PlateText` still live in core. Removing it is stage 6.
- No country name anywhere in core_plate.
- Do not change `PlateInputMachine`.
- Do not change what any app LOOKS like. This is a state-plumbing change.

ACCEPTANCE CHECK
- `flutter analyze` clean across all seven packages and all six example apps.
- `grep -rn "BlocProvider" --include=*.dart .` returns hits ONLY inside
  core_plate/lib/src/widgets/plate_card_binding.dart and
  core_plate/lib/src/widgets/show_plate.dart.
- These must run with behaviour unchanged: core_plate/example, iran_plate/example,
  germany_plate/example, yemen_plate/example (including the gallery),
  palestine_plate/example (including the gallery and the mid-entry scheme switch),
  plate_number_holder (the full showcase — device cycling, the auto-typist, the stacked
  second plate, the tablet keypad and the laptop deck keys).
- palestine_plate's four test files still pass.
Finish with analyzer clean + a git commit.
