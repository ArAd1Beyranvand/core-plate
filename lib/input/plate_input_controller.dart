import 'package:flutter/foundation.dart';

import '../model/plate_spec.dart';

/// Implemented by PlateCanvas's State. Not for app code to implement.
///
/// The controller talks to the attached canvas through this interface because
/// the canvas's State is private and cannot be referenced by type from here.
abstract class PlateInputTarget {
  PlateSlot? get activeSlot;
  void submitCharacter(String character);
  void backspaceCharacter();
  void focusFirstEmptySlot();
  void focusSlot(int index);
}

/// A handle a host app holds to drive character entry on a [PlateCanvas]
/// without knowing which slot is active or which alphabet it accepts.
///
/// The host renders its own on-screen keypad, reads [activeSlot] to decide
/// which keys to show, and calls [submit]/[backspace] to enter or remove
/// characters. The controller keeps no plate state of its own: every operation
/// is proxied to the attached canvas, which owns the focus and the bloc.
class PlateInputController extends ChangeNotifier {
  PlateInputTarget? _target;

  /// Called by PlateCanvas. Do not call from app code.
  void attach(PlateInputTarget target) {
    _target = target;
    notifyListeners();
  }

  /// Called by PlateCanvas. Do not call from app code.
  ///
  /// Guarded so that when a PlateCanvas is rebuilt into a new element — the new
  /// state attaches before the old one disposes — the old state's detach does
  /// not null out the live target.
  void detach(PlateInputTarget target) {
    if (identical(_target, target)) {
      _target = null;
      notifyListeners();
    }
  }

  /// Called by PlateCanvas when its active slot changes.
  void notifyActiveSlotChanged() => notifyListeners();

  /// The slot currently accepting input, or null when the plate is unfocused
  /// (or no canvas is attached). Hosts read it to decide which keypad to show.
  PlateSlot? get activeSlot => _target?.activeSlot;

  /// Whether a canvas is currently attached.
  bool get isAttached => _target != null;

  /// Commit [character] to the active slot and advance focus, exactly as typing
  /// into that slot would. No-op when there is no active slot, or when
  /// `activeSlot.alphabet.accepts(character)` is false.
  void submit(String character) => _target?.submitCharacter(character);

  /// Clear the active slot; if it is already empty, step focus backwards to the
  /// previous slot (the one whose `next` points at the active index) and clear
  /// that instead. No-op at the start of the plate.
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
