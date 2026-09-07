# Prompt — build `yemen_plate`

You are working in the `plate` monorepo (`~/StudioProjects/plate`), which already
contains `core_plate`, `plate_keypad`, `iran_plate`, `germany_plate`,
`palestine_plate` and (from the companion prompt) `palestine_plate`.

Build a new Flutter package **`yemen_plate`**: Yemen's licence plates expressed
as **data for `core_plate`**, structurally parallel to `palestine_plate`.

---

## 0. Read this first — it overrides every instinct you have

`core_plate` is a country-neutral plate engine. It owns every widget, every
painter, the input state machine, the bloc and the theming. A country package
contributes **`const` data and nothing else**.

Before writing a line:

1. Read `core_plate/lib/core_plate.dart` — its doc comment *is* the contract.
2. Read `core_plate/lib/src/model/plate_spec.dart`, `plate_alphabet.dart`,
   `plate_country.dart`, `plate_asset.dart`, `plate_box.dart`,
   `theme/plate_theme.dart`, `validators/plate_validator.dart`.
3. Read `iran_plate/` end to end — the reference implementation of a country
   package.
4. Read `palestine_plate/` — this package mirrors its layout, naming and
   documentation discipline exactly.

### Hard rules

- **No `CustomPainter`. No `StatefulWidget`. No new widget of any kind.**
  `PlateCanvas` and `ShowPlate` from `core_plate` render every plate here.
- **No BLoC, no state management, no controllers.** `core_plate` owns the bloc.
- A plate design is a `const PlateSpec`. **Adding a plate means adding a const.**
- Geometry is plate space: `canvasWidth` × `canvasHeight` with the origin
  top-left, and `PlateBox(left, top, width, height)`. Millimetres are a fine
  canvas unit — set the canvas to the real millimetre size and every box is in
  millimetres. **No `mmToPx` helper**; `PlateCanvas` scales the whole canvas.
- Colour is a `PlateTheme`, never baked into a spec.
- Validation is a `PlateValidator` returning `PlateValidation`. It never throws
  and never bars a keystroke. There is no sealed result type to invent.
- **Dependencies: `core_plate` only.** Not `plate_keypad`, not `iran_plate`, not
  `palestine_plate`. `plate_keypad` may appear **only** in
  `example/pubspec.yaml`.
- Not one file in `lib/` may name another country.

### Translation table (old brief → `core_plate`)

| The old brief said | You write |
|---|---|
| `abstract YemenPlate` + subclasses | nothing — plates are `const PlateSpec` values |
| `YemenUnifiedPlate`, `YemenNorthernPlate` | two `abstract final class` namespaces of spec consts |
| one `CustomPainter` per template | nothing |
| `YemenFormFactor` → different geometry | one `PlateSpec` const per form factor |
| colour by usage | one `PlateTheme` const per scheme + a `YemenUsage → PlateTheme` lookup |
| `ye_metrics.dart` of consts | numbers live inline on each spec line, with the `// CALIBRATE` comment there |
| `ye_colors.dart` | `yemen_plate/lib/src/yemen_colors.dart` — one file, all `// CALIBRATE` |
| sealed validation result | `PlateValidation` + `static const` reason strings |
| `YemenPlateWidget` | `PlateCanvas` / `ShowPlate` from `core_plate` |

---

## 1. Critical context — read before designing the API

**Yemen has no single national plate system.** Political control is fractured
and two incompatible systems are on the road simultaneously, in different
geographies. This is not a legacy/current pair; **both are current**.

- **System A** — approved 9 May 2026 by the Ministry of Interior of the
  internationally recognised government (Presidential Leadership Council),
  announced by Brig. Gen. Omar Bamshmos, Director General of Traffic Police.
  Valid **only** in governorates under that government's control.
- **System B** — the 1993 format, still in force across the Houthi-controlled
  north. The larger share of the fleet, because System A only began rolling out
  in mid-2026.

**Model these as two sibling namespaces, never as a version flag on one.** They
have different serial grammars, different colour semantics and different
geographic validity. Keeping them apart is the point — do not "unify" them, and
do not add a `YemenSystem` enum that selects between them at runtime.

> Note on dates: System A is very recent and this prompt is your only source for
> it. Treat every System A dimension and colour as unverified — see §11.

