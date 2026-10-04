import 'package:plate_core/plate_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A slot fed from outside keeps its focus when the user taps outside it.
///
/// Under [PlateInputSource.packageKeypad] and [PlateInputSource.host] a typed
/// slot is a read-only [TextField], and every character arrives from something
/// the user taps somewhere else on the screen. TextField's default
/// `onTapOutside` unfocuses on desktop at pointer-down, which on linux/macOS/
/// windows made the plate's active slot null one press before the host's pad
/// could submit into it: the pad looked live and typed nothing.

const _country = PlateCountry(
  code: 'zz',
  captionLines: ['ZZ'],
  panelColor: Color(0xFF003399),
  panelTextColor: Color(0xFFFFFFFF),
);

final PlateSpec _spec = PlateSpec(
  id: 'zz.external',
  country: _country,
  canvasWidth: 400,
  canvasHeight: 100,
  panel: const PlatePanel(box: PlateBox(0, 0, 10, 40)),
  slots: <PlateSlot>[
    for (int i = 0; i < 2; i++)
      PlateSlot(
        alphabet: PlateAlphabet.latinDigits,
        box: PlateBox(20 + i * 25.0, 5, 20, 30),
      ),
  ],
);

/// The plate with something else tappable under it, standing in for a host's
/// own keypad.
Widget _host(PlateController controller, PlateInputSource source) =>
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: <Widget>[
            PlateCanvas(
              spec: _spec,
              controller: controller,
              inputSource: source,
              onChooseCharacter: (PlateAlphabet a) async => null,
            ),
            const SizedBox(
              height: 200,
              width: 200,
              child: ColoredBox(color: Color(0xFF222222)),
            ),
          ],
        ),
      ),
    );

void main() {
  for (final (PlateInputSource source, int? afterTap)
      in <(PlateInputSource, int?)>[
        // Fed from outside: focus survives, so the host's next key lands.
        (PlateInputSource.packageKeypad, 0),
        (PlateInputSource.host, 0),
        // Typed into directly: desktop's ordinary "tap away to leave the field".
        (PlateInputSource.system, null),
      ]) {
    testWidgets(
      '$source: tapping outside the plate ${afterTap == null ? 'drops' : 'keeps'} focus',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          final PlateController controller = PlateController(spec: _spec);
          addTearDown(controller.dispose);
          await tester.pumpWidget(_host(controller, source));

          await tester.tap(find.byType(TextField).first);
          await tester.pumpAndSettle();
          expect(controller.activeIndex, 0);

          await tester.tap(find.byType(ColoredBox).last);
          await tester.pumpAndSettle();
          expect(controller.activeIndex, afterTap);
        } finally {
          // Reset inside the body: flutter_test asserts no foundation debug
          // variable outlives it, and that check runs before any tearDown.
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  }
}
