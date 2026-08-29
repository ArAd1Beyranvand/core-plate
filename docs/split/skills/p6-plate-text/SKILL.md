---
name: p6-plate-text
description: "Refactor phase P6 of the plate_number split — move plate-string rendering out of the PlateText widget into PlateSpec, and merge ShowPlate and PlateText's duplicated empty-state. Use when the user asks to run P6 or work on plate text rendering."
---

# P6 — Plate text into the model

Follow `CLAUDE.md` working style. Independent of P4 and P5 — runnable any time after P2.
Finish analyzer-clean, tests green, committed; report diffstat and hashes only.

## Why

`lib/widgets/show_plate.dart` holds two widgets that share a 12-line preamble
(`BlocBuilder` → `state.plateNumber.isEmpty()` → fall back to `emptyPlate`) and differ only in
what they render afterwards.

Worse, `PlateText`'s body contains the library's only implementation of "render a plate as
text": the empty-`textGroups` fallback, the per-group character mapping through
`alphabet.render`, the prefix handling, and the non-empty-group filter. That is model logic
living in a widget, so it can only be tested by pumping one — and `PlateSpec.valueOfGroup`
already does a near-identical walk for validators, duplicating the group scan.

Both widgets also ship the string `'Default Widget for Empty Plate Value'` as a user-visible
default. No published package should render that.

## Do

### `lib/model/plate_spec.dart`

1. Add to `PlateSpec`:

```dart
/// [textGroups] if set, else one group per slot in index order. The fallback
/// every caller was writing for itself.
List<PlateTextGroup> get effectiveTextGroups;

/// The rendered text of each group, in [textDirection] reading order, with
/// each character mapped through its slot's alphabet and the group's prefix
/// applied. Groups with no set character are omitted.
List<String> renderGroups(List<String?> values);

/// The whole plate as one string, groups joined by [separator].
String render(List<String?> values, {String separator = ' '});
```

2. Reimplement `valueOfGroup(String key, List<String?> values)` on top of the same group scan
   so there is one walk, not two. Keep its exact current semantics: **canonical storage form,
   not rendered glyphs**, and `''` when no group carries that key. Validators depend on
   getting ASCII back — do not route it through `alphabet.render`.

   Write that difference down in the doc comments of both methods. It is the kind of thing a
   later refactor unifies by accident and breaks the German validator with.

### `lib/widgets/show_plate.dart`

3. One private widget class carries the shared preamble (a class, not a function —
   `claude.md` §1):

```dart
class _PlateStateBuilder extends StatelessWidget {
  const _PlateStateBuilder({required this.emptyPlate, required this.builder});
  final Widget? emptyPlate;
  final Widget Function(BuildContext, PlateCardState) builder;
  …
}
```

   The `builder:` callback is permitted — it is the `BlocBuilder`-shaped exception
   `claude.md` §1 names.

4. `ShowPlate` and `PlateText` each become ~12 lines wrapping it.
5. Both `emptyPlate` defaults become `const SizedBox.shrink()`. Delete the placeholder string
   from both. Note it in `CHANGELOG.md` as a behaviour change — a consumer relying on the
   visible placeholder will now see nothing, which is the correct default but is not
   source-compatible in effect.
6. `PlateText.build` reduces to a `Row` over `spec.renderGroups(values)` inside the existing
   `Directionality` and `DefaultTextStyle`.

### Tests

7. New `test/plate_text_test.dart`, no widget pumping:
   - `irCar` with a full value renders four groups, `'IR '` prefix intact on the last
   - a partly-filled plate omits wholly-empty groups but keeps partly-filled ones
   - Persian digits render as `۰`–`۹` through `renderGroups` while `valueOfGroup('serial', …)`
     returns ASCII
   - a spec with no `textGroups` (`irBicycle`) falls back to one group per slot

## Verify

```
cd plate-number-upgrade   && flutter analyze && flutter test
cd ../plate_number_holder && flutter analyze && flutter test
```

Then check the holder's callout cards, which render plate strings — the German plate should
still read `DA X1953` with the same spacing.

Expected: ~35 net lines removed from `lib/`, and plate-string rendering becomes testable
without Flutter.
