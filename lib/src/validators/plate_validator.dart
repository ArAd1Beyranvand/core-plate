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

  // Equality over [reason] so a consumer that listens for verdict changes
  // (e.g. PlateController.validation) notifies when the verdict changes,
  // not on every committed value that leaves the verdict the same.
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

  /// The slot the user is on, when a host tracks one. A validator MUST NOT
  /// use this to decide what may be typed next — it exists so a verdict can
  /// name the offending group, and so a validator can stay quiet about a
  /// group the user has not reached yet.
  final int? activeIndex;

  /// Canonical value of the group with [key], or '' if no group has it.
  String group(String key) => spec.valueOfGroup(key, values);

  /// The group containing [activeIndex], or null.
  PlateTextGroup? get activeGroup =>
      activeIndex == null ? null : spec.groupAt(activeIndex!);
}

/// Whether every character of [value] is an ASCII digit, and [value] is not
/// empty.
///
/// The one place the `^[0-9]+$` test lives. It was declared four times across
/// three country packages, twice in the same file. Not a method on
/// [PlateEntry], because a validator also asks it of values that never came
/// from a slot — a database row, a scan result.
bool isDigits(String value) =>
    value.isNotEmpty && value.codeUnits.every((u) => u >= 0x30 && u <= 0x39);

/// [isDigits] and exactly [length] characters long.
bool isDigitsOfLength(String value, int length) =>
    value.length == length && isDigits(value);

/// A rule about whether a plate's value is acceptable.
///
/// A validator NEVER prevents input. It is asked a question and answers it;
/// what a host does with the answer — paint the frame red, enable a submit
/// button, do nothing — is the host's decision. There is deliberately no
/// "which keys are barred" method: see docs/split/PLAN.md §1.
abstract class PlateValidator {
  const PlateValidator();

  PlateValidation validate(PlateEntry entry);
}

/// A [PlateValidator] that stays quiet until one named register has something
/// in it.
///
/// Every validator in this workspace has this shape, and for one reason: a
/// validator never bars a keystroke, so the invalid state is the only feedback
/// there is, and a plate that flashes red at its first character is worse than
/// no validation. The register named by [gateGroup] is the last one the user
/// reaches, so by the time it is non-empty there is a whole plate to judge.
///
/// Subclasses implement [judge] and never see the empty-plate case.
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
