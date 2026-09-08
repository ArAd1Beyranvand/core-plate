import 'package:flutter/widgets.dart';

import 'plate_alphabet.dart';
import 'plate_box.dart';
import 'plate_country.dart';

/// One editable position on a plate. [box].height doubles as the slot height
/// passed to the glyph style — do not add a separate field for it.
@immutable
class PlateSlot {
  const PlateSlot({required this.alphabet, required this.box});

  final PlateAlphabet alphabet;
  final PlateBox box;
}

/// A read-only echo of a slot's value, painted somewhere else on the plate.
///
/// A plate that prints the same number twice — big national numerals on top,
/// the same number again smaller in Latin digits beneath — is one value with
/// two presentations, not two slots. A mirror is stateful (it shows a value
/// that changes) but not editable: it owns no [FocusNode], no controller and no
/// position in [PlateSpec.slots], so it never appears in text groups, focus
/// traversal, completion or validation.
///
/// [alphabet] IS the transform: [PlateAlphabet.glyphs] is the storage -> display
/// map, so echoing a slot in another numeral system means pointing [alphabet] at
/// an alphabet with different glyphs. Null renders through the source slot's own
/// alphabet.
@immutable
class PlateMirror {
  const PlateMirror({
    required this.source,
    required this.box,
    required this.glyphHeight,
    this.alphabet,
  });

  /// Index into [PlateSpec.slots] of the slot whose value is echoed.
  final int source;

  final PlateBox box;

  /// Passed to the glyph style as the slot height.
  final double glyphHeight;

  /// Renders the echoed value. Null means the source slot's own alphabet.
  final PlateAlphabet? alphabet;
}

/// A painted rule (e.g. a vertical divider between character groups).
@immutable
class PlateRule {
  const PlateRule({required this.box});

  final PlateBox box;
}

/// A fixed image painted on the plate face at a set position — a sticker or
/// badge that sits *between* character groups rather than inside a slot (e.g.
/// the German inspection and federal-state stickers). Like [PlateLabel] and
/// [PlateRule], it is pure plate-space geometry plus content: the widget layer
/// paints whatever [image] provides, so adding one never means a new widget.
@immutable
class PlateDecal {
  const PlateDecal({required this.image, required this.box});

  /// The image to paint, e.g. an `AssetImage(..., package: 'plate_number')`.
  final ImageProvider image;

  final PlateBox box;
}

/// Fixed text printed on the plate face (e.g. "ایران").
@immutable
class PlateLabel {
  const PlateLabel({
    required this.text,
    required this.box,
    required this.glyphHeight,
  });

  final String text;
  final PlateBox box;

  /// Passed to the glyph style as the slot height.
  final double glyphHeight;
}

/// The coloured country block on the plate face: where it sits, and how the
/// flag and caption are laid out inside it.
@immutable
class PlatePanel {
  const PlatePanel({
    required this.box,
    this.flagScale = 1.0,
    this.captionScale = 1.0,
    this.padding,
  });

  final PlateBox box;

  /// Scale factor applied to the flag inside the country panel. Defaults to
  /// 1.0 (full size). Use a smaller value (e.g. 0.4) for compact plates where
  /// the panel is too shallow to display a full-size flag legibly.
  final double flagScale;

  /// Scale factor applied to the country caption inside the panel. Defaults
  /// to 1.0 (full size). Use a smaller value on compact plates where a
  /// bigger flag needs the caption to give up some room.
  final double captionScale;

  /// Padding around the flag + caption inside the country panel. Null keeps
  /// the default: a uniform inset of 10% of the panel's height on all sides.
  final EdgeInsets? padding;
}

/// One visual group in the plain-text rendering of a plate (e.g. a digit
/// triple). [prefix] is prepended to the rendered characters (e.g. a country
/// code before a regional group).
@immutable
class PlateTextGroup {
  const PlateTextGroup(this.indices, {this.prefix = '', this.key});
  final List<int> indices;
  final String prefix;

  /// Optional semantic identifier (e.g. 'district', 'letters', 'serial'),
  /// used by spec-aware validators to pull a group's value by name instead
  /// of by position. Null for groups with no validator meaning.
  final String? key;
}

/// A complete plate design. Adding a plate — including for a new country — means
/// adding a const of this type. It must never mean adding a widget.
@immutable
class PlateSpec {
  const PlateSpec({
    required this.id,
    required this.country,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.panel,
    required this.slots,
    this.rules = const <PlateRule>[],
    this.labels = const <PlateLabel>[],
    this.decals = const <PlateDecal>[],
    this.mirrors = const <PlateMirror>[],
    this.textDirection = TextDirection.ltr,
    this.borderWidthRatioOverride,
    this.textGroups = const <PlateTextGroup>[],
  });

