import 'package:flutter_test/flutter_test.dart';
import 'package:plate_number/model/plate_alphabet.dart';

void main() {
  group('PlateAlphabet.latinDigits', () {
    test('accepts digits, rejects others', () {
      expect(PlateAlphabet.latinDigits.accepts('5'), isTrue);
      expect(PlateAlphabet.latinDigits.accepts('A'), isFalse);
      expect(PlateAlphabet.latinDigits.accepts(''), isFalse);
    });

    test('renders digits unchanged (no glyph mapping)', () {
      expect(PlateAlphabet.latinDigits.render('5'), '5');
    });

    test('isNumeric is true', () {
      expect(PlateAlphabet.latinDigits.isNumeric, isTrue);
    });
  });

  group('PlateAlphabet.persianDigits', () {
    test('accepts ASCII digit storage form', () {
      expect(PlateAlphabet.persianDigits.accepts('5'), isTrue);
      expect(PlateAlphabet.persianDigits.accepts('۵'), isFalse);
    });

    test('renders to Persian glyphs', () {
      expect(PlateAlphabet.persianDigits.render('0'), '۰');
      expect(PlateAlphabet.persianDigits.render('9'), '۹');
    });

    test('falls back to storage form for unmapped values', () {
      expect(PlateAlphabet.persianDigits.render('x'), 'x');
    });

    test('isNumeric is true', () {
      expect(PlateAlphabet.persianDigits.isNumeric, isTrue);
    });
  });

  group('PlateAlphabet.persianPlateLetters', () {
    test('accepts a known letter, rejects a digit', () {
      expect(PlateAlphabet.persianPlateLetters.accepts('ب'), isTrue);
      expect(PlateAlphabet.persianPlateLetters.accepts('5'), isFalse);
    });

    test('renders unchanged (no glyph mapping)', () {
      expect(PlateAlphabet.persianPlateLetters.render('ب'), 'ب');
    });

    test('is chosen input, not numeric', () {
      expect(PlateAlphabet.persianPlateLetters.input, AlphabetInput.chosen);
      expect(PlateAlphabet.persianPlateLetters.isNumeric, isFalse);
    });
  });

  group('PlateAlphabet.latinUppercase', () {
    test('accepts letters, rejects lowercase and digits', () {
      expect(PlateAlphabet.latinUppercase.accepts('A'), isTrue);
      expect(PlateAlphabet.latinUppercase.accepts('a'), isFalse);
      expect(PlateAlphabet.latinUppercase.accepts('1'), isFalse);
    });

    test('is not numeric', () {
      expect(PlateAlphabet.latinUppercase.isNumeric, isFalse);
    });
  });
}
