## Unreleased

- **Gaza car plates: vertical flag only.** Removed `PSGazaPlates.car2021`, the
  one-line design with the flag the right way up and a watermark — a Gaza car
  plate now only ever renders as `car2012`, with the flag turned a quarter
  turn. The two-line wraps (`car2012TwoLine`, `car2021TwoLine`) are unaffected:
  a landscape band cannot hold a vertical strip, so both already carried the
  horizontal flag and still do.
- **New: `PSGazaPlates.moto`.** A one-line Gaza motorcycle plate, carrying the
  horizontal flag and watermark that `car2021` used to.

## 0.1.0

First release.

- Contains Palestine's plate data as `const`s for `core_plate: ^0.1.0`, and
  depends on nothing else. No widget, no painter, no bloc: `PlateCanvas` and
  `ShowPlate` render every spec here.

- **Two designs, not one.** `PSWestBankPlates` (nine specs: modern and legacy
  car, the public-transport and government colour variants, both two-line wraps,
  two motorcycle form factors and the trade plate) and `PSGazaPlates` (four:
  the 2012 and 2021 treatments, each with a two-line wrap). Gaza left the
  Palestinian Authority's numbering in 2012, carries a flag where the West Bank
  carries `ف / P`, and never inverts its white field.

- **Colour is derived from usage, never chosen.** `PSThemes.forUsage` and
  `PSThemes.forGazaUsageCode` do the lookup over `PSUsage`, `PSLegacyUsage` and
  `PSGazaUsage`. `PlateSpec` carries no theme field, so the host passes
  `theme:` or wraps the canvas in a `PlateThemeScope`. `forGazaUsageCode`
  returns null for an unallocated code rather than a fallback theme.

- **One `PlateCountry` per ink colour**, all with `code: 'ps'` so they compare
  equal. `PlateCountry` carries colours and `PlateSpec` carries a country, so a
  country const is pinned to one scheme; leaving `panelColor` transparent
  collapses six schemes into three consts plus the inline variant the two-line
  motorcycle plate needs.

- Three advisory validators — `PSWestBankModernValidator`,
  `PSWestBankLegacyValidator`, `PSGazaValidator` — one per scheme rather than
  one that sniffs which scheme it is looking at. Each is `const`, never throws,
  never bars a keystroke, stays quiet until the user reaches the group being
  judged, and exposes a static spec-free `validateFields`. Named failures are
  `static const String` reason constants: the `I`/`O` gap, the `P`–`T` letters
  allocated to Gaza and never issued, the illegal legacy districts `0` and `2`,
  the unallocated Gaza usage classes, and a Gaza prefix other than `3`.

- `PSSerialGenerator` produces reproducible synthetic serials from a seeded
  `Random`, drawing only from the legal sets its matching validator accepts.

- Owns `assets/flags/Flag_of_Palestine.svg`, a pre-rotated vertical twin for the
  2012 Gaza plate, and `assets/marks/palestine_watermark.png`. Each is declared
  in this package's `pubspec.yaml` in the same commit as the literal that names
  it, so there is no revision in which an asset reference points at a bundle
  that does not declare the file.

- **Nearly all geometry and colour is provisional.** Only `PSColors.green`
  (`0xFF3C875D`), `borderWidthRatio: 0.027` and `plateRadiusRatio: 0.10` come
  from a photograph — `palestine_plate/pics/reference_plate.png`. Everything
  else is marked `// CALIBRATE` on the line. Goldens cover every spec × theme so
  a retune is a visible diff.

- Supersedes `palestine_plate`, which covered one green-on-white car spec and
  the `ف / P` block. Its measured geometry, sampled green and validator
  reasoning carry over. `palestine_plate` is untouched on disk.

### Known `core_plate` limitations

None of these were worked around by editing `core_plate`:

- `PlateDecal` takes an `ImageProvider`, not a `PlateAsset`, and paints at full
  opacity — so the Gaza watermark ships as a pre-faded PNG rather than an SVG.
- No rotation hook, so the 2012 Gaza flag ships pre-rotated as a second asset.
- `CountryPanel` lays `captionLines` out as a `Column` only, so the two-line
  motorcycle plate puts `ف` and `P` in one string to set them side by side.
