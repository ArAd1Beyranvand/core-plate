# Prompt — build `palestine_plate`

You are working in the `plate` monorepo (`~/StudioProjects/plate`), which already
contains `core_plate`, `plate_keypad`, `iran_plate`, `germany_plate` and a small
first-pass `palestine_plate`.

Build a new Flutter package **`palestine_plate`**: Palestine's licence plates
expressed as **data for `core_plate`**.

---

## 0. Read this first — it overrides every instinct you have

`core_plate` is a country-neutral plate engine. It already owns every widget,
every painter, the input state machine, the bloc and the theming. A country
package contributes **`const` data and nothing else**.

So, before writing a line:

1. Read `core_plate/lib/core_plate.dart` — its doc comment *is* the contract.
2. Read `core_plate/lib/src/model/plate_spec.dart`, `plate_alphabet.dart`,
   `plate_country.dart`, `plate_asset.dart`, `plate_box.dart`,
   `theme/plate_theme.dart`, `validators/plate_validator.dart`.
3. Read `iran_plate/` end to end. It is the reference implementation for what a
   country package looks like.
4. Read the existing `palestine_plate/` package. It is prior art covering a
   **subset** of this brief (one green-on-white car plate, the `ف / P` block,
   the two trailing endings). Reuse its measured geometry, its sampled green and
   its validator reasoning where they apply. `palestine_plate` supersedes it —
   at the end, say so in the README and leave `palestine_plate` untouched on
   disk; deleting it is the user's call, not yours.

### Hard rules

- **No `CustomPainter`. No `StatefulWidget`. No new widget of any kind.**
  If you feel you need one, you have mis-modelled the plate. `PlateCanvas` and
  `ShowPlate` from `core_plate` render every plate in this package.
- **No BLoC, no state management, no controllers.** `core_plate` owns the bloc.
- A plate design is a `const PlateSpec`. **Adding a plate means adding a const.**
- Geometry lives in *plate space*: `PlateSpec.canvasWidth` × `canvasHeight` with
  the origin at the top-left, expressed as `PlateBox(left, top, width, height)`.
  Millimetres are a fine unit for the canvas — set `canvasWidth: 520`,
  `canvasHeight: 110` and every box in mm and the numbers *are* millimetres.
  Do **not** write an `mmToPx` helper; `PlateCanvas` scales the whole canvas.
- Colour is a `PlateTheme`, never baked into a spec. `PlateSpec` has no theme
  field and that is deliberate — the host passes `theme:` or wraps the canvas in
  a `PlateThemeScope`.
- Validation is a `PlateValidator` returning `PlateValidation`. It **never**
  throws and **never** bars a keystroke. There is no sealed result type to
  invent: `PlateValidation.valid()` / `.invalid(reason)` is the type.
- **Dependencies: `core_plate` only.** Not `plate_keypad`, not `iran_plate`, not
  `germany_plate`. `plate_keypad` may appear **only** in `example/pubspec.yaml`.
- Not one file in `lib/` may name another country.

### Translation table (old brief → `core_plate`)

| The old brief said | You write |
|---|---|
| `abstract PalestinePlate` + subclasses | nothing — plates are `const PlateSpec` values |
| `PSWestBankPlate`, `PSGazaPlate` | two `abstract final class` namespaces of spec consts |
| one `CustomPainter` per template | nothing |
| `PSFormFactor` enum → different geometry | one `PlateSpec` const per form factor |
| colour derived from usage | one `PlateTheme` const per colour scheme + a `PSUsage → PlateTheme` lookup |
| `ps_metrics.dart` of `// CALIBRATE` consts | the numbers live inline in each spec, with the `// CALIBRATE` comment on the line |
| `ps_colors.dart` | `palestine_plate/lib/src/palestine_colors.dart` — still one file, still all `// CALIBRATE` |
| sealed validation result | `PlateValidation` + `static const` reason strings |
| `PalestinePlateWidget` | `PlateCanvas` / `ShowPlate` from `core_plate` |
| hand-drawn flag `Path` | an SVG asset this package ships, referenced by `SvgPlateAsset` |

---

## 1. File layout

