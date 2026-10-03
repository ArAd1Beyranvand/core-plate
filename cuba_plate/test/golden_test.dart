import 'dart:io';

import 'package:core_plate/core_plate.dart';
import 'package:cuba_plate/cuba_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// One golden per spec, rendered with a real font so the CUBA stack and the
/// serial can be measured against the reference photographs.
///
/// Regenerate with `flutter test --update-goldens` after a deliberate change.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Roboto');
    final file = File('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf');
    if (file.existsSync()) {
      loader.addFont(file.readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await loader.load();
  });

  Future<void> renderGolden(
    WidgetTester tester,
    PlateSpec spec,
    String value,
    String name,
  ) async {
    final controller = PlateController.fromValues(spec, <String?>[
      for (final c in value.split('')) c,
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 520,
              height: 520 * spec.canvasHeight / spec.canvasWidth,
              child: PlateThemeScope(
                theme: CubaPlates.theme,
                child: PlateView(
                  controller: controller,
                  theme: CubaPlates.theme,
                  country: CubaCountry.cuba,
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

  testWidgets(
    'car, natural person',
    (t) => renderGolden(t, CubaPlates.car, 'D004027', 'cu_car'),
  );
  testWidgets(
    'car, legal entity',
    (t) => renderGolden(
      t,
      CubaPlates.carLegalEntity,
      'K000807',
      'cu_car_legal_entity',
    ),
  );
  testWidgets(
    'motorcycle',
    (t) => renderGolden(t, CubaPlates.motorcycle, 'P28588', 'cu_motorcycle'),
  );
}
