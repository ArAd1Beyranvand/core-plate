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

import '../validators/plate_validator.dart';

/// Nationwide-forbidden letter pairs (Nazi-organisation abbreviations) plus
/// widely-documented state-level additions and generically-offensive pairs.
///
/// These consts are the single source of truth for this data — the old
/// `docs/forbidden.json`, which duplicated them by hand, has been removed.
const Set<String> _forbiddenLetterPairs = {
  'SS', 'SA', 'KZ', 'HJ', 'NS',
  'AH', 'HH', 'SD', 'IS',
};

/// Digit strings commonly barred nationwide/regionally for the same reason.
/// Source of truth, as with [_forbiddenLetterPairs].
const Set<String> _forbiddenNumbers = {
  '88', '18', '14',
};

/// Retained for one release so consumers of the old result type keep
/// compiling. [GermanPlateValidationResult] is now just [PlateValidation].
typedef GermanPlateValidationResult = PlateValidation;

/// Validates a German car-plate district code + identifier pair.
///
/// Answers a question — is this plate valid? — and never prevents input. The
/// per-keystroke `barredNext*` helpers this class used to expose are removed;
/// a validator no longer bars keys (see docs/split/PLAN.md §1).
class GermanPlateValidator extends PlateValidator {
  const GermanPlateValidator();

  static final RegExp _districtPattern = RegExp(r'^[A-ZÄÖÜ]{1,3}$');
  static final RegExp _identifierLetterPattern = RegExp(r'^[A-Z]{1,2}$');
  static final RegExp _identifierDigitPattern = RegExp(r'^[0-9]{1,4}$');

  /// Reads the district/letters/serial groups off [entry] by key and
  /// validates them. Returns [PlateValidation.valid] while the 'letters' group
  /// is still blank, mirroring the rule that an in-progress plate shouldn't be
  /// flagged before it's filled in — with nothing barring input, the red state
  /// is the only feedback, and a plate that flashes red on its first character
  /// is worse than no validation.
  @override
  PlateValidation validate(PlateEntry entry) {
    final letters = entry.group('letters');
    if (letters.isEmpty) return const PlateValidation.valid();

    return validateFields(
      district: entry.group('district'),
      identifierLetters: letters,
      identifierDigits: entry.group('serial'),
    );
  }

  /// The country rule without a spec: pass the plate's own slot values in.
  ///
  /// [district] is the `Unterscheidungszeichen` (1-3 letters, e.g. "DA").
  /// [identifierLetters] is the 1-2 letter block of the `Erkennungsnummer`
  /// (e.g. "X" or "AB"). [identifierDigits] is the 1-4 digit serial (e.g.
  /// "1953"). Named [validateFields] rather than overloading the instance
  /// [validate]; the instance method delegates to it.
  static PlateValidation validateFields({
    required String district,
    required String identifierLetters,
    required String identifierDigits,
  }) {
    final d = district.toUpperCase();
    final letters = identifierLetters.toUpperCase();
    final digits = identifierDigits;

    if (!_districtPattern.hasMatch(d)) {
      return const PlateValidation.invalid('District code must be 1-3 letters.');
    }

    if (!_identifierLetterPattern.hasMatch(letters)) {
      return const PlateValidation.invalid(
        'Identifier letters must be 1-2 letters.',
      );
    }

    if (digits.isNotEmpty && !_identifierDigitPattern.hasMatch(digits)) {
      return const PlateValidation.invalid(
        'Identifier digits must be 1-4 digits.',
      );
    }

    if (d.length + letters.length + digits.length > 8) {
      return const PlateValidation.invalid(
        'Plate exceeds the 8-character maximum.',
      );
    }

    if (_forbiddenLetterPairs.contains(letters)) {
      return PlateValidation.invalid('"$letters" is a forbidden combination.');
    }

    if (digits.isNotEmpty && _forbiddenNumbers.contains(digits)) {
      return PlateValidation.invalid('"$digits" is a forbidden combination.');
    }

    return const PlateValidation.valid();
  }
}