```
palestine_plate/
  lib/
    palestine_plate.dart              # the only public surface; exports src/*
    src/
      palestine_colors.dart           # every colour, all // CALIBRATE
      palestine_themes.dart           # PlateTheme per colour scheme + usage lookup
      palestine_country.dart          # PlateCountry for West Bank and for Gaza
      palestine_alphabets.dart        # every PlateAlphabet
      palestine_governorates.dart     # PSGovernorate enum (letter, ar/en names)
      palestine_usage.dart            # PSUsage enum + legacy/Gaza usage-code maps
      west_bank_plates.dart           # PSWestBankPlates.* specs
      gaza_plates.dart                # PSGazaPlates.* specs
      palestine_validators.dart       # PSWestBankValidator, PSGazaValidator
      palestine_serial_generator.dart # synthetic-serial generator
  assets/
    flags/Flag_of_Palestine.svg
    marks/palestine_watermark.svg     # pre-faded; see §7
  example/
    lib/main.dart
    pubspec.yaml                      # depends on palestine_plate + plate_keypad
  test/
    ...
  pubspec.yaml
  CHANGELOG.md
  README.md
  LICENSE
  analysis_options.yaml
```

Copy `analysis_options.yaml` and `LICENSE` from `iran_plate` verbatim.

`pubspec.yaml`:

```yaml
name: palestine_plate
description: "Palestine's licence plates for the core_plate library — the West Bank and Gaza specs, the alphabets, the usage themes and the advisory validators."
version: 0.1.0
homepage: https://github.com/ArAd1Beyranvand/plate-palestine

environment:
  sdk: '>=3.10.0 <4.0.0'
  flutter: ">=1.17.0"

dependencies:
  flutter:
    sdk: flutter
  core_plate: ^0.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  assets:
    - assets/flags/Flag_of_Palestine.svg
    - assets/marks/palestine_watermark.svg
```

> The `package:` field of every `SvgPlateAsset` you write must be
> `'palestine_plate'`, and the path must appear in the block above. An asset
> reference resolves against the bundle of the package that *declares* it, so
> the literal and the pubspec entry move together or the flag works locally and
> breaks for a fresh consumer. `iran_plate` has this comment; keep it.

---

## 2. Domain — the West Bank plate

Two serial schemes share one visual template. Detect the scheme from the third
group.

### Scheme MODERN (issued since July 2018) — `D · DDDD · L`

- group 1: exactly 1 digit
- group 2: exactly 4 digits (serial, runs sequentially)
- group 3: exactly 1 Latin uppercase letter = governorate code
- 6 characters total

Governorate letters — a **closed** set:

| Letter | Governorate |
|---|---|
| A | Jenin |
| B | Tulkarm |
| C | Tubas |
| D | Nablus |
| E | Qalqilya |
| F | Salfit |
| G | Jericho |
| H | Ramallah |
| J | Jerusalem |
| K | Bethlehem |
| L | Hebron |
| M | Dura |
| N | Yatta |

**There is no `I` and no `O`.** The sequence jumps H → J. Never emit them; in
an OCR confusion matrix treat `I → 1 / J` and `O → 0` as guaranteed misreads.
Document that in the `PSGovernorate` doc comment.

`P, Q, R, S, T` were allocated to Gaza governorates and never issued — Gaza went
its own way in 2012. Expose them as
`PSGovernorate.reservedGazaLetters` (a `List<String>`) and **reject** them in
the validator.

### Scheme LEGACY (1994 – July 2018, still very common) — `D · DDDD · DD`

- group 1: 1 digit, district code
- group 2: any 4 digits
- group 3: exactly 2 digits, usage class
- 7 digits, no letters

District codes (legacy only) — `0` and `2` are **invalid**:

| Code | District |
|---|---|
| 1 | Gaza Strip, registered before 1995 |
| 3 | Gaza Strip, registered after 1995 |
| 4 | Northern West Bank, before 1995 |
| 7 | Northern West Bank, after 1995 |
| 5 | Central West Bank, before 1995 |
| 6 | Central West Bank, after 1995 |
| 8 | Southern West Bank (Bethlehem, Hebron), before 1995 |
| 9 | Southern West Bank (Bethlehem, Hebron), after 1995 |

