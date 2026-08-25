# Claude Code prompt pack — new poster around the existing device

Nine prompts, in order. Each is self-contained: Claude Code starts cold every session,
so every prompt re-states the freeze rules and points at `DESIGN_SPEC.md`.

**Scope:** the road, the theme, the text containers and the page chrome. The device and
everything on its screen — shells, plate, keypads, typist, scripts — do not change.

Run them in sequence. Commit after each. Every prompt ends with a verification step.

| # | Prompt | Quality | Budget |
|---|---|---|---|
| P1 | Bootstrap & demolition | Sonnet · `think` | Sonnet · — |
| P2 | Theme tokens & responsive metrics | Sonnet · `think` | Sonnet · — |
| P3 | Bevel-panel primitives | Opus · `think hard` | Sonnet · `think hard` |
| P4 | The road backdrop | Opus · `think hard` | Sonnet · `think hard` |
| P5 | Sweep light & ground shadow | Sonnet · `think hard` | Sonnet · `think` |
| P6 | Wordmark & page chrome | Opus · `think` | Sonnet · `think` |
| P7 | Callout content & cards | Sonnet · `think` | Sonnet · — |
| P8 | Callout motion | Opus · `think hard` | Sonnet · `think hard` |
| P9 | Responsive assembly & verification | Opus · `ultrathink` | Opus · `think hard` |

### The one rule that matters

**The device is not part of this migration.** The design draws its own laptop, phone,
tablet, plates and keyboards — that is reference art, not a spec. Ignore its plate slot
counts, its German layout, its Persian digit strings, its keypad grids and its status
chip. `lib/`, `device_preview/`, the typist scripts, the keypad and `plate_display` all
stay exactly as they are.

What actually changes: the background becomes a lit road, the callouts become bevelled
panels with new copy, a display wordmark and page chrome arrive, and the device moves
from centre-stage to right-of-centre.

---

## P1 — Bootstrap & demolition

**Quality:** Sonnet · `think` **Budget:** Sonnet · —

> Before running: copy `DESIGN_SPEC.md` to the repo root and unzip `poster_assets.zip`
> into `example/assets/`.

```
We are replacing the poster design that surrounds the device in the Flutter example
app. Read `DESIGN_SPEC.md` at the repo root first — it is the source of truth and every
later task refers to it.

SCOPE. We are changing the background, the theme, the text containers and the page
chrome. We are NOT changing the device or anything on its screen. The design file draws
its own devices, plates and keyboards; that is reference art, not a specification.

FROZEN — do not edit any of these, in this or any following task:
  lib/**                                        (the plate_number package)
  example/lib/device_preview/**                 (all of it: presets, painters,
                                                 laptop_deck, pixel_dissolve,
                                                 device_frame, device_transition)
  example/lib/showcase/plate_typist.dart        (keep carScript, germanCarScript,
                                                 bicycleScript exactly as they are)
  example/lib/showcase/virtual_keypad.dart
  example/lib/showcase/device_cycle.dart
  example/lib/widgets/plate_display.dart
  example/lib/poster/plate_backdrop.dart        (this one is the GLASS backdrop behind
                                                 the plate — it is device content and
                                                 it stays, despite living in poster/)

If something seems to require changing a frozen file, stop and report it instead.

This task is bootstrap and demolition only. Build no new design yet.

1. Wire up the new assets. `example/assets/` now contains `textures/` (bg_grain_a.png,
   bg_grain_b.png, tex_screen.png, tex_overlay.png) and `fonts/` (Archivo, MartianMono,
   Newsreader, Vazirmatn variable TTFs, split into latin / latin-ext / arabic subsets).
   Register them in `example/pubspec.yaml` with family names `Archivo`, `MartianMono`,
   `Newsreader`, `Vazirmatn`. The subsets are separate files covering different Unicode
   ranges and Flutter picks per family, not per range — so register the widest-coverage
   file per family and report what coverage that loses. Vazirmatn needs Arabic AND
   Latin, so say if neither single file covers both.

2. Delete these — they are the old poster and none of it survives:
     example/lib/poster/annotation_callout.dart
     example/lib/poster/callout_content.dart
     example/lib/poster/connector_motion.dart
     example/lib/poster/corner_brackets.dart
     example/lib/poster/grid_backdrop.dart
     example/lib/poster/poster_footer.dart
     example/lib/poster/poster_header.dart
     example/lib/poster/tech_chip.dart

   Do NOT delete example/lib/poster/plate_backdrop.dart.
   Leave callout_motion.dart and callout_rail.dart in place for now — P8 rewrites them.

3. `example/lib/poster/poster_tokens.dart` is rewritten in P2, but it is imported by
   frozen device-side code. Right now, leave it alone.

4. `example/lib/screens/showcase_screen.dart` currently references the deleted files.
   Reduce it to the smallest thing that compiles: the device stage cycling as it does
   today, with the plate, keypad and typist all working exactly as before, and no
   poster chrome at all. Do not touch the `_DeviceStage` state class or any of its
   plate/typist/keypad wiring — only strip the poster layout around it.

5. `flutter analyze` clean; the app builds and cycles all three devices with plates
   typing correctly.

Report which files you deleted, what you stripped from showcase_screen.dart, and
confirm that the plate still types on all three devices.
```

