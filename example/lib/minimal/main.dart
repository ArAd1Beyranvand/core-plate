// Run with: flutter run -t lib/minimal/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plate_number/plate_number.dart';

void main() {
  runApp(const MinimalApp());
}

class MinimalApp extends StatelessWidget {
  const MinimalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider(
          create: (_) => PlateCardBloc(PlateSpecs.irCar),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              // inputSource defaults per platform and can be overridden
              child: PlateCanvas(spec: PlateSpecs.irCar),
            ),
          ),
        ),
      ),
    );
  }
}
