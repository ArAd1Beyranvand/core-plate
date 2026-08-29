# Splitting `plate_number` into `core_plate` + country packages

Status: **plan, not executed.** Phase 0 (the example app) is done.

---

## 0. Where things stand

| | |
|---|---|
| `plate_number_holder/` | the showcase, now its own project, path-depends on the package |
| `plate-number-upgrade/lib/` | 2 588 lines, one package, all countries inside |
| `plate-number-upgrade/example/` | left in place as a working copy; delete once the holder is verified |

Current `lib/` line counts:

```
model/plate_spec.dart              388     widgets/plate_slot_item.dart      252
widgets/plate_keypad.dart          408     validators/german_...dart         159
widgets/plate_canvas.dart          387     theme/plate_theme.dart            141
                                           widgets/country_panel.dart        120
                                           widgets/plate_flag.dart            89
                                           model/plate_country.dart           83
                                           widgets/show_plate.dart            83
                                           widgets/plate_frame.dart           82
                                           input/plate_input_controller.dart  74
                                           model/plate_alphabet.dart          72
                                           widgets/plate_character_picker.dart 62
                                           model/plate_input_source.dart      50
                                           model/plate_number.dart            49
                                           bloc/* + plate_number.dart         89
```

The good news the recon turns up: **the widget layer is already
country-agnostic.** `PlateCanvas`, `PlateSlotItem`, `PlateFrame`,
`PlateCharacterPicker` and the bloc contain no country knowledge at all — they
read geometry, alphabets and direction off the spec, exactly as `claude.md` §2
and §3 demand. The split is therefore mostly a *data* move, plus four small
leaks to plug.

---

## 1. Target layout

A monorepo inside the existing repo, so one `git clone` still gets everything:

```
plate-number-upgrade/
  packages/
    core_plate/       engine: models, theme, bloc, widgets, validator interface
    iran_plate/       PlateCountry.iran, Persian alphabets, ir.car + ir.bicycle,
                      flag SVG
    germany_plate/    PlateCountry.germany, de.car, the two decals,
                      GermanPlateValidator
  plate_number/       thin facade: depends on all three, re-exports them
  melos.yaml          (or a pubspec workspace) so one `pub get` links them
```

Dependencies point one way only:

```
iran_plate ──┐
             ├──> core_plate
germany_plate┘

plate_number ──> all three   (compatibility shim; deletable later)
```

`iran_plate` and `germany_plate` never see each other. An app that ships only
Iranian plates never compiles a byte of the German validator or its PNGs.

### Why keep `plate_number`?

So nothing breaks on day one. `plate_number_holder` keeps its single
`package:plate_number/plate_number.dart` import through the whole refactor;
we swap it to the two country packages as the last step, once everything is
green. It is ~10 lines of `export`.

---

## 2. What goes where

### `core_plate`

| file | note |
|---|---|
| `model/plate_spec.dart` | **minus** the `PlateSpecs` catalogue |
| `model/plate_alphabet.dart` | **minus** the Persian constants; keeps `latinDigits`, `latinUppercase` |
| `model/plate_country.dart` | the class; **minus** `.iran` / `.germany` |
| `model/plate_number.dart`, `model/plate_input_source.dart` | as-is |
| `theme/plate_theme.dart` | as-is; docs stop saying "Iranian" — it is the generic white-face/black-frame theme both countries use |
| `bloc/*`, `input/plate_input_controller.dart` | as-is |
| `widgets/*` | all of them |
| `validators/plate_validator.dart` | **new**: the interface (see §3.3) |

### `iran_plate`

`PlateCountry.iran`, `PlateAlphabet.persianDigits`,
`PlateAlphabet.persianPlateLetters`, `IranPlates.car`, `IranPlates.bicycle`,
`assets/flags/Flag_of_Iran.svg`.

### `germany_plate`

`PlateCountry.germany`, `GermanPlates.car`, `assets/de_inspection_sticker.png`,
`assets/de_state_seal.png`, `GermanPlateValidator` (as a `PlateValidator`).

---

## 3. The four leaks that must be plugged first

These are the only places core code knows a specific country. Each is a small
API change and each makes core *better*, not just splittable.

### 3.1 `PlateFlag` hard-codes Iran's SVG

```dart
// widgets/plate_flag.dart — today
static const Map<String, String> _svgAssets = {
  'ir': 'assets/flags/Flag_of_Iran.svg',
};
```