---

## P2 — Theme tokens & responsive metrics

**Quality:** Sonnet · `think` **Budget:** Sonnet · —

```
Read `DESIGN_SPEC.md` at the repo root, especially §0 (what is frozen), §1 (colours),
§2 (typography), §3 (textures) and §8 (responsive tiers).

FROZEN: lib/**, example/lib/device_preview/**, plate_typist.dart, virtual_keypad.dart,
device_cycle.dart, plate_display.dart, poster/plate_backdrop.dart. The device and
everything on its screen is out of scope.

Build the foundation for the new poster. Three files under `example/lib/poster/`:

1. Rewrite `poster_tokens.dart` from §1 and §2.

   CRITICAL COMPATIBILITY REQUIREMENT — read §1's "Compatibility names" box. The frozen
   `virtual_keypad.dart` reads `PosterTokens.accent` and `PosterTokens.hairline`, and
   the plate wiring reads `PosterTokens.bg` and `PosterTokens.invalid`. All four names
   must survive the rewrite so no frozen file has to be touched:
     accent   -> the new #7C5CFF
     hairline -> keep rgba(255,255,255,.10)
     bg       -> the new stageBlack #07080B
     invalid  -> keep #F87171
   Verify by grepping for `PosterTokens.` across the example before and after; the set
   of names used by frozen files must not shrink.

   Structure the rest as:
     - `PosterColors` — every token in §1 as `static const Color`, keeping the spec's
       names. Repeated gradients (cardSteel, cardDark, linkButton) become named
       `LinearGradient` constants. CSS `linear-gradient(158deg, …)` is measured
       clockwise from "to top" — convert to Flutter `Alignment` begin/end correctly and
       leave the original CSS in a comment on each.
     - `PosterFonts` — the four family names plus named `List<FontVariation>` helpers
       for the width axes the design uses: Archivo wdth 79 / 84 / 86 / 104.
     - `PosterType` — every specimen in §2's table as a factory taking a scale factor
       and returning a `TextStyle`. No absolute sizes at call sites.

2. `poster_scale.dart` — §8's responsive foundation:
     - `enum PosterTier { wide, medium, compact }` with the documented breakpoints.
     - `PosterMetrics`, an `InheritedWidget` carrying `tier`, the fluid factor `f` and
       the stage `Size`, with `PosterMetrics.of(context)` and a scope widget that
       computes it from a `LayoutBuilder`.
     - Helpers `double px(double designPx)` and `Rect box(fx, fy, fw, fh)` converting
       the spec's 1920x1080 design coordinates to real ones. Every poster widget
       positions itself through these, never with raw pixels.

3. `poster_textures.dart` — §3's four tiles. A `PosterTexture` enum plus a
   `textureDecoration(...)` returning a `DecorationImage` with the right repeat, tile
   size (scaled through `PosterMetrics`), opacity and `BlendMode`. Tile size is the CSS
   `background-size`: the tile draws at that many DESIGN px regardless of the PNG's own
   pixel size.

Add a throwaway `example/lib/dev/token_gallery.dart` run target rendering every colour
swatch, every text specimen at tier wide, and each texture over the stage black.

Verify: `flutter analyze` clean, the gallery runs, the app still builds, and the keypad
still renders with its accent colour. Report anything in the spec you could not
represent faithfully and what you substituted.
```

---

## P3 — Bevel-panel primitives

**Quality:** Opus · `think hard` **Budget:** Sonnet · `think hard`

