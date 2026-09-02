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

  @override
  bool operator ==(Object other) => other is PlateSpec && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Debug-only sanity check for a [PlateSpec]'s internal consistency: every
/// slot rect fits within the canvas. Always returns true — call it inside an
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

  // Alphabet ids must be a stable key for character content: within one spec,
  // no id may appear with two different `characters` lists, and no two distinct
  // ids may share one list.
  final byId = <String, List<String>>{};
  final byChars = <String, String>{};
  for (final slot in spec.slots) {
    final a = slot.alphabet;
    final charsKey = a.characters.join(' ');
    final seenChars = byId[a.id];
    assert(
      seenChars == null || _sameChars(seenChars, a.characters),
      'Alphabet id "${a.id}" in spec "${spec.id}" appears with two different '
      'character lists.',
    );
    byId[a.id] = a.characters;
    final seenId = byChars[charsKey];
    assert(
      seenId == null || seenId == a.id,
      'Spec "${spec.id}" has two distinct alphabet ids ("$seenId", "${a.id}") '
      'sharing the same characters list.',
    );
    byChars[charsKey] = a.id;
  }

  return true;
}

bool _sameChars(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
