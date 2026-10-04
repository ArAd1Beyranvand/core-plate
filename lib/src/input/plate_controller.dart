import 'package:flutter/foundation.dart';

import '../model/plate_number.dart';
import '../model/plate_restriction.dart';
import '../model/plate_spec.dart';
import '../validators/plate_validator.dart';
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

/// Owns a plate's characters and drives focus and navigation. Pass to
/// [PlateCanvas] as `controller:` to read or write the value, track the active
/// slot, or feed characters from your own keypad.
///
/// Listen at two grains: [slot] rebuilds one position per keystroke, [completed]
/// flips on full/not-full, and the controller itself notifies on every change.
class PlateController extends ChangeNotifier {
  PlateController({required PlateSpec spec, List<String?>? values})
    : _spec = spec {
    _values = [
      for (var i = 0; i < spec.slotCount; i++) _printedCharacter(spec, i),
    ];
    if (values != null) {
      for (var i = 0; i < spec.slotCount && i < values.length; i++) {
        final printed = _printedCharacter(spec, i);
        if (printed != null) continue;
        _values[i] = _sanitize(spec, i, values[i]);
      }
    }
    final refused = _clearRestricted(spec, _values);
    _foundSlots();
    _completed = ValueNotifier<bool>(_computeCompleted());
    _rejection = ValueNotifier<PlateRestriction?>(refused);
  }

  /// [values] with characters the slots refuse dropped.
  factory PlateController.fromValues(PlateSpec spec, List<String?> values) =>
      PlateController(spec: spec, values: values);

  /// One character of [text] per slot in order; skipping characters no alphabet
  /// accepts. Separators cost nothing — a space is skipped rather than consuming
  /// a slot.
  factory PlateController.fromText(PlateSpec spec, String text) {
    final values = List<String?>.filled(spec.slotCount, null);
    var index = 0;
    for (final character in text.characters) {
      if (index >= spec.slotCount) break;
      final alphabet = spec.slots[index].alphabet;
      if (!alphabet.accepts(character)) continue;
      values[index] = alphabet.canonical(character);
      index++;
    }
    return PlateController(spec: spec, values: values);
  }

  PlateSpec _spec;
  late List<String?> _values;
  late List<ValueNotifier<String?>> _slots;
  late final ValueNotifier<bool> _completed;
  late final ValueNotifier<PlateRestriction?> _rejection;

  /// The plate this controller holds values for. Changed only through [adoptSpec].
  PlateSpec get spec => _spec;

  /// The characters in slot order, [PlateSpec.slotCount] long. Unmodifiable;
  /// write through [setAt], [setValues], [setGroup] or [clear].
  List<String?> get values => List<String?>.unmodifiable(_values);

  /// The character at [index], or null when [index] is outside the plate.
  String? valueAt(int index) =>
      index >= 0 && index < _values.length ? _values[index] : null;

  /// The character at [index]; '' or null clears the slot. A character the
  /// slot's alphabet refuses is a no-op — the controller stores plates that
  /// could exist, and never bars a keystroke by way of an exception.
  /// A slot with one printed character always holds it.
  ///
  /// A write that would complete a [PlateSpec.restrictions] value is refused
  /// too, and published on [rejection]. Returns whether the write was stored.
  bool setAt(int index, String? value) {
    if (index < 0 || index >= _values.length) return false;
    if (_printedCharacter(_spec, index) != null) return false;
    final next = _sanitize(_spec, index, value);
    if (next == null && value != null && value.isNotEmpty) return false;
    if (_refuse(List<String?>.of(_values)..[index] = next)) return false;
    _values[index] = next;
    _slots[index].value = next;
    _completed.value = _computeCompleted();
    _rejection.value = null;
    notifyListeners();
    return true;
  }

  /// Every slot at once, in index order, as [PlateController.new] reads them.
  /// A printed slot keeps its fixed
  /// character and ignores [values]. Notifies once for the whole write rather than once per slot. A write that
  /// breaks a restriction is refused whole; returns whether it was stored.
  bool setValues(List<String?> values) {
    final candidate = [
      for (var i = 0; i < _values.length; i++)
        _printedCharacter(_spec, i) ??
            (i < values.length ? _sanitize(_spec, i, values[i]) : null),
    ];
    if (_refuse(candidate)) return false;
    for (var i = 0; i < _values.length; i++) {
      _values[i] = candidate[i];
      _slots[i].value = candidate[i];
    }
    _completed.value = _computeCompleted();
    _rejection.value = null;
    notifyListeners();
    return true;
  }

