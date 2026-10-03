import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'niger_alphabets.dart';
import 'niger_country.dart';

/// The article's "Other Formats": state transport, military and the two
/// diplomatic plates. **No image of any of them was found**, so nothing here
/// is measured off them. Digit height, frame and the 520×110 canvas are the
/// private plate's, and every cell is one 54-unit pitch (the artwork's own is
/// 53.9) so the digits look like the measured plates'. Where each element
/// sits, and every colour (see `NigerThemes`), is a reading of the article's
/// prose.
///
/// Each plate is one row of cells, centred on the canvas: a digit slot, a
/// fixed word, or a gap, each some number of pitches wide.
abstract final class _Layout {
  static const double width = 520;
  static const double height = 110;
  static const double pitch = 54;

  /// Fixed letters are set a little smaller than the digits so a three-letter
  /// word fits its three cells.
  static const double wordGlyph = 84;

  /// The military flag at the left, in the artwork-less guess: 7:6, and a
  /// little under the plate's inner height.
  static const PlateBox flag = PlateBox(18, 22.5, 70, 60);
}

enum _Kind { digit, word, gap }

class _Cell {
  const _Cell.digit(this.group) : kind = _Kind.digit, text = '', span = 1;
  const _Cell.word(this.text, {this.span = 1}) : kind = _Kind.word, group = '';
  const _Cell.gap(this.span) : kind = _Kind.gap, text = '', group = '';

  final _Kind kind;
  final String group;
  final String text;
  final double span;
}

/// What differs between the four: the country, where the row starts, and its
/// cells. `left` is null to centre the row on the canvas.
class _Format {
  const _Format({
    required this.id,
    required this.country,
    required this.cells,
    this.left,
    this.panel,
  });

  final String id;
  final PlateCountry country;
  final List<_Cell> cells;
  final double? left;
  final PlateBox? panel;

  double get span => cells.fold(0.0, (double a, _Cell c) => a + c.span);
}

abstract final class NigerOtherPlates {
  static const _Format _state = _Format(
    id: 'ne.2005.state',
    country: NigerCountry.plain,
    cells: <_Cell>[
      _Cell.digit('serial'),
      _Cell.digit('serial'),
      _Cell.digit('serial'),
      _Cell.digit('serial'),
      _Cell.digit('serial'),
      _Cell.word('ARN', span: 3),
      _Cell.digit('area'),
    ],
  );

  static const _Format _military = _Format(
    id: 'ne.2005.military',
    country: NigerCountry.military,
    panel: _Layout.flag,
    left: 167,
    cells: <_Cell>[
      _Cell.digit('serial'),
      _Cell.digit('serial'),
      _Cell.digit('serial'),
      _Cell.digit('serial'),
      _Cell.digit('serial'),
    ],
  );

  static const _Format _chief = _Format(
    id: 'ne.2005.diplomatic.cmd',
    country: NigerCountry.plain,
    cells: <_Cell>[
      _Cell.digit('code'),
      _Cell.digit('code'),
      _Cell.digit('code'),
      _Cell.word('CMD', span: 3),
      _Cell.gap(0.5),
      _Cell.word('RN', span: 2),
    ],
  );

  static const _Format _staff = _Format(
    id: 'ne.2005.diplomatic.cd',
    country: NigerCountry.plain,
    cells: <_Cell>[
      _Cell.digit('code'),
      _Cell.digit('code'),
      _Cell.digit('code'),
      _Cell.word('CD', span: 2),
      _Cell.digit('room'),
      _Cell.gap(0.5),
      _Cell.word('RN', span: 2),
    ],
  );

  static PlateSpec _build(_Format format) {
    final double left =
        format.left ?? (_Layout.width - format.span * _Layout.pitch) / 2;
    final slots = <PlateSlot>[];
    final labels = <PlateLabel>[];
    final groups = <String, List<int>>{};
    double x = left;
    for (final _Cell cell in format.cells) {
      final PlateBox box = PlateBox(
        x,
        0,
        cell.span * _Layout.pitch,
        _Layout.height,
      );
      switch (cell.kind) {
        case _Kind.digit:
          groups.putIfAbsent(cell.group, () => <int>[]).add(slots.length);
          slots.add(PlateSlot(alphabet: NigerAlphabets.digits, box: box));
        case _Kind.word:
          labels.add(
            PlateLabel(
              text: cell.text,
              box: box,
              glyphHeight: _Layout.wordGlyph,
            ),
          );
        case _Kind.gap:
      }
      x += cell.span * _Layout.pitch;
    }
    return PlateSpec(
      id: format.id,
      country: format.country,
      canvasWidth: _Layout.width,
      canvasHeight: _Layout.height,
      panel: PlatePanel(
        box: format.panel ?? const PlateBox(0, 0, 1, 1),
        padding: EdgeInsets.zero,
      ),
      noPanel: format.panel == null,
      labels: labels,
      slots: slots,
      textGroups: <PlateTextGroup>[
        for (final MapEntry<String, List<int>> g in groups.entries)
          PlateTextGroup(g.value, key: g.key),
      ],
    );
  }

  static final PlateSpec state = _build(_state);
  static final PlateSpec military = _build(_military);
  static final PlateSpec diplomaticChief = _build(_chief);
  static final PlateSpec diplomaticStaff = _build(_staff);
}