Usage codes (legacy only) — **this is what drives colour**:

| Code | Usage |
|---|---|
| 40–49 | private |
| 90–98 | private |
| 99 | Palestinian Authority government vehicle |
| 30 | public transport (taxi, service, bus) |
| 31 | duty-exempt (ambulance, fire, civil defence) |
| 32 | leased vehicle |
| anything else | invalid |

The modern scheme encodes no usage. A host supplies `PSUsage` separately,
defaulting to `PSUsage.private`.

---

## 3. Domain — the Gaza plate

Gaza broke away from the PA numbering in 2012 and has run its own design since.
There is **no `ف / P` block** — a Palestinian flag takes that space.

Grammar, single scheme — `3 · DDDD · DD`:

- group 1: **always the literal digit `3`**, hard-coded, not variable. It is
  inherited from the pre-2012 PA system and deliberately retained.
- group 2: any 4 digits
- group 3: exactly 2 digits, usage class

Gaza usage codes — these drive **glyph colour only**:

| Code | Usage | Glyphs |
|---|---|---|
| 00–09 | private | black |
| 10–19 | commercial / truck | green |
| 20–29 | public transport / taxi | blue |
| 40–49 | municipality | blue |
| 50–59 | government (police, MoH ambulance) | red |
| 30–39, 60–99 | invalid | — |

**The Gaza background is always white.** Only glyph and border colour change.
Do not invert the plate for public transport the way the West Bank does.

Two graphic treatments, same grammar (`PSGazaStyle`):

- **`style2012`** (2012–2021): a **vertical** Palestinian flag on the right,
  full plate height, ~55 mm wide (the flag rotated so its triangle points
  down). Plain white field, no watermark.
- **`style2021`** (2021 onward): a **horizontal** Palestinian flag instead, and
  a watermark behind the digits — "فلسطين" and "Palestine" at roughly 12%
  opacity in light grey. Digits draw on top at full opacity.

---

## 4. Alphabets

Declare every alphabet under a `ps.` id prefix in `palestine_alphabets.dart`,
even where the characters match `PlateAlphabet.latinDigits`. Reason (state it in
the class doc, the way `palestine_plate` does): `debugValidateSpec` requires that
one id never stand for two character lists within a spec, and these alphabets
have superset relationships, so naming them all in one file keeps the
relationship visible instead of half-inherited from core.

| Const | id | characters | `input` | notes |
|---|---|---|---|---|
| `digits` | `ps.digits` | `0`–`9` | `typed` | `isNumeric: true` |
| `districtDigits` | `ps.districtDigits` | `1,3,4,5,6,7,8,9` | `typed` | legacy group 1; `0`/`2` are not legal characters, so they are not in the alphabet |
| `governorateLetters` | `ps.governorateLetters` | `A B C D E F G H J K L M N` | **`chosen`** | no `I`, no `O`; `chosen` so `plate_keypad`'s `PlateCharacterPicker` offers exactly the legal set |
| `gazaPrefix` | `ps.gazaPrefix` | `['3']` | `typed` | a one-character alphabet: the literal is enforced by the alphabet, not by the validator |
| `usageDigits` | `ps.usageDigits` | `0`–`9` | `typed` | *distinct id from `digits` only if the character list differs; if it does not, reuse `digits`* — do not create an id whose characters duplicate another id in the same spec, `debugValidateSpec` asserts on that |

Read that last row carefully and obey it: **two distinct ids sharing one
character list is an assertion failure**, and so is one id appearing with two
different lists. Only mint a new id when the characters genuinely differ.

Every alphabet is LTR here (`direction` stays at its default) — Palestinian
plates are printed in Latin digits and Latin capitals.

---

## 5. Countries

`palestine_country.dart` exposes two `PlateCountry` consts.

```dart
/// The West Bank block: no coloured panel and no flag — just `ف` over `P`
/// printed in the plate's own ink, in the strip right of the vertical rule.
static const PlateCountry westBank = PlateCountry(
  code: 'ps',
  captionLines: ['ف', 'P'],
  panelColor: /* the plate background for the active usage */,
  panelTextColor: /* the ink for the active usage */,
  flag: null,
);
```

