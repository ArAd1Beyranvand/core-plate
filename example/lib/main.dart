import 'package:flutter/material.dart';
import 'package:plate_core/plate_core.dart';
import 'package:iran_plate/iran_plate.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final spec = IranPlates.car;
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: PlateCanvas(
              spec: spec,
              onChooseCharacter: (alphabet) async => null,
            ),
          ),
        ),
      ),
    );
  }
}
