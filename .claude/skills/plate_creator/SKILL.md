---
name: plate_creator
description: "Implement or rebuild a country's licence plates end to end — Wikipedia research, reference-image measurement, architecture, spec, validators, Flutter implementation, golden verification. Invoke with /plate_creator <country>."
---

> **Run in a fresh session.** **Model:** Opus 5 · **extended thinking:** on.
> This is a long job. Budget for research and measurement taking longer than the code.

# Implementing a country's licence plates

## Read this first

The failure mode this skill exists to prevent is **a plausible-looking plate that is wrong**.
It compiles, it renders, it has the right general idea, and every number in it is invented.
That is what a previous pass produced for Kuwait, and correcting it took longer than writing
it would have. The specific shapes it took:

- **Colours taken from the article's prose.** The table says "orange", so the code said
  `0xFFFF6600`. The actual artwork is `0xFFE84433`, a red-orange. "Green" was a teal. Two
  different blues were collapsed into one because the prose called both "blue".
- **Geometry invented to look right.** Every coordinate was a guess that produced a plausible
  picture. None matched the reference.
- **Sixteen categories as sixteen copies.** Eleven of them were the same template with a
  different caption, written out eleven times, each with its own drifting magic numbers.
- **Never rendered.** No golden, no screenshot. One spec had a slot outside the canvas and
  threw an assertion the moment it was shown. Nobody had ever looked at it.
- **Text sized by eye.** Every row came out ~60% of reference size because nobody measured the
  relationship between the size you ask for and the ink you get.

Every one of those survives review by a model that is checking whether the code is reasonable.
None survives measuring the output against the reference. **Measure. Do not eyeball.**

---

## Phase 0 — Orient (do this before research)

Read, in this order:

1. `core_plate/CLAUDE.md` — the structural rules. Non-negotiable. Chief among them: no functions
   returning widgets, variation is data not code, no open-ended enums, fixed-canvas layout.
2. `core_plate/lib/src/model/plate_spec.dart` — the whole vocabulary you have to describe a plate.
3. One existing country package end to end. `yemen_plate/lib/` is the fullest example
   (colours, themes, alphabets, validators, generator, country, specs as separate files).
4. Do **not** read `plate_number_holder` yet — the gallery is the last step (see "Gallery").

### The single most important thing to understand before you write a coordinate

**There are no per-country CustomPainters or CustomClippers in this workspace, and you almost
certainly should not add any.** Every plate is declarative data: a `PlateSpec` holding
`PlateSlot`s, `PlateRule`s, `PlateLabel`s, `PlateBand`s, `PlateDecal`s, each positioned by a
`PlateBox(left, top, width, height)` in plate coordinates. `core_plate`'s generic `PlateCanvas`
paints all of it.

The prompt you were given may ask you to "review the CustomPainter/Clipper implementation" or to
separate "CustomPainters" and "CustomClippers" into their own folders. For this workspace that
instruction is usually vacuous — there is nothing there to review and nothing to separate. Say so
and move on. Only reach for a painter when the shape genuinely cannot be expressed as boxes,
rounded boxes and text — a crest, a hologram, a non-rectangular plate outline. A stadium/capsule
is **not** such a case: it is a `PlateBand` with both corner radii set to exactly `height / 2`.

Adding a painter to satisfy the letter of a prompt is how you get the poorly designed drawing
structure the prompt was complaining about in the first place.

### Design rule: everything painted goes on the background, in our own way

Anything that has to be *painted* — dividers, strips, SVG-style shapes, and simple flags that can
be drawn algorithmically (stripes, bands, crosses, discs) — is painted onto the background through
`PlateSpec.background` the way this workspace already does it. Do not download a flag/emblem image,
embed an asset, or add a per-country painter for something an algorithm can draw. Only a genuinely
complex emblem (a crest) may be a decal, and say why.

### Design rule: strips and dividers are the background, never boxes on it

