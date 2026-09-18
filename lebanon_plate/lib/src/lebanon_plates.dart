import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'lebanon_alphabets.dart';
import 'lebanon_colors.dart';
import 'lebanon_country.dart';

/// Lebanon's two plate geometries.
///
/// **Lebanon has two shapes and many colours**, which is the opposite of most
/// of the systems in this repo. A private car, a taxi, a consular car, a
/// diplomatic car, a driving school car and a tourist car are all the same
/// plate — a letter, then up to six digits, with a blue band carrying the cedar
/// and لبنان — printed on a different field. So this file is short and
/// `LebanonThemes` is long:
///
/// - [oneLine] — the long European-proportioned plate, band down the left edge.
/// - [twoLine] — the shorter, taller plate, band across the top.
///
/// Both are current and both are issued for the same vehicles; which one a car
/// carries is a matter of what fits its mounting, not of what it is for. There
/// is deliberately no enum selecting between them: a host picks the const it
/// wants to draw.
///
/// ### Usage is not a spec
///
/// ```dart
/// PlateCanvas(
///   spec: LebanonPlates.oneLine,
///   country: LebanonCountry.forUsage(usage), // the band's caption
///   theme: LebanonThemes.forUsage(usage),    // the field colour
/// )
/// ```
///
/// Each spec names [LebanonCountry.private] as its own `country`, so a caller
/// who passes no override gets the ordinary plate rather than a blank band.
///
/// ### Number length
///
/// Six digits is the standard, and [oneLine] / [twoLine] are the six-digit
/// plates. Shorter numbers exist — motorcycle `M` plates have been issued with
/// fewer than six digits since 2019, and an `MP` plate is numbered 1..128 — so
/// [oneLineOf] and [twoLineOf] build the same geometry with one to six digit
/// cells. The cells keep the six-digit pitch and stay left-aligned against the
/// letter, because that is what a short number on a full-size plate looks like;
/// they are not respaced to fill the face.
///
/// > **Swapping `spec:` on a live `PlateCanvas` carries the value across** as
/// > `PlateCanvas.onSpecChange` directs. With `byGroupKey` a change of length
/// > keeps the digits already entered and truncates only those the shorter
/// > plate has no slot for.
///
/// ### Geometry, and what is measured
///
/// Nothing here is measured from a standard. Both canvases are proportioned
/// from photographs of issued plates: the one-line face at 1040 x 220 (an
/// aspect ratio of 4.73, the European 520 x 110 proportion Lebanon's long plate
/// shares) and the two-line face at 520 x 288 (1.81). Zone positions were read
/// off those photographs as fractions and multiplied out; the cell heights were
/// then traded down for width, because core names no font family and the stock
/// face is far wider per glyph than the condensed type a real plate is printed
/// in. Every number is a calibration target.
///
/// ### One deviation worth knowing about
///
/// On a real one-line plate the band's text runs **vertically**, rotated
/// ninety degrees. `core_plate` has no rotation — not on a label, not on a
/// caption — so this package prints لبنان and the usage word horizontally
/// inside the band, scaled down to fit. It is the one place where these specs
/// knowingly do not reproduce the plate, and it is a core limitation rather
/// than a calibration gap: no number in this file would fix it.
abstract final class LebanonPlates {
  // ---------------------------------------------------------------------------
  // Shared. Declared once and referenced by both geometries, so a recalibration
  // is one edit.
  // ---------------------------------------------------------------------------

  /// Matches `LebanonThemes._borderWidthRatio`, and is repeated on every spec
  /// via [PlateSpec.borderWidthRatioOverride] so the geometry survives a host
  /// that supplies its own theme.
  static const double _borderRatio = 0.022; // CALIBRATE

  /// The standard number length, and the one [oneLine] and [twoLine] build.
  static const int standardDigits = 6;