---

## 2. File layout

```
yemen_plate/
  lib/
    yemen_plate.dart                 # the only public surface; exports src/*
    src/
      yemen_colors.dart              # every colour, all // CALIBRATE
      yemen_themes.dart              # PlateTheme per scheme + usage lookups
      yemen_country.dart             # PlateCountry consts
      yemen_alphabets.dart           # every PlateAlphabet
      yemen_governorates.dart        # YemenGovernorate enum (1..22, ar/en, control)
      yemen_usage.dart               # YemenUsage, YemenMilitaryStyle enums
      unified_plates.dart            # YemenUnifiedPlates.* specs   (System A)
      northern_plates.dart           # YemenNorthernPlates.* specs  (System B)
      yemen_validators.dart          # one validator per system
      yemen_serial_generator.dart    # synthetic-serial generator
  assets/
    marks/yemen_emblem.svg           # optional; see §6
  example/
    lib/main.dart
    pubspec.yaml                     # depends on yemen_plate + plate_keypad
  test/
  pubspec.yaml
  CHANGELOG.md
  README.md
  LICENSE
  analysis_options.yaml
```

Copy `analysis_options.yaml` and `LICENSE` from `iran_plate` verbatim.

`pubspec.yaml`:

```yaml
name: yemen_plate
description: "Yemen's licence plates for the core_plate library — the 2026 unified specs, the 1993 northern specs, the alphabets, the usage themes and the advisory validators."
version: 0.1.0
homepage: https://github.com/ArAd1Beyranvand/plate-yemen

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
```

Add a `flutter: assets:` block **only if** you actually ship an asset. If the
emblem is not sourced, ship no assets and say so in the README, the way
`palestine_plate` does.

---

## 3. Template A — `YemenUnifiedPlates` (System A, 2026)

The plate carries: the name of Yemen, the vehicle number, the governorate code,
the year of registration, and the type of use. The published specification also
fixes plate dimensions, font sizes and numbering format.

### Grammar

- **vehicleNumber**: 4 to 6 Latin digits. No letters, no separators. The
  official mock-up sample is `24378` (5 digits). Do not zero-pad; render as
  entered.
- **sideCode**: exactly 2 digits. The official text says this field carries the
  governorate code **and** the registration year; the published sample shows a
  single 2-digit value (`99`). **This is unresolved.** Model it as an opaque
  2-character field named `sideCode`, with a `TODO`, and **do not** split it into
  governorate + year until a real photograph confirms the split. Do not invent a
  split and do not "helpfully" derive a governorate from it.
- **usage**: `YemenUsage`, supplied by the host.

### Usage enum (drives the two text lines in the blue panel)

| Value | Arabic | Latin |
|---|---|---|
| `private` | خصوصي | PRIV. |
| `forHire` | أجرة | TAXI |
| `transport` | نقل | TRANS. |
| `government` | حكومي | GOV. |
| `police` | شرطة | POLICE |

### Colour

**System A does not recolour the field by usage.** The background stays white for
every usage; usage is conveyed by the text in the blue side panel only.

```
plateBackground = WHITE
allGlyphs       = BLACK
sidePanel       = LIGHT BLUE  0xFF7FB2E5   // CALIBRATE
outerFrame      = BLACK, rounded rect, thick stroke
```

Implement it that way. **Do not add colour coding**, however tempting the
symmetry with Template B is.

Consequence for `core_plate`: the blue side panel *is* the `PlatePanel`, so it
comes from `PlateCountry.panelColor`. One `PlateCountry` const per usage is
therefore unnecessary here — the panel colour never changes — but the caption
lines do. See §5.

### Zones — 520 × 288 canvas, left to right (LTR plate order, even though two
labels are Arabic)

| Zone | Extent | Content |
|---|---|---|
| **A** — country block | ~18% of width, left edge | line 1 `اليمن` (Arabic, bold), line 2 `YEMEN` (Latin, bold, same optical weight). Both black, stacked and vertically centred together |
| **B** — main number | ~55% of width, centre | the vehicleNumber, black, very large, heavy condensed grotesque. Cap height ≈ 62% of plate height `// CALIBRATE`. Horizontally centred, tracking slightly negative |
| **C1** — separator | ~2% of width | a narrow vertical **dotted / stippled** strip immediately left of the blue panel, black on white `// CALIBRATE dot pitch` |
| **C2** — blue side panel | ~20% of width, right edge, full height | line 1 `sideCode` (2 chars, black, bold, large); line 2 usage Arabic label (black, small); line 3 usage Latin label (black, small, bold); behind lines 2–3, a faint emblem watermark |

