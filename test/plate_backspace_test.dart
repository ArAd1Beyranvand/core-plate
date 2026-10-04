import 'package:plate_core/plate_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// What backspace does at the edge of a slot.
///
/// The rule is two presses, not one: the first clears the focused slot and
/// stays there, so the user can retype without losing their place; a second
/// press — on a slot that is now empty — clears the slot BEFORE it and moves
/// focus there. Pinned because the natural implementation (a TextField
/// deleting its own character) silently does nothing on the second press.

const _country = PlateCountry(
  code: 'zz',
  captionLines: ['ZZ'],
  panelColor: Color(0xFF003399),
  panelTextColor: Color(0xFFFFFFFF),
);

const _letters = PlateAlphabet(
  id: 'zz.letters',
  characters: ['A', 'B'],
  input: AlphabetInput.chosen,
  isNumeric: false,
);

/// Three typed digit slots.
final PlateSpec _typedSpec = PlateSpec(
  id: 'zz.backspace.typed',
  country: _country,
  canvasWidth: 400,
  canvasHeight: 100,
  panel: const PlatePanel(box: PlateBox(0, 0, 10, 40)),
  slots: <PlateSlot>[
    for (int i = 0; i < 3; i++)
      PlateSlot(
        alphabet: PlateAlphabet.latinDigits,
        box: PlateBox(20 + i * 25.0, 5, 20, 30),
      ),
  ],
);

/// A chosen slot between two typed ones, so the stepped-back slot is a chosen
/// one under a hardware keyboard.
final PlateSpec _chosenSpec = PlateSpec(
  id: 'zz.backspace.chosen',
  country: _country,
  canvasWidth: 400,
  canvasHeight: 100,
  panel: const PlatePanel(box: PlateBox(0, 0, 10, 40)),
  slots: <PlateSlot>[
    PlateSlot(alphabet: _letters, box: const PlateBox(20, 5, 20, 30)),
    PlateSlot(
      alphabet: PlateAlphabet.latinDigits,
      box: const PlateBox(45, 5, 20, 30),
    ),
  ],
);

Widget _host(
  PlateSpec spec,
  PlateController controller,
  PlateInputSource source,
) => MaterialApp(
  home: PlateCanvas(
    spec: spec,
    controller: controller,
    inputSource: source,
    onChooseCharacter: (PlateAlphabet a) async => null,
  ),
);

/// The plate's characters with "unset" normalised: a cleared slot may read
/// back as null or '' depending on the path that cleared it, and this file is
/// about focus, not about which of the two the controller stores.
List<String> _values(PlateController controller) => [
  for (final v in controller.values) v ?? '',
];

/// Which slot the canvas reports as focused.
int? _activeIndex(PlateController controller) => controller.activeIndex;

void main() {
  for (final source in <PlateInputSource>[
    PlateInputSource.system,
    PlateInputSource.hardwareKeyboard,
  ]) {
    testWidgets(
      'typed slot: backspace clears in place, then steps back ($source)',
      (tester) async {
        final PlateController controller = PlateController(spec: _typedSpec);
        addTearDown(controller.dispose);
        await tester.pumpWidget(_host(_typedSpec, controller, source));

        controller.setAt(0, '1');
        controller.setAt(1, '2');
        await tester.pump();

        controller.focusSlot(1);
        await tester.pumpAndSettle();
        expect(_activeIndex(controller), 1);

        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        await tester.pumpAndSettle();
        expect(_values(controller), <String>[
          '1',
          '',
          '',
        ], reason: 'the first press clears the focused slot only');
        expect(
          _activeIndex(controller),
          1,
          reason: 'the first press does not move focus',
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        await tester.pumpAndSettle();
        expect(_values(controller), <String>[
          '',
          '',
          '',
        ], reason: 'the second press clears the previous slot');
        expect(
          _activeIndex(controller),
          0,
          reason: 'the second press moves focus back',
        );
      },
    );
  }

  testWidgets(
    'chosen slot under a hardware keyboard follows the same two presses',
    (tester) async {
      final PlateController controller = PlateController(spec: _chosenSpec);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(_chosenSpec, controller, PlateInputSource.hardwareKeyboard),
      );

      controller.setAt(0, 'A');
      controller.setAt(1, '7');
      await tester.pump();

      controller.focusSlot(1);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();
      expect(_values(controller), <String>['A', '']);
      expect(_activeIndex(controller), 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();
      expect(_values(controller), <String>['', '']);
      expect(_activeIndex(controller), 0);

      // And the chosen slot, now focused and already empty, has nowhere to step
      // back to: it stays put rather than wrapping to the end of the plate.
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();
      expect(_activeIndex(controller), 0);
    },
  );
}
