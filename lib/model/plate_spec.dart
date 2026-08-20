import 'package:flutter/widgets.dart';

import 'plate_alphabet.dart';
import 'plate_country.dart';

/// One editable position on a plate.
@immutable
class PlateSlot {
  const PlateSlot({
    required this.index,
    required this.alphabet,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.next,
  });

  /// Position in PlateNumber.values.
  final int index;

  final PlateAlphabet alphabet;

  /// Plate-space geometry. [height] doubles as the slot height passed to the
  /// glyph style — do not add a separate field for it.
  final double left, top, width, height;

  /// The index focus advances to when this slot fills. Null unfocuses.
  final int? next;
}

/// A painted rule (e.g. the vertical divider on an Iranian car plate).
@immutable
class PlateRule {
  const PlateRule({required this.left, required this.top,
                   required this.width, required this.height});

  final double left, top, width, height;
}

/// A fixed image painted on the plate face at a set position — a sticker or
/// badge that sits *between* character groups rather than inside a slot (e.g.
/// the German inspection and federal-state stickers). Like [PlateLabel] and
/// [PlateRule], it is pure plate-space geometry plus content: the widget layer
/// paints whatever [image] provides, so adding one never means a new widget.
@immutable
class PlateDecal {
  const PlateDecal({
    required this.image,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// The image to paint, e.g. an `AssetImage(..., package: 'plate_number')`.
  final ImageProvider image;

  /// Plate-space geometry, in the same coordinate system as slots and rules.
  final double left, top, width, height;
}

/// Fixed text printed on the plate face (e.g. "ایران").
@immutable
class PlateLabel {
  const PlateLabel({
    required this.text, required this.left, required this.top,
    required this.width, required this.height, required this.glyphHeight,
  });

  final String text;
  final double left, top, width, height;

  /// Passed to the glyph style as the slot height.
  final double glyphHeight;
}

/// One visual group in the plain-text rendering of a plate (e.g. the "886"
/// digit triple on an Iranian car plate). [prefix] is prepended to the
/// rendered characters (e.g. 'IR ' before the province code).
@immutable
class PlateTextGroup {
  const PlateTextGroup(this.indices, {this.prefix = ''});
  final List<int> indices;
  final String prefix;
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
    required this.panelLeft,
    required this.panelTop,
    required this.panelWidth,
    required this.panelHeight,
    required this.slots,
    this.rules = const <PlateRule>[],
    this.labels = const <PlateLabel>[],
    this.decals = const <PlateDecal>[],
    this.textDirection = TextDirection.ltr,
    this.borderWidthRatioOverride,
    this.flagScale = 1.0,
    this.captionScale = 1.0,
    this.panelPadding,
    this.textGroups = const <PlateTextGroup>[],
  });

  /// Stable identifier, e.g. 'ir.car'. Used for equality and persistence.
  final String id;

  final PlateCountry country;

  final double canvasWidth, canvasHeight;
  final double panelLeft, panelTop, panelWidth, panelHeight;

  final List<PlateSlot> slots;
  final List<PlateRule> rules;
  final List<PlateLabel> labels;
  final List<PlateDecal> decals;

  final TextDirection textDirection;

  /// Applied via theme.copyWith when non-null.
  final double? borderWidthRatioOverride;

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
  final EdgeInsets? panelPadding;

  /// Groups of slot indices for the plain-text rendering of the plate, listed
  /// in [textDirection] reading order. Empty means each slot is its own
  /// group, in index order.
  final List<PlateTextGroup> textGroups;

  /// How many values this plate stores. Derived, never hard-coded.
  int get slotCount => slots.length;

  /// The slot at [index], or null.
  PlateSlot? slotAt(int index) {
    for (final s in slots) { if (s.index == index) return s; }
    return null;
  }

  @override
  bool operator ==(Object other) => other is PlateSpec && other.id == id;

