---
name: p3-country-decoupling
description: "Phase P3 of the plate split (second edition) — remove every place core code names a country: PlateFlag's hard-coded Iranian SVG, the keypad's Persian defaults and RTL sniff, CountryPanel's Iran default, the Arabic placeholder glyph, and the country constants themselves. Use when the user asks to run P3 or work on country decoupling."
---

# P3 — Country decoupling

Follow `CLAUDE.md` working style. **Requires P2 committed.** This project does not use
automated tests: do not write or update anything under `test/`, and do not run `flutter test`.
Finish analyzer-clean in both repos, committed; report diffstat and hashes only.

**This phase is what makes P8 possible.** After it, no file that will live in `core_plate`
mentions Iran, Germany, Persian, `'ir'` or `'de'`. Grep is the acceptance test, and P8 will
not start until it comes back empty.

## The five leaks

Everything else in the widget layer is already country-agnostic — the canvas, the slot item,
the frame and the bloc read geometry, alphabets and direction off the spec. These five are all
that is left.

### 1. `PlateFlag` hard-codes Iran's SVG

```dart
// lib/widgets/plate_flag.dart
static const Map<String, String> _svgAssets = {'ir': 'assets/flags/Flag_of_Iran.svg'};
…
SvgPicture.asset(asset, package: 'plate_number', …)
```

A country-neutral widget with a map of one country in it, naming its own package in a string
literal that will be wrong the moment the asset moves.

**Fix.** New value type in core:

```dart
/// An image a country package ships, named so it survives the package split:
/// [package] is the package that OWNS [path], not the one rendering it.
@immutable
sealed class PlateAsset {
  const PlateAsset(this.path, {required this.package});
  final String path;
  final String package;
}
class SvgPlateAsset    extends PlateAsset { const SvgPlateAsset(super.path, {required super.package}); }
class RasterPlateAsset extends PlateAsset { const RasterPlateAsset(super.path, {required super.package}); }
```

`PlateCountry` gains `final PlateAsset? flag;`. `PlateFlag` takes `required PlateCountry
country` instead of `String countryCode` and renders `country.flag`.

Then **give Germany its own flag asset**, drop the `country_flags` fallback branch, and remove
`country_flags` from `pubspec.yaml`. One less transitive dependency for every consumer and one
less rendering path — the existing doc comment explains why the quantized `.si` format reads as
pixelation on a detailed emblem; rewrite it as the reason every country now ships a vector
rather than deleting the reasoning.

Make `flag` **required-in-practice**: leave the field nullable (a country without a flag asset
is legitimate) but have `PlateFlag` render nothing rather than falling back to a package that
is no longer a dependency.

While in this file: `PlateFlag._resolveSize` is ~15 lines guessing an aspect ratio from
unbounded constraints with a 7:4 fallback. `PlateCountry.flagAspectRatio` is on the same
object. Delete `_resolveSize`.

**Three call sites, not one.** Grep both repos before calling the rename done:

- `lib/widgets/country_panel.dart` — internal, updates alongside the type.
- `plate_number_holder/lib/dev/flag_panel_gallery.dart:~40` — constructs
  `PlateFlag(countryCode: 'ir')` directly, and at ~57 `CountryPanel(country: PlateCountry.iran)`.
  It also imports four deep `package:plate_number/model/…` paths instead of the barrel.
- any use inside `plate_canvas.dart` (it passes `spec.country`, so likely none — confirm).

### 2. `PlateKeypad` defaults to Persian and sniffs for it

```dart
this.digitAlphabet  = PlateAlphabet.persianDigits,
this.letterAlphabet = PlateAlphabet.persianPlateLetters,
…
final direction = widget.letterAlphabet == PlateAlphabet.persianPlateLetters
    ? TextDirection.rtl : TextDirection.ltr;   // _buildLettersLayer, ~line 284
```

**Fix.** Reading direction is a property of an alphabet, not something to infer by comparing
constants. `PlateAlphabet` gains `final TextDirection direction;` defaulting to
`TextDirection.ltr`; the Persian alphabets declare `rtl`. The comparison becomes
`widget.letterAlphabet.direction`.

Make `digitAlphabet` and `letterAlphabet` **required**. **Check both `PlateKeypad` call sites
in `device_stage.dart` before assuming this is a no-op — it is not.** The tablet/full-pad
branch (`compact: false`) passes both explicitly (`latinDigits`, `latinUppercase`). The
mobile/compact branch (the `else` around line 332, used for the bicycle plate) passes
**neither** — it relies on the Persian defaults this fix removes, and it is correct today only
because the bicycle plate happens to be Persian. Making the parameters required turns "worked
by accident" into "must be stated," and that call site needs
`digitAlphabet: PersianAlphabets.digits, letterAlphabet: PersianAlphabets.plateLetters`
(or whatever leak 5 names them) added explicitly, or the file will not compile. That is the
point.

