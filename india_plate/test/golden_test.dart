import 'dart:io';

import 'package:plate_core/plate_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:india_plate/india_plate.dart';

/// One golden per format and colour class, rendered with a real font so the
/// row can be measured against the colour-class artwork.
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
    PlateTheme theme,
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
              width: 760,
              height: 760 * spec.canvasHeight / spec.canvasWidth,
              child: PlateThemeScope(
                theme: theme,
                child: PlateView(
                  controller: controller,
                  theme: theme,
                  country: IndiaCountry.india,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // The chakra decal decodes off the real event loop, which fake time does
    // not advance; give it a real slice of time before the golden is taken.
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

  final cases = <(String, PlateSpec, PlateTheme, String)>[
    ('in_private', IndiaPlates.private, IndiaThemes.private, 'MH20DV2366'),
    ('in_transport', IndiaPlates.standard, IndiaThemes.transport, 'MH12DV4353'),
    ('in_rental', IndiaPlates.standard, IndiaThemes.rental, 'MH09DV5346'),
    ('in_electric', IndiaPlates.standard, IndiaThemes.electric, 'MH04DV4321'),
    (
      'in_electric_transport',
      IndiaPlates.standard,
      IndiaThemes.electricTransport,
      'MH04DV4321',
    ),
    (
      'in_diplomatic',
      IndiaPlates.diplomatic,
      IndiaThemes.diplomatic,
      '052CD0019',
    ),
    ('in_consular', IndiaPlates.diplomatic, IndiaThemes.consular, '199CC0123'),
    ('in_bharat', IndiaPlates.bharat, IndiaThemes.private, '212345AA'),
    ('in_vintage', IndiaPlates.vintage, IndiaThemes.private, 'MHAA0000'),
    ('in_military', IndiaPlates.military, IndiaThemes.military, '02B084821H'),
    (
      'in_military_police',
      IndiaPlates.military,
      IndiaThemes.militaryPolice,
      '24B123456Z',
    ),
    (
      'in_temporary',
      IndiaPlates.temporary,
      IndiaThemes.temporary,
      '1123KL5986KA',
    ),
    ('in_trade', IndiaPlates.trade, IndiaThemes.trade, 'UP16C00020073'),
  ];
  for (final (name, spec, theme, value) in cases) {
    testWidgets(name, (t) => renderGolden(t, spec, theme, value, name));
  }
}
