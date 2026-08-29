# Plate Number — Poster Design Spec

Extracted from `Plate Number Poster.html` (a Claude Design canvas export).

**Scope: the poster AROUND the device. Nothing inside it.**

This spec covers the road, the theme, the text containers and the page chrome. It does
**not** cover the device shells, the plate, the keypads or the typist — those already
exist, they work, and they are not migrating. Where the design draws its own plate or
its own keyboard, that is reference art only; ignore it.

---

## 0. What moves and what does not

| Zone | Treatment |
|---|---|
| `lib/**` (the `plate_number` package) | **Frozen.** No edits, ever. |
| `example/lib/device_preview/**` | **Frozen.** Not one line — no preset retune, no colour retune, no deck changes. |
| `example/lib/showcase/plate_typist.dart` | **Frozen.** Keep `carScript`, `germanCarScript`, `bicycleScript` exactly as they are. |
| `example/lib/showcase/virtual_keypad.dart` | **Frozen** apart from the two `PosterTokens` colour references it already makes. |
| `example/lib/showcase/device_cycle.dart` | **Frozen.** Device→spec mapping and cycle order stay. |
| `example/lib/widgets/plate_display.dart` | **Frozen.** |
| `example/lib/poster/plate_backdrop.dart` | **Kept.** It is the glass backdrop — device content, not poster. |
| `example/lib/poster/**` (everything else) | **Rebuilt** from this spec. |
| `example/lib/screens/showcase_screen.dart`, `example/lib/app/app.dart` | **Rewritten** — they compose the new poster around the unchanged device. |

Two consequences worth stating plainly:

- **The plate never changes.** Slot counts, alphabets, the German spec, the Persian
  digit storage form, the demo values, the letter picker — all of it stays. The design
  draws its plate differently; that is not a spec, it is a mockup.
- **The device shells never change.** `DevicePresets`' body sizes, radii and bezels
  stay as they are. The design's shell boxes are used only to decide *where on the page
  the device sits and how much room it gets* (§7.1), never to reshape it.

The design is authored on a fixed **1920 × 1080** canvas. The port is **fully
responsive** — every position below is given as design px *and* as a fraction of that
canvas, so it can be re-derived at any size (§8).

---

## 1. Colour tokens

### Ground / atmosphere
| Token | Value | Use |
|---|---|---|
| `pageBlack` | `#050608` | Page behind the stage |
| `stageBlack` | `#07080B` | Stage ground |
| `groundRadial` | radial 1500×920 at 74% 50%: `#121620` → `#0A0B0E` @50% → `#050608` | Stage vignette |
| `beamHi` | `rgba(182,202,232,.6)` | Beam core (radial 900×520 at 1430,545) |
| `beamMid` | `rgba(148,175,214,.16)` @48% | Beam falloff |
| `beamTint` | `rgba(70,92,124,.18)` overlay-blended | Beam colour cast |
| `roadMask` | `rgba(3,2,1,.72)` | The dark wedges above and below the beam |
| `railLight` | `rgba(206,220,242,.9)` → `rgba(190,208,236,.24)` @62% → transparent | The two thin light rails |
| `roadStripe` | `rgba(255,255,255,.92)` | Lane dashes |
| `sweepBody` | `rgba(196,214,240,.02)` → `rgba(198,216,242,.16)` @44% → `rgba(210,224,246,.3)` | Raking sweep during a hop |
| `sweepEdge` | `rgba(224,235,250,.4)` → `.98` @30% → `.4`, glow `0 0 34px rgba(184,203,233,.75)` | Sweep's bright leading edge |
| `groundShadow` | `rgba(3,2,1,.95)` → `rgba(5,3,2,.5)` @58% → transparent | Skewed slab under the device |

### Text
| Token | Value |
|---|---|
| `inkDisplay1` | `#EAF0FB` |
| `inkDisplay2` | `#D6E1F1` |
| `inkDisplay3` | `#C4D0E2` |
| `inkDisplay4` | `#1A2130` (the dark "ROAD" base) |
| `inkDisplayCut` | `#BCD3F0` (the "ROAD" split overlay + link hover) |
| `inkByline` | `#DEE7F4` |
| `inkMutedItalic` | `#8E9DB4` |
| `inkLink` | `#A9B3C7` |
| `inkMetaStrong` | `#A5B4C7` |
| `inkMetaWeak` | `#8592A3` |
| `inkStamp` | `#B3BECD` |

