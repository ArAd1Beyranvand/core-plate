import 'dart:io';

import 'package:plate_core/plate_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_plate/vietnam_plate.dart';

/// One golden per category, drawn with a real bold face so the ink can be
/// measured against the references (see `_Layout` in `vietnam_plates.dart`).
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
    double width = 520,
    double height = 110,
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
              width: width,
              height: height,
              child: PlateThemeScope(
                theme: theme,
                child: PlateView(
                  controller: controller,
                  theme: theme,
                  country: VietnamCountry.vietnam,
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

  testWidgets('long car white', (tester) async {
    await render(
      tester,
      spec: VietnamPlates.long(),
      theme: VietnamThemes.white,
      values: '3 0 F 2 5 6 5 8',
      name: 'vn_white_long',
      width: 520,
      height: 110,
    );
  });

  testWidgets('long car yellow', (tester) async {
    await render(
      tester,
      spec: VietnamPlates.long(),
      theme: VietnamThemes.yellow,
      values: '5 1 K 1 2 3 4 5',
      name: 'vn_yellow_long',
      width: 520,
      height: 110,
    );
  });

  testWidgets('long car blue', (tester) async {
    await render(
      tester,
      spec: VietnamPlates.long(),
      theme: VietnamThemes.blue,
      values: '8 0 A 0 0 1 2 3',
      name: 'vn_blue_long',
      width: 520,
      height: 110,
    );
  });

  testWidgets('long two-letter series', (tester) async {
    await render(
      tester,
      spec: VietnamPlates.long(serial: 2),
      theme: VietnamThemes.blue,
      values: '8 0 L D 1 2 3 4 5',
      name: 'vn_blue_long_ld',
      width: 520,
      height: 110,
    );
  });

  testWidgets('short car', (tester) async {
    await render(
      tester,
      spec: VietnamPlates.short(),
      theme: VietnamThemes.white,
      values: '3 0 F 2 5 6 5 8',
      name: 'vn_white_short',
      width: 330,
      height: 165,
    );
  });

  testWidgets('short car yellow', (tester) async {
    await render(
      tester,
      spec: VietnamPlates.short(),
      theme: VietnamThemes.yellow,
      values: '5 1 K 1 2 3 4 5',
      name: 'vn_yellow_short',
      width: 330,
      height: 165,
    );
  });

  testWidgets('motorcycle', (tester) async {
    await render(
      tester,
      spec: VietnamPlates.motorcycle(),
      theme: VietnamThemes.white,
      values: '2 9 A B 2 2 6 5 8',
      name: 'vn_white_moto',
      width: 190,
      height: 140,
    );
  });

  testWidgets('temporary', (tester) async {
    await render(
      tester,
      spec: VietnamPlates.temporary(),
      theme: VietnamThemes.white,
      values: 'T 8 0 2 3 5 8 8',
      name: 'vn_white_temporary',
      width: 330,
      height: 165,
    );
  });

  testWidgets('diplomatic long', (tester) async {
    await render(
      tester,
      spec: VietnamPlates.foreignLong(),
      theme: VietnamThemes.white,
      values: '8 0 4 4 1 N G 4 5',
      name: 'vn_foreign_long_ng',
      width: 520,
      height: 110,
    );
  });

  testWidgets('international organisation long', (tester) async {
    await render(
      tester,
      spec: VietnamPlates.foreignLong(codeFirst: true),
      theme: VietnamThemes.white,
      values: '2 7 Q T 5 4 7 4 5',
      name: 'vn_foreign_long_qt',
      width: 520,
      height: 110,
    );
  });

  testWidgets('foreigner long', (tester) async {
    await render(
      tester,
      spec: VietnamPlates.foreignLong(statusColor: null),
      theme: VietnamThemes.white,
      values: '8 0 4 4 1 N N 4 5',
      name: 'vn_foreign_long_nn',
      width: 520,
      height: 110,
    );
  });

  testWidgets('diplomatic short', (tester) async {
    await render(
      tester,
      spec: VietnamPlates.foreignShort(),
      theme: VietnamThemes.white,
      values: '8 0 4 4 1 N G 4 5',
      name: 'vn_foreign_short_ng',
      width: 330,
      height: 165,
    );
  });

  testWidgets('military long', (tester) async {
    await render(
      tester,
      spec: VietnamPlates.militaryLong(),
      theme: VietnamThemes.red,
      values: 'A B 1 2 3 4',
      name: 'vn_military_long',
      width: 532,
      height: 100,
    );
  });

  testWidgets('military short', (tester) async {
    await render(
      tester,
      spec: VietnamPlates.militaryShort(),
      theme: VietnamThemes.red,
      values: 'A B 1 2 3 4',
      name: 'vn_military_short',
      width: 280,
      height: 200,
    );
  });

  testWidgets('military motorcycle', (tester) async {
    await render(
      tester,
      spec: VietnamPlates.militaryMotorcycle(),
      theme: VietnamThemes.red,
      values: 'A B 1 2 3',
      name: 'vn_military_moto',
      width: 190,
      height: 140,
    );
  });
}
