---
name: p2
description: "P2 — add a PlateTheme.monochrome primitive to core and collapse the 15 near-identical theme literals in palestine_plate and yemen_plate onto it. Invoke with /p2 in a fresh session."
---

> **Run this in a fresh session** (`/clear` first).
> **Model:** Sonnet 5 · **reasoning:** medium · **extended thinking:** off
> **Requires:** /p1
> Full index: `/phases` · evidence: `claude/AUDIT_DIAGNOSIS.md` · overview: `claude/REFACTOR_ROADMAP.md`

# P2 — `PlateTheme.monochrome`

## Context (assume nothing else)

`core_plate/lib/src/theme/plate_theme.dart` defines `PlateTheme`, an immutable colour + ratio bundle
with nine fields: `plateBackground`, `plateBorder`, `ink`, `dividerColor`, `borderWidthRatio`,
`plateRadiusRatio`, `activeColor`, `inactiveColor`, `alertColor`. It has one factory,
`PlateTheme.standard()`, plus `copyWith`, `glyphStyle` and a `PlateThemeScope` inherited widget.

Two country packages declare 15 `PlateTheme` literals between them:

- `palestine_plate/lib/src/palestine_themes.dart:46-173` — 8 literals
  (`greenOnWhite`, `whiteOnGreen`, `redOnWhite`, `whiteOnBlue`, `gazaBlack`, `gazaGreen`, `gazaBlue`, `gazaRed`).
- `yemen_plate/lib/src/yemen_themes.dart:50-131` — 7 literals
  (`unified`, `northernPrivate`, `northernForHire`, `northernTransport`, `northernGovernment`,
  `northernMilitaryClassic`, `northernMilitaryModern`).

**All 15 are monochrome:** each sets `plateBorder`, `ink`, `dividerColor` and `activeColor` to the same
colour. (14 do so by naming one constant four times; `YemenThemes.unified` names `unifiedFrame` once and
`unifiedInk` three times, and both constants hold `0xFF111111`.) Each literal is 11–12 lines of which four
are the same value repeated, and every one of them is a calibration target — `palestine_colors.dart` and
`yemen_colors.dart` mark nearly every constant `// CALIBRATE`. Today, recalibrating one plate's ink means
editing four fields in the right literal and getting all four right.

`PSThemes` also repeats `borderWidthRatio: 0.027` and `plateRadiusRatio: 0.10` as literals eight times;
`YemenThemes` already hoists them into `_borderWidthRatio` / `_unifiedRadiusRatio` private consts.

## Scope

**In:**
- `core_plate/lib/src/theme/plate_theme.dart` — add one `const` factory.
- `core_plate/test/plate_theme_test.dart` — new.
- `palestine_plate/lib/src/palestine_themes.dart` — rewrite the eight literals.
- `yemen_plate/lib/src/yemen_themes.dart` — rewrite the seven literals.

**Out — frozen:**
- **Every colour value.** This phase must not change a single rendered pixel. `PSColors` and
  `YemenColors` are untouched. If a rewrite would change a colour, the rewrite is wrong.
- The public names of all 15 theme constants and both `forUsage`-style lookups. Hosts and the
  Palestine golden test reference them by name.
- `PlateTheme.standard()`, `copyWith`, `glyphStyle`, `PlateThemeScope`, `_props`, equality — unchanged.
  `standard()` is **not** monochrome (`plateBorder` `0xFF000000` vs `ink` `0xFF0A0A0A`) and must stay
  exactly as it is.
- `alertColor`'s default.
- Anything in `plate_canvas.dart`.

## Steps

### 1. Add the primitive

In `plate_theme.dart`, beside `standard()`:

```dart
  /// A plate printed in one ink on one field: the shape every country theme in
  /// this workspace actually has.
  ///
  /// [ink] is the border, the glyphs, the rules and the completed-field
  /// outline — a real plate does not print its divider in a different colour
  /// from its digits, and writing those four out separately means a
  /// recalibration can move three of them and miss the fourth.
  ///
  /// [inactive] is input chrome only: the outline core paints under an empty
  /// field. It is never printed, so it takes no default — a dark field needs a
  /// light outline and a grey one vanishes.
  const PlateTheme.monochrome({
    required Color field,
    required Color ink,
    required Color inactive,
    required double borderWidthRatio,
    required double plateRadiusRatio,
    Color alertColor = const Color(0xFFF87171),
  }) : this(
         plateBackground: field,
         plateBorder: ink,
         ink: ink,
         dividerColor: ink,
         borderWidthRatio: borderWidthRatio,
         plateRadiusRatio: plateRadiusRatio,
         activeColor: ink,
         inactiveColor: inactive,
         alertColor: alertColor,
       );
```

