import 'package:plate_core/plate_core.dart';
import 'package:flutter/material.dart';
import 'package:india_plate/india_plate.dart';

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
              spec: IndiaPlates.private,
              country: IndiaCountry.india,
              theme: IndiaThemes.private,
              validator: const IndiaValidator(),
              autoValidate: true,
              // Every Indian alphabet is typed, so no picker is ever asked for.
              onChooseCharacter: (alphabet) async => null,
            ),
          ),
        ),
      ),
    );
  }
}
