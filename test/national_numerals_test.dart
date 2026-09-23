import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// National-numeral input: a slot that renders another numeral system accepts a
/// character in EITHER script and always stores the canonical (ASCII) one, and
/// an editable mirror is a second field bound to one slot's value.

const _country = PlateCountry(
  code: 'zz',
  captionLines: ['ZZ'],
  panelColor: Color(0xFF003399),
  panelTextColor: Color(0xFFFFFFFF),
);

const _persian = PlateAlphabet(
  id: 'zz.persian',
  characters: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
  input: AlphabetInput.typed,
  isNumeric: true,
  glyphs: {'0': '۰', '1': '۱', '2': '۲', '3': '۳', '4': '۴', '5': '۵', '6': '۶', '7': '۷', '8': '۸', '9': '۹'},
);

const _latin = PlateAlphabet.latinDigits;

void main() {
  group('PlateAlphabet', () {
    test('accepts both the storage character and its display glyph', () {
      expect(_persian.accepts('5'), isTrue);
      expect(_persian.accepts('۵'), isTrue);
      expect(_persian.accepts('x'), isFalse);
    });

    test('canonical folds a glyph back to storage and leaves storage alone', () {
      expect(_persian.canonical('۵'), '5');
      expect(_persian.canonical('5'), '5');
      // A character that is not a glyph of this alphabet is returned unchanged.
      expect(_persian.canonical('x'), 'x');
    });

    test('a glyphless alphabet is the identity for canonical', () {
      expect(_latin.canonical('7'), '7');
      expect(_latin.accepts('٧'), isFalse);
    });

    test('a glyph shared by two storage chars folds to the first declared', () {
      const shared = PlateAlphabet(
        id: 'zz.shared',
        characters: ['P', 'D'],
        input: AlphabetInput.chosen,
        isNumeric: false,
        glyphs: {'P': 'ش', 'D': 'ش'},
      );
      expect(shared.canonical('ش'), 'P');
    });
  });

  group('PlateController stores canonical', () {
    final spec = PlateSpec(
      id: 'zz.persian.plate',
      country: _country,
      canvasWidth: 100,
      canvasHeight: 40,
      panel: const PlatePanel(box: PlateBox(0, 0, 10, 40)),
      slots: const [
        PlateSlot(alphabet: _persian, box: PlateBox(20, 5, 20, 30)),
        PlateSlot(alphabet: _persian, box: PlateBox(45, 5, 20, 30)),
      ],
    );

    test('setAt with a Persian glyph stores ASCII', () {
      final c = PlateController(spec: spec);
      c.setAt(0, '۵');
      expect(c.valueAt(0), '5');
    });

    test('fromText reads a Persian string into ASCII slots', () {
      final c = PlateController.fromText(spec, '۱۲');
      expect(c.values, ['1', '2']);
    });
  });

  testWidgets('an editable mirror shares one value with its source slot in two scripts', (tester) async {
    final spec = PlateSpec(
      id: 'zz.paired',
      country: _country,
      canvasWidth: 200,
      canvasHeight: 100,
      panel: const PlatePanel(box: PlateBox(0, 0, 10, 40)),
      // Top (primary) row: Persian. One slot.
      slots: const [PlateSlot(alphabet: _persian, box: PlateBox(20, 5, 40, 40))],
      // Bottom row: an editable Latin mirror of slot 0.
      mirrors: const [
        PlateMirror(source: 0, box: PlateBox(20, 55, 40, 40), glyphHeight: 30, alphabet: _latin, editable: true),
      ],
    );
    final controller = PlateController(spec: spec);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlateCanvas(
            spec: spec,
            controller: controller,
            inputSource: PlateInputSource.system,
            onChooseCharacter: (PlateAlphabet a) async => null,
          ),
        ),
      ),
    );

    // Two fields exist: the primary slot and the editable mirror.
    expect(find.byType(TextField), findsNWidgets(2));

    // Mirrors paint before slots, so the mirror (Latin) field is first and the
    // primary slot (Persian) field is last.
    final fields = find.byType(TextField);
    final persianField = fields.last;
    final latinField = fields.first;

    // Typing into the primary (Persian) field stores ASCII and the Latin mirror
    // shows the same value in its own script.
    await tester.enterText(persianField, '۵');
    await tester.pump();
    expect(controller.valueAt(0), '5');
    expect(find.text('۵'), findsOneWidget); // primary row, Persian
    expect(find.text('5'), findsOneWidget); // mirror row, Latin

    // Typing into the mirror (Latin) writes the same one value back.
    await tester.enterText(latinField, '7');
    await tester.pump();
    expect(controller.valueAt(0), '7');
    expect(find.text('۷'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });
}
