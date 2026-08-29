---
name: p2-plate-geometry
description: "Refactor phase P2 of the plate_number split — introduce PlateBox and PlatePanel so slots, rules, labels, decals and the country panel share one geometry type. Use when the user asks to run P2 or work on plate geometry."
---

# P2 — Plate geometry

Follow `CLAUDE.md` working style. Requires **P1** to be committed. Finish analyzer-clean,
tests green, committed; report diffstat and hashes only.

## Why

`PlateSlot`, `PlateRule`, `PlateLabel` and `PlateDecal` each declare
`final double left, top, width, height;` with near-identical doc comments. `PlateSpec` then
carries seven more fields describing one rectangle and its contents
(`panelLeft`, `panelTop`, `panelWidth`, `panelHeight`, `flagScale`, `captionScale`,
`panelPadding`) — twelve fields in total describing "things placed on the plate face".

`PlateCanvas.build` pays for it four times over: four near-identical
`Positioned(left: …, top: …, width: …, height: …)` blocks that differ only in their child.

## Do

### `lib/model/plate_box.dart` (new)

```dart
/// A rectangle in plate-space: the same coordinate system slots, rules, labels,
/// decals and the country panel all live in, with the origin at the plate's
/// top-left and units matching [PlateSpec.canvasWidth]/[canvasHeight].
@immutable
class PlateBox {
  const PlateBox(this.left, this.top, this.width, this.height);
  final double left, top, width, height;
  double get right => left + width;
  double get bottom => top + height;
  Rect get rect => Rect.fromLTWH(left, top, width, height);
}
```

Positional parameters, deliberately: these literals appear ~30 times in the specs and named
arguments would make them longer than what they replace.

### `lib/model/plate_spec.dart`

1. `PlateSlot`, `PlateRule`, `PlateLabel`, `PlateDecal` each drop their four doubles and gain
   `final PlateBox box;`. Delete the four repeated doc comments; document the coordinate
   system once, on `PlateBox`.
2. `PlateLabel.glyphHeight` stays — it is not geometry, it is type size.
3. `PlateSlot`'s glyph sizing now reads `slot.box.height`.
4. New value type in the same file:

```dart
/// The coloured country block on the plate face: where it sits, and how the
/// flag and caption are laid out inside it.
@immutable
class PlatePanel {
  const PlatePanel({
    required this.box,
    this.flagScale = 1.0,
    this.captionScale = 1.0,
    this.padding,
  });
  final PlateBox box;
  final double flagScale, captionScale;
  final EdgeInsets? padding;
}
```

5. `PlateSpec` replaces its seven panel fields with `required this.panel` of type
   `PlatePanel`. Move the existing doc comments for `flagScale`, `captionScale` and
   `panelPadding` onto `PlatePanel`'s fields verbatim — they are good and explain real
   decisions.
6. Rewrite the three specs. The seam-overlap comments on `panelLeft: 0, panelTop: 0` in
   `irCar`, `irBicycle` and `deCar` must move onto the new `PlatePanel(box: …)` literal
   **unchanged** — they document a real anti-aliasing fix and are the kind of thing that gets
   silently deleted in a refactor.
7. `debugValidateSpec`'s bounds assertion becomes a one-liner against `slot.box`.

### `lib/widgets/plate_canvas.dart`

8. Add one private widget (a class — `claude.md` §1 forbids widget-returning functions):

```dart
class _Placed extends StatelessWidget {
  const _Placed({required this.box, required this.child});
  final PlateBox box;
  final Widget child;
  @override
  Widget build(BuildContext context) => Positioned(
        left: box.left, top: box.top, width: box.width, height: box.height,
        child: child,
      );
}
```

9. Replace all four `Positioned(...)` blocks (panel, rules, labels, decals) and the slot loop
   with `_Placed`. The build method should lose ~25 lines and gain no nesting.

### `lib/widgets/country_panel.dart`

10. `CountryPanel` takes `required PlatePanel panel` instead of `flagScale`, `captionScale`
    and `padding`. Its internal use of `constraints.maxHeight * 0.10` as the default padding
    is unchanged.

### Tests

11. `test/spec_test.dart` and `test/plate_canvas_test.dart` construct slots and read
    geometry — update to `box`.

## Considered and rejected

A `sealed class PlateElement { PlateBox get box; }` with `SlotElement`/`RuleElement`/… and one
`for (final e in spec.elements)` loop in the canvas. It reads well, but the canvas still needs
a different child per kind, so the four loops become one loop plus a five-arm `switch` — no
lines saved, one more layer of indirection between the spec literal and the pixel, and the
four lists are individually useful (`spec.slots.length` drives `PlateNumber`). Not worth it.
If a fifth element kind ever appears, revisit.

## Verify

```
cd plate-number-upgrade   && flutter analyze && flutter test
cd ../plate_number_holder && flutter analyze && flutter test
```

Then screenshot the three demo plates and diff against `screenshot.png` /
`.scratch/showcase_after_max.png`. **This phase must be pixel-identical.** The panel-overlap
geometry in particular is easy to get subtly wrong; if the thin white seam between the blue
panel and the black frame reappears, the overlap comments were not carried across correctly.

Expected: ~80 net lines removed from `lib/`, and every spec literal materially shorter.
