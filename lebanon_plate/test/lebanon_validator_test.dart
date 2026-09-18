import 'package:core_plate/core_plate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebanon_plate/lebanon_plate.dart';

void main() {
  group('LebanonValidator.validateFields', () {
    test('accepts an ordinary town plate', () {
      expect(LebanonValidator.validateFields(letter: 'B', serial: '123456').isValid, isTrue);
      expect(LebanonValidator.validateFields(letter: 'T', serial: '1').isValid, isTrue);
    });

    test('accepts a letter that is no longer issued', () {
      // K (Baalbek) is out of service, and K plates are on the road.
      expect(LebanonValidator.validateFields(letter: 'K', serial: '123456').isValid, isTrue);
    });

    test('accepts a leading zero, because nothing establishes the padding rule', () {
      expect(LebanonValidator.validateFields(letter: 'B', serial: '000123').isValid, isTrue);
    });

    test('rejects a missing letter', () {
      final PlateValidation v = LebanonValidator.validateFields(letter: '', serial: '123456');
      expect(v.isValid, isFalse);
      expect(v.reason, LebanonValidator.reasonLetterMissing);
    });

    test('rejects a letter Lebanon does not issue', () {
      final PlateValidation v = LebanonValidator.validateFields(letter: 'Q', serial: '123456');
      expect(v.reason, LebanonValidator.reasonLetterUnknown);
    });

    test('rejects a serial that is empty or too long', () {
      expect(LebanonValidator.validateFields(letter: 'B', serial: '').reason, LebanonValidator.reasonSerialLength);
      expect(
        LebanonValidator.validateFields(letter: 'B', serial: '1234567').reason,
        LebanonValidator.reasonSerialLength,
      );
    });

    test('rejects a non-numeric serial', () {
      expect(
        LebanonValidator.validateFields(letter: 'B', serial: '12A456').reason,
        LebanonValidator.reasonSerialNotNumeric,
      );
    });

    test('holds a parliament plate to 1..128 — the one documented range', () {
      expect(LebanonValidator.validateFields(letter: 'MP', serial: '1').isValid, isTrue);
      expect(LebanonValidator.validateFields(letter: 'MP', serial: '128').isValid, isTrue);
      expect(LebanonValidator.validateFields(letter: 'MP', serial: '0').reason, LebanonValidator.reasonParliamentRange);
      expect(
        LebanonValidator.validateFields(letter: 'MP', serial: '129').reason,
        LebanonValidator.reasonParliamentRange,
      );
      // The same number on any other letter is fine.
      expect(LebanonValidator.validateFields(letter: 'B', serial: '129').isValid, isTrue);
    });
  });

  group('gating', () {
    const LebanonValidator validator = LebanonValidator();

    test('stays quiet until the serial has something in it', () {
      final PlateSpec spec = LebanonPlates.oneLine;
      final List<String?> empty = List<String?>.filled(spec.slots.length, null);
      expect(validator.validate(PlateEntry(spec: spec, values: empty)).isValid, isTrue);

      // A letter alone is still not judged.
      final List<String?> letterOnly = List<String?>.from(empty)..[0] = 'Q';
      expect(validator.validate(PlateEntry(spec: spec, values: letterOnly)).isValid, isTrue);

      // One digit opens the gate, and the bad letter is reported.
      final List<String?> withDigit = List<String?>.from(letterOnly)..[1] = '1';
      expect(validator.validate(PlateEntry(spec: spec, values: withDigit)).isValid, isFalse);
    });

    test('judges a full plate through the spec groups', () {
      final PlateSpec spec = LebanonPlates.twoLine;
      final List<String?> values = <String?>['B', '1', '2', '3', '4', '5', '6'];
      expect(validator.validate(PlateEntry(spec: spec, values: values)).isValid, isTrue);
    });
  });
}
