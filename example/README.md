# core_plate example

The smallest thing that renders. `core_plate` ships no country, so the example borrows
one from `iran_plate` — the engine needs something to paint.

Run it with `flutter run` from this directory.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core_plate/core_plate.dart';
import 'package:iran_plate/iran_plate.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // PlateCanvas reads its state from a PlateCardBloc provided above it.
    // Build the bloc with the same spec you pass to the canvas.
    const spec = IranPlates.car;
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BlocProvider(
              create: (_) => PlateCardBloc(spec),
              child: PlateCanvas(
                spec: spec,
                onChooseCharacter: (alphabet) async => null,
              ),
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

The example's `pubspec.yaml` carries a `dependency_overrides` block pointing at the
sibling checkouts. Copying this example into your own app? Delete that block.