`PlateKeypad` also has `highlightedKeyListenable`, a `ValueListenable<String?>` each `_Key`
watches for itself so a press-flash does not rebuild the grid. Orthogonal to this phase —
**leave it alone.** It matters to P4, which has to carry it through `_KeyGrid`.

### 3. `CountryPanel` defaults to Iran

```dart
this.country = PlateCountry.iran,
```

**Fix.** Make it required. `plate_canvas.dart` passes `spec.country` and needs no change. The
dev gallery already passes `country:` explicitly, so it needs no change for *this* leak — but
its argument changes in leak 5.

### 4. `PlateSlotItem` hard-codes an Arabic question mark

`lib/widgets/plate_slot_item.dart` renders `'؟'` as the empty-slot placeholder for chosen
slots. That is a Persian glyph in a country-neutral widget, and it is wrong on a German plate
today.

**Fix.** `PlateAlphabet` gains `final String placeholder;`, defaulting to `'?'`. The Persian
letter alphabet declares `'؟'`. The widget reads it off the slot's alphabet.

### 5. The country constants live on the country class

`PlateCountry.iran` and `PlateCountry.germany` are `static const` members of the class that
will live in core, and `PlateSpecs` holds `irCar`, `irBicycle` and `deCar` side by side.

**Fix, this phase:** move them out into

- `lib/countries/iran.dart` — `IranCountry.iran`, `PersianAlphabets.digits`,
  `PersianAlphabets.plateLetters`, `IranPlates.car`, `IranPlates.bicycle`
- `lib/countries/germany.dart` — `GermanyCountry.germany`, `GermanPlates.car`, and the two
  German `PlateDecal` asset references

Re-export both from `lib/plate_number.dart` so nothing downstream breaks yet. **These two
files become `iran-plate` and `germany-plate` in P8 — a straight directory move.** Their
internal shape now is the shape they will have as packages, so give them the `src/`-ready
layout: one class per file, no cross-references between `iran.dart` and `germany.dart`.

`PlateAlphabet.latinDigits` and `latinUppercase` **stay in core.** They are not German; they
are Latin, and any future country will want them.

Keep `PlateSpecs` as a deprecated shim for one release
(`@Deprecated('Use IranPlates.car') static const irCar = IranPlates.car;`) or delete it
outright and update every call site — either is fine, but not both halves of neither. Say
which in the report and note it in `CHANGELOG.md`.

**Now close the loop on `flag_panel_gallery.dart`:** its four deep imports become one
`import 'package:plate_number/plate_number.dart';`, `PlateFlag(countryCode: 'ir')` becomes
`PlateFlag(country: IranCountry.iran)`, and `CountryPanel(country: PlateCountry.iran)` becomes
`CountryPanel(country: IranCountry.iran)`. This file is a standalone `main()` — nothing else
imports it, so `flutter analyze` reaching it is the only static check, and a runtime asset
failure will not show up until someone runs it. **Actually run it** (below).

## Also in this pass

- `lib/model/plate_alphabet.dart` and `lib/theme/plate_theme.dart` have doc comments opening
  "The visual language of a real Iranian licence plate" and similar, on code Germany uses
  unchanged. Reword them to say what the code does. **Do not rename `PlateTheme.standard()`** —
  it is the generic white-face/black-frame theme and the name is right.
- Any remaining `package: 'plate_number'` string literals in asset references stay as they are
  for now. P8 moves the assets and updates the literals in the same commit, so there is never a
  state where a literal names a package that does not own the file.

## Acceptance

```bash
cd plate-core
grep -rniE "iran|german|persian|'ir'|'de'" lib/ \
  --exclude-dir=countries \
  --exclude=plate_number.dart
```

**Must return nothing** except a `country_flags` removal comment if you left one. Anything else
is a leak this phase missed, and P8 is blocked until it is empty. Paste the command and its
output into the report — not a claim that it passed.

## Widgets, not widget functions

Per `PLAN.md` §5, in the files this phase already edits — here `plate_flag.dart` and
`country_panel.dart`, both already widget classes. `plate_keypad.dart`'s two widget functions
belong to **P4**; do not pre-empt them, even though this phase edits the same file.

## Verify

```
cd plate-core            && flutter analyze
cd ../plate_number_holder && flutter analyze
```

(Do not run `flutter test`.)

Then, because the flag is the one thing here that can regress invisibly:

```bash
cd plate_number_holder && flutter run -t lib/dev/flag_panel_gallery.dart -d linux
```

Confirm it launches and that the flag and country-panel tiles render at all three sizes.
Compare the rendered Iranian flag against `docs/references/car-plate-iran.jpg` and the German
plate against `docs/references/germany-license-plate-english-infographic.jpg` at full poster
scale. Then run the showcase and confirm the bicycle plate's compact keypad still shows Persian
digits — it does so now because a call site states it, not because a default supplied it.

Expected: ~35 net lines removed, `country_flags` dropped, and `grep` proving core is
country-free for the first time.
