import 'dart:math' show max, min;

import 'package:flutter/widgets.dart' show Color;

import 'package:plate_core/plate_core.dart';

import 'package:plate_alphabet/plate_alphabet.dart';
import 'vietnam_colors.dart';
import 'vietnam_country.dart';
import 'vietnam_missions.dart';

/// Where the ink sits on a Vietnamese plate, in millimetres.
///
/// **Civil, temporary and foreign plates** are the sizes QCVN 08:2024/BCA
/// §1.2–1.3 gives — short 330×165, long 520×110, motorcycle 190×140 — and the
/// ink was measured off its drawing and the Commons template
/// (`2020 Vietnamese vehicle reg. plate - Cars.jpg`, `…Motorbikes.jpg`,
/// `2020 Vietnam temporary…png`, `В’ЄТНАМСЬКИЙ НОМЕР QT.gif`), each plate
/// rectangle normalised to those millimetres:
///
/// * car, both shapes: ink 63 tall (the regulation says 63), glyphs 38 wide
///   at a 48 pitch (its 10 mm gap). Long `30F-256.58`: ink y 23.1..86.4,
///   `30F` x 49..182, dash 193..211 (18), `256` 221..355, dot 365..375 (a
///   9.5 square on the baseline), `58` 385..471 — content centred. Short:
///   row 1 y 12.2..74.9, row 2 y 90.1..152.8, `30F` 98..232, `256.58` 40..290
///   with the dot 185..194.
/// * motorcycle `29-AB`/`226.58`: rows y 9..63 and 74..127, ink 54 (the
///   regulation says 55). Row 1 glyph pitch 28, dash 12×8 at mid-height; row
///   2 pitch 32, dot 7.5.
/// * foreign long `27-QT-547-45` (the artwork is 4.28:1, so x is normalised
///   to 520): ink 21..497, glyph pitch 44.5, dash cell 27.8.
/// * the 4 mm rim is 3.9 measured on both car plates.
///
/// **Military plates** are not in QCVN 08 and the article gives no millimetres.
/// They are measured off the 2021 Ministry of National Defence scan
/// (`2021 Vietnam Ministry of National Defence … (colorized).jpg`), so only
/// their *aspect ratios* are the artwork's: short 1.39 (drawn 280×200), motorcycle
/// 1.34 (190×140, the civil size) and long 5.32 (drawn 532×100). The scan's
/// proportions are not guaranteed to be the plates'. Its ink is 75–80% of the
/// plate's height.
///
/// **Under-height ink, accepted.** `glyphStyle` prints ink at ~0.52 of the slot
/// and a slot cannot leave the canvas, so a 63 mm glyph would need a 120 mm
/// slot on a 110 mm plate. Rows are as tall as the canvas lets them be, with
/// each row's centre kept on the reference ink's (a short plate's rows are
/// nudged 3 mm toward the middle): ink is ~90% of the reference on the long
/// plate, ~78% on the short and ~70–78% on the motorcycle. `plate_core`
/// is unchanged. The screw hole and the Công an hiệu security mark are not
/// drawn.
class _Row {
  const _Row({
    required this.top,
    required this.height,
    required this.pitch,
    this.dashCell = 28.5,
    this.dashWidth = 18,
    this.dashHeight = 9.5,
    this.dotCell = 20,
    this.dotSize = 9.5,
  });

  /// The slot box. The glyph is centred in it, so the marks are placed from it.
  final double top, height;

  /// The ink's centre and baseline: `glyphStyle` prints a cap ~0.525 of the box.
  double get inkCentre => top + height / 2;
  double get inkBottom => inkCentre + 0.525 * height / 2;

  /// The slot's width. A glyph is centred in its box and shrinks to its width.
  /// The plates print a condensed face and `glyphStyle` a regular one, whose
  /// digits are ~0.5 of the box height wide, so a box as narrow as the pitch
  /// would shrink the ink. Boxes are widened to fit a digit, up to 15% over the
  /// pitch (past that the glyphs touch) and overlap their neighbours; their
  /// centres keep the pitch.
  double get cellWidth => min(max(pitch, 0.5 * height), 1.15 * pitch);

  /// A glyph's cell pitch, the dash's and dot's cell, and their ink.
  final double pitch, dashCell, dashWidth, dashHeight, dotCell, dotSize;
}

class _Geo {
  const _Geo(this.width, this.height, this.rows, {this.rim = 3.9});

  final double width, height;
  final List<_Row> rows;

  /// Rim thickness in mm; 0 for a plate printed without one.
  final double rim;
}

