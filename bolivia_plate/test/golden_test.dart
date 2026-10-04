import 'dart:io';

import 'package:bolivia_plate/bolivia_plate.dart';
import 'package:plate_core/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// One golden per category, drawn with DejaVu Sans Bold at 2 px per
/// millimetre, so the ink can be measured against the references (see
/// `_Layout` in `bolivia_plates.dart`).
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
                  country: BoliviaCountry.bolivia,
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

  for (final BoliviaService s in BoliviaService.values) {
    testWidgets('standard ${s.id}, 1852PHD L', (tester) async {
      await render(
        tester,
        spec: BoliviaPlates.standard(service: s),
        theme: BoliviaThemes.standard,
        values: '1 8 5 2 P H D L',
        name: 'bo_standard_${s.id}',
      );
    });
  }

  testWidgets('standard, three digits', (tester) async {
    await render(
      tester,
      spec: BoliviaPlates.standard(digits: 3),
      theme: BoliviaThemes.standard,
      values: '0 4 7 A B C S',
      name: 'bo_standard_3',
    );
  });

  final Map<BoliviaMission, PlateTheme> missionThemes = {
    BoliviaMission.consular: BoliviaThemes.consular,
    BoliviaMission.diplomatic: BoliviaThemes.diplomatic,
    BoliviaMission.international: BoliviaThemes.mission,
    BoliviaMission.organization: BoliviaThemes.organization,
  };
  for (final BoliviaMission m in BoliviaMission.values) {
    testWidgets('special ${m.code}, 57-${m.code}-07', (tester) async {
      await render(
        tester,
        spec: BoliviaPlates.special(m),
        theme: missionThemes[m]!,
        values: '5 7 0 7',
        name: 'bo_special_${m.id}',
      );
    });
  }

  testWidgets('mercosur, BB 01234', (tester) async {
    await render(
      tester,
      spec: BoliviaPlates.mercosur,
      theme: BoliviaThemes.mercosur,
      values: 'B B 0 1 2 3 4',
      name: 'bo_mercosur',
    );
  });

  test('validator', () {
    bool ok(String n, String l, String d) =>
        BoliviaValidator.validateFields(number: n, letters: l, department: d) ==
        const PlateValidation.valid();
    expect(ok('1852', 'PHD', 'L'), isTrue);
    expect(ok('047', 'ABC', 'S'), isTrue);
    expect(ok('18', 'PHD', 'L'), isFalse);
    expect(ok('1852', 'PH', 'L'), isFalse);
    expect(ok('1852', 'PHD', 'X'), isFalse);
  });

  test('generator fills every slot of every spec', () {
    for (final PlateSpec spec in <PlateSpec>[
      BoliviaPlates.standard(),
      BoliviaPlates.standard(digits: 3),
      BoliviaPlates.special(),
      BoliviaPlates.mercosur,
    ]) {
      expect(BoliviaSerialGenerator.generate(spec), everyElement(isNotNull));
    }
  });
}
