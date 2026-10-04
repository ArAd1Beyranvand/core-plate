import 'dart:math';

import 'package:plate_core/core_plate.dart';

/// Generates plausible values for fixtures and demos. Pure Dart.
abstract final class NigerSerialGenerator {
  static List<String?> generate(PlateSpec spec, {Random? random}) {
    final Random rnd = random ?? Random();
    return <String?>[
      for (final PlateSlot slot in spec.slots)
        slot.alphabet.characters[rnd.nextInt(slot.alphabet.characters.length)],
    ];
  }
}
