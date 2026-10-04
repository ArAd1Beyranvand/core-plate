import 'dart:math';

import 'package:plate_core/core_plate.dart';

import 'yemen_governorates.dart';

/// Makes plate values that satisfy `YemenUnifiedValidator`. For demos, fixtures, goldens.
/// Pure Dart, no Flutter. Pass a seeded [Random] for repeatable sequences.
/// Well-formed but not registered. Output drops into [PlateController] or [ShowPlate].
abstract final class YemenUnifiedSerialGenerator {
  /// A value for [spec] — vehicle number and side code, positioned by spec's text groups.
  /// Throws [ArgumentError] if [spec] has no `number` and `sideCode` groups.
  /// Side code is two uniform digits (not constrained to 1..22; see TODO in validator).
  static List<String?> generate(PlateSpec spec, {Random? random}) {
    final Random rnd = random ?? Random();
    final List<String?> values = List<String?>.filled(spec.slots.length, null);

    final List<int> number = _require(spec, 'number');
    final List<int> sideCode = _require(spec, 'sideCode');

    for (final int i in number) {
      values[i] = rnd.nextInt(10).toString();
    }
    for (final int i in sideCode) {
      values[i] = rnd.nextInt(10).toString();
    }

    return values;
  }

  /// [count] values for [spec], each one independently generated.
  static List<List<String?>> generateMany(
    PlateSpec spec,
    int count, {
    Random? random,
  }) {
    final Random rnd = random ?? Random();
    return List<List<String?>>.generate(
      count,
      (_) => generate(spec, random: rnd),
      growable: false,
    );
  }
}

/// Makes plate values that satisfy `YemenNorthernValidator`.
/// Honours both constraints: governorate code 1..22, serial never zero-padded.
/// See [YemenUnifiedSerialGenerator] for the general contract.
abstract final class YemenNorthernSerialGenerator {
  /// A value for [spec] — governorate code and serial, positioned by spec's text groups.
  /// Governorate drawn uniformly from the range the spec can hold (1..22 for two cells, 1..9 for one).
  /// Two-cell codes zero-padded (plate's format); serials not (plate's format).
  /// Throws [ArgumentError] if [spec] has no `governorate` and `serial` groups.
  static List<String?> generate(PlateSpec spec, {Random? random}) {
    final Random rnd = random ?? Random();
    final List<String?> values = List<String?>.filled(spec.slots.length, null);

    final List<int> governorate = _require(spec, 'governorate');
    final List<int> serial = _require(spec, 'serial');

    final int maxCode = governorate.length >= 2 ? YemenGovernorate.maxCode : 9;
    final String code =
        (YemenGovernorate.minCode +
                rnd.nextInt(maxCode - YemenGovernorate.minCode + 1))
            .toString()
            .padLeft(governorate.length, '0');
    for (int i = 0; i < governorate.length; i++) {
      values[governorate[i]] = code[i];
    }

    for (int i = 0; i < serial.length; i++) {
      // No leading zero: the first digit runs 1..9.
      values[serial[i]] = (i == 0 ? 1 + rnd.nextInt(9) : rnd.nextInt(10))
          .toString();
    }

    return values;
  }

  /// [count] values for [spec], each one independently generated.
  static List<List<String?>> generateMany(
    PlateSpec spec,
    int count, {
    Random? random,
  }) {
    final Random rnd = random ?? Random();
    return List<List<String?>>.generate(
      count,
      (_) => generate(spec, random: rnd),
      growable: false,
    );
  }
}

// Slot indices of spec's text group named key. Throws if group not found.
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
