# AUDIT_DIAGNOSIS — plate monorepo

Structural audit of `~/StudioProjects/plate/`, all packages except `plate_number_holder/`.
Conducted from the source as it stands; no prior plan, manifest or migration doc was read.

**Scope:** 7 packages, 73 Dart files, 12,449 lines.

| Package | lib | example | test | Version | Depends on |
|---|---:|---:|---:|---|---|
| `core_plate` | 3,070 | 27 | **0** | 0.5.0 | flutter, flutter_svg |
| `core_plate_bloc` | 417 | 123 | **0** | 0.1.0 | core_plate, bloc, flutter_bloc |
| `plate_keypad` | 531 | 47 | **0** | 0.1.0 | core_plate |
| `iran_plate` | 235 | 27 | **0** | 0.1.0 | core_plate |
| `germany_plate` | 245 | 30 | **0** | 0.1.0 | core_plate |
| `palestine_plate` | 1,855 | 1,237 | 542 | 0.1.0 | core_plate |
| `yemen_plate` | 3,168 | 895 | **0** | 0.2.0 | core_plate |

---

## Executive summary

### Structural duplication
- **44 of yemen_plate's 55 `const PlateSpec`s exist only to vary one field**, as `northern_plates.dart:615-617` states outright: *"Four layouts x five usages, and the only fields that vary with usage are `id` and `country`."* Every spec in a usage family shares `canvasWidth/Height`, `panel`, `slots`, `mirrors`, `rules`, `labels`, `textGroups` and `borderWidthRatioOverride` through named private consts, and differs from its siblings in `id` and `country` alone (`northern_plates.dart:621-1018`, `unified_plates.dart:373-786`). Palestine repeats the pattern at small scale (`west_bank_plates.dart:219`, `:234`).
- **15 `PlateTheme` literals across two packages are the same shape.** 14 of 15 verifiably set `plateBorder == ink == dividerColor == activeColor`; the 15th (`YemenThemes.unified`) sets two differently-named constants that hold the same value. Each literal is ~11 lines of which 4 are the same colour repeated.
- **The `~/^[0-9]+$/` digit regex is declared three times** (`palestine_validators.dart:6`, `yemen_validators.dart:40`, `:129`), and a fourth variant in `german_plate_validator.dart:56`. All six validators in the workspace repeat one control shape: *return valid while group X is empty, else delegate to a static `validateFields`*.
- **`PlateTextView` (`plate_view.dart:82-112`) and `PlateText` (`show_plate.dart:61-87`) are the same 30-line widget** over two data sources, and `_noCharacterChooser` is declared verbatim in both files.

### Coupling violations
- **`core_plate`'s own example imports `iran_plate`** (`core_plate/example/lib/main.dart:3`; `core_plate/example/pubspec.yaml:14`). The engine's example is a byte-level near-clone of `iran_plate`'s and creates a dev-time cycle: `iran_plate → core_plate`, `core_plate/example → iran_plate`.
- **`PlateSpec` carries colour after all.** `core_plate.dart:10-14` states the package "does not know any country" and both country packages state "colour never lives on a `PlateSpec`" — yet `PlateSpec.country` is a `PlateCountry`, which carries `panelColor` and `panelTextColor`. Both packages work around this identically and both document the workaround: Palestine mints three country consts that differ only in ink (`palestine_country.dart:47/57/66`) and Yemen mints six northern consts over a `_transparent` panel (`yemen_country.dart:132-194`). `west_bank_plates.dart:215-218` names the cause exactly: *"A whole second spec for one colour because `PlateCountry` carries its own text colour and `PlateSpec` carries a country: there is no way to recolour the block from the theme."*
- **No package boundary is violated by imports.** The import graph is clean and acyclic (below). The leaks are in what the types carry, not in who imports whom.

