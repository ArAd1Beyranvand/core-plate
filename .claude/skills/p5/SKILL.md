---
name: p5
description: "P5 — remove palestine_plate's two colour-clone specs and collapse the three ink-variant PlateCountry consts onto the render-time country override from P3. Invoke with /p5 in a fresh session."
---

> **Run this in a fresh session** (`/clear` first).
> **Model:** Sonnet 5 · **reasoning:** medium · **extended thinking:** off
> **Requires:** /p3
> Full index: `/phases` · evidence: `claude/AUDIT_DIAGNOSIS.md` · overview: `claude/REFACTOR_ROADMAP.md`

# P5 — Palestine: collapse the colour clones

## Context (assume nothing else)

`~/StudioProjects/plate/palestine_plate` (1,855 lines of `lib/`, 542 lines of tests including one golden
image) models two designs: the West Bank's green-on-white scheme and Gaza's separate scheme.

`lib/src/palestine_country.dart` declares seven `PlateCountry` consts. Three of them —
`westBankGreenInk` (`:47`), `westBankWhiteInk` (`:57`) and `westBankRedInk` (`:66`) — are byte-identical
apart from `panelTextColor`, all carry `code: 'ps'` (so they compare equal, `PlateCountry`'s equality
being over the code), and all use `panelColor: Color(0x00000000)`. The file explains at `:18-39` that
this is a workaround: *"`PlateCountry` carries colours and `PlateSpec` carries a country, so a country
const is pinned to one colour scheme — which collides head-on with a design whose colour is derived from
usage."*

That workaround leaks into the spec catalogue. `lib/src/west_bank_plates.dart` declares three specs with
**identical geometry**:

- `legacyCar` (`:199`) — `country: PSCountries.westBankGreenInk`
- `legacyCarPublicTransport` (`:219`) — `country: PSCountries.westBankWhiteInk`
- `legacyCarGovernment` (`:234`) — `country: PSCountries.westBankRedInk`

All three use `_legacyCarSlots`, `_carPanel`, `_carRules`, `_legacyCarLabels`, `_legacyGroups` and
`borderWidthRatioOverride: 0.027`. The comment at `:215-218` names the cause outright:

> *A whole second spec for one colour because `PlateCountry` carries its own text colour and `PlateSpec`
> carries a country: there is no way to recolour the block from the theme.*

A lookup, `legacyCarForUsage(PSUsage)` (`:255`), maps usages onto the three.

P3 removed the reason: `PlateCanvas` and `PlateView` now take an optional `country:` that overrides
`spec.country` at render time, exactly as `theme:` already overrides the theme.

This is the small sibling of P4. It is separate because Palestine's blast radius includes a **golden
test**, and mixing that into the 700-line Yemen deletion would make a pixel regression hard to attribute.

## Scope

**In:**
- `palestine_plate/lib/src/west_bank_plates.dart`
- `palestine_plate/lib/src/palestine_country.dart` (docs; the three consts stay)
- `palestine_plate/test/golden_test.dart` — call sites only
- `palestine_plate/example/lib/main.dart`, `gallery.dart` — minimally, to keep them compiling
- `palestine_plate/README.md`, `CHANGELOG.md`
- `palestine_plate/pubspec.yaml` — `core_plate: ^0.6.0`

**Out — frozen:**
- **Every geometry constant.** `_carPanel`, `_carRules`, `_modernCarSlots`, `_legacyCarSlots`,
  `_modernCarLabels`, `_legacyCarLabels`, `_modernGroups`, `_legacyGroups`, `_twoLineRules`,
  `_twoLinePanel`, `_twoLineLabels`, and every inline `PlateBox` in the moto and trade specs. Not one
  number moves. The dot-geometry rule documented at `:123-126` is measured, not derived.
- **The three ink consts themselves.** `westBankGreenInk`, `westBankWhiteInk` and `westBankRedInk` stay
  in `palestine_country.dart` — they are exactly the data a host now hands to `country:`. Only their
  *use as spec fields* goes away. Same for `westBankGreenInkInline` and `westBankGreenInkBlank`, each
  used by one spec whose panel genuinely differs.
- **All nine other specs.** `modernCar`, `modernCarTwoLine`, `legacyCarTwoLine`, `modernMoto`,
  `modernMotoTwoLine`, `modernTrade` and the four Gaza specs keep their ids, geometry and country.
  Gaza is a different design, not a recolouring, and `PSCountries.gaza2012`/`gaza2021` carry real flags.
- `palestine_themes.dart` (P2 already rewrote it), `palestine_colors.dart`, `palestine_usage.dart`,
  `palestine_governorates.dart`, `palestine_alphabets.dart`, `palestine_validators.dart`.
