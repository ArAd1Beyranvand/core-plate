import 'package:flutter/widgets.dart';

import 'plate_alphabet.dart';
import 'plate_box.dart';
import 'plate_country.dart';

/// One editable position on a plate. [box].height doubles as the glyph height,
/// so there is deliberately no separate field for it.
@immutable
class PlateSlot {
  const PlateSlot({required this.alphabet, required this.box});

  final PlateAlphabet alphabet;
  final PlateBox box;
}

/// An echo of a slot's value, painted elsewhere on the plate — the same number
/// printed twice, once per script.
///
/// A mirror shares the [source] slot's single value and owns no position in
/// [PlateSpec.slots], so it never adds to [PlateSpec.slotCount], text groups,
/// completion or validation. When [editable] it is still one value: it gets its
/// own [FocusNode] and text controller but reads and writes the source's
/// position, so typing in either row updates both.
///
/// [alphabet] is the transform — echoing in another numeral system means
/// pointing it at an alphabet with different [PlateAlphabet.glyphs]. Null uses
/// the source slot's own.
@immutable
class PlateMirror {
  const PlateMirror({
    required this.source,
    required this.box,
    required this.glyphHeight,
    this.alphabet,
    this.editable = false,
  });

  /// Index into [PlateSpec.slots].
  final int source;

  final PlateBox box;
  final double glyphHeight;
  final PlateAlphabet? alphabet;
  final bool editable;
}

/// A painted rule (e.g. a vertical divider between character groups).
@immutable
class PlateRule {
  const PlateRule({required this.box});

  final PlateBox box;
}

/// A solid block of colour on the plate face — the band a validity date is
/// printed over at the end of a short-term or export plate.
///
/// Paints only the rectangle; the characters over it are ordinary slots and
/// [PlateLabel]s positioned inside [box]. Not a fat [PlateRule], because a rule
/// takes the theme's divider colour and so would follow [PlateSpec.inkOverride];
/// a band is the field the ink is printed *on*, so it carries its own [color].
@immutable
class PlateBand {
  const PlateBand({
    required this.box,
    required this.color,
    this.topCornerRadius = 0,
    this.bottomCornerRadius = 0,
  });

  final PlateBox box;
  final Color color;

  /// Rounds the band's top-left and top-right corners by this radius; the
  /// bottom corners stay square since they sit on the plate's own edge.
  final double topCornerRadius;

  /// Rounds the bottom-left and bottom-right corners too — set alongside
  /// [topCornerRadius] to make a small band a full capsule, e.g. a white
  /// pill sitting inside a larger coloured band.
  final double bottomCornerRadius;
}

/// A fixed image on the plate face — a sticker or badge that sits between
/// character groups rather than inside a slot.
@immutable
class PlateDecal {
  const PlateDecal({required this.image, required this.box});