### Dead weight
- **Constraint rot that would break every published consumer.** `core_plate` is at 0.5.0. `iran_plate`, `germany_plate`, `palestine_plate` and `plate_keypad` all declare `core_plate: ^0.1.0` (= `>=0.1.0 <0.2.0`); `yemen_plate` declares `^0.2.0`. They compile only because of `dependency_overrides`. Published as-is, each would resolve a core that predates `PlateController`, `PlateView`, `PlateSelector`, `PlateAsset`, `SlotBehavior`, `PlateMirror` and the required `onChooseCharacter` parameter.
- **Nine `dependency_overrides` blocks in three different mechanisms** (in `pubspec.yaml`, in `pubspec_overrides.yaml`, in example pubspecs) with no workspace to make them unnecessary; `palestine_plate/pubspec.yaml:47` carries one in the *published* pubspec.
- **~2.7 MB of stale documentation and artefacts inside published package directories**, including `core_plate/docs/poster_assets.zip` (2.6 MB), nine prior phase plans, a byte-identical duplicate of `DESIGN_SPEC.md` at two paths, and `plate_number.iml` — an IDE module named after a package that no longer exists.
- **Three deprecated symbols with zero call sites** across the whole workspace: `PlateInputController`, `PlateController.activeSlotIn`, `RemovePlateCard`. Two are marked for removal in 0.6.0, which has not happened.
- **Four empty directories** under `palestine_plate/lib/src/`: `generator/`, `models/`, `render/`, `validation/`.

### Rendering problems
- **There is no layout vocabulary, so every register is a hand-unrolled `for` loop.** `PlateBox(left, top, width, height)` is the only geometry primitive core has, and a plate is not a bag of rectangles — it is a few *registers*: runs of equal cells at a constant pitch, separated by wider gaps. Core already knows this semantically (`PlateTextGroup` names exactly those runs) but geometry does not, so the two are declared independently and drift. **281 `PlateBox` literals** across the four country packages, roughly 140 of them inside a provably regular run. Clearest case: `unified_plates.dart:159-184` writes twenty-four `PlateRule`s at x=838 with y stepping by 12 — 26 lines for one loop — and `_motoStipple` (`:276`) does it again in 24 more.
- **Three registers have already drifted arithmetically, and nothing can catch it.** `debugValidateSpec` checks that boxes fit the canvas and that mirrors point at real slots; it does not check that a register is evenly pitched, and `yemen_plate` has no tests at all. See the drift table below.
- **`plate_canvas.dart` is sound.** Its per-slot `ValueListenable` bindings, the resolved-once `SlotBehavior` list and the `_PlateFaceClipper` overlap fix are all correct and well-argued. This file is not where the debt is.
- **The one real model/widget split is the country panel.** `CountryPanel` lays `captionLines` out as a `Column`, always. Palestine works around it twice — once by packing two glyphs into one string (`palestine_country.dart:92`), once by abandoning the panel entirely and drawing two `PlateLabel`s plus a `PlateRule` (`:119`) — and documents both as core limitations.
- **`PlateSlotItem` re-derives `isTyped` from the alphabet** (`plate_slot_item.dart:62`) and switches on it inside three of five `SlotBehavior` arms, after the canvas already resolved behaviour once. The five-arm switch collapses to three real widgets.

### Frame budget (reported symptom: animations lag at the start and again partway through)
All animation in the workspace is 9 constructs in `plate_keypad.dart`, 2 in `palestine_plate/example/lib/main.dart` and 2 in `plate_canvas.dart`. Reading them turns up ten candidates; the four that matter most:
- **`ThemeData.light().copyWith(...)` runs on every `PlateCanvas.build`** (`plate_canvas.dart:279`). A complete Material theme — colour scheme, text theme, ~30 sub-themes — rebuilt per build, when it depends on one colour.
- **The Palestine demo rebuilds the entire screen on every keystroke** (`example/lib/main.dart:266-284`), and defers it to `addPostFrameCallback`, so the rebuild lands one frame late. This defeats the whole per-slot `ValueListenableBuilder` architecture the canvas is built around — and it fires mid-typing, which is mid-animation.
- **The keypad's hidden letters grid is built and laid out unconditionally** (`plate_keypad.dart:194`): up to 30 keys ≈ 150 widgets, constructed while translated off-screen, on every pad build — and the pad rebuilds whenever `activeAlphabet` changes, i.e. as focus moves between slots while typing.
- **Nothing precaches anything.** Four SVG flags and three PNG decals are parsed or decoded on the first frame that shows them. A plate appearing *as* an animation starts pays that cost inside the animation's first frame — a precise match for the start-of-animation half of the symptom.

