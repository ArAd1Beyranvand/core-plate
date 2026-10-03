import 'package:core_plate/core_plate.dart';

import 'india_alphabets.dart';

/// Judges any `IndiaPlates` value by the groups its spec has. Reports, never
/// throws, never bars a keystroke; quiet until every cell is filled, since
/// diplomatic numbers and temporary series may legitimately be short.
class IndiaValidator extends PlateValidator {
  const IndiaValidator();

  static const String reasonState = 'Not a state or union-territory code.';
  static const String reasonRto = 'RTO number 00 is not issued.';
  static const String reasonNumber = 'Number 0000 is not issued.';
  static const String reasonMonth = 'The month is not 01–12.';
  static const String reasonClass = 'Not an armed-forces vehicle class.';
  static const String reasonMission = 'Mission type is CD, CC or UN.';
  static const String reasonCategory = 'Trade category is A to J.';

  @override
  PlateValidation validate(PlateEntry entry) {
    if (entry.values.length < entry.spec.slotCount ||
        entry.values.any((v) => v == null || v.isEmpty)) {
      return const PlateValidation.valid();
    }
    final keys = <String?>{
      for (final g in entry.spec.effectiveTextGroups) g.key,
    };
    String g(String key) => entry.group(key);

    if (keys.contains('state') &&
        !IndiaAlphabets.stateNames.containsKey(g('state'))) {
      return const PlateValidation.invalid(reasonState);
    }
    if (keys.contains('rto') && g('rto') == '00') {
      return const PlateValidation.invalid(reasonRto);
    }
    if (keys.contains('number') && int.tryParse(g('number')) == 0) {
      return const PlateValidation.invalid(reasonNumber);
    }
    if (keys.contains('date')) {
      final month = int.tryParse(g('date').substring(0, 2)) ?? 0;
      if (month < 1 || month > 12) {
        return const PlateValidation.invalid(reasonMonth);
      }
    }
    if (keys.contains('class') &&
        !IndiaAlphabets.militaryClasses.containsKey(g('class'))) {
      return const PlateValidation.invalid(reasonClass);
    }
    if (keys.contains('type') &&
        !IndiaAlphabets.missions.containsKey(g('type'))) {
      return const PlateValidation.invalid(reasonMission);
    }
    if (keys.contains('category') &&
        !IndiaAlphabets.tradeCategories.containsKey(g('category'))) {
      return const PlateValidation.invalid(reasonCategory);
    }
    return const PlateValidation.valid();
  }
}