  /// The number lengths [oneLineOf] and [twoLineOf] will build, shortest first.
  static const List<int> digitLengths = <int>[1, 2, 3, 4, 5, 6];

  // ---------------------------------------------------------------------------
  // The one-line plate — 1040 x 220.
  //
  //   band    x   0 .. 126  (0.121, run to the edges under the frame)
  //   letter  x 160 .. 270
  //   digits  x 320 .. 1000 on a 113-unit pitch
  // ---------------------------------------------------------------------------

  static const double _oneLineWidth = 1040;
  static const double _oneLineHeight = 220;

  /// The blue band down the left edge.
  ///
  /// It overlaps the frame on the three edges it touches rather than sitting
  /// flush at the border thickness: core clips panel paint back to the rounded
  /// face, so extending it under the frame kills the hairline seam a flush edge
  /// leaves once the whole canvas is scaled.
  ///
  /// The band reads top to bottom as a column: لبنان, then the cedar, then the
  /// usage word. `CountryPanel`'s own [PlatePanel.direction] (vertical, the
  /// default) lays the cedar above the caption; the top padding below leaves
  /// لبنان room to sit above both, still on the same blue box.
  static const PlatePanel _oneLinePanel = PlatePanel(
    box: PlateBox(0, 0, 126, _oneLineHeight),
    flagScale: 0.62,
    captionScale: 1.1, // CALIBRATE
    padding: EdgeInsets.fromLTRB(10, 86, 8, 10), // CALIBRATE
  );

  /// لبنان, printed at the top of the band, above the cedar.
  ///
  /// A [PlateLabel] rather than a caption line, because the country name does
  /// not vary with usage and the caption does: putting it here keeps one
  /// `PlateCountry` per usage instead of one per usage per geometry. Its colour
  /// is stated explicitly — a label defaults to the theme's ink, which is black
  /// on a white plate and would vanish into the blue band.
  static const List<PlateLabel> _oneLineLabels = <PlateLabel>[
    PlateLabel(text: 'لبنان', box: PlateBox(10, 14, 106, 56), glyphHeight: 50, color: LebanonColors.bandInk),
  ];

  /// The letter cell.
  ///
  /// Wider than a digit cell, and deliberately: `MP` is one character in this
  /// alphabet and two glyphs on the face (see `LebanonAlphabets.letters`), and
  /// a cell sized to a single capital would clip it.
  static const PlateSlot _oneLineLetter = PlateSlot(
    alphabet: LebanonAlphabets.letters,
    box: PlateBox(160, 34, 110, 152),
  );

  /// The two-line plate — 520 x 288.
  static const double _twoLineWidth = 520;
  static const double _twoLineHeight = 288;

  /// The band across the top reads left to right as a row: لبنان, then the
  /// cedar, then the usage word. The panel box spans the whole band, so the
  /// blue fill runs edge to edge; [PlatePanel.direction] is horizontal so
  /// `CountryPanel` lays the cedar and caption side by side instead of
  /// stacked, and the left padding reserves room for لبنان — its own
  /// [PlateLabel] — ahead of them.
  static const PlatePanel _twoLinePanel = PlatePanel(
    box: PlateBox(0, 0, _twoLineWidth, 88),
    flagScale: 0.85,
    // The caption's font size is unrelated to لبنان's `glyphHeight`, so left
    // at the default it renders visibly smaller; scaled up to roughly match.
    captionScale: 1.9, // CALIBRATE
    padding: EdgeInsets.fromLTRB(236, 16, 16, 16), // CALIBRATE
    direction: Axis.horizontal,
  );

  static const List<PlateLabel> _twoLineLabels = <PlateLabel>[
    PlateLabel(text: 'لبنان', box: PlateBox(16, 18, 130, 52), glyphHeight: 46, color: LebanonColors.bandInk),
  ];

  static const PlateSlot _twoLineLetter = PlateSlot(
    alphabet: LebanonAlphabets.letters,
    box: PlateBox(26, 116, 84, 140),
  );