Two further per-frame costs: 46 `PlateRule` widgets redrawn per unified-plate build where one `CustomPaint` would do, and up to 42 simultaneous implicit `AnimatedContainer` decoration tweens when `activeAlphabet` changes. Full list and a measure-fix-remeasure protocol in `P12_animation_frame_budget.md`.

### Widget factory bloat
- Not the problem this codebase has. `_Placed`, `_FrameBinding`, `_SlotBinding`, `_MirrorBinding`, `_ValidationBinding`, `_VerdictListener`, `_KeyGrid`, `_Key` are all real classes with narrow subscriptions. The equivalent bloat lives **in the example apps**, where `_PlateStage`, `_Section`, `_PickerRow` and `_SampleCard` are 90–100% identical between `palestine_plate/example` and `yemen_plate/example`, and each of those two apps ships **two** `void main()` entry points (`main.dart` and `gallery.dart`) with a duplicated catalogue.

### Implicit defaults
- **`PlateKeypad._rows` hard-codes `1-9,0,⌫` in Latin order** (`plate_keypad.dart:128-133`) regardless of `digitAlphabet.characters`. An alphabet like `YemenAlphabets.governorateTens` (`['0','1','2']`) still draws ten keys and greys seven.
- **`'⌫'` is a magic literal in three places** (`:132`, `:314`, `:433`) with a parallel `kPlateBackspaceKey` sentinel.
- **`_Caption._baseFontSize = 24.0`** (`country_panel.dart:98`) is an unparameterised constant; the panel's 10% uniform padding default (`:42`) is likewise hard-coded.
- **No font is reachable.** `PlateTheme.glyphStyle` (`plate_theme.dart:98`) names no `fontFamily`, and `PlateCanvas` wraps its face in `Theme(data: ThemeData.light()...)` (`plate_canvas.dart:279`, `:429`), so a host's `DefaultTextStyle` cannot reach a glyph. Both Palestine and Yemen document this as a shipped limitation.
- Good news: RTL is **not** inferred anywhere. `PlateAlphabet.direction` and `PlateSpec.textDirection` are explicit fields with correct doc comments.

---

## Dependency graph

```
                    flutter_svg
                         │
                    ┌────▼─────┐
        ┌───────────│core_plate│───────────┬──────────────┐
        │           └────┬─────┘           │              │
        │                │                 │              │
┌───────▼──────┐  ┌──────▼──────┐  ┌───────▼──────┐  ┌────▼─────┐
│ iran_plate   │  │germany_plate│  │palestine_pl. │  │yemen_plate│
└───────┬──────┘  └─────────────┘  └──────┬───────┘  └──────────┘
        │                                 │
        │  ┌────────────┐          ┌──────▼──────┐
        │  │plate_keypad│──────────│  (example)  │
        │  └────────────┘          └─────────────┘
        │
        └──► core_plate/example      ◄── VIOLATION: engine example
                                          depends on a country
core_plate_bloc ──► core_plate  (+ bloc, flutter_bloc)   [leaf; nothing imports it]
```

**Facts:**
- No country package imports another country package. No country package imports `plate_keypad` or `core_plate_bloc`.
- `plate_keypad` imports `core_plate` for `PlateAlphabet` only.
- `core_plate_bloc` is a leaf: nothing in the workspace depends on it.
- `flutter_svg` is a hard dependency of `core_plate` for `PlateFlag` alone. Yemen ships no flag and pays for it transitively.
- The only edge that should not exist is `core_plate/example → iran_plate`.

**Declared vs. actual `core_plate` constraint:**

| Package | Declares | Resolves via override to | Would break if published? |
|---|---|---|---|
| `iran_plate` | `^0.1.0` | 0.5.0 | **Yes** |
| `germany_plate` | `^0.1.0` | 0.5.0 | **Yes** |
| `palestine_plate` | `^0.1.0` | 0.5.0 | **Yes** |
| `plate_keypad` | `^0.1.0` | *(not overridden — pub.dev)* | **Yes** |
| `yemen_plate` | `^0.2.0` | 0.5.0 | **Yes** |
| `core_plate_bloc` | `^0.5.0` | 0.5.0 | No |