### Accent / signal
| Token | Value | Use |
|---|---|---|
| `accent` | `#7C5CFF` | Form-factor pips, the phone group's slot rails |
| `accentRail` | `rgba(124,92,255,.55)`, glow `0 0 12px rgba(124,92,255,.95)` | Slot rails |
| `accentPipGlow` | `0 0 18px rgba(124,92,255,.95)` | Active pip |
| `pipIdle` | `rgba(200,212,236,.24)` | Inactive pip |
| `flareRed` | `#F02C1E` | The `FLARE — SERIAL FIELD` tag on card 09 |
| `flareInk` | `#1A0603` | Text on that tag |

> ### Compatibility names — do not drop these
> `virtual_keypad.dart` and the plate wiring in `showcase_screen.dart` already read
> `PosterTokens.accent`, `PosterTokens.hairline`, `PosterTokens.bg` and
> `PosterTokens.invalid`. Those four names must survive the token rewrite so nothing
> device-side has to be touched. Give `accent` the new `#7C5CFF`, keep `invalid` at
> `#F87171`, point `bg` at `stageBlack`, and keep `hairline` at `rgba(255,255,255,.10)`.

### Card decoration colours
Used by the callout cards themselves (§5), not by any plate.

| Token | Value |
|---|---|
| `cardBlueIr` | `#16479D` |
| `cardBlueDe` | `#003399` |
| `euStar` | `#F5D021` |
| flag bands (bright) | `#239F40` / `#EDEFF3` / `#DA0000` |
| flag bands (muted, card 02) | `#1D7A36` / `#B9B4A6` / `#9E1410` |
| chip face | `#EDEFF3`, chip ink `#12141B` |

### Card grounds
| Kind | Value |
|---|---|
| `cardHeroIr` | flat `#16479D` |
| `cardHeroDe` | flat `#003399` |
| `cardSteel` | `linear-gradient(158°, #232C42, #0E1219)` |
| `cardDark` | `linear-gradient(158°, #141926, #080A10)` (variant `#131826 → #080A10`) |
| `cardChipWhite` | flat `#EDEFF3` |
| `cardChipDark` | `linear-gradient(158°, #1C2233, #0D1017)` (variant `#1B2131 → #0C0F16`) |
| `linkButton` | `linear-gradient(158°, #1A2032, #0C0E16)`; hover → `#EDEFF3` |
| `metaStrip` | `rgba(9,8,6,.92)` |

---

## 2. Typography

Four families, all on Google Fonts. The extracted variable TTFs ship in
`assets/fonts/` with their axes intact.

| Family | Axes | Role |
|---|---|---|
| **Archivo** | `wght 100–900`, `wdth 62–125` | Wordmark, English card titles, index chips |
| **Martian Mono** | `wght 100–800`, `wdth 75–112.5` | Eyebrows, meta, stamp, link labels |
| **Newsreader** | `wght 200–800`, `opsz 6–72` | English body copy, the "sole author" italic |
| **Vazirmatn** | `wght 100–900` | All Persian text in the poster layer |

The `wdth` axis is reached with `FontVariation('wdth', 84)` in
`TextStyle.fontVariations`. The design leans on it hard — use real variable fonts, not
static instances.

> These four families are for the **poster layer only**. Nothing inside the device
> changes typeface: the plate keeps whatever `PlateDigit.styleFor` gives it and the
> keypad keeps its current style.

### Specimens (design px @ 1920 canvas)

