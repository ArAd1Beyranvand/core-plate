---
name: p4
description: "P4 — collapse yemen_plate's 55 const PlateSpecs to 11 by removing the usage axis, which varies only the id and the country block. The single largest deletion in the roadmap. Invoke with /p4 in a fresh session."
---

> **Run this in a fresh session** (`/clear` first).
> **Model:** Opus 5 · **reasoning:** high · **extended thinking:** ON
> **Requires:** /p3  (ideally /p3b too)
> Full index: `/phases` · evidence: `claude/AUDIT_DIAGNOSIS.md` · overview: `claude/REFACTOR_ROADMAP.md`

# P4 — Yemen: collapse the usage axis

## Context (assume nothing else)

`~/StudioProjects/plate/yemen_plate` (3,168 lines of `lib/`, **zero tests**) models Yemen's two
concurrent plate systems:

- **System A**, `lib/src/unified_plates.dart` (872 lines) — the 2026 unified white plate. A blue side
  panel carries the usage as two lines of text (`خصوصي` / `PRIV.`). The field is white for every usage;
  System A does not colour-code by use.
- **System B**, `lib/src/northern_plates.dart` (1,108 lines) — the 1993 northern plate. The **field
  colour** is the usage signal; the usage word is printed in the top band.

Both files share one shape. Geometry is hoisted into named private consts — `_carWidth`, `_height`,
`_carPanel`, `_carGov2Serial5`, `_carMirrorsGov2Serial5`, `_carRules`, `_carLabels`,
`_groupsGov2Serial5`, `_borderRatio` — and then the same const is spelled out once per usage:

```dart
  static const PlateSpec carGov2Serial5Private = PlateSpec(
    id: 'ye.northern.car.g2s5.private',
    country: YemenCountry.northernPrivate,     // <-- only this
    canvasWidth: _carWidth, canvasHeight: _height,
    panel: _carPanel, slots: _carGov2Serial5,
    mirrors: _carMirrorsGov2Serial5, rules: _carRules,
    labels: _carLabels, textGroups: _groupsGov2Serial5,
    borderWidthRatioOverride: _borderRatio,
  );
```

`northern_plates.dart:615-617` states it outright: *"Four layouts x five usages, and the only fields that
vary with usage are `id` and `country` — the country carrying the usage word, and the field colour coming
from the theme."*

**The counts:**

| File | Specs | Real geometries | Clones |
|---|---:|---:|---:|
| `northern_plates.dart:621-1018` | 25 | 5 (4 car + 1 moto) | 20 |
| `unified_plates.dart:373-786` | 30 | 6 (2 vehicles × 3 lengths) | 24 |

Below each block sits a hand-written const lookup map — `Map<YemenUsage, Map<(int,int), PlateSpec>> car`
(`northern_plates.dart:1028-1088`) and `Map<YemenUsage, Map<int, PlateSpec>> moto`, plus the System A
pair at `unified_plates.dart:796-855` — enumerating every clone, so adding a geometry means editing
five map entries in lockstep.

**P3 removed the reason all of this exists.** `PlateCanvas` and `PlateView` now take an optional
`country:` that overrides `spec.country` at render time — exactly as `theme:` already overrides the
theme. The usage axis was never geometry; it is a render-time input, and it already *is* one for colour
(`YemenThemes.forNorthernUsage`) and for the country block (`YemenCountry.northernFor`). This phase
finishes the thought.

## The target API

```dart
// One spec per geometry:
YemenNorthernPlates.car(governorateDigits: 2, serialDigits: 5)   // -> PlateSpec?
YemenNorthernPlates.moto(governorateDigits: 2, serialDigits: 5)
YemenUnifiedPlates.car(numberDigits: 5)
YemenUnifiedPlates.moto(numberDigits: 5)

// The usage axis, already country/theme lookups, unchanged:
PlateCanvas(
  spec:    YemenNorthernPlates.car(governorateDigits: 2, serialDigits: 5)!,
  country: YemenCountry.northernFor(usage),
  theme:   YemenThemes.forNorthernUsage(usage),
  onChooseCharacter: ...,
);
```

Ids lose their usage suffix: `ye.northern.car.g2s5.private` → `ye.northern.car.g2s5`.

## Scope

**In:**
- `yemen_plate/lib/src/northern_plates.dart`
- `yemen_plate/lib/src/unified_plates.dart`
- `yemen_plate/lib/yemen_plate.dart` (library doc — it advertises "fifty-five `const` `PlateSpec`s")
- `yemen_plate/README.md`, `yemen_plate/CHANGELOG.md`
- `yemen_plate/example/lib/main.dart` and `gallery.dart` — **minimally**, only enough to keep them
  compiling and rendering. They are rewritten wholesale in P10.
