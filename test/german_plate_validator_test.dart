import 'package:flutter_test/flutter_test.dart';
import 'package:plate_number/model/plate_spec.dart';
import 'package:plate_number/validators/german_plate_validator.dart';

void main() {
  group('GermanPlateValidator.validate table', () {
    final cases = <String, ({String d, String l, String s, bool valid})>{
      'valid DA/X/1953': (d: 'DA', l: 'X', s: '1953', valid: true),
      'forbidden letters SS': (d: 'DA', l: 'SS', s: '1953', valid: false),
      'forbidden number 88': (d: 'DA', l: 'X', s: '88', valid: false),
      'bad district 1A': (d: '1A', l: 'X', s: '1953', valid: false),
      'exceeds 8 chars': (d: 'ABC', l: 'AB', s: '12345', valid: false),
    };

    cases.forEach((name, c) {
      test(name, () {
        final result = GermanPlateValidator.validate(
          district: c.d,
          identifierLetters: c.l,
          identifierDigits: c.s,
        );
        expect(result.isValid, c.valid, reason: result.reason);
      });
    });
  });

  group('GermanPlateValidator.validateValues', () {
    test('empty letters group is treated as valid (in-progress plate)', () {
      final values = <String?>['D', 'A', null, '1', '9', '5', '3'];
      final result = GermanPlateValidator.validateValues(PlateSpecs.deCar, values);
      expect(result.isValid, isTrue);
    });

    test('reads district/letters/serial groups from spec and validates', () {
      final valid = <String?>['D', 'A', 'X', '1', '9', '5', '3'];
      expect(GermanPlateValidator.validateValues(PlateSpecs.deCar, valid).isValid, isTrue);

      final forbidden = <String?>['D', 'A', 'X', '8', '8', null, null];
      expect(GermanPlateValidator.validateValues(PlateSpecs.deCar, forbidden).isValid, isFalse);
    });
  });

  group('barredNextDigits', () {
    test("'8' bars '8' (completes 88)", () {
      expect(GermanPlateValidator.barredNextDigits('8'), {'8'});
    });

    test("'1' bars '8' and '4' (completes 18/14)", () {
      expect(GermanPlateValidator.barredNextDigits('1'), {'8', '4'});
    });
  });

  group('barredNextLetters', () {
    test("'S' bars 'S', 'A', and 'D' (completes SS/SA/SD)", () {
      expect(GermanPlateValidator.barredNextLetters('S'), {'S', 'A', 'D'});
    });
  });
}
