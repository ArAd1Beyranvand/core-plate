---
name: p7-extract-keypad
description: "Phase P7 of the plate split (second edition) — create ../plate-keypad as a sibling package depending on core_plate, move the soft keyboard into it, and point the holder at it. The first extraction; establishes the sibling-package pattern P8 repeats. Use when the user asks to run P7 or extract the keypad."
---

# P7 — Extract `plate-keypad`

Follow `CLAUDE.md` working style. **Requires P5 committed** (the `src/` layout and the settled
public surface) and P4 committed (the compacted grid you are moving). P6 need not have run,
though it is cheaper if it has. This project does not use automated tests: do not write, update
or move anything under `test/`, and do not run `flutter test`. Finish analyzer-clean everywhere,
committed in each repo you touched; report diffstat and hashes only.

**This is the first phase that creates a package.** It goes first among the extractions because
the keypad is the least entangled thing in the library — it depends on `core_plate` for
`PlateAlphabet` and essentially nothing else — so if the sibling-package mechanics are wrong,
they fail here where the blast radius is one widget rather than two countries and an asset
bundle. **Whatever pattern you establish here, P8 copies.** Get the pubspec, the barrel, the
`src/` layout, the `analysis_options.yaml` include, the `README.md` and the `LICENSE` right
once.

## The target

```
StudioProjects/plate/
  plate-core/             package `plate_number` (renamed to core_plate in P9)
  plate-keypad/           package `plate_keypad`   ← this phase creates it
  plate_number_holder/
```

`plate_keypad` depends on the core package **by path**:

```yaml
dependencies:
  flutter: {sdk: flutter}
  plate_number: {path: ../plate-core}   # becomes core_plate in P9
```

Yes, that dependency name is temporarily ugly. P9 renames it in one place. The alternative —
renaming the core package first — means every import in both repos moves in the same commit as
the first extraction, and a phase that changes two things at once is a phase you cannot bisect.

## Ask first

`docs/split/PLAN.md` §6.7 is open and **this is the phase that asks it**: does
`PlateCharacterPicker` move into `plate_keypad`?

- It is Cupertino-flavoured and ~62 lines.
- `PlateCanvas.onChooseCharacter` already lets a host supply its own picker.
- Moving it takes core's last `package:flutter/cupertino.dart` import with it — a real
  reduction in what core drags in.
- But `onChooseCharacter` would become **required** rather than optional-with-a-built-in-default,
  which is an API break, and it would mean a consumer who wants slot-picker input has to depend
  on a package called "keypad" to get it.

Put both options to the user with `AskUserQuestion` **before writing any code**, and note the
answer in `PLAN.md` §6 so the decision stops being open. Do not decide it yourself.

## Do

### Create the package

1. `flutter create --template=package ../plate-keypad`, then replace its generated `lib/`
   wholesale.
2. `git init` in it and make a first commit of the scaffold before moving anything in, so the
   move shows up as a move rather than as the initial import.
3. `pubspec.yaml`: name `plate_keypad`, the same SDK constraint as core, the path dependency
   above, and nothing else. Set the version to `0.1.0`; copy `LICENSE` from core verbatim
   (same author, same terms) and start a `CHANGELOG.md` with one entry saying where the code
   came from and which core version it was extracted at.
4. `analysis_options.yaml` in the new package is just:
   ```yaml
   include: package:plate_number/../analysis_options.yaml
   ```
   — which does not work across packages. Dart cannot include an analysis config from a path
   dependency, so **copy** core's `analysis_options.yaml` (the one P6 tightened) into the new
   package instead, with a comment at the top naming `plate-core/analysis_options.yaml` as the
   file it is kept in sync with. Four copies of six lines is the price of four repos; note it in
   the report as a known duplication rather than pretending it is not one.

### Move the code

5. `git mv` from core into `plate-keypad/lib/src/`:
   - `plate_keypad.dart` (post-P4, with `_KeyGrid`), carrying `PlateKeypadTheme`,
     `kPlateBackspaceKey` and `kPlateKeypadSlide`
   - `plate_character_picker.dart`, **only if the user said yes above**

   Since this crosses repositories, `git mv` will not preserve history by itself. Either use
   `git format-patch`/`git am`, or accept a plain add-and-delete and say so in the commit
   message — an honest "extracted from plate-core at `<hash>`" line is worth more than a
   half-working history rewrite.

6. `plate-keypad/lib/plate_keypad.dart` is the barrel. Export exactly the names P5's
   classification put in the public bucket for these files, with `show:` clauses where a file
   holds internal names too. `_Key` and `_KeyGrid` are private and stay that way.

7. `plate_keypad`'s only import from core should be `PlateAlphabet` (and `PlateInputSource`, if
   the doc comments reference it). **If the analyzer says otherwise, report the coupling rather
   than accepting it** — an unexpected dependency here is P5 having mis-classified something,
   and it is far cheaper to fix now than after P8.

8. `README.md`: what the package is, what it depends on, and the three lines it takes to use
   one. Short.

### Update core

9. Remove the moved files and their exports from core's barrel. Core must not depend on
   `plate_keypad` — the arrow points one way only. Verify:
   ```bash
   cd plate-core && grep -rn "plate_keypad" lib/ pubspec.yaml   # → empty
   ```
10. `CHANGELOG.md` in core: the keypad has moved to its own package, with the import a consumer
    should switch to. This is a breaking change for anyone using it — say so.

### Update the holder

11. `plate_number_holder/pubspec.yaml` gains `plate_keypad: {path: ../plate-keypad}`.
12. Rewrite the keypad imports — `device_stage.dart` is the main one; grep for `PlateKeypad`,
    `PlateKeypadTheme` and `kPlateBackspaceKey` rather than assuming.
13. Update the comment block in the holder's pubspec that explains the repo layout. It predicts
    a `packages/`-inside-`plate-core` structure that is no longer the plan; replace the
    prediction with the sibling layout from `PLAN.md` §0 and what has actually happened so far.

## Widgets, not widget functions

Per `PLAN.md` §5. This phase moves files without editing bodies, so it converts nothing. A
widget function surviving into `plate-keypad` means P4 missed one — report it.

## Verify

```
cd plate-keypad          && flutter pub get && flutter analyze
cd ../plate-core         && flutter pub get && flutter analyze
cd ../plate_number_holder && flutter clean && flutter pub get && flutter analyze && flutter run
```

(Do not run `flutter test`.)

Then prove the arrow points the right way — this is the first time the split is testable at
all, and the check is the whole reason the phase exists:

```bash
cd plate-keypad && grep -rn "iran\|german\|persian" lib/ -i    # → empty
cd ../plate-core && grep -rn "plate_keypad" lib/               # → empty
```

Run the showcase and exercise both pads — full (tablet) and compact (bicycle) — plus a press
flash, and confirm the slide-in animation still uses `kPlateKeypadSlide`. Then, if
`PlateCharacterPicker` moved, exercise the picker path on a chosen slot.

Expected: no net line change; one package where there was none; the holder honest about the
fact that it uses a soft keyboard.
