import 'package:flutter/widgets.dart';

import '../model/plate_alphabet.dart';
import '../model/plate_input_source.dart';
import '../model/plate_number.dart';
import '../model/plate_spec.dart';
import '../model/slot_behavior.dart';
import 'plate_input_controller.dart';

/// Owns focus and navigation for one plate. Knows the spec and the focus
/// nodes; knows nothing about pixels, and nothing about bloc.
///
/// Values reach it through [readValues] and leave through [commit], so the
/// machine is independent of how the host stores plate state. That is what
/// makes it exercisable on its own, and it is why swapping `PlateCardBloc` for
/// something else later would not touch this file.
///
/// A machine belongs to exactly one [spec]: its focus nodes and controllers are
/// built from that spec's slot list, and a slot index means nothing outside it.
/// A canvas whose spec changes therefore disposes its machine and builds a new
/// one, rather than reindexing the old plate's nodes against the new plate.
class PlateInputMachine implements PlateInputTarget {
  PlateInputMachine({
    required this.spec,
    required this.readValues,
    required this.commit,
    required this.inputSource,
    this.onActiveIndexChanged,
  }) {
    for (var i = 0; i < spec.slots.length; i++) {
      _focusNodes.add(FocusNode()..addListener(_handleFocusChange));
      _controllers.add(
        spec.slots[i].alphabet.input == AlphabetInput.typed
            ? TextEditingController()
            : null,
      );
    }
    // Seed the active slot to the first one before any focus lands, so a host
    // that renders its own keypad off [activeIndex] (e.g. picking a digit vs.
    // letters pad from the slot's alphabet) starts on the alphabet the first
    // slot actually takes — instead of defaulting to one type and visibly
    // switching the instant focus reaches slot 0. The seed is deliberately not
    // announced from here: see the post-frame report in PlateCanvas.
    _activeIndex = spec.slots.isNotEmpty ? 0 : null;
  }

  /// The plate this machine drives. Fixed for the machine's lifetime.
  final PlateSpec spec;

  /// The plate's characters in slot order, read on demand so the machine never
  /// caches a value the host has since changed.
  final List<String?> Function() readValues;

  /// Writes one slot's character back to the host; '' clears the slot.
  final void Function(int index, String value) commit;

  /// Where characters come from. Mutable because the canvas re-resolves it per
  /// build — [PlateMode.display] forces [PlateInputSource.system].
  PlateInputSource inputSource;

  /// Fired when the focused slot changes, with its position, or null when focus
  /// leaves the plate.
  final ValueChanged<int?>? onActiveIndexChanged;

  /// Fired when a chosen slot under [SlotBehavior.sheet] is reached by
  /// [advanceFrom]. The canvas sets this; the machine never presents UI.
  ValueChanged<int>? onSheetRequested;

  // Indexed by slot position: slot identity *is* list order, so a dense list
  // says that in the type instead of leaving it to convention. Null controller
  // entries are chosen-alphabet slots, which have no text field.
  final List<FocusNode> _focusNodes = [];
  final List<TextEditingController?> _controllers = [];

  int? _activeIndex;

  FocusNode focusNodeAt(int index) => _focusNodes[index];

  /// Null for chosen slots, which have no text field.
  TextEditingController? controllerAt(int index) => _controllers[index];

  @override
  int? get activeIndex => _activeIndex;

  void _handleFocusChange() {
    int? active;
    for (var i = 0; i < _focusNodes.length; i++) {
      if (_focusNodes[i].hasFocus) {
        active = i;
        break;
      }
    }
    if (active != _activeIndex) {
      _activeIndex = active;
      onActiveIndexChanged?.call(active);
    }
  }

  /// Moves focus off [index] to wherever the plate says input continues:
  /// the next slot, the picker for a chosen slot, or nowhere at the end of the
  /// plate — where focus is dropped rather than wrapped around.
  void advanceFrom(int index) {
    final next = spec.nextIndex(index);
    if (next == null) {
      _focusNodes[index].unfocus();
      return;
    }
    final nextBehavior = resolveSlotBehavior(
      mode: PlateMode.input,
      input: spec.slots[next].alphabet.input,
      source: inputSource,
    );
    if (nextBehavior == SlotBehavior.sheet) {
      onSheetRequested?.call(next);
    } else {
      _focusNodes[next].requestFocus();
    }
  }

  /// Keeps ONE slot's field in step with the host's value for it.
  ///
  /// Deliberately per-slot, not a walk over the whole plate: the canvas's slot
  /// bindings each subscribe to their own character, so a keystroke rebuilds
  /// (and syncs) one slot. A bulk sync here would put the whole-plate rebuild
  /// back.
  void syncController(int index, String? value) {
    final field = _controllers[index];
    if (field == null) return;
    final text = value ?? '';
    if (field.text == text) return;
    field.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void dispose() {
    for (final c in _controllers) {
      c?.dispose();
    }
    for (final f in _focusNodes) {
      f.removeListener(_handleFocusChange);
      f.dispose();
    }
  }

  @override
  void submitCharacter(String c) {
    final index = _activeIndex;
    if (index == null || !spec.slots[index].alphabet.accepts(c)) return;
    commit(index, c);
    advanceFrom(index);
  }

  @override
  void backspaceCharacter() {
    final index = _activeIndex;
    if (index == null) return;
    final values = readValues();
    final current = values[index];
    final target = (current == null || current.isEmpty)
        ? spec.previousIndex(index)
        : index;
    if (target == null) return;
    commit(target, '');
    _focusNodes[target].requestFocus();
  }

  @override
  void focusFirstEmptySlot() {
    final values = readValues();
    for (var i = 0; i < spec.slots.length; i++) {
      final v = values[i];
      if (v == null || v.isEmpty) {
        _focusNodes[i].requestFocus();
        return;
      }
    }
    _focusNodes.first.requestFocus();
  }

  @override
  void focusSlot(int index) {
    if (index < 0 || index >= _focusNodes.length) return;
    _focusNodes[index].requestFocus();
  }
}