`plate_keypad/example/pubspec.yaml:24` overrides `plate_keypad` but **not** `core_plate`, so alone among the examples it does not build against the local engine.

---

## Redundancy matrix

| Concern | core_plate | plate_keypad | iran | germany | palestine | yemen | Verdict |
|---|---|---|---|---|---|---|---|
| Digit alphabet (`0`–`9`, typed, numeric) | `latinDigits` | — | `fa.digits` | *(uses core)* | `ps.digits` | `ye.digits`, `ye.easternDigits` | **Justified** — `debugValidateSpec` keys on characters+glyphs; both packages document why |
| Restricted digit subset | — | — | — | — | `ps.districtDigits`, `ps.gazaPrefix` | `ye.govTens`, `ye.easternGovTens` | Justified, same reason |
| `RegExp(r'^[0-9]+$')` | — | — | — | `{1,4}` variant | 1× | 2× | **Duplicated — move to core** |
| "quiet until group X filled → `validateFields`" shape | — | — | — | 1× | 3× | 2× | **6 copies of one control flow** |
| `PlateTheme` monochrome literal | `standard()` | — | — | — | 8× | 7× | **15 copies — needs a `monochrome` primitive** |
| Usage → theme lookup | — | — | — | — | `forUsage`, `forGazaUsageCode` | `forNorthernUsage`, `forUnifiedUsage` | Country-specific; shape is shared |
| Usage → country lookup | — | — | — | — | *(implicit in spec choice)* | `unifiedFor`, `northernFor` | Yemen's is the better idiom |
| `PlateCountry` consts per country | — | — | 1 | 1 | **7** | **12** | Palestine/Yemen counts are a symptom, not data |
| Spec catalogue surface | — | — | *(none)* | *(none)* | `.all` lists | `carGeometries`/`motoGeometries` maps + `car()`/`moto()` | **Four different idioms; no shared contract** |
| Serial generator | — | — | — | — | positional, spec-blind | spec-driven via text groups | **Two idioms; Yemen's is correct** |
| Slot-index lookup by group key | `valueOfGroup` (values only) | — | — | — | — | private `_indicesOf` | **Belongs in `PlateSpec`** |
| Evenly-pitched register, written cell by cell | *(no primitive)* | — | 14 slots | 7 slots | ~40 slots | 15 slots + 21 mirrors | **~140 of 281 `PlateBox` literals are an unrolled loop** |
| Constant-pitch rule run (stipple) | *(no primitive)* | — | — | — | — | 46 rules / 50 lines | **Two `for` loops written out by hand** |
| Echo band (same register at another y) | *(no primitive)* | — | — | — | — | 4 mirror lists, ~150 lines | **Re-declares the slot geometry verbatim** |
| Transparent panel literal | — | — | — | — | `Color(0x00000000)` ×7 | `_transparent` ×6 | Symptom of colour-on-spec |
| Read-only text renderer | `PlateTextView` | — | — | — | — | — | *(and `PlateText` in bloc)* — **2 copies** |
| No-op character chooser | `_noCharacterChooser` | — | — | — | — | — | *(and 1 in bloc)* — **2 copies** |
| Example scaffold widgets | — | 1 file | 1 file | 1 file | 2 entry points | 2 entry points | **`_PlateStage`/`_Section`/`_PickerRow`/`_SampleCard` 90–100% identical PS↔YE** |
| `analysis_options.yaml` | 1,545 B | 1,774 B | 1,774 B | 1,774 B | 1,774 B | 1,774 B | **6 identical copies + 2 example copies; no shared base** |

---

## Is the size difference real? Cost per plate

`germany_plate` is 245 lines and `yemen_plate` is 3,168 — a 13× spread that looks alarming. Normalised
per **distinct plate geometry**, counting code lines only (comments and blanks excluded), most of it
dissolves:

