## 0.1.0

First pub.dev release. The four packages (`core_plate`, `iran_plate`,
`germany_plate`, `plate_keypad`) are now published with versioned
dependencies — the country and keypad packages depend on `core_plate: ^0.1.0`
rather than a sibling `path:`.

- `PlateCanvas` now wraps its face in a `Material`, so it renders outside a
  `Scaffold` without throwing.
- `PlateCanvas` dispatches `SpecIsChanged` to the `PlateCardBloc` when its
  `spec` changes, keeping the bloc's value list the right length for the new
  spec.

### P9 — the rename, and the split settles

The package is now **`core_plate`** (was `plate_number`); its directory is
**`core-plate/`** (was `plate-core/`); its barrel is
**`package:core_plate/core_plate.dart`** (was `package:plate_number/plate_number.dart`).
The `lib/src/model/plate_number.dart` file — the `PlateNumber` entered-value type — keeps
its name; it is a domain type, not the package.

**Upgrading from `plate_number` 0.1.0 — every breaking change across P1–P9, in one place:**

- **The import.** `package:plate_number/plate_number.dart` →
  `package:core_plate/core_plate.dart`. Path dependency
  `plate_number: {path: ../plate-core}` → `core_plate: {path: ../core-plate}`. These
  packages are path-only; they are not published to pub.dev (`docs/split/PLAN.md` §6.6).
- **The `plate_number` facade is retired, not replaced.** There is no meta-package that
  re-exports the four. A consumer imports exactly what it uses. The four imports that
  replace the old single import:
  ```dart
  import 'package:core_plate/core_plate.dart';     // always
  import 'package:iran_plate/iran_plate.dart';      // if you draw Iranian plates
  import 'package:germany_plate/germany_plate.dart';// if you draw German plates
  import 'package:plate_keypad/plate_keypad.dart';  // if you want the on-screen keypad
  ```
- **Validation no longer blocks input** (P2). `PlateKeypad.unavailableKeys`,
  `GermanPlateValidator.barredNextDigits` / `barredNextLetters`, the `ForbiddenByGroup`
  mixin and `docs/forbidden.json` are **removed**. A plate may now hold an invalid
  value. What survives: `PlateValidator` / `PlateValidation` / `PlateEntry`, a verdict
  and nothing more. `PlateCanvas` gains `validator` and `autoValidate` (default
  `false`); with `autoValidate: true` the frame paints red in `PlateTheme.alertColor`
  and the keystroke still lands. `PlateInputController.validation` exposes the verdict
  on demand.
- **The core names no country** (P3). `PlateCountry.iran` / `.germany` and
  `PlateSpecs` (`irCar`, `irBicycle`, `deCar`) are **removed**. See the country
  packages below.
- **`PlateFlag` takes `required PlateCountry country`** (P3), not `String countryCode`,
  and renders `country.flag` (a `PlateAsset?`). The `country_flags` dependency and the
  `_resolveSize` aspect-ratio guess are gone. New `PlateAsset` / `SvgPlateAsset` /
  `RasterPlateAsset`; `PlateCountry` gains `PlateAsset? flag`.
- **`CountryPanel.country` and `PlateKeypad.digitAlphabet` / `letterAlphabet` are
  `required`** (P3) — they used to default to Iran / Persian.
- **`PlateAlphabet` gains `TextDirection direction` and `String placeholder`** (P3).
  RTL and the empty-slot glyph are read off the alphabet, not sniffed against
  `persianPlateLetters` or hard-coded `'؟'`.
- **`PlateAlphabet.persianDigits` / `persianPlateLetters` moved** (P3) to
  `PersianAlphabets` in `iran_plate`.
- **Grouping moved into the model** (P1). `PlateSpec` gains `effectiveTextGroups` /
  `groupAt` / `renderGroup`; `ShowPlate` no longer computes its own grouping.
- **Keypad grids collapsed** (P4). One `_KeyGrid` for both pads; `_buildDigitKey` /
  `_buildLettersLayer` gone. Internal, but it is why the keypad shrank ~90 lines.