- **The golden image `test/goldens/wb_modern_car_green.png`.** Do not run `--update-goldens` in this
  phase. If the golden moves, the phase is wrong.
- `core_plate`.

## Steps

### 1. Delete the two clone specs

Remove `legacyCarPublicTransport` (`:219-232`) and `legacyCarGovernment` (`:234-248`) and the
`legacyCarForUsage` lookup (`:255-266`). `legacyCar` survives with
`country: PSCountries.westBankGreenInk` as its default.

Replace `legacyCarForUsage` with a country lookup that mirrors Yemen's `northernFor`, so both packages
present one idiom:

```dart
  /// The `ف / P` block a legacy plate of this usage is printed in — the value a
  /// host hands to `PlateCanvas.country` beside the theme from
  /// `PSThemes.forUsage`.
  ///
  /// Replaces `legacyCarForUsage`, which returned a whole second spec for a
  /// colour. Geometry is identical across every legacy usage; only the ink
  /// changes, and ink is a render-time choice.
  static PlateCountry legacyCountryForUsage(PSUsage usage) => switch (usage) {
    PSUsage.publicTransport || PSUsage.tradePlate => PSCountries.westBankWhiteInk,
    PSUsage.government || PSUsage.exempt => PSCountries.westBankRedInk,
    _ => PSCountries.westBankGreenInk,
  };
```

Put it beside `legacyCar` in `PSWestBankPlates`, not in `PSCountries` — it is a fact about this spec
family. Keep `legacyCarForUsage` for one release as a `@Deprecated` shim returning `legacyCar` regardless
of usage, with a message pointing at `legacyCountryForUsage`.

### 2. Fix `PSWestBankPlates.all`

`all` (`:527`) lists every spec. Remove the two deleted entries. Anything iterating `all` — the golden
test, both example apps — now sees 11 specs instead of 13.

### 3. Update call sites

- `test/golden_test.dart`: wherever it renders `legacyCarPublicTransport` or `legacyCarGovernment`, render
  `legacyCar` with `country: PSWestBankPlates.legacyCountryForUsage(usage)` and the theme it already passes.
  **Golden file names must not change** — a renamed golden is a new golden and proves nothing.
- `example/lib/main.dart` and `gallery.dart`: same substitution, minimal edit. P10 rewrites them.

### 4. Docs

- `palestine_country.dart:18-39`: the "Why there are several West Bank consts" section now describes
  render-time values rather than a workaround. Rewrite that paragraph — keep the `P`-is-Portugal's-code
  note and the transparent-panel rationale, both of which are still true and still useful.
- `west_bank_plates.dart:215-218`: the *"A whole second spec for one colour"* comment describes code that
  no longer exists. Delete it.
- `README.md`: the spec table drops two rows; the usage example gains `country:`.
- `CHANGELOG.md`: `0.2.0`, breaking — name the two removed constants and the removed lookup.

## Verification

```bash
cd ~/StudioProjects/plate/palestine_plate

flutter analyze --no-fatal-infos

# THE test. If a pixel moved, this fails.
flutter test
#   -> golden_test.dart passes with test/goldens/wb_modern_car_green.png unchanged
#   -> palestine_validators_test.dart, palestine_serial_generator_test.dart,
#      spec_validation_test.dart all still pass

git status --porcelain test/goldens/    # MUST be empty
ls test/failures/ 2>/dev/null           # MUST be empty or absent

grep -c 'static const PlateSpec' lib/src/west_bank_plates.dart   # 7 (was 9)
grep -rn 'legacyCarPublicTransport\|legacyCarGovernment' lib/ test/ example/
#   -> only the CHANGELOG mentions them

(cd example && flutter run -d linux --debug)
```

**Visual check:** in the example, select the legacy West Bank plate and cycle usage through
`private → publicTransport → government`. The plate must invert to white-on-green for public transport
and go red-on-white for government, with the `ف / P` block changing ink to match — the same three
appearances as before, now produced by `country:` + `theme:` rather than by three specs.

**Success:** 11 specs in `all`; the golden passes byte-identical; all four Palestine test files pass;
`legacyCountryForUsage` is the only usage→appearance route; the example renders all three legacy
appearances correctly.

## Dependencies

P3 (`PlateCanvas.country`). P2 if run first (the golden must be green going in either way).

## Line estimate

`west_bank_plates.dart` −46 · `palestine_country.dart` −8 docs · `golden_test.dart` ±0 · example +6 ·
docs +12. **Net ≈ −70 of production code.**
