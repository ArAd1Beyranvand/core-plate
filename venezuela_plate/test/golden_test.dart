import 'dart:io';

import 'package:plate_core/core_plate.dart';
import 'package:venezuela_plate/venezuela_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// One golden per spec, rendered with a real font so the caption, state name and the
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
                theme: VenezuelaPlates.theme,
                child: PlateView(
                  controller: controller,
                  theme: VenezuelaPlates.theme,
                  country: VenezuelaCountry.venezuela,
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
    'car, Lara',
    (t) => renderGolden(t, VenezuelaPlates.car, 'AB174SK', 've_car_lara'),
  );
  testWidgets(
    'car, Distrito Capital',
    (t) => renderGolden(
      t,
      VenezuelaPlates.car,
      'AA848YA',
      've_car_distrito_capital',
    ),
  );
}
