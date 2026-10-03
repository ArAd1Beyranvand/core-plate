import 'dart:math';

import 'package:core_plate/core_plate.dart';

/// Generates plausible values for fixtures and demos. Pure Dart.
///
/// Fills every slot of any `BoliviaPlates` spec from its own alphabet. A
/// four-digit PTA number is drawn below 6500, where the article puts the
/// series in December 2024.
abstract final class BoliviaSerialGenerator {
  static List<String?> generate(PlateSpec spec, {Random? random}) {
    final Random rnd = random ?? Random();
    final List<String?> values = List<String?>.filled(spec.slots.length, null);
    for (int i = 0; i < spec.slots.length; i++) {
      final List<String> chars = spec.slots[i].alphabet.characters;
      values[i] = chars[rnd.nextInt(chars.length)];
    }
    final List<int> number = spec.indicesOfGroup('number');
    if (spec.id.startsWith('bo.standard') && number.length == 4) {
      final String n = rnd.nextInt(6500).toString().padLeft(4, '0');
      for (int i = 0; i < 4; i++) {
        values[number[i]] = n[i];
      }
    }
    return values;
  }
}
