import 'dart:math';

import 'package:core_plate/core_plate.dart';

/// Generates plausible values for fixtures and demos. Pure Dart.
///
/// Fills every slot of any `ColombiaPlates` spec from its own alphabet; a
/// series' fixed letters come out right because their cells hold only that
/// letter.
abstract final class ColombiaSerialGenerator {
  static List<String?> generate(PlateSpec spec, {Random? random}) {
    final Random rnd = random ?? Random();
    return <String?>[
      for (final PlateSlot slot in spec.slots)
        slot.alphabet.characters[rnd.nextInt(slot.alphabet.characters.length)],
    ];
  }
}
