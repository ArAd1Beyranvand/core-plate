---
name: p8
description: "P8 — extract the one text-rendering widget core_plate and core_plate_bloc each ship a copy of, share the no-op character chooser, and give ShowPlate the theme and country parameters PlateView already has. Invoke with /p8 in a fresh session."
---

> **Run this in a fresh session** (`/clear` first).
> **Model:** Sonnet 5 · **reasoning:** low · **extended thinking:** off
> **Requires:** /p1
> Full index: `/phases` · evidence: `claude/AUDIT_DIAGNOSIS.md` · overview: `claude/REFACTOR_ROADMAP.md`

# P8 — Core surface: one text renderer, one no-op chooser

## Context (assume nothing else)

Two packages ship read-only plate views over the same engine:

- `core_plate/lib/src/widgets/plate_view.dart` (113 lines) — `PlateView` and `PlateTextView`, both driven
  by a `PlateController`. `PlateView` narrows to `(spec, isEmpty)` through a `PlateSelector` and forwards
  to `PlateCanvas` in `PlateMode.display`.
- `core_plate_bloc/lib/src/show_plate.dart` (88 lines) — `ShowPlate` and `PlateText`, the same pair driven
  by `PlateCardBloc` state through a `BlocBuilder`.

Three duplications, all verifiable by grep:

**1. `_noCharacterChooser` is declared verbatim in both files** (`plate_view.dart:11`,
`show_plate.dart:7`):

```dart
Future<String?> _noCharacterChooser(PlateAlphabet _) async => null;
```

Both carry the same explanatory comment at the call site: *"Display mode never opens a chooser;
`onChooseCharacter` is required since the keypad split, so satisfy it with one that is never called."*

**2. `PlateTextView.build` (`plate_view.dart:82-112`) and `PlateText.build` (`show_plate.dart:61-87`) are
the same 30-line widget.** Both build a `DefaultTextStyle` over a `Directionality(spec.textDirection)`
over a `Row(mainAxisAlignment: spaceEvenly)` whose children are one `Text(spec.renderGroup(g, values))`
per `effectiveTextGroups` entry that has at least one non-empty value, with the same bounds check
(`i < values.length`) and the same comment explaining it. They differ in exactly one thing: where `spec`
and `values` come from.

**3. `ShowPlate` takes neither `theme:` nor `country:`; `PlateView` takes both** (`country:` as of P3).
So a bloc-shaped host cannot render a coloured Palestinian or Yemeni plate at all — every plate comes out
in `PlateTheme.standard()`'s black on white. That is not a duplication, it is a capability gap that the
duplication hid.

## Scope

**In:**
- `core_plate/lib/src/widgets/plate_view.dart`
- `core_plate/lib/src/widgets/plate_text_row.dart` — new
- `core_plate/lib/core_plate.dart` — export the new primitive
- `core_plate/test/plate_text_row_test.dart` — new
- `core_plate_bloc/lib/src/show_plate.dart`
- `core_plate_bloc/test/show_plate_test.dart` — new (this package has no tests)
- Both `CHANGELOG.md`s

**Out — frozen:**
- **The public names `PlateView`, `PlateTextView`, `ShowPlate`, `PlateText`** and their existing
  parameters. `yemen_plate/example` uses `PlateView`; `core_plate_bloc/example` uses both
  `PlateText` and `PlateTextView` side by side deliberately, to show the two routes.
- **`PlateCanvas`.** Untouched by this phase.
- **`PlateSelector`** and the `(PlateSpec, bool)` narrowing in `PlateView.build` — it is the reason a
  keystroke does not rebuild the display view, and it is documented as such.
- **`PlateCardBloc`, `PlateCardState`, `PlateCardBinding`, the events.** State plumbing is not this
  phase's business; the deprecated `RemovePlateCard` is P9's.
- Rendering output. `PlateTextView` and `PlateText` must produce identical widget trees after the change.

## Steps

### 1. Extract `PlateTextRow`

New file `core_plate/lib/src/widgets/plate_text_row.dart`:

```dart
/// The plain-text rendering of a plate: each of [spec]'s effective text groups,
/// rendered through its slots' alphabets, laid out in the plate's own reading
/// direction.
///
/// The shared body of [PlateTextView] (controller-driven) and `PlateText` from
/// `core_plate_bloc` (bloc-driven). Those two differ only in where they read
/// [spec] and [values]; everything below the read was the same 30 lines in both
/// packages.
///
/// A group with no non-empty value is omitted rather than rendered blank, and
/// an index past the end of [values] is skipped rather than thrown on — so a
/// frame built against a longer spec than the value list it is handed renders a
/// short plate instead of crashing.
class PlateTextRow extends StatelessWidget {
  const PlateTextRow({
    super.key,
    required this.spec,
    required this.values,
    this.textStyle,
  });

  final PlateSpec spec;
  final List<String?> values;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) => DefaultTextStyle(
        style: textStyle ?? const TextStyle(color: Color(0xFF000000)),
        child: Directionality(
          textDirection: spec.textDirection,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final g in spec.effectiveTextGroups)
                if (g.indices.any((i) => i < values.length && (values[i] ?? '').isNotEmpty))
                  Text(spec.renderGroup(g, values)),
            ],
          ),
        ),
      );
}
```