| Package | code | doc | declared specs | real geometries | **code / geometry** |
|---|---:|---:|---:|---:|---:|
| `germany_plate` | 150 | 72 | 1 | 1 | **150** |
| `iran_plate` | 180 | 43 | 2 | 2 | **90** |
| `palestine_plate` | 904 | 802 | 13 | 13 | **70** |
| `yemen_plate` | 1,817 | 1,101 | 55 | **11** | **165** |

Three readings:

1. **Most of the spread is real.** Yemen models eleven plate geometries across two concurrent national
   systems; Germany models one. Per design, the four packages are within about 2× of each other, and
   Palestine — the second-largest — is the *most* economical in the repo.
2. **Some of it is documentation, and that is a feature.** 35% of `yemen_plate` and 43% of
   `palestine_plate` is doc comments, much of it recording calibration provenance and what the package
   deliberately does not claim. Do not "reduce" it.
3. **The genuine excess is two things, and they are separate problems.** 44 of Yemen's 55 specs are usage
   clones (≈575 code lines, removed by P4). What remains — the gap between Palestine's 70 and Yemen's
   165 — is almost exactly the hand-unrolled geometry: Yemen is the only package with mirrors (30) and
   the only one with a stipple (46 rules), and both are written out cell by cell.

### The three drifts

Consecutive cells of one register, at a constant `top` and `height`, that are not at a constant pitch:

| File:line | Register | Pitch sequence | Rule says | Consequence |
|---|---|---|---|---|
| `yemen_plate/.../northern_plates.dart:240` | `_carGov2Serial4` | 98, **97**, 98 | 390/4 = 97.5 | third cell 1 unit left; the register ends at **531** where every sibling ends at 530 |
| `yemen_plate/.../northern_plates.dart:526` | `_motoGov2Serial5` | 42, 42, **41**, 42 | 209/5 = 41.8 | fourth cell 1 unit left |
| `palestine_plate/.../west_bank_plates.dart:399` | `modernMoto` serial | **31.5**, 32, 32 | one value | one cell 0.5 unit out |

The sibling layouts prove the rule: `_carGov2Serial5` is exactly 78 (390/5) and `_carGov2Serial6` is
exactly 65 (390/6). Only the case that does not divide evenly was rounded by hand, and only that case is
wrong. All three are invisible to `debugValidateSpec` and to every existing test.

---

## File-by-file findings

Severity: **H** = will break a consumer or corrupt data · **M** = structural debt with a real cost · **L** = hygiene.

### core_plate

