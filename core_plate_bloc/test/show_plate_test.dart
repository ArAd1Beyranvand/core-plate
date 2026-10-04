import 'package:plate_core/plate_core.dart';
import 'package:core_plate_bloc/core_plate_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _spec = PlateSpec(
  id: 'zz.test',
  country: PlateCountry(
    code: 'zz',
    captionLines: ['ZZ'],
    panelColor: Color(0xFF003399),
    panelTextColor: Color(0xFFFFFFFF),
  ),
  canvasWidth: 400,
  canvasHeight: 110,
  panel: PlatePanel(box: PlateBox(0, 0, 40, 110)),
  slots: [
    PlateSlot(
      alphabet: PlateAlphabet.latinDigits,
      box: PlateBox(70, 17, 60, 76),
    ),
    PlateSlot(
      alphabet: PlateAlphabet.latinDigits,
      box: PlateBox(136, 17, 60, 76),
    ),
  ],
);

const _otherCountry = PlateCountry(
  code: 'yy',
  captionLines: ['YY-CAPTION'],
  panelColor: Color(0xFF990000),
  panelTextColor: Color(0xFFFFFFFF),
);

Future<PlateController> _filled(WidgetTester tester, Widget child) async {
  final controller = PlateController(spec: _spec)..setValues(['1', '2']);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: PlateCardBinding(
        controller: controller,
        child: Center(child: child),
      ),
    ),
  );
  await tester.pump();
  return controller;
}

void main() {
  testWidgets('ShowPlate forwards theme: to PlateCanvas', (tester) async {
    final theme = PlateTheme.standard().copyWith(
      plateBackground: const Color(0xFF112233),
    );
    await _filled(tester, ShowPlate(theme: theme));
    final canvas = tester.widget<PlateCanvas>(find.byType(PlateCanvas));
    expect(canvas.theme?.plateBackground, const Color(0xFF112233));
  });

  testWidgets('ShowPlate forwards country: to PlateCanvas', (tester) async {
    await _filled(tester, const ShowPlate(country: _otherCountry));
    final canvas = tester.widget<PlateCanvas>(find.byType(PlateCanvas));
    expect(canvas.country, same(_otherCountry));
  });

  testWidgets('PlateText and PlateTextView render the same text', (
    tester,
  ) async {
    final controller = PlateController(spec: _spec)..setValues(['1', '2']);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PlateCardBinding(
          controller: controller,
          child: Column(
            children: [
              const PlateText(),
              PlateTextView(controller: controller),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('1'), findsNWidgets(2));
    expect(find.text('2'), findsNWidgets(2));
  });
}