**Fix:** move it onto the country, where every other country-specific fact
already lives.

```dart
// core: PlateCountry gains
final AssetBundleImage? flagSvg;   // asset path + owning package, or null

// iran_plate
static const iran = PlateCountry(
  code: 'ir',
  flagSvg: PlateAsset('assets/flags/Flag_of_Iran.svg', package: 'iran_plate'),
  ...
);
```

`PlateFlag` becomes: draw `country.flagSvg` if present, else fall back to
`country_flags` by code. The `'ir'` map and the `package: 'plate_number'`
string both disappear. Same treatment for `PlateDecal`'s
`AssetImage(..., package: 'plate_number')` — those literals move into
`germany_plate` and name their own package.

**Bonus:** `PlateFlag` currently takes `countryCode` (a String) and re-derives
everything. Take a `PlateCountry` instead and `_resolveSize`'s 7:4 guess
(15 lines) collapses to `country.flagAspectRatio`.

### 3.2 `PlateKeypad` defaults to Persian and tests for it

```dart
this.digitAlphabet   = PlateAlphabet.persianDigits,
this.letterAlphabet  = PlateAlphabet.persianPlateLetters,
...
final direction = widget.letterAlphabet == PlateAlphabet.persianPlateLetters
    ? TextDirection.rtl : TextDirection.ltr;
```

**Fix:** direction is a property of the alphabet, not a thing to guess by
equality.

```dart
// core: PlateAlphabet gains
final TextDirection direction;   // default ltr
```

The two defaults become required parameters (the host already passes them in
every real call site), and the `==` sniff becomes `letterAlphabet.direction`.

### 3.3 The validator is German-shaped in a country-neutral package

`GermanPlateValidator` is already spec-driven (`validateValues(spec, values)`
reads groups by key), which is exactly right — it just lives in the wrong
package, and `PlateCanvas`/`PlateKeypad` have no way to ask for one.

**Fix:** core gains a two-method interface and passes it through.

```dart
// core_plate/validators/plate_validator.dart
abstract class PlateValidator {
  const PlateValidator();
  PlateValidation validate(PlateSpec spec, List<String?> values);
  /// Characters that would complete a forbidden value if entered next.
  Set<String> barredNext(PlateSpec spec, List<String?> values, PlateSlot slot);
}

class PlateValidation {
  const PlateValidation.valid();
  const PlateValidation.invalid(this.reason);
  final String? reason;
}
```

`germany_plate` implements it; `PlateKeypad.unavailableKeys` is then computed by
`PlateCanvas` from `validator.barredNext(...)` instead of being wired up by the
host app. That deletes plumbing from `plate_number_holder` too.

The two `barredNextDigits` / `barredNextLetters` methods in the German
validator merge into one `barredNext` that branches on
`slot.alphabet.isNumeric` — ~20 lines saved.

### 3.4 `CountryPanel` defaults to `PlateCountry.iran`

```dart
this.country = PlateCountry.iran,
```

**Fix:** make it required. It is only ever built from `spec.country` anyway
(`plate_canvas.dart:276`), so no call site changes.

---

## 4. Shortening core

The user brief was "make it a lot shorter". These are the cuts, largest first.
None of them are cosmetic — each removes a thing that has to be maintained.

### 4.1 Kill the hand-written `==` / `hashCode` — **~140 lines**

`PlateSlot`, `PlateCountry` and `PlateTheme` each carry 25–45 lines of
boilerplate equality, and `PlateCountry` even ships its own `_listEquals`
because `foundation`'s wasn't imported.

Three of these are const singletons that are *only* ever compared to decide
"did the spec change" — `PlateSpec` already figured this out and compares on
`id` alone. Give `PlateCountry` and `PlateAlphabet` an `id`/`code` and do the
same. `PlateSlot`'s equality exists only for `PlateSpec` equality, which is
`id`-based, so it can go entirely. `PlateTheme` genuinely needs `==`
(`InheritedWidget.updateShouldNotify`, `CustomPainter.shouldRepaint`) — keep
it, but express it as one `List<Object?> get _props` used by both `==` and
`hashCode`: 45 lines → 12.

### 4.2 Delete `LetterInputMode` — **~50 lines**

`model/plate_number.dart` carries `LetterInputMode` and
`defaultLetterInputMode()`; `model/plate_input_source.dart` carries
`PlateInputSource`, `defaultInputSource()` and a
`inputSourceFromLetterMode()` adapter whose docs already call the old one
deprecated. Two enums for one concept.

