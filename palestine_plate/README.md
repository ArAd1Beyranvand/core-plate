FREE PALESTINE 🇵🇸🇮🇷 پاینده ایران

GO VEGAN 🌱

==================================

Palestine's licence plates for [`core_plate`](https://pub.dev/packages/core_plate) - a
country that, as the licence header insists, actually exists.

## Also available

- [`core_plate`](https://pub.dev/packages/core_plate) - Paint license plates.
- [`plate_keypad`](https://pub.dev/packages/plate_keypad) - A character picker for license plates.
- [`iran_plate`](https://pub.dev/packages/iran_plate) - Iran's plates.
- [`germany_plate`](https://pub.dev/packages/germany_plate) - Germany's plates.
- [`yemen_plate`](https://pub.dev/packages/yemen_plate) - Yemen's plates.

# palestine_plate

It's data, not code: two country blocks, four alphabets, thirteen `PlateSpec` consts,
eight `PlateTheme`s and three validators. There is no widget in this package, no
painter and no state - `core_plate` owns all of that and paints whatever a spec
describes. **Adding a plate here means adding a `const`.**

## Depends on

`core_plate` alone - not `iran_plate`, not `germany_plate`, not `plate_keypad`, not
`core_plate_bloc`. The keypad appears in `example/pubspec.yaml` and nowhere else.

## Use

```dart
import 'package:core_plate/core_plate.dart';
import 'package:palestine_plate/palestine_plate.dart';

PlateCanvas(
  spec: PSWestBankPlates.modernCar,
  theme: PSThemes.forUsage(PSUsage.private),   // colour is derived, see below
  validator: const PSWestBankModernValidator(),
  autoValidate: true,
  // The governorate slot is a `chosen` alphabet, so it opens a picker.
  // `PlateCharacterPicker.show` comes from plate_keypad, which is the host's
  // dependency to take, not this package's.
  onChooseCharacter: (a) => PlateCharacterPicker.show(context, a),
);
```

For a legacy plate, whose `ف / P` block ink follows its usage, pass `country:`
beside the theme — one spec, recoloured at render time rather than a spec per ink:

```dart
PlateCanvas(
  spec: PSWestBankPlates.legacyCar,
  theme: PSThemes.forUsage(PSUsage.publicTransport),
  country: PSWestBankPlates.legacyCountryForUsage(PSUsage.publicTransport),
  validator: const PSWestBankLegacyValidator(),
  autoValidate: true,
);
```

`example/` holds two apps: `lib/main.dart`, one plate with pickers and a keypad,
and `lib/gallery.dart`, all eleven specs on one page, each empty and editable
(`flutter run -t lib/gallery.dart`). The gallery is the fastest way to see what
this package draws.

## Two designs, not one plate with a flag

The West Bank and Gaza are **separate plates**, not one template with a different
badge. Gaza broke away from the Palestinian Authority's numbering in 2012 and has run
its own design since.

|  | West Bank | Gaza |
|---|---|---|
| identity block | `ف` over `P`, in the plate's own ink | the Palestinian flag |
| grammar | `D·DDDD·L` (modern) or `D·DDDD·DD` (legacy) | `3·DDDD·DD`, always |
| field | white, **or green** when the plate inverts | always white |
| what usage changes | the whole colour scheme | glyph, border and rule colour only |

`P` is **Portugal's** international code. Palestine has none assigned, so `P` is used
unofficially - it is a literal glyph printed on the plate, never the result of a
country-code lookup, and nothing in this package resolves it as one.

The West Bank's two schemes are two specs, not one spec that sniffs which it is
looking at: modern ends in a governorate letter, legacy ends in two usage digits, and
they have different slot counts. Each gets its own validator to match.

## Colour is derived from usage, and the host passes the theme

A host does not decide a plate is green. It knows the vehicle is a private car and
asks:

```dart
final theme = PSThemes.forUsage(PSUsage.private);        // green on white
final gaza  = PSThemes.forGazaUsageCode('12');           // green glyphs, white field
```

`PlateSpec` carries **no theme field** - a spec is geometry, a theme is colour, and
`core_plate` keeps them apart deliberately - so a theme cannot be attached to a spec
and picked up for you. Pass `theme:` or wrap the canvas in a `PlateThemeScope`.

The legacy scheme encodes usage in its last two digits and Gaza's does the same, so
for those a plate's colour is readable off the plate. **The modern West Bank scheme
encodes no usage at all**: the trailing letter is a governorate. A host supplies the
usage from whatever record it has, and `PSUsage.private` is the sane default.

`forGazaUsageCode` returns **null** for an unallocated code (`30`-`39`, `60`-`99`)
rather than a fallback theme. An out-of-range code is an invalid plate; painting it
black anyway would hide that.

## The `I` / `O` gap

The thirteen modern governorate letters are a **closed** set:

```
A B C D E F G H J K L M N
```

**There is no `I` and no `O`.** The sequence jumps `H` to `J`. In an OCR confusion
matrix, `I` is a guaranteed misread of `1` or `J`, and `O` of `0` - never emit either.
`P`, `Q`, `R`, `S` and `T` were allocated to Gaza's governorates under the pre-2012
scheme and never issued; `PSGovernorate.reservedGazaLetters` names them and
`PSWestBankModernValidator` rejects them with a reason of their own.

Legacy district codes have their own hole: `0` and `2` are not legal, which is why
`PSAlphabets.districtDigits` leaves them out of the alphabet rather than validating
them out afterwards.

## Switching spec carries the value across

`PlateCanvas` reacts to a changed `spec.id` under `PlateValuePreservation.byGroupKey`
(the default since `core_plate` 0.4.0): it copies each register to the same-keyed
register on the new spec and truncates only what no longer fits, instead of emptying
the plate. **So swapping scheme or form factor mid-entry keeps what still makes
sense** - a five-digit serial survives the jump from `modernCar` to `modernMoto`, the
trailing governorate letter does not survive the jump to a scheme that has no such
slot. `example/lib/main.dart` relies on this; it no longer re-seeds by hand. Pass
`onSpecChange:` to choose `byIndex` or `none` instead.

## Validation is advisory

Every validator here is `const`, never throws, and **never bars a keystroke**. Each
stays quiet - `PlateValidation.valid()` - until the user has actually reached the
group being judged: with nothing blocking input, the red underline is the only
feedback there is, and a plate that flashes red at its first keystroke is worse than
no validation at all.

Each also exposes a static, spec-free `validateFields({...})` taking the group strings
directly. That is what the serial generator and the tests call.

## Contains

- `PSCountries` - `westBankGreenInk` / `.westBankWhiteInk` / `.westBankRedInk` /
  `.westBankGreenInkInline` / `.westBankGreenInkBlank`, and `.gaza2012` /
  `.gaza2021`. One const per **ink** colour, all with `code: 'ps'` so they
  compare equal.
- `PSAlphabets.digits` / `.districtDigits` / `.governorateLetters` / `.gazaPrefix`.
- `PSGovernorate` - the thirteen letters with Arabic and English names.
- `PSUsage`, `PSLegacyUsage` and `PSGazaUsage` - the two unrelated usage-code maps.
- `PSColors` and `PSThemes` - eight themes plus `forUsage` / `forGazaUsageCode`.
- `PSWestBankPlates` - `modernCar`, `legacyCar`, `modernCarTwoLine`,
  `legacyCarTwoLine`, `modernMoto`, `modernMotoTwoLine`, `modernTrade`, `all`,
  and `legacyCountryForUsage` (the `ف / P` ink for a legacy usage, handed to
  `PlateCanvas.country`).
- `PSGazaPlates` - `car2012`, `car2012TwoLine`, `car2021TwoLine`, `moto`, `all`.
- `PSWestBankModernValidator`, `PSWestBankLegacyValidator`, `PSGazaValidator`.
- `PSSerialGenerator` - reproducible synthetic serials, one per scheme.
- `assets/flags/Flag_of_Palestine.svg`, its pre-rotated vertical twin, and
  `assets/marks/palestine_watermark.png`.

## What it does not ship

**No fonts.** The plate prints `ف`, `اختبار` and `במבחן`, and none of those are on a
stock Android or a bare CI runner. `PlateTheme.glyphStyle` names no font family and
`core_plate` offers no hook to give one to a label, so a font bundled here could not
be applied to the glyphs that need it. Supplying a face to the subtree is the host's
job, through its own `Theme` or `DefaultTextStyle`. (`assets/fonts/` holds the
licence notices and the faces the watermark artwork was rasterised from - provenance,
not a shipped resource; nothing in `lib/` references them.)

**No verified geometry outside the two measured plates.** Two reference images back
this package, and only what is measured off them is not a guess:

- `pics/reference_plate.png` gives the West Bank car template - `borderWidthRatio:
  0.027`, `plateRadiusRatio: 0.10`, `modernCar`'s horizontal positions, and
  `PSColors.green` (`0xFF3C875D`, sampled - 29 397 pixels of that image are exactly
  that value).
- `pics/License_Plate_-_Palestine_-_Motorcycle_-_2018_-_1-Line_Design.png` gives
  `PSWestBankPlates.modernMoto` outright: its 250 x 123 canvas is that image's own
  pixels, and every slot, label and rule on it is measured. It is *not* the car
  template rescaled - the serial runs full width and the `P | ف` block is a centred
  header band above it, `P` on the left.

**Everything else is provisional and marked `// CALIBRATE` on the line.** That
includes every red, blue and grey; the two-line, trade and Gaza layouts; and the
520 x 110 canvas Gaza inherits from the West Bank for visual consistency rather than
because it is attested. The golden tests exist so that retuning any of it shows up as
a visible diff.

**No scanned artwork.** The flag SVGs are authored to the official geometry - three
equal bands black/white/green, a red isosceles triangle on the hoist reaching a third
of the width, 2:1 - not traced from a plate. The watermark is set in Vazirmatn and
rasterised; it is legible, correctly shaped Arabic, but it is *not* the face a Gaza
plate is actually printed in. See `assets/marks/PROVENANCE.md`.

## `core_plate` limitations this package works around

Reported rather than patched around, and none of them were fixed by editing
`core_plate`:

- **`PlateDecal` takes an `ImageProvider`, not a `PlateAsset`.** So the Gaza watermark
  ships as a PNG through `AssetImage` rather than the SVG its layout calls for.
- **`PlateDecal` paints at full opacity.** There is no fade parameter anywhere on that
  path, so the watermark's ~12% is baked into the pixels. Retune it by regenerating
  the asset, never by changing `lib/`.
- **There is no rotation hook.** Gaza's 2012 plate carries the flag turned a quarter
  turn, so this package ships a *second, pre-rotated* SVG rather than rotating at
  render time.
- **`CountryPanel` lays `captionLines` out as a `Column`, always.** Both motorcycle
  plates want `P` and `ف` side by side, and there are two answers depending on whether
  the divider's position is known. The two-line plate puts both glyphs in one string
  (`westBankGreenInkInline`) and drops the divider, because its x would depend on font
  metrics. The one-line plate has a reference image, so its divider's x is measured:
  it uses `westBankGreenInkBlank` - a country that draws nothing - and prints both
  glyphs and the rule as plate-space geometry instead.
- **`PlateLabel` has no `TextDirection`.** That one is a feature here: it makes each
  label an isolated run, which is why the trade plate's `اختبار` and `במבחן` are two
  labels and must stay two, and why the one-line motorcycle plate's `P` and `ف` are.
  Concatenated into one string, the bidi algorithm reorders them against each other
  and the left label lands on the right.

Draw order was checked rather than assumed: `spec.decals` is painted into the `Stack`
before `spec.slots`, so the watermark is genuinely beneath the digits.

## History

An earlier package covered a subset of this ground: one green-on-white car spec, the
`ف / P` block and the two trailing endings. Its measured geometry, its sampled green
and its validator reasoning are carried over here, along with its reference image at
`pics/reference_plate.png`; what it modelled as one spec with an either/or slot is
modelled here as the two separate schemes it turned out to be. It has been removed
from the repo and this package took its name.
