---
name: p10
description: "P10 — consolidate the four showcase apps and three minimal examples into one standalone plate_gallery app, reducing each package's example to a single ~30-line pub.dev example. Invoke with /p10 in a fresh session."
---

> **Run this in a fresh session** (`/clear` first).
> **Model:** Opus 5 · **reasoning:** high · **extended thinking:** ON
> **Requires:** /p4 /p5 /p9
> Full index: `/phases` · evidence: `claude/AUDIT_DIAGNOSIS.md` · overview: `claude/REFACTOR_ROADMAP.md`

# P10 — `plate_gallery/` consolidation

## Context (assume nothing else)

Every package in `~/StudioProjects/plate/` ships an `example/` sub-package. They fall into two groups.

**Three are minimal and appropriate** (27–47 lines): `iran_plate/example`, `germany_plate/example`,
`plate_keypad/example`. `core_plate_bloc/example` (123 lines) is longer but earns it — it demonstrates
the bidirectional binding, which is the package's whole point.

**One is a duplicate.** `core_plate/example/lib/main.dart` (27 lines) is a near-byte-identical clone of
`iran_plate/example/lib/main.dart`, differing only in a trailing comment, and it **imports
`iran_plate`** — making the engine's own example depend on a country package, which
`core_plate.dart:10-14` forbids. P0 flagged this and left the Dart alone.

**Two are showcase applications that duplicate each other:**

| | `palestine_plate/example` | `yemen_plate/example` |
|---|---:|---:|
| `lib/main.dart` | 883 lines | 616 lines |
| `lib/gallery.dart` | 354 lines | 279 lines |
| **`void main()` entry points** | **2** | **2** |

Both ship two independent apps in one package. Both define their own catalogue, their own `_Kind`/`_Entry`
model, their own card widget. And the shared scaffolding is near-identical between the two packages —
measured by line-level diff:

| Class | Palestine | Yemen | Similarity |
|---|---:|---:|---:|
| `_SampleCard` | 8 | 8 | **100%** |
| `_Section` | 34 | 34 | **94%** |
| `_PickerRow` | 38 | 38 | **92%** |
| `_PlateStage` | 29 | 29 | **90%** |
| `_SampleCardState` | 67 | 60 | 65% |
| `_CatalogueTab` | 54 | 70 | 48% |

`gallery.dart` in both defines the same six class names: `GalleryApp`, `_GalleryPage`, `_SectionHeader`,
`_PlateGrid`, `_PlateCard`, `_Entry`.

**Why they duplicate: there is no catalogue contract.** Each country exposes its plates differently:

| Package | Catalogue surface |
|---|---|
| `iran_plate` | none — two bare consts, `IranPlates.car` / `.bicycle` |
| `germany_plate` | none — one const, `GermanPlates.car` |
| `palestine_plate` | `PSWestBankPlates.all` and `PSGazaPlates.all` (`List<PlateSpec>`) |
| `yemen_plate` | `carGeometries`/`motoGeometries` maps + `car(...)`/`moto(...)` lookups (post-P4) |

Four idioms. Any app that wants to show all of them writes four adapters — so each app wrote its own.

**What P3–P5 changed, and why the gallery must be written after them:** a plate's appearance is now
three independent render-time inputs — `spec:` (geometry), `theme:` (colour), `country:` (the panel
block) — rather than a single spec that bakes all three. A gallery written against the old shape would
enumerate 55 Yemen specs; written against the new one it enumerates 11 geometries × a usage picker.

## Scope

**In:**
- `plate_gallery/` — new package at the repo root.
- Root `pubspec.yaml` — add `plate_gallery` to `workspace:`.
- `palestine_plate/example/`, `yemen_plate/example/` — reduced to one minimal `main.dart` each;
  both `gallery.dart` files deleted.
- `core_plate/example/` — rewritten to stop importing `iran_plate`.
- `iran_plate/example/`, `germany_plate/example/`, `plate_keypad/example/` — reviewed, kept as they are
  unless they no longer compile.
- Each package's `README.md` example snippet.

**Out — frozen:**
- **Every `lib/` directory.** This phase writes an application. If the gallery needs something a country
  package does not expose, **add nothing to the package** — build it in the gallery's own adapter and
  report the gap. A showcase must not drive library API.
- **`core_plate_bloc/example`.** It demonstrates the binding and is not a showcase. Leave it.
- **`palestine_plate/test/`.** The golden test lives in the package, not the gallery, and stays there.
  Gallery-level goldens are P11's business.
