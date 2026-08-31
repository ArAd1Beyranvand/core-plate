import 'package:flutter/foundation.dart';

import '../model/plate_spec.dart';
import '../validators/plate_validator.dart';

/// What a [PlateInputController] drives: one plate's focus and navigation.
///
/// Implemented by [PlateInputMachine], which is the object a [PlateCanvas]
/// attaches on the host's behalf — and a perfectly ordinary object for a host
/// to hold and attach itself.
abstract class PlateInputTarget {
  int? get activeIndex;
  void submitCharacter(String character);
  void backspaceCharacter();
  void focusFirstEmptySlot();
  void focusSlot(int index);
}

/// A handle a host app holds to drive character entry on a [PlateCanvas]
/// without knowing which slot is active or which alphabet it accepts.
///
/// The host renders its own on-screen keypad, reads [activeIndex] to decide
/// which keys to show, and calls [submit]/[backspace] to enter or remove
/// characters. The controller keeps no plate state of its own: every operation
/// is proxied to the attached canvas, which owns the focus and the bloc.
class PlateInputController extends ChangeNotifier {
  PlateInputTarget? _target;

  PlateValidation? Function()? _probe;
  PlateValidation? _lastVerdict;

  /// The verdict on the attached plate as it stands, or null when the canvas
  /// has no validator (or none is attached). A host reads this to decide its
  /// own timing — paint something, enable a submit button — instead of
  /// validating by hand.
  ///
  /// Computed on demand, so it is meaningful whether or not the canvas runs
  /// `autoValidate`: a host that validates on submit only pays for exactly the
  /// validations it asks for.
  PlateValidation? get validation => _probe?.call();

  /// Called by PlateCanvas. Do not call from app code.
  ///
  /// Installs the callback behind [validation]; pass null when detaching.
  void installValidation(PlateValidation? Function()? probe) {
    _probe = probe;
    _lastVerdict = null;
  }

  /// Called by PlateCanvas while it is auto-validating. Do not call from app
  /// code.
  ///
  /// Notifies on a change of *verdict* (over [PlateValidation]'s equality,
  /// i.e. its reason), not on every committed value — so a listener rebuilds
  /// on a flip, not on a keystroke. Putting the narrowing here keeps that
  /// property true for every consumer rather than for whichever one
  /// remembered to implement it.
  void reportValidation(PlateValidation? value) {
    if (_lastVerdict == value) return;
    _lastVerdict = value;
    notifyListeners();
  }

  /// Called by PlateCanvas. Do not call from app code.
  void attach(PlateInputTarget target) {
    _target = target;
    notifyListeners();
  }

  /// Called by PlateCanvas. Do not call from app code.
  ///
  /// Guarded so that when a PlateCanvas is rebuilt into a new element — the new
  /// state attaches before the old one disposes — the old state's detach does
  /// not null out the live target. Still load-bearing after a spec swap, which
  /// retires one machine and attaches its replacement.
  void detach(PlateInputTarget target) {
    if (identical(_target, target)) {
      _target = null;
      notifyListeners();
    }
  }

  /// Called by PlateCanvas when its active slot changes.
  void notifyActiveSlotChanged() => notifyListeners();

  /// The position of the slot currently accepting input, or null when the
  /// plate is unfocused (or no canvas is attached). Hosts read it to decide
  /// which keypad to show.
  int? get activeIndex => _target?.activeIndex;

  /// The active slot itself, resolved against [spec] — the convenience for
  /// hosts that need the slot's alphabet rather than just its position. They
  /// know which spec is on screen; the controller deliberately does not.
  PlateSlot? activeSlotIn(PlateSpec spec) => spec.slotAt(activeIndex ?? -1);

  /// Whether a canvas is currently attached.
  bool get isAttached => _target != null;

  /// Commit [character] to the active slot and advance focus, exactly as typing
  /// into that slot would. No-op when there is no active slot, or when the
  /// active slot's alphabet does not accept [character].
  void submit(String character) => _target?.submitCharacter(character);

  /// Clear the active slot; if it is already empty, step focus backwards to the
  /// preceding slot and clear that instead. No-op at the start of the plate.
  void backspace() => _target?.backspaceCharacter();

  /// Focus the first slot with a null/empty value, or the first slot if the
  /// plate is empty. Used to (re)enter the plate programmatically.
  void focusFirstEmpty() => _target?.focusFirstEmptySlot();

  /// Focus the slot at [index] directly, without regard to its value. Used by
  /// hosts that drive character entry programmatically (e.g. a scripted
  /// demo) and need the visible focus/cursor to track the slot being written
  /// to, the way it would if the user had tapped there.
  void focusSlot(int index) => _target?.focusSlot(index);
}