| File:line | Sev | Finding |
|---|---|---|
| `pubspec.yaml` (all consumers) | **H** | Version 0.5.0 while four dependents pin `^0.1.0`. See matrix above. |
| `lib/src/validators/plate_validator.dart:58` | M | Public API doc points at `docs/split/PLAN.md §1` — a prior plan file, shipped inside the package. |
| `lib/src/model/plate_spec.dart:68` | M | `PlateDecal.image` doc example says `package: 'plate_number'` — a package that does not exist. |
| `lib/src/model/plate_country.dart:12-50` | **H** | Carries `panelColor`/`panelTextColor`. Because `PlateSpec.country` is required, colour is on the spec, contradicting `core_plate.dart:10` and forcing 19 country consts downstream. **Root cause of the largest duplication in the repo.** |
| `lib/src/model/plate_country.dart:11` | L | Doc refers to constants living "in their own files (`countries/…`)" — no such directory exists. |
| `lib/src/model/plate_box.dart` (whole file) | **H** | `PlateBox` is the *only* geometry primitive. No register, no run, no echo band — so every regular layout is unrolled by hand in the country packages, and three have drifted. |
| `lib/src/model/plate_spec.dart:261-326` | **H** | `debugValidateSpec` validates containment and alphabet ids but **not** register evenness, which is the one invariant a hand-written layout actually violates. |
| `lib/src/widgets/country_panel.dart:60-82` | M | Caption is always a `Column`. No horizontal arrangement, no per-line style. Two documented Palestine workarounds. |
| `lib/src/widgets/country_panel.dart:98` | L | `_baseFontSize = 24.0` unparameterised. |
| `lib/src/widgets/plate_view.dart:11` + `core_plate_bloc/.../show_plate.dart:7` | M | `_noCharacterChooser` declared verbatim twice. |
| `lib/src/widgets/plate_view.dart:82-112` + `show_plate.dart:61-87` | M | `PlateTextView` and `PlateText` are the same widget over two sources. `PlateView` takes `theme:`; `ShowPlate` does not. |
| `lib/src/widgets/plate_slot_item.dart:62,83-124` | M | `isTyped` re-derived and switched on inside three `SlotBehavior` arms. Five arms, three outcomes. |
| `lib/src/widgets/plate_slot_item.dart:199-203` | L | `TODO(national-numerals)` — typed fields show ASCII, so a Persian/eastern digit slot in `imeField` mode displays Latin. |
| `lib/src/widgets/plate_canvas.dart:279` | **H** | `ThemeData.light().copyWith(...)` constructed on **every build**. Depends only on `theme.activeColor`; should be cached on that. |
| `lib/src/widgets/plate_canvas.dart:345-349` | M | Every `PlateRule` becomes a `_Placed`→`Positioned`→`ColoredBox`. Yemen's unified plate has 46 of them: 46 widgets built, laid out and painted per canvas build to draw a dotted line. `PlateFrame` already proves the `CustomPainter` alternative in this same package. |
| `lib/src/widgets/plate_canvas.dart:331` | L | `_PlateFaceClipper` allocated per build (`shouldReclip` prevents the reclip, not the allocation). |
| `lib/src/widgets/plate_canvas.dart:596` | L | `_SlotBinding.build` mutates a `TextEditingController` during build via `syncController`. Guarded and documented, but a `ChangeNotifier` write inside build can schedule an extra frame. |
| `lib/src/widgets/plate_flag.dart:32-43` | M | `SvgPicture.asset` built inline with no precache path and no doc telling a host to warm it. First paint of any flagged plate pays the SVG parse. |
| `lib/src/input/plate_input_controller.dart:22` | M | `PlateInputController` typedef — deprecated for 0.6.0, **zero call sites**. |
| `lib/src/input/plate_controller.dart:264-268` | M | `activeSlotIn` — deprecated for 0.6.0, **zero call sites**. |
| `lib/core_plate.dart:83-86, 110-113, 121-126` | L | Three comment blocks narrating removals "in P7"/"in P8"/"in 0.4.0" — changelog prose in a barrel file. |
| `lib/` (whole package) | **H** | **Zero tests.** 3,070 lines including all value migration, focus, behaviour resolution and spec validation. |
| `claude.md` + `CLAUDE.md` | L | Two files differing only in case; one clobbers the other on a case-insensitive checkout. |
| `DESIGN_SPEC.md` + `docs/DESIGN_SPEC.md` | L | Byte-identical duplicates (24,674 B each). |
| `docs/poster_assets.zip` | L | 2.6 MB binary inside a publishable package. |
| `docs/split/`, `docs/migration/`, `docs/all prompts.md`, `REFACTOR_MANIFEST.md` | L | ~120 KB of prior-plan prose, referenced from live API docs. |
| `plate_number.iml` | L | IDE module named after a defunct package. |

### yemen_plate

