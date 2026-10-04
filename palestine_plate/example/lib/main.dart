import 'package:plate_core/plate_core.dart';
import 'package:flutter/material.dart';
import 'package:palestine_plate/palestine_plate.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final spec = PSWestBankPlates.modernCar;
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: PlateCanvas(
              spec: spec,
              // Colour is derived from usage, never chosen, and it is a
              // render-time input rather than a field on the spec.
              theme: PSThemes.forUsage(PSUsage.private),
              validator: const PSWestBankModernValidator(),
              autoValidate:
                  true, // paints red on an invalid plate; never blocks input
              // The trailing governorate letter is a `chosen` alphabet, so the
              // host is asked for a character instead of the slot accepting
              // typing. Returning null declines; `plate_gallery` wires
              // `plate_keypad`'s PlateCharacterPicker.show in here.
              onChooseCharacter: (alphabet) async => null,
            ),
          ),
        ),
      ),
    );
  }
}
