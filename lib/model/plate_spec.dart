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

/// A painted rule (e.g. the vertical divider on an Iranian car plate).
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

/// One visual group in the plain-text rendering of a plate (e.g. the "886"
/// digit triple on an Iranian car plate). [prefix] is prepended to the
/// rendered characters (e.g. 'IR ' before the province code).
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

  /// Stable identifier, e.g. 'ir.car'. Used for equality and persistence.
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

  /// The slot at [index], or null when [index] is outside the plate.
  PlateSlot? slotAt(int index) =>
      index >= 0 && index < slots.length ? slots[index] : null;

  /// The slot focus advances to from [index], or null at the end of the plate.
  int? nextIndex(int index) =>
      index >= 0 && index + 1 < slots.length ? index + 1 : null;

  /// The slot focus steps back to from [index], or null at the start.
  int? previousIndex(int index) =>
      index > 0 && index < slots.length ? index - 1 : null;

  /// Concatenates [values] at the indices of the text group with the given
  /// [key], unset slots rendering as ''. Returns '' if no group has that key.
  String valueOfGroup(String key, List<String?> values) {
    for (final g in textGroups) {
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

  return true;
}

/// The catalogue of known plate designs.
///
/// Adding a new plate type — a new country, a new vehicle class, a different
/// alphabet, slot count, reading direction, or divider layout — requires only a
/// new `const PlateSpec` declaration here. No widget file needs to be touched:
/// the widgets read geometry, alphabets, direction, rules, and labels entirely
/// from the spec. If adding a plate ever forces a widget edit, the abstraction
/// has leaked and should be fixed at the widget, not worked around here.
class PlateSpecs {
  const PlateSpecs._();

  static const PlateSpec irCar = PlateSpec(
    id: 'ir.car',
    country: PlateCountry.iran,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: PlatePanel(
      // Overlap the border on the three touching edges (left/top/bottom)
      // instead of sitting flush at the border thickness (0.04 * canvasHeight =
      // 4.4). The panel is clipped back to the rounded plate face by
      // _PlateFaceClipper, so extending it under the frame just makes the blue
      // paint right up to the clip boundary — killing the thin white seam that
      // a flush edge leaves when the FittedBox scale lands the panel edge and
      // the border edge on different physical pixels. Right edge (56.4) stays
      // interior and is unchanged.
      box: PlateBox(0, 0, 56.4, 110),
    ),
    textDirection: TextDirection.rtl,
    slots: [
      PlateSlot(alphabet: PlateAlphabet.persianDigits, box: PlateBox(65, 17, 47, 76)),
      PlateSlot(alphabet: PlateAlphabet.persianDigits, box: PlateBox(120, 17, 47, 76)),
      PlateSlot(alphabet: PlateAlphabet.persianPlateLetters, box: PlateBox(175, 17, 55, 76)),
      PlateSlot(alphabet: PlateAlphabet.persianDigits, box: PlateBox(238, 17, 47, 76)),
      PlateSlot(alphabet: PlateAlphabet.persianDigits, box: PlateBox(293, 17, 47, 76)),
      PlateSlot(alphabet: PlateAlphabet.persianDigits, box: PlateBox(348, 17, 47, 76)),
      PlateSlot(alphabet: PlateAlphabet.persianDigits, box: PlateBox(428, 40, 32, 52)),
      PlateSlot(alphabet: PlateAlphabet.persianDigits, box: PlateBox(466, 40, 32, 52)),
    ],
    rules: [
      // The province divider runs the full height of the plate face (top edge
      // to bottom edge), meeting the border at both ends — no empty gaps.
      PlateRule(box: PlateBox(404, 4.4, 5, 101.2)),
    ],
    labels: [
      PlateLabel(text: 'ایران', box: PlateBox(412, 18, 103, 16), glyphHeight: 16),
    ],
    textGroups: [
      PlateTextGroup([0, 1]),
      PlateTextGroup([2]),
      PlateTextGroup([3, 4, 5]),
      PlateTextGroup([6, 7], prefix: 'IR '),
    ],
  );

  static const PlateSpec irBicycle = PlateSpec(
    id: 'ir.bicycle',
    country: PlateCountry.iran,
    canvasWidth: 175,
    canvasHeight: 110,
    panel: PlatePanel(
      // Overlap the border on the two touching edges (left/top) instead of
      // sitting flush at the border thickness (0.05 * canvasHeight = 5.5); the
      // panel is clipped back to the plate face, so this kills the thin white
      // seam a flush edge leaves. See irCar. Right (63.7) and bottom (53.7)
      // edges are interior and unchanged.
      //
      // Panel width is sized to wrap the flag (the widest element) plus the
      // left/right margins below, instead of a slack fraction: flagScale is 1.0
      // so the flag fills its box exactly and panelWidth = padding + flag
      // width.
      box: PlateBox(0, 0, 47, 53.7),
      flagScale: 1.0,
      captionScale: 0.25,
      // Bigger left margin than top/bottom: matches a real bicycle plate's
      // panel, where the flag+caption block sits clear of the frame on the
      // left but only needs breathing room, not a deep inset, top and bottom.
      // Extra margin all around keeps the smaller flag/caption clear of the
      // panel edges instead of crowding the blue block.
      padding: EdgeInsets.fromLTRB(15, 16, 6, 6),
    ),
    textDirection: TextDirection.rtl,
    borderWidthRatioOverride: 0.05,
    slots: [
      PlateSlot(alphabet: PlateAlphabet.persianDigits, box: PlateBox(74, 13, 22, 36)),
      PlateSlot(alphabet: PlateAlphabet.persianDigits, box: PlateBox(104, 13, 22, 36)),
      PlateSlot(alphabet: PlateAlphabet.persianDigits, box: PlateBox(134, 13, 22, 36)),
      PlateSlot(alphabet: PlateAlphabet.persianDigits, box: PlateBox(8, 58, 27, 44)),
      PlateSlot(alphabet: PlateAlphabet.persianDigits, box: PlateBox(41, 58, 27, 44)),
      PlateSlot(alphabet: PlateAlphabet.persianDigits, box: PlateBox(74, 58, 27, 44)),
      PlateSlot(alphabet: PlateAlphabet.persianDigits, box: PlateBox(107, 58, 27, 44)),
      PlateSlot(alphabet: PlateAlphabet.persianDigits, box: PlateBox(140, 58, 27, 44)),
    ],
  );

  /// A standard German car plate (e.g. "DA·X1953"): a district code of Latin
  /// letters, then the two round stickers (vehicle-inspection and federal-state
  /// seal), then the identifier's Latin letter and serial digits — read
  /// left-to-right, with no dividers and no printed labels. The stickers are
  /// [PlateDecal]s that sit in the gap between the two character groups.
  static const PlateSpec deCar = PlateSpec(
    id: 'de.car',
    country: PlateCountry.germany,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: PlatePanel(
      // Overlap the border on the three touching edges — see irCar.
      box: PlateBox(0, 0, 56.4, 110),
    ),
    textDirection: TextDirection.ltr,
    slots: [
      // District code, e.g. "DA".
      PlateSlot(alphabet: PlateAlphabet.latinUppercase, box: PlateBox(64, 17, 52, 76)),
      PlateSlot(alphabet: PlateAlphabet.latinUppercase, box: PlateBox(122, 17, 52, 76)),
      // Identifier: one letter then the serial digits, e.g. "X1953".
      PlateSlot(alphabet: PlateAlphabet.latinUppercase, box: PlateBox(230, 17, 52, 76)),
      PlateSlot(alphabet: PlateAlphabet.latinDigits, box: PlateBox(288, 17, 46, 76)),
      PlateSlot(alphabet: PlateAlphabet.latinDigits, box: PlateBox(338, 17, 46, 76)),
      PlateSlot(alphabet: PlateAlphabet.latinDigits, box: PlateBox(388, 17, 46, 76)),
      PlateSlot(alphabet: PlateAlphabet.latinDigits, box: PlateBox(438, 17, 46, 76)),
    ],
    decals: [
      // Stacked in the gap between the district code and the identifier: the
      // orange TÜV inspection sticker on top, the federal-state seal below.
      PlateDecal(
        image: AssetImage('assets/de_inspection_sticker.png', package: 'plate_number'),
        box: PlateBox(184, 14, 38, 38),
      ),
      PlateDecal(
        image: AssetImage('assets/de_state_seal.png', package: 'plate_number'),
        box: PlateBox(184, 54, 38, 38),
      ),
    ],
    textGroups: [
      PlateTextGroup([0, 1], key: 'district'),
      PlateTextGroup([2], key: 'letters'),
      PlateTextGroup([3, 4, 5, 6], key: 'serial'),
    ],
  );
}
