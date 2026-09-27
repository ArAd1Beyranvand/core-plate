import 'plate_controller.dart';

/// What a [PlateController] drives: a plate's focus and navigation.
/// Implemented by [PlateInputMachine], which a [PlateCanvas] attaches on the
/// host's behalf — or a host can hold and attach itself.
abstract class PlateInputTarget {
  int? get activeIndex;
  void submitCharacter(String character);
  void backspaceCharacter();
  void focusFirstEmptySlot();
  void focusSlot(int index);
}