| File:line | Sev | Finding |
|---|---|---|
| `lib/src/northern_plates.dart:621-1018` | **H** | 25 `const PlateSpec`s over **5** geometries. 20 differ from a sibling only in `id` and `country`. |
| `lib/src/unified_plates.dart:373-786` | **H** | 30 `const PlateSpec`s over **6** geometries. 24 are usage clones. |
| `lib/src/northern_plates.dart:1028-1088`, `unified_plates.dart:796-855` | M | Two hand-written 5×N const lookup maps enumerate the clones; they must be edited in lockstep with every spec added. |
| `lib/src/unified_plates.dart:159-184`, `:276-299` | M | `_carStipple` (24 rules, 26 lines) and `_motoStipple` (22 rules, 24 lines) are one `for` loop each, unrolled by hand. 50 lines for two constant-pitch runs. |
| `lib/src/northern_plates.dart:240` | **H** | `_carGov2Serial4` pitch is 98, **97**, 98 — the only serial length that does not divide 390 evenly is the only one that is wrong. Its register ends at 531; every sibling ends at 530. |
| `lib/src/northern_plates.dart:526` | **H** | `_motoGov2Serial5` pitch is 42, 42, **41**, 42. |
| `lib/src/northern_plates.dart:295-490` | M | Four `PlateMirror` lists, 21 literals, ~150 lines, re-declaring the slot registers' x and width verbatim at a different `top`. A northern plate prints its number twice; the geometry is written twice to say so. |
| `lib/src/yemen_country.dart:44` | M | `YemenCountry.unified` — **zero references**; self-documented as unused. |
| `lib/src/yemen_country.dart:188` | M | `northernMilitaryModern` — **zero references**; self-documented as unused. |
| `lib/src/yemen_themes.dart:50-131` | M | 7 monochrome `PlateTheme` literals, 12 lines each. |
| `lib/src/yemen_validators.dart:40,129` | M | Same `RegExp` declared twice in one file. |
| `lib/src/yemen_serial_generator.dart:130-139` | M | Private `_indicesOf(spec, key)` — a `PlateSpec` capability implemented in a country package. Reads `spec.textGroups`, not `effectiveTextGroups`. |
| `lib/src/yemen_usage.dart:91-94` | L | `onNorthern`'s doc says it is "derived from `unifiedLatin`"; the body is `this != YemenUsage.police`. |
| `lib/src/yemen_governorates.dart:68` | L | `TODO(control-map)` on published data. |
| `example/pubspec.yaml:23` | L | Cites `plate_canvas.dart:227 and :355`; the actual lines are **279** and **429**. |
| `lib/` | **H** | Zero tests for 3,168 lines, 55 specs and 2 validators. `flutter_test` is a declared dev-dependency with no `test/`. |

### palestine_plate

| File:line | Sev | Finding |
|---|---|---|
| `lib/src/palestine_country.dart:47,57,66` | **H** | Three `PlateCountry` consts identical but for `panelTextColor`. Forces `legacyCarPublicTransport` and `legacyCarGovernment` to exist. |
| `lib/src/west_bank_plates.dart:215-218` | **H** | Comment names the cause: *"A whole second spec for one colour because `PlateCountry` carries its own text colour and `PlateSpec` carries a country: there is no way to recolour the block from the theme."* |
| `lib/src/palestine_themes.dart:46-173` | M | 8 monochrome `PlateTheme` literals; `borderWidthRatio: 0.027` written out 8 times where Yemen uses a private const. |
| `lib/src/palestine_themes.dart:105-115` | M | `forUsage` maps two Gaza-only usages into Gaza themes, mixing two designs behind one West Bank lookup. |
| `lib/src/west_bank_plates.dart:399` | M | `modernMoto`'s serial pitch is **31.5**, 32, 32 — a hand-rounded register. Not covered by the golden. |
| `lib/src/palestine_serial_generator.dart:25-53` | M | Emits fixed positional lists and never reads the spec; correct only because all 9 West Bank specs share two group tables. Yemen's spec-driven generator is the right idiom. |
| `lib/src/palestine_validators.dart:6` | M | Third copy of the digit regex. |
| `lib/src/{generator,models,render,validation}/` | L | Four empty directories. |
| `test/failures/*.png` (4 files) | M | Golden-diff artefacts newer (`wb_modern_car_green`) than the master image — **the golden test appears to be failing right now**. Establish this baseline before any refactor. |
| `pubspec.yaml:47` | M | `dependency_overrides` in the published pubspec (every other package uses `pubspec_overrides.yaml`). |
| `images.jpeg` (34 KB) | L | Stray file at package root. |
| `example/lib/main.dart:266-284` | **H** | `_onPlateChanged` calls `setState(() {})` on the whole screen for every controller notification, and defers it to `addPostFrameCallback` when mid-frame — so every keystroke costs one extra, fully-rebuilt, one-frame-late build. Defeats the canvas's per-slot bindings entirely. |
| `example/lib/main.dart` + `example/lib/gallery.dart` | M | Two `void main()`s, duplicated `_Kind` enum and catalogue, 1,237 lines total. |

### plate_keypad

