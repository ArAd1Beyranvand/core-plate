import 'package:plate_core/plate_core.dart';

import 'sudan_alphabets.dart';
import 'sudan_colors.dart';
import 'sudan_country.dart';

/// Where the ink sits, in plate coordinates. Measured off the Wikipedia
/// artwork (`License_Plate_-_Sudan.png`) by normalising its frame to the
/// 320×160 mm the Arabic article gives. The artwork is drawn at 1.88, not 2.0,
/// so x is stretched proportionally; the photographs agree on the layout.
///
/// The plate, top to bottom:
///   * a name band — SUDAN left (ink x 16.6..114.1, y 13.9..30.9, cap 17.0),
///     السودان right (x 191.2..301.5, y 11.5..33.3);
///   * an ink rule edge to edge, y 40.6..43.6;
///   * a row split by the grey hologram strip (x 112.8..122.4, rule to
///     bottom edge): the class digit and state code on the left, the serial
///     on the right, each in Arabic over a small Latin echo.
///
/// Measured ink, which the goldens are checked against:
///   class digit  ٧   x 12.7..37.6   y 48.5..86.7
///   state code   خ   x 63.1..84.1   y 55.8..89.7
///   Latin 7KH        x 13.4..101.4  y 110.3..144.8 (cap 34.5)
///   serial  ١٠٣٤٦    x 134.5..296.4 y 57.0..109.7 (digit 51)
///   Latin serial     centres 149..292, y 122.4..141.2 (cap 18.2)
///
/// core sets a glyph at `0.72 * box height`, so ink is roughly half of the
/// number written here. Heights are tuned for Vazirmatn, the face the gallery
/// app draws in, and capped so no input box reaches into the row below.
abstract final class _Layout {
  static const double width = 320;
  static const double height = 160;

  static const double ruleY = 42.1;
  static const double ruleThickness = 3.0;
  static const double hologramLeft = 112.8;
  static const double hologramRight = 122.4;

  static const double nameTop = 6;
  static const double arabicNameTop = 3.2;
  static const double nameHeight = 33;
  static const double latinNameGlyph = 32.4;
  static const double arabicNameGlyph = 34;

  // Every input box is its own band: a field draws its outline along its
  // bottom edge, so a box reaching into the row below strikes through it.
  // Left cell: Arabic y 45..105, Latin 105..157. Serial: Arabic 45..117,
  // Latin 118..152.

  // The artwork centres the class digit on x 25.2 and the state code on
  // 73.6; each is 1.5 further out here, because ٨ and the two-letter ب ح are
  // both wider than ٧ and خ and would touch.
  static const double codeTop = 45;
  static const double codeHeight = 60;
  static const PlateBox classBox = PlateBox(5.5, codeTop, 36, codeHeight);
  static const PlateBox stateBox = PlateBox(44.5, codeTop, 61, codeHeight);

  // `KH` and `RS` are wider than their Arabic letter, so the state echo
  // overhangs its column on both sides.
  static const double codeEchoTop = 105;
  static const double codeEchoGlyph = 52;
  static const PlateBox classEchoBox = PlateBox(
    7,
    codeEchoTop,
    32,
    codeEchoGlyph,
  );
  static const PlateBox stateEchoBox = PlateBox(
    36,
    codeEchoTop,
    75,
    codeEchoGlyph,
  );

  // Five cells centred 149.4 .. 288.6 at 34.8 pitch; four share the span.
  static const double serialLeft = 132;
  static const double serialRight = 306;
  static const double serialTop = 45;
  static const double serialHeight = 72;

  static const double serialEchoTop = 118;
  static const double serialEchoGlyph = 34;
}

