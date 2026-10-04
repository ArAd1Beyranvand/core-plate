FREE PALESTINE 🇮🇷🇵🇸 پاینده ایران

GO VEGAN 🌱

==================================

https://platexample.ir/#/discover/india

# india_plate

India's current licence plates for [`plate_core`](https://pub.dev/packages/plate_core) — the 1989 format on the HSRP plate, in every colour class.

## What is here

One 500 × 120 layout (the article's light-motor-vehicle size). The format is
the spec, the colour class is the theme:

| Spec | Format | Themes |
|---|---|---|
| `private` | MH 20 DV 2366 + chakra and IND | `private` |
| `standard` | MH 12 DV 4353 | `transport`, `rental`, `electric`, `electricTransport` |
| `bharat` | 21 BH 2345 AA + badge | `private` |
| `vintage` | MH VA AA 0000 + badge | `private` |
| `diplomatic` | 52 CD 19 | `diplomatic`, `consular` |
| `military` | ↑ 02 B 084821 H | `military`, `militaryPolice`, `electric` |
| `temporary` | T 1123 KL 5986 KA | `temporary` |
| `trade` | UP 16 C 0002 TC 0073 | `trade` |

Printed letters that are part of a format (BH, VA, TC, T, ↑) are labels, not
cells. `IndiaValidator` judges any of the specs by the groups it has.

## Sources and measurements

Geometry and every colour come from the colour-class artwork that came with the
task (private, commercial, rental, embassy, electric). Each plate in it is
850 × 183 px (4.65:1). It is normalised to 500 × 120 with x read
proportionally. Wikipedia's colour table gives only CSS keywords, so it decides
which colour goes where but never the value. Trade, temporary and military
police use the artwork's own red, `DB351F`.

| | reference | golden |
|---|---|---|
| plain row ink x | 48.2..450.6 | 47.4..447.4 |
| private row ink x | 71.8..474.1 | 70.4..470.4 |
| row ink centre y | 60.3 | 60.2 |
| IND x / y | 15.9..44.1 / 57.0..71.5 | 16.4..43.4 / 57.2..67.8 |
| chakra x / y | 14.7..42.4 / 21.0..52.5 | 15.1..41.4 / 23.0..49.3 |
| row ink height | 78.7 | 29.6 |

### The characters are ~38% of reference height

The plate's face is a tall condensed one. Each cell is 41.4 wide. A cell scales
down any glyph wider than itself, and the fallback bold M is about 0.86 em, so
55 is the largest slot where every capital keeps the same height. Getting to
78.7 would need a condensed face in the theme. `plate_core` has no hook for
that, and changing `glyphStyle` would move every country.

## Not implemented

- Plates before 1989, and the president's and governors' emblem plates.
- One- and three-letter RTO series, and the three-letter IOD mission type.
  Each of these needs a different number of cells.
- The laser-etched serial under IND, and the hologram's shimmer.
- Two-wheeler and commercial-vehicle plate sizes.

## Also available

From the mighty people of Iran to the people of India to view examples:

- [`plate_core`](https://pub.dev/packages/plate_core) - Paint license plates.
- [`plate_keypad`](https://pub.dev/packages/plate_keypad) - A character picker for license plates.
- [`iran_plate`](https://pub.dev/packages/iran_plate) - Iran's plates.
- [`germany_plate`](https://pub.dev/packages/germany_plate) - Germany's plates.
- [`palestine_plate`](https://pub.dev/packages/palestine_plate) - Palestine's plates.
- [`yemen_plate`](https://pub.dev/packages/yemen_plate) - Yemen's plates.
- [`plate_core_bloc`](https://pub.dev/packages/plate_core_bloc) - The optional bloc layer for `plate_core`.
