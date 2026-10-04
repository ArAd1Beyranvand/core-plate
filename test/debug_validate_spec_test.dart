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

/// Same accepted characters as [_digits], different rendering, different id —
/// the legal pair `yemen_plate`'s `ye.digits` / `ye.iranianDigits` depends on.
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

PlateSpec _spec({
  List<PlateSlot> slots = const [],
  List<PlateMirror> mirrors = const [],
  PlateSection background = PlateSection.plain,
}) => PlateSpec(
  id: 'zz.test',
  country: _country,
  canvasWidth: 400,
  canvasHeight: 100,
  panel: _panel,
  slots: slots.isEmpty
      ? const [
          PlateSlot(alphabet: _digits, box: PlateBox(20, 5, 20, 30)),
          PlateSlot(alphabet: _digits, box: PlateBox(50, 5, 20, 30)),
        ]
      : slots,
  mirrors: mirrors,
  background: background,
);

PlateSlot _slotAt(PlateBox box) => PlateSlot(alphabet: _digits, box: box);

PlateMirror _mirrorAt({
  int source = 0,
  PlateBox box = const PlateBox(20, 50, 20, 30),
  PlateAlphabet? alphabet,
}) =>
    PlateMirror(source: source, box: box, glyphHeight: 30, alphabet: alphabet);

