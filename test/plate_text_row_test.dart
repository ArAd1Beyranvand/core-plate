import 'package:plate_core/plate_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _country = PlateCountry(
  code: 'zz',
  captionLines: ['ZZ'],
  panelColor: Color(0xFF003399),
  panelTextColor: Color(0xFFFFFFFF),
);

const _panel = PlatePanel(box: PlateBox(0, 0, 10, 40));
const _digits = PlateAlphabet.latinDigits;
const _iranianDigits = PlateAlphabet(
  id: 'zz.iranian',
  characters: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
  input: AlphabetInput.typed,
  isNumeric: false,
  glyphs: {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
  },
);

PlateSlot _slot(PlateAlphabet a, double left) =>
    PlateSlot(alphabet: a, box: PlateBox(left, 5, 20, 30));

PlateSpec _spec({
  List<PlateAlphabet> alphabets = const [_digits, _digits, _digits],
  List<PlateTextGroup> textGroups = const [],
  TextDirection textDirection = TextDirection.ltr,
}) => PlateSpec(
  id: 'zz.test',
  country: _country,
  canvasWidth: 400,
  canvasHeight: 100,
  panel: _panel,
  slots: [
    for (var i = 0; i < alphabets.length; i++)
      _slot(alphabets[i], 20 + i * 25.0),
  ],
  textGroups: textGroups,
  textDirection: textDirection,
);

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  Directionality(textDirection: TextDirection.ltr, child: child),
);

void main() {
  testWidgets(
    'empty group renders nothing; filled group renders through glyphs',
    (tester) async {
      final spec = _spec(
        alphabets: const [_digits, _iranianDigits],
        textGroups: const [
          PlateTextGroup([0]),
          PlateTextGroup([1]),
        ],
      );
      await _pump(tester, PlateTextRow(spec: spec, values: const ['1', null]));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('٢'), findsNothing);

      await _pump(tester, PlateTextRow(spec: spec, values: const ['1', '2']));
      expect(find.text('٢'), findsOneWidget);
    },
  );

  testWidgets('group order follows textDirection; prefix is prepended', (
    tester,
  ) async {
    final spec = _spec(
      textGroups: const [
        PlateTextGroup([0], prefix: 'A-'),
        PlateTextGroup([1]),
        PlateTextGroup([2]),
      ],
      textDirection: TextDirection.rtl,
    );
    await _pump(
      tester,
      PlateTextRow(spec: spec, values: const ['1', '2', '3']),
    );
    expect(find.text('A-1'), findsOneWidget);
    final row = tester.widget<Directionality>(
      find.descendant(
        of: find.byType(PlateTextRow),
        matching: find.byType(Directionality),
      ),
    );
    expect(row.textDirection, TextDirection.rtl);
  });

  testWidgets(
    'values shorter than slots renders what fits and does not throw',
    (tester) async {
      final spec = _spec(
        textGroups: const [
          PlateTextGroup([0]),
          PlateTextGroup([1]),
          PlateTextGroup([2]),
        ],
      );
      await _pump(tester, PlateTextRow(spec: spec, values: const ['1']));
      expect(find.text('1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('null textStyle gives black', (tester) async {
    final spec = _spec(
      textGroups: const [
        PlateTextGroup([0]),
      ],
    );
    await _pump(tester, PlateTextRow(spec: spec, values: const ['1']));
    final style = tester.widget<DefaultTextStyle>(
      find.descendant(
        of: find.byType(PlateTextRow),
        matching: find.byType(DefaultTextStyle),
      ),
    );
    expect(style.style.color, const Color(0xFF000000));
  });
}