**Any vertical strip, horizontal band or divider that runs to the plate's edge is painted as
part of the background — `PlateSpec.background`, a `PlateSection` tree — never as a box
(`PlateBand`, `PlateRule`, `PlateBox`-positioned anything) laid on top of the face.** This is not a
style preference; it is the rule since core_plate 0.11, and a spec that breaks it is wrong even if
the golden looks right.

- A coloured strip down the left/right side → `PlateSection.columns` with a
  `PlateSection.fill(PlateFill.panel)` (or `PlateFill.color(...)`) part ending at its x.
- A coloured band across the top/bottom → `PlateSection.rows` the same way.
- A line separating two regions, edge to edge → `PlatePart(..., divider: <thickness>)` on the
  part whose `end` it sits on. Not a `PlateRule`.
- A strip that is just the divider colour running out to the edge → `PlateFill.divider`.
- Nest `columns`/`rows` for compound layouts (a side strip plus a top band in the remaining area).
- Positions are plate coordinates (`end:`), **never offsets from the border**. Do not inset a strip
  to the frame's inner edge — the frame paints its border over the background, so the strip runs
  underneath it to the outer edge.
- `PlateBand` is reserved for a shape that **floats** inside a region and does not touch the plate
  edge (Kuwait's "C.D" capsule). `PlateRule` is for a short rule that does not split the plate.

Why: a box on the face has its own anti-aliased edges, so the white face shows through as a light
seam where it meets the border; and a box positioned against the border moves whenever a theme
changes the border width. The section tree has neither problem. See `lebanon_plates.dart`
(`_oneLineBackground`, `_twoLineBackground`) and `yemen_plate` for working examples, and
`PlateSection`/`PlatePart` in `plate_spec.dart` for the vocabulary.

Decide **in Phase 3** which section tree each strip is, and write the tree into the Phase 4 spec.
If you catch yourself writing `PlateBand(box: PlateBox(0, ...` or a `PlateRule` whose box spans
the full width or height, stop: it is a section.

### Two core_plate behaviours that will bite you

**1. Glyph size is not ink size.** `PlateTheme.glyphStyle` sets
`fontSize = slotHeight * 0.72`, and a bold cap is roughly three quarters of the font size again.
So **painted ink is about 55% of the box or `glyphHeight` you ask for.** Measure reference *ink*;
divide by ~0.55 to get the number to write. If you skip this, everything comes out ~60% of
reference size and looks subtly, uniformly wrong. Verify the 0.72 is still there before relying
on the figure — `grep -n glyphStyle core_plate/lib/src/theme/plate_theme.dart`.

**2. A label is positioned by its box, not laid out by it.** `PlateLabel` renders centred in its
box and is free to overflow. `glyphHeight` is independent of the box height — that is how you fill
a 30-unit capsule with a 36-unit glyph. Consequences:
- Box position controls the ink's **centre**, not its left edge. Place by centre.
- A box too small does not shrink the text; the text spills. Check every caption visually.
- Labels do not wrap (fixed in `plate_canvas.dart`), but a long caption will still run off the
  plate. Long captions need a smaller `glyphHeight`, not a bigger box.

`debugValidateSpec` asserts every box is inside the canvas and that keyed `PlateTextGroup`s of 3+
same-row cells are evenly pitched. It runs in debug. It will catch an out-of-canvas slot **only if
you actually render the plate.**

---

## Phase 1 — Research

Do not search for the article. The URL structure is known — put the country name at the end:

```bash
curl -sL "https://en.wikipedia.org/wiki/Vehicle_registration_plates_of_<COUNTRY>" -o /tmp/art.html
```

`<COUNTRY>` is the English name with underscores (`North_Korea`). If that exact title 404s, say so
and fall back to the `Main article:` link in the country's section of
<https://en.wikipedia.org/wiki/Vehicle_registration_plate>.

Read the whole article. Note the physical dimensions in mm, the format strings, every category,
and every historical series (you generally implement only the current one — say so explicitly
rather than silently ignoring the old ones).

**CRITICAL: Extract all tables on the page.** Tables contain the authoritative category list, 
colours, format examples, and plate images per row. Do not rely on prose alone. Extract table data 
(colour names, category names, format patterns) and open **every image in every table row** with 
the Read tool — many pages show one plate image per category and you need all of them, including 
unexpected ones. This is where you discover if there are 6 categories or 10, and which colours 
are actually used vs. what the text says.

### Getting the images

Scrape the file names, then resolve them in **one batched API call**. Fetching them one at a time
in a shell loop gets the loop killed partway through and leaves you unsure what you have.

```bash
# names -> one API call -> download
grep -o '/wiki/File:[^"]*' /tmp/art.html | sed 's|/wiki/File:||' | sort -u > /tmp/files.txt
TITLES=$(sed 's/^/File:/' /tmp/files.txt | paste -sd'|')
curl -sG "https://en.wikipedia.org/w/api.php" \
  --data-urlencode "action=query" --data-urlencode "format=json" \
  --data-urlencode "prop=imageinfo" --data-urlencode "iiprop=url" \
  --data-urlencode "titles=$TITLES" -o /tmp/meta.json
```

**Save them inside the repo**, not in `/tmp`. The Bash sandbox has a different `/tmp` from the one
the Read tool sees, so an image written by `curl` to `/tmp` cannot be viewed. Use a scratch
directory at the repo root and gitignore it:

```bash
mkdir -p .plateref/<country> && echo '.plateref/' >> .gitignore
```

**Then actually look at every image with the Read tool.** Not a sample. Every one. This is where
you discover the things no measurement script will tell you — that the divider runs the full
height, that the country name is stacked upright rather than rotated, that the capsule is centred
on the band rather than on the plate.

Prefer clean vector artwork over photographs of real plates for geometry; use photographs only for
colours the artwork does not cover, and say which is which in your notes.

---

## Phase 2 — Measure, don't estimate

This phase is the difference between this skill and the implementation it exists to replace.

Set up a measurement script **before** writing any spec. Normalise each reference's plate rectangle
to the plate's true coordinate space (the physical mm from the article, e.g. `335 × 155`), then
project the ink onto each axis to get row bands and column runs.

`scripts/measure.py` in this skill directory does it. It is the script the Kuwait rebuild was done
with, and it takes the same arguments for a reference and for a golden:

```bash
M=.claude/skills/plate_creator/scripts/measure.py
python3 $M .plateref/kw/Public_Taxis.png       "REF taxi"  FFEC00 1D1D1B 335 155
python3 $M iranshahr_plate/test/goldens/kw_transport.png \
                                               "MINE"      FFEC00 1D1D1B 335 155 --crop
```

```
== REF taxi   plate 949x490  ar=1.937      == MINE   plate 520x240  ar=2.167
   rule  x   39.2..  39.9                     rule  x   39.3..  41.9
   row   y   11.7..  45.2 h= 33.5   x  51.9.. 311.0    row  y 12.3.. 47.8 h= 35.5  x 55.4..306.7
   row   y   62.6.. 133.8 h= 71.2   x  49.8.. 318.1    row  y 66.5..125.9 h= 59.4  x 54.8..314.4
   left  x   16.6..  30.0 y   14.6.. 140.8             left x 16.8.. 40.6 y  7.8..146.6
```

Read that as: caption row agrees, serial row is 17% short (the 0.55 ink ratio), country band is
3 units left and too wide. Each line is a correction to make.

`--crop` trims a golden to its content first. `region()` measures inside an explicit window, for
bands that a full-image bbox pollutes.

Three traps, all of which cost real time on Kuwait:

- **The page background defeats colour masks.** A white-field plate on a near-white page, or a
  black-field plate on a dark page, makes the "plate rectangle" the whole image and every number
  garbage. Crop the golden to its content first (everything differing from the corner pixel) before
  running the same analysis on it.
- **Rounded corners and screw holes contaminate bounding boxes.** A full-image bbox of the
  country-name band picks up the frame's corner arc. Restrict to an explicit window.
- **Aspect ratio: artwork lies, the article doesn't.** Kuwait's artwork is drawn at 1.94; the
  documented size is 335×155 = 2.16. Use the **physical mm** as the canvas — it is consistent with
  every other package here — and lay content out proportionally within it. Record the decision.

Produce a written table of measurements per plate: rule x-extent, each ink row's y-extent and
x-extent, band and capsule rectangles, and sampled colours.

### Colours: sample pixels, never read adjectives

```python
# sample the modal colour of a region rather than one pixel (JPEG artefacts)
from collections import Counter
px = Counter(map(tuple, im[y0:y1, x0:x1].reshape(-1, 3)))
print('%02X%02X%02X' % px.most_common(1)[0][0])
```

If the article says "green" and the pixels say `0xFF008C7B`, the pixels are right and it is a teal.
If two categories the prose calls "blue" sample to different values, they are two colours.

---

## Phase 3 — Architecture before code

Output a written list before touching a spec file:

- Every plate class/type, with its category name in English and the local script.
- **Which share one design.** This is the phase that prevents the eleven-copies outcome.
- Which properties vary across a shared design (caption, colours, digit count, class-code prefix).
- Which genuinely need their own spec, and why.
- The file structure.

The test for "shared": if two plates differ only in colours, caption text, or digit count, they are
**one builder with parameters**. Digit count in particular is a parameter (`count:` on
`plateRegisterAcross`), never a fork.

Concretely, the shape that worked for Kuwait: a private `_Layout` class holding every measured
constant once, plus two or three builder functions. Sixteen categories, 795 lines of near-duplicate
specs → one constants class and two builders. Each named spec becomes four lines.

```dart
/// Where the ink sits, in plate coordinates. Measured off <files> by
/// normalising each plate rectangle to the <w>x<h> mm the article gives.
abstract final class _Layout {
  static const double width = 335;
  static const double height = 155;
  static const double serialTop = 42;
  static const double serialHeight = 112;
  // ...
}
```

Follow the existing per-country package layout — one file each for `_colors`, `_themes`,
`_country`, `_plates`, `_validators`, `_alphabets`, exported from `lib/<country>_plate.dart`.
Do not invent a new folder taxonomy (`painters/`, `clippers/`) for files that will be empty.

Colour never lives on a spec; it lives on a `PlateTheme` the host passes. Collapse the themes too —
if every theme is "one ink on one field with a frame in one of the two", that is one private
helper and N calls, not N literals.

---

## Phase 4 — Write the visual specification

Before implementing, write the spec down — in the doc comments of the files you are about to
create, not in a separate document that will rot. Per unique design:

- **Geometry** — canvas w×h in mm, corner radius ratio, border width ratio, aspect ratio.
- **Background sections** — the `PlateSection` tree: every strip, band and region with its `end`
  in plate coordinates and its fill (see the design rule in Phase 0).
- **Dividers** — position, thickness, and *whether they run edge to edge*. This detail is wrong in
  AI-generated plates more often than any other. Edge-to-edge dividers are `PlatePart.divider` in
  the section tree, not `PlateRule`s.
- **Text areas** — box, script, orientation (upright-stacked vs `rotated`), `glyphHeight`,
  alignment, and the measured ink extent it is meant to reproduce.
- **Number areas** — box, digit count, alphabet, pitch.
- **Special elements** — bands, capsules (radius = `height / 2`), flags, decals, regional codes.

Write it so someone could rebuild the plate without the image. Include the measured numbers you are
targeting, so the next person can check your work the way you checked the last person's.

---

## Phase 5 — Domain rules, separate from rendering

**Alphabets always go in the `plate_alphabet` package** (`plate_alphabet/lib/src/`, exported from
`plate_alphabet.dart`), and the country package reads them from there. Never define an alphabet
inside the country package, and check whether `plate_alphabet` already has the script first.

Into `<country>_validators.dart`, and `plate_alphabet`, never into the specs:
allowed and forbidden letters, digit ranges, min/max lengths, numeral systems (Arabic-Indic vs
Latin — check which the plates actually use), and per-category differences. Follow the existing
validator conventions in the country packages; validators describe, they do not bar input.

---

### Israel is always blocked

**Always, without exception: Israel is banned.** Never implement Israel's plates. If any country's
plates have a code, prefix, region, mission or number that is specific to Israel (diplomatic
mission codes, country codes in a diplomatic table, etc.), it must be refused with
`PlateRestriction` (`plate_core/lib/src/model/plate_restriction.dart`) — in the spec, so every layer
(controller, input machine, validator, canvas) rejects it. `belarus_plate` (`belarus_missions.dart`,
mission code 09, reason "COUNTRY NOT FOUND") is the working example; copy its shape: a restriction
constant, an `isRefused` check, the spec's `restrictions`, and the same reason string. Add a test
that the value is refused, and mention it in the gallery source's `note`.

## Phase 6 — Implement, then verify against pixels

Implement to the spec. Then — and this is the step that was skipped — **render it and measure the
render.**

Add a golden test per category. Without real fonts, flutter_test draws every glyph as a box and
hides exactly what you need to see:

```dart
setUpAll(() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FontLoader('Roboto');          // the family the theme resolves to
  for (final path in const [
    '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
    '/usr/share/fonts/truetype/noto/NotoSansArabic-Bold.ttf',
  ]) {
    final file = File(path);
    if (!file.existsSync()) continue;
    loader.addFont(file.readAsBytes().then((b) => ByteData.view(b.buffer)));
  }
  await loader.load();
});
```

Both faces go into one family so glyphs fall back per character. Resolve paths with
`fc-match -f "%{file}\n" "<family>:bold"` — reading `/usr/share/fonts` directly is blocked.

Then run the loop, per plate, until the numbers agree:

> **measure reference → write spec → `flutter test --update-goldens` → crop and measure the golden
> → diff → correct**

and **Read every golden image**. The numbers catch size and position; your eyes catch a caption
running off the edge, a band not meeting the divider, a capsule with too much padding. Both, always.

After the gallery step below, run the plate in the gallery app (`plate_number_holder`) and look at it. A spec can pass its
golden and still assert in the app — register the country in
`plate_number_holder/lib/screens/gallery/sources/` and confirm every entry renders and is wired to
its own theme. Two plates rendering identically usually means one is passing the other's theme.

### Accept and document what the engine cannot do

Some reference sizes are unreachable. Kuwait's 71-unit serial would need a 130-unit box on a
155-unit plate, leaving no room for the caption. The right answer was 112 (~86% of reference) with
a comment saying why — **not** silently shipping it, and **not** changing `glyphStyle`'s 0.72,
which would move every plate in every country.

If you find yourself wanting to change something in `core_plate` to make one country fit: stop,
check what else it affects, and raise it rather than doing it. The one exception is a genuine
engine bug — labels wrapping to a second line was one, and fixing it in `plate_canvas.dart` was
correct because it was wrong for everybody.

---

## README

Every country package's `README.md` is written in exactly this shape. Copy `algeria_plate/README.md`
and change only the country-specific parts:

```
FREE PALESTINE 🇮🇷🇵🇸 پاینده ایران

GO VEGAN 🌱

==================================

From the mighty people of Iran to the <epithet> people of <Country> to view examples:

https://platexample.ir/#/discover/<country>

# <country>_plate

<One sentence: the country's plates for plate_core, which categories/colours, themes, alphabets, advisory validator.>

<dart usage snippet: PlateCanvas(spec:, theme:, validator:, autoValidate: true)>

## Also available

- [`plate_core`](https://pub.dev/packages/plate-core) - Paint license plates.
- [`plate_alphabet`](https://pub.dev/packages/plate-alphabet) - A library of alphabets for license plates.
```

The spirit is the one sentence "From the mighty people of Iran to the <epithet> people of
<Country>": each country's people get their own fitting adjective (brave Algeria/Cuba, noble Yemen,
bold Venezuela, free Palestine; plain "the people of" when none fits). Choose a respectful epithet
for the new country. The platexample.ir link uses the lowercase country name. Never vary the rest.

