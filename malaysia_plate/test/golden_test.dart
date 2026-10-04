import 'dart:io';

import 'package:plate_core/plate_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:malaysia_plate/malaysia_plate.dart';

/// One golden per category, drawn with a real bold face so the ink can be
/// measured against the references (see `_Layout` in `malaysia_plates.dart`).
///
/// Regenerate with `flutter test --update-goldens` after a deliberate change.
void main() {
  setUpAll(() async {
    final FontLoader loader = FontLoader('Roboto');
    final File face = File(
      '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
    );
    if (face.existsSync()) {
      loader.addFont(face.readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await loader.load();
  });

  Future<void> render(
    WidgetTester tester, {
    required PlateSpec spec,
    required PlateTheme theme,
    required String values,
    required String name,
  }) async {
    final PlateController controller = PlateController.fromValues(
      spec,
      values.split(' '),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 520,
              height: 520 * spec.canvasHeight / spec.canvasWidth,
              child: PlateThemeScope(
                theme: theme,
                child: PlateView(
                  controller: controller,
                  theme: theme,
                  country: MalaysiaCountry.malaysia,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(PlateView),
      matchesGoldenFile('goldens/$name.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  }

  testWidgets('private, QAB 8557 K', (tester) async {
    await render(
      tester,
      spec: MalaysiaPlates.singleRow(suffix: true),
      theme: MalaysiaThemes.standard,
      values: 'Q A B 8 5 5 7 K',
      name: 'my_single_suffix',
    );
  });

  testWidgets('private, PFQ 5217', (tester) async {
    await render(
      tester,
      spec: MalaysiaPlates.singleRow(),
      theme: MalaysiaThemes.standard,
      values: 'P F Q 5 2 1 7',
      name: 'my_single',
    );
  });

  testWidgets('taxi, HWD 378', (tester) async {
    await render(
      tester,
      spec: MalaysiaPlates.singleRow(digits: 3),
      theme: MalaysiaThemes.taxi,
      values: 'H W D 3 7 8',
      name: 'my_taxi',
    );
  });

  testWidgets('two-row, QAF 6229', (tester) async {
    await render(
      tester,
      spec: MalaysiaPlates.twoRow(),
      theme: MalaysiaThemes.standard,
      values: 'Q A F 6 2 2 9',
      name: 'my_two_row',
    );
  });

  testWidgets('diplomatic, 99-64-DC', (tester) async {
    await render(
      tester,
      spec: MalaysiaPlates.diplomatic,
      theme: MalaysiaThemes.diplomatic,
      values: '9 9 6 4 DC',
      name: 'my_diplomatic',
    );
  });

  testWidgets('JPJePlate', (tester) async {
    await render(
      tester,
      spec: MalaysiaPlates.ev(),
      theme: MalaysiaThemes.ev,
      values: 'V E A 1 2 3 4',
      name: 'my_ev',
    );
  });

  test('validator', () {
    bool ok(String prefix, String number, [String suffix = '']) =>
        MalaysiaValidator.validateFields(
          prefix: prefix,
          number: number,
          suffix: suffix,
        ) ==
        const PlateValidation.valid();
    expect(ok('QAB', '8557', 'K'), isTrue);
    expect(ok('WOA', '1'), isFalse);
    expect(ok('W', '0123'), isFalse);
    expect(ok('SAA', '8967', 'S'), isFalse);
  });
}
