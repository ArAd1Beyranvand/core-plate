import 'package:flutter/widgets.dart';

import '../model/plate_alphabet.dart';
import '../model/plate_input_source.dart';
import '../model/plate_number.dart';
import '../model/plate_spec.dart';
import '../model/slot_behavior.dart';
import 'plate_input_controller.dart';

/// Owns focus and navigation for one plate: the focus nodes and text
/// controllers. Takes values through [readValues] and writes them through
/// [commit], so it is independent of how the host stores state. Tied to its
/// [spec]: a spec change disposes it and builds a new one rather than
/// reindexing.
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
    // An editable mirror is a second field over one slot, but it is not a slot
    // itself: it adds nothing to the plate's count, grammar or completion. Its
    // focus reports as its source's, so a keypad reads the same alphabet
    // whichever row is being typed.
    for (var i = 0; i < spec.mirrors.length; i++) {
      final mirror = spec.mirrors[i];
      final alphabet = mirror.alphabet ?? spec.slots[mirror.source].alphabet;
      if (mirror.editable && alphabet.input == AlphabetInput.typed) {
        _mirrorFocusNodes.add(FocusNode()..addListener(_handleFocusChange));
        _mirrorControllers.add(TextEditingController());
      } else {
        _mirrorFocusNodes.add(null);
        _mirrorControllers.add(null);
      }
    }
    // Seed the active slot to the first one before focus lands. A host that
    // renders its keypad off [activeIndex] starts on the first slot's alphabet
    // rather than defaulting to a type. The seed is not announced from here.
    _activeIndex = spec.slots.isNotEmpty ? 0 : null;
  }

  final PlateSpec spec;
  final List<String?> Function() readValues;

  /// Write one slot's character; '' clears it.
  final void Function(int index, String value) commit;

  /// Where characters come from. Re-resolved per build; [PlateMode.display]
  /// forces [PlateInputSource.system].
  PlateInputSource inputSource;

  /// Fired when the focused slot changes or focus leaves the plate.
  final ValueChanged<int?>? onActiveIndexChanged;

  /// Fired when a chosen slot under [SlotBehavior.sheet] is reached.
  ValueChanged<int>? onSheetRequested;

  // Dense list by slot position. Null controllers are chosen-alphabet slots.
  final List<FocusNode> _focusNodes = [];
  final List<TextEditingController?> _controllers = [];

  // Parallel to mirrors. Null entries are read-only or chosen-alphabet mirrors.
  final List<FocusNode?> _mirrorFocusNodes = [];
  final List<TextEditingController?> _mirrorControllers = [];

  int? _activeIndex;

  FocusNode focusNodeAt(int index) => _focusNodes[index];
  TextEditingController? controllerAt(int index) => _controllers[index];
  FocusNode? mirrorFocusNodeAt(int mirrorIndex) =>
      _mirrorFocusNodes[mirrorIndex];
  TextEditingController? mirrorControllerAt(int mirrorIndex) =>
      _mirrorControllers[mirrorIndex];

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
    // An editable mirror reports focus as its source's — the two share one value.
    if (active == null) {
      for (var i = 0; i < _mirrorFocusNodes.length; i++) {
        if (_mirrorFocusNodes[i]?.hasFocus ?? false) {
          active = spec.mirrors[i].source;
          break;
        }
      }
    }
    if (active != _activeIndex) {
      _activeIndex = active;
      onActiveIndexChanged?.call(active);
    }
  }

  /// Advance focus off [index] to the next slot, the sheet for a chosen slot,
  /// or nowhere at the end of the plate.
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

  /// Sync one slot's field with the host's value for it. Per-slot, not bulk:
  /// the canvas's slot bindings each subscribe to their own character, so a
  /// keystroke rebuilds one slot.
  ///
  /// The field shows the alphabet's display form (national numerals) while the
  /// host stores the canonical value. This lets a national-numeral slot type in
  /// its own script.
  void syncController(int index, String? value) {
    final field = _controllers[index];
    if (field == null) return;
    final stored = value ?? '';
    final text = stored.isEmpty
        ? ''
        : spec.slots[index].alphabet.render(stored);
    if (field.text == text) return;
    field.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Sync an editable mirror's field with its source slot's value, rendered
  /// through the mirror's alphabet — the Latin row shows `5` where the Iranian
  /// row shows `٥`.
  void syncMirrorController(
    int mirrorIndex,
    PlateAlphabet alphabet,
    String? value,
  ) {
    final field = _mirrorControllers[mirrorIndex];
    if (field == null) return;
    final stored = value ?? '';
    final text = stored.isEmpty ? '' : alphabet.render(stored);
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
    for (final c in _mirrorControllers) {
      c?.dispose();
    }
    for (final f in _mirrorFocusNodes) {
      f?.removeListener(_handleFocusChange);
      f?.dispose();
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