- `yemen_plate/test/` — new, see below.
- `yemen_plate/pubspec.yaml` — `core_plate: ^0.6.0` (P3 shipped the override).

**Out — frozen:**
- **Every geometry constant.** `_carWidth`, `_height`, `_motoWidth`, `_borderRatio`, `_carPanel`,
  `_motoPanel`, every `_carGov*`/`_car*Slots` list, every `_carMirrors*` list, `_carRules`, `_carDivider`,
  `_carRule`, `_carLabels`, `_motoLabels`, `_echoTop`, `_echoHeight`, `_motoEchoHeight`, every
  `_groups*` list. Not one number moves. These are `// CALIBRATE` values proportioned from photographs;
  re-deriving them is a different project.
- `yemen_country.dart` — all twelve `PlateCountry` consts and both `unifiedFor`/`northernFor` lookups
  stay exactly as they are. They are the data this phase makes load-bearing. (`YemenCountry.unified` and
  `northernMilitaryModern` are unreferenced; P9 decides their fate, not this phase.)
- `yemen_themes.dart`, `yemen_colors.dart`, `yemen_usage.dart`, `yemen_governorates.dart`,
  `yemen_alphabets.dart`, `yemen_validators.dart`, `yemen_serial_generator.dart` — untouched.
- `core_plate` — P3 built the override; this phase only consumes it.
- The `@Deprecated` annotations on the five moto specs. The motorcycle geometry is unverified and the
  deprecation says so; carry the annotation onto the one surviving moto spec verbatim.

## Steps

### 1. `northern_plates.dart` — 25 specs → 5

Keep exactly one spec per geometry, named for the geometry and carrying the **private** country as its
default (private is the ordinary case, and `spec.country` must remain a sensible fallback for a caller
that passes no override):

- `carGov2Serial5` (id `ye.northern.car.g2s5`)
- `carGov1Serial5` (id `ye.northern.car.g1s5`)
- `carGov2Serial4` (id `ye.northern.car.g2s4`)
- `carGov2Serial6` (id `ye.northern.car.g2s6`)
- `motoGov2Serial5` (id `ye.northern.moto.g2s5`) — keep the `@Deprecated`

Delete the other twenty. Replace the two nested const maps with one flat const map plus a lookup:

```dart
  /// The car geometries this package builds, keyed by
  /// `(governorate digits, serial digits)`. A combination that is missing is
  /// missing on purpose; see the class-level TODO.
  static const Map<(int, int), PlateSpec> carGeometries = <(int, int), PlateSpec>{
    (2, 5): carGov2Serial5,
    (1, 5): carGov1Serial5,
    (2, 4): carGov2Serial4,
    (2, 6): carGov2Serial6,
  };

  /// The northern car plate with this register shape, or null when the
  /// combination is not one this package builds.
  ///
  /// Usage is not a parameter. It selects the country block and the field
  /// colour, both of which the host passes to the canvas:
  /// `country: YemenCountry.northernFor(usage)`,
  /// `theme: YemenThemes.forNorthernUsage(usage)`.
  static PlateSpec? car({required int governorateDigits, required int serialDigits}) =>
      carGeometries[(governorateDigits, serialDigits)];
```

Same for `motoGeometries` / `moto(...)`.

Keep `byDigits` as a `@Deprecated` shim for one release so an external caller does not break:

```dart
  @Deprecated(
    'Usage no longer selects a spec — it selects a country block and a theme. '
    'Use car()/moto() and pass YemenCountry.northernFor(usage) to the canvas. '
    'Will be removed in 0.4.0.',
  )
  static Map<(int, int), PlateSpec> byDigits(YemenUsage usage, {bool motorcycle = false}) =>
      usage.onNorthern ? (motorcycle ? motoGeometries : carGeometries) : const {};
```

Note the behaviour change this shim makes explicit: `byDigits(police)` returned `{}` before and still
does, because `YemenUsage.onNorthern` is false for police.

### 2. `unified_plates.dart` — 30 specs → 6

Identically:

- `car4`, `car5`, `car6` (ids `ye.unified.car4` … )
- `moto4`, `moto5`, `moto6`
- `carGeometries` / `motoGeometries` as `Map<int, PlateSpec>`
- `car({required int numberDigits})`, `moto({required int numberDigits})`
- `byNumberLength` kept as a `@Deprecated` shim returning the geometry map for a usage System A issues
  (`usage.onUnified`) and `{}` otherwise
