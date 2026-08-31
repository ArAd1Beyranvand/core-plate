---
name: p8-extract-countries
description: "Phase P8 of the plate split (second edition) — create ../iran-plate and ../germany-plate as sibling packages, moving country constants, alphabets, specs, assets and the German validator out of the core. Includes the districts.json product decision. Use when the user asks to run P8 or create the country packages."
---

# P8 — Extract `iran-plate` and `germany-plate`

Follow `CLAUDE.md` working style. **Requires P7 committed** (the sibling-package pattern) and
**P3's acceptance grep still returning nothing** — re-run it before you start; if it has
regressed, fix that first, because moving country code out while core still names a country
produces two broken packages instead of one. This project does not use automated tests: do not
write, update or move anything under `test/`, and do not run `flutter test`. Finish
analyzer-clean everywhere, committed in each repo you touched; report diffstat and hashes only.

Mechanical, like P7 — **except for asset ownership**, which is the one thing in this whole plan
that fails silently on the machine you develop on and breaks for everyone else.

## Precondition

```bash
cd plate-core
grep -rniE "iran|german|persian|'ir'|'de'" lib/src/ --exclude-dir=countries
```

Empty, or stop. Paste it into the report.

## Ask first

`docs/split/PLAN.md` §6.8 is open and **this is the phase that asks it**: does
`docs/districts.json` back the German district check?

The situation: `GermanPlateValidator`'s district regex is `^[A-ZÄÖÜ]{1,3}$`, so `AA`, `ZZ` and
`QQ` all validate today though none is a real `Unterscheidungszeichen`. `docs/districts.json`
holds ~150 real codes, is referenced by no `pubspec.yaml` and read by no code. The three
options:

1. **Wire it in.** `germany_plate` ships `districts.json` as a declared asset (or as a Dart
   `const Set` generated from it), and the validator checks membership. Stricter, more
   correct — and a data file someone has to keep current as districts change.
2. **Delete it.** The validator's doc comment already says it is demo-scoped and not an
   official guarantee; the regex is consistent with that. One less file.
3. **Ship it as data, unused by the validator.** `germany_plate` exports the list so a consumer
   who wants strict district validation can build their own rule, while the built-in validator
   stays permissive.

Put all three to the user with `AskUserQuestion` **before writing code**, and record the answer
in `PLAN.md` §6. Do not default to "wire it in" — a refactor phase is exactly where a product
decision gets made by accident.

## Do

### `../iran-plate`

1. Same recipe as P7: `flutter create --template=package ../iran-plate`, `git init`, scaffold
   commit, then move code in. Package name `iran_plate`, version `0.1.0`, `LICENSE` copied from
   core, `CHANGELOG.md` with an extracted-from line, `analysis_options.yaml` copied from core
   with the same kept-in-sync comment.
2. Dependencies: `flutter`, and the core package by path
   (`plate_number: {path: ../plate-core}` — renamed in P9). **Nothing else.** Not
   `germany_plate`, not `plate_keypad`, not `flutter_bloc`.
3. Move in from `plate-core/lib/src/countries/iran.dart` (created in P3):
   - `IranCountry.iran` → `lib/src/iran_country.dart`
   - `PersianAlphabets.digits` / `.plateLetters` → `lib/src/persian_alphabets.dart`
   - `IranPlates.car` / `.bicycle` → `lib/src/iran_plates.dart`
4. Move `plate-core/assets/flags/Flag_of_Iran.svg` → `iran-plate/assets/flags/Flag_of_Iran.svg`.
5. Declare it in `iran-plate/pubspec.yaml`'s `flutter.assets:` and change the `SvgPlateAsset`
   literal's `package:` from `'plate_number'` to `'iran_plate'` **in the same commit as the
   file move**. See "the asset trap".
6. Barrel `lib/iran_plate.dart` exports the three `src/` files.
7. `README.md`: one paragraph and a three-line usage sample.

