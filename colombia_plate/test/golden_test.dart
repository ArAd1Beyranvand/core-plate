import 'dart:io';

import 'package:colombia_plate/colombia_plate.dart';
import 'package:plate_core/plate_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// One golden per category, drawn with DejaVu Sans Bold at 2 px per
/// millimetre, so the ink can be measured against the references (see
/// `_Layout` in `colombia_plates.dart`).
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
    tester.view.physicalSize = const Size(1200, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 2 * spec.canvasWidth,
              height: 2 * spec.canvasHeight,
              child: PlateThemeScope(
                theme: theme,
                child: PlateView(
                  controller: controller,
                  theme: theme,
                  country: ColombiaCountry.colombia,
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

  final List<(ColombiaSeries, PlateTheme, String, String?)> cases = [
    (ColombiaSeries.private, ColombiaThemes.private, 'N A Z 8 2 7', 'ARMENIA'),
    (
      ColombiaSeries.commercial,
      ColombiaThemes.commercial,
      'X Z F 6 0 7',
      'S. ANDRES ISLA',
    ),
    (
      ColombiaSeries.official,
      ColombiaThemes.official,
      'O V D 9 4 7',
      'PEREIRA',
    ),
    (
      ColombiaSeries.antiqueCar,
      ColombiaThemes.antique,
      'A I D 8 9 9',
      'BOGOTA D.C.',
    ),
    (
      ColombiaSeries.mototaxi,
      ColombiaThemes.private,
      '1 2 3 A B C',
      'SINCELEJO',
    ),
    (ColombiaSeries.trailer, ColombiaThemes.official, 'R 1 2 3 4 5', 'CALI'),
    (ColombiaSeries.tankTruck, ColombiaThemes.tank, 'T 1 2 3 4', 'MEDELLIN'),
    (ColombiaSeries.consular, ColombiaThemes.consular, 'C C 0 0 7 1', null),
    (
      ColombiaSeries.organization,
      ColombiaThemes.organization,
      'O I 0 0 4 5',
      null,
    ),
    (ColombiaSeries.staff, ColombiaThemes.staff, 'A T 0 2 8 2', null),
  ];
  for (final (ColombiaSeries s, PlateTheme theme, String values, String? city)
      in cases) {
    testWidgets('standard ${s.id}, $values', (tester) async {
      await render(
        tester,
        spec: ColombiaPlates.standard(series: s, city: city ?? 'BOGOTA D.C.'),
        theme: theme,
        values: values,
        name: 'co_${s.id}',
      );
    });
  }

  testWidgets('police, 60-0007', (tester) async {
    await render(
      tester,
      spec: ColombiaPlates.police,
      theme: ColombiaThemes.police,
      values: '6 0 0 0 0 7',
      name: 'co_police',
    );
  });

  testWidgets('diplomatic, A FR 000', (tester) async {
    await render(
      tester,
      spec: ColombiaPlates.diplomatic,
      theme: ColombiaThemes.diplomatic,
      values: 'A F R 0 0 0',
      name: 'co_diplomatic',
    );
  });

  test('validator', () {
    bool ok(ColombiaSeries s, String l, String n) =>
        ColombiaValidator.validateFields(s, letters: l, number: n) ==
        const PlateValidation.valid();
    expect(ok(ColombiaSeries.private, 'NAZ', '827'), isTrue);
    expect(ok(ColombiaSeries.private, 'NA', '827'), isFalse);
    expect(ok(ColombiaSeries.official, 'OVD', '947'), isTrue);
    expect(ok(ColombiaSeries.official, 'AVD', '947'), isFalse);
    expect(ok(ColombiaSeries.consular, 'CC', '0071'), isTrue);
    expect(ok(ColombiaSeries.consular, 'CC', '071'), isFalse);
    expect(ok(ColombiaSeries.trailer, 'R', '12345'), isTrue);
  });

  test('generator fills every slot of every spec', () {
    for (final PlateSpec spec in <PlateSpec>[
      for (final ColombiaSeries s in ColombiaSeries.values)
        ColombiaPlates.standard(series: s),
      ColombiaPlates.police,
      ColombiaPlates.diplomatic,
    ]) {
      expect(ColombiaSerialGenerator.generate(spec), everyElement(isNotNull));
    }
  });

  test('a fixed letter cell holds only that letter', () {
    final PlateSpec spec = ColombiaPlates.standard(
      series: ColombiaSeries.consular,
    );
    expect(spec.slots[0].alphabet.characters, <String>['C']);
    expect(spec.slots[2].alphabet.characters, contains('7'));
  });
}