  @override
  int get hashCode => id.hashCode;
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
    // Overlap the border on the three touching edges (left/top/bottom) instead
    // of sitting flush at the border thickness (0.04 * canvasHeight = 4.4). The
    // panel is clipped back to the rounded plate face by _PlateFaceClipper, so
    // extending it under the frame just makes the blue paint right up to the
    // clip boundary — killing the thin white seam that a flush edge leaves when
    // the FittedBox scale lands the panel edge and the border edge on different
    // physical pixels. Right edge (56.4) stays interior and is unchanged.
    panelLeft: 0,
    panelTop: 0,
    panelWidth: 56.4,
    panelHeight: 110,
    textDirection: TextDirection.rtl,
    slots: [
      PlateSlot(index: 0, alphabet: PlateAlphabet.persianDigits, left: 65, top: 17, width: 47, height: 76, next: 1),
      PlateSlot(index: 1, alphabet: PlateAlphabet.persianDigits, left: 120, top: 17, width: 47, height: 76, next: 2),
      PlateSlot(index: 2, alphabet: PlateAlphabet.persianPlateLetters, left: 175, top: 17, width: 55, height: 76, next: 3),
      PlateSlot(index: 3, alphabet: PlateAlphabet.persianDigits, left: 238, top: 17, width: 47, height: 76, next: 4),
      PlateSlot(index: 4, alphabet: PlateAlphabet.persianDigits, left: 293, top: 17, width: 47, height: 76, next: 5),
      PlateSlot(index: 5, alphabet: PlateAlphabet.persianDigits, left: 348, top: 17, width: 47, height: 76, next: 6),
      PlateSlot(index: 6, alphabet: PlateAlphabet.persianDigits, left: 428, top: 40, width: 32, height: 52, next: 7),
      PlateSlot(index: 7, alphabet: PlateAlphabet.persianDigits, left: 466, top: 40, width: 32, height: 52, next: null),
    ],
    rules: [
      // The province divider runs the full height of the plate face (top edge
      // to bottom edge), meeting the border at both ends — no empty gaps.
      PlateRule(left: 404, top: 4.4, width: 5, height: 101.2),
    ],
    labels: [
      PlateLabel(text: 'ایران', left: 412, top: 18, width: 103, height: 16, glyphHeight: 16),
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
    // Overlap the border on the two touching edges (left/top) instead of
    // sitting flush at the border thickness (0.07 * canvasHeight = 7.7); the
    // panel is clipped back to the plate face, so this kills the thin white
    // seam a flush edge leaves. See irCar. Right (63.7) and bottom (53.7) edges
    // are interior and unchanged.
    panelLeft: 0,
    panelTop: 0,
    // Panel width is sized to wrap the flag (the widest element) plus the
    // left/right margins below, instead of a slack fraction: flagScale is 1.0
    // so the flag fills its box exactly and panelWidth = padding + flag width.
    panelWidth: 47,
    panelHeight: 53.7,
    textDirection: TextDirection.rtl,
    borderWidthRatioOverride: 0.07,
    flagScale: 1.0,
    captionScale: 0.25,
    // Bigger left margin than top/bottom: matches a real bicycle plate's
    // panel, where the flag+caption block sits clear of the frame on the
    // left but only needs breathing room, not a deep inset, top and bottom.
    // Extra margin all around keeps the smaller flag/caption clear of the
    // panel edges instead of crowding the blue block.
    panelPadding: EdgeInsets.fromLTRB(15, 16, 6, 6),
    slots: [
      PlateSlot(index: 0, alphabet: PlateAlphabet.persianDigits, left: 74, top: 13, width: 22, height: 36, next: 1),
      PlateSlot(index: 1, alphabet: PlateAlphabet.persianDigits, left: 104, top: 13, width: 22, height: 36, next: 2),
      PlateSlot(index: 2, alphabet: PlateAlphabet.persianDigits, left: 134, top: 13, width: 22, height: 36, next: 3),
      PlateSlot(index: 3, alphabet: PlateAlphabet.persianDigits, left: 8, top: 58, width: 27, height: 44, next: 4),
      PlateSlot(index: 4, alphabet: PlateAlphabet.persianDigits, left: 41, top: 58, width: 27, height: 44, next: 5),
      PlateSlot(index: 5, alphabet: PlateAlphabet.persianDigits, left: 74, top: 58, width: 27, height: 44, next: 6),
      PlateSlot(index: 6, alphabet: PlateAlphabet.persianDigits, left: 107, top: 58, width: 27, height: 44, next: 7),
      PlateSlot(index: 7, alphabet: PlateAlphabet.persianDigits, left: 140, top: 58, width: 27, height: 44, next: null),
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
    // Overlap the border on the three touching edges — see irCar.
    panelLeft: 0,
    panelTop: 0,
    panelWidth: 56.4,
    panelHeight: 110,
    textDirection: TextDirection.ltr,
    slots: [
      // District code, e.g. "DA".
      PlateSlot(index: 0, alphabet: PlateAlphabet.latinUppercase, left: 64, top: 17, width: 52, height: 76, next: 1),
      PlateSlot(index: 1, alphabet: PlateAlphabet.latinUppercase, left: 122, top: 17, width: 52, height: 76, next: 2),
      // Identifier: one letter then the serial digits, e.g. "X1953".
      PlateSlot(index: 2, alphabet: PlateAlphabet.latinUppercase, left: 230, top: 17, width: 52, height: 76, next: 3),
      PlateSlot(index: 3, alphabet: PlateAlphabet.latinDigits, left: 288, top: 17, width: 46, height: 76, next: 4),
      PlateSlot(index: 4, alphabet: PlateAlphabet.latinDigits, left: 338, top: 17, width: 46, height: 76, next: 5),
      PlateSlot(index: 5, alphabet: PlateAlphabet.latinDigits, left: 388, top: 17, width: 46, height: 76, next: 6),
      PlateSlot(index: 6, alphabet: PlateAlphabet.latinDigits, left: 438, top: 17, width: 46, height: 76, next: null),
    ],
    decals: [
      // Stacked in the gap between the district code and the identifier: the
      // orange TÜV inspection sticker on top, the federal-state seal below.
      PlateDecal(
        image: AssetImage('assets/de_inspection_sticker.png', package: 'plate_number'),
        left: 184, top: 14, width: 38, height: 38,
      ),
      PlateDecal(
        image: AssetImage('assets/de_state_seal.png', package: 'plate_number'),
        left: 184, top: 54, width: 38, height: 38,
      ),
    ],
    textGroups: [
      PlateTextGroup([0, 1]),
      PlateTextGroup([2]),
      PlateTextGroup([3, 4, 5, 6]),
    ],
  );
}
