import 'plate_controller.dart';

/// What a [PlateController] drives: one plate's focus and navigation.
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

/// The old name for [PlateController].
///
/// Until 0.5.0 the value-owning handle *extended* a focus-only
/// `PlateInputController`, so a canvas could take either. There is one class
/// now; this alias keeps existing annotations compiling.
@Deprecated('Renamed to PlateController in 0.5.0; will be removed in 0.6.0.')
typedef PlateInputController = PlateController;
