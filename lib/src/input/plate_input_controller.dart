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
