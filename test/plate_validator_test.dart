import 'package:plate_core/core_plate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _country = PlateCountry(
  code: 'zz',
  captionLines: ['ZZ'],
  panelColor: Color(0xFF003399),
  panelTextColor: Color(0xFFFFFFFF),
);
const _panel = PlatePanel(box: PlateBox(0, 0, 10, 40));

/// A spec with one digit slot per key in [keys], one single-slot group per key.
PlateSpec _spec(List<String> keys) => PlateSpec(
  id: 'stub-${keys.join()}',
  country: _country,
  canvasWidth: 400,
  canvasHeight: 100,
  panel: _panel,
  slots: [
    for (var i = 0; i < keys.length; i++)
      PlateSlot(
        alphabet: PlateAlphabet.latinDigits,
        box: PlateBox(20 + i * 25.0, 5, 20, 30),
      ),
  ],
  textGroups: [
    for (var i = 0; i < keys.length; i++) PlateTextGroup([i], key: keys[i]),
  ],
);

class _StubGated extends GatedPlateValidator {
  const _StubGated(this._gate);
  final String _gate;

  static int judgeCalls = 0;

  @override
  String get gateGroup => _gate;

  @override
  PlateValidation judge(PlateEntry entry) {
    judgeCalls++;
    return const PlateValidation.invalid('judged');
  }
}

void main() {
  group('isDigits', () {
    test('true for ASCII digit runs', () {
      expect(isDigits('0'), isTrue);
      expect(isDigits('0123456789'), isTrue);
    });

    test('false for empty, letters, signs, spaces, iranian glyphs', () {
      expect(isDigits(''), isFalse);
      expect(isDigits('1a'), isFalse);
      expect(isDigits('+9'), isFalse);
      expect(isDigits(' 9'), isFalse);
      expect(isDigits('١٢٣'), isFalse);
    });
  });

  group('isDigitsOfLength', () {
    test('exact length at the boundaries', () {
      expect(isDigitsOfLength('12', 2), isTrue);
      expect(isDigitsOfLength('1', 2), isFalse);
      expect(isDigitsOfLength('123', 2), isFalse);
      expect(isDigitsOfLength('', 0), isFalse); // isDigits('') is false
      expect(isDigitsOfLength('1a', 2), isFalse);
    });
  });

  group('GatedPlateValidator', () {
    setUp(() => _StubGated.judgeCalls = 0);

    test('judge is not called while the gate group is empty', () {
      final spec = _spec(['a', 'b']);
      final entry = PlateEntry(spec: spec, values: ['1', null]);
      final v = const _StubGated('b').validate(entry);
      expect(v.isValid, isTrue);
      expect(_StubGated.judgeCalls, 0);
    });

    test('judge is called once the gate group is non-empty', () {
      final spec = _spec(['a', 'b']);
      final entry = PlateEntry(spec: spec, values: ['1', '2']);
      final v = const _StubGated('b').validate(entry);
      expect(v, const PlateValidation.invalid('judged'));
      expect(_StubGated.judgeCalls, 1);
    });

    test(
      'a gate key no group carries leaves the validator permanently quiet',
      () {
        final spec = _spec(['a', 'b']);
        final entry = PlateEntry(spec: spec, values: ['1', '2']);
        final v = const _StubGated('nonesuch').validate(entry);
        expect(v.isValid, isTrue);
        expect(_StubGated.judgeCalls, 0);
      },
    );
  });

  group('PlateValidation equality', () {
    test('equal over reason', () {
      expect(
        const PlateValidation.invalid('x'),
        const PlateValidation.invalid('x'),
      );
      expect(
        const PlateValidation.invalid('x') ==
            const PlateValidation.invalid('y'),
        isFalse,
      );
      expect(
        const PlateValidation.valid() == const PlateValidation.valid(),
        isTrue,
      );
    });
  });
}
