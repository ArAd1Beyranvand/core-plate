import 'package:flutter/foundation.dart';

import '../model/plate_spec.dart';

/// The verdict on a plate. [reason] is developer- or user-facing text
/// explaining an invalid plate; null when valid.
@immutable
class PlateValidation {
  const PlateValidation.valid() : reason = null;
  const PlateValidation.invalid(String this.reason);

  final String? reason;

  bool get isValid => reason == null;

  /// Equality over [reason] so listeners rebuild on verdict changes, not on
  /// every committed value that keeps the verdict the same.
  @override
  bool operator ==(Object other) =>
      other is PlateValidation && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}

/// Everything a validator needs about a plate as it stands.
@immutable
class PlateEntry {
  const PlateEntry({
    required this.spec,
    required this.values,
    this.activeIndex,
  });

  final PlateSpec spec;
  final List<String?> values;

  /// The focused slot, for a validator to stay quiet about groups the user has
  /// not reached yet. Never for deciding which keys are legal.
  final int? activeIndex;

  /// Canonical value of the group with [key], or '' if no group has it.
  String group(String key) => spec.valueOfGroup(key, values);

  /// The group containing [activeIndex], or null.
  PlateTextGroup? get activeGroup =>
      activeIndex == null ? null : spec.groupAt(activeIndex!);
}

/// True when every character is an ASCII digit 0-9.
bool isDigits(String value) =>
    value.isNotEmpty && value.codeUnits.every((u) => u >= 0x30 && u <= 0x39);

/// [isDigits] and exactly [length] characters.
bool isDigitsOfLength(String value, int length) =>
    value.length == length && isDigits(value);

/// Whether a plate's value is acceptable. A validator never prevents input;
/// it is asked and answers. What the host does with the answer — paint red,
/// enable submit, do nothing — is the host's decision.
abstract class PlateValidator {
  const PlateValidator();

  PlateValidation validate(PlateEntry entry);
}

/// A [PlateValidator] that stays quiet until one named register has something
/// in it. The register named by [gateGroup] is the last one the user reaches,
/// so by the time it is non-empty there is a whole plate to judge.
abstract class GatedPlateValidator extends PlateValidator {
  const GatedPlateValidator();

  /// The [PlateTextGroup.key] whose emptiness keeps this validator quiet.
  String get gateGroup;

  /// The verdict on a plate whose [gateGroup] is non-empty.
  PlateValidation judge(PlateEntry entry);

  @override
  PlateValidation validate(PlateEntry entry) => entry.group(gateGroup).isEmpty
      ? const PlateValidation.valid()
      : judge(entry);
}
