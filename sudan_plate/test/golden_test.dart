import 'dart:io';

import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudan_plate/sudan_plate.dart';

/// One golden per livery, each the value of its reference photograph, drawn
/// with DejaVu Sans Bold and Noto Sans Arabic Bold at 2 px per millimetre so
/// the ink can be measured against `_Layout` in `sudan_plates.dart`.
///
/// Regenerate with `flutter test --update-goldens` after a deliberate change.
void main() {
  setUpAll(() async {
    final FontLoader loader = FontLoader('Roboto');
    for (final String path in const <String>[
      '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
      '/usr/share/fonts/truetype/noto/NotoSansArabic-Bold.ttf',
    ]) {
      final File face = File(path);
      if (!face.existsSync()) continue;
      loader.addFont(face.readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await loader.load();
  });

  Future<void> render(
    WidgetTester tester, {
    required PlateSpec spec,
    required PlateTheme theme,
    required List<String> values,
    required String name,
  }) async {
    final PlateController controller = PlateController.fromValues(
      spec,
      values,
    );
    tester.view.physicalSize = const Size(800, 400);
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
                  country: SudanCountry.sudan,
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

  final List<(String, PlateSpec, SudanUsage, List<String>)> cases = [
    // The Wikipedia artwork.
    (
      'sd_private',
      SudanPlates.serial5,
      SudanUsage.private,
      ['7', 'KH', '1', '0', '3', '4', '6'],
    ),
    // worldlicenseplates' Al Jazirah plate.
    (
      'sd_private_g',
      SudanPlates.serial5,
      SudanUsage.private,
      ['1', 'G', '1', '4', '3', '4', '9'],
    ),
    // worldlicenseplates' bus/taxi plate.
    (
      'sd_transport',
      SudanPlates.serial4,
      SudanUsage.transport,
      ['4', 'KH', '1', '2', '0', '9'],
    ),
    // worldlicenseplates' commercial plate.
    (
      'sd_commercial',
      SudanPlates.serial5,
      SudanUsage.commercial,
      ['8', 'RS', '2', '0', '3', '6', '8'],
    ),
  ];
  for (final (name, spec, usage, values) in cases) {
    testWidgets('$name ${values.join(' ')}', (tester) async {
      await render(
        tester,
        spec: spec,
        theme: SudanThemes.forUsage(usage),
        values: values,
        name: name,
      );
    });
  }

  test('every spec passes debugValidateSpec', () {
    for (final PlateSpec spec in SudanPlates.bySerialDigits.values) {
      expect(debugValidateSpec(spec), isTrue);
    }
  });

  test('one stored value prints in both scripts', () {
    expect(SudanAlphabets.stateArabic.render('KH'), 'خ');
    expect(SudanAlphabets.stateLatin.render('KH'), 'KH');
    expect(SudanAlphabets.arabicDigits.render('7'), '٧');
    expect(SudanAlphabets.stateArabic.canonical('خ'), 'KH');
  });

  test('validator', () {
    PlateValidation v(String c, String s, String n) =>
        SudanValidator.validateFields(classDigit: c, state: s, serial: n);
    expect(v('7', 'KH', '10346').isValid, isTrue);
    expect(v('4', 'KH', '1209').isValid, isTrue);
    expect(v('', 'KH', '10346').isValid, isFalse);
    expect(v('7', 'XX', '10346').isValid, isFalse);
    expect(v('7', 'KH', '103').isValid, isFalse);
  });
}
