import 'dart:io';

import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tunisia_plate/tunisia_plate.dart';

/// One golden per category, drawn with real bold faces — DejaVu for digits
/// and Latin, Noto Sans Arabic for تونس and the suffixes, in one family so
/// glyphs fall back per character — at 2 px per millimetre, so the ink can be
/// measured against the photos (see `_Layout` in `tunisia_plates.dart`).
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
      if (face.existsSync()) {
        loader.addFont(face.readAsBytes().then((b) => ByteData.view(b.buffer)));
      }
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
                  country: TunisiaCountry.tunisia,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // The military flag is decoded off the real event loop, which fake time
    // does not advance; runAsync gives it a real slice of time.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(PlateView),
      matchesGoldenFile('goldens/$name.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  }

  testWidgets('standard, 131 تونس 2180', (tester) async {
    await render(
      tester,
      spec: TunisiaPlates.standard(),
      theme: TunisiaThemes.standard,
      values: '1 3 1 2 1 8 0',
      name: 'tn_standard',
    );
  });

  testWidgets('standard, two-digit series', (tester) async {
    await render(
      tester,
      spec: TunisiaPlates.standard(seriesDigits: 2),
      theme: TunisiaThemes.standard,
      values: '7 3 3 2 9 4',
      name: 'tn_standard_2',
    );
  });

  testWidgets('rental, 126 تونس 8202', (tester) async {
    await render(
      tester,
      spec: TunisiaPlates.standard(),
      theme: TunisiaThemes.rental,
      values: '1 2 6 8 2 0 2',
      name: 'tn_rental',
    );
  });

  testWidgets('square, 6069 / 47 تونس', (tester) async {
    await render(
      tester,
      spec: TunisiaPlates.square(seriesDigits: 2),
      theme: TunisiaThemes.standard,
      values: '6 0 6 9 4 7',
      name: 'tn_square',
    );
  });

  testWidgets('square, three-digit series', (tester) async {
    await render(
      tester,
      spec: TunisiaPlates.square(),
      theme: TunisiaThemes.standard,
      values: '6 0 6 9 2 5 8',
      name: 'tn_square_3',
    );
  });

  testWidgets('government, 20 - 130486', (tester) async {
    await render(
      tester,
      spec: TunisiaPlates.government(),
      theme: TunisiaThemes.government,
      values: '2 0 1 3 0 4 8 6',
      name: 'tn_government',
    );
  });

  testWidgets('military, 21551', (tester) async {
    await render(
      tester,
      spec: TunisiaPlates.military,
      theme: TunisiaThemes.military,
      values: '2 1 5 5 1',
      name: 'tn_military',
    );
  });

  for (final TunisiaMission m in TunisiaMission.values) {
    testWidgets('diplomatic ${m.latin}', (tester) async {
      await render(
        tester,
        spec: TunisiaPlates.diplomatic(m),
        theme: TunisiaThemes.diplomatic,
        values: m == TunisiaMission.chief ? '4 6 0 1' : '4 6 0 2',
        name: 'tn_diplomatic_${m.id}',
      );
    });
  }

  testWidgets('temporary, 73141 - ن ت', (tester) async {
    await render(
      tester,
      spec: TunisiaPlates.temporary(),
      theme: TunisiaThemes.standard,
      values: '7 3 1 4 1',
      name: 'tn_temporary',
    );
  });

  // No dealer photo exists for its black-on-yellow, so there is no dealer
  // theme; this checks only the layout of `ع ع`.
  testWidgets('dealer layout, 12345 - ع ع', (tester) async {
    await render(
      tester,
      spec: TunisiaPlates.temporary(TunisiaSuffix.dealer),
      theme: TunisiaThemes.standard,
      values: '1 2 3 4 5',
      name: 'tn_dealer_layout',
    );
  });

  test('validator', () {
    bool ok(String series, String number) =>
        TunisiaValidator.validateFields(series: series, number: number) ==
        const PlateValidation.valid();
    expect(ok('131', '2180'), isTrue);
    expect(ok('73', '3294'), isTrue);
    expect(ok('031', '2180'), isFalse);
    expect(ok('131', '218'), isFalse);
    expect(ok('131', '0000'), isFalse);
  });

  test('generator fills every slot of every spec', () {
    for (final PlateSpec spec in <PlateSpec>[
      TunisiaPlates.standard(),
      TunisiaPlates.square(seriesDigits: 1),
      TunisiaPlates.government(),
      TunisiaPlates.diplomatic(),
      TunisiaPlates.military,
      TunisiaPlates.temporary(),
    ]) {
      expect(TunisiaSerialGenerator.generate(spec), everyElement(isNotNull));
    }
  });
}