  /// Stable identifier, e.g. 'xx.car'. Used for equality and persistence.
  final String id;

  final PlateCountry country;

  final double canvasWidth, canvasHeight;
  final PlatePanel panel;

  final List<PlateSlot> slots;
  final List<PlateRule> rules;
  final List<PlateLabel> labels;
  final List<PlateDecal> decals;

  /// Read-only echoes of slot values. Purely presentational: they do not add
  /// to [slotCount] and carry no input state.
  final List<PlateMirror> mirrors;

  final TextDirection textDirection;

  /// Applied via theme.copyWith when non-null.
  final double? borderWidthRatioOverride;

  /// Groups of slot indices for the plain-text rendering of the plate, listed
  /// in [textDirection] reading order. Empty means each slot is its own
  /// group, in index order.
  final List<PlateTextGroup> textGroups;

  /// How many values this plate stores. Derived, never hard-coded.
  int get slotCount => slots.length;

  /// The slot at [index], or null when [index] is outside the plate. Position
  /// is list position — [PlateSlot] carries no index field — so this is a
  /// bounds check and an indexing.
  PlateSlot? slotAt(int index) =>
      index >= 0 && index < slots.length ? slots[index] : null;

  /// [textGroups] if non-empty, else one group per slot in index order — the
  /// rule [textGroups]'s own doc comment describes. Callers should read this
  /// rather than reimplementing the fallback.
  ///
  /// The fallback list is rebuilt per call rather than cached: [PlateSpec] is
  /// `const`-constructed and `@immutable`, and a plate has a handful of slots,
  /// so a fresh `List` of that many [PlateTextGroup]s is cheaper than breaking
  /// const to install a lazy field.
  List<PlateTextGroup> get effectiveTextGroups => textGroups.isNotEmpty
      ? textGroups
      : [
          for (var i = 0; i < slots.length; i++) PlateTextGroup([i]),
        ];

  /// The group in [effectiveTextGroups] containing [index], or null when
  /// [index] is outside every group.
  PlateTextGroup? groupAt(int index) {
    for (final g in effectiveTextGroups) {
      if (g.indices.contains(index)) return g;
    }
    return null;
  }

  /// [group]'s prefix followed by each of its slot values rendered through
  /// that slot's alphabet. Unset slots render as ''.
  String renderGroup(PlateTextGroup group, List<String?> values) {
    final buffer = StringBuffer(group.prefix);
    for (final i in group.indices) {
      final value = i < values.length ? (values[i] ?? '') : '';
      buffer.write(slotAt(i)?.alphabet.render(value) ?? '');
    }
    return buffer.toString();
  }

  /// The slot focus advances to from [index], or null at the end of the plate.
  int? nextIndex(int index) =>
      index >= 0 && index + 1 < slots.length ? index + 1 : null;

  /// The slot focus steps back to from [index], or null at the start.
  int? previousIndex(int index) =>
      index > 0 && index < slots.length ? index - 1 : null;

  /// Concatenates [values] at the indices of the text group with the given
  /// [key], unset slots rendering as ''. Returns '' if no group has that key.
  ///
  /// Walks [effectiveTextGroups] for consistency, though an unkeyed spec has no
  /// keyed groups by definition — the fallback groups carry no [key] — so this
  /// only ever matches on a spec that declares its groups explicitly.
  String valueOfGroup(String key, List<String?> values) {
    for (final g in effectiveTextGroups) {
      if (g.key != key) continue;
      final buffer = StringBuffer();
      for (final i in g.indices) {
        buffer.write(i < values.length ? (values[i] ?? '') : '');
      }
      return buffer.toString();
    }
    return '';
  }

  /// The slot indices of the text group named [key], or an empty list when no
  /// group carries that key.
  ///
  /// The counterpart to [valueOfGroup]: that reads a register's characters,
  /// this names the positions they live in — what anything that *writes* a
  /// register needs. Walks [effectiveTextGroups], so a spec that declares no
  /// groups answers consistently with every other accessor here (its fallback
  /// groups carry no keys, so the answer is empty).
  ///
  /// Returns empty rather than throwing: a caller that wants the strict
  /// behaviour tests for it and says so in its own terms.
  List<int> indicesOfGroup(String key) {
    for (final g in effectiveTextGroups) {
      if (g.key == key) return g.indices;
    }
    return const <int>[];
  }

