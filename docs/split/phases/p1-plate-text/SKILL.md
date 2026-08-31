---
name: p1-plate-text
description: "Phase P1 of the plate split (second edition) — move plate-text grouping out of the PlateText widget and into PlateSpec, and collapse ShowPlate/PlateText's duplicated empty state into one widget. Use when the user asks to run P1 or work on plate text rendering."
---

# P1 — Plate text into the model

Follow `CLAUDE.md` working style. **Requires nothing** — this is the first phase of the second
edition. This project does not use automated tests: do not write or update anything under
`test/`, and do not run `flutter test`. Finish analyzer-clean in both repos, committed; report
diffstat and hashes only.

Read `docs/split/PLAN.md` §2 and §5 first if you have not.

## Why

`lib/widgets/show_plate.dart` holds two widgets that share an empty state verbatim and one of
which does model work in its `build`:

```dart
// PlateText.build, lines 58-60
final groups = spec.textGroups.isEmpty
    ? [for (var i = 0; i < spec.slots.length; i++) PlateTextGroup([i])]
    : spec.textGroups;
```

That "empty means one group per slot" rule is documented on `PlateSpec.textGroups` and
implemented in a widget. It is a property of the spec. **P2 needs it in the model** — its
`PlateEntry.activeGroup` has to answer "which group is index 4 in?" without a widget in
scope — so it moves now rather than getting copied a second time.

The same file also renders each group inline:

```dart
Text(g.prefix + g.indices.map((i) =>
    spec.slotAt(i)?.alphabet.render(values[i] ?? '') ?? '').join())
```

`spec.slotAt(i)` inside a `map` inside a `for` is a linear scan per glyph per frame. The
rendered string of a group is model work too.

And both widgets carry the identical fallback:

```dart
emptyPlate ?? const Text('Default Widget for Empty Plate Value', style: TextStyle(fontSize: 18))
```

— a developer-facing placeholder string that would ship to end users.

## Do

### `lib/model/plate_spec.dart`

1. Add to `PlateSpec`:

```dart
/// [textGroups] if non-empty, else one group per slot in index order — the
/// rule [textGroups]'s own doc comment describes. Callers should read this
/// rather than reimplementing the fallback.
List<PlateTextGroup> get effectiveTextGroups;

/// The group in [effectiveTextGroups] containing [index], or null when
/// [index] is outside every group.
PlateTextGroup? groupAt(int index);

/// [group]'s prefix followed by each of its slot values rendered through
/// that slot's alphabet. Unset slots render as ''.
String renderGroup(PlateTextGroup group, List<String?> values);
```

   `effectiveTextGroups` must not allocate a fresh list on every read for the common case —
   when `textGroups` is non-empty, return it. When it is empty, build the fallback once and
   cache it in a `late final` field; `PlateSpec` is `@immutable` and `const`-constructed, so
   the cache belongs on a lazily-initialised private field, or the fallback is cheap enough to
   build per call and you say so in the report. Pick one deliberately — do not leave a
   `const` constructor broken to install a cache.

2. `valueOfGroup(String key, …)` already walks `textGroups` directly. Point it at
   `effectiveTextGroups` so a spec with no declared groups behaves consistently, and note in
   its doc comment that an unkeyed spec has no keyed groups by definition.

3. While you are in this file: `slotAt` is a linear scan. `PlateSlot` lost its `index` field
   in the first edition, so position **is** list position — `slotAt(i)` should be a bounds
   check and a `slots[i]`. If it already is, say so and move on.

### `lib/widgets/show_plate.dart`

4. Extract the shared empty state into one private widget:

```dart
class _EmptyPlate extends StatelessWidget {
  const _EmptyPlate(this.replacement);
  final Widget? replacement;
  …
}
```

   Keep the current default *text* — do not invent a better string, that is a product change —
   but it is worth one line in the report that "Default Widget for Empty Plate Value" is
   developer-facing copy sitting in a shipping default.

5. `PlateText.build` becomes a loop over `spec.effectiveTextGroups` calling
   `spec.renderGroup(g, values)`. The `if (g.indices.any(...))` non-empty guard stays in the
   widget — whether to *show* an empty group is a rendering decision, not a model one.

6. `ShowPlate` is unchanged apart from the shared empty state.

### Barrel

7. No new files, so `lib/plate_number.dart` needs no new export. Confirm that rather than
   assuming it.

### `plate_number_holder`

8. Nothing in the holder should need to change. **Verify that rather than assuming it** —
   grep for `textGroups`, `PlateTextGroup` and `valueOfGroup` in the holder before you claim
   it. If something turns up, it is a call site this phase owns.

## Widgets, not widget functions

Per `PLAN.md` §5, in the files this phase already edits. `show_plate.dart` has no widget
functions today, and step 4 adds a widget class rather than a helper — so there is likely
nothing to convert. Say so in the report; do not go looking in files this phase does not
touch.

## Verify

```
cd plate-core            && flutter analyze
cd ../plate_number_holder && flutter analyze
```

(Do not run `flutter test`.)

Then run the showcase and confirm the plain-text rendering is character-for-character what it
was: the Iranian car plate's four groups with the `'IR '` prefix on the last, in RTL order,
and the German plate's three. A group that renders in a different order, or a prefix that
moved, means `effectiveTextGroups` is not returning `textGroups` in declaration order.

Also record `lib/`'s current line count in `docs/split/PROGRESS.md` — the second edition has no
measured baseline yet and this is the phase that establishes it:

```bash
cd plate-core && find lib -name '*.dart' | xargs wc -l | tail -1
```

Expected: ~35 lines out of `lib/`, no behaviour change, and `PlateSpec` able to answer the
three questions P2 is about to ask it.
