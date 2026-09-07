FREE PALESTINE 🇮🇷🇵🇸 پاینده ایران

GO VEGAN 🌱

==================================

The optional bloc layer for [`core_plate`](https://pub.dev/packages/core_plate),
for hosts whose code around the plate is already bloc-shaped.

# core_plate_bloc

A `PlateCanvas` owns its characters in a `PlateController` and needs nothing above
it — no provider, no bloc, no package but `core_plate`. This package is for the app
that already has a `BlocBuilder` over the plate value, its own `ValueIsChanged`
dispatches, or a `ShowPlate` in a list, and would rather keep them than rewrite them.

## Depends on

`core_plate` (`^0.5.0`), `flutter_bloc` and `bloc`. Nothing in `core_plate` depends on
this package — that is the point of the split.

## Use

`PlateCardBinding` goes where a `BlocProvider<PlateCardBloc>` used to. It provides a
bloc to the subtree and keeps it holding the same characters as the controller, in
both directions, so a write on either side reaches the other.

```dart
import 'package:core_plate/core_plate.dart';
import 'package:core_plate_bloc/core_plate_bloc.dart';

final controller = PlateController(spec: spec); // your country package's spec

PlateCardBinding(
  controller: controller,
  child: Column(
    children: [
      PlateCanvas(
        spec: spec,
        controller: controller,
        onChooseCharacter: (alphabet) async => null,
      ),
      BlocBuilder<PlateCardBloc, PlateCardState>(
        builder: (context, state) => Text(state.plateNumber.values.join()),
      ),
    ],
  ),
);
```

Pass `bloc:` to mirror onto a bloc the host already holds; leave it null and the
binding creates one for the controller's spec and disposes it with itself.

## What lives here

| Name | What it is |
| --- | --- |
| `PlateCardBloc` | The store: `ValueIsChanged`, `SpecIsChanged`, `PlateCardState`. |
| `PlateCardBinding` | Provides that bloc, mirrored onto a `PlateController`. |
| `ShowPlate` | Read-only graphical plate, driven off bloc state. |
| `PlateText` | Read-only plain-text plate string, driven off bloc state. |

`ShowPlate` and `PlateText` are superseded by `core_plate`'s `PlateView` and
`PlateTextView`, which render a controller, take a `PlateTheme`, and need no provider
above them. Prefer those in new code.

`RemovePlateCard` is deprecated and will be removed in 1.0.0 — clear the plate through
`PlateController.clear()`.