```
Read `DESIGN_SPEC.md`, especially §4 (the bevel-panel recipe).

FROZEN: lib/**, example/lib/device_preview/**, plate_typist.dart, virtual_keypad.dart,
device_cycle.dart, plate_display.dart, poster/plate_backdrop.dart.

§4 is the design's signature — every callout card, index chip and link button is built
from it. Build it once, properly, in `example/lib/poster/cards/`:

1. `bevel_panel.dart` — `BevelPanel`, implementing all ten layers of §4 in order. API:
   a ground (Color or Gradient), a `BevelStyle` (hero / steel / dark / chipWhite /
   chipDark, each carrying its own bevel widths and light/dark rgba pairs from §4.6 and
   §4.7), whether the screen-grain layer is on, an optional screw-dot config, the hard
   shadow's offsets, and a child.

   Details that are easy to get wrong:
     - Layer 1 is a HARD-EDGED duplicate rect, not a blur, and it is asymmetric
       (left+5..8 / top+8..12 / right-5..-8 / bottom-8..-12).
     - The outer bevel is light on top+left, dark on bottom+right. The inner
       counter-bevel at 10-12px inset is INVERTED. Both are inset borders. Draw them in
       one `CustomPainter` as edge strips — nested `Container` borders leave visible
       seams at the corners.
     - Blend modes are load-bearing: overlay grain is `BlendMode.overlay`, screen grain
       and the 103deg sheen are `BlendMode.screen`. They must composite against the
       card's own ground, not the page — so they need a `saveLayer` boundary.
     - Screw dots measure from the card's device-facing edge: left for LTR, right for
       RTL.

2. `index_chip.dart` — `IndexChip`, the 01-12 numbered chip: itself a `BevelPanel`
   (chipWhite or chipDark), Archivo wght 800 wdth 104, 44-78 design px. Support the
   -3.4deg rotation on chip 01 and the pinning offsets from §4.10.

3. `dashed_rule.dart` — `DashedRule` from §4.9, parameterised on dash, gap, height and
   colour. 8/16 for 2px rules, 10/20 for 3px.

4. `card_decorations.dart` — the per-card extras at the end of §4: the vertical IR flag
   strip (card 01), the faded flag strip (02), the two-tone divider and flag footer
   (05), the EU star badge column (09) and its red tag, the DE strip (10).

Add `example/lib/dev/bevel_gallery.dart` rendering each `BevelStyle` at a realistic card
size, LTR and RTL, with and without screw dots and index chips, over the stage black.

Verify visually: does the panel read as a raised physical object with a light source
from the top-left? If not, say what is off rather than declaring success.
```

---

## P4 — The road backdrop

**Quality:** Opus · `think hard` **Budget:** Sonnet · `think hard`

```
Read `DESIGN_SPEC.md`, especially §6 "Backdrop layers" and §1's ground/atmosphere
tokens.

FROZEN: lib/**, example/lib/device_preview/**, plate_typist.dart, virtual_keypad.dart,
device_cycle.dart, plate_display.dart, poster/plate_backdrop.dart.

The old `GridBackdrop` (a flat grid and vignette) is gone. The new background is a lit
road receding to the right. Build layers 1 through 9 of §6 in
`example/lib/poster/backdrop/poster_backdrop.dart`, bottom-up in exactly that order:

  - the ground radial, 1500x920 at 74%,50%
  - two full-bleed grain tiles
  - the BEAM WEDGE: a `ClipPath` on polygon(0% -6%, 100% 23%, 100% 112%, 0% 66%).
    Those are percentages of the stage box and the negative / over-100 values are
    intentional, so build the path from the layout size and let it exceed the bounds.
    Inside: a screen-blended radial at 1430,545 plus a 99deg linear, and a blurred
    1990x64 bar rotated 12.9deg anchored at the wedge's own origin.
  - the same wedge re-clipped twice more, for the overlay grain and the colour cast
  - the two dark masks above and below the wedge
  - two rotated light rails, 9.26deg and 14.5deg
  - the lane dashes: a 2100x9 bar rotated 11.8deg with a 104px-on / 68px-off repeating
    gradient

EVERY rotation in the source is `transform-origin: 0 0` — top-left, NOT centre. Use
`Transform.rotate(alignment: Alignment.topLeft)` or an explicit `Matrix4`. Getting this
wrong looks plausible and is wrong — check the rail endpoints against the spec.

Every position and size goes through `PosterMetrics` from P2, never raw pixels.

Add `example/lib/dev/backdrop_gallery.dart` rendering the backdrop full-screen at
several window sizes.

Verify: the beam must read as a lit road surface receding to the right, with the lane
dashes lying ON the beam and converging with it — not floating at a different angle. If
they disagree, say so rather than moving on.
```

