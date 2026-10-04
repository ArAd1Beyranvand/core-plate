import 'dart:io';

import 'package:plate_core/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indonesia_plate/indonesia_plate.dart';

/// One golden per category, drawn with a real bold face so the ink can be
/// measured against the references (see `_Layout` in `indonesia_plates.dart`).
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
              width: 520,
              height: 520 * spec.canvasHeight / spec.canvasWidth,
              child: PlateThemeScope(
                theme: theme,
                child: PlateView(
                  controller: controller,
                  theme: theme,
                  country: IndonesiaCountry.indonesia,
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

  testWidgets('private car', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.car(prefix: 1),
      theme: IndonesiaThemes.private,
      values: 'B 1 9 4 5 P K L 0 8 2 8',
      name: 'id_car_private',
    );
  });

  testWidgets('public car', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.car(),
      theme: IndonesiaThemes.public,
      values: 'X X 1 2 3 4 A B C 0 8 2 8',
      name: 'id_car_public',
    );
  });

  testWidgets('government car', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.car(),
      theme: IndonesiaThemes.government,
      values: 'X X 1 2 3 4 A B C 0 8 2 8',
      name: 'id_car_govt',
    );
  });

  testWidgets('free-trade-zone car', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.car(),
      theme: IndonesiaThemes.freeTradeZone,
      values: 'B P 1 2 3 4 A B C 0 8 2 8',
      name: 'id_car_ftz',
    );
  });

  testWidgets('private EV car', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.car(band: true),
      theme: IndonesiaThemes.privateEv,
      values: 'X X 1 2 3 4 A B C 0 8 2 8',
      name: 'id_car_private_ev',
    );
  });

  testWidgets('public EV car', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.car(band: true),
      theme: IndonesiaThemes.publicEv,
      values: 'X X 1 2 3 4 A B C 0 8 2 8',
      name: 'id_car_public_ev',
    );
  });

  testWidgets('government EV car', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.car(band: true),
      theme: IndonesiaThemes.governmentEv,
      values: 'X X 1 2 3 4 A B C 0 8 2 8',
      name: 'id_car_govt_ev',
    );
  });

  testWidgets('FTZ EV car', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.car(band: true),
      theme: IndonesiaThemes.freeTradeZoneEv,
      values: 'X X 1 2 3 4 A B C 0 8 2 8',
      name: 'id_car_ftz_ev',
    );
  });

  testWidgets('short car, B 1 A', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.car(prefix: 1, digits: 1, suffix: 1),
      theme: IndonesiaThemes.private,
      values: 'B 1 A 0 1 2 8',
      name: 'id_car_short',
    );
  });

  testWidgets('private motorcycle', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.motorcycle(),
      theme: IndonesiaThemes.private,
      values: 'X X 1 2 3 4 A B C 0 8 2 8',
      name: 'id_moto_private',
    );
  });

  testWidgets('public motorcycle', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.motorcycle(),
      theme: IndonesiaThemes.public,
      values: 'X X 1 2 3 4 A B C 0 8 2 8',
      name: 'id_moto_public',
    );
  });

  testWidgets('government motorcycle', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.motorcycle(),
      theme: IndonesiaThemes.government,
      values: 'X X 1 2 3 4 A B C 0 8 2 8',
      name: 'id_moto_govt',
    );
  });

  testWidgets('FTZ motorcycle', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.motorcycle(),
      theme: IndonesiaThemes.freeTradeZone,
      values: 'X X 1 2 3 4 A B C 0 8 2 8',
      name: 'id_moto_ftz',
    );
  });

  testWidgets('private EV motorcycle', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.motorcycle(band: true),
      theme: IndonesiaThemes.privateEv,
      values: 'X X 1 2 3 4 A B C 0 8 2 8',
      name: 'id_moto_private_ev',
    );
  });

  testWidgets('public EV motorcycle', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.motorcycle(band: true),
      theme: IndonesiaThemes.publicEv,
      values: 'X X 1 2 3 4 A B C 0 8 2 8',
      name: 'id_moto_public_ev',
    );
  });

  testWidgets('government EV motorcycle', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.motorcycle(band: true),
      theme: IndonesiaThemes.governmentEv,
      values: 'X X 1 2 3 4 A B C 0 8 2 8',
      name: 'id_moto_govt_ev',
    );
  });

  testWidgets('FTZ EV motorcycle', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.motorcycle(band: true),
      theme: IndonesiaThemes.freeTradeZoneEv,
      values: 'X X 1 2 3 4 A B C 0 8 2 8',
      name: 'id_moto_ftz_ev',
    );
  });

  testWidgets('diplomatic', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.diplomatic(),
      theme: IndonesiaThemes.diplomatic,
      values: 'CD 1 2 3 1 2 3 0 8 2 8',
      name: 'id_diplomatic',
    );
  });

  testWidgets('diplomatic EV', (tester) async {
    await render(
      tester,
      spec: IndonesiaPlates.diplomatic(),
      theme: IndonesiaThemes.diplomaticEv,
      values: 'CD 1 2 3 1 2 3 0 8 2 8',
      name: 'id_diplomatic_ev',
    );
  });

  test('validator', () {
    bool ok(
      String prefix,
      String number, [
      String suffix = '',
      String month = '',
    ]) =>
        IndonesiaValidator.validateFields(
          prefix: prefix,
          number: number,
          suffix: suffix,
          month: month,
        ) ==
        const PlateValidation.valid();
    expect(ok('B', '1945', 'PKL', '01'), isTrue);
    expect(ok('XX', '1234'), isFalse);
    expect(ok('B', '0123'), isFalse);
    expect(ok('B', '1', '', '13'), isFalse);
  });

  test('generator fills every slot', () {
    final PlateSpec spec = IndonesiaPlates.car();
    expect(IndonesiaSerialGenerator.generate(spec), everyElement(isNotNull));
  });
}
