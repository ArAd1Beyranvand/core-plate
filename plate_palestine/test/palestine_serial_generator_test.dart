import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:plate_palestine/plate_palestine.dart';

void main() {
  const iterations = 10000;

  test('10000 generated modern West Bank serials all validate', () {
    final rng = Random(1);
    for (var i = 0; i < iterations; i++) {
      final values = PSSerialGenerator.modernWestBank(rng);
      final v = PSWestBankModernValidator.validateFields(
        region: values[0]!,
        serial: values.sublist(1, 5).join(),
        governorate: values[5]!,
      );
      expect(v.isValid, isTrue, reason: '$values: ${v.reason}');
    }
  });

  test('10000 generated legacy West Bank serials all validate', () {
    final rng = Random(2);
    for (var i = 0; i < iterations; i++) {
      final values = PSSerialGenerator.legacyWestBank(rng);
      final v = PSWestBankLegacyValidator.validateFields(
        district: values[0]!,
        serial: values.sublist(1, 5).join(),
        usage: values.sublist(5, 7).join(),
      );
      expect(v.isValid, isTrue, reason: '$values: ${v.reason}');
    }
  });

  test('10000 generated Gaza serials all validate', () {
    final rng = Random(3);
    for (var i = 0; i < iterations; i++) {
      final values = PSSerialGenerator.gaza(rng);
      final v = PSGazaValidator.validateFields(
        prefix: values[0]!,
        serial: values.sublist(1, 5).join(),
        usage: values.sublist(5, 7).join(),
      );
      expect(v.isValid, isTrue, reason: '$values: ${v.reason}');
    }
  });

  test('the generator never emits I, O or a reserved Gaza letter', () {
    final rng = Random(4);
    for (var i = 0; i < iterations; i++) {
      final letter = PSSerialGenerator.modernWestBank(rng)[5];
      expect(PSGovernorate.confusableLetters, isNot(contains(letter)));
      expect(PSGovernorate.reservedGazaLetters, isNot(contains(letter)));
    }
  });

  test('the generator never emits a Gaza prefix other than 3', () {
    final rng = Random(5);
    for (var i = 0; i < iterations; i++) {
      expect(PSSerialGenerator.gaza(rng)[0], '3');
    }
  });

  test('toFilename concatenates with no separator', () {
    expect(
      PSSerialGenerator.toFilename(['1', '0', '2', '3', '4', 'H']),
      '1' '0234H',
    );
  });
}