  @override
  bool operator ==(Object other) => other is PlateSpec && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Debug-only sanity check for a [PlateSpec]'s internal consistency: every
/// slot and mirror rect fits within the canvas, every mirror echoes a real
/// slot, and alphabet ids key content one-to-one. Always returns true — call
/// it inside an
/// `assert(...)` so it's stripped from release builds.
bool debugValidateSpec(PlateSpec spec) {
  for (var i = 0; i < spec.slots.length; i++) {
    final b = spec.slots[i].box;
    assert(
      b.left >= 0 &&
          b.top >= 0 &&
          b.right <= spec.canvasWidth &&
          b.bottom <= spec.canvasHeight,
      'PlateSlot $i in spec "${spec.id}" has a rect outside the '
      'canvas (${spec.canvasWidth}x${spec.canvasHeight}).',
    );
  }

  for (var i = 0; i < spec.mirrors.length; i++) {
    final m = spec.mirrors[i];
    final b = m.box;
    assert(
      b.left >= 0 &&
          b.top >= 0 &&
          b.right <= spec.canvasWidth &&
          b.bottom <= spec.canvasHeight,
      'PlateMirror $i in spec "${spec.id}" has a rect outside the '
      'canvas (${spec.canvasWidth}x${spec.canvasHeight}).',
    );
    assert(
      m.source >= 0 && m.source < spec.slots.length,
      'PlateMirror $i in spec "${spec.id}" echoes slot ${m.source}, which is '
      'not a slot index (0..${spec.slots.length - 1}).',
    );
  }

  // A register drifts silently: a hand-written run of cells is a for-loop
  // unrolled by hand, and one rounded coordinate is invisible until someone
  // measures the plate. Checked only for keyed groups of three or more cells
  // that share a row, so a two-line layout — which splits one register across
  // two bands — is exempt, as is a pair, which has no pitch to be wrong about.
  for (final g in spec.effectiveTextGroups) {
    if (g.key == null || g.indices.length < 3) continue;
    final boxes = <PlateBox>[
      for (final i in g.indices)
        if (spec.slotAt(i) != null) spec.slots[i].box,
    ];
    if (boxes.length != g.indices.length) continue;
    final sameRow = boxes.every(
      (b) => b.top == boxes.first.top && b.height == boxes.first.height,
    );
    if (!sameRow) continue;
    final pitch = boxes[1].left - boxes[0].left;
    for (var n = 1; n < boxes.length; n++) {
      assert(
        (boxes[n].left - boxes[0].left - n * pitch).abs() < 0.01,
        'Register "${g.key}" in spec "${spec.id}" is unevenly pitched: cell $n '
        'sits at ${boxes[n].left}, but a pitch of $pitch puts it at '
        '${boxes[0].left + n * pitch}. Build it with plateRegister/'
        'plateRegisterAcross rather than cell by cell.',
      );
    }
  }

  // Alphabet ids must be a stable key for *rendered* character content: within
  // one spec, no id may appear with two different characters/glyphs pairs, and
  // no two distinct ids may share one pair.
  //
  // The key is characters AND glyphs, not characters alone. `characters` is the
  // accepted (storage) set, so an alphabet that accepts ASCII digits but prints
  // them as national numerals carries the same list as `latin.digits` and a
  // genuinely different meaning - keying on the list alone would call that a
  // collision. Mirrors' alphabets are walked too: they render on the same face.
  final byId = <String, String>{};
  final byContent = <String, String>{};
  for (final a in <PlateAlphabet>[
    for (final slot in spec.slots) slot.alphabet,
    for (final m in spec.mirrors)
      if (m.alphabet != null) m.alphabet!,
  ]) {
    final contentKey = _contentKey(a);
    final seenContent = byId[a.id];
    assert(
      seenContent == null || seenContent == contentKey,
      'Alphabet id "${a.id}" in spec "${spec.id}" appears with two different '
      'character/glyph sets.',
    );
    byId[a.id] = contentKey;
    final seenId = byContent[contentKey];
    assert(
      seenId == null || seenId == a.id,
      'Spec "${spec.id}" has two distinct alphabet ids ("$seenId", "${a.id}") '
      'sharing the same characters and glyphs.',
    );
    byContent[contentKey] = a.id;
  }

  return true;
}

/// The identity of an alphabet's content: what it accepts, and how each
/// accepted character is rendered.
String _contentKey(PlateAlphabet a) =>
    a.characters.map((c) => '$c=${a.render(c)}').join(' ');