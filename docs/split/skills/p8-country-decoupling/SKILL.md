---
name: p8-country-decoupling
description: "Refactor phase P8 of the plate_number split — remove the last four places core code names a specific country, move flag assets onto PlateCountry, and drop the country_flags dependency. Use when the user asks to run P8 or work on country decoupling."
---

# P8 — Country decoupling

Follow `CLAUDE.md` working style. Requires **P7** committed. This project does not use
automated tests — do not write or update anything under `test/`, and do not run
`flutter test`. Finish analyzer-clean, committed; report diffstat and hashes only.

**This is the last phase before the package split.** After it, no file that will live in
`core_plate` mentions Iran, Germany, Persian or `'ir'`. Grep is the acceptance test.

## The four leaks

Everything else in the widget layer is already country-agnostic. These four are all that is
left.

### 1. `PlateFlag` hard-codes Iran's SVG

```dart
// lib/widgets/plate_flag.dart
static const Map<String, String> _svgAssets = {
  'ir': 'assets/flags/Flag_of_Iran.svg',
};
…
SvgPicture.asset(asset, package: 'plate_number', …)
```

**Fix.** New value type in core:

```dart
/// An image a country package ships, named so it survives the package split:
/// [package] is the package that owns [path], not the one rendering it.
@immutable
sealed class PlateAsset {
  const PlateAsset(this.path, {required this.package});
  final String path;
  final String package;
}
class SvgPlateAsset  extends PlateAsset { const SvgPlateAsset(super.path, {required super.package}); }
class RasterPlateAsset extends PlateAsset { const RasterPlateAsset(super.path, {required super.package}); }
```

`PlateCountry` gains `final PlateAsset? flag;`. `PlateFlag` takes `required PlateCountry country`
instead of a `String countryCode`, renders `country.flag` when set, and falls back to
`country_flags` by `country.code` when null.

This constructor change has **three** call sites, not the one you'll find by grepping
`lib/` alone — check `plate_number_holder` too before you consider the rename done:
`lib/widgets/country_panel.dart` (internal, updates alongside the type), and
`plate_number_holder/lib/dev/flag_panel_gallery.dart:40`, a standalone dev-gallery
entrypoint (`flutter run -t lib/dev/flag_panel_gallery.dart`) that constructs
`PlateFlag(countryCode: 'ir')` directly. That file also constructs
`CountryPanel(theme: theme, country: PlateCountry.iran)` at line 57, and imports four
`package:plate_number/model/...`/`widgets/...` deep paths instead of the barrel. All three
need fixing in this same commit — see the very end of this phase for the exact edits, since
`PlateCountry.iran`'s new home isn't decided until leak 4 below.

Then **give Germany its own flag asset** so the fallback has no users, and delete the
`country_flags` dependency from `pubspec.yaml` along with the fallback branch. One less
transitive dependency for every consumer, and one less rendering path with different fidelity
(the existing doc comment explains why the quantized `.si` format reads as pixelation on a
detailed emblem — that argument applies to the German eagle-free tricolour less, but a single
rendering path is worth more than the saved bytes).

Keep the comment explaining the SVG-vs-`country_flags` fidelity decision, rewritten as the
reason every country now ships a vector.

While there: `PlateFlag._resolveSize` is 15 lines guessing an aspect ratio from unbounded
constraints with a 7:4 fallback. `PlateCountry.flagAspectRatio` is now available on the same
object. Delete `_resolveSize`.

### 2. `PlateKeypad` defaults to Persian and sniffs for it

```dart
this.digitAlphabet  = PlateAlphabet.persianDigits,
this.letterAlphabet = PlateAlphabet.persianPlateLetters,
…
final direction = widget.letterAlphabet == PlateAlphabet.persianPlateLetters
    ? TextDirection.rtl : TextDirection.ltr;
```

**Fix.** Reading direction is a property of an alphabet, not something to infer by comparing
constants. `PlateAlphabet` gains `final TextDirection direction;` defaulting to
`TextDirection.ltr`; `persianPlateLetters` and `persianDigits` declare `rtl`. The comparison
becomes `widget.letterAlphabet.direction`.

Make `digitAlphabet` and `letterAlphabet` **required**. **Check both `PlateKeypad` call sites
in `device_stage.dart` before assuming this is a no-op change — it is not.** The tablet/full-pad
branch (`compact: false`) passes both explicitly
(`digitAlphabet: PlateAlphabet.latinDigits, letterAlphabet: PlateAlphabet.latinUppercase`).
The mobile/compact-pad branch (`compact: config.compactKeypad`, used for the bicycle plate)
passes **neither** — it relies on the Persian defaults this fix removes, and it happens to be
correct today only because the bicycle plate's alphabet is Persian digits, which is what the
default silently supplied. When you make the parameters required, that second `PlateKeypad(...)`
call site (`device_stage.dart`, the `else` branch around line 332) needs
`digitAlphabet: PlateAlphabet.persianDigits, letterAlphabet: PlateAlphabet.persianPlateLetters`
added explicitly, or the file fails to compile — which is the point: a required parameter
turns "worked by accident" into "must be stated," and this is the one call site where that
accident was live.

