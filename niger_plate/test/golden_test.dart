import 'dart:io';

import 'package:plate_core/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niger_plate/niger_plate.dart';

/// One golden per livery, each the value of its reference artwork, drawn with
/// DejaVu Sans Bold at 2 px per millimetre so the ink can be measured against
/// `_Layout` in `niger_plates.dart`.
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

  final List<(String, PlateSpec, NigerUsage, List<String>)> cases = [
    (
      'ne_private',
      NigerPlates.privateSpec,
      NigerUsage.private,
      ['8', 'H', '7', '6', '5', '4'],
    ),
    (
      'ne_commercial',
      NigerPlates.commercialSpec,
      NigerUsage.commercial,
      ['1', 'E', '2', '3', '4', '5'],
    ),
    // The four below have no reference image; these goldens pin the layout.
    (
      'ne_state',
      NigerOtherPlates.state,
      NigerUsage.stateTransport,
      ['1', '2', '3', '4', '5', '6'],
    ),
    (
      'ne_military',
      NigerOtherPlates.military,
      NigerUsage.military,
      ['1', '2', '3', '4', '5'],
    ),
    (
      'ne_diplomatic_cmd',
      NigerOtherPlates.diplomaticChief,
      NigerUsage.diplomaticChief,
      ['1', '2', '3'],
    ),
    (
      'ne_diplomatic_cd',
      NigerOtherPlates.diplomaticStaff,
      NigerUsage.diplomaticStaff,
      ['1', '2', '3', '4'],
    ),
  ];
  for (final (name, spec, usage, values) in cases) {
    testWidgets('$name ${values.join(' ')}', (tester) async {
      final PlateController controller = PlateController.fromValues(
        spec,
        values,
      );
      final PlateTheme theme = NigerThemes.forUsage(usage);
      tester.view.physicalSize = const Size(1200, 300);
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
                    country: spec.country,
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
    });
  }

  test('every spec passes debugValidateSpec', () {
    expect(debugValidateSpec(NigerPlates.privateSpec), isTrue);
    expect(debugValidateSpec(NigerPlates.commercialSpec), isTrue);
    expect(debugValidateSpec(NigerOtherPlates.state), isTrue);
    expect(debugValidateSpec(NigerOtherPlates.military), isTrue);
    expect(debugValidateSpec(NigerOtherPlates.diplomaticChief), isTrue);
    expect(debugValidateSpec(NigerOtherPlates.diplomaticStaff), isTrue);
  });

  test('validator', () {
    PlateValidation v(String r, String s, String n) =>
        NigerValidator.validateFields(region: r, series: s, serial: n);
    expect(v('8', 'H', '7654').isValid, isTrue);
    expect(v('1', 'E', '2345').isValid, isTrue);
    expect(v('9', 'H', '7654').isValid, isFalse);
    expect(v('8', '', '7654').isValid, isFalse);
    expect(v('8', 'H', '765').isValid, isFalse);
  });
}
