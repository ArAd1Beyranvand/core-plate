import 'package:plate_core/plate_core.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

/// A plate to type into.
///
/// **This package ships no country and borrows none** — a country name here,
/// even in an example, is the bug `plate_core.dart` describes. So the example
/// draws its own four-slot spec: two Latin letters, two digits, a plain blue
/// panel.
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
    PlateSlot(
      alphabet: PlateAlphabet.latinUppercase,
      box: PlateBox(70, 17, 60, 76),
    ),
    PlateSlot(
      alphabet: PlateAlphabet.latinUppercase,
      box: PlateBox(136, 17, 60, 76),
    ),
    PlateSlot(
      alphabet: PlateAlphabet.latinDigits,
      box: PlateBox(212, 17, 60, 76),
    ),
    PlateSlot(
      alphabet: PlateAlphabet.latinDigits,
      box: PlateBox(278, 17, 60, 76),
    ),
  ],
);

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
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