- **Package dependency direction.** `plate_gallery` depends on the countries; no country ever gains a
  dependency on the gallery, on `plate_keypad`, or on another country.
- `plate_number_holder/`.

## The catalogue contract — in the gallery, not in core

The gallery defines its own model and one adapter per country. This is deliberate: a catalogue is a
*presentation* concern, and putting a `PlateCatalog` type into `core_plate` would make the engine know
about lists of plates, which is one step from knowing about countries.

```dart
// plate_gallery/lib/src/catalogue.dart
/// One entry in the gallery: everything needed to draw one plate and say what
/// it is.
///
/// [spec] is geometry, [theme] is colour and [country] is the panel block —
/// three independent inputs to PlateCanvas since core_plate 0.6.0. An entry
/// binds one combination of the three and names it.
@immutable
class GalleryEntry {
  const GalleryEntry({
    required this.id,
    required this.label,
    required this.spec,
    this.theme,
    this.country,
    this.validator,
    this.sampleValues,
  });

  final String id;              // stable, for goldens and deep links
  final String label;           // human-readable, shown on the card
  final PlateSpec spec;
  final PlateTheme? theme;
  final PlateCountry? country;
  final PlateValidator? validator;
  final List<String?>? sampleValues;
}

/// Everything one country package offers.
abstract interface class GallerySource {
  String get countryName;
  List<GallerySection> get sections;
}
```

One adapter file per country, each ~40–90 lines:

- `sources/iran.dart` — 2 entries.
- `sources/germany.dart` — 1 entry, carrying `const GermanPlateValidator()`.
- `sources/palestine.dart` — 11 specs post-P5; the legacy family expands over `PSUsage` using
  `PSWestBankPlates.legacyCountryForUsage(usage)` and `PSThemes.forUsage(usage)`.
- `sources/yemen.dart` — 11 geometries post-P4; each expands over the usages its system issues
  (`YemenUsage.unified` / `.northern`) using `YemenCountry.unifiedFor`/`northernFor` and
  `YemenThemes.forUnifiedUsage`/`forNorthernUsage`.

The adapters are where the four idioms get normalised, once, in an app — instead of four times, in four apps.

## Steps

### 1. Scaffold

```bash
cd ~/StudioProjects/plate
flutter create --template=app --platforms=linux,web --project-name plate_gallery plate_gallery
```

`pubspec.yaml`: `publish_to: none`, `resolution: workspace`, and dependencies on `core_plate`,
`plate_keypad` and all four country packages. Add it to the root `workspace:` list.

### 2. Port the shared widgets — once

Take the best of each pair and write one copy in `plate_gallery/lib/src/widgets/`:

- `PlateStage` — from `_PlateStage` (90% identical across the two apps).
- `SectionHeader` — from `_Section` / `_SectionHeader`.
- `PickerRow` — from `_PickerRow` (92% identical).
- `PlateCard` — merge `_SampleCard`/`_SampleCardState` and `_PlateCard`/`_PlateCardState`. These are the
  most divergent pair (65%); read both before writing, and prefer Palestine's, which handles the
  `onChooseCharacter` picker path that Yemen's does not need.

Where the two differ, prefer the version that does **not** assume a country. Any `PSUsage`/`YemenUsage`
reference in a shared widget is a bug — it belongs in the adapter.

### 3. Build the app

Three screens is enough:

- **Catalogue** — every `GalleryEntry` from every source, grouped by country then section, rendered in
  `PlateMode.display` with `sampleValues`. This subsumes both `gallery.dart` files.
- **Playground** — one entry at a time, `PlateMode.input`, with pickers for country / spec / usage /
  input source, live validation via the entry's validator, and `PlateKeypad` wired through
  `PlateController.submit` / `.backspace` when `PlateInputSource.packageKeypad` is selected. This
  subsumes both `main.dart` files. Use `PlateCharacterPicker.show` for `onChooseCharacter` — that is
  what `plate_keypad` is for, and it is why the gallery depends on it.
- **About** — package versions and a one-line note per country pointing at its README.

### 4. Reduce the examples

Each `example/lib/main.dart` becomes the pub.dev example: one plate, no picker, no tabs, ~30 lines.
`germany_plate/example` is already exactly right (30 lines) — use it as the template for the others.

- `palestine_plate/example` — `PSWestBankPlates.modernCar` with
  `PSThemes.forUsage(PSUsage.private)`. Delete `gallery.dart`. Drop the `plate_keypad` dependency from
  its pubspec if the reduced example no longer uses the picker.
