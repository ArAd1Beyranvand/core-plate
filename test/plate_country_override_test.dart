import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The spec's own country: what a canvas paints when nothing overrides it.
const _specCountry = PlateCountry(
  code: 'zz',
  captionLines: ['ZZCAPTION'],
  panelColor: Color(0xFF003399),
  panelTextColor: Color(0xFFFFFFFF),
);

/// The render-time override: a different block entirely — different code, so
/// the two are unequal, and a different caption, so a pump can tell them apart.
const _overrideCountry = PlateCountry(
  code: 'qq',
  captionLines: ['QQCAPTION'],
  panelColor: Color(0xFFCC0000),
  panelTextColor: Color(0xFF000000),
);

/// The usage-class case the override exists for: the same country, recoloured.
/// Equal to [_specCountry] by `code`, so it is *only* reachable at render time.
const _sameCodeOtherInk = PlateCountry(
  code: 'zz',
  captionLines: ['ZZCAPTION'],
  panelColor: Color(0xFF003399),
  panelTextColor: Color(0xFF00FF00),
);

const _panel = PlatePanel(box: PlateBox(0, 0, 60, 100));

const _spec = PlateSpec(
  id: 'zz.override',
  country: _specCountry,
  canvasWidth: 400,
  canvasHeight: 100,
  panel: _panel,
  slots: [
    PlateSlot(alphabet: PlateAlphabet.latinDigits, box: PlateBox(80, 20, 40, 60)),
    PlateSlot(alphabet: PlateAlphabet.latinDigits, box: PlateBox(140, 20, 40, 60)),
  ],
  labels: [PlateLabel(text: 'LABEL', box: PlateBox(220, 20, 60, 30), glyphHeight: 20)],
  rules: [PlateRule(box: PlateBox(200, 10, 2, 80))],
);

Future<String?> _noChooser(PlateAlphabet _) async => null;

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PlateCanvas.country', () {
    testWidgets('paints the spec country when no override is passed', (tester) async {
      await tester.pumpWidget(
        _host(const PlateCanvas(spec: _spec, mode: PlateMode.display, onChooseCharacter: _noChooser)),
      );

      expect(find.text('ZZCAPTION'), findsOneWidget);
      expect(find.text('QQCAPTION'), findsNothing);
    });

    testWidgets('paints the override instead of the spec country', (tester) async {
      await tester.pumpWidget(
        _host(
          const PlateCanvas(
            spec: _spec,
            mode: PlateMode.display,
            country: _overrideCountry,
            onChooseCharacter: _noChooser,
          ),
        ),
      );

      expect(find.text('QQCAPTION'), findsOneWidget);
      expect(find.text('ZZCAPTION'), findsNothing);
      expect(tester.widget<CountryPanel>(find.byType(CountryPanel)).country, _overrideCountry);
    });

    testWidgets('reaches the panel even when it compares equal to the spec\'s', (tester) async {
      // The whole point of the override: `_sameCodeOtherInk == _specCountry`,
      // so a spec could never distinguish them — but the renderer must.
      expect(_sameCodeOtherInk, _specCountry);

      await tester.pumpWidget(
        _host(
          const PlateCanvas(
            spec: _spec,
            mode: PlateMode.display,
            country: _sameCodeOtherInk,
            onChooseCharacter: _noChooser,
          ),
        ),
      );

      final panel = tester.widget<CountryPanel>(find.byType(CountryPanel));
      expect(panel.country.panelTextColor, const Color(0xFF00FF00));
    });

    testWidgets('changes nothing but the panel', (tester) async {
      Future<void> pumpWith(PlateCountry? country) => tester.pumpWidget(
        _host(
          PlateCanvas(
            spec: _spec,
            mode: PlateMode.display,
            country: country,
            controller: PlateController(spec: _spec)
              ..setAt(0, '7')
              ..setAt(1, '3'),
            onChooseCharacter: _noChooser,
          ),
        ),
      );

      await pumpWith(null);
      final baseline = (
        seven: find.text('7').evaluate().length,
        three: find.text('3').evaluate().length,
        label: find.text('LABEL').evaluate().length,
        rules: find.byType(ColoredBox).evaluate().length,
      );
      expect(baseline.seven, 1);
      expect(baseline.three, 1);
      expect(baseline.label, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpWith(_overrideCountry);

      expect(find.text('7').evaluate().length, baseline.seven);
      expect(find.text('3').evaluate().length, baseline.three);
      expect(find.text('LABEL').evaluate().length, baseline.label);
      expect(find.byType(ColoredBox).evaluate().length, baseline.rules);
    });

    testWidgets('swapping it on a live canvas does not rebuild the machine', (tester) async {
      final controller = PlateController(spec: _spec);
      addTearDown(controller.dispose);
      var activeIndexCalls = 0;

      // Input mode here, unlike the rendering tests: the property under test is
      // that focus survives, and focus only exists where slots take input.
      Future<void> pumpWith(PlateCountry? country) => tester.pumpWidget(
        _host(
          PlateCanvas(
            spec: _spec,
            country: country,
            controller: controller,
            onActiveIndexChanged: (_) => activeIndexCalls++,
            onChooseCharacter: _noChooser,
          ),
        ),
      );

      await pumpWith(null);
      await tester.pumpAndSettle();
      controller.setAt(0, '7');
      controller.setAt(1, '3');
      controller.focusSlot(1);
      await tester.pumpAndSettle();

      final callsBefore = activeIndexCalls;
      final activeBefore = controller.activeIndex;
      // A rebuilt machine would hold fresh, unfocused nodes, so this is the
      // assertion that has teeth below.
      expect(activeBefore, 1);

      // The same canvas, same spec, different country: a rebuild, not a
      // remount. A `copyWith`-shaped spec change here would have rebuilt the
      // machine and migrated the values.
      await pumpWith(_overrideCountry);
      await tester.pumpAndSettle();

      expect(activeIndexCalls, callsBefore);
      expect(controller.activeIndex, activeBefore);
      expect(controller.values, ['7', '3']);
      expect(find.text('QQCAPTION'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('a flagless override renders no flag but keeps its caption', (tester) async {
      expect(_overrideCountry.flag, isNull);

      await tester.pumpWidget(
        _host(
          const PlateCanvas(
            spec: _spec,
            mode: PlateMode.display,
            country: _overrideCountry,
            onChooseCharacter: _noChooser,
          ),
        ),
      );

      expect(find.byType(PlateFlag), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.text('QQCAPTION'), findsOneWidget);
    });
  });

  group('PlateView.country', () {
    testWidgets('forwards the override to its canvas', (tester) async {
      final controller = PlateController(spec: _spec)..setAt(0, '7');
      addTearDown(controller.dispose);

      await tester.pumpWidget(_host(PlateView(controller: controller, country: _overrideCountry)));

      expect(tester.widget<PlateCanvas>(find.byType(PlateCanvas)).country, _overrideCountry);
      expect(find.text('QQCAPTION'), findsOneWidget);
      expect(find.text('ZZCAPTION'), findsNothing);
    });

    testWidgets('keeps the spec country when none is passed', (tester) async {
      final controller = PlateController(spec: _spec)..setAt(0, '7');
      addTearDown(controller.dispose);

      await tester.pumpWidget(_host(PlateView(controller: controller)));

      expect(find.text('ZZCAPTION'), findsOneWidget);
    });
  });
}
