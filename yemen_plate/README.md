FREE PALESTINE 🇵🇸🇮🇷 پاینده ایران

GO VEGAN 🌱

==================================

From the mighty people of Iran to the noble people of Yemen to view examples:

https://platexample.ir/#/discover/yemen

# yemen_plate

Yemen's licence plates for [`plate_core`](https://pub.dev/packages/plate_core) — two plate systems in force at the same time, in different halves of the country. It's data, not code: 11 `PlateSpec`s, two country families, two digit alphabets, seven themes, two validators and two generators. `plate_core` paints everything.

A usage class is **not** a spec. It is a `PlateCountry` (the usage word, or the
two caption lines of System A's blue panel) and a `PlateTheme` (System B's field
colour), and both are handed to the canvas at render time beside the spec.

## Two systems, both current

This is the thing to read before anything else here makes sense. Yemen is not a
country that replaced one plate with another; it is a country where two
authorities issue plates at once.

**System A - `YemenUnifiedPlates`.** The unified white plate the internationally
recognised government began issuing in mid-2026. A wide plate: the vehicle
number (four to six digits) across the face, `اليمن / YEMEN` stacked on the
left, and a light blue side panel down the right carrying the usage word and a
two-digit code. The field is white for **every** usage - a taxi and a police car
are the same colour, and the panel text is what tells them apart.

**System B - `YemenNorthernPlates`.** The 1993 format, still in force across the
Houthi-controlled north and still the larger share of the fleet on the road.
Two stacked registers split by a horizontal rule: the governorate code (1..22,
one or two digits) above, the vehicle serial (up to six digits, never
zero-padded) below, with `اليمن` and the usage word in a band across the top.
The **field colour is the usage** - blue private, yellow for hire, red
transport, green government, black military - and it is the first thing read.

They are two sibling namespaces with nothing shared between them. There is
deliberately **no** `YemenSystem` enum and **no** version flag selecting one at
runtime, because there is no before-and-after to select: which system a plate
belongs to is a fact about where the vehicle was registered. A host normally
knows that and reaches for one namespace.

**The south's own plates.** Some southern authorities issue their own, measured
off the article's artwork:

- `YemenGovernoratePlates` - Hadhramaut (H), Al Mahrah (M), Shabwah (W) and
  Marib (M): a coloured strip with the governorate letter, the name over the
  number. The strip colour is the usage - blue private, yellow for hire, red
  commercial, green government - and rides on `YemenCountry.southernFor`.
  Temporary (مؤقت strip on the right), police (الشرطة band, `HP`/`WP` prefix)
  and motorcycle layouts where the article shows them.
- `YemenAdenPlates` - Aden's black-on-white lighthouse plate, 520 x 110 and
  335 x 170.
- `YemenTaizPlates.temporary` - Taiz's ج-ي / مؤقت-تعز plate; the class is the
  theme (`YemenThemes.taizPrivate` blue, `taizCommercial` red).

Validate them with `YemenSouthernValidator`. Their digits are ~80-87% of the
reference height (the tallest box that fits); the doc comments give the numbers.

**Riyadh - `RiyadhPlates`.** Three letters and up to four digits, each printed
twice (Arabic above, Latin below), in the US and EU sizes; five categories
(private, public transport, commercial, temporary, diplomatic) told apart by
the strip colour, which rides on `RiyadhCountry.byCategory`. Theme
`RiyadhThemes.standard`, validator `RiyadhValidator`, alphabets
`RiyadhAlphabets` (from `plate_alphabet`).

## Depends on

`plate_core` alone - not `plate_keypad`, not `iran_plate`, not `palestine_plate`,
not `plate_core_bloc`. `plate_keypad` appears only in `example/`.

## Use