Two things to carry over from `palestine_plate` and keep:

- `CountryPanel` paints a flag and a caption and nothing else, so the short
  horizontal rule between `ف` and `P` is a `PlateRule` on the spec, drawn over
  the block — not part of `PlateCountry`.
- `P` is Portugal's code, used unofficially because Palestine has no assigned
  one. It is a literal glyph, never a country-code lookup. Say so in the doc
  comment.

**`PlateCountry` carries colours and `PlateSpec` carries a country, so a country
const is tied to one colour scheme.** That collides with usage-driven colour.
Resolve it this way and document the choice:

- Declare **one `PlateCountry` per colour scheme**: `westBankOnWhite`,
  `westBankInverted`, `westBankRed`, `westBankTrade`, `gaza…` etc., each with
  `code: 'ps'` so they compare equal (equality is over `code`).
- Each `PlateSpec` names the country matching its scheme, and the matching
  `PlateTheme` from §6 is passed by the host.

Gaza's country const carries the flag:

```dart
static const PlateCountry gaza = PlateCountry(
  code: 'ps',
  captionLines: [],                  // the flag is the whole block
  flagAspectRatio: 2 / 1,            // official Palestinian ratio
  flag: SvgPlateAsset('assets/flags/Flag_of_Palestine.svg',
                      package: 'palestine_plate'),
  ...
);
```

Ship the flag as an **SVG asset**, not a drawn `Path`: `core_plate` renders
`PlateAsset` through `flutter_svg` and has no path-drawing hook. Author the SVG
to the official geometry — three equal horizontal bands black / white / green
top to bottom, a red isosceles triangle on the hoist side whose apex reaches ⅓
of the width, ratio 2:1 — and for `style2012` ship a **second, pre-rotated**
SVG (`Flag_of_Palestine_vertical.svg`, triangle pointing down) rather than
trying to rotate at render time; there is no rotation hook either.

---

## 6. Colours and themes

`palestine_colors.dart` — every value carries `// CALIBRATE`, because no
official hex is published:

```dart
static const Color green = Color(0xFF0F6B3C); // CALIBRATE
static const Color red   = Color(0xFFC8102E); // CALIBRATE
static const Color blue  = Color(0xFF1B4F9C); // CALIBRATE
static const Color white = Color(0xFFFFFFFF);
static const Color black = Color(0xFF000000);
```

Reconcile `green` against `palestine_plate`'s `plateGreen` = `0xFF3C875D`, which
was sampled off `palestine_plate/pics/reference_plate.png`. Pick one, and leave
a comment saying which source won and why.

`palestine_themes.dart` — a `PlateTheme` per scheme plus the lookup:

| `PSUsage` | foreground | background | theme const |
|---|---|---|---|
| `private` | green | white | `PSThemes.greenOnWhite` |
| `leased` (legacy 32) | green | white | `PSThemes.greenOnWhite` |
| `publicTransport` (legacy 30) | white | **green** | `PSThemes.whiteOnGreen` |
| `government` (legacy 99) | red | white | `PSThemes.redOnWhite` |
| `exempt` (legacy 31) | red | white | `PSThemes.redOnWhite` |
| `police` (modern) | green | white | `PSThemes.greenOnWhite` |
| `tradePlate` / test | white | **blue** | `PSThemes.whiteOnBlue` |

```dart
/// The theme a plate of this usage is printed in. Colour is *derived* from
/// usage — a host never picks a theme directly.
static PlateTheme forUsage(PSUsage usage) => switch (usage) { ... };
```

Gaza is different: background always white, so declare
`PSThemes.gazaBlack / gazaGreen / gazaBlue / gazaRed`, each
`plateBackground: white` with `ink`, `plateBorder` and `dividerColor` set to the
usage colour, and `PSThemes.forGazaUsageCode(String code)` doing the lookup.

Base every theme on `PlateTheme.standard()`'s ratios unless a reference photo
says otherwise; `palestine_plate` measured `borderWidthRatio: 0.027` and
`plateRadiusRatio: 0.10` off its reference and those are the best numbers we
have. Carry the border ratio on the spec too, via
`borderWidthRatioOverride`, so the geometry survives a host that supplies its
own theme.

