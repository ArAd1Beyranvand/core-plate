import 'package:plate_core/plate_core.dart';
import 'package:cuba_plate/cuba_plate.dart';
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
              // `carLegalEntity` is the blue-strip plate; `motorcycle` the 200×140.
              spec: CubaPlates.car,
              country: CubaCountry.cuba,
              theme: CubaPlates.theme,
              validator: const CubaValidator(),
              autoValidate: true,
              // Every Cuban alphabet is typed, so no picker is ever asked for.
              onChooseCharacter: (alphabet) async => null,
            ),
          ),
        ),
      ),
    );
  }
}
