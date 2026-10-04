## 0.3.0

- **Breaking: removed the `@Deprecated` `PSWestBankPlates.legacyCarForUsage`
  shim.** 0.2.0 kept it for one release; this is that release. It returned
  `legacyCar` for every usage. Pass `legacyCountryForUsage(usage)` to
  `PlateCanvas.country` alongside `legacyCar` instead.

- **Breaking: `PSSerialGenerator` is spec-driven.** `modernWestBank`,
  `legacyWestBank` and `gaza` now take a `PlateSpec` and an optional
  `random:`, matching `yemen_plate`'s generator shape. Each register's
  characters are written at the slot indices the spec's own `region` /
  `serial` / `governorate` / `district` / `prefix` / `usage` text groups
  name, via `PlateSpec.indicesOfGroup`, instead of into a fixed positional
  list. A spec whose serial sits elsewhere (e.g. a bottom-row-first two-line
  layout) now generates correctly; before it silently produced a wrong plate.
  Handed a spec with no matching groups, the generator throws `ArgumentError`.
  Seeded output is byte-identical to 0.2.0 for every existing spec: the draw
  order (and the legal value sets) are unchanged.

## 0.2.0

- **Breaking: the legacy West Bank ink is a render-time value, not three specs.**
  Removed `PSWestBankPlates.legacyCarPublicTransport` and
  `PSWestBankPlates.legacyCarGovernment` — geometry clones of `legacyCar` that
  differed only in the `ف / P` block ink. Removed the `legacyCarForUsage`
  lookup (kept for one release as a `@Deprecated` shim that returns `legacyCar`
  regardless of usage). Use `legacyCar` with
  `PSWestBankPlates.legacyCountryForUsage(usage)` handed to `PlateCanvas.country`,
  beside `PSThemes.forUsage(usage)`. `PSWestBankPlates.all` and
  the gallery now hold 11 specs, not 13. The three ink consts
  (`PSCountries.westBankGreenInk` / `.westBankWhiteInk` / `.westBankRedInk`)
  stay — they are exactly what a host now passes to `country:`. Goldens
  unchanged.
- **Fixed: `PSWestBankPlates.modernMoto`'s serial was unevenly pitched.** Its
  four digits were hand-written at x 60.5, 92, 124, 156 — pitches of **31.5**,
  32, 32 — and are now a uniform 32 from x 60: 60, 92, 124, 156. The first cell
  moves half a unit on a 250-wide canvas, and the header band's `·` centres it
  documents are correspondingly 27.5, **75**, 107, 139, 171, 220. The golden
  `wb_modern_moto_green.png` was regenerated for this and is the only golden
  that changed; every other one is byte-identical. Nothing but pitch was
  touched.
- **The serial runs are registers, not rectangles.** `_modernCarSlots`,
  `_legacyCarSlots`, `modernMoto` and Gaza's `_sevenCellSlots`, `_motoSlots` and
  `_twoLineSlots` build their four-cell serials with `plateRegister` (core
  0.6.0) rather than four `PlateBox` literals apiece. The isolated region,
  district and governorate cells and the trailing usage pairs stay literal —
  they sit in the gaps the `·` labels occupy and are not part of any register.
  No coordinate changed except the drift above.
- Every `PlateSpec` in this package is now `static final` rather than
  `static const`, as are the `all` lists: a `const` constructor cannot run a
  loop. `PlateSpec` equality is over `id` alone and a `static final` is
  initialised lazily once per isolate, so this changes no behaviour — but a
  const-context use (`const spec = …`) must become `final spec = …`, as the
  examples and validator tests now do.
- Requires `plate_core: ^0.6.0` for `plateRegister`.
- **Gaza car plates: vertical flag only.** Removed `PSGazaPlates.car2021`, the
  one-line design with the flag the right way up and a watermark — a Gaza car
  plate now only ever renders as `car2012`, with the flag turned a quarter
  turn. The two-line wraps (`car2012TwoLine`, `car2021TwoLine`) are unaffected:
  a landscape band cannot hold a vertical strip, so both already carried the
  horizontal flag and still do.
- **New: `PSGazaPlates.moto`.** A one-line Gaza motorcycle plate, carrying the
  horizontal flag and watermark that `car2021` used to.
- **`PSWestBankPlates.modernMoto` rebuilt from a reference image.** It was
  `modernCar` rescaled onto a 200 x 100 canvas, guessed throughout. It is now
  measured off
  `pics/License_Plate_-_Palestine_-_Motorcycle_-_2018_-_1-Line_Design.png`, on
  that image's own 250 x 123 canvas, and the layout is materially different:
  the serial runs the full width of the plate, and `P` and `ف` sit side by side
  in a centred header band above it — `P` on the **left** — separated by a
  short vertical divider, where the old spec stacked `ف` over `P` in a strip on
  the right. This is a visual breaking change for anyone rendering it.
- **New: `PSCountries.westBankGreenInkBlank`.** A West Bank country that draws
  no caption and no flag, so `modernMoto` can print `P`, `ف` and the divider as
  measured plate-space geometry instead of going through `CountryPanel`'s
  vertical-only caption column.

## 0.1.0

First release.

- Contains Palestine's plate data as `const`s for `plate_core: ^0.1.0`, and
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

### Known `plate_core` limitations

None of these were worked around by editing `plate_core`:

- `PlateDecal` takes an `ImageProvider`, not a `PlateAsset`, and paints at full
  opacity — so the Gaza watermark ships as a pre-faded PNG rather than an SVG.
- No rotation hook, so the 2012 Gaza flag ships pre-rotated as a second asset.
- `CountryPanel` lays `captionLines` out as a `Column` only, so the two-line
  motorcycle plate puts `ف` and `P` in one string to set them side by side.