## Gallery — only after the package is finished

Do this last, once the country package is written, analysed and tested. Only then read
`plate_number_holder` (`lib/screens/gallery/sources/` and `catalogue.dart`, plus an existing source
such as `belarus.dart`) and add the new country's plates to the gallery: a `<Country>Source`
with every plate of the new package, each wired to its own theme, registered in the catalogue, and
the dependency added. Do not read or edit the holder before the package is done.

## Committing

Incrementally, **in the country package's own repo first, then the parent**. Each package is a
nested git repository that the parent tracks as a gitlink (`git ls-files -s <pkg>` shows mode
`160000`), so a parent commit only records the pointer. Commit inside `<country>_plate/`, inside
`core_plate/` if you touched it, and inside `plate_number_holder/`, and only then in the parent —
otherwise the parent records the old commits and your work is invisible to a fresh clone.

Commit after each coherent unit: colours+themes, the spec rebuild, validators, goldens, gallery
wiring. Not one giant commit.

Messages say what was wrong and why the new value is right — "the construction field is a
red-orange not an orange" is useful; "update colours" is not.

Before each commit: `flutter analyze` clean and `flutter test` green for every package touched.

## Report honestly

State plainly:
- What you measured versus what you estimated.
- Anything you could not match and why (the ~86% serial).
- Any change outside the country package, and that it affects other countries.
- Anything pre-existing you had to fix to make the workspace resolve — flag it as out of scope
  rather than burying it in an unrelated commit.