  /// Empty every slot.
  void clear() => setValues(List<String?>.filled(_values.length, null));

  /// Each [PlateSpec.effectiveTextGroups] rendered through its slots' alphabets,
  /// joined by [sep].
  String text({String sep = ' '}) => [
    for (final group in _spec.effectiveTextGroups)
      _spec.renderGroup(group, _values),
  ].join(sep);

  /// The characters of the group named [key], in canonical (storage) form. ''
  /// when no group carries that key.
  String group(String key) => _spec.valueOfGroup(key, _values);

  /// Writes [value] across the slots of the group named [key], one character
  /// per slot in group order, stopping at the shorter of the two. Characters
  /// the target slot refuses clear it rather than being forced in. No-op when
  /// no group carries that key.
  ///
  /// Refused whole when it breaks a restriction; returns whether it was stored.
  bool setGroup(String key, String value) {
    final group = _groupNamed(_spec, key);
    if (group == null) return false;
    final characters = value.characters;
    final candidate = List<String?>.of(_values);
    for (var n = 0; n < group.indices.length; n++) {
      final index = group.indices[n];
      if (_printedCharacter(_spec, index) != null) continue;
      final character = n < characters.length ? characters[n] : '';
      candidate[index] = _sanitize(_spec, index, character);
    }
    if (_refuse(candidate)) return false;
    for (final index in group.indices) {
      _values[index] = candidate[index];
      _slots[index].value = _values[index];
    }
    _completed.value = _computeCompleted();
    _rejection.value = null;
    notifyListeners();
    return true;
  }

  bool get isCompleted => _completed.value;
  bool get isEmpty => !_values.any((v) => v != null && v.isNotEmpty);

  /// The value as a [PlateNumber] for a bloc or validator.
  PlateNumber get plateNumber => PlateNumber(values: _values);

  /// A listenable for the character at [index]. Out of range returns a listenable
  /// that is null forever, so a widget outliving a shrinking spec paints an empty
  /// slot rather than crashing.
  ValueListenable<String?> slot(int index) =>
      index >= 0 && index < _slots.length
      ? _slots[index]
      : const _AlwaysNull<String?>();

  /// Whether the plate is full, as a listenable that fires on the flip only.
  ValueListenable<bool> get completed => _completed;