| Role | Spec |
|---|---|
| Wordmark | Archivo `wght 900`, `wdth 79`, 176px, height `.86`, tracking `-.045em`, 4 lines, uppercase |
| Byline name | Martian Mono `wght 800`, 17px, tracking `.16em`, `#DEE7F4` |
| Byline role | Newsreader `wght 400` italic, 15px, `#8E9DB4` |
| Card eyebrow (hero) | Martian Mono `wght 700`, 13px, tracking `.30em` |
| Card eyebrow (steel) | Martian Mono `wght 700`, 12px, tracking `.28em`, `#9FB6E4` |
| Card eyebrow (dark) | Martian Mono `wght 600`, 12px, tracking `.24em`, `#8F9BB2` / `#8B97AE` |
| Card title EN (hero) | Archivo `wght 800`, `wdth 84`, 42–62px, height `.92–.94`, tracking `-.032em` |
| Card title EN (small) | Archivo `wght 800`, `wdth 86`, 34–36px, height `.96`, tracking `-.025em` |
| Card title FA | Vazirmatn `wght 800`, 34–50px, height `1.18–1.22` |
| Card body EN | Newsreader `wght 400`, 18–24px, height `1.44–1.46` |
| Card body FA | Vazirmatn `wght 400`, 19–23px, height `1.70–1.78` |
| Index chip | Archivo `wght 800`, `wdth 104`, 44–78px |
| Link label | Martian Mono `wght 700`, 14px, tracking `.20em` |
| Meta strong | Martian Mono `wght 600`, 17px, tracking `.14em` |
| Meta weak | Martian Mono `wght 500`, 15px, tracking `.14em` |
| Stamp | Martian Mono `wght 700`, 12px, height `1.55`, tracking `.20em`, centred |
| Red tag (card 09) | Martian Mono `wght 700`, 13px, tracking `.20em`, `#1A0603` |

---

## 3. Textures

Four PNG tiles, extracted to `assets/textures/`.

| File | Tile size in design | Opacity | Blend | Where |
|---|---|---|---|---|
| `bg_grain_a.png` | 256px | `.15` | normal | Stage ground |
| `bg_grain_b.png` | 320px / 250px | `.44` / `.62` | normal / overlay | Stage ground; inside the beam wedge |
| `tex_screen.png` | 140–220px | `.30–.60` | **screen** | Hero cards, white index chips |
| `tex_overlay.png` | 200–240px | `.14–.24` | **overlay** | Card grounds, link buttons |

In Flutter these are `ImageRepeat.repeat` `DecorationImage`s with an explicit
`BlendMode` and the given opacity. Tile size is the CSS `background-size` — the tile is
drawn at that many *design* px regardless of the PNG's own pixel size, so scale it
through `PosterMetrics`.

---

## 4. The bevel-panel recipe

Every callout card, index chip and link button is built from this stack. Build it once
and reuse it — it is the design's signature.

1. **Hard offset shadow** — a duplicate rect at `left+5..8, top+8..12, right−5..−8,
   bottom−8..−12`, filled `rgba(2,2,1,.70–.80)`. No blur. Painted behind.
2. **Ground fill** — one of the card grounds from §1.
3. **Overlay grain** — `tex_overlay.png`, opacity `.14–.24`, `BlendMode.overlay`.
4. **Screen grain** — `tex_screen.png`, opacity `.30–.60`, `BlendMode.screen`
   *(hero cards and white chips only)*.
5. **Diagonal sheen** — `linear-gradient(103°, rgba(…,.22–.30), rgba(…,.04–.06) @44–46%,
   transparent @62–64%)`, `BlendMode.screen`.
6. **Outer bevel** — inset `8–9px`: top/left light, bottom/right dark.
   - hero: light `rgba(226,238,255,.62/.44)`, dark `rgba(0,8,26,.60/.46)`, 3px
   - steel: light `rgba(212,226,252,.46/.30)`, dark `rgba(0,3,10,.64/.50)`, 2px
   - dark: light `rgba(184,200,230,.22–.24/.15–.16)`, dark `rgba(0,2,8,.70/.56)`, 2px
7. **Inner counter-bevel** — inset `10–12px`, **inverted** (top/left dark, bottom/right light).
8. **Screw dots** — two circles near the top edge, `12–17px`, fill `#03050A` / `#04060B`
   / `#04070F`, inner shadow `inset -1..-1.5px -1..-1.5px 0 rgba(light,.32–.52)`.
   Measured from the card's device-facing edge: left for LTR, right for RTL.
9. **Dashed rule** — `repeating-linear-gradient(90°, rgba(…,.32–.72) 0 8–10px,
   transparent 8–10px 16–20px)`, height 2–3px. 8/16 for 2px rules, 10/20 for 3px.