---

## 7. Specs

Every dimension below is in **millimetres on the canvas**, and every one of them
is a `// CALIBRATE` unless it comes from a measured reference image. If a
reference photo exists in `pics/`, measure off it and say so in the comment; if
not, say the number is provisional.

### `PSWestBankPlates`

Shared layout for the 520 × 110 single-line plate:

- `0 … 458` — **main field**. The serial, horizontally centred, drawn as three
  slot groups separated by a hyphen-width gap. **Do not draw a literal hyphen**;
  leave whitespace of about 0.6 × glyph width between groups. Cap height ≈ 78.
  (`palestine_plate` instead prints a raised `·` as a `PlateLabel` between
  groups — that is a departure worth keeping only if a reference photo supports
  it. If you keep it, note it; if not, use the gap.) Vertically centre the band.
- `458 … 462` — **vertical separator**, a full-height `PlateRule` ~2 wide in the
  foreground colour.
- `462 … 520` — **identity strip**: `PlatePanel` with `flagScale: 0` (no flag —
  do not reserve a strip for a null image) and a `captionScale` that makes the
  two caption lines fill the block. Plus the short horizontal `PlateRule`
  between `ف` and `P`, at the y where the two caption lines meet.
- **Outer border**: rounded rect, 3 stroke, foreground colour, corner radius ≈ 8
  — expressed as ratios on the theme, not as spec geometry.

Consts to declare:

| Const | id | canvas | notes |
|---|---|---|---|
| `modernCar` | `ps.wb.modern.car` | 520 × 110 | 6 slots: `digits`, `digits`×4, `governorateLetters` |
| `legacyCar` | `ps.wb.legacy.car` | 520 × 110 | 7 slots: `districtDigits`, `digits`×4, `digits`×2 |
| `modernCarTwoLine` | `ps.wb.modern.car2l` | 300 × 150 | for imported vehicles whose bumper cannot fit a one-line plate. Groups 1+2 on line 1, group 3 on line 2. Identity strip stays on the right, full height |
| `legacyCarTwoLine` | `ps.wb.legacy.car2l` | 300 × 150 | same wrap |
| `modernMoto` | `ps.wb.modern.moto` | 200 × 100 | `modernCar` rescaled |
| `modernMotoTwoLine` | `ps.wb.modern.moto2l` | 165 × 165 | near-square. Serial wraps as two-line. **The identity strip moves to a full-width bottom band**, `ف` and `P` side by side — so `captionLines` still has two entries but the panel is wide and short. `// CALIBRATE` the placement |
| `modernTrade` | `ps.wb.modern.trade` | 520 × 110 | see below |

Motorcycles use the identical serial grammar and are legally private vehicles.
Say that in the doc comment; do not model a separate usage for them.

**Trade / test variant** (dealer and inspection plates): blue field, white text,
plus a **header row** above the serial split left/right — `اختبار` on the left,
`במבחן` on the right. The serial takes the lower ~65% of the plate height. The
identity strip is retained.

In `core_plate` terms the header row is **two `PlateLabel`s**, not a widget.
`PlateLabel` has no `TextDirection` field — `core_plate` lays labels out as
given — so an Arabic or Hebrew label is a single isolated run of its own and
will render correctly on its own; do not concatenate the two into one label
string, or the bidi algorithm will reorder them against each other. Two labels,
two boxes. Write that reason into the comment.

Name it `PSWestBankPlates.modernTrade` (a const), not a named constructor —
there are no constructors here, only consts.

### `PSGazaPlates`

| Const | id | canvas | notes |
|---|---|---|---|
| `car2012` | `ps.gz.2012.car` | 520 × 110 | vertical flag on the right, ~55 wide, full height; plain white field |
| `car2021` | `ps.gz.2021.car` | 520 × 110 | horizontal flag right; watermark decal behind the digits |
| `car2012TwoLine` | `ps.gz.2012.car2l` | 300 × 150 | flag becomes a **full-width top band**, horizontal |
| `car2021TwoLine` | `ps.gz.2021.car2l` | 300 × 150 | same, plus the watermark |

7 slots each: `gazaPrefix`, `digits` × 4, `digits` × 2.

