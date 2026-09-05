import 'package:flutter/foundation.dart';

import '../model/plate_number.dart';
import '../model/plate_spec.dart';
import 'plate_input_controller.dart';

/// What happens to the characters already on a plate when its [PlateSpec] is
/// swapped under them by [PlateController.adoptSpec].
enum PlateValuePreservation {
  /// Start the new plate empty.
  none,

  /// Copy slot by slot while both plates have a slot at that position.
  byIndex,

  /// Copy register by register, matching [PlateTextGroup.key] between the two
  /// specs. The default, because corresponding registers rarely sit in
  /// corresponding positions.
  byGroupKey,
}

/// A host-facing handle that *owns* one plate's characters, on top of the
/// focus and navigation [PlateInputController] already drives.
///
/// It subclasses [PlateInputController] deliberately: every host that passes a
/// controller to a canvas keeps compiling, while a host that wants the value
/// as well passes one of these instead. [PlateInputController] stays as it is,
/// for hosts that only ever wanted focus.
///
/// Listening is available at two grains, and the finer one is the point:
/// [slot] hands back a listenable for a single position, so a keystroke
/// rebuilds the one slot it landed in; [completed] flips only when the plate
/// crosses between full and not; and the controller itself notifies on every
/// committed change for whoever genuinely wants all of them.
class PlateController extends PlateInputController {
  PlateController({required PlateSpec spec, List<String?>? values})
    : _spec = spec {
    _values = List<String?>.filled(spec.slotCount, null);
    if (values != null) {
      for (var i = 0; i < spec.slotCount && i < values.length; i++) {
        _values[i] = _sanitize(spec, i, values[i]);
      }
    }
    _foundSlots();
    _completed = ValueNotifier<bool>(_computeCompleted());
  }

  /// The plate as [values] describes it, characters the slots refuse dropped.
  factory PlateController.fromValues(PlateSpec spec, List<String?> values) =>
      PlateController(spec: spec, values: values);

  /// One character of [text] per slot, in index order, skipping characters the
  /// slot's alphabet refuses. Separators in [text] therefore cost nothing: a
  /// space is not in any alphabet, so it is passed over rather than consuming
  /// a slot.
  factory PlateController.fromText(PlateSpec spec, String text) {
    final values = List<String?>.filled(spec.slotCount, null);
    var index = 0;
    for (final character in text.characters) {
      if (index >= spec.slotCount) break;
      if (!spec.slots[index].alphabet.accepts(character)) continue;
      values[index] = character;
      index++;
    }
    return PlateController(spec: spec, values: values);
  }

  PlateSpec _spec;
  late List<String?> _values;
  late List<ValueNotifier<String?>> _slots;
  late final ValueNotifier<bool> _completed;

  /// The plate this controller holds a value for. Changed only through
  /// [adoptSpec], which decides what happens to the characters.
  PlateSpec get spec => _spec;

  /// The characters in slot order. Always [PlateSpec.slotCount] long, with
  /// null for an unset slot. Unmodifiable — write through [setAt],
  /// [setValues], [setGroup] or [clear].
  List<String?> get values => List<String?>.unmodifiable(_values);

  /// The character at [index], or null when [index] is outside the plate.
  String? valueAt(int index) =>
      index >= 0 && index < _values.length ? _values[index] : null;

  /// The character at [index]; '' or null clears the slot. A character the
  /// slot's alphabet refuses is a no-op — the controller stores plates that
  /// could exist, and never bars a keystroke by way of an exception.
  void setAt(int index, String? value) {
    if (index < 0 || index >= _values.length) return;
    final next = _sanitize(_spec, index, value);
    if (next == null && value != null && value.isNotEmpty) return;
    _values[index] = next;
    _slots[index].value = next;
    _completed.value = _computeCompleted();
    notifyListeners();
  }

  /// Every slot at once, in index order, as [PlateController.new] reads them.
  /// Notifies once for the whole write rather than once per slot.
  void setValues(List<String?> values) {
    for (var i = 0; i < _values.length; i++) {
      final next = i < values.length ? _sanitize(_spec, i, values[i]) : null;
      _values[i] = next;
      _slots[i].value = next;
    }
    _completed.value = _computeCompleted();
    notifyListeners();
  }

  /// Empty every slot.
  void clear() => setValues(List<String?>.filled(_values.length, null));

  /// The plate as text: each of [PlateSpec.effectiveTextGroups] rendered
  /// through its slots' alphabets, joined by [sep].
  String text({String sep = ' '}) => [
    for (final group in _spec.effectiveTextGroups)
      _spec.renderGroup(group, _values),
  ].join(sep);

  /// The characters of the group named [key], in canonical (storage) form —
  /// what a validator reads. '' when no group carries that key.
  String group(String key) => _spec.valueOfGroup(key, _values);

  /// Writes [value] across the slots of the group named [key], one character
  /// per slot in group order, stopping at the shorter of the two. Characters
  /// the target slot refuses clear it rather than being forced in. No-op when
  /// no group carries that key.
  void setGroup(String key, String value) {
    final group = _groupNamed(_spec, key);
    if (group == null) return;
    final characters = value.characters;
    for (var n = 0; n < group.indices.length; n++) {
      final index = group.indices[n];
      final character = n < characters.length ? characters[n] : '';
      _values[index] = _sanitize(_spec, index, character);
      _slots[index].value = _values[index];
    }
    _completed.value = _computeCompleted();
    notifyListeners();
  }

