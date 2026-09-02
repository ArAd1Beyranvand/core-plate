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
  // (e.g. PlateInputController.validation) notifies when the verdict changes,
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
