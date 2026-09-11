import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:yemen_plate/yemen_plate.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // System A, the 2026 unified plate. System B — the 1993 northern format
    // still in force across the north — is `YemenNorthernPlates`; the two are
    // separate namespaces because they are two current systems, not a current
    // one and a legacy one.
    final spec = YemenUnifiedPlates.car(numberDigits: 5)!;
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: PlateCanvas(
              spec: spec,
              // Usage is not a spec: it selects the country block carrying the
              // panel's caption lines and, on System B, the field colour. Both
              // are render-time inputs.
              country: YemenCountry.unifiedFor(YemenUsage.private),
              theme: YemenThemes.unified,
              validator: const YemenUnifiedValidator(),
              autoValidate:
                  true, // paints red on an invalid plate; never blocks input
              onChooseCharacter: (alphabet) async => null,
            ),
          ),
        ),
      ),
    );
  }
}
