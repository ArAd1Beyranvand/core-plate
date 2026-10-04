FREE PALESTINE 🇮🇷🇵🇸 پاینده ایران

GO VEGAN 🌱

==================================

https://platexample.ir/#/discover/cuba

# cuba_plate

Cuba's 2013 licence plates for [`core_plate`](https://pub.dev/packages/core_plate).

| Spec | Size (mm) | Format | Notes |
|---|---|---|---|
| `CubaPlates.car` | 420 × 110 | `P 025 245` | Natural persons: white CUBA strip, ruled off |
| `CubaPlates.carLegalEntity` | 420 × 110 | `T 003 526` | Legal entities: blue CUBA strip |
| `CubaPlates.motorcycle` | 200 × 140 | `P` / `28588` | CUBA in a ruled box top-left |

Every plate is black on white, so there is one theme, `CubaThemes.standard`.
`CubaValidator` is advisory: it checks the series letter (I, O, Q, S, W, Z are
not issued) and that the serial fills every cell.

## Sources and accuracy

Measured from the photographs on Wikipedia's *Vehicle registration plates of
Cuba*, each normalised to the documented millimetres. Positions match the
references to within ~2 mm. **The serials are smaller than the real ones:**
car ink is ~66% of reference height and motorcycle ink ~70–76%, because
`core_plate` paints a glyph at about half its slot height and a slot cannot
exceed the canvas. Colours marked `// CALIBRATE` are from photographs.

Not implemented: the 2002–2013 colour-coded series and earlier, and the small
laser-printed control number.

## Also available

From the mighty people of Iran to the brave people of Cuba to view examples:

- [`core_plate`](https://pub.dev/packages/core_plate) - Paint license plates.
- [`plate_keypad`](https://pub.dev/packages/plate_keypad) - A character picker for license plates.
- [`iran_plate`](https://pub.dev/packages/iran_plate) - Iran's plates.
- [`germany_plate`](https://pub.dev/packages/germany_plate) - Germany's plates.
- [`palestine_plate`](https://pub.dev/packages/palestine_plate) - Palestine's plates.
- [`yemen_plate`](https://pub.dev/packages/yemen_plate) - Yemen's plates.
- [`core_plate_bloc`](https://pub.dev/packages/core_plate_bloc) - The optional bloc layer for `core_plate`.