  // ---------------------------------------------------------------------------
  // Slots and groups, per number length.
  //
  // The letter is always slot 0 and the digits follow it, so the text groups
  // are arithmetic rather than a table.
  // ---------------------------------------------------------------------------

  static List<PlateSlot> _oneLineSlots(int digits) => <PlateSlot>[
    _oneLineLetter,
    ...plateRegister(
      alphabet: LebanonAlphabets.digits,
      count: digits,
      left: 320,
      top: 34,
      width: 113,
      height: 152,
      pitch: 113,
    ),
  ];

  static List<PlateSlot> _twoLineSlots(int digits) => <PlateSlot>[
    _twoLineLetter,
    ...plateRegister(
      alphabet: LebanonAlphabets.digits,
      count: digits,
      left: 120,
      top: 116,
      width: 62,
      height: 140,
      pitch: 62,
    ),
  ];

  /// `letter` is slot 0; `serial` is everything after it.
  ///
  /// Two keys, and they are what `LebanonValidator` and
  /// `LebanonSerialGenerator` read the plate by — neither indexes a slot list
  /// directly, so a host that derives a spec with a different layout keeps both
  /// working.
  static List<PlateTextGroup> _groups(int digits) => <PlateTextGroup>[
    const PlateTextGroup(<int>[0], key: 'letter'),
    PlateTextGroup(<int>[for (int i = 1; i <= digits; i++) i], key: 'serial'),
  ];

  // ---------------------------------------------------------------------------
  // The plates.
  // ---------------------------------------------------------------------------

  /// The long plate with a six-digit number — the one to reach for first.
  static final PlateSpec oneLine = _oneLineSpec(standardDigits);

  /// The short, tall plate with a six-digit number.
  static final PlateSpec twoLine = _twoLineSpec(standardDigits);

  static PlateSpec _oneLineSpec(int digits) => PlateSpec(
    id: 'lb.oneLine$digits',
    country: LebanonCountry.private,
    canvasWidth: _oneLineWidth,
    canvasHeight: _oneLineHeight,
    panel: _oneLinePanel,
    slots: _oneLineSlots(digits),
    labels: _oneLineLabels,
    textGroups: _groups(digits),
    borderWidthRatioOverride: _borderRatio,
  );

  static PlateSpec _twoLineSpec(int digits) => PlateSpec(
    id: 'lb.twoLine$digits',
    country: LebanonCountry.private,
    canvasWidth: _twoLineWidth,
    canvasHeight: _twoLineHeight,
    panel: _twoLinePanel,
    slots: _twoLineSlots(digits),
    labels: _twoLineLabels,
    textGroups: _groups(digits),
    borderWidthRatioOverride: _borderRatio,
  );

  /// The one-line geometries, keyed by how many digits the number has. Built
  /// once, so `oneLineOf(6)` and a second `oneLineOf(6)` are the same instance
  /// and a `PlateCanvas` handed one twice does not see a spec change.
  static final Map<int, PlateSpec> oneLineGeometries = <int, PlateSpec>{
    for (final int d in digitLengths) d: d == standardDigits ? oneLine : _oneLineSpec(d),
  };

  /// The two-line geometries, keyed the same way.
  static final Map<int, PlateSpec> twoLineGeometries = <int, PlateSpec>{
    for (final int d in digitLengths) d: d == standardDigits ? twoLine : _twoLineSpec(d),
  };

  /// The one-line plate whose number has [digits] digits, or null when that is
  /// not a length this package builds.
  static PlateSpec? oneLineOf({required int digits}) => oneLineGeometries[digits];

  /// The two-line plate whose number has [digits] digits, or null.
  static PlateSpec? twoLineOf({required int digits}) => twoLineGeometries[digits];

  /// Both standard plates, for a gallery or a picker.
  static List<PlateSpec> get all => <PlateSpec>[oneLine, twoLine];
}
