---
name: p10-core-package
description: "Refactor phase P10 of the plate_number split — create the pub workspace and packages/core_plate, reduce the root plate_number package to a re-export facade, and establish one shared, slightly stricter analysis_options.yaml across every workspace member. Use when the user asks to run P10 or create the core package."
---

# P10 — The core package

Follow `CLAUDE.md` working style. Requires **P9** committed and the P8 acceptance grep
returning nothing. This project does not use automated tests — do not write, update, or move
anything under `test/`, and do not run `flutter test`. Finish analyzer-clean, committed;
report diffstat and hashes only.

This phase is mechanical. If it turns out not to be — if moving a file forces a logic change —
stop and report it, because it means an earlier phase left a leak.

## Prerequisite: settle the naming decision

`docs/split/PLAN.md` §5.1 leaves `core_plate` / `iran_plate` / `germany_plate` versus
`plate_core` / `plate_ir` / `plate_de` open. Confirm with the user before creating
directories. Everything below assumes the first form.

Note that the repo itself is now called `plate-core` (renamed from `plate-number-upgrade`,
commit `8e52fd9`). That is the *repository* directory, not a package name — the package inside
`packages/` is still `core_plate` and the root package is still `plate_number`. Do not let the
repo name be mistaken for the naming decision having been settled.

## Also in this pass: a shared, slightly stricter lint config

`analysis_options.yaml` today includes only stock `flutter_lints` with zero project rules —
this is how the raw `Emitter` in `plate_card_bloc.dart` (fixed in P5) went uncaught. Splitting
into five packages is the natural point to fix this once, at the workspace root, rather than
five times:

1. Root `analysis_options.yaml` becomes the shared config, kept where it is (workspace root).
   Add to its `analyzer:` section — not present at all today —
   ```yaml
   analyzer:
     language:
       strict-casts: true
       strict-inference: true
       strict-raw-types: true
   ```
   `strict-raw-types` is specifically what would have caught the bare `Emitter`. Run
   `flutter analyze` immediately after adding this, before doing anything else in this phase —
   it may surface other raw-type or inference gaps across the newly-moved files that are worth
   fixing now, while you are already touching every file for the move, rather than later as a
   surprise in some other phase.
2. Each member package's own `analysis_options.yaml` (created by `flutter create
   --template=package`) becomes just:
   ```yaml
   include: ../../analysis_options.yaml
   ```
   so every package in the workspace shares one lint configuration, adjustable in one place.
3. Do not add lint rules beyond the three `analyzer.language` settings above in this phase.
   The point is closing the specific gap that let a real bug through, not a general lint
   audit — that is a different, larger piece of work the user hasn't asked for here.

## Do

### Workspace

1. Root `pubspec.yaml` becomes the workspace root. Dart pub workspaces need ≥3.6; the
   existing constraint is `>=3.10.0 <4.0.0`, so no change there.

```yaml
name: plate_number
# … existing fields …
workspace:
  - packages/core_plate
```

   Each member package declares `resolution: workspace`. One `flutter pub get` at the root
   then resolves everything and links the members without path-dependency churn.

   If `melos` is preferred instead, say so and stop — the file layout is the same but the
   wiring differs and it should be a deliberate choice, not a default.

### `packages/core_plate`

2. Create the package with `flutter create --template=package packages/core_plate`, then
   replace its generated `lib/` wholesale.

3. Move, without editing bodies:

```
lib/model/plate_box.dart              lib/widgets/plate_canvas.dart
lib/model/plate_spec.dart             lib/widgets/plate_slot_item.dart
lib/model/plate_alphabet.dart         lib/widgets/plate_frame.dart
lib/model/plate_country.dart          lib/widgets/plate_flag.dart
lib/model/plate_number.dart           lib/widgets/country_panel.dart
lib/model/plate_input_source.dart     lib/widgets/plate_character_picker.dart
lib/model/slot_behavior.dart          lib/widgets/show_plate.dart
lib/theme/plate_theme.dart            lib/validators/plate_validator.dart
lib/bloc/*                            lib/input/plate_input_controller.dart
                                      lib/input/plate_input_machine.dart
```

4. **Stays behind** in the root package for now: `lib/countries/iran.dart`,
   `lib/countries/germany.dart`, `lib/validators/german_plate_validator.dart`,
   `lib/widgets/plate_keypad.dart`, and the `assets/` directory. P11 and P12 move those.

   The root package therefore depends on `core_plate` for the duration.

5. Relative imports mostly survive the move unchanged because the directory shape is
   preserved. Fix the ones that do not with an analyzer pass, not by hand-editing every file.

6. `packages/core_plate/lib/core_plate.dart` is the barrel — the current
   `lib/plate_number.dart` export list minus the country files, the keypad and the German
   validator, plus the new `plate_box.dart`, `slot_behavior.dart`, `plate_input_machine.dart`
   and `plate_validator.dart`.

7. `packages/core_plate/pubspec.yaml` dependencies: `flutter`, `bloc`, `flutter_bloc`,
   `flutter_svg`. **Not** `country_flags` (removed in P8) and **not** `bloc_concurrency`
   (removed in P5). If either reappears, something regressed.

8. This project does not use automated tests, so there is no `test/` directory to split
   between packages — skip this step entirely; do not create one.

### The facade

9. Root `lib/plate_number.dart` becomes:

```dart
/// Compatibility facade. Depends on every plate package and re-exports them,
/// so an app can keep a single `package:plate_number/plate_number.dart`
/// import. Retired in P12 unless the packages are published, in which case
/// this is what most consumers should depend on — see docs/split/PLAN.md §5.2.
library plate_number;

export 'package:core_plate/core_plate.dart';
export 'countries/iran.dart';
export 'countries/germany.dart';
export 'validators/german_plate_validator.dart';
export 'widgets/plate_keypad.dart';
```

10. `plate_number_holder`'s `pubspec.yaml` and every import are **unchanged** in this phase.
    That is the point: the facade absorbs the move.

### Asset paths

11. `PlateAsset`/`PlateDecal` literals still name `package: 'plate_number'` and the assets are
    still declared in the root `pubspec.yaml`. Leave both. P11 moves the assets and updates
    the package strings in the same commit, so there is never a state where a literal points
    at a package that does not own the file.

## Widgets, not widget functions

`claude.md` §1 forbids widget-returning functions, and from here on every phase enforces it in
the files it already edits — this phase moves files without editing bodies, so it converts nothing. If a widget function survives into `core_plate`, an earlier phase missed it — report it rather than fixing it here.

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
cd plate-core
flutter pub get                      # at the workspace root
flutter analyze
cd ../plate_number_holder && flutter analyze && flutter run
```

(Do not run `flutter test` — this project does not use automated tests.)

Then confirm the split is real:

```bash
grep -rniE "iran|german|persian" plate-core/packages/core_plate/lib/
```

Must return nothing.

Expected: no net line change. Files moved, one barrel written, one facade written.
