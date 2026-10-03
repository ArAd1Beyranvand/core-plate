import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:lebanon_plate/lebanon_plate.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Lebanon is two geometries and many colours. `twoLine` is the other
    // geometry; everything else about the plate is the two render-time
    // arguments below.
    const usage = LebanonUsage.private;
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: PlateCanvas(
              spec: LebanonPlates.oneLine,
              // Usage is not a spec: it selects the band's caption and the
              // field colour, and both are render-time inputs.
              country: LebanonCountry.forUsage(usage),
              theme: LebanonThemes.forUsage(usage),
              validator: const LebanonValidator(),
              autoValidate:
                  true, // paints red on an invalid plate; never blocks input
              // The letter is a `chosen` alphabet — a closed list of seventeen,
              // one of them two glyphs wide. A real host shows a picker here;
              // `plate_keypad`'s `PlateCharacterPicker.show` is one.
              onChooseCharacter: (alphabet) async => null,
            ),
          ),
        ),
      ),
    );
  }
}