---

## P5 — Sweep light & ground shadow

**Quality:** Sonnet · `think hard` **Budget:** Sonnet · `think`

```
Read `DESIGN_SPEC.md` §6 (layer 10 and the ground shadow row) and §7.2 (what drives the
poster's motion).

FROZEN: lib/**, example/lib/device_preview/**, plate_typist.dart, virtual_keypad.dart,
device_cycle.dart, plate_display.dart, poster/plate_backdrop.dart.

Two atmosphere pieces that react to a device hop. Read §7.2 first: the poster layer has
NO state machine of its own. It hangs off signals the existing device stage already
emits — `onFrameDeviceChanged` for the device, and `DeviceFrame.onPhaseChanged` for
whether a hop is running. Do not build a second clock, and do not port the design's own
`go()` / `tick()` machinery.

1. `example/lib/poster/backdrop/sweep_light.dart` — `SweepLight`. A 400x1500 gradient
   band plus a 5px bright edge at x=396, both rotated 11.8deg about their centre,
   translating X from -560 to 2400 over 1.5s `cubic-bezier(.42,.02,.6,1)`, with opacity
   ramping 0/1 over .34s linear. Screen blend.

   It takes a `bool isHopping` and runs the sweep once per hop. Drive that from
   `DeviceFrame.onPhaseChanged`: true for any phase other than
   `DeviceTransitionPhase.idle`. Note the existing transition is long (see
   `DeviceTransitionDurations.total`) and the sweep is only 1.5s, so the sweep should
   fire once at the start of the hop and not loop or retrigger while the phase is still
   non-idle.

2. `example/lib/poster/backdrop/ground_shadow.dart` — `GroundShadow`, the skewed slab
   under the device. 900x104 at (1030, 872) in design coordinates, skewX of -34deg /
   -30deg / -41deg for desktop / mobile / tablet, gradient and blur from §1 and §6.

   It animates between the three skews on a device change. Match its duration and curve
   to the device's own morph — `DeviceTransitionDurations.frameTransform` (1500ms) and
   `Curves.easeInOutCubic` — NOT the design's 1.15s, so the shadow and the shell move
   together.

   Flutter has no skewX shorthand: use `Matrix4.skewX(radians)`, and note CSS skewX
   leans the opposite way to the maths convention. Verify visually rather than trusting
   the sign.

Extend `dev/backdrop_gallery.dart` with a keypress that fires the sweep and cycles the
ground shadow through its three skews.

Verify: the sweep should read as a single headlight raking across the scene along the
same angle as the lane dashes, and the shadow should stay anchored under the device as
it changes shape. Report if either fights the road's perspective.
```

---

## P6 — Wordmark & page chrome

**Quality:** Opus · `think` **Budget:** Sonnet · `think`

