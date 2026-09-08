## Unreleased

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
  `static const`, as are the `car` / `moto` lookup maps: a `const` constructor
  cannot run a loop. `PlateSpec` equality is over `id` alone and a
  `static final` is initialised lazily once per isolate, so this changes no
  behaviour.
- Requires `core_plate: ^0.6.0` for `plateRegister` / `plateRegisterAcross` /
  `plateEcho` / `plateStipple`.

### Added

- `test/spec_validation_test.dart` — the package's first tests. Every one of the
  55 specs is run through `debugValidateSpec`, spec ids are checked unique, and
  the northern serial registers are asserted to end flush at the same right
  edge, which is the drift above stated as a test.

## 0.2.0

- The northern plate now prints its number twice, as the reference photograph
  shows: big eastern-Arabic numerals over a small Latin echo row. The big row is
  the slot itself, drawn over the new `YemenAlphabets.easternDigits` /
  `easternGovernorateTens`; the small row is a `PlateMirror` per slot, which is
  a read-only presentation of a value rather than a second value. Slot counts,
  text groups, focus order and the validators are unchanged.
- Storage stays ASCII throughout. The eastern alphabets accept `'0'..'9'` and
  differ from their Latin twins only in `glyphs`.
- Known limitation: the eastern numerals appear in `PlateMode.display`. In
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
