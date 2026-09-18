# germany_plate — research notes

Source: <https://en.wikipedia.org/wiki/Vehicle_registration_plates_of_Germany>
(full wikitext in `SOURCE_wikipedia.wikitext`), fetched 2026-09-15.
101 reference images in this directory, downloaded from Wikimedia Commons at 900px.

Reference material only — **not** a publishable package asset directory. Anything
vendored into `germany_plate/assets/` must be copied there deliberately and its
licence recorded.

## 1. The format we get wrong today

`GermanPlates.car` hard-codes 2 district letters + 1 identifier letter + 4 digits.
The real rule (FZV, Appendix 1):

> "an area code of one, two or three letters, followed by an identifier sequence of
> one or two letters and one to four digits. The total quantity of characters on the
> plate must not exceed eight."

The Erkennungsnummer is not free within those bounds — it falls into exactly five
issued groups:

| Group | Letters | Digits | Range | Combinations |
|---|---|---|---|---|
| a | 1 | 1–3 | A1 – Z999 | 25,974 |
| b | 2 | 1–2 | AA1 – ZZ99 | 675,324 |
| c | 2 | 3 | AA100 – ZZ999 | 608,400 |
| d | 1 | 4 | A1000 – Z9999 | 234,000 |
| e | 2 | 4 | AA1000 – ZZ9999 | 6,084,000 |

> "Not every group is issued by every authority and group e cannot be combined with
> three-letter area codes."

Group e + 3-letter area code would be 3+2+4 = 9 > 8, so that exclusion is the
8-character cap restated. Every other combination of (1–3 area letters × groups a–e)
fits in 8.

Other hard rules from the text:

- **No leading zero in the serial.** "A James Bond fan from Hamburg would not be
  allowed the plate HH-JB 007 because leading digits 0 (or even double-0) are not
  possible." (Confirms the guess in the previous pass — it is a real rule.)
- **Letters and digits never interleave.** "nor may letters and digits be mixed at
  will" (`VW-P0 L01` is impossible).
- **All 26 Latin letters are now legal in the identifier.** B, F, G were re-allowed in
  1992; I, O, Q in 2000. The old exclusion (B/8, F/E, G/6, I/1, O/Q/0) is history —
  a validator that still bars them is wrong for anything issued after 2000.
