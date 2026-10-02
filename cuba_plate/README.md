# cuba_plate

Cuba's 2013 licence plates for [core_plate](../core_plate).

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