void main() {
  test('asserts are enabled — the whole file depends on it', () {
    var enabled = false;
    assert(() {
      enabled = true;
      return true;
    }());
    expect(
      enabled,
      isTrue,
      reason: 'debugValidateSpec only checks anything with asserts on',
    );
  });

  test('a well-formed spec returns true', () {
    expect(debugValidateSpec(_spec()), isTrue);
  });

  group('slot geometry', () {
    test('a box extending past canvasWidth throws', () {
      final spec = _spec(slots: [_slotAt(const PlateBox(390, 5, 20, 30))]);
      expect(() => debugValidateSpec(spec), throwsAssertionError);
    });

    test('a box extending past canvasHeight throws', () {
      final spec = _spec(slots: [_slotAt(const PlateBox(20, 90, 20, 30))]);
      expect(() => debugValidateSpec(spec), throwsAssertionError);
    });

    test('a negative left throws', () {
      final spec = _spec(slots: [_slotAt(const PlateBox(-1, 5, 20, 30))]);
      expect(() => debugValidateSpec(spec), throwsAssertionError);
    });

    test('a negative top throws', () {
      final spec = _spec(slots: [_slotAt(const PlateBox(20, -1, 20, 30))]);
      expect(() => debugValidateSpec(spec), throwsAssertionError);
    });

    test('a box flush with the canvas edges is legal', () {
      final spec = _spec(slots: [_slotAt(const PlateBox(0, 0, 400, 100))]);
      expect(debugValidateSpec(spec), isTrue);
    });
  });

  group('mirrors', () {
    test('a well-placed mirror on a real slot is legal', () {
      expect(debugValidateSpec(_spec(mirrors: [_mirrorAt()])), isTrue);
    });

    test('a box outside the canvas throws', () {
      final spec = _spec(
        mirrors: [_mirrorAt(box: const PlateBox(390, 50, 20, 30))],
      );
      expect(() => debugValidateSpec(spec), throwsAssertionError);
    });

    test('a negative source throws', () {
      expect(
        () => debugValidateSpec(_spec(mirrors: [_mirrorAt(source: -1)])),
        throwsAssertionError,
      );
    });

    test('a source at or past slots.length throws', () {
      // _spec()'s default plate has two slots, so 2 is one past the end.
      expect(
        () => debugValidateSpec(_spec(mirrors: [_mirrorAt(source: 2)])),
        throwsAssertionError,
      );
    });
  });

  group('alphabet ids key content one-to-one', () {
    test('one id with two different character/glyph pairs throws', () {
      const a = PlateAlphabet(
        id: 'zz.dup',
        characters: ['0', '1'],
        input: AlphabetInput.typed,
        isNumeric: true,
      );
      const b = PlateAlphabet(
        id: 'zz.dup',
        characters: ['A', 'B'],
        input: AlphabetInput.typed,
        isNumeric: false,
      );
      final spec = _spec(
        slots: const [
          PlateSlot(alphabet: a, box: PlateBox(20, 5, 20, 30)),
          PlateSlot(alphabet: b, box: PlateBox(50, 5, 20, 30)),
        ],
      );
      expect(() => debugValidateSpec(spec), throwsAssertionError);
    });

    test('two distinct ids sharing one character/glyph pair throws', () {
      const a = PlateAlphabet(
        id: 'zz.a',
        characters: ['0', '1'],
        input: AlphabetInput.typed,
        isNumeric: true,
      );
      const b = PlateAlphabet(
        id: 'zz.b',
        characters: ['0', '1'],
        input: AlphabetInput.typed,
        isNumeric: true,
      );
      final spec = _spec(
        slots: const [
          PlateSlot(alphabet: a, box: PlateBox(20, 5, 20, 30)),
          PlateSlot(alphabet: b, box: PlateBox(50, 5, 20, 30)),
        ],
      );
      expect(() => debugValidateSpec(spec), throwsAssertionError);
    });

    test('same characters, different glyphs, different ids is legal', () {
      // The case a plate printing one value in two numeral systems needs.
      final spec = _spec(
        slots: const [
          PlateSlot(alphabet: _digits, box: PlateBox(20, 5, 20, 30)),
          PlateSlot(alphabet: _iranianDigits, box: PlateBox(50, 5, 20, 30)),
        ],
      );
      expect(debugValidateSpec(spec), isTrue);
    });

    test('the same alphabet used by many slots is legal', () {
      final spec = _spec(
        slots: const [
          PlateSlot(alphabet: _digits, box: PlateBox(20, 5, 20, 30)),
          PlateSlot(alphabet: _digits, box: PlateBox(50, 5, 20, 30)),
          PlateSlot(alphabet: _digits, box: PlateBox(80, 5, 20, 30)),
        ],
      );
      expect(debugValidateSpec(spec), isTrue);
    });

    test(
      'a mirror\'s alphabet is walked too — it renders on the same face',
      () {
        // A mirror alphabet colliding with a slot alphabet's content under a
        // different id is the same violation as two slots doing it.
        const clash = PlateAlphabet(
          id: 'zz.clash',
          characters: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
          input: AlphabetInput.typed,
          isNumeric: true,
        );
        final spec = _spec(mirrors: [_mirrorAt(alphabet: clash)]);
        expect(() => debugValidateSpec(spec), throwsAssertionError);
      },
    );

    test('a mirror rendering through a different numeral system is legal', () {
      final spec = _spec(mirrors: [_mirrorAt(alphabet: _iranianDigits)]);
      expect(debugValidateSpec(spec), isTrue);
    });
  });

  group('background sections', () {
    const strip = PlateSection.fill(PlateFill.panel);

    test('a left strip with a divider is well formed', () {
      final spec = _spec(
        background: const PlateSection.columns([
          PlatePart(strip, end: 40, divider: 3),
          PlatePart(PlateSection.plain),
        ]),
      );
      expect(debugValidateSpec(spec), isTrue);
      expect(spec.background.paintsPanel, isTrue);
      expect(PlateSection.plain.paintsPanel, isFalse);
    });

    test('an end past the parent throws', () {
      final spec = _spec(
        background: const PlateSection.columns([
          PlatePart(strip, end: 400),
          PlatePart(PlateSection.plain),
        ]),
      );
      expect(() => debugValidateSpec(spec), throwsAssertionError);
    });

    test('a nested end outside its own region throws', () {
      final spec = _spec(
        background: const PlateSection.rows([
          PlatePart(PlateSection.plain, end: 50),
          PlatePart(
            PlateSection.rows([
              PlatePart(strip, end: 40),
              PlatePart(PlateSection.plain),
            ]),
          ),
        ]),
      );
      expect(() => debugValidateSpec(spec), throwsAssertionError);
    });

    test('an end on the last part throws', () {
      final spec = _spec(
        background: const PlateSection.columns([
          PlatePart(strip, end: 40),
          PlatePart(PlateSection.plain, end: 400),
        ]),
      );
      expect(() => debugValidateSpec(spec), throwsAssertionError);
    });

    test('stripes with one stop between each pair are well formed', () {
      final spec = _spec(
        background: const PlateSection.fill(
          PlateFill.stripes(
            [
              PlateFill.field,
              PlateFill.color(Color(0xFFFFCC00)),
              PlateFill.panel,
            ],
            stops: [40, 70],
            angle: 0.1,
          ),
        ),
      );
      expect(debugValidateSpec(spec), isTrue);
      expect(spec.background.paintsPanel, isTrue);
    });

    test('stripes without a stop between each pair throw', () {
      final spec = _spec(
        background: const PlateSection.fill(
          PlateFill.stripes(
            [PlateFill.field, PlateFill.panel],
            stops: [40, 70],
          ),
        ),
      );
      expect(() => debugValidateSpec(spec), throwsAssertionError);
    });

    test('stripes with stops out of order throw', () {
      final spec = _spec(
        background: const PlateSection.fill(
          PlateFill.stripes(
            [PlateFill.field, PlateFill.panel, PlateFill.divider],
            stops: [70, 40],
          ),
        ),
      );
      expect(() => debugValidateSpec(spec), throwsAssertionError);
    });
  });
}
