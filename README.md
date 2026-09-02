> پاینده ایران FREE PALESTINE 🇮🇷🇵🇸
> GO VEGAN 🌱
> ==================================

# core_plate

The backbone of license plate packages for countries that actually exist (we checked).

A plate here is just a `const PlateSpec`: some geometry, a country panel, and a row of
slots over alphabets. The widget layer paints whatever the spec says, so adding a plate
means adding a const — never a widget, never a subclass, never a meeting.

`core_plate` knows no country and ships no assets. It hands you the plate face, the
slots, the input machine, and a `PlateValidator` that gives opinions but never blocks a
keystroke. The actual countries live in their own packages.

## Install

```yaml
dependencies:
  core_plate: ^0.1.0
```

Then pick a country package (`iran_plate`, `germany_plate`) and, if you want the
on-screen keyboard, `plate_keypad`.

## Use

```dart
import 'package:core_plate/core_plate.dart';
import 'package:iran_plate/iran_plate.dart';

BlocProvider(
  create: (_) => PlateCardBloc(IranPlates.car),
  child: PlateCanvas(
    spec: IranPlates.car,
    onChooseCharacter: (alphabet) async => null,
  ),
)
```

`PlateCanvas` needs a `PlateCardBloc` above it and it will tell you so, loudly, on
build if you forget. It brings its own `Material`, so it survives outside a `Scaffold`.

## Things it refuses to do

- Know a country. Grep `lib/` for a country name; a hit is a bug.
- Police input. The validator can paint the frame red. It cannot stop you typing.
- Own your keyboard. Feed it characters from wherever you like.

## API

Whatever `package:core_plate/core_plate.dart` exports is API. Anything under
`lib/src/` that the barrel doesn't re-export is ours to change without warning.
