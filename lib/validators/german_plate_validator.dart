/// Validates the identifier letter block of a German (Kennzeichen) car plate
/// against the nationwide and commonly-documented forbidden combinations
/// (FZV §8: identification marks must not offend common decency).
///
/// This is a small, demo-scoped validator -- it checks format and the
/// letter/number combinations most consistently cited across sources. It is
/// NOT an exhaustive reproduction of every municipality's local ban list;
/// those are published separately by each Zulassungsbehörde and change over
/// time. Treat a `true` result as "not obviously forbidden", not as an
/// official registration guarantee.
library;

import '../model/plate_spec.dart';

/// Nationwide-forbidden letter pairs (Nazi-organisation abbreviations) plus
/// widely-documented state-level additions and generically-offensive pairs.
const Set<String> _forbiddenLetterPairs = {
  'SS', 'SA', 'KZ', 'HJ', 'NS',
  'AH', 'HH', 'SD', 'IS',
};

/// Digit strings commonly barred nationwide/regionally for the same reason.
const Set<String> _forbiddenNumbers = {
  '88', '18', '14',
};

class GermanPlateValidationResult {
  const GermanPlateValidationResult({
    required this.isValid,
    this.reason,
  });

  final bool isValid;

  /// Human-readable reason when [isValid] is false; null when valid.
  final String? reason;

  static const valid = GermanPlateValidationResult(isValid: true);
}

/// Validates a German car-plate district code + identifier pair.
///
/// [district] is the `Unterscheidungszeichen` (1-3 letters, e.g. "DA").
/// [identifierLetters] is the 1-2 letter block of the `Erkennungsnummer`
/// (e.g. "X" or "AB"). [identifierDigits] is the 1-4 digit serial (e.g.
/// "1953"). Pass the plate's own slot values in; this function does not know
/// about `PlateSpec` or `PlateSlot` and has no widget dependency.
class GermanPlateValidator {
  const GermanPlateValidator._();

  static final RegExp _districtPattern = RegExp(r'^[A-ZÄÖÜ]{1,3}$');
  static final RegExp _identifierLetterPattern = RegExp(r'^[A-Z]{1,2}$');
  static final RegExp _identifierDigitPattern = RegExp(r'^[0-9]{1,4}$');

  /// Reads the district/letters/serial groups off [spec] by key and
  /// validates them. Returns [GermanPlateValidationResult.valid] while the
  /// 'letters' group is still blank, mirroring the showcase's rule that an
  /// in-progress plate shouldn't be flagged before it's filled in — hosts
  /// need no pre-check before calling this.
  static GermanPlateValidationResult validateValues(
    PlateSpec spec,
    List<String?> values,
  ) {
    final letters = spec.valueOfGroup('letters', values);
    if (letters.isEmpty) return GermanPlateValidationResult.valid;

    return validate(
      district: spec.valueOfGroup('district', values),
      identifierLetters: letters,
      identifierDigits: spec.valueOfGroup('serial', values),
    );
  }

  static GermanPlateValidationResult validate({
    required String district,
    required String identifierLetters,
    required String identifierDigits,
  }) {
    final d = district.toUpperCase();
    final letters = identifierLetters.toUpperCase();
    final digits = identifierDigits;

    if (!_districtPattern.hasMatch(d)) {
      return const GermanPlateValidationResult(
        isValid: false,
        reason: 'District code must be 1-3 letters.',
      );
    }

    if (!_identifierLetterPattern.hasMatch(letters)) {
      return const GermanPlateValidationResult(
        isValid: false,
        reason: 'Identifier letters must be 1-2 letters.',
      );
    }

    if (digits.isNotEmpty && !_identifierDigitPattern.hasMatch(digits)) {
      return const GermanPlateValidationResult(
        isValid: false,
        reason: 'Identifier digits must be 1-4 digits.',
      );
    }

    if (d.length + letters.length + digits.length > 8) {
      return const GermanPlateValidationResult(
        isValid: false,
        reason: 'Plate exceeds the 8-character maximum.',
      );
    }

    if (_forbiddenLetterPairs.contains(letters)) {
      return GermanPlateValidationResult(
        isValid: false,
        reason: '"$letters" is a forbidden combination.',
      );
    }

    if (digits.isNotEmpty && _forbiddenNumbers.contains(digits)) {
      return GermanPlateValidationResult(
        isValid: false,
        reason: '"$digits" is a forbidden combination.',
      );
    }

    return GermanPlateValidationResult.valid;
  }

  /// Digits that would complete a forbidden number if typed next after
  /// [serialSoFar].
  ///
  /// For each forbidden number in [_forbiddenNumbers], if it starts with
  /// [serialSoFar] and is exactly one character longer, the next character
  /// of that forbidden number is barred. Lets an on-screen keypad grey out
  /// or block the keys that would COMPLETE a forbidden combination, rather
  /// than only rejecting after the fact.
  static Set<String> barredNextDigits(String serialSoFar) {
    return {
      for (final n in _forbiddenNumbers)
        if (n.startsWith(serialSoFar) && n.length == serialSoFar.length + 1)
          n[serialSoFar.length],
    };
  }

  /// Letters that would complete a forbidden letter pair if typed next
  /// after [lettersSoFar].
  ///
  /// For each forbidden pair in [_forbiddenLetterPairs], if it starts with
  /// [lettersSoFar] and is exactly one character longer, the next character
  /// of that forbidden pair is barred. Lets an on-screen keypad grey out
  /// or block the keys that would COMPLETE a forbidden combination, rather
  /// than only rejecting after the fact.
  static Set<String> barredNextLetters(String lettersSoFar) {
    return {
      for (final n in _forbiddenLetterPairs)
        if (n.startsWith(lettersSoFar) && n.length == lettersSoFar.length + 1)
          n[lettersSoFar.length],
    };
  }
}