```dart
import 'package:plate_core/plate_core.dart';
import 'package:yemen_plate/yemen_plate.dart';

// System A: a private car with a five-digit number.
PlateCanvas(
  spec: YemenUnifiedPlates.car5,
  country: YemenCountry.unifiedFor(YemenUsage.private),   // خصوصي / PRIV. in the panel
  theme: YemenThemes.forUnifiedUsage(YemenUsage.private),
  validator: const YemenUnifiedValidator(),
  onChooseCharacter: (a) async => null,      // every slot here is typed
);

// System B: two governorate digits, a five-digit serial, for hire.
PlateCanvas(
  spec: YemenNorthernPlates.carGov2Serial5,
  country: YemenCountry.northernFor(YemenUsage.forHire),     // اجرة in the top band
  theme: YemenThemes.forNorthernUsage(YemenUsage.forHire),   // the yellow IS the class
  validator: const YemenNorthernValidator(),
  onChooseCharacter: (a) async => null,
);
```

Or look a geometry up by its shape - the length is what varies the slot list,
and it is the only thing that does:

```dart
YemenUnifiedPlates.car(numberDigits: 6);                             // or null
YemenNorthernPlates.car(governorateDigits: 2, serialDigits: 5);      // or null
```

Both return null for a shape this package does not build; `carGeometries` and
`motoGeometries` are the maps behind them. Neither takes a usage, because a
usage never changed a cell. `YemenUsage.onUnified` and `.onNorthern` say which
system issues which, if you want to grey an option out - `police` is System A
only and `military` System B only.

`example/` is one plate, the shortest thing that runs. Every geometry crossed
with every usage its system issues - alongside the other countries' - is in the
repo's `plate_gallery/` app, which walks the geometry maps above and passes the
usage as a `country:`, exactly as a host does.

## Pick the shape before entry begins

Every *layout* is a separate spec, because the number of cells differs - and
nothing else is, because nothing else changes a cell. Swapping
`spec:` on a live `PlateCanvas` carries the value across by group key (the
`plate_core` default): a shared register survives, a digit that no longer fits is
truncated. It no longer empties the plate - but a governorate serial reinterpreted
under a different length is still rarely what the user meant, so present the system,
usage and register lengths first, then the plate. Pass `onSpecChange:` for `byIndex`
or `none`.

## Colour

On System B the theme is not decoration. A green plate is a government vehicle;
the same spec under `YemenThemes.northernPrivate` is a claim that it is a
private one. `YemenThemes.forNorthernUsage(usage)` is the way to get the right
one without naming a colour anywhere in your code.

The specs themselves carry no colour at all - a spec is geometry, a theme is
colour, and `plate_core` keeps them apart. A spec does name a `country`, but
only as the default for a caller that passes none: every spec here defaults to
private. The northern usage word rides on `PlateCountry.captionLines` over a fully
**transparent** panel: transparent rather than the field colour, so that pairing
a spec with the wrong theme cannot paint a wrong-coloured block on the plate.

Military plates come in two printings - the classic black field with white text
and a newer white field with red text. That is a `YemenMilitaryStyle` passed to
the theme, not a sixth usage: same layout, same grammar, two colours.

## Governorates

`YemenGovernorate` carries all 22 with their codes, English and Arabic names,
and an advisory `underHouthiControl` flag. That flag is **exposed and never
enforced** - no validator consults it, no lookup filters on it. Territorial
control is contested, changes, and does not follow governorate boundaries; the
flag is a coarse hint for a host that wants to explain something to a user, and
it is not a fact about a licence plate.

## Fonts

This package ships no font and names no font family, and - unlike
`palestine_plate` - a host cannot supply one either. `PlateCanvas` wraps its
whole face in `Theme(data: ThemeData.light().copyWith(...))` to pin the cursor
and selection colours, and the `Material` beneath that installs *that* theme's
default text style. `PlateTheme.glyphStyle` sets no `fontFamily`. So labels, the
panel caption and every slot glyph render in the platform default no matter what
the app theme says, and the example bundles no substitute face because bundling
one would have changed nothing.

