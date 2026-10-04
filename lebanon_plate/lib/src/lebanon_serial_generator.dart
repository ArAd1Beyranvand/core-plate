import 'dart:math';

import 'package:plate_core/core_plate.dart';

import 'lebanon_letters.dart';
import 'lebanon_usage.dart';
import 'lebanon_validators.dart';

/// Generates valid plate values for fixtures and tests. Pure Dart, no widget.
/// Returns a `List<String?>` ready for `PlateController` or `ShowPlate`.
/// Pass [random] for repeatability: `generate(spec, random: Random(7))`.
abstract final class LebanonSerialGenerator {
  /// A value for [spec]: letter and number at the spec's text group indices.
  /// Returns a list `spec.slots.length` long, fully filled.
  ///
  /// [letter] or [usage] fixes the letter; both is an error. [letter] omitted
  /// draws from currently-issued letters (K excluded). MP numbers are 1..128;
  /// others have uniform width, non-zero leading digit.
  ///
  /// Throws if spec has no `letter` and `serial` groups (not a Lebanon spec).
  static List<String?> generate(
    PlateSpec spec, {
    Random? random,
    LebanonLetter? letter,
    LebanonUsage? usage,
  }) {
    if (letter != null && usage?.letter != null) {
      throw ArgumentError(
        'Pass letter: or usage:, not both — they would disagree.',
      );
    }
    final Random rnd = random ?? Random();
    final List<String?> values = List<String?>.filled(spec.slots.length, null);

    final List<int> letterSlots = _require(spec, 'letter');
    final List<int> serialSlots = _require(spec, 'serial');

    final LebanonLetter chosen =
        letter ??
        (usage?.letter != null
            ? LebanonLetter.fromCharacter(usage!.letter!)!
            : _issued[rnd.nextInt(_issued.length)]);

    for (int i = 0; i < letterSlots.length; i++) {
      values[letterSlots[i]] = i == 0 ? chosen.character : '';
    }

    final String serial = chosen == LebanonLetter.mp
        ? (1 + rnd.nextInt(LebanonValidator.maxParliamentNumber))
              .toString()
              .padLeft(serialSlots.length.clamp(1, 3), '0')
        : _number(serialSlots.length, rnd);

    for (int i = 0; i < serialSlots.length; i++) {
      values[serialSlots[i]] = i < serial.length ? serial[i] : '';
    }

    return values;
  }

  static List<List<String?>> generateMany(
    PlateSpec spec,
    int count, {
    Random? random,
    LebanonLetter? letter,
    LebanonUsage? usage,
  }) {
    final Random rnd = random ?? Random();
    return List<List<String?>>.generate(
      count,
      (_) => generate(spec, random: rnd, letter: letter, usage: usage),
      growable: false,
    );
  }

  static final List<LebanonLetter> _issued = LebanonLetter.values
      .where((LebanonLetter l) => l.inUse)
      .toList(growable: false);

  static String _number(int length, Random rnd) {
    final StringBuffer buffer = StringBuffer((1 + rnd.nextInt(9)).toString());
    for (int i = 1; i < length; i++) {
      buffer.write(rnd.nextInt(10));
    }
    return buffer.toString();
  }
}

/// Slot indices of [spec]'s text group [key]. Throws if not found.
List<int> _require(PlateSpec spec, String key) {
  final List<int> indices = spec.indicesOfGroup(key);
  if (indices.isEmpty) {
    throw ArgumentError.value(
      spec.id,
      'spec',
      'has no text group named "$key"',
    );
  }
  return indices;
}
