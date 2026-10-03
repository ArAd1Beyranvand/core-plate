import 'dart:io';

import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:algeria_plate/algeria_plate.dart';

/// One golden per category, drawn with a real bold face so the ink can be
/// measured against the references (see `_Layout` in `algeria_plates.dart`).
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
                  country: AlgeriaCountry.algeria,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // The army roundel is decoded off the real event loop, which fake time
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

  testWidgets('front, 02865 114 11', (tester) async {
    await render(
      tester,
      spec: AlgeriaPlates.singleLine,
      theme: AlgeriaThemes.front,
      values: '0 2 8 6 5 1 1 4 1 1',
      name: 'dz_front',
    );
  });

  testWidgets('rear, 56789 120 34', (tester) async {
    await render(
      tester,
      spec: AlgeriaPlates.singleLine,
      theme: AlgeriaThemes.rear,
      values: '5 6 7 8 9 1 2 0 3 4',
      name: 'dz_rear',
    );
  });

  testWidgets('two-line, 76739 125 10', (tester) async {
    await render(
      tester,
      spec: AlgeriaPlates.twoLine,
      theme: AlgeriaThemes.rear,
      values: '7 6 7 3 9 1 2 5 1 0',
      name: 'dz_two_line',
    );
  });

  testWidgets('diplomatic, 558-66-27', (tester) async {
    await render(
      tester,
      spec: AlgeriaPlates.diplomatic,
      theme: AlgeriaThemes.diplomatic,
      values: '5 5 8 6 6 2 7',
      name: 'dz_diplomatic',
    );
  });

  testWidgets('army, 140501920', (tester) async {
    await render(
      tester,
      spec: AlgeriaPlates.army,
      theme: AlgeriaThemes.army,
      values: '1 4 0 5 0 1 9 2 0',
      name: 'dz_army',
    );
  });

  test('validator', () {
    bool ok(String serial, String type, String wilaya) =>
        AlgeriaValidator.validateFields(
          serial: serial,
          type: type,
          wilaya: wilaya,
        ) ==
        const PlateValidation.valid();
    expect(ok('02865', '114', '11'), isTrue);
    expect(ok('00513', '111', '69'), isTrue);
    expect(ok('2865', '114', '11'), isFalse);
    expect(ok('02865', '014', '11'), isFalse);
    expect(ok('02865', '114', '70'), isFalse);
    expect(ok('02865', '114', '00'), isFalse);
  });
}
