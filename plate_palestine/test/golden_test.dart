import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_palestine/plate_palestine.dart';

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
    final bloc = PlateCardBloc(spec);
    for (var i = 0; i < values.length; i++) {
      bloc.add(ValueIsChanged(index: i, value: values[i]));
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 520,
              height: 520 * spec.canvasHeight / spec.canvasWidth,
              child: BlocProvider.value(
                value: bloc,
                child: PlateThemeScope(
                  theme: theme,
                  child: const ShowPlate(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ShowPlate),
      matchesGoldenFile('goldens/$name.png'),
    );
    await bloc.close();
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

    testWidgets('modern motorcycle (green on white)', (tester) async {
      await renderGolden(
        tester,
        spec: PSWestBankPlates.modernMoto,
        theme: PSThemes.forUsage(PSUsage.private),
        values: const ['1', '0', '2', '3', '4', 'H'],
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

    testWidgets('style2021, public transport (blue) + watermark', (tester) async {
      await renderGolden(
        tester,
        spec: PSGazaPlates.car2021,
        theme: PSThemes.forGazaUsageCode('25')!,
        values: const ['3', '0', '2', '3', '4', '2', '5'],
        name: 'gz_2021_car_blue',
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
