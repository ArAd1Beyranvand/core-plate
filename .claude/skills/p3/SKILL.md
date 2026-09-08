---
name: p3
description: "P3 — make the country block a render-time input on PlateCanvas and PlateView, the way the theme already is, so a spec stops being pinned to one colour scheme and one caption. Core only; no country package changes. Invoke with /p3 in a fresh session."
---

> **Run this in a fresh session** (`/clear` first).
> **Model:** Opus 5 · **reasoning:** high · **extended thinking:** ON
> **Requires:** /p1
> Full index: `/phases` · evidence: `claude/AUDIT_DIAGNOSIS.md` · overview: `claude/REFACTOR_ROADMAP.md`

# P3 — Render-time country override

## Context (assume nothing else)

`core_plate/lib/core_plate.dart:10-14` states the package's central rule: *"It does not know any country…
a country name in this package, even in a comment, is the bug."* The import graph honours that
completely — no core file names a country.

But there is a leak the import graph cannot show. `PlateSpec` (`lib/src/model/plate_spec.dart:136`)
requires a `PlateCountry`, and `PlateCountry` (`lib/src/model/plate_country.dart:13`) carries
**`panelColor` and `panelTextColor`** — two colours. So a `const PlateSpec` is pinned to one colour
scheme, even though both country packages state in their own docs that *"colour never lives on a
`PlateSpec` — a spec is geometry"*.

The two countries with a usage-varying design both hit this and both wrote the workaround down:

- `palestine_plate/lib/src/west_bank_plates.dart:215-218`:
  *"A whole second spec for one colour because `PlateCountry` carries its own text colour and `PlateSpec`
  carries a country: there is no way to recolour the block from the theme."* — which is why
  `legacyCarPublicTransport` and `legacyCarGovernment` exist alongside `legacyCar` with identical
  geometry.
- `palestine_plate/lib/src/palestine_country.dart:18-39` mints `westBankGreenInk`, `westBankWhiteInk`
  and `westBankRedInk` — three consts identical but for `panelTextColor`, all with `code: 'ps'` so they
  compare equal — over a transparent panel, and explains that this is what "collapses six schemes into three".
- `yemen_plate/lib/src/yemen_country.dart:132-194` mints six northern consts over a `_transparent`
  panel purely to carry a usage word in `captionLines`, and says so at `:17-28`.

Downstream, this forces **44 of yemen_plate's 55 specs** and **2 of palestine_plate's 13** to exist only
to name a different `country:`.

The theme is already a render-time input: `PlateCanvas(theme:)` overrides `PlateTheme.of(context)`.
This phase gives the country block the same treatment. It is the pivot the whole roadmap turns on.

## The design

**Do not add `copyWith` to `PlateSpec`, and do not make `country` nullable.**

`PlateSpec` equality is over `id` alone (`plate_spec.dart:250`), and three things key off that:
`PlateCanvas.didUpdateWidget` (`plate_canvas.dart:121`) rebuilds the input machine when `spec.id`
changes, `PlateController.adoptSpec` migrates values on a swap, and `PlateCardState` compares specs.
A `copyWith` that kept the id would produce two unequal specs that compare equal; one that changed the id
would trigger a spurious machine rebuild and value migration on every usage change. Both are wrong.

Instead, add an optional `country:` to the two widgets that render a plate. `spec.country` stays required
and stays the default. Nothing about identity, migration or focus moves.

```dart
  /// The country block to paint, overriding [PlateSpec.country].
  ///
  /// A spec is geometry; which country block sits in the panel is a render-time
  /// choice, exactly as [theme] is. A design whose panel text or ink varies with
  /// something the spec does not encode — a vehicle's usage class, say — passes
  /// the block here instead of minting a second spec that differs in one field.
  ///
  /// Null keeps [PlateSpec.country], so every existing call site is unaffected.
  final PlateCountry? country;
```

## Scope

**In:**
- `core_plate/lib/src/widgets/plate_canvas.dart` — add the field, thread it to `CountryPanel`.
- `core_plate/lib/src/widgets/plate_view.dart` — add the same field, forward it.
- `core_plate/lib/src/model/plate_country.dart` — doc only.
- `core_plate/lib/core_plate.dart` — doc only.
- `core_plate/test/plate_country_override_test.dart` — new.
- `core_plate/CHANGELOG.md`.