```
Read `DESIGN_SPEC.md`, especially §6 "Chrome" and §2 (type).

FROZEN: lib/**, example/lib/device_preview/**, plate_typist.dart, virtual_keypad.dart,
device_cycle.dart, plate_display.dart, poster/plate_backdrop.dart.

The old `PosterHeader`, `PosterFooter` and `TechChip` are gone. Build the new
always-on-screen chrome in `example/lib/poster/chrome/`, all positioned through
`PosterMetrics` fractional anchors:

1. `poster_wordmark.dart` — four lines of display type: PLATE / INPUT / FOR THE / ROAD.
   Archivo wght 900, wdth 79, 176 design px, line height .86, tracking -.045em.
   The fourth line is the interesting one: `ROAD` in #1A2130 with a second #BCD3F0 copy
   on top, masked by `linear-gradient(103.5deg, opaque 0->46%, transparent 46%)` — a
   hard-edged diagonal cut, not a fade. Use a `ShaderMask` with two stops at the same
   position so the edge stays crisp, and derive begin/end from 103.5deg correctly.
   Lines 1 and 2 carry a `0 0 80px rgba(150,180,220,.28-.32)` glow.

   This is the largest element on the page — it occupies the lower-left quadrant that
   the device used to sit in. Get its scale right before anything else.

2. `poster_masthead.dart` — `ARAD BIRANVAND` (Martian Mono 800, .16em) baseline-aligned
   with `sole author` (Newsreader italic 400), gap 14.

3. `poster_links.dart` — two bevel-panel buttons, PUB.DEV and GITHUB, with their icons
   redrawn as `CustomPainter`s (a wireframe cube and a circled octocat, 18px). Ground
   goes to #EDEFF3 on hover with the label and icon inverting.
     pub.dev -> https://pub.dev/packages/plate_number
     github  -> https://github.com/ArAd1Beyranvand/plate-number-upgrade
   Use `url_launcher` only if it is already a dependency; if not, make the tap a no-op
   and tell me rather than adding one.

4. `poster_meta.dart` — the `plate_number | pub.dev | MIT` strip with its hairlines and
   1px dividers.

5. `inspection_stamp.dart` — rotated -6deg, double inner ring, two centred lines:
   `FORM FACTOR {01|02|03}/03` and `{LAPTOP|PHONE|TABLET} — INSPECTED`. It takes the
   current `DeviceType`; the mapping is desktop->LAPTOP 01, mobile->PHONE 02,
   tablet->TABLET 03, following `DeviceCycle.order`.

6. `form_factor_pips.dart` — three 5px bars in a right-aligned column, gap 12. Active
   28px #7C5CFF with glow; idle 14px rgba(200,212,236,.24). Width animates .24s linear.

§9.1: in the source, cards 04/08/12 and the link buttons overlap and clip the meta
strip. Build the chrome so it can live in its own layer ABOVE the callouts, and leave a
comment marking that decision.

Add these to `dev/backdrop_gallery.dart` over the real backdrop.

Verify: screenshot at 1920x1080 and check the wordmark's diagonal cut and the stamp's
rotation against the spec. Report any type that overflows its anchor.
```

---

## P7 — Callout content & cards

**Quality:** Sonnet · `think` **Budget:** Sonnet · —

```
Read `DESIGN_SPEC.md` §5 (the twelve callouts) and §4 (bevel recipe).

FROZEN: lib/**, example/lib/device_preview/**, plate_typist.dart, virtual_keypad.dart,
device_cycle.dart, plate_display.dart, poster/plate_backdrop.dart.

The old `AnnotationCallout` / `calloutSets` are gone — new copy, new structure. Two
files under `example/lib/poster/callouts/`:

1. `callout_data.dart` — the twelve callouts as pure data:

     enum CalloutKind { heroIr, heroDe, steel, dark }
     enum CalloutSide { left, right }   // motif direction, NOT screen position

     @immutable class CalloutSpec {
       index, kind, side, textDirection, anchorFx, anchorFy, widthFx,
       eyebrow, title, body (nullable), titleSizeDesignPx, bodySizeDesignPx,
       plus flags for the per-card decorations built in P3
     }

     const Map<DeviceType, List<CalloutSpec>> calloutSets = { … }

   Transcribe every string in §5 EXACTLY, including the Persian. Do not translate,
   normalise, reorder or "fix" any of it — copy it character for character, including
   the zero-width non-joiners in `ساخته‌ٔ`, `حالت‌های`, `آن‌هایی`, `می‌افتند`,
   `صفحه‌کلید` and `متن‌باز`. After writing the file, print each Persian string's code
   points back to me so I can confirm nothing was mangled.

   Cards 02, 04, 05, 07 and 12 are RTL. Their eyebrows are set `direction: ltr;
   text-align: right` in the source — a Latin-styled label inside an RTL block, so it
   must not be reordered. Reproduce that.

2. `callout_card.dart` — `CalloutCard`, rendering one `CalloutSpec`: a `BevelPanel` of
   the right style with eyebrow / title / dashed rule / body stacked at the spec's
   paddings, plus whichever decorations that card declares. The index chip pins outside
   the panel's bounds, so the card must not clip it.

Add a gallery page laying out all twelve cards at their real widths.

Verify: render all twelve and confirm the Persian shapes and joins correctly (Vazirmatn
must be the resolved font, not a fallback — check with a deliberate wrong-font test if
unsure) and that the RTL cards' text hugs the right edge. Report any card whose content
overflows its declared width.
```

---

## P8 — Callout motion

**Quality:** Opus · `think hard` **Budget:** Sonnet · `think hard`