abstract final class _Layout {
  static const _Geo longCar = _Geo(520, 110, <_Row>[
    _Row(top: 1, height: 108, pitch: 48),
  ]);

  static const _Geo longForeign = _Geo(520, 110, <_Row>[
    _Row(top: 1, height: 108, pitch: 44.5, dashCell: 27.8, dashWidth: 16),
  ]);

  static const _Geo shortCar = _Geo(330, 165, <_Row>[
    _Row(top: 0, height: 94, pitch: 48),
    _Row(top: 71, height: 94, pitch: 48),
  ]);

  static const _Geo motorcycle = _Geo(190, 140, <_Row>[
    _Row(
      top: 0,
      height: 72,
      pitch: 28,
      dashCell: 26.5,
      dashWidth: 12,
      dashHeight: 8,
    ),
    _Row(top: 60, height: 80, pitch: 32.2, dotCell: 13, dotSize: 7.5),
  ]);

  static const _Geo longMilitary = _Geo(532, 100, <_Row>[
    _Row(
      top: 2.2,
      height: 97.6,
      pitch: 54.5,
      dashCell: 80,
      dashWidth: 25,
      dashHeight: 8,
    ),
  ], rim: 0);

  static const _Geo shortMilitary = _Geo(280, 200, <_Row>[
    _Row(
      top: 0,
      height: 109,
      pitch: 48,
      dashCell: 48,
      dashWidth: 21,
      dashHeight: 8,
    ),
    _Row(
      top: 93.4,
      height: 106.6,
      pitch: 48,
      dashCell: 48,
      dashWidth: 21,
      dashHeight: 8,
    ),
  ], rim: 0);

  static const _Geo motorcycleMilitary = _Geo(190, 140, <_Row>[
    _Row(top: 0, height: 75, pitch: 31),
    _Row(top: 65, height: 75, pitch: 37.5),
  ], rim: 0);
}

/// One piece of a row: a run of [count] cells over [alphabet], or a printed
/// [mark] — `-` or `.`. Runs with the same [key] form one text group, in order.
class _Part {
  const _Part.run(
    PlateAlphabet this.alphabet,
    this.count,
    String this.key, {
    this.color,
  }) : mark = null;
  const _Part.dash()
    : alphabet = null,
      count = 0,
      key = null,
      color = null,
      mark = '-';
  const _Part.dot()
    : alphabet = null,
      count = 0,
      key = null,
      color = null,
      mark = '.';

  final PlateAlphabet? alphabet;
  final int count;
  final String? key;
  final Color? color;
  final String? mark;
}

/// Vietnam's plate geometries. Colour is the theme, not the spec:
/// `VietnamThemes.white` (private, diplomatic, temporary), `yellow`
/// (commercial), `blue` (state) and `red` (military).
///
/// * [long] / [short] — a car: province code, serial letter(s), number.
/// * [motorcycle] — `NN-LN` over the number.
/// * [temporary] — the short plate with a `T` first.
/// * [foreignLong] / [foreignShort] — diplomatic (`NG`), international
///   organisation (`QT`) and foreigner (`NN`): province, mission code, status
///   code and number. Country codes 336–340 are refused; see
///   [VietnamMissions].
/// * [militaryLong] / [militaryShort] / [militaryMotorcycle] — white on red,
///   unit code and number.
///
/// Text groups: `province`, `series`, `number`; foreign `mission`, `status`;
/// military `unit`, `number`. A number split by a dot or dash is `number` then
/// `number2` (and `number3`), one group per run.
///
/// Not implemented: trailer (`123RM`), semi-trailer and specialised-machinery
/// military variants, the `LA`/`SAXA` yellow construction plates' own shape
/// (they are [long] with two serial letters on the yellow theme), the old
/// 1978–2003 plates, and the foreign motorcycle plate, whose drawing is
/// unreadable.
abstract final class VietnamPlates {
  static final Map<String, PlateSpec> _cache = <String, PlateSpec>{};

  static PlateSpec _memo(String id, PlateSpec Function() build) =>
      _cache[id] ??= build();

  static void _check(String name, int value, List<int> allowed) {
    if (!allowed.contains(value)) {
      throw ArgumentError.value(value, name, 'must be one of $allowed');
    }
  }

