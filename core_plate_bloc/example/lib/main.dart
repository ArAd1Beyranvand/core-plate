import 'package:core_plate/core_plate.dart';
import 'package:core_plate_bloc/core_plate_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() => runApp(const ExampleApp());

/// A plate to type into. This package ships no country and borrows none, so the
/// example draws its own four-slot spec: two letters, two digits, a blank
/// panel. What is on the plate is not the point — where its characters live is.
const _spec = PlateSpec(
  id: 'example.plate',
  country: PlateCountry(code: 'zz', captionLines: [], panelColor: Color(0xFF003399), panelTextColor: Color(0xFFFFFFFF)),
  canvasWidth: 400,
  canvasHeight: 110,
  panel: PlatePanel(box: PlateBox(0, 0, 40, 110)),
  textDirection: TextDirection.ltr,
  slots: [
    PlateSlot(alphabet: PlateAlphabet.latinUppercase, box: PlateBox(70, 17, 60, 76)),
    PlateSlot(alphabet: PlateAlphabet.latinUppercase, box: PlateBox(136, 17, 60, 76)),
    PlateSlot(alphabet: PlateAlphabet.latinDigits, box: PlateBox(212, 17, 60, 76)),
    PlateSlot(alphabet: PlateAlphabet.latinDigits, box: PlateBox(278, 17, 60, 76)),
  ],
);

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  /// The plate's characters. The canvas writes here; the binding mirrors it
  /// onto the bloc it provides.
  final _controller = PlateController(spec: _spec);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        // Where a BlocProvider<PlateCardBloc> used to go. The binding creates
        // the bloc for the controller's spec, disposes it with itself, and
        // keeps the two holding the same characters in both directions.
        body: PlateCardBinding(
          controller: _controller,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: PlateCanvas(spec: _spec, controller: _controller, onChooseCharacter: (alphabet) async => null),
                ),
                // The proof: this reads the bloc, not the controller, and
                // updates on every keystroke the canvas commits.
                BlocBuilder<PlateCardBloc, PlateCardState>(
                  builder: (context, state) => Text(
                    state.plateNumber.values.map((v) => (v ?? '').isEmpty ? '_' : v!).join(' '),
                    style: const TextStyle(fontSize: 24, letterSpacing: 2),
                  ),
                ),
                const SizedBox(height: 16),
                // And the other direction: a hand-dispatched event lands on the
                // bloc and reaches the plate, which paints the character.
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => context.read<PlateCardBloc>().add(ValueIsChanged(index: 0, value: 'A')),
                      child: const Text('bloc: set slot 0 to A'),
                    ),
                    TextButton(onPressed: _controller.clear, child: const Text('controller: clear')),
                  ],
                ),
                // The bloc-reading read-only view, for comparison with
                // core_plate's controller-reading PlateTextView.
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: PlateText(emptyPlate: Text('nothing typed yet')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