```
Read `DESIGN_SPEC.md` §7.2 (what drives the poster's motion) and §7.3 (the three
motifs).

FROZEN: lib/**, example/lib/device_preview/**, plate_typist.dart, virtual_keypad.dart,
device_cycle.dart, plate_display.dart, poster/plate_backdrop.dart.

Rewrite `example/lib/poster/callout_motion.dart` and turn
`example/lib/poster/callout_rail.dart` into
`example/lib/poster/callouts/callout_layer.dart`.

READ THE EXISTING `callout_rail.dart` BEFORE REPLACING IT. Its structure is right and
stays: one `AnimationController` per side at 1500ms, the outgoing set on
`Interval(0, .45)`, the incoming on `Interval(.55, 1)`, animations built once in
`initState` and never in `build`, and only ever ONE set constructed at a time. It also
already drives itself off a device change in `didUpdateWidget`, which is exactly the
signal §7.2 says to use. Keep all of that.

What changes is the transforms, the curves, the motif-to-device mapping, and that the
cards are now positioned by fractional anchor in a `Stack` rather than in two fixed
360px rails.

THE MAPPING CHANGED. Old: desktop->siphon, mobile->sweep, tablet->trapdoor. New:
  - desktop -> SWEEP:    rest translateX(0); enter and exit at translateX(∓520)
  - mobile  -> TRAPDOOR: rest translateY(0); enter from -90, exit to +90
  - tablet  -> SIPHON:   rest translateX(0) scale(1);
                         enter from translateX(-nudge) scale(.04),
                         exit to  translateX(+nudge) scale(.04)
`nudge` is +18 for side L and -18 for side R. Sweep's sign is -520 for L, +520 for R.
Siphon's transform origin is `100% 12%` for side L and `0% 12%` for side R — that is
what makes it collapse toward the device-facing edge rather than its own centre.

THE CURVES (§7.3), all six, as `Cubic(...)`:
  sweep    in cubic-bezier(.215,.61,.355,1)   out cubic-bezier(.55,.055,.675,.19)
  trapdoor in cubic-bezier(.25,.46,.45,.94)   out cubic-bezier(.55,.085,.68,.53)
  siphon   in cubic-bezier(.34,1.56,.64,1)    out cubic-bezier(.36,0,.66,-.56)
`sipIn` overshoots past 1 and `sipOut` undershoots below 0. Flutter's `Cubic` handles
both — do NOT clamp them, the overshoot is the point.

Group opacity is separate from the transform, so the outgoing set is fully gone before
the incoming one arrives. The existing .45/.55 interval split already gives you that
gap; keep it.

SLOT RAILS — mobile group only. Four 3px bars, one at each mobile card's own anchor,
full card width, rgba(124,92,255,.55) with a `0 0 12px rgba(124,92,255,.95)` glow. They
animate scaleX 0 -> 1 from the LEADING edge over .3s linear, delayed to roughly the
entry interval when the phone is the incoming device and undelayed when it is outgoing.

Add a dev target that cycles the three groups on a keypress over the real backdrop.

Verify: watch each of the three hops and confirm (a) the outgoing set is fully
transparent before the incoming set begins to move, (b) siphon's overshoot is visible
on entry, (c) the slot rails draw outward from the card's leading edge, not from the
centre. Report anything that reads wrong even if the numbers are right.
```

---

## P9 — Responsive assembly & verification

**Quality:** Opus · `ultrathink` **Budget:** Opus · `think hard`