Mapping each zone onto `core_plate`:

- **Zone A is not the `PlatePanel`.** The panel in this design is Zone C2 (the
  blue block on the right). Zone A is **two `PlateLabel`s**, `اليمن` and
  `YEMEN`, stacked. Keep them as two separate labels — `PlateLabel` has no
  `TextDirection` and `core_plate` lays a label out as given, so an Arabic label
  on its own is an isolated run and renders correctly, while concatenating it
  with a Latin one would let the bidi algorithm reorder them. Write that reason
  into the comment.
- **Zone B is the slots**, one `PlateSlot` per digit.
- **Zone C1** is a problem: `core_plate` has `PlateRule`, which paints a solid
  box, and no stippled-rule primitive. Pick one and document it: either a column
  of many short `PlateRule`s (honest, verbose, and it *is* data), or a solid rule
  with a `TODO` saying the stipple is unimplemented. **Do not add a painter to
  `core_plate` for this** without reporting it.
- **Zone C2** is the `PlatePanel` (`panelColor` = the light blue,
  `panelTextColor` = black, `flag: null`, `flagScale: 0`) carrying the usage
  caption lines, **plus** slots for the `sideCode`. Note the ordering
  constraint: slots are a flat list in reading order, so the two `sideCode`
  slots come after the vehicleNumber slots in the list even though they are in a
  different zone. That is fine — `textGroups` restores the semantics.
- The **emblem watermark** is a `PlateDecal`, which takes an `ImageProvider` and
  paints at full opacity — `core_plate` has no opacity parameter. So it must be
  a **pre-faded** asset. **The emblem artwork is not sourced.** Leave the decal
  out entirely, with a `TODO` naming exactly what is missing, and list it under
  "What it does not ship" in the README. Do not draw an approximation of a state
  emblem and ship it as the real one.

### Specs to declare

| Const | id | canvas | notes |
|---|---|---|---|
| `car5` | `ye.unified.car5` | 520 × 288 | the sample-length plate: 5 number digits + 2 sideCode |
| `car4` | `ye.unified.car4` | 520 × 288 | 4 number digits |
| `car6` | `ye.unified.car6` | 520 × 288 | 6 number digits |
| `moto5` | `ye.unified.moto5` | 289 × 288 | see §5 |
| `moto4`, `moto6` | … | 289 × 288 | |

**On variable length.** `PlateSpec` has a fixed slot list, so a 4-to-6-digit
number cannot be one spec. Declare one const per length and a
`Map<int, PlateSpec> byNumberLength`. Then write this caveat into the doc
comment and the README: **swapping `spec:` on a live `PlateCanvas` resets the
bloc**, so a host picks the length before entry begins, not during it. That is
the same reasoning `palestine_plate` used to avoid two specs for its two
endings — here the conclusion goes the other way because the slot *count*
differs, and it is worth saying why.

---

## 4. Template B — `YemenNorthernPlates` (System B, 1993 format)

Plate types are distinguished by **background colour** plus an Arabic usage word
placed above the numeric block, next to the country name اليمن. The numeric
section is split into two by a **horizontal line**.

### Grammar

- **governorateCode**: 1 or 2 digits, 1..22 inclusive. Rendered **above** the
  rule.
- **vehicleSerial**: 1 to 6 digits, no leading-zero padding. Rendered **below**
  the rule.

Note the asymmetry: this is a **stacked two-register** layout, not a left/right
split. The rule separates them vertically.

### Governorate enum (closed, 1..22)

| | | | |
|---|---|---|---|
| 1 Sanaa (City) | 7 Ibb | 13 Al Bayda | 19 Amran |
| 2 Sanaa (Governorate) | 8 Hajjah | 14 Al Mahwit | 20 Dhale |
| 3 Aden | 9 Dhamar | 15 Shabwah | 21 Raymah |
| 4 Taiz | 10 Saada | 16 Marib | 22 Socotra |
| 5 Hadhramaut | 11 Abyan | 17 Al Mahrah | |
| 6 Al Hudaydah | 12 Lahij | 18 Al Jawf | |