The consequence is visible and it is measurable. Core sets a glyph at
`0.72 * cellHeight`, so in Roboto - cap 0.711 em, digit advance 0.562 em - a
cell yields `0.512 * cellHeight` of cap height but needs `0.41 * cellHeight` of
width per digit. System A's plates are set in FE-Schrift and System B's Arabic
in a square Kufic, both far narrower than that.

On the unified car this is what caps the digits at about 0.46 of the plate
against a measured 0.557: matching the photograph would need a cell 318 units
tall on a 292-unit canvas, where the glyphs would fit but their underlines would
fall off the plate. The number zone is widened to claw back what it can. The
northern plate is not width-bound - its registers are short enough that Roboto
fits at the measured cap.

The same cause has a second, harsher effect on the Arabic labels. Core renders a
`PlateLabel` as a plain `Text` inside a fixed-width box, so a string set wider
than its box does not overhang — it wraps, and the wrap clips. `اليمن` measured
off a photograph is a run of square Kufic; asked for at that width in the
platform's much wider fallback face it overruns and comes out as `الي`. So the
northern labels are not set at their measured size: the car's box is widened
past the measured run and centred on it, and the motorcycle's — which has no
spare field to widen into — has its glyph height cut instead.

Fixing both properly needs a `fontFamily` on `PlateTheme.glyphStyle` (or a
`TextStyle` hook on `PlateSpec`) in `plate_core`. With the plate's own faces
installed, these boxes would go back to their measured sizes.

## Contains

- `YemenUsage` - five classes, each system's own printing of the word, and which
  system issues which. Plus `YemenMilitaryStyle`.
- `YemenGovernorate` - 22 governorates, codes 1..22, `underHouthiControl`.
- `YemenColors` - every colour both systems print in.
- `YemenAlphabets.digits` / `.governorateTens`.
- `YemenCountry` - six unified side panels, six northern usage words.
- `YemenThemes` - one for System A, six for System B, and the two lookups.
- `YemenUnifiedPlates` - 6 specs: car and motorcycle x 4/5/6 number digits.
- `YemenNorthernPlates` - 4 car specs, plus 1 motorcycle spec marked
  `@Deprecated`.
- `YemenGovernoratePlates`, `YemenAdenPlates`, `YemenTaizPlates` - the
  southern plates, plus `YemenThemes.southern` / `aden` / `taizPrivate` /
  `taizCommercial` and `YemenCountry.southern*` / `plain`.
- `YemenUnifiedValidator` / `YemenNorthernValidator` / `YemenSouthernValidator`
  - advisory, never bar a keystroke.
- `YemenUnifiedSerialGenerator` / `YemenNorthernSerialGenerator` - seeded, pure
  Dart, for demos and fixtures.

## What it does not ship

**No dimensions from a standard.** No published Yemeni plate standard with
millimetre dimensions was available, so nothing here is a manufacturing
dimension and this package should not be used as one.

The **car** geometry of both systems is nonetheless measured, off photographs of
issued plates, as fractions of the plate's width and height. The class docs of
`YemenUnifiedPlates` and `YemenNorthernPlates` give the fractions beside the
units they produce, so a reading can be checked. The unified car canvas is
1024 x 292 (aspect 3.51) and the northern car canvas 540 x 288 (aspect 1.875);
both were wrong before those photographs were measured.

What is still `// CALIBRATE` is what no photograph covered: both motorcycle
layouts, the stipple's dot pitch on the unified plate, and every colour - the
colours are sampled by eye, not specified.

One consequence of the measurement is visible and is not a bug. The digits are
shorter, relative to the plate, than a photograph shows - about 0.46 of the
plate against a measured 0.557 on the unified car. That gap is the font, not the
geometry; see `## Fonts` below.