It must be `const` — every one of the 15 call sites is a `static const`, and losing constness would
push theme construction onto the build path.

### 2. Rewrite `palestine_themes.dart`

Hoist the ratios first, matching what `YemenThemes` already does:

```dart
  /// 7px of border and 26px of corner radius on the 260px-tall reference image
  /// `pics/reference_plate.png`. Every Palestinian scheme prints the same.
  static const double _borderWidthRatio = 0.027;
  static const double _plateRadiusRatio = 0.10;
```

Then each theme becomes, e.g.:

```dart
  static const PlateTheme greenOnWhite = PlateTheme.monochrome(
    field: PSColors.white,
    ink: PSColors.green,
    inactive: PSColors.inactiveGreen,
    borderWidthRatio: _borderWidthRatio,
    plateRadiusRatio: _plateRadiusRatio,
  );
```

Map each of the eight one-for-one. Keep every doc comment — they carry the calibration provenance
(which reference image, which usage code, why Gaza is not a recolouring of the West Bank), and that
prose is the most valuable thing in the file.

The `forUsage` and `forGazaUsageCode` switch bodies do not change.

### 3. Rewrite `yemen_themes.dart`

Same shape. `_borderWidthRatio` and `_unifiedRadiusRatio` already exist — keep both names.

For `YemenThemes.unified`, the mechanical rewrite is `ink: YemenColors.unifiedInk`, which drops the
reference to `YemenColors.unifiedFrame`. **Both constants hold `0xFF111111`, so this is pixel-identical.**
Leave `unifiedFrame` defined in `yemen_colors.dart` with a one-line note that it is now unreferenced and
is a candidate for P9, rather than deleting it here — it is documented as a distinct calibration target
and that is a data decision, not a refactoring one.

`forNorthernUsage` and `forUnifiedUsage` do not change.

### 4. Add `core_plate/test/plate_theme_test.dart`

- `PlateTheme.monochrome` sets `plateBorder == ink == dividerColor == activeColor == ink`.
- It is usable in a `const` context (`const t = PlateTheme.monochrome(...)` compiles).
- `alertColor` defaults to `0xFFF87171` and is overridable.
- `copyWith` on a monochrome theme changes only the named field — in particular
  `copyWith(activeColor: ...)` (which `PlateCanvas` uses for the alert state) leaves `ink` alone.
- Equality holds across a monochrome theme and the equivalent longhand literal.

## Verification

The whole point is that nothing renders differently. Prove it three ways.

```bash
cd ~/StudioProjects/plate

# 1. No colour constant moved.
git diff --stat palestine_plate/lib/src/palestine_colors.dart yemen_plate/lib/src/yemen_colors.dart
#    -> palestine_colors.dart unchanged; yemen_colors.dart at most a comment line.

# 2. The golden still matches — this is the pixel proof.
(cd palestine_plate && flutter test)
#    If wb_modern_car_green now differs, a colour moved. Revert and find it.
#    Do NOT run --update-goldens in this phase.

# 3. Engine tests and analysis.
(cd core_plate && flutter test && flutter analyze --no-fatal-infos)
for p in palestine_plate yemen_plate; do (cd "$p" && flutter analyze --no-fatal-infos); done
```

Equality check as a belt-and-braces assertion — add this temporarily to a scratch test, confirm it passes,
then delete it:

```dart
expect(PSThemes.greenOnWhite, const PlateTheme(
  plateBackground: PSColors.white, plateBorder: PSColors.green,
  ink: PSColors.green, dividerColor: PSColors.green,
  borderWidthRatio: 0.027, plateRadiusRatio: 0.10,
  activeColor: PSColors.green, inactiveColor: PSColors.inactiveGreen,
));
```

Repeat for all 15 before deleting. `PlateTheme`'s `==` is over all nine fields, so this is exhaustive.

**Success:** the Palestine golden passes unchanged; all 15 constants keep their names and compare equal
to their old values; `palestine_themes.dart` and `yemen_themes.dart` each shrink by ~45 lines;
`flutter analyze` is clean everywhere.

## Dependencies

P1 (the engine test suite must exist before the engine's public API grows).

## Line estimate

`plate_theme.dart` +32 · `plate_theme_test.dart` +55 · `palestine_themes.dart` −48 · `yemen_themes.dart` −42.
**Net ≈ −3 with the test, −95 excluding it.**
