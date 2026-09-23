FREE PALESTINE 🇮🇷🇵🇸 پاینده ایران

GO VEGAN 🌱

==================================

<!-- METADATA: core_plate
packages: 9
countries: 8
-->

The backbone of license plate packages for countries that actually exist (we checked).

## Available plates

### Core
- [`core_plate`](https://pub.dev/packages/core_plate) - Paint license plates.
- [`core_plate_bloc`](https://pub.dev/packages/core_plate_bloc) - The optional bloc layer, for hosts already bloc-shaped.

### Countries
- [`iran_plate`](https://pub.dev/packages/iran_plate) - Iran's license plates.
- [`germany_plate`](https://pub.dev/packages/germany_plate) - Germany's license plates.
- [`palestine_plate`](https://pub.dev/packages/palestine_plate) - Palestine's license plates.
- [`yemen_plate`](https://pub.dev/packages/yemen_plate) - Yemen's license plates.
- [`iranshahr_plate`](https://pub.dev/packages/iranshahr_plate) - Bahrain's, Azerbaijan's and Afghanistan's license plates.
- [`lebanon_plate`](https://pub.dev/packages/lebanon_plate) - Lebanon's license plates.

### Utilities
- [`plate_keypad`](https://pub.dev/packages/plate_keypad) - A character picker for license plates.

# core_plate

A plate here is just a `const PlateSpec`: some geometry, a country panel, and a row of
slots over alphabets. The widget layer paints whatever the spec says, so adding a plate
means adding a const - never a widget, never a subclass, never a meeting.

`core_plate` knows no country and ships no assets. It hands you the plate face, the
slots, the input machine, and a `PlateValidator` that gives opinions but never blocks a
keystroke. The actual countries live in their own packages.

## Install

```yaml
dependencies:
  core_plate: ^0.5.0
```

Then pick a country package (`iran_plate`, `germany_plate`, `palestine_plate`,
`yemen_plate`) and, if you want the on-screen keyboard, `plate_keypad`. The repo's
`plate_gallery/` app draws every plate all four of them ship, in one place.

## Use

```dart
import 'package:core_plate/core_plate.dart';
import 'package:iran_plate/iran_plate.dart';

PlateCanvas(
  spec: IranPlates.car,
  onChooseCharacter: (alphabet) async => null,
)
```

That is a complete, editable plate. It needs **nothing above it** — no provider, no
bloc. A `PlateCanvas` owns its characters in a `PlateController` (a `ChangeNotifier`,
no dependency beyond Flutter); pass `controller:` when you want to read or write the
value, track the active slot, or feed characters from your own keypad. It brings its
own `Material`, so it survives outside a `Scaffold`.

Swapping `spec:` on a live canvas now **carries the value across** to the new spec,
matching registers by group key — `onSpecChange` tunes that.

If the code around your plate is already bloc-shaped, `core_plate_bloc` provides a
`PlateCardBloc` mirrored onto the controller; nothing in `core_plate` depends on it.

## Things it refuses to do

- Know a country. Grep `lib/` for a country name; a hit is a bug.
- Police input. The validator can paint the frame red. It cannot stop you typing.
- Own your keyboard. Feed it characters from wherever you like.
- Choose your state management. A plate holds its own characters in a
  `PlateController`. Bloc-shaped hosts add `core_plate_bloc`; core neither knows nor
  asks.

## API

Whatever `package:core_plate/core_plate.dart` exports is API. Anything under
`lib/src/` that the barrel doesn't re-export is ours to change without warning.