**Do not implement Gaza motorcycle plates.** Motorcycles in Gaza are rarely
fitted with plates at all; a moto const would be dead code. Put that sentence in
the class doc so the next person does not add one.

**The watermark.** `PlateDecal` takes an `ImageProvider` and paints it at full
opacity into its box; `core_plate` has no opacity parameter. So do not try to
fade at render time — ship a **pre-faded** asset (`palestine_watermark.svg`,
authored at ~12% grey) and reference it with a `PlateDecal`. `PlateDecal` wants
an `ImageProvider`, so either ship the watermark as a PNG via `AssetImage(...,
package: 'palestine_plate')`, or — if you want the vector — note in the comment
that `PlateDecal` cannot take an `SvgPlateAsset` today and that closing that gap
is a `core_plate` change, not a `palestine_plate` one. **Do not patch
`core_plate` to make this work without saying so loudly in your final report.**

Draw order matters: decals paint under slots in `PlateCanvas`. Verify that
against `core_plate/lib/src/widgets/plate_canvas.dart` before you rely on it,
and if it is the other way round, say so rather than working around it.

### `textGroups`

Every spec declares keyed groups so the validators read by name, not position:

- West Bank modern: `region` `[0]`, `serial` `[1,2,3,4]`, `governorate` `[5]`
- West Bank legacy: `district` `[0]`, `serial` `[1,2,3,4]`, `usage` `[5,6]`
- Gaza: `prefix` `[0]`, `serial` `[1,2,3,4]`, `usage` `[5,6]`

---

## 8. Validators

`palestine_validators.dart` — two `PlateValidator` subclasses. Both are `const`,
both never throw, both stay **quiet** (`PlateValidation.valid()`) until the user
has actually reached the group being judged, the same rule
`PalestinePlateValidator` and `GermanPlateValidator` already follow: with
nothing barring input, the red state is the only feedback there is, and a plate
that flashes red at its first keystroke is worse than no validation at all.

`PlateValidation` carries a single `reason` string, so the "named failure
reasons" from the old brief become **`static const String` reason constants** on
the validator, referenced by the tests:

```dart
static const String invalidGroupCount   = '...';
static const String illegalLetterIO     = 'The letters I and O are never issued; H is followed by J.';
static const String reservedGazaLetter  = 'P, Q, R, S and T were allocated to Gaza and never issued.';
static const String invalidUsageCode    = '...';
static const String gazaPrefixNotThree  = 'A Gaza plate always begins with 3.';
static const String invalidDistrictCode = '...';
```

Also give each validator a **static, spec-free** `validateFields({...})` — the
country rule without a `PlateSpec`, taking the group strings directly, exactly
as `PalestinePlateValidator.validateFields` does. That is what the generator and
the tests call.

Scheme detection for the West Bank: read the `governorate`/`usage` group; a
letter means modern, two digits mean legacy. Since modern and legacy are
*different specs*, each validator knows which it is — do not build a sniffing
validator that handles both, build `PSWestBankModernValidator` and
`PSWestBankLegacyValidator`, and let the spec pick.

---

## 9. Serial generator

`palestine_serial_generator.dart` — pure Dart, no Flutter import beyond what
`core_plate` needs. One generator per scheme, seeded `Random` for reproducible
synthetic datasets.

It must never emit `I` or `O`, never emit a reserved Gaza letter on a West Bank
plate, never emit an invalid usage or district code, and never emit a Gaza
prefix other than `3`. Return `List<String?>` — the shape `PlateNumber` and the
validators already speak — plus a convenience that formats it for a filename.

Assert in tests that 10 000 generated serials all validate.

---

## 10. Example app

`example/lib/main.dart`, modelled on `palestine_plate/example/lib/main.dart`.
It depends on **`palestine_plate` and `plate_keypad`** and demonstrates:

- a spec picker (modern / legacy / Gaza 2012 / Gaza 2021 / trade / the two-line
  and moto form factors);
- a `PSUsage` picker that swaps the **theme**, showing that colour is derived
  and never passed;