```
Read `DESIGN_SPEC.md` in full, especially §7.1 (where the device sits) and §8
(responsive tiers).

FROZEN: lib/**, example/lib/device_preview/**, plate_typist.dart, virtual_keypad.dart,
device_cycle.dart, plate_display.dart, poster/plate_backdrop.dart.

Assemble everything from P2-P8 into the real screen, and make the fixed 1920x1080
design responsive. Think hard about the layout architecture first — this is where the
port either holds together or becomes unmaintainable.

Rewrite `example/lib/screens/showcase_screen.dart` and `example/lib/app/app.dart`.

WHERE THE DEVICE GOES (§7.1). The composition changes: the device moves from centre
stage to right-of-centre, and the wordmark fills the lower left. The design's shell
boxes become STAGE BOUNDS — the box `DeviceFrame` is handed. `DeviceFrame` already fits
itself to its constraints, so it keeps its own preset proportions and letterboxes
inside. Nothing about the device changes; only where it sits and how much room it gets.

  desktop  .527, .243, .433, .450     (L, T, W, H as fractions of the stage)
  mobile   .677, .191, .190, .646
  tablet   .523, .231, .454, .556

Animate the box on a device change using `DeviceTransitionDurations.frameTransform`
(1500ms) and `Curves.easeInOutCubic` — the device's OWN morph timing, not the design's
1.15s. Two animations of different lengths on the same object reads as a wobble. The
laptop's deck extends below its box and `DeviceFrame` already accounts for that in
`totalSize`, so pass the body height and let the frame handle it.

THE TIERS (§8):
  wide    (>=1240 wide and >=700 tall) — the full poster: backdrop -> device stage at
          its fraction -> callout layer -> chrome layer on top.
  medium  (>=760) — wordmark scales into a top band; device stage centred with the
          fractions re-anchored to the stage box; only TWO callouts per group (01/03,
          05/06, 09/10) in rails flanking the stage; stamp and pips to a bottom bar.
  compact — single scrolling column: byline -> wordmark -> device stage in a
          fixed-aspect box -> all four callouts full-width and stacked with index chips
          inline -> links -> meta. Motifs degrade to a fade plus a 24px slide.

The device stage is unchanged at every tier — it is handed a box and fits itself. Do not
special-case the device on compact; give it a box and let it letterbox.

PRESERVE THESE, they exist for real reasons — read their comments before touching them:
  - the `RepaintBoundary` around the device stage. The shell is expensive to raster and
    on Linux a window maximise that forces a full re-raster has crashed the GL embedder.
  - the split where the FRAME device flips at the start of a hop while the CONTENT
    device lags until `DeviceFrame`'s `onContentSwap` fires during the blank hold. That
    is what stops the incoming plate being seen crossing the outgoing one.
  - the whole `_DeviceStage` plate / typist / keypad / bloc wiring. Move it if you must,
    but do not rewrite it.

THEN VERIFY, adversarially:

1. FREEZE AUDIT. `git diff --stat` against the commit before this migration started.
   Confirm ZERO changes under `lib/` and under `example/lib/device_preview/`, and zero
   changes to plate_typist.dart, virtual_keypad.dart, device_cycle.dart,
   plate_display.dart and poster/plate_backdrop.dart. If any changed, revert and report.

2. THE PLATE STILL WORKS. Watch a full three-device cycle: the Iranian car plate, the
   bicycle plate and the German plate must each type exactly as they did before this
   migration, including the German script's forbidden-value flare and its
   backspace-and-correct beat. Any behaviour change here is a bug.

3. SPEC CONFORMANCE. Section by section — §1 colours, §2 type, §4 bevel, §5 the twelve
   callouts, §6 chrome and backdrop, §7 motion — report CONFORMS, DEVIATES (with the
   deviation and whether it was deliberate), or MISSING. Check every Persian string
   character for character including ZWNJs, all six easing curves, and the changed motif
   mapping.

4. §9.1's two known design bugs must be FIXED, not faithfully reproduced: index chips
   01 and 09 must not cover their own eyebrows, and the meta strip must not be clipped
   by cards 04/08/12 or the link buttons.

5. Sizes: 1920x1080, 1440x900, 1024x768, 800x600, 400x880. At each, run a full cycle,
   screenshot each settled state, and confirm no overflow errors, no clipped text and
   no callout escaping the viewport. Include an instant window maximise and confirm no
   "Timed out waiting for OpenGL frame".

6. Dead code: remove anything orphaned — unused imports, unreferenced widgets, dev
   gallery targets that no longer build, assets nothing loads. Keep
   `example/lib/dev/flag_panel_gallery.dart`; it exercises the frozen package.

7. `flutter analyze` clean. `flutter test` in `example/` passes —
   `device_cycle_test.dart` must not have been weakened. Update
   `example/test/widget_test.dart`, which still tests a counter app that no longer
   exists.

Report findings ranked, most severe first.
```

---

## Notes on running the pack

- **Commit between every prompt.** P8 and P9 are the most likely to need a second pass.
- **P3 and P4 are load-bearing.** If the bevel recipe or the beam wedge come out wrong,
  everything downstream inherits the error. Spend the extra turn there.
- **P9 is the hard one** — the tier architecture plus the freeze audit. It is also the
  only prompt that can catch a device-side regression, so don't skip its verification.
- If Claude Code ever proposes changing a plate spec, a typist script, a keypad layout
  or a device preset, that is the wrong answer — none of that is in scope.