`0` and anything above 22 are invalid. Each value carries its English name, its
Arabic name, and a `bool underHouthiControl` — System B is only genuinely
current in the north. **Expose that flag; do not enforce it.** A validator that
rejected a southern governorate on a northern plate would be making a political
claim the data does not support.

### Usage, colour and text — here colour **is** the primary signal

| Usage | Arabic | Background | Text |
|---|---|---|---|
| `private` | خصوصي | blue | black |
| `forHire` | اجرة | yellow | black |
| `transport` | نقل | red | black |
| `government` | — | green | white |
| `military` | — | black | white |

`forHire` covers taxis and buses; `transport` covers goods vehicles, pick-ups,
trucks and trailers. A newer military form uses **white + red** — expose it as
`YemenMilitaryStyle.classic` / `.modern`, not as a sixth usage.

```dart
static const Color blue   = Color(0xFF1F5FA8); // CALIBRATE
static const Color yellow = Color(0xFFF2C200); // CALIBRATE
static const Color red    = Color(0xFFC0261F); // CALIBRATE
static const Color green  = Color(0xFF14733E); // CALIBRATE
static const Color black  = Color(0xFF111111); // CALIBRATE
```

### Typeface — this is specified, not guessed

- alphanumerics: **FE-Schrift** (the German anti-forgery face)
- Arabic: **Square Kufic**

Both apply to the 2018 revision onward.

**But `PlateTheme.glyphStyle` names no font family** — it sets colour, weight
700, size and height only, and `core_plate` deliberately leaves the family to the
host's subtree (`palestine_plate`'s README says exactly this about its condensed
face). So `yemen_plate` **cannot** bundle a font and have it picked up. Do this
instead:

- Document in the README, under `## Fonts`, that the plate is set in FE-Schrift
  and Square Kufic, that the package does not ship them, and that the host
  supplies them by wrapping the canvas in a `DefaultTextStyle` / theme with the
  right family.
- Bundle the fonts in `example/` only, and use them there, so the example shows
  the plate as it really looks.
- If a substitute face is used in the example, name the substitution in a code
  comment.

Do **not** add a `fontFamily` field to `PlateTheme` to make this work without
reporting it as a `core_plate` change.

### Layout — 520 × 288 canvas

- **Top band**, full width, ~28% of height: `اليمن` on the left, the usage word
  on the right, adjacent to it. Both in the foreground colour for the active
  usage. → two `PlateLabel`s (separate labels, for the bidi reason in §3).
- **Main block**, remaining ~72%:
  - upper register: governorateCode slots, centred;
  - **horizontal rule**: full width of the numeric block, foreground colour,
    ~3% of plate height → a `PlateRule`;
  - lower register: vehicleSerial slots, centred.
  - `// CALIBRATE` the register split — from reference images the lower register
    is optically **larger** than the upper.
- **Outer border**: rectangular, foreground colour → a theme with
  `plateRadiusRatio: 0` and the stroke on `borderWidthRatio`. Mirror the stroke
  on the spec via `borderWidthRatioOverride` so the geometry survives a host
  that supplies its own theme.

### Specs

Same variable-length problem, twice over (1–2 governorate digits × 1–6 serial
digits). Do not enumerate all twelve. Declare the attested and useful subset —
`gov2serial5`, `gov1serial5`, `gov2serial4`, `gov2serial6`, and whatever a
reference image actually shows — expose
`Map<(int govDigits, int serialDigits), PlateSpec>`, and put a `TODO` on the
combinations you did not build rather than generating a wall of speculative
consts. Say in the README which combinations exist.

---

## 5. Motorcycles — a form factor on **both** systems, not a third namespace

Yemeni motorcycle plates are not a separate design. Wikimedia Commons holds
governorate plate files at **520 × 288** for cars and **289 × 288** for
motorcycles of the *same* governorate — same content, half the width. Confirmed
for Marib and Al Mahrah.

```
car        aspect ≈ 1.80   (canvas 520 × 288)
motorcycle aspect ≈ 1.00   (canvas 289 × 288)
```

