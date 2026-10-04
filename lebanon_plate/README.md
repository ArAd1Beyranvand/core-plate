FREE PALESTINE 🇵🇸🇮🇷 پاینده ایران

GO VEGAN 🌱

==================================

https://platexample.ir/#/discover/lebanon

# lebanon_plate

Lebanon's licence plates for [`plate_core`](https://pub.dev/packages/plate_core) — two plate shapes, many plate colours. It's data, not code: 2 standard `PlateSpec`s (12 with short-number variants), one country family, two alphabets, eight themes, one validator and one generator. `plate_core` paints everything.

A usage class is **not** a spec. It is a `PlateTheme` (the field colour) and a
`PlateCountry` (the Arabic word on the band), and both are handed to the canvas
at render time beside the spec.

## Two shapes, many colours

This is the thing to read first, because it is the opposite of most of the
systems this workspace models. Lebanon does not cut a new geometry per class of
vehicle. Every plate is **a letter, then up to six digits, with a blue
identification band carrying the cedar and لبنان**. What changes is the colour
it is printed on.

**`LebanonPlates.oneLine`** - the long plate, European 520 x 110 proportions,
band down the left edge.

**`LebanonPlates.twoLine`** - the shorter, taller plate, band across the top.

Both are current. Which one a vehicle carries is a matter of what fits its
mounting, not of what it is for, so there is deliberately no enum selecting
between them.

## The two axes, and why they are two types

| | what it is | where it lands |
| --- | --- | --- |
| `LebanonUsage` | the **field colour** | `LebanonThemes.forUsage` |
| `LebanonLetter` | the **letter** before the number | the first slot's value |

They cross rather than nest, which is why one enum could not do the job:

- `B 123456` and `Z 123456` are the same usage (private, white) and different
  letters (Beirut, Zahleh).
- A red مؤسسات plate and a yellow driving-school plate both carry `M`.

### The colours

| usage | field | letter |
| --- | --- | --- |
| `private` | white | the town - see below |
| `consular` | purple | `C` |
| `diplomatic` | orange | `D` |
| `publicInstitution` | red | `M` |
| `publicTransport` | red † | `P` |
| `drivingSchool` | yellow | `M` |
| `transit` | green | - |
| `temporary` | brown | - |
| `tourism` | pink | - |

† Inherited, not attested: `P` plates were split out of the red `M` series and
no source consulted names their current field. See the TODO on that enum value.

### The letters

`A` is the pre-1998 general series (and trades as a vanity plate). `B` Beirut,
`Y` Aley, `G` Jounieh, `N` Nabatieh, `O` Ouzai, `S` Sidon, `T` Tripoli,
`K` Baalbek (documented, no longer issued), `Z` Zahleh. `J` judicial,
`R` religious official, `M` motorcycle/commercial, `MP` parliament (numbered
1..128), plus the `C` / `D` / `P` class letters above.

`MP` is one character in `LebanonAlphabets.letters` and two glyphs on the face,
which is why that alphabet is `AlphabetInput.chosen` and why the letter cell is
wider than a digit cell.

## Using it

```dart
const usage = LebanonUsage.diplomatic;

PlateCanvas(
  spec: LebanonPlates.oneLine,
  country: LebanonCountry.forUsage(usage), // the band's caption
  theme: LebanonThemes.forUsage(usage),    // the field colour
  validator: const LebanonValidator(),
  autoValidate: true,
  onChooseCharacter: (alphabet) async => null, // a real host shows a picker
)
```

Short numbers - a motorcycle `M` plate, a parliament `MP` plate - are the same
faces with fewer digit cells:

```dart
LebanonPlates.oneLineOf(digits: 3); // null for a length this package does not build
```

The cells keep the six-digit pitch and stay left-aligned against the letter,
because that is what a short number on a full-size plate looks like.

## Validation

`LebanonValidator` is advisory, gated on the `serial` group (quiet until the
number has something in it), and never bars a keystroke. Lebanon's grammar gives
it very little: a closed letter set, a one-to-six digit number, and the single
documented range in the system - `MP` is 1..128. There is no published block
allocation, no check digit and no per-town range, so `B 000001` and `B 999999`
are equally well-formed as far as anything public says.

It deliberately does **not** reject the out-of-service `K` letter (those plates
are on the road) or a leading zero (nothing establishes the padding rule).

## Depends on

`plate_core` alone - not `plate_keypad`, not any other country's package, not
`plate_core_bloc`.

## What it does not ship

**The cedar.** It is the signature of a Lebanese plate and it is not in this
package. No public-domain vector of the plate's cedar was sourced, and drawing
an approximation of a state emblem and shipping it as the real thing is not
something this package will do. Every `PlateCountry` here has `flag: null` and
every `PlatePanel` has `flagScale: 0`, which gives the band's height to its text
instead of reserving a strip for an image that does not exist. A host with
rights to a cedar asset can pass its own `PlateCountry`.

**A font.** `PlateTheme` names no font family and `plate_core` offers no hook to
give one to a label, so a font bundled here could not reach the لبنان on the
band. Supplying a face to the subtree is the host's job, via its own `Theme` or
`DefaultTextStyle`. Without one, Arabic band text falls back to whatever the
platform has - which on a CI runner is often nothing, and is why the goldens in
`test/` show boxes.

**Rotated band text.** On a real one-line plate the band's text runs vertically.
`plate_core` has no rotation, on a label or on a caption, so this package prints
it horizontally and scaled to fit. It is the one place where these specs
knowingly do not reproduce the plate, and no number in `lebanon_plates.dart`
would fix it.

**Measurements.** Every dimension and every colour here is marked `// CALIBRATE`.
The canvases are proportioned from photographs and the colours are named in
prose by the sources - "purple", "orange", "brown" - with no hex or ink
reference anywhere. Each value is the right hue family at roughly the right
value, and none of them is a measurement.

**The diplomatic numbering.** A `D` plate's number encodes a country code and a
car number rather than being a plain serial. This package draws it as six
digits and says nothing about the encoding.

## Also available

From the mighty people of Iran to the people of Lebanon to view examples:

- [`plate_core`](https://pub.dev/packages/plate_core) - Paint license plates.
- [`plate_keypad`](https://pub.dev/packages/plate_keypad) - A character picker for license plates.
- [`iran_plate`](https://pub.dev/packages/iran_plate) - Iran's plates.
- [`germany_plate`](https://pub.dev/packages/germany_plate) - Germany's plates.
- [`palestine_plate`](https://pub.dev/packages/palestine_plate) - Palestine's plates.
- [`yemen_plate`](https://pub.dev/packages/yemen_plate) - Yemen's plates.
- [`plate_core_bloc`](https://pub.dev/packages/plate_core_bloc) - The optional bloc layer for `plate_core`.