/// The 2009 bilingual plate, built for 2009 onward. Every photographed
/// livery — private, bus and taxi, commercial — is this one design; the
/// livery is the theme ([SudanThemes]), not the spec.
///
/// The value is `class · state · serial`, all stored in Latin: `7 KH 10346`.
/// Each slot prints in Arabic on the upper row and is echoed in Latin below;
/// both rows are editable and write the same value.
///
/// Not built: the newer printing where the hologram strip is replaced by
/// جمهورية السودان embossed upright in the same column (photographs only,
/// too small to measure), and the pre-2009 series.
abstract final class SudanPlates {
  static const PlateSection _background = PlateSection.rows(<PlatePart>[
    PlatePart(
      PlateSection.plain,
      end: _Layout.ruleY,
      divider: _Layout.ruleThickness,
    ),
    PlatePart(
      PlateSection.columns(<PlatePart>[
        PlatePart(PlateSection.plain, end: _Layout.hologramLeft),
        PlatePart(
          PlateSection.fill(PlateFill.color(SudanColors.hologram)),
          end: _Layout.hologramRight,
        ),
        PlatePart(PlateSection.plain),
      ]),
    ),
  ]);

  static const List<PlateLabel> _labels = <PlateLabel>[
    PlateLabel(
      text: 'SUDAN',
      box: PlateBox(16, _Layout.nameTop, 99, _Layout.nameHeight),
      glyphHeight: _Layout.latinNameGlyph,
    ),
    PlateLabel(
      text: 'السودان',
      box: PlateBox(186, _Layout.arabicNameTop, 121, _Layout.nameHeight),
      glyphHeight: _Layout.arabicNameGlyph,
    ),
  ];

  static PlateSpec _build({required String id, required int serialDigits}) {
    final double pitch =
        (_Layout.serialRight - _Layout.serialLeft) / serialDigits;
    return PlateSpec(
      id: id,
      country: SudanCountry.sudan,
      canvasWidth: _Layout.width,
      canvasHeight: _Layout.height,
      panel: const PlatePanel(box: PlateBox(0, 0, _Layout.width, 40)),
      noPanel: true,
      background: _background,
      labels: _labels,
      slots: <PlateSlot>[
        const PlateSlot(
          alphabet: SudanAlphabets.arabicDigits,
          box: _Layout.classBox,
        ),
        const PlateSlot(
          alphabet: SudanAlphabets.stateArabic,
          box: _Layout.stateBox,
        ),
        ...plateRegister(
          alphabet: SudanAlphabets.arabicDigits,
          count: serialDigits,
          left: _Layout.serialLeft,
          top: _Layout.serialTop,
          width: pitch,
          height: _Layout.serialHeight,
          pitch: pitch,
        ),
      ],
      mirrors: <PlateMirror>[
        const PlateMirror(
          source: 0,
          box: _Layout.classEchoBox,
          glyphHeight: _Layout.codeEchoGlyph,
          alphabet: SudanAlphabets.digits,
          editable: true,
        ),
        const PlateMirror(
          source: 1,
          box: _Layout.stateEchoBox,
          glyphHeight: _Layout.codeEchoGlyph,
          alphabet: SudanAlphabets.stateLatin,
          editable: true,
        ),
        ...plateEcho(
          sources: List<int>.generate(serialDigits, (i) => 2 + i),
          left: _Layout.serialLeft,
          top: _Layout.serialEchoTop,
          width: pitch,
          height: _Layout.serialEchoGlyph,
          alphabet: SudanAlphabets.digits,
          editable: true,
        ),
      ],
      textGroups: <PlateTextGroup>[
        const PlateTextGroup(<int>[0], key: 'class'),
        const PlateTextGroup(<int>[1], key: 'state'),
        PlateTextGroup(
          List<int>.generate(serialDigits, (i) => 2 + i),
          prefix: '-',
          key: 'serial',
        ),
      ],
    );
  }

  /// Five-digit serial: the artwork and most photographs.
  static final PlateSpec serial5 = _build(id: 'sd.2009.s5', serialDigits: 5);

  /// Four-digit serial: the bus-and-taxi photograph (`4KH 1209`).
  static final PlateSpec serial4 = _build(id: 'sd.2009.s4', serialDigits: 4);

  static final Map<int, PlateSpec> bySerialDigits = <int, PlateSpec>{
    4: serial4,
    5: serial5,
  };
}