10. **Index chip** — pinned at `left/right: −24..−34px, top: −22..−34px`, itself a bevel
    panel. Chip 01 is rotated `−3.4deg`; chip 05 pins to the opposite edge.

Per-card extras:
- **01** — vertical IR flag strip, `26px` wide, inset `left 22, top 22, bottom 22`,
  `inset 0 0 0 2px rgba(0,8,26,.55), 0 0 0 1px rgba(226,238,255,.30)`.
- **02** — faded vertical flag strip, `5px`, `right 20, top 20, bottom 20`, opacity `.8`.
- **05** — two-tone divider bar, `6px`: dark `rgba(0,8,26,.6)` over light
  `rgba(226,238,255,.46)`, 3px each. Plus a footer row: a 44×26 IR flag beside
  `IR · MOTORBIKE`.
- **09** — EU badge column, `34px` wide: 12 yellow stars (r `1.9`, on a circle of
  r `11.5` about the centre of a 34-unit box) over `D` in Martian Mono `wght 700` 15px.
  Plus the red `FLARE — SERIAL FIELD` tag: ground `#F02C1E`, padding `9 14 10`,
  `inset 0 2px 0 rgba(230,224,244,.6), inset 0 -2px 0 rgba(50,10,30,.5)`.
- **10** — `#003399` vertical strip, `8px`, `right 16, top 16, bottom 16`.

---

## 5. The twelve callouts

These replace the old `calloutSets` copy entirely. `side` drives the motif direction,
**not** screen position.

### Group 0 — `DeviceType.desktop`

| # | Anchor (px / fraction) | Width | Kind | side | Content |
|---|---|---|---|---|---|
| **01** | 626, 132 / `.326, .122` | 536 / `.279` | hero IR | L | eyebrow `COUNTRIES` · title `Two countries,\none widget` (62px) · body `Iranian and German plates ship in the box — same widget, one const swapped.` (24px, max-w 396) |
| **02** | 1636, 44 / `.852, .041` | 250 / `.130` | dark **RTL** | R | eyebrow `صفحه‌کلید` · title `کلیدهای فارسی` (34px) · body `چیدمان حرف‌های پلاک، از پیش آماده.` (19px) |
| **03** | 648, 614 / `.338, .569` | 350 / `.182` | steel | L | eyebrow `VARIANTS` · title `Cars and\nmotorbikes` (36px) · body `One-row and two-row plates, same package.` (20px) |
| **04** | 126, 892 / `.066, .826` | 378 / `.197` | dark **RTL** | L | eyebrow `متن‌باز` · title `ساخته‌ٔ ایران، آزاد` (34px) · *no body* |

### Group 1 — `DeviceType.mobile`

Each card in this group also gets a **slot rail**: a 3px bar at the card's own anchor,
full card width, `rgba(124,92,255,.55)` + glow, animating `scaleX 0 → 1`.

| # | Anchor (px / fraction) | Width | Kind | side | Content |
|---|---|---|---|---|---|
| **05** | 832, 222 / `.433, .206` | 386 / `.201` | hero IR **RTL** | L | eyebrow `تنظیمات` · title `هر بخش از پلاک\nقابل تنظیم` (50px) · two-tone divider · body `رنگ، اندازه، پرچم و رفتار صفحه‌کلید همه در دست تو.` (23px) · footer: IR flag + `IR · MOTORBIKE` |
| **06** | 1656, 268 / `.863, .248` | 244 / `.127` | steel | R | eyebrow `VALIDATION` · title `Checks as\nyou type` (34px) · body `Plate rules are verified field by field.` (19px) |
| **07** | 1586, 40 / `.826, .037` | 306 / `.159` | dark **RTL** | R | eyebrow `حالت‌های خاص` · title `حالت‌های خاص هندل شده` (34px) · body `آن‌هایی که معمولاً از قلم می‌افتند.` (19px) |
| **08** | 158, 886 / `.082, .820` | 366 / `.191` | dark | L | eyebrow `COMPACT` · title `Fits a phone` (34px) · body `Twelve keys, one hand, no layout gymnastics.` (19px) |