Reflow:

- **Unified (A)**: Zone A moves to a full-width **top band** (`اليمن` and
  `YEMEN` side by side). Zone B takes the middle. Zone C2 becomes a full-width
  **bottom band**, blue, with `sideCode` on the left and the usage labels on the
  right. In `core_plate` terms: the `PlatePanel` box becomes wide and short, and
  the two country labels move — the *spec* changes, no code does.
- **Northern (B)**: already vertically stacked, so it compresses naturally. Keep
  the top band, keep the horizontal rule, shrink the serial register.

**Known-unknown to encode as a `TODO`, not to invent:** no official motorcycle
design has been published for the northern (Houthi) system, despite active
registration campaigns run by the Sanaa traffic police under Cabinet Decision
No. 33 of 1446 AH and an equivalent process in Taiz. Generate the northern
motorcycle plate as a moto-form rendering of Template B and mark those consts:

```dart
@Deprecated('unverified geometry — calibrate against photographs')
```

so they are not silently trusted in a training set. Say the same thing in the
README.

One colour note worth keeping: **Marib classifies motorcycles as yellow.** Other
southern governorates publish no motorcycle colour. **Do not extrapolate yellow
to the rest.**

---

## 6. Alphabets and countries

`yemen_alphabets.dart` — declare under a `ye.` id prefix. Every slot on both
templates is a Latin digit, so in principle `PlateAlphabet.latinDigits` would do;
restate them here for the same reason `palestine_plate` does — the governorate
alphabet is a *restricted* digit set, and `debugValidateSpec` asserts that one id
never stands for two character lists, and that two ids never share one list.

| Const | id | characters | input |
|---|---|---|---|
| `digits` | `ye.digits` | `0`–`9` | `typed`, `isNumeric: true` |
| `governorateTens` | `ye.govTens` | `0,1,2` | `typed` — the tens digit of 1..22 |
| `sideCodeDigits` | — | *reuse `digits`* | — do not mint a second id with the same list |

Read that last row and obey it. Only mint a new id when the characters genuinely
differ.

`yemen_country.dart` — `PlateCountry` consts. The System A blue panel and the
System B coloured field need different `panelColor` / `panelTextColor`, so
declare one const per scheme (`unified`, `northernPrivate`, `northernForHire`,
`northernTransport`, `northernGovernment`, `northernMilitaryClassic`,
`northernMilitaryModern`), all with `code: 'ye'` so they compare equal, all with
`flag: null` and `flagScale: 0` on the panel — a Yemeni plate carries no flag, so
do not reserve a strip for a null image.

For System B the country name and the usage word live in the **top band as
labels**, not in the panel — so those `PlateCountry` consts mostly exist to carry
the two colours. Note that in the doc comment; it is a slightly odd use of the
type and the next reader deserves the sentence.

---

## 7. Themes

`yemen_themes.dart`:

- `YemenThemes.unified` — white field, black ink, black border, `// CALIBRATE`
  the corner radius and stroke. One theme for all five usages, by design.
- `YemenThemes.northernPrivate / ForHire / Transport / Government /
  MilitaryClassic / MilitaryModern` — background from the table in §4, ink black
  or white to match, `plateRadiusRatio: 0` (the northern plate is rectangular).
- `YemenThemes.forNorthernUsage(YemenUsage, {YemenMilitaryStyle style})` — the
  lookup. Colour is derived from usage; a host never picks a theme directly.

---

## 8. Validators

`yemen_validators.dart` — `YemenUnifiedValidator` and `YemenNorthernValidator`.
Both `const`, both never throw, both stay quiet until the group being judged has
something in it (the rule `PalestinePlateValidator` and `GermanPlateValidator`
already follow: with nothing barring input, red is the only feedback there is,
and a plate that flashes red at its first keystroke is worse than none).

Named failures become `static const String` reason constants, referenced by the
tests:

```dart
static const String serialTooShort        = '...';
static const String serialTooLong         = '...';
static const String governorateOutOfRange = 'Governorate code must be between 1 and 22.';
static const String sideCodeWrongLength   = 'The side code is exactly two digits.';
static const String serialNotDigits       = '...';
```

