import 'package:plate_core/plate_core.dart';
import 'package:venezuela_plate/venezuela_plate.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

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
              spec: VenezuelaPlates.car,
              country: VenezuelaCountry.venezuela,
              theme: VenezuelaPlates.theme,
              validator: const VenezuelaValidator(),
              autoValidate: true,
              // Every Venezuelan alphabet is typed, so no picker is ever asked for.
              onChooseCharacter: (alphabet) async => null,
            ),
          ),
        ),
      ),
    );
  }
}