- **Public surface is now a decision** (P5). `lib/src/` holds the implementation;
  `core_plate.dart` exports a chosen list, not every file. Anything under `src/` the
  barrel does not name is not API.
- **Dead weight removed** (P6). `PlateKeypadTheme.copyWith` (unused), the `args`
  dependency, and doc comments that described "a real Iranian licence plate" for
  country-neutral code.
- **The on-screen keypad left core** (P7). `PlateKeypad`, `PlateKeypadTheme`,
  `kPlateBackspaceKey`, `kPlateKeypadSlide` and `PlateCharacterPicker` are in
  `plate_keypad`. **`PlateCanvas.onChooseCharacter` is now `required`** — core ships no
  fallback picker. Core no longer imports `package:flutter/cupertino.dart`.
- **The countries left core** (P8). `IranCountry` / `PersianAlphabets` / `IranPlates`
  are in `iran_plate`; `GermanyCountry` / `GermanPlates` / `GermanPlateValidator` are
  in `germany_plate`. Core ships no assets — no `flutter.assets:` block. `flutter_svg`
  stays: `PlateFlag` renders whatever `SvgPlateAsset` a country hands it.
  `docs/districts.json` was deleted (§6.8); the German district check stays
  shape-only (`^[A-ZÄÖÜ]{1,3}$`).

### P8 — countries extracted to their own packages

- **Breaking: the countries have left core.** `IranCountry`, `PersianAlphabets`
  and `IranPlates` are **removed** from `plate_number` and now live in the
  sibling package `iran_plate` (`path: ../iran-plate`); `GermanyCountry`,
  `GermanPlates` and `GermanPlateValidator` live in `germany_plate`
  (`path: ../germany-plate`). Switch
  `import 'package:plate_number/plate_number.dart';` to
  `import 'package:iran_plate/iran_plate.dart';` or
  `import 'package:germany_plate/germany_plate.dart';` for those names; both
  packages depend on `plate_number`, so the imports coexist. Depend only on the
  countries you actually draw.
- **Breaking: core ships no assets.** The `flutter.assets:` block is gone. The
  two flag SVGs and the two German stickers moved into the packages that name
  them, and the `package:` argument of every `SvgPlateAsset` / `AssetImage`
  literal moved with them in the same commit — an asset reference resolves
  against the bundle of the package that *declares* the file, so a literal and
  its declaration can never be in different packages, even briefly.
- `flutter_svg` remains a dependency: `PlateFlag` renders whatever
  `SvgPlateAsset` a country hands it.
- `docs/districts.json` deleted — see `docs/split/PLAN.md` §6.8. It was read by
  no code and declared in no pubspec, and `germany_plate` chose not to take on
  keeping a district list current.
- This is the claim the whole split was built to make:
  `grep -rniE "iran|german|persian" plate-core/lib/` returns nothing.

### P7 — keypad extracted to its own package

- **Breaking: the on-screen keypad has left core.** `PlateKeypad`,
  `PlateKeypadTheme`, `kPlateBackspaceKey`, `kPlateKeypadSlide` and
  `PlateCharacterPicker` are **removed** from `plate_number` and now live in the
  sibling package `plate_keypad` (`path: ../plate-keypad`). Switch
  `import 'package:plate_number/plate_number.dart';` to
  `import 'package:plate_keypad/plate_keypad.dart';` for those names; the keypad
  package depends on `plate_number` for `PlateAlphabet`, so both imports coexist.
- **Breaking: `PlateCanvas.onChooseCharacter` is now `required`.** It used to
  default to an internal `PlateCharacterPicker`; that picker moved out with the
  keypad, so core no longer has a fallback. Pass
  `PlateCharacterPicker.show` from `plate_keypad`, or any
  `Future<String?> Function(PlateAlphabet)` of your own.
- Core no longer imports `package:flutter/cupertino.dart` anywhere.

### P3 — country decoupling