  /// The restriction the last refused write broke, or null once a write has
  /// been stored since. What a host shows as the error; the canvas paints its
  /// reason over the plate.
  ValueListenable<PlateRestriction?> get rejection => _rejection;

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
    final refused = _clearRestricted(next, migrated);
    _spec = next;
    _values = migrated;
    _rejection.value = refused;
    for (final slot in _slots) {
      slot.dispose();
    }
    _foundSlots();
    _completed.value = _computeCompleted();
    notifyListeners();
  }

  PlateInputTarget? _target;
  PlateValidation? Function()? _probe;
  PlateValidation? _lastVerdict;

  /// The verdict on the plate as it stands, or null when the canvas has no
  /// validator (or none is attached). A host reads this to decide its own
  /// timing — paint something, enable a submit button — instead of validating
  /// by hand.
  ///
  /// Computed on demand, so it is meaningful whether or not the canvas runs
  /// `autoValidate`: a host that validates on submit only pays for exactly the
  /// validations it asks for.
  ///
  /// A refused write outranks everything: while [rejection] holds one, the
  /// verdict is its reason, with or without a canvas or validator.
  PlateValidation? get validation {
    final refused = _rejection.value;
    if (refused != null) return PlateValidation.invalid(refused.reason);
    return _probe?.call();
  }

  /// Called by PlateCanvas. Do not call from app code. Installs the probe.
  void installValidation(PlateValidation? Function()? probe) {
    _probe = probe;
    _lastVerdict = null;
  }

  /// Called by PlateCanvas. Do not call from app code. Notifies on a change of
  /// verdict, not on every keystroke.
  void reportValidation(PlateValidation? value) {
    if (_lastVerdict == value) return;
    _lastVerdict = value;
    notifyListeners();
  }

  void attach(PlateInputTarget target) {
    _target = target;
    notifyListeners();
  }

  /// Guarded so that a detach from the old state does not null out a live
  /// target when PlateCanvas rebuilds into a new element.
  void detach(PlateInputTarget target) {
    if (identical(_target, target)) {
      _target = null;
      notifyListeners();
    }
  }

  void notifyActiveSlotChanged() => notifyListeners();

  /// The position of the slot currently accepting input, or null when unfocused.
  int? get activeIndex => _target?.activeIndex;

  /// The slot currently accepting input. Null when unfocused.
  PlateSlot? get activeSlot => _spec.slotAt(activeIndex ?? -1);

  bool get isAttached => _target != null;

  /// Commit [character] to the active slot and advance focus, as typing would.
  void submit(String character) => _target?.submitCharacter(character);

  /// Clear the active slot; if already empty, step back and clear that instead.
  void backspace() => _target?.backspaceCharacter();

  /// Focus the first slot with a null/empty value, or the first slot if empty.
  void focusFirstEmpty() => _target?.focusFirstEmptySlot();

  /// Focus the slot at [index] directly. Used when the host drives character
  /// entry programmatically and needs the cursor to track.
  void focusSlot(int index) => _target?.focusSlot(index);

  @override
  void dispose() {
    // Clear the target first so that a later detach from an outliving canvas
    // does not notify a disposed ChangeNotifier.
    _target = null;
    _probe = null;
    for (final slot in _slots) {
      slot.dispose();
    }
    _completed.dispose();
    _rejection.dispose();
    super.dispose();
  }

  void _foundSlots() {
    _slots = [
      for (var i = 0; i < _spec.slotCount; i++)
        ValueNotifier<String?>(_values[i]),
    ];
  }

  /// Whether [candidate] breaks a restriction; if so, publishes it on
  /// [rejection] and notifies, so a listener shows the error even though the
  /// value did not change.
  bool _refuse(List<String?> candidate) {
    final broken = _spec.restrictionViolatedBy(candidate);
    if (broken == null) return false;
    _rejection.value = broken;
    notifyListeners();
    return true;
  }

  /// Empties, in place, every register of [values] that breaks one of
  /// [spec]'s restrictions — for paths that are handed a whole value rather
  /// than asked to write one. Returns the last restriction broken, or null.
  static PlateRestriction? _clearRestricted(
    PlateSpec spec,
    List<String?> values,
  ) {
    PlateRestriction? broken;
    for (final r in spec.restrictions) {
      if (!r.matches(spec.valueOfGroup(r.group, values))) continue;
      for (final i in spec.indicesOfGroup(r.group)) {
        if (i < values.length) values[i] = null;
      }
      broken = r;
    }
    return broken;
  }

  bool _computeCompleted() =>
      _values.isNotEmpty && !_values.any((v) => v == null || v.isEmpty);

  /// [value] as the slot will store it — null for cleared or refused characters.
  /// A national-numeral slot accepts either form (storage `'5'` or glyph `'۵'`)
  /// and stores the canonical one.
  static String? _sanitize(PlateSpec spec, int index, String? value) {
    if (value == null || value.isEmpty) return null;
    final slot = spec.slotAt(index);
    if (slot == null || !slot.alphabet.accepts(value)) return null;
    return slot.alphabet.canonical(value);
  }

  /// The fixed character of a slot whose alphabet holds exactly one — printed on
  /// every plate, not typed. Null for an ordinary slot.
  static String? _printedCharacter(PlateSpec spec, int index) {
    final characters = spec.slots[index].alphabet.characters;
    return characters.length == 1 ? characters.single : null;
  }

  static PlateTextGroup? _groupNamed(PlateSpec spec, String key) {
    for (final group in spec.effectiveTextGroups) {
      if (group.key == key) return group;
    }
    return null;
  }

  static bool _hasKeyedGroups(PlateSpec spec) =>
      spec.effectiveTextGroups.any((g) => g.key != null);

  /// Migrate [values] from [from] spec to [to] spec as [preserve] directs.
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

    // Fill printed slots first so a matched group still wins.
    for (var i = 0; i < to.slotCount; i++) {
      result[i] = _printedCharacter(to, i);
    }

    for (final target in to.effectiveTextGroups) {
      final key = target.key;
      if (key == null) continue;
      final source = _groupNamed(from, key);
      if (source == null) continue;

      // The source group's non-empty characters, skipped rather than carried as
      // gaps — a half-typed register carries as far as it got.
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

/// A null listenable, so a widget outliving a shrinking spec does not hold
/// a nullable listenable.
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
  /// Single characters. Plate alphabets are single-character sets, so [runes]
  /// is the right unit — code units break scripts outside the BMP.
  List<String> get characters => [
    for (final rune in runes) String.fromCharCode(rune),
  ];
}