  /// `30F-256.58`. [serial] is 1 letter, or 2 for the special series (`LD`,
  /// `DA`, `LA`); [digits] is 5 (`256.58`) or 4 (`2565`, the old numbering).
  static PlateSpec long({int serial = 1, int digits = 5}) {
    _check('serial', serial, const <int>[1, 2]);
    _check('digits', digits, const <int>[4, 5]);
    return _memo(
      'vn.long.$serial$digits',
      () => _build('vn.long.$serial$digits', _Layout.longCar, <List<_Part>>[
        <_Part>[
          const _Part.run(VietnamAlphabets.digits, 2, 'province'),
          _Part.run(VietnamAlphabets.series, serial, 'series'),
          const _Part.dash(),
          ..._number(digits),
        ],
      ]),
    );
  }

  /// `30F` over `256.58`.
  static PlateSpec short({int serial = 1, int digits = 5}) {
    _check('serial', serial, const <int>[1, 2]);
    _check('digits', digits, const <int>[4, 5]);
    return _memo(
      'vn.short.$serial$digits',
      () => _build('vn.short.$serial$digits', _Layout.shortCar, <List<_Part>>[
        <_Part>[
          const _Part.run(VietnamAlphabets.digits, 2, 'province'),
          _Part.run(VietnamAlphabets.series, serial, 'series'),
        ],
        _number(digits),
      ]),
    );
  }

  /// `29-AB` over `226.58`. The second cell of the series is a letter or a
  /// digit (`29-B1`).
  static PlateSpec motorcycle({int digits = 5}) {
    _check('digits', digits, const <int>[4, 5]);
    return _memo(
      'vn.moto.$digits',
      () => _build('vn.moto.$digits', _Layout.motorcycle, <List<_Part>>[
        const <_Part>[
          _Part.run(VietnamAlphabets.digits, 2, 'province'),
          _Part.dash(),
          _Part.run(VietnamAlphabets.series, 1, 'series'),
          _Part.run(VietnamAlphabets.seriesOrDigit, 1, 'series'),
        ],
        _number(digits),
      ]),
    );
  }

  /// `T80` over `235.88`: the short plate, `T` first.
  static PlateSpec temporary() => _memo(
    'vn.temporary',
    () => _build('vn.temporary', _Layout.shortCar, <List<_Part>>[
      const <_Part>[
        _Part.run(VietnamAlphabets.letters, 1, 'series'),
        _Part.run(VietnamAlphabets.digits, 2, 'province'),
      ],
      _number(5),
    ]),
  );

  /// `80-441-NG-45`, or with [codeFirst] `27-QT-547-45` (an international
  /// organisation outside Hanoi). [statusColor] is the code's ink: red for
  /// `NG` and `QT`, null for the black `NN`.
  static PlateSpec foreignLong({
    bool codeFirst = false,
    Color? statusColor = VietnamColors.codeRed,
  }) => _memo(
    'vn.foreignLong.${codeFirst ? 'c' : 'm'}${statusColor == null ? 'k' : 'r'}',
    () => _build(
      'vn.foreignLong.${codeFirst ? 'c' : 'm'}${statusColor == null ? 'k' : 'r'}',
      _Layout.longForeign,
      <List<_Part>>[
        <_Part>[
          const _Part.run(VietnamAlphabets.digits, 2, 'province'),
          const _Part.dash(),
          if (codeFirst) ...<_Part>[
            _Part.run(
              VietnamAlphabets.letters,
              2,
              'status',
              color: statusColor,
            ),
            const _Part.dash(),
          ],
          const _Part.run(VietnamAlphabets.digits, 3, 'mission'),
          const _Part.dash(),
          if (!codeFirst) ...<_Part>[
            _Part.run(
              VietnamAlphabets.letters,
              2,
              'status',
              color: statusColor,
            ),
            const _Part.dash(),
          ],
          const _Part.run(VietnamAlphabets.digits, 2, 'number'),
        ],
      ],
      restrictions: const <PlateRestriction>[VietnamMissions.restriction],
    ),
  );

  /// `80-441` over `NN-02`.
  static PlateSpec foreignShort({Color? statusColor = VietnamColors.codeRed}) =>
      _memo(
        'vn.foreignShort.${statusColor == null ? 'k' : 'r'}',
        () => _build(
          'vn.foreignShort.${statusColor == null ? 'k' : 'r'}',
          _Layout.shortCar,
          <List<_Part>>[
            const <_Part>[
              _Part.run(VietnamAlphabets.digits, 2, 'province'),
              _Part.dash(),
              _Part.run(VietnamAlphabets.digits, 3, 'mission'),
            ],
            <_Part>[
              _Part.run(
                VietnamAlphabets.letters,
                2,
                'status',
                color: statusColor,
              ),
              const _Part.dash(),
              const _Part.run(VietnamAlphabets.digits, 2, 'number'),
            ],
          ],
          restrictions: const <PlateRestriction>[VietnamMissions.restriction],
        ),
      );

