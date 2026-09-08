## 0.2.0

**Breaking: removed the deprecated `RemovePlateCard` event.** Nothing dispatched
it. Clear the plate through `PlateController.clear()` on the controller the
`PlateCardBinding` mirrors.


**`ShowPlate` gains `theme:` and `country:`.** `PlateView` has taken a `theme:`
since 0.4.0 and a `country:` since core 0.5.0; `ShowPlate` took neither, so a
bloc-shaped host could only ever render `PlateTheme.standard()`'s black on
white — wrong for any coloured plate. Both parameters default to null and
forward straight to `PlateCanvas`, so no existing caller changes.

**`PlateText` and `ShowPlate` share core's primitives.** `PlateText.build` is
now a `PlateTextRow` (exported from `core_plate`) over a `BlocBuilder` rather
than a private re-implementation of the same row; the no-op display chooser is
core's exported `noCharacterChooser`. The private `_noCharacterChooser` and
`_EmptyPlate` are gone. Rendering is unchanged.

**First tests.** `show_plate_test.dart` pins the two forwarded parameters and
asserts `PlateText` and `PlateTextView` render identical text for the same
value.

## 0.1.0

First release. Extracted from `core_plate` as part of its 0.4.0 release, which dropped
`flutter_bloc` and `bloc` from that package's dependencies entirely.

Everything here is a plain move — no behaviour changed in the transfer:

- `PlateCardBloc`, `PlateCardEvent`, `ValueIsChanged`, `RemovePlateCard`,
  `SpecIsChanged`, `PlateCardState`.
- `PlateCardBinding` — provides a `PlateCardBloc` to its subtree and mirrors it
  onto a `PlateController` in both directions. This is how a bloc host wires a
  plate now: the canvas no longer looks for a bloc above it.
- `ShowPlate` and `PlateText` — the bloc-reading read-only views. `core_plate`'s
  `PlateView` and `PlateTextView` are the controller-reading replacements and
  need no provider; these stay for hosts that already have a bloc.

Two deliberate differences from the code as it stood in core:

- `PlateCardBloc.spec` (the constructor field) is **removed**. Only
  `PlateCardState.spec` was ever read; the field was dead after construction.
  The constructor argument is unchanged — `PlateCardBloc(spec)` still seeds the
  empty state for that spec.
- `RemovePlateCard` is **deprecated**. Nothing dispatches it; clear the plate
  through `PlateController.clear()` on the controller the binding mirrors. It
  will be removed in 1.0.0.

### Migrating a bloc host from `core_plate` 0.2.x

Add this package, then wrap the plate subtree in a `PlateCardBinding` where a
`BlocProvider<PlateCardBloc>` used to be:

```dart
final controller = PlateController(spec: spec);

PlateCardBinding(
  controller: controller,
  child: PlateCanvas(spec: spec, controller: controller, /* … */),
);
```

Every `BlocBuilder<PlateCardBloc, PlateCardState>`, `context.read`, `ShowPlate`
and hand-dispatched `ValueIsChanged` below it keeps working, with the import
changed to `package:core_plate_bloc/core_plate_bloc.dart`.
