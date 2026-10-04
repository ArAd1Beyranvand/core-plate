import 'package:plate_core/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yemen_plate/yemen_plate.dart';

/// Goldens for the northern (System B) specs. Modelled on
/// `palestine_plate/test/golden_test.dart`.
///
/// The private/government pair off `carGov2Serial5` is the point of this
/// file: one spec, rendered twice with only `country:` and `theme:` differing,
/// is the P4 country/theme split shown as pixels. If the two are wired
/// correctly the images differ in field colour and panel word and nothing
/// else — same geometry, same digits, same mirrors.
///
/// The other two goldens pin the P3B pitch corrections (`carGov2Serial4`'s
/// register used to end one unit past its siblings; `motoGov2Serial5`'s
/// fourth cell used to sit 0.4 unit off pitch) so the fix has a rendered
/// appearance on record, not just a changelog entry.
///
/// Regenerate with `flutter test --update-goldens` after a deliberate change.
void main() {
  Future<void> renderGolden(
    WidgetTester tester, {
    required PlateSpec spec,
    required PlateTheme theme,
    required PlateCountry country,
    required List<String?> values,
    required String name,
  }) async {
    final controller = PlateController.fromValues(spec, values);

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
                  country: country,
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

  group('northern car g2s5: one spec, two usages', () {
    // 2 governorate digits + 5 serial digits = 7 slots.
    final spec = YemenNorthernPlates.car(
      governorateDigits: 2,
      serialDigits: 5,
    )!;

    testWidgets('private (blue)', (tester) async {
      await renderGolden(
        tester,
        spec: spec,
        theme: YemenThemes.forNorthernUsage(YemenUsage.private),
        country: YemenCountry.northernFor(YemenUsage.private),
        values: const ['1', '2', '3', '4', '5', '6', '7'],
        name: 'ye_northern_car_g2s5_private',
      );
    });

    testWidgets('government (green)', (tester) async {
      await renderGolden(
        tester,
        spec: spec,
        theme: YemenThemes.forNorthernUsage(YemenUsage.government),
        country: YemenCountry.northernFor(YemenUsage.government),
        values: const ['1', '2', '3', '4', '5', '6', '7'],
        name: 'ye_northern_car_g2s5_government',
      );
    });
  });

  group('P3B pitch corrections, pinned', () {
    testWidgets('carGov2Serial4: register now ends flush at 530', (
      tester,
    ) async {
      await renderGolden(
        tester,
        spec: YemenNorthernPlates.carGov2Serial4,
        theme: YemenThemes.forNorthernUsage(YemenUsage.private),
        country: YemenCountry.northernFor(YemenUsage.private),
        values: const ['1', '2', '3', '4', '5', '6'],
        name: 'ye_northern_car_g2s4',
      );
    });

    testWidgets('motoGov2Serial5: uniform 41.8 pitch', (tester) async {
      await renderGolden(
        tester,
        // ignore: deprecated_member_use_from_same_package
        spec: YemenNorthernPlates.motoGov2Serial5,
        theme: YemenThemes.forNorthernUsage(YemenUsage.private),
        country: YemenCountry.northernFor(YemenUsage.private),
        values: const ['1', '2', '3', '4', '5', '6', '7'],
        name: 'ye_northern_moto_g2s5',
      );
    });
  });
}
