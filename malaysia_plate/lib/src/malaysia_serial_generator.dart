import 'dart:math';

import 'package:plate_core/plate_core.dart';

/// Generates plausible values for fixtures and demos. Pure Dart.
///
/// Fills the `prefix`, `number` and `suffix` groups of a Malaysian spec.
/// [prefix] fixes the leading letters (`'W'`, `'SAA'`); the remainder of the
/// group is drawn from the issued letters (no I, O or Z). Numbers have no
/// leading zero.
abstract final class MalaysiaSerialGenerator {
  static const String _issued = 'ABCDEFGHJKLMNPQRSTUVWXY';

  static List<String?> generate(
    PlateSpec spec, {
    Random? random,
    String prefix = '',
  }) {
    final Random rnd = random ?? Random();
    final List<String?> values = List<String?>.filled(spec.slots.length, null);
    final List<int> prefixSlots = _require(spec, 'prefix');
    final List<int> numberSlots = _require(spec, 'number');
    for (int i = 0; i < prefixSlots.length; i++) {
      values[prefixSlots[i]] = i < prefix.length
          ? prefix[i]
          : _issued[rnd.nextInt(_issued.length)];
    }
    for (int i = 0; i < numberSlots.length; i++) {
      values[numberSlots[i]] = (i == 0 ? 1 + rnd.nextInt(9) : rnd.nextInt(10))
          .toString();
    }
    for (final int i in spec.indicesOfGroup('suffix')) {
      values[i] = _issued[rnd.nextInt(_issued.length)];
    }
    return values;
  }
}

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