  /// e.g. an `AssetImage(..., package: 'germany_plate')`.
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
    this.color,
    this.rotated = false,
    this.lineHeight,
  });

  final String text;
  final PlateBox box;
  final double glyphHeight;

  /// Ink for this label, or null for the theme's. Set it only for a label on a
  /// [PlateBand], where the field's ink would be illegible — the theme carries
  /// one ink, and overriding that would recolour the digits too.
  final Color? color;

  /// True to turn the text 90° counter-clockwise to fill a narrow column with
  /// one horizontal word, rather than stacking its letters upright.
  final bool rotated;

  /// [TextStyle.height] override for [glyphStyle], or null for its default.
  /// Set it on a stacked-letter label (one line per character) to open up the
  /// gaps between the lines so the stack fills a tall box.
  final double? lineHeight;
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
    this.direction = Axis.vertical,
  });

  final PlateBox box;

  final double flagScale;
  final double captionScale;

  /// Null means a uniform inset of 10% of the panel's height.
  final EdgeInsets? padding;

  /// [Axis.vertical] puts the flag above the caption, horizontal beside it.
  final Axis direction;
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
    this.noPanel = false,
    this.rightBand,
    this.innerBand,
    this.rules = const <PlateRule>[],
    this.labels = const <PlateLabel>[],
    this.decals = const <PlateDecal>[],
    this.mirrors = const <PlateMirror>[],
    this.textDirection = TextDirection.ltr,
    this.borderWidthRatioOverride,
    this.inkOverride,
    this.textGroups = const <PlateTextGroup>[],
  });

  /// Stable identifier, e.g. 'xx.car'. The sole basis of [operator ==].
  final String id;

  final PlateCountry country;

  final double canvasWidth, canvasHeight;
  final PlatePanel panel;

  /// Suppresses [panel] for a plate with no country block, such as a German
  /// short-term or export plate.
  ///
  /// A bool rather than a nullable [panel]: callers read `spec.panel.box`
  /// unconditionally, so a suppressed panel still declares its geometry and the
  /// face simply does not paint it.
  final bool noPanel;

  /// A solid block of colour at the right-hand end of the plate. Named for its
  /// position because that is the only place the formats using one put it — a
  /// second position is the signal to generalise into a list.
  final PlateBand? rightBand;

  /// A small band layered on top of [rightBand] — a white capsule behind a
  /// short code (e.g. Kuwait's "C.D") sitting inside the coloured band.
  final PlateBand? innerBand;

  final List<PlateSlot> slots;
  final List<PlateRule> rules;
  final List<PlateLabel> labels;
  final List<PlateDecal> decals;

  /// Echoes of slot values. See [PlateMirror] — they never add to [slotCount].
  final List<PlateMirror> mirrors;

  final TextDirection textDirection;

  /// Applied via theme.copyWith when non-null.
  final double? borderWidthRatioOverride;

  /// The one ink this plate is printed in, for a design whose print colour is
  /// its own rather than the host's livery (Germany's green tax-exempt and red
  /// dealer plates). Null for the theme's ink.
  ///
  /// Replaces the whole monochrome set — glyphs, border, rules, completed-field
  /// outline — since a green plate has a green rim, not a black one.
  final Color? inkOverride;

  /// Groups of slot indices for the plain-text rendering, in [textDirection]
  /// reading order. Empty means one group per slot in index order.
  final List<PlateTextGroup> textGroups;

  int get slotCount => slots.length;

  /// The slot at [index], or null when [index] is outside the plate.
  PlateSlot? slotAt(int index) =>
      index >= 0 && index < slots.length ? slots[index] : null;

  /// [textGroups], or the one-group-per-slot fallback. Read this rather than
  /// reimplementing the fallback.
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

  PlateTextGroup? _groupNamed(String key) {
    for (final g in effectiveTextGroups) {
      if (g.key == key) return g;
    }
    return null;
  }

  /// The raw (unrendered) [values] of the group named [key], concatenated.
  /// Unset slots and an unknown key both give ''.
  String valueOfGroup(String key, List<String?> values) {
    final group = _groupNamed(key);
    if (group == null) return '';
    final buffer = StringBuffer();
    for (final i in group.indices) {
      buffer.write(i < values.length ? (values[i] ?? '') : '');
    }
    return buffer.toString();
  }

  /// The slot indices of the group named [key] — what a caller that *writes* a
  /// register needs. Empty for an unknown key.
  List<int> indicesOfGroup(String key) =>
      _groupNamed(key)?.indices ?? const <int>[];

  @override
  bool operator ==(Object other) => other is PlateSpec && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Debug-only consistency check: every rect fits the canvas, every mirror
/// echoes a real slot, registers are evenly pitched, and alphabet ids key
/// content one-to-one. Always returns true — call it inside an `assert(...)` so
/// it is stripped from release builds.
bool debugValidateSpec(PlateSpec spec) {
  void checkInCanvas(PlateBox b, String what) {
    assert(
      b.left >= 0 &&
          b.top >= 0 &&
          b.right <= spec.canvasWidth &&
          b.bottom <= spec.canvasHeight,
      '$what in spec "${spec.id}" has a rect outside the '
      'canvas (${spec.canvasWidth}x${spec.canvasHeight}).',
    );
  }

  for (var i = 0; i < spec.slots.length; i++) {
    checkInCanvas(spec.slots[i].box, 'PlateSlot $i');
  }

  for (var i = 0; i < spec.mirrors.length; i++) {
    final m = spec.mirrors[i];
    checkInCanvas(m.box, 'PlateMirror $i');
    assert(
      m.source >= 0 && m.source < spec.slots.length,
      'PlateMirror $i in spec "${spec.id}" echoes slot ${m.source}, which is '
      'not a slot index (0..${spec.slots.length - 1}).',
    );
  }

  final band = spec.rightBand;
  if (band != null) checkInCanvas(band.box, 'The right band');
  final inner = spec.innerBand;
  if (inner != null) checkInCanvas(inner.box, 'The inner band');

  // One rounded coordinate in a hand-written run of cells is invisible until
  // someone measures the plate. Only keyed groups of three or more cells on one
  // row have a pitch to be wrong about; a two-line layout splits a register
  // across bands, so it is exempt.
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

  // Within one spec an alphabet id must map one-to-one onto rendered content.
  // The key is characters AND glyphs: an alphabet accepting ASCII digits but
  // printing national numerals shares `latin.digits`' character list and means
  // something else entirely.
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

/// What an alphabet accepts, paired with how each accepted character renders.
String _contentKey(PlateAlphabet a) =>
    a.characters.map((c) => '$c=${a.render(c)}').join(' ');
