import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a keystroke is allowed to rebuild.
///
/// Frame timings are not testable here, but every animation-budget problem this
/// canvas has ever had reduced to a rebuild count: a host that rebuilt the whole
/// screen on every controller notification, or a canvas that rebuilt its own
/// furniture on every keystroke. Those are testable, and this file pins them.
///
/// The proxy for "the canvas rebuilt" is the identity of a widget the canvas
/// constructs in `build`: [CountryPanel] is built once per `PlateCanvas.build`
/// and never by anything narrower, so the same instance surviving a keystroke
/// means the canvas itself did not run.

const _country = PlateCountry(
  code: 'zz',
  captionLines: ['ZZ'],
  panelColor: Color(0xFF003399),
  panelTextColor: Color(0xFFFFFFFF),
);

final PlateSpec _spec = PlateSpec(
  id: 'zz.rebuild',
  country: _country,
  canvasWidth: 400,
  canvasHeight: 100,
  panel: const PlatePanel(box: PlateBox(0, 0, 10, 40)),
  slots: <PlateSlot>[
    for (int i = 0; i < 3; i++) PlateSlot(alphabet: PlateAlphabet.latinDigits, box: PlateBox(20 + i * 25.0, 5, 20, 30)),
  ],
);

/// A [MaterialApp] because the typed slots are [TextField]s, which require
/// [MaterialLocalizations].
Widget _host(PlateController controller, {PlateTheme? theme}) => MaterialApp(
  home: PlateCanvas(
    spec: _spec,
    controller: controller,
    theme: theme,
    onChooseCharacter: (PlateAlphabet a) async => null,
  ),
);

/// The [CountryPanel] instance currently in the tree.
CountryPanel _panelOf(WidgetTester tester) => tester.widget<CountryPanel>(find.byType(CountryPanel));

/// The [ThemeData] the canvas scopes its slots' selection colours with: the
/// outermost [Theme] the canvas itself builds.
ThemeData _selectionThemeOf(WidgetTester tester) =>
    tester.widgetList<Theme>(find.descendant(of: find.byType(PlateCanvas), matching: find.byType(Theme))).first.data;

void main() {
  testWidgets('a keystroke does not rebuild the canvas', (tester) async {
    final PlateController controller = PlateController(spec: _spec);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller));

    final CountryPanel before = _panelOf(tester);
    controller.setAt(0, '1');
    await tester.pump();

    // Not a vacuous pass: the character did land.
    expect(controller.values.first, '1');
    expect(
      identical(_panelOf(tester), before),
      isTrue,
      reason:
          'writing a character rebuilt the whole canvas; only the one '
          '_SlotBinding for that position should have run',
    );
  });

  testWidgets('filling the plate does not rebuild the canvas', (tester) async {
    // The completing keystroke is the interesting one: it flips
    // `controller.completed`, which the frame watches. The frame is allowed to
    // rebuild; the canvas is not.
    final PlateController controller = PlateController(spec: _spec);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller));

    controller.setAt(0, '1');
    controller.setAt(1, '2');
    await tester.pump();
    final CountryPanel before = _panelOf(tester);

    controller.setAt(2, '3');
    await tester.pump();

    expect(controller.isCompleted, isTrue);
    expect(identical(_panelOf(tester), before), isTrue);
  });

  testWidgets('the selection theme is not rebuilt when the theme has not '
      'changed', (tester) async {
    // ThemeData.light() builds a colour scheme, a full text theme and some
    // thirty sub-themes. It used to run on every canvas build; it now depends
    // on one colour and is cached against it.
    final PlateController controller = PlateController(spec: _spec);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller));

    final ThemeData before = _selectionThemeOf(tester);

    // A fresh PlateCanvas widget with identical parameters: the element is
    // updated in place and rebuilds, which is exactly the case the cache is
    // for.
    await tester.pumpWidget(_host(controller));

    expect(
      identical(_selectionThemeOf(tester), before),
      isTrue,
      reason: 'the canvas rebuilt ThemeData.light() for an unchanged colour',
    );
  });

  testWidgets('the selection theme is rebuilt when the active colour changes', (tester) async {
    final PlateController controller = PlateController(spec: _spec);
    addTearDown(controller.dispose);

    final PlateTheme base = PlateTheme.standard();
    await tester.pumpWidget(_host(controller, theme: base));
    final ThemeData before = _selectionThemeOf(tester);

    await tester.pumpWidget(_host(controller, theme: base.copyWith(activeColor: const Color(0xFFFF0000))));

    expect(identical(_selectionThemeOf(tester), before), isFalse);
    expect(_selectionThemeOf(tester).textSelectionTheme.cursorColor, const Color(0xFFFF0000));
  });
}
