FREE PALESTINE 🇵🇸🇮🇷 پاینده ایران

GO VEGAN 🌱

==================================

Yemen's licence plates for [`core_plate`](https://pub.dev/packages/core_plate) - a
country with two plate systems in force at the same time, in different halves of
it.

## Also available

- [`core_plate`](https://pub.dev/packages/core_plate) - Paint license plates.
- [`plate_keypad`](https://pub.dev/packages/plate_keypad) - A character picker for license plates.
- [`iran_plate`](https://pub.dev/packages/iran_plate) - Iran's plates.
- [`germany_plate`](https://pub.dev/packages/germany_plate) - Germany's plates.
- [`palestine_plate`](https://pub.dev/packages/palestine_plate) - Palestine's plates.

# plate_yemen

It's data, not code: 55 `const PlateSpec`s, two country families, two digit
alphabets, seven themes, two advisory validators and two seeded generators.
`core_plate` paints all of it. There is not a widget in this package.

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

## Depends on

`core_plate` (`^0.1.0`). Nothing else - not `plate_keypad`, not `iran_plate`,
not `palestine_plate`. `plate_keypad` appears only in `example/`.

## Use

```dart
import 'package:core_plate/core_plate.dart';
import 'package:plate_yemen/plate_yemen.dart';

// System A: a private car with a five-digit number.
PlateCanvas(
  spec: YemenUnifiedPlates.car5Private,
  theme: YemenThemes.forUnifiedUsage(YemenUsage.private),
  validator: const YemenUnifiedValidator(),
  onChooseCharacter: (a) async => null,      // every slot here is typed
);

// System B: two governorate digits, a five-digit serial, for hire.
PlateCanvas(
  spec: YemenNorthernPlates.carGov2Serial5ForHire,
  theme: YemenThemes.forNorthernUsage(YemenUsage.forHire),   // the yellow IS the class
  validator: const YemenNorthernValidator(),
  onChooseCharacter: (a) async => null,
);
```

Or look one up:

```dart
YemenUnifiedPlates.byNumberLength(YemenUsage.forHire)[6];
YemenNorthernPlates.byDigits(YemenUsage.government)[(2, 5)];
```

Both lookups return an empty map for a usage their system does not issue -
`police` on System B, `military` on System A. `YemenUsage.onUnified` and
`.onNorthern` are the question to ask first if you want to grey the option out.

## Pick the shape before entry begins

Every layout is a separate spec, because the number of cells differs. Swapping
`spec:` on a live `PlateCanvas` dispatches `SpecIsChanged`, which **empties the
bloc** - correct, since a five-cell value cannot be reinterpreted in a six-cell
plate, but it means a length picker sitting beside the plate wipes it on every
tap. Present the system, usage and register lengths first, then the plate.

## Colour

On System B the theme is not decoration. A green plate is a government vehicle;
the same spec under `YemenThemes.northernPrivate` is a claim that it is a
private one. `YemenThemes.forNorthernUsage(usage)` is the way to get the right
one without naming a colour anywhere in your code.

The specs themselves carry no colour at all - a spec is geometry, a theme is
colour, and `core_plate` keeps them apart. The one place that rule bends is the
northern usage word, which rides on `PlateCountry.captionLines` over a fully
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

The consequence is visible: System A's plates are set in FE-Schrift and System
B's Arabic in a square Kufic, both far narrower than a default weight-700 face,
so the digits sit looser in their cells here than in a photograph. Fixing it
needs a `fontFamily` on `PlateTheme.glyphStyle` (or a `TextStyle` hook on
`PlateSpec`) in `core_plate`.

## Contains

- `YemenUsage` - five classes, each system's own printing of the word, and which
  system issues which. Plus `YemenMilitaryStyle`.
- `YemenGovernorate` - 22 governorates, codes 1..22, `underHouthiControl`.
- `YemenColors` - every colour both systems print in.
- `YemenAlphabets.digits` / `.governorateTens`.
- `YemenCountry` - six unified side panels, six northern usage words.
- `YemenThemes` - one for System A, six for System B, and the two lookups.
- `YemenUnifiedPlates` - 30 specs: car and motorcycle x 4/5/6 number digits x
  five usages.
- `YemenNorthernPlates` - 20 car specs, plus 5 motorcycle specs marked
  `@Deprecated`.
- `YemenUnifiedValidator` / `YemenNorthernValidator` - advisory, never bar a
  keystroke.
- `YemenUnifiedSerialGenerator` / `YemenNorthernSerialGenerator` - seeded, pure
  Dart, for demos and fixtures.

## What it does not ship

**No measured geometry.** Every dimension in this package is marked
`// CALIBRATE`. They are proportioned from photographs and published
descriptions, not measured from a standard - no published Yemeni plate standard
with millimetre dimensions was available. The same goes for every colour: they
are sampled by eye, not specified.

**No emblem.** The 2026 unified plate carries an eagle emblem. No artwork was
sourced at a resolution worth shipping, and drawing an approximation of a state
emblem and presenting it as the real one is not something this package will do.
So it ships no images at all and its `pubspec.yaml` has no `flutter: assets:`
block.

**No motorcycle plate you should trust.** No official motorcycle design has been
published for either system, despite active registration campaigns in Sanaa and
Taiz. `YemenUnifiedPlates`' motorcycle specs are the car layout reflowed into a
square canvas, and `YemenNorthernPlates`' are marked `@Deprecated('unverified
geometry - calibrate against photographs')` so that nothing trusts them
silently. (Marib classifies motorcycles as yellow. That is Marib's rule and this
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
