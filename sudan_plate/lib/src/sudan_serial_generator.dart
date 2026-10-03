import 'dart:math';

import 'package:core_plate/core_plate.dart';

/// Generates plausible values for fixtures and demos. Pure Dart.
abstract final class SudanSerialGenerator {
  static List<String?> generate(PlateSpec spec, {Random? random}) {
    final Random rnd = random ?? Random();
    return <String?>[
      for (final PlateSlot slot in spec.slots)
        slot.alphabet.characters[rnd.nextInt(slot.alphabet.characters.length)],
    ];
  }
}