- `numberLengths` unchanged

Default `country:` on each surviving spec is `YemenCountry.unifiedPrivate`.

### 3. Update the example enough to compile

`yemen_plate/example/lib/main.dart` and `gallery.dart` select specs by usage today. Change each call site
to select by geometry and pass `country:` alongside the `theme:` it already passes. Do not restructure the
apps — P10 replaces them.

### 4. Add `yemen_plate/test/yemen_specs_test.dart`

This package has never had a test and it is about to lose 44 constants. Pin what survives:

- Every spec in `carGeometries` / `motoGeometries` on both systems passes `debugValidateSpec`.
- Every spec's `textGroups` carry the keys its validator reads: `governorate` + `serial` on System B,
  `number` + `sideCode` on System A.
- Slot counts match the geometry name: `carGov2Serial5` has 7 slots (2 + 5), `car4` has 4 + 2 = 6.
- Ids are unique across both files and carry **no** usage segment:
  `expect(id.split('.').length, 4)` and `expect(YemenUsage.values.any((u) => id.contains(u.name)), isFalse)`.
- `YemenNorthernSerialGenerator.generate` and `YemenUnifiedSerialGenerator.generate` still produce values
  their validators accept, for every surviving spec, over 1,000 seeded draws — the same round-trip
  `palestine_plate/test/palestine_serial_generator_test.dart` already does for Palestine. This is the
  strongest available proof that no group key or slot order moved.
- The deprecated `byDigits`/`byNumberLength` shims return the same geometry sets.

### 5. Docs

- `yemen_plate.dart` library doc says "fifty-five `const` `PlateSpec`s". Change to eleven and add a short
  paragraph: *usage selects a country block and a theme, not a spec.* Keep everything else — the System A
  vs System B explanation is the most useful text in the package.
- `README.md`: update the counts and the usage example.
- `CHANGELOG.md`: `0.3.0`, breaking. List the removed constant names — all 44 — so a consumer can grep.

## Verification

```bash
cd ~/StudioProjects/plate/yemen_plate

flutter analyze --no-fatal-infos
flutter test                                   # the new spec suite

# The counts are the point of the phase.
grep -c 'static const PlateSpec' lib/src/northern_plates.dart   # 5
grep -c 'static const PlateSpec' lib/src/unified_plates.dart    # 6

# No usage word survives in an id.
grep -n "id: 'ye\." lib/src/*.dart | grep -Ei 'private|forHire|transport|government|police|military'
#   -> no output

# No geometry constant moved.
git diff lib/src/northern_plates.dart | grep -E '^[-+].*(PlateBox|PlateSlot|PlateMirror|PlateRule|_carWidth|_height|_borderRatio)' \
  | grep -v '^[-+].*//'
#   -> only deletions from inside removed spec bodies; no changed numbers

(cd example && flutter analyze --no-fatal-infos && flutter run -d linux --debug)
#   -> renders; switching usage in the app changes colour AND panel text
```

**Visual check, and do it — this phase changes what a plate looks like if the override is wired wrong.**
Run the example, cycle through all five northern usages on a `(2,5)` car and all five unified usages on a
`car5`, and confirm for each: the field colour changes (System B) and the side-panel text changes
(System A). Before P4 those came from the spec; after P4 they come from `country:` and `theme:`. If the
panel text is stuck on `خصوصي`, the override is not reaching `CountryPanel`.

**Success:** 11 specs remain; `flutter analyze` clean; the new test suite passes including the
generator round-trips; no geometry number changed; the example renders all ten usage/system
combinations correctly.

## Dependencies

P3 (`PlateCanvas.country` must exist). P1 transitively.

**Check whether P3B has run.** P3B replaces the hand-written slot and mirror registers in these two files
with `plateRegisterAcross` / `plateEcho` calls, and converts the affected constants from `const` to
`final`.

- **If P3B ran first** (preferred), the geometry constants you are preserving are already generator calls
  and the five surviving specs are `static final`, not `static const`. Keep them `final`; do not try to
  restore `const`. The "no geometry number moved" verification below still applies — it is now a diff of
  generator arguments rather than of box literals.
- **If P3B has not run**, proceed exactly as written. P3B afterwards will find four mirror lists instead
  of the original eight, which is simply less work.

Either order ends in the same place.

## Line estimate

`northern_plates.dart` −325 · `unified_plates.dart` −386 · example +18 · docs +25 · new test +140.
**Net ≈ −700 of production code, −528 including the test.**