| File:line | Sev | Finding |
|---|---|---|
| `lib/src/plate_keypad.dart:98` | M | **Corrupted doc comment**: `/// gimme cloc command to would reject them anyway —`. An editing artefact committed into a public API doc. |
| `lib/src/plate_keypad.dart:128-133` | M | Digit grid hard-codes Latin `1-9,0,⌫`; `digitAlphabet` only restyles labels. |
| `lib/src/plate_keypad.dart:132,314,433` | L | `'⌫'` magic literal in three places alongside `kPlateBackspaceKey`. |
| `lib/src/plate_keypad.dart:194` | **H** | `Positioned.fill(child: _buildLettersLayer(...))` is unconditional: up to 30 keys (~150 widgets) built and laid out while slid off-screen, on every pad build. The pad rebuilds whenever `activeAlphabet` changes — during typing. |
| `lib/src/plate_keypad.dart:261-266` | M | `AnimatedBuilder` rebuilds an `IgnorePointer` on all ~16 frames of the 260 ms slide to flip a bool that changes twice. |
| `lib/src/plate_keypad.dart:412-431` | M | Two implicit animations per key (84 across a full pad). An `activeAlphabet` change starts up to 42 simultaneous 180 ms `BoxDecoration` tweens. |
| `lib/src/plate_keypad.dart:169,230,311,408,428` | M | Per-build allocations on the animated path: two fresh lists per pad build, a `Duration` and a dimmed `Color` per key per build, and a `Builder` element per grid cell. |
| `example/pubspec.yaml:22-24` | M | Overrides `plate_keypad` but not `core_plate`. Alone among examples, it resolves the engine from pub.dev at `^0.1.0`. |

### germany_plate / iran_plate

| File:line | Sev | Finding |
|---|---|---|
| `germany_plate/lib/src/german_plate_validator.dart:16,50` | M | API doc references `docs/districts.json` "deleted in P8" and `docs/split/PLAN.md §1` — neither path exists in this package. |
| `germany_plate/lib/src/german_plate_validator.dart:56` | L | Fourth digit-regex variant. |
| `iran_plate` | L | No validator, no catalogue surface, no tests — the thinnest country package and the model the others should converge on. |

### core_plate_bloc

| File:line | Sev | Finding |
|---|---|---|
| `lib/src/plate_card_event.dart:22` | M | `RemovePlateCard` — deprecated for 1.0.0, **zero dispatchers**. |
| `lib/src/plate_card_event.dart:24` | L | `SpecIsChanged` — no dispatcher anywhere in the workspace; untested. |
| `lib/src/show_plate.dart:26-32` | M | `ShowPlate` takes no `theme:`, so a bloc host cannot render a coloured Palestinian or Yemeni plate. `PlateView` can. |
| `lib/` | M | Zero tests for the two-way `PlateCardBinding` mirror — the one genuinely tricky piece of state plumbing in the repo. |

### Workspace root

| Path | Sev | Finding |
|---|---|---|
| *(no root `pubspec.yaml`)* | **H** | No pub workspace and no melos. Nine `dependency_overrides` blocks in three mechanisms substitute for one. |
| `debug.log`, `omniroute.log`, `omniroute-debug.log` | L | Runtime logs at repo root. |
| `PLATE_CONTROLLER_PLAN.md` (64 KB), `PROMPT_palestine_plate.md` (28 KB), `PROMPT_yemen_plate.md` (25 KB) | L | Prior-plan prose at repo root. |
| `*/build/`, `*/.dart_tool/` | L | Build output on disk, including a checked-in Chrome profile under `palestine_plate/example/.dart_tool/chrome-device/` (cookies, login data, session storage). Verify `.gitignore` coverage. |

---

## The one sentence

The engine is well built and the country data is carefully researched; the debt is concentrated in **two
missing abstractions and a build layer** — `PlateCountry` carries colour and text and sits on `PlateSpec`
(forcing 44 clone specs, 19 country consts and 15 theme literals), core has no register primitive so
every regular layout is a `for` loop unrolled by hand (281 box literals, three already drifted), and there
is no workspace, no tests for 6,700 lines of engine and country logic, and version constraints that would
break on the day anything is published.

The size difference between the packages is, on the other hand, **mostly honest**: per plate geometry all
four cost within 2× of each other, and Yemen is large because Yemen has eleven plate designs.