- **Breaking: the core no longer names a country.** `PlateCountry.iran` /
  `PlateCountry.germany` and the `PlateSpecs` catalogue (`irCar`, `irBicycle`,
  `deCar`) are **removed, not deprecated** — a shim would have re-introduced the
  country names the phase exists to remove. The constants moved to
  `countries/iran.dart` (`IranCountry.iran`, `PersianAlphabets.digits` /
  `.plateLetters`, `IranPlates.car` / `.bicycle`) and `countries/germany.dart`
  (`GermanyCountry.germany`, `GermanPlates.car`), both re-exported from
  `plate_number.dart`. `PlateAlphabet.persianDigits` / `persianPlateLetters`
  likewise moved to `PersianAlphabets`.
- `GermanPlateValidator` moved to `countries/german_plate_validator.dart`
  (still exported from the barrel) — it is a country artifact, and the phase's
  acceptance is that no file outside `countries/` names a country.
- New `PlateAsset` (`SvgPlateAsset` / `RasterPlateAsset`): a country ships its
  own flag asset, named with the package that owns it. `PlateCountry` gains
  `PlateAsset? flag`.
- **Breaking: `PlateFlag` takes `required PlateCountry country`** instead of
  `String countryCode`, and renders `country.flag` (nothing when null). Its
  `_resolveSize` aspect-ratio guess is gone.
- Dropped the `country_flags` dependency and its fallback rendering path;
  Germany now ships `assets/flags/Flag_of_Germany.svg`. Every country renders
  from a vector.
- **Breaking: `CountryPanel.country` and `PlateKeypad.digitAlphabet` /
  `letterAlphabet` are now `required`** — they defaulted to Iran / Persian.
- `plate_number.dart` now also exports `model/plate_box.dart` (`PlateBox` is
  part of the `PlateSpec` surface and consumers need it to build a `PlatePanel`).
- `PlateAlphabet` gains `TextDirection direction` (default `ltr`) and
  `String placeholder` (default `'?'`). `PlateKeypad` reads direction off the
  alphabet instead of comparing against a constant; `PlateSlotItem` reads the
  empty-slot placeholder off the alphabet instead of hard-coding `'؟'`.

- **Breaking: validation no longer prevents input.** `PlateKeypad.unavailableKeys`
  and `GermanPlateValidator.barredNextDigits` / `barredNextLetters` are
  **removed**, not deprecated. They existed to grey out and swallow the keys
  that would complete a forbidden value; a plate library has no business
  refusing a keystroke, and a plate may now hold an invalid value. `_keyEnabled`
  still disables a key outside the active alphabet — that is a fact about the
  alphabet, not a validation rule.
- New `PlateValidator` / `PlateValidation` / `PlateEntry` in
  `validators/plate_validator.dart`: a validator answers one question — is this
  plate valid? — and returns a verdict. There is deliberately no "which keys are
  barred" method.
- `PlateCanvas` gains `validator` and `autoValidate` (default `false`). With
  `autoValidate: true` the canvas paints the invalid state itself, in the new
  `PlateTheme.alertColor`. With it `false` the validator is never called by the
  canvas; read `PlateInputController.validation` and pick your own timing.
- `PlateInputController.validation` exposes the verdict on demand and notifies
  listeners when the verdict changes, not on every keystroke.
- `GermanPlateValidator` is now `const`-constructible and implements
  `PlateValidator`. `GermanPlateValidationResult` is a `typedef` for
  `PlateValidation`, kept for one release. `validateValues(spec, values)` is
  replaced by the `validate(PlateEntry)` override; the spec-free static is
  renamed `validateFields`.
- Removed `docs/forbidden.json`. It duplicated `_forbiddenLetterPairs` /
  `_forbiddenNumbers` by hand and nothing read it; the Dart consts always were
  the source of truth.
- Rewrote `README.md` against the current `PlateSpec`/`PlateCanvas` API.

## 0.0.1 — history as `plate_number`

- **Breaking:** Removed `CarPlateNumber` and `BicyclePlateNumber`. Use
  `PlateCanvas(spec: PlateSpecs.irCar)` and
  `PlateCanvas(spec: PlateSpecs.irBicycle)` instead.
- `PlateCanvas` is now exported from the package root (`plate_number.dart`)
  instead of requiring a deep import.
- **Breaking:** Removed `PlateCanvas.showRemoveButton` and `onRemove`. Hosts
  should render their own remove control alongside `PlateCanvas`.