**No emblem.** The 2026 unified plate carries an eagle emblem. No artwork was
sourced at a resolution worth shipping, and drawing an approximation of a state
emblem and presenting it as the real one is not something this package will do.
So it ships no images at all and its `pubspec.yaml` has no `flutter: assets:`
block.

**No motorcycle plate you should trust.** No official motorcycle design has been
published for either system, despite active registration campaigns in Sanaa and
Taiz, and no photograph of one was available to measure. `YemenUnifiedPlates`'
motorcycle specs are the car layout reflowed into a square canvas, and
`YemenNorthernPlates`' are marked `@Deprecated('unverified geometry - calibrate
against photographs')` so that nothing trusts them silently.

The northern motorcycle layout is at least *derived* rather than guessed: both
canvases are 288 units tall, so it keeps the car's measured vertical bands, and
renormalises the car's measured width ratios onto the narrower canvas. A
photograph could still move its horizontal numbers; it would leave the vertical
ones alone. The one band that does not keep its measured height is `اليمن` in
the top band, set smaller than measured so it fits its box — see `## Fonts`. (Marib classifies motorcycles as yellow. That is Marib's rule and this
package does not generalise it to other governorates.)

**No meaning for the System A side code.** The two digits stacked in the blue
panel are widely described as encoding a governorate and a year of issue, but
nothing establishes which digit is which, or whether the governorate half uses
the 1..22 numbering `YemenGovernorate` carries. So the validator checks the code
for shape - two digits - and nothing else, and the generator does not draw it
from the governorate range. A range check here would be a guess wearing the
clothes of a rule.

**No usage word for two northern classes.** No source names the Arabic printed
on a green (government) or a military northern plate, so those country blocks
carry `اليمن` alone rather than a word copied across from the unified system's
table.

**Nothing about who controls what.** See "Governorates" above.

## Also available

- [`plate_core`](https://pub.dev/packages/plate-core) - Paint license plates.
- [`plate_alphabet`](https://pub.dev/packages/plate-alphabet) - A library of alphabets for license plates.
- [`plate_keypad`](https://pub.dev/packages/plate-keypad) - A character picker for license plates.
- [`plate_number_holder`](https://pub.dev/packages/plate-number-holder) - A frame to hold license plate numbers.
- [`algeria_plate`](https://pub.dev/packages/algeria-plate) - Algeria's licence plates.
- [`bolivia_plate`](https://pub.dev/packages/bolivia-plate) - Bolivia's licence plates.
- [`colombia_plate`](https://pub.dev/packages/colombia-plate) - Colombia's licence plates.
- [`cuba_plate`](https://pub.dev/packages/cuba-plate) - Cuba's licence plates.
- [`germany_plate`](https://pub.dev/packages/germany-plate) - Germany's licence plates.
- [`india_plate`](https://pub.dev/packages/india-plate) - India's licence plates.
- [`indonesia_plate`](https://pub.dev/packages/indonesia-plate) - Indonesia's licence plates.
- [`iran_plate`](https://pub.dev/packages/iran-plate) - Iran's licence plates.
- [`iranshahr_plate`](https://pub.dev/packages/iranshahr-plate) - Iranshahr region's licence plates.
- [`lebanon_plate`](https://pub.dev/packages/lebanon-plate) - Lebanon's licence plates.
- [`malaysia_plate`](https://pub.dev/packages/malaysia-plate) - Malaysia's licence plates.
- [`mali_plate`](https://pub.dev/packages/mali-plate) - Mali's licence plates.
- [`niger_plate`](https://pub.dev/packages/niger-plate) - Niger's licence plates.
- [`palestine_plate`](https://pub.dev/packages/palestine-plate) - Palestine's licence plates.
- [`sudan_plate`](https://pub.dev/packages/sudan-plate) - Sudan's licence plates.
- [`tunisia_plate`](https://pub.dev/packages/tunisia-plate) - Tunisia's licence plates.
- [`venezuela_plate`](https://pub.dev/packages/venezuela-plate) - venezuela_ licence plates.
