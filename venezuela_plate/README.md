# venezuela_plate

Venezuela's 2008 licence plate for [core_plate](../core_plate).

| Spec | Size (mm) | Format | Notes |
|---|---|---|---|
| `VenezuelaPlates.car` | 300 × 150 | `AB174SK` | Navy on the flag; the last letter is the state |

The flag is the background: white, then yellow, blue and red bands rising
5.7° to the right, painted with `PlateFill.stripes` (core_plate 0.11.2). The
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
  face is very condensed; `core_plate` scales each glyph down to its cell
  width, and the fallback font is too wide to stand 74 mm tall in a 38.9 mm
  cell. The caption is ~60% for the same reason. A condensed font in the theme
  would fix both; core_plate has no per-theme font today.
- The real bands fan and wave slightly; one angle is the fit.
- Colours marked `// CALIBRATE` are from photographs, white-balanced on the
  field.

Not implemented: the pre-2008 series; the motorcycle plate (smaller, size not
documented); the yellow provisional and Free Port plates; the eight stars, the
microprint and the airbrushed fade at the plate's ends.
