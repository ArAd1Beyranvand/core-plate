import 'package:plate_core/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'india_alphabets.dart';
import 'india_country.dart';

/// Where the ink sits, in millimetres.
///
/// The canvas is the article's light-motor-vehicle plate, 500×120. The
/// colour-class artwork is drawn at 4.65:1 rather than 4.17:1, so each of its
/// plates (850×183 px) is normalised to 500×120 and x is read proportionally.
abstract final class _Layout {
  static const double width = 500;
  static const double height = 120;

  /// Ten cells at a 41.4 stride (ink lefts 48.2, 89.4, 131.2, 172.9, ...),
  /// the same on all five plates.
  static const double pitch = 41.4;

  /// Ink centre of the ten-cell row: x 48.2..450.6 → 249.4 on the plain
  /// plates; x 71.8..474.1 → 273 on the private plate, pushed right by the
  /// chakra badge.
  static const double centre = 250;
  static const double badgedCentre = 273;

  /// The widest a row may run when a format has too many cells for [pitch]:
  /// 20..480 clears the frame (5.6) and the corner arcs.
  static const double maxSpan = 460;

  /// Ink is 78.7 tall at y 21.0..99.7, centred 60.3. Reaching that would need
  /// a ~143 slot on a 120 plate, and the reference face is a condensed one far
  /// narrower than any fallback, so the cell width is what limits the glyph.
  /// A cell scales down a glyph wider than itself: at 66 the bold M came out
  /// at 0.845 of the other characters, so 55 is the largest slot where every
  /// capital fits the 41.4 cell. Ink lands ~29 tall (~37%). See README.
  static const double slotHeight = 55;

  /// A box centred 61.8 rendered ink centred 61.5, so 60.6 lands the ink on
  /// the reference's 60.3.
  static const double rowCentre = 60.6;

  /// The chakra hologram: x 14.7..42.4, y 21.0..52.5.
  static const PlateBox chakra = PlateBox(14.2, 21, 28.6, 31.5);

  /// IND: ink x 15.9..44.1, y 57.0..71.5, centred (30, 64.3). Sized to its
  /// 28 width, which the fallback face reaches before the 14.5 height: 19
  /// rendered 25.7 wide, so 20.5.
  static const PlateBox ind = PlateBox(10, 56, 40, 16.6);
  static const double indGlyph = 20.5;
}

/// One run of cells in a format: [count] editable cells in [alphabet] keyed
/// [key], or, for [_Run.fixed], printed characters no one types (BH, VA, TC).
class _Run {
  const _Run(this.key, this.alphabet, this.count) : text = '';
  const _Run.fixed(this.text) : key = '', alphabet = null, count = text.length;

  final String key;
  final PlateAlphabet? alphabet;
  final int count;
  final String text;
}

/// A plate: every format's cells evenly pitched in one row on the 500×120
/// face — the artwork prints no gaps between groups. A format with more cells
/// than fit at the measured pitch closes up to [_Layout.maxSpan] and its
/// glyphs shrink in proportion. [badge] adds the HSRP chakra and IND on the
/// left and moves the row right, as the private plate does.
PlateSpec _plate(String id, List<_Run> runs, {bool badge = false}) {
  final cells = runs.fold<int>(0, (n, r) => n + r.count);
  final pitch = (_Layout.maxSpan / cells).clamp(0.0, _Layout.pitch);
  final height = _Layout.slotHeight * pitch / _Layout.pitch;
  final top = _Layout.rowCentre - height / 2;
  var centre = badge ? _Layout.badgedCentre : _Layout.centre;
  // Keep a long badged row clear of the right frame.
  if (badge) centre = centre.clamp(0.0, 480 - cells * pitch / 2);
  var left = centre - cells * pitch / 2;

  final slots = <PlateSlot>[];
  final labels = <PlateLabel>[
    if (badge)
      const PlateLabel(
        text: 'IND',
        box: _Layout.ind,
        glyphHeight: _Layout.indGlyph,
      ),
  ];
  final groups = <PlateTextGroup>[];
  var prefix = '';
  for (final run in runs) {
    if (run.alphabet == null) {
      for (var i = 0; i < run.count; i++) {
        labels.add(
          PlateLabel(
            text: run.text[i],
            box: PlateBox(left + i * pitch, top, pitch, height),
            glyphHeight: height,
          ),
        );
      }
      prefix += run.text;
    } else {
      final first = slots.length;
      slots.addAll(
        plateRegister(
          alphabet: run.alphabet!,
          count: run.count,
          left: left,
          top: top,
          width: pitch,
          height: height,
        ),
      );
      groups.add(
        PlateTextGroup(
          <int>[for (var i = first; i < slots.length; i++) i],
          prefix: prefix,
          key: run.key,
        ),
      );
      prefix = '';
    }
    left += run.count * pitch;
  }

  return PlateSpec(
    id: id,
    country: IndiaCountry.india,
    canvasWidth: _Layout.width,
    canvasHeight: _Layout.height,
    noPanel: true,
    panel: const PlatePanel(box: PlateBox(0, 0, _Layout.width, _Layout.height)),
    decals: <PlateDecal>[
      if (badge)
        const PlateDecal(
          image: AssetImage(
            'assets/in_ashoka_chakra.png',
            package: 'india_plate',
          ),
          box: _Layout.chakra,
        ),
    ],
    labels: labels,
    slots: slots,
    textGroups: groups,
  );
}

