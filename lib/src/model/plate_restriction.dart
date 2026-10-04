import 'package:flutter/foundation.dart';

/// A value a named register may never hold, and the error to show when
/// something tries to put it there.
///
/// The one place this package bars input. A [PlateValidator] judges and never
/// refuses; a restriction refuses, in every layer that writes a value: the
/// controller drops the write and publishes it as `PlateController.rejection`,
/// the input machine does not advance past it, validators report [reason]
/// before anything else, and the canvas paints [reason] over the plate. It is
/// for values a country package must guarantee no host can ever store — not
/// for ordinary validity, which stays advisory.
///
/// Matched against the whole register: a restriction on `'09'` lets `'0'`
/// through and refuses the `'9'` that would complete it, whichever slot is
/// typed last.
@immutable
class PlateRestriction {
  const PlateRestriction({
    required this.group,
    required this.values,
    required this.reason,
  });

  /// The [PlateTextGroup.key] of the register this restriction watches.
  final String group;

  /// Register values, in canonical (storage) form, that are refused.
  final List<String> values;

  /// The error shown wherever the refusal surfaces.
  final String reason;

  /// Whether [groupValue] is one of the refused [values].
  bool matches(String groupValue) => values.contains(groupValue);
}

/// Thrown by `PlateSpec.checkRestrictions` for a value list that breaks a
/// [PlateRestriction]. Its [toString] is the restriction's reason, so an
/// uncaught one says what the plate says.
class PlateRestrictionException implements Exception {
  const PlateRestrictionException(this.restriction);

  final PlateRestriction restriction;

  @override
  String toString() => restriction.reason;
}
