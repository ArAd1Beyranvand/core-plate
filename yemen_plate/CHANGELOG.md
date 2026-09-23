## 0.3.0

**Breaking. A usage class no longer selects a spec.** It selects a country block
and a theme, and `core_plate` 0.6.0 takes both at render time. So the 55 specs
this package shipped — four northern car layouts and one motorcycle layout
crossed with five usages, six unified geometries crossed with five — are now
**11**, one per geometry, and 44 of them were clones that differed only in `id`
and `country`.

```dart
// Before
PlateCanvas(
  spec: YemenNorthernPlates.carGov2Serial5ForHire,
  theme: YemenThemes.forNorthernUsage(YemenUsage.forHire),
);

// After
PlateCanvas(
  spec: YemenNorthernPlates.carGov2Serial5,
  country: YemenCountry.northernFor(YemenUsage.forHire),   // the usage word
  theme: YemenThemes.forNorthernUsage(YemenUsage.forHire), // the field colour
);
```

Nothing about the drawn plate changes, provided the `country:` is passed. Drop
it and every plate reads خصوصي / PRIV., because each surviving spec keeps the
private block as its own default — a spec's `country` is a fallback, not a claim
about the vehicle.

### Removed

The 44 usage clones. Each line's shape survives under the name in the first
column; the removed names differ from it only in `id` and `country`.

| Kept | Removed |
| --- | --- |
| `YemenNorthernPlates.carGov2Serial5` | `carGov2Serial5Private`, `carGov2Serial5ForHire`, `carGov2Serial5Transport`, `carGov2Serial5Government`, `carGov2Serial5Military` |
| `YemenNorthernPlates.carGov1Serial5` | `carGov1Serial5Private`, `carGov1Serial5ForHire`, `carGov1Serial5Transport`, `carGov1Serial5Government`, `carGov1Serial5Military` |
| `YemenNorthernPlates.carGov2Serial4` | `carGov2Serial4Private`, `carGov2Serial4ForHire`, `carGov2Serial4Transport`, `carGov2Serial4Government`, `carGov2Serial4Military` |
| `YemenNorthernPlates.carGov2Serial6` | `carGov2Serial6Private`, `carGov2Serial6ForHire`, `carGov2Serial6Transport`, `carGov2Serial6Government`, `carGov2Serial6Military` |
| `YemenNorthernPlates.motoGov2Serial5` (still `@Deprecated`) | `motoGov2Serial5Private`, `motoGov2Serial5ForHire`, `motoGov2Serial5Transport`, `motoGov2Serial5Government`, `motoGov2Serial5Military` |
| `YemenUnifiedPlates.car4` | `car4Private`, `car4ForHire`, `car4Transport`, `car4Government`, `car4Police` |
| `YemenUnifiedPlates.car5` | `car5Private`, `car5ForHire`, `car5Transport`, `car5Government`, `car5Police` |
| `YemenUnifiedPlates.car6` | `car6Private`, `car6ForHire`, `car6Transport`, `car6Government`, `car6Police` |
| `YemenUnifiedPlates.moto4` | `moto4Private`, `moto4ForHire`, `moto4Transport`, `moto4Government`, `moto4Police` |
| `YemenUnifiedPlates.moto5` | `moto5Private`, `moto5ForHire`, `moto5Transport`, `moto5Government`, `moto5Police` |
| `YemenUnifiedPlates.moto6` | `moto6Private`, `moto6ForHire`, `moto6Transport`, `moto6Government`, `moto6Police` |

Also removed: the nested `YemenNorthernPlates.car` / `.moto` and
`YemenUnifiedPlates.car` / `.moto` maps keyed by usage. Those two names now
belong to the geometry lookups below, so a call site that indexed them by usage
fails to compile rather than silently changing meaning.

### Added

- `YemenNorthernPlates.car({governorateDigits, serialDigits})` and
  `.moto(...)`, returning a `PlateSpec?` — null for a shape this package does
  not build. Backed by `carGeometries` / `motoGeometries`, flat maps keyed by
  `(governorate digits, serial digits)`.
- `YemenUnifiedPlates.car({numberDigits})` and `.moto({numberDigits})`, backed
  by `carGeometries` / `motoGeometries` keyed by number length.
- Ids lost their usage segment: `ye.northern.car.g2s5.private` is now
  `ye.northern.car.g2s5`, `ye.unified.car5.police` is now `ye.unified.car5`.
  A spec id is a geometry's name.
- `test/yemen_specs_test.dart`, replacing `test/spec_validation_test.dart` and
  keeping its sweep: `debugValidateSpec` over all 11 specs, ids unique and free
  of any usage word, the group keys each validator reads, slot counts against
  the shape each map key claims, the northern registers' flush right edge, and
  1,000 seeded generator draws per spec round-tripped through the matching
  validator — which is what proves no group key or slot order moved when the
  clones went.

- `YemenNorthernPlates.byDigits(usage, {motorcycle})` and
  `YemenUnifiedPlates.byNumberLength(usage, {motorcycle})`. Briefly staged as
  deprecated shims during this release's development and removed before it
  shipped, so no published version ever carried them. Every usage a system
  issues yields the same geometries — the usage never varied the geometry — so
  the shims only wrapped `carGeometries` / `motoGeometries` behind a usage
  filter. Use `car()` / `moto()` and pass the usage to the canvas as `country:`.