- **Umlauts are area-code-only.** Ä, Ö, Ü may appear in the area code; ẞ may not.
  An umlaut in the *identifier* is the canonical marker of a fake plate — film crews
  use it deliberately ("the crew could use an impossible identifier, such as an umlaut
  in this middle section").
- **The gap is significant.** `F ST 683` ≠ `FS T 683`. Our `district`/`letters` groups
  already model this correctly.

## 2. Physical geometry

| Plate | Size (mm) | Glyph height | Letter / digit width |
|---|---|---|---|
| Car, one line (current spec) | 520 × 110 | 75 | 47.5 / 44.5 |
| Car, two lines | 340 × 200 | 75 | 47.5 / 44.5 |
| Motorcycle, large, until 2011 | 280 × 200 | 75 | 47.5 / 44.5 |
| Motorcycle, since 2011 | 180 × 200 or 220 × 200 | 49 | 31 / 29 |
| Light motorcycle / tractor ≤40 km/h | 255 × 130 | 49 | 31 / 29 |

> "Plates bearing few characters may have reduced length but must retain the size and
> shape of the characters."

So a short plate is a **shorter plate**, not a wide-tracked 520 one — see
`German_Licence_Plate_N-M4.jpg` (`N ⊙ M 4`). Our fixed 520 canvas is wrong for short
combinations. Letters are wider than digits (47.5 vs 44.5), which the current spec
already approximates (52 vs 46 at our scale).

Typeface is **FE-Schrift** since 1994, mandatory from 2000; DIN 1451 before that.
Euroband: blue strip, 12 gold stars, white `D`.

## 3. Sticker placement — the photos correct our layout

Across `Germany_Cuxhaven_...`, `Zwickau_license_plate.JPG`, `Licence_plate_N-A_5_...`,
`German_Licence_Plate_N-M4.jpg`, `2007_Baden-Württemberg_...`:

The two stickers sit **immediately after the last area-code letter**, and the
identifier letter begins immediately after them. They are part of the character flow,
not a fixed-position pair in a fixed gap. On the one-letter Zwickau plate (`Z ⊙ LA 66`)
they are at x ≈ one letter in; on `CUX ⊙ DP 150` they are three letters in. Our
`PlateDecal` boxes at a literal `left: 184` only work for the 2-letter district.

Stacking order, top to bottom: **HU (safety-test) sticker above, registration seal
below**. Diameters: seal 45 mm current (35 mm pre-1994); both roughly the same size on
the plate.

- The HU sticker is **rotated so the expiry month points to 12 o'clock** — that is how
  it is read. See `Kfz-Kennzeichen_Deutschland_-_Toepfchensiegel.jpg`, where the whole
  disc is turned so `6` is at the top. The black arc framing `11–12–1` is the fixed
  reference mark. Our current asset is drawn upright and cannot express a month.
- Year is both printed in the centre (`07`, `19`, …) **and** colour-coded on a 6-year
  cycle: brown 1974+6n, pink 1975+6n, yellow-green 1976+6n, lemon-yellow 1977+6n, sky
  blue 1978+6n, yellow-orange 1979+6n. So **2026 is sky blue** (RAL 5015 `#2874b2`),
  2025 yellow-orange (RAL 2000 `#dd7907`), 2027 lemon yellow (RAL 1012 `#d9c022`),
  2024 yellow-green (RAL 6018 `#48a43f`), 2028 copper brown (RAL 8004 `#8f4e35`),
  2029 light pink (RAL 3015 `#e1a6ad`).
  Our shipped `de_inspection_sticker.png` is orange with `19` — a 2019 sticker, now
  three years stale and the wrong colour for any current year.
- A **hexagonal** orange sticker on the *front* plate was the emission test, 1985–2010,
  abolished. `Germany_plate_Hesse_FST_683.jpg` shows one. Front plates issued after
  2010 carry **no sticker at all** (`Licenceplate_of_Germany_Kreis_Steinburg.JPG`).
- The seal carries the *Bundesland* arms plus the state name and issuing district in
  print — it is per-district, not one national image. Ours is fixed to Thüringen.

Both `Plakette_Hauptuntersuchung.svg` and `Plakette_Abgassonderuntersuchung.svg` are
**public domain** (author: Bundesrepublik Deutschland) per the Commons API, as is
`Zulassungsplakette_Coburg.png`. Safe to vendor. Note that state coats of arms are
separately regulated as official emblems even where not copyrighted — a generic or
stylised seal is the safer default for a demo package.

## 4. Variants, and what each one actually changes

Ordered roughly by implementation cost.

| Variant | Ink | Euroband | Layout change | Image |
|---|---|---|---|---|
| Standard car | black | yes | — | `2007_Baden-Württemberg_...png` |
| Green / tax-exempt | **green** | yes | none | `..._steuerbefreite_Fahrzeuge_(grüne_Schrift).jpg` |
| H historic | black | yes | `H` appended after digits, no gap | `Historic_license_plates_of_Lübeck.jpg` |
| E electric | black | yes | `E` appended after digits, no gap | `German_electric_car_license_plate.jpg` |
| Seasonal | black | yes | two 2-digit months stacked with a rule between, at the right end | `German_licenseplate_valid_from_March_to_October.JPG` |
| 07 collector | **red** | yes | 5 digits starting `07`, **seal only, no HU sticker** | `Oldtimer_plate_Kreis_Stendal.JPG` |
| 06 dealer | **red** | yes | digits start `06` | `Rotes_DIN-Kennzeichen_06.jpg` |
| Kurzzeit (04) | black | **none** | plain white left edge; 5 digits starting `04`; one small seal; **yellow band on the right**, date stacked DD/MM/YY on three lines | `Deutsches_Kurzzeit-KFZ-Kennzeichen.jpg` |
| Export | black | **none** | as above but a **red** right band | `Deutsche_Ausfuhr-Kfz-Kennzeichen_(Export).jpg` |
| Wechselkennzeichen | black | yes | small superscript `W` above the seal, plus a **separate companion plate** on the right carrying the HU sticker, the varying final digit, and the main number in tiny print | `Special_license_plate_Germany_Berlin.JPG` |
| Diplomatic | black | yes | `0` then stickers then `NN-NN`, **printed hyphen**; leading zero legal here | `Deutsches_Diplomatenkennzeichen_(Indonesien).jpg` |
| Bundeswehr `Y` | black | **German flag block**, narrower | `Y-NNN NNN`, printed hyphen, Bundeswehr seal only, no HU sticker, non-reflective | `Deutsches_Bundeswehr-Kfz-Kennzeichen.jpg` |
| NATO `X` | black | flag block | `X-NNNN` | — |
| THW / BP / BW / BD | black | yes | letter code then 5 digits, federal eagle seal (`THW-94091`, all numbers start 8 or 9) | `License_plate_of_Technisches_Hilfswerk_in_Germany.JPG` |
| Pre-2006 authority | black | yes | district + number only, **no identifier letters** (`M-1234`) | `..._Behördenfahrzeuge_(Nummernbereich_3).jpg` |
| Highest state offices | black | yes | `0-1` … `0-4`, `1-1` | `Licenseplate_of_limousine.png` |

Note that several of these (04, export, 07, THW, Y) use **5–6 digits** and therefore
break both the 4-digit register and the 8-character cap. They are not "the car spec
with a colour swapped" — they are separate specs.

## 5. Prohibited and reserved combinations, as documented

Nationwide-avoided two-letter identifier blocks: `NS`, `KZ`, `HJ`, `SS`, `SA`.
Also avoided as a district+first-letter *combination* spanning the gap — which our
validator does not currently model:

`H-J`, `N-S`, `K-Z`, `S-A`, `S-D`, `S-S`, `STA-SI`, `S-ED`, `SE-D`, `HE-IL`, `HEI-L`,
`IZ-AN`, `WAF-FE`, `BUL-LE`, `MO-RD`, `TO-D`, `KI-LL`, `SU-FF`, `N-PD`, `N-SU`, `HF-Z`.

Digits: `88`, `18`, `14`; Brandenburg additionally bars `1888`, `8818`, `8888` and
anything ending `88`, `888`, `188`, plus `AH 18` and `HH 18`.

`IS` is banned by *some* districts only (2010s). Explicitly **permitted**: `AC-AB`,
`S-EX`, `SE-X`, `SE-XY`. `HH` and `AH` are legal *area codes* (Hansestadt Hamburg,
Ahaus) — our validator correctly bars them only as identifier letters.

Reserved: `DD-Q` (Saxony police), `EF-LP` (Thuringia police), `M-PM`, `N-PP`, `RO-P`,
`K-TX` (Cologne taxis), `K-LN`, `FW` (fire brigades), `B-FA` / `BN-AA` (embassy staff).

The decision is per-authority and changes over time — the existing "advisory, not a
registration guarantee" framing in `german_plate_validator.dart` is the right posture
and should stay.