Each validator also gets a static, spec-free `validateFields({...})` taking the
group strings directly, as `PalestinePlateValidator.validateFields` does — that
is what the generator and the tests call.

`textGroups`, keyed, on every spec:

- unified: `number` `[0..n]`, `sideCode` `[n+1, n+2]`
- northern: `governorate` `[...]`, `serial` `[...]`

---

## 9. Serial generator

`yemen_serial_generator.dart` — pure Dart, seeded `Random`, one generator per
system. Honour every range above: governorate 1..22 and never 0 or >22, serial
1–6 digits with no leading-zero padding, `sideCode` exactly 2 digits, unified
number 4–6 digits. Return `List<String?>`.

Test: 10 000 generated serials all validate, for both systems.

---

## 10. Example, tests, docs

**Example** (`example/`, depends on `yemen_plate` **and** `plate_keypad`):
a system switch (Unified / Northern), a usage picker that swaps the theme,
a form-factor switch (car / motorcycle), `PlateCanvas` with
`inputSource: PlateInputSource.packageKeypad` and a `PlateKeypad` underneath
driven by `PlateInputController`
(`onKey: (key) => key == kPlateBackspaceKey ? controller.backspace() :
controller.submit(key)`), `autoValidate: true`, and a `ShowPlate` row of
generated plates. Bundle FE-Schrift and Square Kufic (or named substitutes)
here and apply them to the subtree, since the package cannot.

Write the bloc-reset caveat into the example: changing system, usage-length or
form factor mid-entry resets the canvas.

**Tests**: `debugValidateSpec` on every spec; validator cases per reason
constant plus the boundaries (governorate 0, 22, 23; serial length 0, 1, 6, 7;
`sideCode` of 1 and 3 chars); generator round-trip; and **golden tests, one per
(spec × usage theme)** so a calibration change shows as a visible diff.

**README**: house style — the `FREE PALESTINE 🇮🇷🇵🇸 پاینده ایران` /
`GO VEGAN 🌱` header, the `==========` rule, "Also available", a "Depends on"
line stating `core_plate` and nothing else, `## Use`, `## Contains`,
`## Fonts`, `## What it does not ship`. Lead with the two-systems fact — it is
the first thing a consumer needs to know and the reason the API looks the way it
does.

**CHANGELOG**: a single `## 0.1.0` entry.

---

## 11. Honesty rules — the part that matters most

Parts of this brief are attested and parts are inference. **Do not launder
inference into `const`s that read as fact.**

- **System A is new and thinly sourced.** Every one of its dimensions, its light
  blue, its dot pitch and its cap-height ratio is `// CALIBRATE`. The
  governorate/year split in `sideCode` is explicitly unresolved — leave it
  opaque with a `TODO`.
- The northern motorcycle geometry is unverified. `@Deprecated` it and say so.
- Marib's yellow motorcycles do not generalise. Do not extrapolate.
- `underHouthiControl` is exposed, never enforced.
- If the emblem artwork or a font is not sourced, **do not approximate it and
  ship it as the real thing.** Leave it out, `TODO` what is missing, and list it
  under "What it does not ship" — `palestine_plate` set that precedent with the
  state emblem and it is the right one.
- If a `core_plate` limitation blocks something — decal opacity, no stipple
  primitive, no font family on `PlateTheme`, label direction, draw order —
  **report it**; do not silently edit `core_plate`, and do not fake it in the
  country package.

At the end, produce a short report listing: every `// CALIBRATE` left, every
`TODO`, every `@Deprecated` const, every `core_plate` limitation hit, and every
place you departed from this prompt and why.

---

## 12. Definition of done

- [ ] `flutter analyze` clean under `iran_plate`'s `analysis_options.yaml`.
- [ ] `flutter test` green, goldens committed.
- [ ] `grep -ril "iran\|germany\|palestin\|keypad" yemen_plate/lib/` returns
      nothing.
- [ ] `yemen_plate/lib/` contains no `Widget`, no `CustomPainter`, no
      `StatefulWidget`, no bloc, no `mmToPx`.
- [ ] `pubspec.yaml` dependencies are `flutter` and `core_plate`, full stop.
- [ ] The two systems are two namespaces with no shared version flag between
      them.
- [ ] The example runs and drives every spec from `plate_keypad`.