### Group 2 — `DeviceType.tablet`

| # | Anchor (px / fraction) | Width | Kind | side | Content |
|---|---|---|---|---|---|
| **09** | 598, 64 / `.311, .059` | 400 / `.208` | hero DE + EU badge | L | eyebrow `RULES` · title `Live\nvalidation` (42px) · body `Forbidden district and serial combinations flare red as you type — before submit, not after.` (18px, max-w 300) · red tag `FLARE — SERIAL FIELD` |
| **10** | 1200, 900 / `.625, .833` | 344 / `.179` | steel + DE strip | R | eyebrow `COUNTRY` · title `Plates are\ndata` (36px) · body `A new country is a const, not a new widget. This one is German.` (20px) |
| **11** | 1556, 36 / `.810, .033` | 320 / `.167` | dark | R | eyebrow `TOUCH` · title `Tap to type` (34px) · body `An on-screen pad drives the plate, field by field, slot by slot.` (19px) |
| **12** | 146, 892 / `.076, .826` | 366 / `.191` | dark **RTL** | L | eyebrow `مقیاس` · title `یک بوم، هر اندازه` (34px) · *no body* |

Group 2's cards use transform origin `100% 12%` (side L) / `0% 12%` (side R).

The RTL cards' eyebrows are set `direction: ltr; text-align: right` in the source — a
Latin-styled label inside an RTL block, so it must not be reordered.

---

## 6. Chrome and backdrop

### Chrome
| Element | Anchor (px / fraction) | Spec |
|---|---|---|
| Byline | 76, 52 / `.040, .048` | `ARAD BIRANVAND` + italic `sole author`, baseline-aligned, gap 14 |
| Wordmark | 70, 186 / `.036, .172`, w 760 / `.396` | `PLATE` `#EAF0FB` · `INPUT` `#D6E1F1` · `FOR THE` `#C4D0E2` · `ROAD` `#1A2130` with a `#BCD3F0` copy masked by `linear-gradient(103.5°, opaque 0–46%, transparent 46%)` — a hard-edged diagonal cut. Glow `0 0 80px rgba(150,180,220,.28–.32)` on lines 1–2. |
| Link buttons | 74, 840 / `.039, .778` | `PUB.DEV` → `https://pub.dev/packages/plate_number`; `GITHUB` → `https://github.com/ArAd1Beyranvand/plate-number-upgrade`. Bevel panel, inner border inset 4px, padding `13 18 14`, gap 10, icon 18px. Hover ground → `#EDEFF3`. |
| Meta strip | 74, 952 / `.039, .882` | `plate_number` (link) │ `pub.dev` │ `MIT`, ground `rgba(9,8,6,.92)`, hairline top `rgba(188,206,235,.18)` / bottom `rgba(0,0,0,.7)`, dividers `rgba(219,200,170,.32)` |
| Inspection stamp | 1618, 944 / `.843, .874`, w 250 / `.130` | `rotate(-6deg)`, double ring `inset 0 0 0 2px rgba(228,214,188,.34), inset 0 0 0 8px rgba(228,214,188,.14)`, text `FORM FACTOR {01|02|03}/03` / `{LAPTOP\|PHONE\|TABLET} — INSPECTED` |
| Form-factor pips | 1876, 448 / `.977, .415` | Column, gap 12, right-aligned. Three 5px bars. Active 28px `#7C5CFF` + glow; idle 14px `rgba(200,212,236,.24)`. `width .24s linear`. |
| Ground shadow | 1030, 872 / `.536, .807`, 900×104 / `.469, .096` | `skewX(-34deg / -30deg / -41deg)` for desktop / mobile / tablet, gradient from §1, blur 2px |

The stamp's labels map to the existing enum as
`desktop → LAPTOP`, `mobile → PHONE`, `tablet → TABLET`, and the numbering follows
`DeviceCycle.order` — `desktop 01`, `mobile 02`, `tablet 03`.

