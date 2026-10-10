FREE PALESTINE 🇮🇷🇵🇸 پاینده ایران

GO VEGAN 🌱

==================================


# plate_core example

The smallest thing that renders. `plate_core` ships no country and borrows none — a
country name here, even in an example, is the bug `plate_core.dart` describes. So the
example declares its own four-slot spec: two Latin letters, two digits, a plain blue
panel.

Run it with `flutter run` from this directory.

```dart
import 'package:plate_core/plate_core.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

const _spec = PlateSpec(
  id: 'example.plate',
  country: PlateCountry(
    code: 'zz',
    captionLines: [],
    panelColor: Color(0xFF003399),
    panelTextColor: Color(0xFFFFFFFF),
  ),
  canvasWidth: 400,
  canvasHeight: 110,
  panel: PlatePanel(box: PlateBox(0, 0, 40, 110)),
  textDirection: TextDirection.ltr,
  slots: [
    PlateSlot(alphabet: PlateAlphabet.latinUppercase, box: PlateBox(70, 17, 60, 76)),
    PlateSlot(alphabet: PlateAlphabet.latinUppercase, box: PlateBox(136, 17, 60, 76)),
    PlateSlot(alphabet: PlateAlphabet.latinDigits, box: PlateBox(212, 17, 60, 76)),
    PlateSlot(alphabet: PlateAlphabet.latinDigits, box: PlateBox(278, 17, 60, 76)),
  ],
);

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // A bare PlateCanvas is a complete plate: it holds its own characters in
    // a PlateController and needs nothing above it. Pass `controller:` when
    // you want to read or write them.
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: PlateCanvas(
              spec: _spec,
              onChooseCharacter: (alphabet) async => null,
            ),
          ),
        ),
      ),
    );
  }
}
```

`onChooseCharacter` returns `null` here, which means "no picker, nothing chosen". Wire
it to `PlateCharacterPicker.show` from `plate_keypad` if you want the real wheel.

For a real plate, add one of the repo's country packages and pass its spec instead;
this example deliberately names none of them. `plate_gallery/` draws every plate all
four of them ship, in one place.