### Fixed

- **`YemenNorthernPlates.carGov2Serial4` and its mirrors ended one unit past
  every sibling layout.** The four serial cells were hand-written at x 140, 238,
  **335**, 433 — pitches of 98, **97**, 98 — so the register ran to 531 where
  the five- and six-digit layouts both end at 530. They are now 140, **237.5**,
  335, **432.5**, width **97.5**, right edge 530. The third and fourth cells
  move by half a unit on a 540-wide canvas. The four `PlateMirror`s of the echo
  band moved with them; they are built from the same span, so they cannot
  disagree with the slots again.
- **`YemenNorthernPlates.motoGov2Serial5` was unevenly pitched.** The five
  serial cells sat at x 75, 117, 159, **200**, 242 — pitches of 42, 42, **41**,
  42 — and are now a uniform **41.8**: 75, 116.8, 158.6, 200.4, 242.2. The
  fourth cell moves by 0.4 unit. Its mirrors moved with it.
- Neither drift was catchable before: `debugValidateSpec` did not check register
  pitch, and this package had no tests at all.

### Changed

- **The hand-unrolled runs are gone.** `_carStipple` (24 `PlateRule`s) and
  `_motoStipple` (22) are two `plateStipple` calls; the unified car's three
  serial lengths are `plateRegisterAcross` over x [292, 832) and the
  motorcycle's three are `plateRegister` with an explicit pitch; the northern
  car's four serial lengths are `plateRegisterAcross` over x [140, 530) and its
  four echo bands are `plateEcho` over that same span. Every one of those was a
  for-loop written out by hand.
- The governorate cells, `_carGovSingle` (which straddles the pair's two cells),
  the labels, panels and dividers stay literal. They are not registers.
- Every `PlateSpec` in this package is now `static final` rather than
  `static const`, as are the `carGeometries` / `motoGeometries` lookup maps: a
  `const` constructor cannot run a loop. `PlateSpec` equality is over `id` alone
  and a `static final` is initialised lazily once per isolate, so this changes
  no behaviour.
- Requires `core_plate` 0.6.0 for `plateRegister` / `plateRegisterAcross` /
  `plateEcho` / `plateStipple`, and for `PlateCanvas.country` /
  `PlateView.country`.
- The package's first tests, now `test/yemen_specs_test.dart` — see **Added**
  above. The northern serial registers are asserted to end flush at the same
  right edge, which is the drift above stated as a test.

## 0.2.0

- The northern plate now prints its number twice, as the reference photograph
  shows: big iranian-Arabic numerals over a small Latin echo row. The big row is
  the slot itself, drawn over the new `YemenAlphabets.iranianDigits` /
  `iranianGovernorateTens`; the small row is a `PlateMirror` per slot, which is
  a read-only presentation of a value rather than a second value. Slot counts,
  text groups, focus order and the validators are unchanged.
- Storage stays ASCII throughout. The iranian alphabets accept `'0'..'9'` and
  differ from their Latin twins only in `glyphs`.
- Known limitation: the iranian numerals appear in `PlateMode.display`. In
  `PlateMode.input` the big row still shows ASCII under the caret — core's
  typed field paints the controller's text without rendering it through the
  alphabet (core's `TODO(national-numerals)`).
- Requires `core_plate: ^0.2.0` for `PlateMirror`.

## 0.1.0

First release.

- Contains Yemen's plate data for `core_plate`: `YemenUsage`,
  `YemenGovernorate`, `YemenColors`, `YemenAlphabets`, `YemenCountry`,
  `YemenThemes`, `YemenUnifiedPlates`, `YemenNorthernPlates`, the two
  validators and the two seeded generators. Depends on `core_plate: ^0.1.0` and
  nothing else.

- **Two systems, both current, in two namespaces.** `YemenUnifiedPlates` is the
  2026 unified white plate the internationally recognised government issues;
  `YemenNorthernPlates` is the 1993 format still in force across the
  Houthi-controlled north and still the larger share of the fleet. Neither is
  the legacy half of a pair, so there is no `YemenSystem` enum and no version
  flag selecting between them at runtime.

- 55 `const PlateSpec`s: 30 unified (car and motorcycle x four, five or six
  number digits x five usages) and 25 northern (four register-length
  combinations x five usages, plus five motorcycle layouts).

- Ships a `PlateTheme` per northern usage, because on System B the field colour
  *is* the usage class - blue private, yellow for hire, red transport, green
  government, black military. System A gets exactly one theme, because it does
  not colour-code by usage at all.

- Every dimension and every colour is marked `// CALIBRATE`. They are
  proportioned from photographs and published descriptions, not measured from a
  standard.

- The five northern motorcycle specs are `@Deprecated('unverified geometry -
  calibrate against photographs')`. No official motorcycle design has been
  published for either system; the unified motorcycle specs carry the same
  warning in prose.

- `YemenGovernorate.underHouthiControl` is exposed and never enforced. No
  validator consults it and no lookup filters on it.

- The System A side code is checked for shape and nothing else: no source pins
  down how its two digits split into a governorate and a year.

- Ships no assets. A Yemeni plate carries no flag, and the unified plate's eagle
  emblem was not available at a resolution worth shipping. Ships no font either,
  and a host cannot supply one - see "Fonts" in the README for the `core_plate`
  limitation behind that.