### Backdrop layers (bottom → top)
1. Ground radial (§1).
2. `bg_grain_a` @256px, `.15`.
3. `bg_grain_b` @320px, `.44`.
4. **Beam wedge** — clip `polygon(0% −6%, 100% 23%, 100% 112%, 0% 66%)`, `BlendMode.screen`:
   a radial highlight at `1430,545` (900×520) + a `linear-gradient(99°, …)`, plus a
   blurred bar at `0,380`, `1990×64`, `rotate(12.9deg)`.
   Percentages are of the stage box, and the negative / over-100 values are intentional
   — the clip must be built from the layout size and allowed to exceed it.
5. `bg_grain_b` @250px, `.62`, overlay — clipped to the same wedge.
6. `rgba(70,92,124,.18)` overlay — same wedge.
7. Dark masks: `polygon(0% −6%,100% 23%,100% −40%,0% −40%)` and
   `polygon(0% 66%,100% 112%,100% 145%,0% 145%)`, both `rgba(3,2,1,.72)`.
8. Light rails: `0,−65`, `1946×3`, `rotate(9.26deg)`; `0,713`, `1984×3`,
   `rotate(14.5deg)`. Screen blend.
9. Lane dashes: `−60,322`, `2100×9`, `rotate(11.8deg)`,
   `repeating-linear-gradient(90°, rgba(255,255,255,.92) 0 104px, transparent 104px 172px)`.
10. Sweep (during a hop only): a `400×1500` gradient band plus a `5px` bright edge at
    `x 396`, both `rotate(11.8deg)`, `translateX −560 → 2400`, transition
    `1.5s cubic-bezier(.42,.02,.6,1)`; opacity `.34s linear`.

**Every rotation in the source is `transform-origin: 0 0` — top-left, not centre.**
Use `Transform.rotate(alignment: Alignment.topLeft)` or an explicit `Matrix4`. Getting
this wrong looks plausible and is wrong; check the rail endpoints.

---

## 7. Motion

### 7.1 Where the device sits

The design's shell boxes are used as **stage bounds** — the box the existing
`DeviceFrame` is handed. `DeviceFrame` already fits itself to its constraints, so it
keeps its own preset proportions and letterboxes inside the box. Nothing about the
device changes; only where it sits and how much room it gets.

| Device | left | top | width | height | fraction (L, T, W, H) |
|---|---|---|---|---|---|
| `desktop` | 1012 | 262 | 832 | 486 | `.527, .243, .433, .450` |
| `mobile` | 1300 | 206 | 364 | 698 | `.677, .191, .190, .646` |
| `tablet` | 1004 | 250 | 872 | 600 | `.523, .231, .454, .556` |

Note the composition this creates: the device sits right-of-centre and the wordmark
fills the lower left. That is the main structural change from the old three-column
(rail / device / rail) layout.

The design animates the box over `1.15s cubic-bezier(.5,.02,.24,1)`. **Do not use those
numbers.** Match the box animation to the device's own morph — the existing
`DeviceTransitionDurations.frameTransform` (1500ms) and `DeviceFrame`'s `curve`
(`Curves.easeInOutCubic`) — so the box and the shell inside it move as one. Two
animations of different lengths on the same object reads as a wobble.

The laptop's deck extends below the box; `DeviceFrame` already accounts for that in
`totalSize`/`fitHeight`, so give the box the body height and let the frame handle it.

### 7.2 What drives the poster's motion

The poster layer has **no state machine of its own**. Everything hangs off signals the
existing device stage already emits:

| Signal | Source | Drives |
|---|---|---|
| device changed | the existing `onFrameDeviceChanged` callback, fired the instant a hop starts | callout motifs, stage box, ground-shadow skew, pips, stamp |
| hop in progress | `DeviceFrame.onPhaseChanged` — any phase other than `idle` | the sweep light |

The design's own `go()` / `tick()` / `pre` / `run` machinery is **not** ported. The app
already cycles devices and types plates; it does not need a second clock.

### 7.3 The three motifs

The old `CalloutRail`'s structure is right and stays: one `AnimationController` per
rail, 1500ms, exit on `Interval(0, .45)`, entry on `Interval(.55, 1)`, only ever one set
built. What changes is the transforms, the curves, and which motif belongs to which
device.

**The mapping changed.** Old: desktop→siphon, mobile→sweep, tablet→trapdoor.
New:

