# Plate Number Package

A Flutter package that renders an interactive license-plate widget and collects the
plate characters a user types into it. It ships layout specs for Iranian car and
motorcycle plates and for the German car plate, and validates each field as it is
entered.

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  plate_number: ^0.1.0
```

Then:

```bash
flutter pub get
```

## Usage

`PlateCanvas` renders a plate for a given `PlateSpec` and reads its state from a
`PlateCardBloc` you provide above it in the widget tree. Create the bloc with the
same spec you pass to the canvas:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plate_number/plate_number.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider(
          create: (_) => PlateCardBloc(PlateSpecs.irCar),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: PlateCanvas(spec: PlateSpecs.irCar),
            ),
          ),
        ),
      ),
    );
  }
}
```

`PlateCanvas` is exported from the package root (`package:plate_number/plate_number.dart`).

## What this package renders

Pass one of the shipped specs to both `PlateCardBloc` and `PlateCanvas`:

- `PlateSpecs.irCar` — Iranian car plate.
- `PlateSpecs.irBicycle` — Iranian motorcycle plate.
- `PlateSpecs.deCar` — German car plate.

## Contributing

Contributions are welcome! If you have suggestions or improvements, feel free to open an issue or
submit a pull request.
