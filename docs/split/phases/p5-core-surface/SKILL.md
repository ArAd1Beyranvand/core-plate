---
name: p5-core-surface
description: "Phase P5 of the plate split (second edition) — decide what core's public API actually is, move everything else under lib/src/, and turn the barrel from a dump of every file into a written contract. Use when the user asks to run P5 or work on the core's public surface."
---

# P5 — The core's public surface

Follow `CLAUDE.md` working style. **Requires P1–P4 committed** — they are still adding and
removing public names, and doing this twice is worse than doing it late. This project does not
use automated tests: do not write or update anything under `test/`, and do not run
`flutter test`. Finish analyzer-clean in both repos, committed; report diffstat and hashes only.

**This is the pivot phase.** Everything before it improves a library. Everything after it moves
files between packages. The move is only safe if "what is public" is a decision rather than an
accident, because after P7/P8 an accidental export is a cross-package compile error and a
missing one is a consumer who cannot do their job.

## The problem

`lib/plate_number.dart` is eighteen `export` lines and no thought:

```dart
export 'model/plate_number.dart';      export 'widgets/show_plate.dart';
export 'model/plate_input_source.dart';export 'widgets/country_panel.dart';
export 'model/plate_country.dart';     export 'widgets/plate_flag.dart';
export 'model/plate_alphabet.dart';    export 'widgets/plate_canvas.dart';
export 'model/slot_behavior.dart';     export 'widgets/plate_character_picker.dart';
export 'model/plate_spec.dart';        export 'widgets/plate_keypad.dart';
export 'bloc/plate_card_bloc.dart';    export 'widgets/plate_slot_item.dart';
export 'theme/plate_theme.dart';       export 'validators/german_plate_validator.dart';
                                       export 'input/plate_input_controller.dart';
                                       export 'input/plate_input_machine.dart';
```

Every file in `lib/` is exported, so every top-level name in every file is public, so every one
of them is something a consumer can depend on and this project can break. Nothing is under
`lib/src/`, which is the one mechanism Dart gives you to say "this is mine."

That is survivable in one package. Across four it is not: `iran_plate` will import
`core_plate`, and whatever `core_plate` exports is what `iran_plate` — and everyone else — is
allowed to reach for.

## Do

### 1. Classify, before moving anything

Walk every top-level name in `lib/` and put it in exactly one bucket. Write the classification
into the report as a table; it is the deliverable of this step and the thing to argue about, not
the file moves that follow.

- **Public API** — a consumer constructs it, passes it, reads it or implements it.
  Expected members: `PlateSpec`, `PlateSlot`, `PlateBox`, `PlateTextGroup`, `PlateLabel`,
  `PlateDecal`, `PlateAlphabet`, `PlateCountry`, `PlateAsset` (+ subclasses), `PlateNumber`,
  `PlateInputSource`, `SlotBehavior`, `PlateTheme`, `PlateValidator`, `PlateValidation`,
  `PlateEntry`, `PlateCardBloc` + its events and state, `PlateCanvas`, `ShowPlate`,
  `PlateText`, `PlateFlag`, `CountryPanel`, `PlateInputController`.
- **Internal** — real implementation that no consumer should name. `PlateInputMachine` is the
  interesting case: `PlateInputController` is the host-facing handle and the machine is what it
  drives. If a consumer never constructs one, it is internal even though it is a real
  abstraction.
- **Undecided** — say so out loud rather than defaulting. `PlateSlotItem` (is a host meant to
  build one directly, or only ever get them from a canvas?) and `PlateCharacterPicker` (whose
  fate P7 asks about) both belong here. **Ask the user about anything in this bucket before
  moving it.** A wrong call here is an API break later.

### 2. `lib/src/`

Move everything classified internal under `lib/src/`, preserving the directory shape
(`lib/src/widgets/…`, `lib/src/model/…`). Public files can live under `lib/src/` too — the
convention that survives the package split is: **`lib/` holds barrels only, `lib/src/` holds
code, and the barrel decides what is public.** That is simpler than sorting files into two
trees by visibility and it is what `flutter create --template=package` produces.

So: `git mv` everything in `lib/` except the barrel into `lib/src/`, then let the barrel do the
work. Relative imports mostly survive because the directory shape is preserved; fix the
stragglers with an analyzer pass, not by hand-editing every file.

Use `git mv` so the history follows the files. A move that shows up as delete+add makes every
future `git log --follow` useless.

### 3. The barrel becomes a document

`lib/plate_number.dart` (still named that until P9) gets:

- a `library` doc comment saying what the package is and what it deliberately does not do
- the exports grouped and commented by role — the model, the theme, the widgets, input,
  validation
- **`show:` clauses where a file holds both public and internal names**, rather than exporting
  the file wholesale and hoping

An export list that needs no `show:` anywhere is a sign that step 1 was skipped.

### 4. `part`/`part of` audit

If any file uses `part of`, it must move together with its parent. Check before moving; a
split `part` pair fails in a way the analyzer explains badly.

### 5. Fix the fallout in the holder

Every `package:plate_number/model/…`-style deep import in `plate_number_holder` breaks now,
which is the point — deep imports into another package's `src/` are exactly what this phase
exists to prevent. Rewrite them all to the barrel. `lib/dev/flag_panel_gallery.dart` is the
known offender (four deep paths); grep for the rest rather than trusting that list:

```bash
cd plate_number_holder && grep -rn "package:plate_number/[a-z_]*/" lib/
```

Must return nothing when this phase is done.

### 6. What this phase does not do

- No renames. `plate_number` → `core_plate` is P9.
- No new packages. P7 and P8.
- No deletions. Dead code is P6, even if step 1 makes it obvious. `claude.md` §5.
- No behaviour changes at all. If a file's body changes for any reason other than an import
  line, stop and explain why in the report.

## Widgets, not widget functions

Per `PLAN.md` §5. This phase moves files without editing bodies, so it converts nothing. If a
widget function turns up during the classification walk, **report it** — it means P1–P4 missed
one in a file they touched — but do not fix it here.

## Verify

```
cd plate-core            && flutter analyze
cd ../plate_number_holder && flutter analyze && flutter run
```

(Do not run `flutter test`.)

Then prove the surface is real, not nominal:

```bash
# nothing outside the barrel is reachable by a deep import
cd plate_number_holder && grep -rn "package:plate_number/" lib/ | grep -v "plate_number/plate_number.dart"
# → must be empty

# the barrel is the only file directly under lib/
cd ../plate-core && ls lib/
# → plate_number.dart, src/
```

And run the showcase plus `flutter run -t lib/dev/flag_panel_gallery.dart` — the gallery is a
`main()`-only file that nothing else imports, so a broken import there survives `flutter
analyze` on the app's own entrypoint.

Expected: no net line change beyond a barrel that got longer in comments and shorter in
exports, a written classification of every public name, and a `lib/` that a package split can
be performed on without guessing.
