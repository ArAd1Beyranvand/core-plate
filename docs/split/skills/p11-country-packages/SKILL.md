---
name: p11-country-packages
description: "Refactor phase P11 of the plate_number split — create packages/iran_plate and packages/germany_plate, moving country constants, alphabets, specs, assets and the German validator out of the root package. Use when the user asks to run P11 or create the country packages."
---

# P11 — The country packages

Follow `CLAUDE.md` working style. Requires **P10** committed. Finish analyzer-clean, tests
green, committed; report diffstat and hashes only.

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

### Tests

12. `test/alphabet_test.dart`'s Persian groups → `packages/iran_plate/test/`.
13. `test/german_plate_validator_test.dart` → `packages/germany_plate/test/`.
14. `test/spec_test.dart` splits by spec: `irCar`/`irBicycle` cases to `iran_plate`, `deCar`
    cases to `germany_plate`. Any case that is really about `PlateSpec` mechanics rather than
    a particular country belongs in `core_plate` with a locally-declared throwaway spec — and
    writing that throwaway spec is a useful check that core really can express a plate with no
    country package present.
15. Add to each country package one test asserting its assets resolve:
    `expect(IranPlates.car.country.flag!.package, 'iran_plate')` and equivalents for the
    German decals. Cheap insurance against the failure mode below.

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

## Verify

```
cd plate-number-upgrade
flutter pub get && flutter analyze && flutter test
for p in packages/*; do (cd "$p" && flutter test); done
cd ../plate_number_holder && flutter clean && flutter pub get && flutter analyze && flutter test
flutter run --release
```

Then confirm the dependency graph is what was designed:

```bash
grep -rn "iran_plate"    plate-number-upgrade/packages/germany_plate/   # must be empty
grep -rn "germany_plate" plate-number-upgrade/packages/iran_plate/      # must be empty
grep -rniE "iran|german|persian" plate-number-upgrade/packages/core_plate/lib/   # must be empty
```

Expected: no net line change; four packages where there was one; core compilable without
either country.