  /// Whether every slot holds a character.
  bool get isCompleted => _completed.value;

  /// Whether no slot holds a character.
  bool get isEmpty => !_values.any((v) => v != null && v.isNotEmpty);

  /// The value as the model type a bloc, a validator or a host's own storage
  /// speaks in.
  PlateNumber get plateNumber => PlateNumber(values: _values);

  /// The character at [index] on its own, so a widget can subscribe to one
  /// slot instead of to the whole plate. Out of range returns a listenable
  /// that is null forever, rather than throwing: a widget that outlives a
  /// shrinking spec by a frame should paint an empty slot, not crash.
  ValueListenable<String?> slot(int index) =>
      index >= 0 && index < _slots.length
      ? _slots[index]
      : const _AlwaysNull<String?>();

  /// Whether the plate is full, as a listenable that fires on the flip and not
  /// on the keystrokes in between.
  ValueListenable<bool> get completed => _completed;

  /// Swaps the plate under the value, carrying the characters across as
  /// [preserve] directs, and notifies once.
  ///
  /// The slot listenables are re-founded for the new spec's length, so anything
  /// holding one from the old spec keeps a live object that simply stops being
  /// updated — hand out [slot] results per build rather than caching them.
  void adoptSpec(
    PlateSpec next, {
    PlateValuePreservation preserve = PlateValuePreservation.byGroupKey,
  }) {
    final migrated = _migrate(_spec, next, _values, preserve);
    _spec = next;
    _values = migrated;
    for (final slot in _slots) {
      slot.dispose();
    }
    _foundSlots();
    _completed.value = _computeCompleted();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final slot in _slots) {
      slot.dispose();
    }
    _completed.dispose();
    super.dispose();
  }

  void _foundSlots() {
    _slots = [
      for (var i = 0; i < _spec.slotCount; i++)
        ValueNotifier<String?>(_values[i]),
    ];
  }

  bool _computeCompleted() =>
      _values.isNotEmpty && !_values.any((v) => v == null || v.isEmpty);

  /// [value] as this slot will store it: null for a cleared slot, and null as
  /// well for a character the slot's alphabet refuses.
  static String? _sanitize(PlateSpec spec, int index, String? value) {
    if (value == null || value.isEmpty) return null;
    final slot = spec.slotAt(index);
    if (slot == null || !slot.alphabet.accepts(value)) return null;
    return value;
  }

  static PlateTextGroup? _groupNamed(PlateSpec spec, String key) {
    for (final group in spec.effectiveTextGroups) {
      if (group.key == key) return group;
    }
    return null;
  }

  static bool _hasKeyedGroups(PlateSpec spec) =>
      spec.effectiveTextGroups.any((g) => g.key != null);

  /// [values], read against [from], rewritten as a value list for [to].
  static List<String?> _migrate(
    PlateSpec from,
    PlateSpec to,
    List<String?> values,
    PlateValuePreservation preserve,
  ) {
    if (preserve == PlateValuePreservation.none) {
      return List<String?>.filled(to.slotCount, null);
    }

    final byKey =
        preserve == PlateValuePreservation.byGroupKey &&
        (_hasKeyedGroups(from) || _hasKeyedGroups(to));
    if (!byKey) {
      return [
        for (var i = 0; i < to.slotCount; i++)
          i < values.length ? _sanitize(to, i, values[i]) : null,
      ];
    }

    final result = List<String?>.filled(to.slotCount, null);

    // A slot whose alphabet holds exactly one character is printed on every
    // plate of this design, not typed: fill it from the alphabet. Done first
    // so a matched group covering the same slot still wins.
    for (var i = 0; i < to.slotCount; i++) {
      final characters = to.slots[i].alphabet.characters;
      if (characters.length == 1) result[i] = characters.single;
    }

    for (final target in to.effectiveTextGroups) {
      final key = target.key;
      if (key == null) continue;
      final source = _groupNamed(from, key);
      if (source == null) continue;

      // The source group's characters in order, unset slots skipped rather
      // than carried as gaps — a half-typed register carries as far as it got.
      final characters = <String>[
        for (final i in source.indices)
          if (i < values.length && (values[i] ?? '').isNotEmpty) values[i]!,
      ];

      for (var n = 0; n < target.indices.length; n++) {
        final index = target.indices[n];
        final character = n < characters.length ? characters[n] : '';
        result[index] = _sanitize(to, index, character);
      }
    }

    return result;
  }
}

/// A listenable that is null forever and never notifies, so nothing has to
/// hold a nullable listenable to describe "no such slot".
@immutable
class _AlwaysNull<T> implements ValueListenable<T?> {
  const _AlwaysNull();

  @override
  T? get value => null;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

extension on String {
  /// The string as single characters. Plate alphabets are single-character
  /// sets, so splitting on code units would be wrong for any script outside
  /// the BMP; [runes] is the honest unit here.
  List<String> get characters => [
    for (final rune in runes) String.fromCharCode(rune),
  ];
}