const PlateAlphabet _d = IndiaAlphabets.digits;
const PlateAlphabet _l = IndiaAlphabets.letters;
const PlateAlphabet _s = IndiaAlphabets.series;

/// India's current (1989 Motor Vehicles Act, HSRP) plates.
///
/// One layout for every format; colour class is the theme (`IndiaThemes`), so
/// a yellow transport plate is [standard] in `IndiaThemes.transport`.
///
/// Fixed for the cell row: the RTO series is two letters, as on the artwork.
/// One- and three-letter series and the IOD mission type need a different
/// cell count and are not specced. Not implemented: the pre-1989 series, the
/// president's and governors' emblem plates, the laser-etched serial under
/// IND, and the two-wheeler and commercial-vehicle plate sizes.
abstract final class IndiaPlates {
  static const List<_Run> _registration = <_Run>[
    _Run('state', _l, 2),
    _Run('rto', _d, 2),
    _Run('series', _s, 2),
    _Run('number', _d, 4),
  ];

  /// MH 20 DV 2366, black on white with the chakra and IND.
  static final PlateSpec private = _plate(
    'in.private',
    _registration,
    badge: true,
  );

  /// The same registration without the badge, as the artwork draws the
  /// transport, rental and electric plates.
  static final PlateSpec standard = _plate('in.standard', _registration);

  /// 21 BH 2345 AA: year, BH, number, series.
  static final PlateSpec bharat = _plate('in.bharat', const <_Run>[
    _Run('year', _d, 2),
    _Run.fixed('BH'),
    _Run('number', _d, 4),
    _Run('series', _s, 2),
  ], badge: true);

  /// MH VA AA 0000: state, VA, series, number.
  static final PlateSpec vintage = _plate('in.vintage', const <_Run>[
    _Run('state', _l, 2),
    _Run.fixed('VA'),
    _Run('series', _s, 2),
    _Run('number', _d, 4),
  ], badge: true);

  /// ↑ 02 B 084821 H: broad arrow, year, class, serial, check letter.
  static final PlateSpec military = _plate('in.military', const <_Run>[
    _Run.fixed('↑'),
    _Run('year', _d, 2),
    _Run('class', _l, 1),
    _Run('number', _d, 6),
    _Run('check', _l, 1),
  ]);

  /// 52 CD 19: mission number, type, vehicle number. Both numbers are
  /// written without leading zeros, so short ones leave cells blank.
  static final PlateSpec diplomatic = _plate('in.diplomatic', const <_Run>[
    _Run('mission', _d, 3),
    _Run('type', _l, 2),
    _Run('number', _d, 4),
  ]);

  /// T 1123 KL 5986 K(K): T, month and year, state, number, series.
  static final PlateSpec temporary = _plate('in.temporary', const <_Run>[
    _Run.fixed('T'),
    _Run('date', _d, 4),
    _Run('state', _l, 2),
    _Run('number', _d, 4),
    _Run('series', _s, 2),
  ]);

  /// UP 16 C 0002 TC 0073: state, RTO, category, certificate, TC, vehicle.
  static final PlateSpec trade = _plate('in.trade', const <_Run>[
    _Run('state', _l, 2),
    _Run('rto', _d, 2),
    _Run('category', _l, 1),
    _Run('certificate', _d, 4),
    _Run.fixed('TC'),
    _Run('number', _d, 4),
  ]);

  static List<PlateSpec> get all => <PlateSpec>[
    private,
    standard,
    bharat,
    vintage,
    military,
    diplomatic,
    temporary,
    trade,
  ];
}
