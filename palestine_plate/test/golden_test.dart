import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palestine_plate/palestine_plate.dart';

/// One golden per (spec x usage theme), so a calibration change — a colour, a
/// ratio, a box moved a unit — shows up as a visible diff instead of an
/// invisible one. That is the entire point of the `// CALIBRATE` discipline in
/// this package: a tuned hex with nothing watching it is a silent regression
/// waiting to happen.
///
/// Regenerate with `flutter test --update-goldens` after a deliberate change.
void main() {
  Future<void> renderGolden(
    WidgetTester tester, {
    required PlateSpec spec,
    required PlateTheme theme,
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
                child: PlateView(controller: controller, theme: theme),
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
    controller.dispose();
  }

  group('West Bank goldens', () {
    testWidgets('modern car, private (green on white)', (tester) async {
      await renderGolden(
        tester,
        spec: PSWestBankPlates.modernCar,
        theme: PSThemes.forUsage(PSUsage.private),
        values: const ['1', '0', '2', '3', '4', 'H'],
        name: 'wb_modern_car_green',
      );
    });

    testWidgets('legacy car, private (green on white)', (tester) async {
      await renderGolden(
        tester,
        spec: PSWestBankPlates.legacyCar,
        theme: PSThemes.forUsage(PSUsage.private),
        values: const ['4', '0', '2', '3', '4', '4', '1'],
        name: 'wb_legacy_car_green',
      );
    });

    testWidgets('legacy car, public transport (white on green)', (tester) async {
      await renderGolden(
        tester,
        spec: PSWestBankPlates.legacyCarPublicTransport,
        theme: PSThemes.forUsage(PSUsage.publicTransport),
        values: const ['4', '0', '2', '3', '4', '3', '0'],
        name: 'wb_legacy_car_publicTransport_whiteOnGreen',
      );
    });

    testWidgets('legacy car, government (red on white)', (tester) async {
      await renderGolden(
        tester,
        spec: PSWestBankPlates.legacyCarGovernment,
        theme: PSThemes.forUsage(PSUsage.government),
        values: const ['4', '0', '2', '3', '4', '9', '9'],
        name: 'wb_legacy_car_government_red',
      );
    });

    testWidgets('modern car, two-line (green on white)', (tester) async {
      await renderGolden(
        tester,
        spec: PSWestBankPlates.modernCarTwoLine,
        theme: PSThemes.forUsage(PSUsage.private),
        values: const ['1', '0', '2', '3', '4', 'H'],
        name: 'wb_modern_car2l_green',
      );
    });

    testWidgets('legacy car, two-line (green on white)', (tester) async {
      await renderGolden(
        tester,
        spec: PSWestBankPlates.legacyCarTwoLine,
        theme: PSThemes.forUsage(PSUsage.private),
        values: const ['4', '0', '2', '3', '4', '4', '1'],
        name: 'wb_legacy_car2l_green',
      );
    });

    // The value is the reference image's own — `2·0345·L`, from
    // pics/License_Plate_-_Palestine_-_Motorcycle_-_2018_-_1-Line_Design.png —
    // so this golden is directly comparable to the photograph the spec was
    // measured off.
    testWidgets('modern motorcycle (green on white)', (tester) async {
      await renderGolden(
        tester,
        spec: PSWestBankPlates.modernMoto,
        theme: PSThemes.forUsage(PSUsage.private),
        values: const ['2', '0', '3', '4', '5', 'L'],
        name: 'wb_modern_moto_green',
      );
    });

    testWidgets('modern motorcycle, two-line (green on white)', (tester) async {
      await renderGolden(
        tester,
        spec: PSWestBankPlates.modernMotoTwoLine,
        theme: PSThemes.forUsage(PSUsage.private),
        values: const ['1', '0', '2', '3', '4', 'H'],
        name: 'wb_modern_moto2l_green',
      );
    });

    testWidgets('trade plate (white on blue)', (tester) async {
      await renderGolden(
        tester,
        spec: PSWestBankPlates.modernTrade,
        theme: PSThemes.forUsage(PSUsage.tradePlate),
        values: const ['1', '0', '2', '3', '4', 'H'],
        name: 'wb_modern_trade_blue',
      );
    });
  });

  group('Gaza goldens', () {
    testWidgets('style2012, private (black)', (tester) async {
      await renderGolden(
        tester,
        spec: PSGazaPlates.car2012,
        theme: PSThemes.forGazaUsageCode('05')!,
        values: const ['3', '0', '2', '3', '4', '0', '5'],
        name: 'gz_2012_car_black',
      );
    });

    testWidgets('motorcycle, public transport (blue) + watermark', (tester) async {
      await renderGolden(
        tester,
        spec: PSGazaPlates.moto,
        theme: PSThemes.forGazaUsageCode('25')!,
        values: const ['3', '0', '2', '3', '4', '2', '5'],
        name: 'gz_moto_blue',
      );
    });

    testWidgets('style2012 two-line, commercial (green)', (tester) async {
      await renderGolden(
        tester,
        spec: PSGazaPlates.car2012TwoLine,
        theme: PSThemes.forGazaUsageCode('15')!,
        values: const ['3', '0', '2', '3', '4', '1', '5'],
        name: 'gz_2012_car2l_green',
      );
    });

    testWidgets('style2021 two-line, government (red) + watermark', (tester) async {
      await renderGolden(
        tester,
        spec: PSGazaPlates.car2021TwoLine,
        theme: PSThemes.forGazaUsageCode('55')!,
        values: const ['3', '0', '2', '3', '4', '5', '5'],
        name: 'gz_2021_car2l_red',
      );
    });
  });
}