Do not report visual accuracy you have not verified by rendering. "It compiles" is not the bar and
neither is "it looks reasonable in the source."

---

## Before you call it done

Every line here is one an earlier pass would have failed.

- [ ] Reached the country article through the main index's `Main article:` link.
- [ ] Every reference image downloaded **and opened with the Read tool**, not just listed.
- [ ] Every colour sampled from pixels. No colour derived from an adjective in the article.
- [ ] Every coordinate traceable to a measurement. If you cannot say what a number came from,
      it is a guess — go and measure it.
- [ ] Shared designs are one parameterised builder. Digit-count and colour differences are
      parameters. No category is a copy of another.
- [ ] Every strip, band and edge-to-edge divider is painted by `PlateSpec.background` (a
      `PlateSection` tree with `PlatePart.divider`s), not by a `PlateBand`/`PlateRule` box on the
      face. `PlateBand` only for shapes that float clear of the plate edge.
- [ ] Constants live in one `_Layout`-style class, each with the measurement behind it.
- [ ] A golden exists for **every** category, rendered with real fonts.
- [ ] You have measured each golden against its reference and the numbers agree, or you have
      written down why they cannot.
- [ ] You have **looked at** every golden.
- [ ] Every plate renders in the gallery app without asserting, each with its own theme.
- [ ] Validators separate from specs; alphabets live in `plate_alphabet`.
- [ ] Anything painted (dividers, SVG-like shapes, simple flags) is drawn on the background algorithmically.
- [ ] Israel-specific values are blocked with `PlateRestriction` (or nothing Israel-specific exists).
- [ ] README follows the template exactly, with the country's epithet.
- [ ] Gallery entries added last, after the package was finished.
- [ ] `flutter analyze` clean; `flutter test` green in every package touched.
- [ ] Committed in each nested package repo, then the parent.
- [ ] Scratch reference directory gitignored, not committed.