Delete `LetterInputMode`, `defaultLetterInputMode()` and the adapter; migrate
the four uses in `plate_number_holder` to `PlateInputSource`. This is the
single cheapest large cut in the codebase.

### 4.3 One geometry type instead of four — **~40 lines**

`PlateSlot`, `PlateRule`, `PlateLabel` and `PlateDecal` all declare
`final double left, top, width, height;` with the same doc comment. Give core

```dart
@immutable
class PlateBox {
  const PlateBox(this.left, this.top, this.width, this.height);
  final double left, top, width, height;
  Rect get rect => Rect.fromLTWH(left, top, width, height);
}
```

and have the four carry a `PlateBox box`. The spec literals get *shorter* too:

```dart
PlateRule(left: 404, top: 4.4, width: 5, height: 101.2)
PlateRule(PlateBox(404, 4.4, 5, 101.2))
```

This is also what makes `debugValidateSpec`'s bounds check a one-liner.

### 4.4 Compress `debugValidateSpec` — **~35 lines**

It walks the slot list four separate times with four `for` loops. One pass
plus a `Set` for the cycle check does the same job in ~25 lines. Keep every
assertion message — they are the valuable part.

### 4.5 Merge `ShowPlate` and `PlateText` — **~25 lines**

Identical `BlocBuilder` + empty-state preamble, differing only in what they
render. One widget with a `PlateMode`-ish switch, or one shared private
`_PlateStateBuilder`. Also drops the two copies of the placeholder string
`'Default Widget for Empty Plate Value'`, which no shipping package should
have.

### 4.6 Smaller items — **~30 lines**

- `PlateFlag._resolveSize` — obsolete once §3.1 gives it the aspect ratio.
- `PlateNumber.copyWith` with a single field — replace with a direct
  constructor call at the two call sites.
- `PlateSpec.slotAt` does a linear scan on every glyph render; build a
  `Map<int, PlateSlot>` once in the constructor. Not a line saving, but it is
  the one real performance smell in the file.

### Expected result

| | now | after |
|---|---|---|
| `core_plate` | — | **~1 550** |
| `iran_plate` | — | ~230 (almost all spec data) |
| `germany_plate` | — | ~270 |
| total | 2 588 | ~2 050 |

Core alone drops ~40 %, and adding a third country stops touching it at all.

---

## 5. Phasing

Each phase ends analyzer-clean with the holder app still running. No phase
depends on a later one.

| | phase | touches |
|---|---|---|
| **S1** | Plug the four leaks (§3), still one package | `plate_flag`, `plate_keypad`, `country_panel`, new validator interface |
| **S2** | The cuts (§4), still one package | models, theme, `show_plate` |
| **S3** | Create `packages/core_plate` — move everything except country data; `plate_number` becomes a facade that re-exports it | mechanical file moves + import rewrites |
| **S4** | Create `packages/iran_plate`; move Iran's country, alphabets, specs, flag asset | |
| **S5** | Create `packages/germany_plate`; move Germany's country, spec, decals, validator | |
| **S6** | Point `plate_number_holder` at `iran_plate` + `germany_plate` directly; decide whether `plate_number` stays as a convenience meta-package or is retired | holder `pubspec.yaml` + import lines |

S1 and S2 are the real work and are worth doing even if the split were
abandoned. S3–S5 are file moves once S1 has removed every cross-country
reference.

---

## 6. Open questions

1. **Package naming.** Dart requires snake_case, so `core_plate`, `iran_plate`,
   `germany_plate`. Prefixing them (`plate_core`, `plate_ir`, `plate_de`) reads
   better on pub.dev and groups alphabetically. Preference?
2. **Publish or not?** If these ever go to pub.dev, each needs its own version,
   changelog and licence, and `iran_plate` must depend on a *published*
   `core_plate` range rather than a path. Worth deciding before S3, because it
   changes whether the `plate_number` facade survives.
3. **`melos` vs. pub workspaces.** Pub workspaces (Dart 3.6+) need no extra
   tooling and your SDK constraint already allows them. Recommend workspaces
   unless you want melos's scripting.
4. **`PlateKeypad` in core?** It is 408 lines of demo-ish soft keyboard with its
   own theme class. Arguably it belongs in a `plate_keypad` package, or in the
   holder app, rather than in the engine every consumer pulls in. Cheap to
   decide now, expensive later.