- `yemen_plate/example` — `YemenUnifiedPlates.car(numberDigits: 5)!` with
  `YemenCountry.unifiedFor(YemenUsage.private)` and `YemenThemes.unified`. Delete `gallery.dart`.
  While here, rewrite the long `pubspec.yaml` font comment P9 trimmed, if it still mentions line numbers.
- `core_plate/example` — **must not import a country package.** Give it the four-slot local `const`
  spec that `core_plate_bloc/example/lib/main.dart:11-41` already defines for exactly this reason: two
  Latin letters, two digits, a plain blue panel. Copy that spec into the example (it is example code,
  duplicating ~30 lines of it across two examples is correct — neither package may depend on the other).
  Remove `iran_plate` from its pubspec and delete P0's `TODO(P10)` marker.
- `iran_plate/example`, `germany_plate/example`, `plate_keypad/example` — unchanged unless broken.
  `plate_keypad/example/pubspec.yaml` should have had its `core_plate` resolution fixed in P0; confirm.

### 5. READMEs

Every package README's usage snippet must compile against the post-P5 API — that means `country:` and
`theme:` alongside `spec:` for Palestine and Yemen. Add a line to each pointing at `plate_gallery` for
the full catalogue.

## Verification

```bash
cd ~/StudioProjects/plate
flutter pub get

(cd plate_gallery && flutter analyze --no-fatal-infos && flutter run -d linux --debug)
(cd plate_gallery && flutter build web --release)     # must succeed

# Acceptance: exactly one main() per example, and no gallery.dart survives.
find . -path ./plate_number_holder -prune -o -name 'main.dart' -path '*/example/*' -print \
  | xargs grep -c 'void main('           # every file: 1
find . -name 'gallery.dart' -not -path './plate_gallery/*' -not -path './plate_number_holder/*'
#   -> no output

# Acceptance: the shared widgets exist exactly once in the repo.
grep -rln "_PlateStage\|_PickerRow\|_SampleCard\|class _Section\b" --include=*.dart . \
  | grep -v plate_number_holder
#   -> no output (they are now public in plate_gallery/lib/src/widgets/)

# Acceptance: the engine example no longer knows a country.
grep -rn "iran_plate\|germany_plate\|palestine_plate\|yemen_plate" core_plate/example/
#   -> no output

# Acceptance: no country package depends on the gallery or on plate_keypad.
grep -rn "plate_gallery\|plate_keypad" --include=pubspec.yaml \
  iran_plate/ germany_plate/ palestine_plate/ yemen_plate/ core_plate/
#   -> no output

# Acceptance: coverage. Count entries against each package's own catalogue.
#   Iran 2 · Germany 1 · Palestine 11 specs · Yemen 11 geometries
#   Add an assertion for this in plate_gallery/test/catalogue_test.dart.

# Acceptance: total example + gallery Dart under 1,200 lines (from 2,386).
find plate_gallery/lib */example/lib -name '*.dart' -not -path './plate_number_holder/*' \
  | xargs wc -l | tail -1

# Everything else still green.
for p in core_plate core_plate_bloc plate_keypad iran_plate germany_plate palestine_plate yemen_plate; do
  (cd "$p" && flutter analyze --no-fatal-infos && flutter test 2>/dev/null) || echo "check $p"
done
```

**Manual check — do it.** Run the gallery on Linux and in Chrome. Walk every country. For Yemen, cycle
all five northern usages and confirm the field colour *and* the panel word both change; for Palestine,
cycle the legacy usages and confirm the plate inverts for public transport. These are the P4/P5 behaviours,
and the gallery is the first place a human sees them all at once.

## Acceptance criteria (restated for the record)

1. `plate_gallery/` builds and runs on Linux and Chrome; `flutter analyze` clean.
2. Every spec reachable in the four old apps is reachable in the gallery — asserted by a test that counts
   entries per source against each package's own catalogue surface.
3. No `example/` directory contains a second `void main()`; no `gallery.dart` outside `plate_gallery/`.
4. `_PlateStage`, `_Section`, `_PickerRow` and `_SampleCard` exist exactly once in the repo.
5. `core_plate/example` imports no country package.
6. No country package gained a dependency.
7. Example + gallery Dart totals under 1,200 lines.
8. Every package's own test suite still passes.

## Dependencies

P4 and P5 (the gallery is written against the collapsed API). P9 (so it is not written against docs the
next phase deletes). P3 transitively.

## Line estimate

`plate_gallery/lib` +950 · `plate_gallery/test` +60 · seven `example/` dirs 2,386 → ~210.
**Net ≈ −1,230.**