**Out — frozen:**
- **`PlateSpec` itself.** No new field, no `copyWith`, no nullable `country`. Explained above.
- **`PlateCanvas`'s build structure.** Add a parameter and use it in exactly one place — the
  `CountryPanel(country: ...)` call at `plate_canvas.dart:339-343`. The per-slot `ValueListenableBuilder`
  bindings, the `behaviors` list, `_PlateFaceClipper`'s `_overlap = 0.75` seam fix and the post-frame
  active-index announcement are load-bearing for rendering and animation timing across three platforms.
  Do not touch them.
- `PlateInputMachine`, `PlateController`, `SlotBehavior` — the override is presentational and reaches
  none of them.
- **Every country package.** P4 and P5 consume this; P3 only builds it.
- `core_plate_bloc`. `ShowPlate` gaining a `country:` (and a `theme:`, which it also lacks) is P8's business.

## Steps

### 1. `PlateCanvas`

- Add `this.country` to the constructor (optional, unnamed default null) and the field with the doc above.
- At the top of `build`, beside the existing theme resolution at `:252-256`:
  ```dart
  final country = widget.country ?? spec.country;
  ```
- Pass it to `CountryPanel` at `:339`. That is the **only** use.
- `_PlateFaceClipper`, the mirrors, the labels, the rules and the slots are all unaffected — none of them
  reads `spec.country`.

Confirm by grep that `spec.country` / `widget.spec.country` appears exactly once in the file after the change.

### 2. `PlateView`

`PlateView` (`plate_view.dart:21`) forwards to `PlateCanvas` in display mode. Add `this.country`, document
it as "forwarded to [PlateCanvas.country]", and pass it through at `:53-61`.

`PlateTextView` does **not** get one — it renders characters, not chrome.

### 3. Documentation

- `plate_country.dart` class doc: add a paragraph saying a country value is data a *renderer* is handed,
  that `PlateSpec.country` is the default rather than the only route, and that a design whose panel varies
  with a runtime axis passes it at render time.
- `plate_country.dart:11` currently says the concrete constants "live in their own files (`countries/…`)".
  No such directory exists in any package. Correct the sentence to say they live in each country's package.
- `core_plate.dart`: one line under the widgets section noting the override.
- `CHANGELOG.md`: a `0.6.0` entry, additive, no breaking change.

### 4. `core_plate/test/plate_country_override_test.dart`

Use `testWidgets` and pump a `PlateCanvas` in `PlateMode.display` (no IME, no focus complications) over a
two-slot local spec whose country has a distinctive `panelColor` and `captionLines`.

- With no `country:`, the panel paints `spec.country`'s caption — find it with `find.text(...)`.
- With `country:` set to a different `PlateCountry`, the panel paints the override's caption and the
  spec's caption is absent.
- The override changes **nothing else**: slot glyphs, label text and rule count are identical between the
  two pumps. Assert on `find.text` counts for the slot values and labels.
- Swapping `country:` on a live canvas (pump, then pump again with a different country) does **not**
  rebuild the input machine: assert `onActiveIndexChanged` fires no extra times and the controller's
  values are untouched. This is the property that makes the override safe and the `copyWith` approach unsafe.
- `PlateView(country:)` forwards it.
- A country whose `flag` is null renders no flag and the caption still appears (the Yemen/West Bank case).

## Verification

```bash
cd ~/StudioProjects/plate

(cd core_plate && flutter test && flutter analyze --no-fatal-infos)

# Every existing caller is unaffected: nothing outside core changed.
git status --porcelain | grep -v '^.. core_plate/'   # must print nothing

# The countries still build and render identically.
for p in iran_plate germany_plate palestine_plate yemen_plate plate_keypad core_plate_bloc; do
  (cd "$p" && flutter analyze --no-fatal-infos) || echo "FAIL $p"
done
(cd palestine_plate && flutter test)        # golden unchanged — no pixel moved

# spec.country is read in exactly one place in the canvas
grep -n "spec.country\|widget.spec.country" core_plate/lib/src/widgets/plate_canvas.dart   # one hit
```

**Success:** `PlateCanvas` and `PlateView` accept `country:`; the Palestine golden passes untouched;
no file outside `core_plate/` changed; the new test proves a country swap does not disturb the input
machine or the controller.

## Dependencies

P1 (engine tests must exist before the engine's API grows).

## Line estimate

`plate_canvas.dart` +18 · `plate_view.dart` +12 · docs +14 · `CHANGELOG.md` +6 · new test +95.
**Net +145 with the test, +50 of production code.**