### `../germany-plate`

8. Same shape. Package `germany_plate`. Dependencies: `flutter`, core by path.
9. Move in from `plate-core/lib/src/countries/germany.dart` and the validator:
   - `GermanyCountry.germany` → `lib/src/germany_country.dart`
   - `GermanPlates.car` → `lib/src/germany_plates.dart`
   - `german_plate_validator.dart` → `lib/src/german_plate_validator.dart`
10. Move the assets: `de_inspection_sticker.png`, `de_state_seal.png`, and the German flag SVG
    P3 added. Declare them, and update the two `PlateDecal` `AssetImage(…, package:
    'plate_number')` literals and the flag's `SvgPlateAsset` to `package: 'germany_plate'` — same
    commit as the move.
11. Whatever the user decided about `districts.json`, implement it here, in this commit, and
    note it in this package's `CHANGELOG.md`.
12. Barrel `lib/germany_plate.dart`.

### Core

13. Remove the moved files and every trace of them from core's barrel. Remove the `assets:`
    block from `plate-core/pubspec.yaml` — after this phase core ships no assets at all. Check
    whether `flutter_svg` is still used by anything in core (`PlateFlag` renders an
    `SvgPlateAsset`, so it probably is); keep it if so.
14. `CHANGELOG.md`: countries and the German validator have moved to their own packages, with
    the imports a consumer switches to. Breaking.

### The holder

15. `pubspec.yaml` gains `iran_plate: {path: ../iran-plate}` and
    `germany_plate: {path: ../germany-plate}`.
16. Rewrite the imports. The mapping:
    - `IranPlates.car` / `.bicycle`, `IranCountry`, `PersianAlphabets` → `iran_plate`
    - `GermanPlates.car`, `GermanyCountry`, `GermanPlateValidator` → `germany_plate`
    - `PlateKeypad`, `PlateKeypadTheme`, `kPlateBackspaceKey` → `plate_keypad` (P7)
    - everything else → the core package
    Do not forget `lib/dev/flag_panel_gallery.dart` and `lib/minimal/main.dart`.

## The asset trap

`AssetImage('assets/x.png', package: 'foo')` resolves against the **declaring** package's
bundle. If the literal says `germany_plate` but the file is still declared in `plate-core`'s
`pubspec.yaml`, it keeps working on your machine — the old bundle is on disk and pub has not
cleaned it — and fails for anyone with a fresh checkout. A debug run on a warm cache proves
nothing here. So, in the holder, before you commit:

```bash
flutter clean && flutter pub get && flutter run --release
```

and confirm with your eyes that both German stickers and both flags actually appear.

Also assert it in code, since there is no test suite to hold it:
`IranPlates.car.country.flag!.package == 'iran_plate'` and the German equivalents. A one-line
`debugPrint` in the gallery during verification is enough; do not leave it in.

## Widgets, not widget functions

Per `PLAN.md` §5. This phase moves files without editing bodies. Nothing to convert.

## Verify

```
cd iran-plate            && flutter pub get && flutter analyze
cd ../germany-plate      && flutter pub get && flutter analyze
cd ../plate-keypad       && flutter pub get && flutter analyze
cd ../plate-core         && flutter pub get && flutter analyze
cd ../plate_number_holder && flutter clean && flutter pub get && flutter analyze
flutter run --release
```

(Do not run `flutter test`.)

Then confirm the dependency graph is the one that was designed:

```bash
grep -rn "iran_plate"    germany-plate/lib/ germany-plate/pubspec.yaml   # → empty
grep -rn "germany_plate" iran-plate/lib/    iran-plate/pubspec.yaml      # → empty
grep -rniE "iran|german|persian" plate-core/lib/                         # → empty
```

All three must be empty. The third is the one that matters: it is the claim this entire
refactor was built to make, and P9 turns it into a build that proves it.

Expected: no net line change; four packages where there was one; core compilable without
either country.
