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
