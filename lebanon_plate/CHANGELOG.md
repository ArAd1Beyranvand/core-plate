## 0.1.0

First release.

- **Two geometries.** `LebanonPlates.oneLine` (1040 x 220, band down the left
  edge) and `LebanonPlates.twoLine` (520 x 288, band across the top). Both are
  six-digit plates; `oneLineOf(digits:)` and `twoLineOf(digits:)` build the same
  faces with one to six digit cells, keeping the six-digit pitch so a short
  number stays left-aligned against the letter rather than being respaced.

- **Eight themes, one per usage class.** `LebanonThemes.forUsage` — white
  private, purple consular, orange diplomatic, red public institutions, yellow
  driving school, green transit, brown temporary, pink tourism. Lebanon
  colour-codes the field and not the band, so `LebanonCountry` is one blue band
  whose only per-usage variation is the Arabic word it captions.

- **Two enums, deliberately not one.** `LebanonUsage` is the field colour;
  `LebanonLetter` is the seventeen plate letters, their towns (B Beirut, T
  Tripoli, S Sidon, Z Zahleh, …) and their classes. They cross rather than
  nest: `M` is both a red public-institution plate and a yellow driving-school
  one.

- **`LebanonValidator`.** Advisory, gated on the `serial` group, and honest
  about how little Lebanon's grammar gives it: a closed letter set, a one-to-six
  digit number, and the one documented range in the system — a parliament `MP`
  plate is numbered 1..128. It does not reject the out-of-service `K` letter or
  a leading zero.

- **`LebanonSerialGenerator`.** Spec-driven, seedable, and constrained to what
  the validator accepts, including the `MP` range.

- Goldens for both geometries and three colour classes, including the
  one-spec-two-usages pair that pins the country/theme split.

### Known gaps

- **No cedar.** The emblem in the middle of the band is not shipped; see "What
  it does not ship" in the README.
- **The band's text runs horizontally.** On a real one-line plate it is rotated
  ninety degrees, and `plate_core` has no rotation.
- **Most coloured classes have no attested Arabic word**, so their band carries
  لبنان alone rather than a word this package invented.