- `PlateCanvas` with `inputSource: PlateInputSource.packageKeypad`, a
  `PlateKeypad` underneath fed from `PlateInputController`, and
  `onChooseCharacter: PlateCharacterPicker.show` so the governorate-letter slot
  opens `plate_keypad`'s modal wheel over the 13 legal letters;
- `autoValidate: true` with the matching validator, and a submit button gated on
  the validator rather than on `PlateNumber.isCompleted`;
- a `ShowPlate` row rendering a few generated plates read-only.

Wire the keypad exactly as `plate_keypad`'s README shows:
`onKey: (key) => key == kPlateBackspaceKey ? controller.backspace() :
controller.submit(key)`.

**Caveat to write into the example, not to paper over:** swapping `spec:` on a
live `PlateCanvas` resets the bloc, so changing scheme or form factor mid-entry
wipes what was typed. The example should either confirm before switching or
re-seed the new spec from the old values.

---

## 11. Tests

- `debugValidateSpec` on **every** spec (it is assert-only, so run it inside an
  `assert`, in a test that runs in debug).
- Validator unit tests driven by `validateFields`, one case per reason constant,
  plus the boundary cases: `H`→`J` gap, `I`/`O` rejected, `P`–`T` rejected,
  legacy `0`/`2` districts rejected, Gaza `30–39` and `60–99` rejected, Gaza
  prefix ≠ 3 rejected, legacy `99` → government theme, modern with no usage →
  private.
- Generator round-trip: 10 000 serials, all valid.
- **Golden tests: one golden per (spec × usage theme)**, so a calibration change
  shows up as a visible diff. Render through `ShowPlate` at a fixed width.
  Goldens are the point of the `// CALIBRATE` discipline — without them a tuned
  hex is an invisible change.

---

## 12. Docs

`README.md` follows the house style of `iran_plate` / `palestine_plate`
exactly — the `FREE PALESTINE 🇵🇸🇮🇷 پاینده ایران` / `GO VEGAN 🌱` header, the
`==========` rule, the "Also available" list, the "Depends on" line stating
`core_plate` and nothing else, a `## Use` block, `## Contains`, and a
`## What it does not ship`.

Cover honestly, in prose:

- that the West Bank and Gaza are two designs, not one with a flag;
- that colour is derived from usage and the host passes the theme, because
  `PlateSpec` carries no theme field;
- that switching spec resets the bloc;
- the `I`/`O` gap;
- what is unverified (see §13).

`CHANGELOG.md`: a single `## 0.1.0` entry.

---

## 13. Honesty rules — the part that matters most

The old brief was written as a spec. Parts of it are attested and parts are
inference. **Do not launder inference into `const`s that read as fact.**

- Every colour is `// CALIBRATE` until sampled from a photograph. Say so.
- Every dimension not measured off an image in `pics/` is provisional. Say so on
  the line.
- If you cannot source the Palestinian flag SVG or the watermark artwork, **do
  not draw an approximation and ship it as the flag**. Leave the asset out, make
  the const `flag: null` with a `TODO` naming exactly what is missing, and list
  it under "What it does not ship" in the README. `palestine_plate` already sets
  that precedent for the state emblem and it is the right one.
- If a `core_plate` limitation blocks something (decal opacity, flag rotation,
  label direction, draw order), **report it**; do not silently edit `core_plate`
  and do not fake it in the country package.
- Anything the reference material genuinely does not settle gets a `TODO` and a
  sentence in the README, not a plausible guess.

At the end, produce a short report listing: every `// CALIBRATE` you left, every
`TODO`, every `core_plate` limitation you hit, and every place you departed from
this prompt and why.

---

## 14. Definition of done

- [ ] `flutter analyze` clean under `iran_plate`'s `analysis_options.yaml`.
- [ ] `flutter test` green, goldens committed.
- [ ] `grep -ril "iran\|germany\|keypad" palestine_plate/lib/` returns nothing.
- [ ] `palestine_plate/lib/` contains no `Widget`, no `CustomPainter`, no
      `StatefulWidget`, no bloc, no `mmToPx`.
- [ ] `pubspec.yaml` dependencies are `flutter` and `core_plate`, full stop.
- [ ] Every declared asset path exists on disk and appears in the pubspec.
- [ ] The example runs and drives every spec from `plate_keypad`.
