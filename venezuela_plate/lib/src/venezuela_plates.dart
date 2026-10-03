import 'dart:math' as math;

import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'venezuela_alphabets.dart';
import 'venezuela_colors.dart';
import 'venezuela_country.dart';
import 'venezuela_themes.dart';

/// Where the ink sits on the 2008 plate, in millimetres.
///
/// The article gives 300×150; that is the canvas. There is no clean artwork,
/// so everything is measured off the three frontal photographs (AB174SK Lara,
/// AA064ST Trujillo, AE328KG Carabobo), each perspective-corrected so the outer
/// edge of its frame maps to 300×150. Figures are the mean across photographs.
abstract final class _Layout {
  static const double width = 300;
  static const double height = 150;

  /// The flag's boundaries where they cross x = 150: white/yellow 49.1 (Lara);
  /// yellow/blue 84.0, 82.6, 85.8; blue/red 119.4, 116.7, 120.1.
  static const List<double> flagStops = <double>[49, 84, 119];

  /// Each boundary falls 24.6–31.1 mm over the 276 mm between x = 12 and
  /// x = 288, rising to the right; 27.7 is the mean. The real bands fan out
  /// slightly and wave; a stripes fill has one angle for all of them.
  static final double flagAngle = math.atan(27.7 / 276);

  /// The white airbrushed over the flag. Saturation along each band is
  /// full only at the ends — red at x <= 70 and x >= 230, yellow and blue
  /// within ~20 of the edge — so the ellipse is centred high, where it is
  /// widest across the upper bands. Pale over saturated gives 0.50, 0.48
  /// and 0.50 for the three bands; against the goldens 0.6 matches the
  /// middle better (red saturation 62 in the photographs).
  static const PlateFog flagFog = PlateFog(
    center: Offset(150, 40),
    radii: Size(150, 130),
    opacity: 0.6,
    plateau: 0.8,
  );

  /// Serial ink is 74 tall (73.8, 74.5) at y 37..111, cells at a 38.9 stride
  /// (38.8, 39.4, 38.6) centred on x 150. Reaching 74 would need a 141 slot,
  /// but the plate's face is far narrower than any fallback, so the cell
  /// width is what limits the glyph. An editable cell does not scale its text
  /// down, so the slot is the height whose bold cap fits the 38.9 cell —
  /// 0.72 x 80 = 57.6 font, ~37 wide. Ink lands ~41 tall (~55%). See README.
  static const double pitch = 38.9;
  static const double serialLeft = 150 - 3.5 * pitch;
  static const double slotTop = 74.2 - slotHeight / 2;
  static const double slotHeight = 80;

  /// REPUBLICA BOLIVARIANA DE VENEZUELA: caps 11.8 (Lara) and 13.8
  /// (Trujillo) tall at y 16.8..28.5, x 31.2..272.8 — centred (151.5, 22.6),
  /// 243 wide. The fallback face is wider than the plate's, so the glyph is
  /// sized to the width: ink lands 7.6 tall, ~60% of reference.
  static const PlateBox caption = PlateBox(21.5, 12.6, 260, 20);
  static const double captionGlyph = 14.2;

  /// The state name: caps 16.0 (LARA) and 17.8 (CARABOBO) at y 123..139,
  /// centred (150, 131.2). Every state prints at one height. Renders 16.5
  /// tall; DISTRITO CAPITAL, the longest, is 230 wide and clears the frame.
  static const PlateBox state = PlateBox(20, 121, 260, 20.4);
  static const double stateGlyph = 31;
}

/// The 2008 plate: [car].
///
/// One design for every ordinary and special category. The categories differ
/// only in which of the first six cells are letters (see
/// `VenezuelaValidator`), so the cells take either. The last letter is the
/// state, and the state name printed under the serial is a mirror of it
/// through [VenezuelaAlphabets.stateName] — it follows whatever is typed.
///
/// The flag is the background: white, then yellow, blue and red bands rising
/// across the lower plate, under the characters.
///
/// Not implemented: the 1955–2008 series; the motorcycle plate (smaller, and
/// the article gives no size); the yellow provisional plate and the Free Port
/// plate, which are different designs; the eight stars on the blue band and
/// the VENEZUELA microprint on the characters.
abstract final class VenezuelaPlates {
  static final PlateSpec car = PlateSpec(
    id: 've.car',
    country: VenezuelaCountry.venezuela,
    canvasWidth: _Layout.width,
    canvasHeight: _Layout.height,
    noPanel: true,
    panel: const PlatePanel(box: PlateBox(0, 0, _Layout.width, _Layout.height)),
    background: PlateSection.fill(
      PlateFill.stripes(
        const <PlateFill>[
          PlateFill.field,
          PlateFill.color(VenezuelaColors.yellow),
          PlateFill.color(VenezuelaColors.blue),
          PlateFill.color(VenezuelaColors.red),
        ],
        stops: _Layout.flagStops,
        angle: _Layout.flagAngle,
        fog: _Layout.flagFog,
      ),
    ),
    labels: const <PlateLabel>[
      PlateLabel(
        text: 'REPUBLICA BOLIVARIANA DE VENEZUELA',
        box: _Layout.caption,
        glyphHeight: _Layout.captionGlyph,
        color: VenezuelaColors.caption,
      ),
    ],
    slots: <PlateSlot>[
      ...plateRegister(
        alphabet: VenezuelaAlphabets.serial,
        count: 6,
        left: _Layout.serialLeft,
        top: _Layout.slotTop,
        width: _Layout.pitch,
        height: _Layout.slotHeight,
      ),
      ...plateRegister(
        alphabet: VenezuelaAlphabets.state,
        count: 1,
        left: _Layout.serialLeft + 6 * _Layout.pitch,
        top: _Layout.slotTop,
        width: _Layout.pitch,
        height: _Layout.slotHeight,
      ),
    ],
    mirrors: const <PlateMirror>[
      PlateMirror(
        source: 6,
        box: _Layout.state,
        glyphHeight: _Layout.stateGlyph,
        alphabet: VenezuelaAlphabets.stateName,
      ),
    ],
    textGroups: const <PlateTextGroup>[
      PlateTextGroup(<int>[0, 1, 2, 3, 4, 5], key: 'serial'),
      PlateTextGroup(<int>[6], key: 'state'),
    ],
  );

  static List<PlateSpec> get all => <PlateSpec>[car];

  /// The theme every spec here is drawn in.
  static const PlateTheme theme = VenezuelaThemes.standard;
}
