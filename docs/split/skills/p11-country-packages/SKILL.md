---
name: p11-country-packages
description: "Refactor phase P11 of the plate_number split — create packages/iran_plate and packages/germany_plate, moving country constants, alphabets, specs, assets and the German validator out of the root package. Use when the user asks to run P11 or create the country packages."
---

# P11 — The country packages

Follow `CLAUDE.md` working style. Requires **P10** committed. This project does not use
automated tests — do not write, update, or move anything under `test/`, and do not run
`flutter test`. Finish analyzer-clean, committed; report diffstat and hashes only.

Mechanical, like P10 — with one thing that is not: **asset ownership**. Get that wrong and the
plates render blank in release mode while looking fine in debug on the machine that has the
old package still resolved.

## Do

### `packages/iran_plate`

1. `flutter create --template=package packages/iran_plate`; add `resolution: workspace` and to
   the root `pubspec.yaml`'s `workspace:` list.
2. Dependencies: `flutter`, `core_plate`. Nothing else.
3. Move in:
   - `lib/countries/iran.dart` → `lib/src/iran_country.dart` (`IranCountry.iran`)
   - the Persian alphabets from wherever P8 parked them →
     `lib/src/persian_alphabets.dart` (`PersianAlphabets.digits`, `.plateLetters`)
   - `IranPlates.car` / `IranPlates.bicycle` → `lib/src/iran_plates.dart`
   - `assets/flags/Flag_of_Iran.svg` → `packages/iran_plate/assets/flags/Flag_of_Iran.svg`
4. Declare the asset in `packages/iran_plate/pubspec.yaml` and change the `SvgPlateAsset`
   literal's `package:` from `'plate_number'` to `'iran_plate'` **in the same commit as the
   file move**.
5. Barrel `lib/iran_plate.dart` exports the three `src/` files.

### `packages/germany_plate`

6. Same shape. Dependencies: `flutter`, `core_plate`.
7. Move in:
   - `lib/countries/germany.dart` → `lib/src/germany_country.dart`
   - `GermanPlates.car` → `lib/src/germany_plates.dart`
   - `lib/validators/german_plate_validator.dart` → `lib/src/german_plate_validator.dart`
   - `assets/de_inspection_sticker.png`, `assets/de_state_seal.png`, and the German flag SVG
     added in P8 → `packages/germany_plate/assets/`
8. Update the two `PlateDecal` `AssetImage(..., package: 'plate_number')` literals and the
   flag's `SvgPlateAsset` to `package: 'germany_plate'`, same commit as the move.
9. Barrel `lib/germany_plate.dart`.

### Root package

10. Remove the moved files, the `assets:` block, and `flutter_svg` if nothing is left using it
    there. Root `pubspec.yaml` now depends on `core_plate`, `iran_plate`, `germany_plate` and
    still owns `plate_keypad.dart`.
11. The facade `lib/plate_number.dart` re-exports the two new barrels in place of the old
    relative paths. **`plate_number_holder` is still untouched.**

This project does not use automated tests, so there is no `test/` directory to split between
packages — skip that step entirely; do not create test files in any package. Instead, manually
confirm each country package's assets resolve (e.g. `IranPlates.car.country.flag!.package ==
'iran_plate'` and the equivalent for the German decals) as part of the release-run check below.

## The asset trap

`AssetImage('assets/x.png', package: 'foo')` resolves against the *declaring* package's
bundle. If the literal says `germany_plate` but the file is still declared in the root
`pubspec.yaml`'s `assets:` block, it will keep working locally — the old bundle is still on
disk and pub has not cleaned it — and fail for a fresh consumer. So:

```bash
flutter clean && flutter pub get && flutter run --release
```

in `plate_number_holder` before you commit, and confirm the two German stickers and both flags
actually appear. A debug run on a warm cache proves nothing here.

## Widgets, not widget functions

`claude.md` §1 forbids widget-returning functions, and from here on every phase enforces it in
the files it already edits — this phase moves files without editing bodies. Nothing to convert.

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
flutter pub get && flutter analyze
cd ../plate_number_holder && flutter clean && flutter pub get && flutter analyze
flutter run --release
```

(Do not run `flutter test` — this project does not use automated tests.)

Then confirm the dependency graph is what was designed:

```bash
grep -rn "iran_plate"    plate-core/packages/germany_plate/   # must be empty
grep -rn "germany_plate" plate-core/packages/iran_plate/      # must be empty
grep -rniE "iran|german|persian" plate-core/packages/core_plate/lib/   # must be empty
```

Expected: no net line change; four packages where there was one; core compilable without
either country.
