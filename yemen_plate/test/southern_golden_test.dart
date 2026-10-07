import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_core/plate_core.dart';
import 'package:yemen_plate/yemen_plate.dart';

/// One golden per southern plate in the article, rendered with real fonts so
/// the ink can be measured against the Wikipedia artwork. Regenerate with
/// `flutter test --update-goldens test/southern_golden_test.dart`.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Roboto');
    for (final path in const [
      '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
      '/usr/share/fonts/truetype/noto/NotoSansArabic-Bold.ttf',
    ]) {
      final file = File(path);
      if (!file.existsSync()) continue;
      loader.addFont(file.readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await loader.load();
  });

  Future<void> golden(
    WidgetTester tester,
    String name,
    PlateSpec spec,
    PlateTheme theme,
    PlateCountry country,
  ) async {
    assert(debugValidateSpec(spec));
    final values = List<String?>.generate(
      spec.slotCount,
      (i) => '1023456'[i % 7],
    );
    final controller = PlateController.fromValues(spec, values);
    await tester.binding.setSurfaceSize(const Size(600, 600));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF808080),
          body: Center(
            child: SizedBox(
              width: 520,
              height: 520 * spec.canvasHeight / spec.canvasWidth,
              child: PlateThemeScope(
                theme: theme,
                child: PlateView(
                  controller: controller,
                  theme: theme,
                  country: country,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Decals decode off the fake clock; load them for real before the shot.
    final context = tester.element(find.byType(PlateView));
    await tester.runAsync(() async {
      for (final decal in spec.decals) {
        await precacheImage(decal.image, context);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(PlateView),
      matchesGoldenFile('goldens/southern/$name.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  }

  const t = YemenThemes.southern;
  final cases = <(String, PlateSpec, PlateTheme, PlateCountry)>[
    for (final (id, g, car, moto) in [
      (
        'hadhramaut',
        YemenSouthernGovernorate.hadhramaut,
        YemenGovernoratePlates.hadhramaut,
        YemenGovernoratePlates.hadhramautMotorcycle,
      ),
      (
        'mahrah',
        YemenSouthernGovernorate.alMahrah,
        YemenGovernoratePlates.alMahrah,
        YemenGovernoratePlates.alMahrahMotorcycle,
      ),
      (
        'shabwah',
        YemenSouthernGovernorate.shabwah,
        YemenGovernoratePlates.shabwah,
        YemenGovernoratePlates.shabwahMotorcycle,
      ),
      (
        'marib',
        YemenSouthernGovernorate.marib,
        YemenGovernoratePlates.marib,
        YemenGovernoratePlates.maribMotorcycle,
      ),
    ]) ...[
      for (final (usage, country) in const [
        ('private', YemenCountry.southernPrivate),
        ('hire', YemenCountry.southernForHire),
        ('commercial', YemenCountry.southernCommercial),
        ('government', YemenCountry.southernGovernment),
      ])
        if (!(g.banded && usage == 'government'))
          ('${id}_$usage', car, t, country),
      ('${id}_motorcycle', moto, t, moto.country),
    ],
    (
      'hadhramaut_private_5',
      YemenGovernoratePlates.hadhramautFiveDigit,
      t,
      YemenCountry.southernPrivate,
    ),
    (
      'hadhramaut_temporary',
      YemenGovernoratePlates.hadhramautTemporary,
      t,
      YemenCountry.southernTemporary,
    ),
    (
      'shabwah_temporary',
      YemenGovernoratePlates.shabwahTemporary,
      t,
      YemenCountry.southernTemporary,
    ),
    (
      'hadhramaut_police',
      YemenGovernoratePlates.hadhramautPolice,
      t,
      YemenCountry.southernPolice,
    ),
    (
      'shabwah_police',
      YemenGovernoratePlates.shabwahPolice,
      t,
      YemenCountry.southernPolice,
    ),
    (
      'aden_520x110',
      YemenAdenPlates.oneLine,
      YemenThemes.aden,
      YemenCountry.plain,
    ),
    (
      'aden_335x170',
      YemenAdenPlates.twoLine,
      YemenThemes.aden,
      YemenCountry.plain,
    ),
    (
      'taiz_private',
      YemenTaizPlates.temporary,
      YemenThemes.taizPrivate,
      YemenCountry.plain,
    ),
    (
      'taiz_commercial',
      YemenTaizPlates.temporary,
      YemenThemes.taizCommercial,
      YemenCountry.plain,
    ),
  ];

  for (final (name, spec, theme, country) in cases) {
    testWidgets(name, (tester) => golden(tester, name, spec, theme, country));
  }
}