| Group | Motif | Rest | Enter from | Exit to |
|---|---|---|---|---|
| `desktop` | **SWEEP** | `translateX(0)` | `translateX(∓520)` | `translateX(∓520)` |
| `mobile` | **TRAPDOOR** | `translateY(0)` | `translateY(-90)` | `translateY(+90)` |
| `tablet` | **SIPHON** | `translateX(0) scale(1)` | `translateX(-nudge) scale(.04)` | `translateX(+nudge) scale(.04)` |

`nudge` is `+18` for side L, `−18` for side R. Sweep's sign is `−520` for L, `+520` for R.
Siphon's transform origin is `100% 12%` (L) / `0% 12%` (R) — that is what makes it
collapse toward the device-facing edge rather than its own centre.

Easing curves:

| | in | out |
|---|---|---|
| sweep | `cubic-bezier(.215,.61,.355,1)` | `cubic-bezier(.55,.055,.675,.19)` |
| trapdoor | `cubic-bezier(.25,.46,.45,.94)` | `cubic-bezier(.55,.085,.68,.53)` |
| siphon | `cubic-bezier(.34,1.56,.64,1)` | `cubic-bezier(.36,0,.66,-.56)` |

`sipIn` overshoots past 1 and `sipOut` undershoots below 0. Flutter's `Cubic` handles
both — do not clamp them, the overshoot is the point.

Group opacity is separate from the transform: outgoing fades over the exit interval,
incoming over the entry interval, so the old set is fully gone before the new arrives.

**Slot rails** (mobile group only): `scaleX 0 → 1` from the leading edge over `.3s
linear`, with a `.74/1.5 ≈ .49` fractional delay when the phone is the incoming device
and none when it is outgoing.

---

## 8. Responsive re-derivation

```dart
enum PosterTier { wide, medium, compact }
// wide:    width >= 1240 && height >= 700
// medium:  width >= 760
// compact: everything else
```

A `PosterMetrics` InheritedWidget carries the tier, a fluid factor
`f = (width / 1920).clamp(lo, 1.0)`, and the stage `Size`. Every font size, gap and
anchor goes through it. Suggested `lo`: `.52` wide, `.46` medium; a fixed step-down
table on compact.

| Tier | Layout |
|---|---|
| **wide** | The full poster. Backdrop → device stage at its `GEO` fraction → callout layer → chrome layer. Everything anchored fractionally. |
| **medium** | Wordmark scales down into a top band. Device stage centred, with the `GEO` fractions re-anchored to the stage box rather than the screen. **Two** callouts per group only — `01/03`, `05/06`, `09/10` — in fixed-width rails flanking the stage. Stamp and pips move to a bottom bar. |
| **compact** | Single scrolling column: byline → wordmark → device stage in a fixed-aspect box → all four callouts full-width and stacked with index chips inline → links → meta. Motifs degrade to a fade plus a 24px slide. |

Constant at every tier: the bevel recipe, the four families and their variable axes, the
colour tokens, the motif mapping and each card's RTL/LTR handedness.

The device stage is unchanged at every tier — it is handed a box and fits itself. On
compact, give it a box with the laptop's aspect and let it letterbox; do not
special-case the device.

---

## 9. Notes

### 9.1 Layering bugs in the design worth fixing
- The `01` and `09` index chips cover the first characters of their own eyebrows
  (`COUNTRIES` renders as `NTRIES`, `RULES` as `S`). Nudge the eyebrow or the chip.
- Cards `04` / `08` / `12` and the link buttons overlap and clip the meta strip. Give
  the chrome its own layer above the callouts, or move the strip.

### 9.2 The design's own device art is reference only
The design draws its own laptop, phone and tablet, its own plates and its own keyboards.
None of that is a specification. In particular, ignore: its plate slot counts, its
German plate layout, its Persian digit strings, its keypad grids and its
`SLOT n / N` status chip. The real device and the real plate already exist and are
staying exactly as they are.

### 9.3 Vestigial values in the source
`renderVals` emits `tabBg*`, `tabFg*`, `tabHi*`, `tabLo*`, `tabTex*`, `tabSeam*` and
`pick0/1/2` for a form-factor picker that is not present in the markup. Ignore them.
