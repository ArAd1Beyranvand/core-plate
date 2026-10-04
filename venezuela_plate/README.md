FREE PALESTINE 🇮🇷🇵🇸 پاینده ایران

GO VEGAN 🌱

==================================

From the mighty people of Iran to the bold people of Venezuela to view examples:

https://platexample.ir/#/discover/venezuela

# venezuela_plate

Venezuela's 2008 licence plate for [`plate_core`](https://pub.dev/packages/plate_core).

| Spec | Size (mm) | Format | Notes |
|---|---|---|---|
| `VenezuelaPlates.car` | 300 × 150 | `AB174SK` | Navy on the flag; the last letter is the state |

The flag is the background: white, then yellow, blue and red bands rising
5.7° to the right, painted with `PlateFill.stripes` (plate_core 0.11.2). The
state name under the serial is a mirror of the last cell through
`VenezuelaAlphabets.stateName`, so it follows whatever letter is typed.

`VenezuelaValidator` is advisory: it checks the last letter names a state and
the six serial cells follow one of the article's 19 seven-character category
patterns (`LLDDDL` private car, `7LDLDL` taxi, ...). `categoryOf` names the
category.

## Sources and accuracy

Measured from three photographs on Wikimedia Commons (AB174SK Lara, AA064ST
Trujillo, AE328KG Carabobo), each perspective-corrected to 300 × 150.

- Positions match to ~2 mm: caption x 30.5..273.2 against 31.2..272.8; flag
  boundaries within 2 mm at both ends; the state name at the measured height.
- **The serial is about 55% of reference height** (40 against 74 mm). The real
  face is very condensed; `plate_core` scales each glyph down to its cell
  width, and the fallback font is too wide to stand 74 mm tall in a 38.9 mm
  cell. The caption is ~60% for the same reason. A condensed font in the theme
  would fix both; plate_core has no per-theme font today.
- The real bands fan and wave slightly; one angle is the fit.
- The white airbrushing is a `PlateFog`: saturated colours at the ends, pale
  in the middle. The photographs' fade is sharper at the red band's ends than
  one ellipse can be.
- Colours marked `// CALIBRATE` are from photographs, white-balanced on the
  field.

Not implemented: the pre-2008 series; the motorcycle plate (smaller, size not
documented); the yellow provisional and Free Port plates; the eight stars, the
microprint.

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
- [`yemen_plate`](https://pub.dev/packages/yemen-plate) - Yemen's licence plates.