  /// `AB-12-34`.
  static PlateSpec militaryLong() => _memo(
    'vn.militaryLong',
    () => _build('vn.militaryLong', _Layout.longMilitary, <List<_Part>>[
      const <_Part>[
        _Part.run(VietnamAlphabets.letters, 2, 'unit'),
        _Part.dash(),
        _Part.run(VietnamAlphabets.digits, 2, 'number'),
        _Part.dash(),
        _Part.run(VietnamAlphabets.digits, 2, 'number'),
      ],
    ]),
  );

  /// `AB` over `12-34`.
  static PlateSpec militaryShort() => _memo(
    'vn.militaryShort',
    () => _build('vn.militaryShort', _Layout.shortMilitary, <List<_Part>>[
      const <_Part>[_Part.run(VietnamAlphabets.letters, 2, 'unit')],
      const <_Part>[
        _Part.run(VietnamAlphabets.digits, 2, 'number'),
        _Part.dash(),
        _Part.run(VietnamAlphabets.digits, 2, 'number'),
      ],
    ]),
  );

  /// `AB` over `123`.
  static PlateSpec militaryMotorcycle() => _memo(
    'vn.militaryMoto',
    () => _build('vn.militaryMoto', _Layout.motorcycleMilitary, <List<_Part>>[
      const <_Part>[_Part.run(VietnamAlphabets.letters, 2, 'unit')],
      const <_Part>[_Part.run(VietnamAlphabets.digits, 3, 'number')],
    ]),
  );

  /// `256.58` or `2565`.
  static List<_Part> _number(int digits) => digits == 5
      ? const <_Part>[
          _Part.run(VietnamAlphabets.digits, 3, 'number'),
          _Part.dot(),
          _Part.run(VietnamAlphabets.digits, 2, 'number'),
        ]
      : const <_Part>[_Part.run(VietnamAlphabets.digits, 4, 'number')];

  static PlateSpec _build(
    String id,
    _Geo geo,
    List<List<_Part>> rows, {
    List<PlateRestriction> restrictions = const <PlateRestriction>[],
  }) {
    final List<PlateSlot> slots = <PlateSlot>[];
    final List<PlateRule> rules = <PlateRule>[];
    final Map<String, List<int>> groups = <String, List<int>>{};
    for (int r = 0; r < rows.length; r++) {
      final _Row row = geo.rows[r];
      double width = 0;
      for (final _Part p in rows[r]) {
        width += switch (p.mark) {
          '-' => row.dashCell,
          '.' => row.dotCell,
          _ => p.count * row.pitch,
        };
      }
      double x = (geo.width - width) / 2;
      for (final _Part p in rows[r]) {
        switch (p.mark) {
          case '-':
            rules.add(
              PlateRule(
                box: PlateBox(
                  x + (row.dashCell - row.dashWidth) / 2,
                  row.inkCentre - row.dashHeight / 2,
                  row.dashWidth,
                  row.dashHeight,
                ),
              ),
            );
            x += row.dashCell;
          case '.':
            rules.add(
              PlateRule(
                box: PlateBox(
                  x + (row.dotCell - row.dotSize) / 2,
                  row.inkBottom - row.dotSize,
                  row.dotSize,
                  row.dotSize,
                ),
              ),
            );
            x += row.dotCell;
          default:
            // A mark splits a group's cells unevenly, so each run is its own
            // group: `number`, then `number2`.
            String key = p.key!;
            for (int n = 2; groups.containsKey(key); n++) {
              key = '${p.key}$n';
            }
            for (int i = 0; i < p.count; i++) {
              groups.putIfAbsent(key, () => <int>[]).add(slots.length);
              slots.add(
                PlateSlot(
                  alphabet: p.alphabet!,
                  box: PlateBox(
                    x + (row.pitch - row.cellWidth) / 2,
                    row.top,
                    row.cellWidth,
                    row.height,
                  ),
                  color: p.color,
                ),
              );
              x += row.pitch;
            }
        }
      }
    }
    return PlateSpec(
      id: id,
      country: VietnamCountry.vietnam,
      canvasWidth: geo.width,
      canvasHeight: geo.height,
      noPanel: true,
      panel: PlatePanel(box: PlateBox(0, 0, 0, geo.height)),
      borderWidthRatioOverride: geo.rim / geo.height,
      slots: slots,
      rules: rules,
      textGroups: <PlateTextGroup>[
        for (final MapEntry<String, List<int>> g in groups.entries)
          PlateTextGroup(g.value, key: g.key),
      ],
      restrictions: restrictions,
    );
  }
}