> Note: after P5 this comparison at least compares correctly (`PlateAlphabet` has `==` on
> `id`). Before P5 it was an identity check. Either way it goes.

`PlateKeypad` has also gained a second highlight input since this phase was written —
`highlightedKeyListenable`, a `ValueListenable<String?>` each `_Key` watches for itself so a
rapid press-flash does not rebuild the grid. It is orthogonal to the alphabet work here; leave
it alone. It matters to P9, which has to carry both inputs through `_KeyGrid`.

### 3. `CountryPanel` defaults to Iran

```dart
this.country = PlateCountry.iran,
```

**Fix.** Make it required. `plate_canvas.dart` (passes `spec.country`) needs no change. The
dev gallery does — `flag_panel_gallery.dart` already passes `country:` explicitly, so it needs
no change for *this* leak, but its argument (`PlateCountry.iran`) does change in leak 4 below.

### 4. The country constants live on the country class

`PlateCountry.iran` and `PlateCountry.germany` are `static const` members of the class that
will live in core.

**Fix, this phase:** move them out of `PlateCountry` into
`lib/countries/iran.dart` (`IranCountry.iran`, plus `PlateAlphabet.persianDigits` and
`persianPlateLetters` relocated there) and `lib/countries/germany.dart`
(`GermanyCountry.germany`). Split `PlateSpecs` the same way into `IranPlates` (`car`,
`bicycle`) and `GermanPlates` (`car`), and move the two German `PlateDecal` asset references
with them.

Re-export all of it from `lib/plate_number.dart` so nothing downstream breaks yet. These
files become the seed of `iran_plate` and `germany_plate` in P11 — a straight directory move.

`PlateAlphabet.latinDigits` and `latinUppercase` **stay in core**. They are not German; they
are Latin, and any future country will want them.

**Now close the loop on `flag_panel_gallery.dart`** promised above: its imports become
```dart
import 'package:plate_number/plate_number.dart';
```
(one barrel import instead of four deep paths), `PlateFlag(countryCode: 'ir')` becomes
`PlateFlag(country: IranCountry.iran)`, and `CountryPanel(theme: theme, country:
PlateCountry.iran)` becomes `CountryPanel(theme: theme, country: IranCountry.iran)`. This file
is a standalone `main()` — the only way to catch a broken import here is to actually run it
(`flutter run -t lib/dev/flag_panel_gallery.dart`), since it is not exercised by
`flutter test` or `flutter analyze` finding it through any other entrypoint. Do that as part of
this phase's verification, not as an afterthought — it is easy for a `main()`-only file to bit-rot
silently exactly because nothing else imports it.

## Also in this pass

- `lib/model/plate_alphabet.dart` and `lib/theme/plate_theme.dart` have doc comments opening
  with "The visual language of a real Iranian licence plate" and similar. `PlateTheme.standard()`
  is the generic white-face/black-frame theme that Germany uses unchanged. Reword the docs to
  say what the code does. Do not rename `standard()`.
- `lib/widgets/plate_slot_item.dart` renders `'؟'` as the empty-slot placeholder for chosen
  slots. That is an Arabic question mark hard-coded in core. Make it
  `PlateAlphabet.placeholder` (default `'?'`), with the Persian letter alphabet declaring
  `'؟'`.

## Acceptance

```bash
cd plate-core
grep -rniE "iran|german|persian|'ir'|'de'" lib/ \
  --exclude-dir=countries \
  --exclude=plate_number.dart
```

Must return nothing but the `country_flags` removal comment, if you left one. Anything else is
a leak this phase missed.

## Widgets, not widget functions

`claude.md` §1 forbids widget-returning functions, and from here on every phase enforces it in
the files it already edits — here that is `plate_flag.dart` and `country_panel.dart`, both already widget classes. `plate_keypad.dart`'s two widget functions are P9's, not this phase's — do not pre-empt them.

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
cd plate-core   && flutter analyze
cd ../plate_number_holder && flutter analyze
```

(Do not run `flutter test` — this project does not use automated tests.)

Then compare the rendered Iranian flag against `docs/references/car-plate-iran.jpg` and the
German plate against `docs/references/germany-license-plate-english-infographic.jpg` at full
poster scale. (P0.5 moved both out of `assets/`; earlier drafts of this file pointed at the old
location.)
The flag is the one thing in this phase that can regress invisibly — this project has no
automated tests, and `flag_panel_gallery.dart` (the one file that exercises `PlateFlag` outside
the full plate canvas) is a `main()` entrypoint that `flutter analyze` won't run for you:

```bash
cd plate_number_holder && flutter run -t lib/dev/flag_panel_gallery.dart -d linux
```

Confirm it launches and both the flag and country-panel tiles render at all three sizes before
calling this phase done.

Expected: ~35 net lines removed, one dependency dropped, and `grep` proving core is
country-free.