Two details:

- The default style. `PlateTextView` uses `const TextStyle(color: Colors.black)` and so does `PlateText`.
  `Colors.black` is `0xFF000000`, so `const Color(0xFF000000)` is the same value and lets the file import
  `package:flutter/widgets.dart` rather than `material.dart`. Confirm the two are equal before committing —
  if in doubt, keep `material.dart` and `Colors.black`; matching the pixel matters more than the import.
- Move the bounds-check comment from `plate_view.dart:98-101` here. It is the only place it belongs now.

Export it from `core_plate.dart` beside `plate_view.dart`, with a one-line doc.

### 2. Add the shared no-op chooser

In `plate_text_row.dart` or a small `lib/src/widgets/_chooser.dart` — either is fine, but it must be
**public**, because `core_plate_bloc` is a separate package and cannot reach a private:

```dart
/// A character chooser that never chooses: for [PlateMode.display], where
/// `PlateCanvas.onChooseCharacter` is required but is never called.
Future<String?> noCharacterChooser(PlateAlphabet alphabet) async => null;
```

Export it. Delete both private copies and both call-site comments (the doc above replaces them).

### 3. Rewrite `PlateTextView`

Its `build` becomes a `ListenableBuilder` on the controller wrapping a `PlateTextRow`:

```dart
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => controller.isEmpty
          ? (emptyPlate ?? const SizedBox.shrink())
          : PlateTextRow(
              spec: controller.spec,
              values: controller.values,
              textStyle: textStyle,
            ),
    );
```

### 4. Rewrite `PlateText` and widen `ShowPlate`

`PlateText.build` becomes the same shape over a `BlocBuilder`, keeping `_EmptyPlate`.

Then give `ShowPlate` the two parameters it lacks:

```dart
  const ShowPlate({super.key, this.emptyPlate, this.theme, this.country});

  /// The livery to paint, or null to inherit from an ancestor `PlateThemeScope`.
  /// `PlateView` has taken one since 0.4.0; a bloc-shaped host needs it just as
  /// much — without it every plate renders in `PlateTheme.standard()`, which is
  /// wrong for any country whose plate is not black on white.
  final PlateTheme? theme;

  /// The country block to paint, overriding the state spec's own. See
  /// [PlateCanvas.country].
  final PlateCountry? country;
```

Forward both to `PlateCanvas`. Both default to null, so no existing caller changes behaviour.

`_EmptyPlate` (`show_plate.dart:40-49`) is now used by `PlateText` only — inline it or keep it; either is
fine, keep the doc comment truthful about who uses it.

### 5. Tests

`core_plate/test/plate_text_row_test.dart`:
- An empty group renders nothing; a partly-filled group renders through the alphabet's glyphs.
- Group order follows `spec.textDirection`; `prefix` is prepended.
- `values` shorter than `slots` renders the groups that fit and does not throw.
- `textStyle` null gives black.

`core_plate_bloc/test/show_plate_test.dart` — first test in this package:
- `ShowPlate` with a `theme:` renders that theme's background (pump and read the painted colour, or assert
  on the `PlateCanvas`'s `theme` argument via `tester.widget`).
- `ShowPlate` with a `country:` renders that country's caption.
- `PlateText` and `PlateTextView` produce the same text for the same values — pump both over a
  `PlateCardBinding` and compare `find.text` results. This is the assertion that pins the extraction.

## Verification

```bash
cd ~/StudioProjects/plate

(cd core_plate && flutter test && flutter analyze --no-fatal-infos)
(cd core_plate_bloc && flutter test && flutter analyze --no-fatal-infos)

grep -rn "_noCharacterChooser" --include=*.dart .     # no output
grep -rn "MainAxisAlignment.spaceEvenly" --include=*.dart */lib/
#   -> exactly one hit, in plate_text_row.dart

(cd core_plate_bloc/example && flutter run -d linux --debug)
#   -> the PlateText line under the plate still updates on every keystroke,
#      and still matches the PlateTextView above it

(cd palestine_plate && flutter test)                  # golden unchanged
```

**Success:** one `PlateTextRow` in the repo; one public `noCharacterChooser`; `ShowPlate` accepts
`theme:` and `country:`; `core_plate_bloc` has its first tests; the bloc example renders identically.

## Dependencies

P1. P3 if you want `ShowPlate.country` in the same pass — if P3 has not run, ship `theme:` only and leave
a `TODO(P3)` for the country parameter.

## Line estimate

`plate_text_row.dart` +48 (new) · `plate_view.dart` −34 · `show_plate.dart` −30 + 14 ·
`core_plate.dart` +6 · tests +115. **Net ≈ −45 of production code, +70 including tests.**
