import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yemen_plate/yemen_plate.dart';
import 'package:plate_core/plate_core.dart';

/// One golden per category, drawn with real bold faces so the ink can be
/// measured against the references (`platekit golden-check`).
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

  /// category id -> (spec, theme, space-separated sample value)
  final Map<String, (PlateSpec, PlateTheme, String)> cases =
      <String, (PlateSpec, PlateTheme, String)>{
        'private': (
          RiyadhPlates.private,
          RiyadhThemes.standard,
          'T N J 7 6 5 3',
        ),
        'public_transport': (
          RiyadhPlates.publicTransport,
          RiyadhThemes.standard,
          'T N J 7 6 5 3',
        ),
        'commercial': (
          RiyadhPlates.commercial,
          RiyadhThemes.standard,
          'T N J 7 6 5 3',
        ),
        'temporary': (
          RiyadhPlates.temporary,
          RiyadhThemes.standard,
          'T N J 7 6 5 3',
        ),
        'diplomatic': (
          RiyadhPlates.diplomatic,
          RiyadhThemes.standard,
          'T N J 7 6 5 3',
        ),
        'eu_private': (
          RiyadhPlates.euPrivate,
          RiyadhThemes.standard,
          'T N J 7 3 5 6',
        ),
        'eu_public_transport': (
          RiyadhPlates.euPublicTransport,
          RiyadhThemes.standard,
          'T N J 7 3 5 6',
        ),
        'eu_commercial': (
          RiyadhPlates.euCommercial,
          RiyadhThemes.standard,
          'T N J 7 3 5 6',
        ),
        'eu_temporary': (
          RiyadhPlates.euTemporary,
          RiyadhThemes.standard,
          'T N J 7 3 5 6',
        ),
        'eu_diplomatic': (
          RiyadhPlates.euDiplomatic,
          RiyadhThemes.standard,
          'T N J 7 3 5 6',
        ),
      };

  for (final MapEntry<String, (PlateSpec, PlateTheme, String)> c
      in cases.entries) {
    testWidgets(c.key, (tester) async {
      final (PlateSpec spec, PlateTheme theme, String values) = c.value;
      final PlateController controller = PlateController.fromValues(
        spec,
        values.split(' '),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 680,
                height: 300,
                child: PlateThemeScope(
                  theme: theme,
                  child: PlateView(
                    controller: controller,
                    theme: theme,
                    country: RiyadhCountry
                        .byCategory[c.key.replaceFirst('eu_', '')]!,
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
        matchesGoldenFile('goldens/riyadh/${c.key}.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }
}
