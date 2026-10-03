/// Constructors for the *regular* parts of a plate face: registers, runs of
/// equal cells at a constant pitch. [PlateTextGroup] declares which slots form
/// a register; these say where the cells sit.
///
/// They build ordinary [PlateSlot] / [PlateMirror] / [PlateRule] values, so the
/// widget layer cannot tell a generated register from a literal one. Irregular
/// elements — an isolated cell, a label, a divider straddling a gap — stay
/// literals; forcing one through a register constructor is worse than writing
/// the four numbers.
///
/// These return `final` lists, so a spec built from one is a `static final`.
/// Harmless: it initialises lazily and [PlateSpec] equality is over `id` alone.
library;

import 'dart:ui' show Color;

import 'plate_alphabet.dart';
import 'plate_box.dart';
import 'plate_spec.dart';

/// [count] equal cells over [alphabet], the first at [left], each [width] wide
/// and [height] tall at [top], stepping by [pitch] — which defaults to [width],
/// i.e. flush cells with no gap between them.
///
/// Pass an explicit [pitch] for a gapped register, where the cells are narrower
/// than their stride. [color] is every cell's [PlateSlot.color].
List<PlateSlot> plateRegister({
  required PlateAlphabet alphabet,
  required int count,
  required double left,
  required double top,
  required double width,
  required double height,
  double? pitch,
  Color? color,
}) {
  _checkCount(count, 'plateRegister');
  final step = pitch ?? width;
  return List<PlateSlot>.unmodifiable(<PlateSlot>[
    for (var i = 0; i < count; i++)
      PlateSlot(
        alphabet: alphabet,
        box: PlateBox(left + i * step, top, width, height),
        color: color,
      ),
  ]);
}

/// [count] flush cells filling `[left, right)` exactly — [plateRegister]
/// expressed by the span to fill rather than by one cell's width.
///
/// Prefer this wherever the register is defined by its bounds: changing [count]
/// re-derives the cell width and still ends flush at [right].
List<PlateSlot> plateRegisterAcross({
  required PlateAlphabet alphabet,
  required int count,
  required double left,
  required double right,
  required double top,
  required double height,
  Color? color,
}) {
  _checkCount(count, 'plateRegisterAcross');
  if (count == 0) return const <PlateSlot>[];
  final width = (right - left) / count;
  return plateRegister(
    alphabet: alphabet,
    count: count,
    left: left,
    top: top,
    width: width,
    height: height,
    color: color,
  );
}

/// One [PlateMirror] per entry of [sources], laid out as a register: the echo
/// band a plate printing its number twice needs. Mirrors come out in [sources]
/// order, so the echo reads in the same direction as the slots it echoes.
///
/// [editable] makes the whole band a row of paired input fields — see
/// [PlateMirror].
List<PlateMirror> plateEcho({
  required Iterable<int> sources,
  required double left,
  required double top,
  required double width,
  required double height,
  double? pitch,
  double? glyphHeight,
  PlateAlphabet? alphabet,
  bool editable = false,
}) {
  final step = pitch ?? width;
  return List<PlateMirror>.unmodifiable(<PlateMirror>[
    for (final (i, source) in sources.indexed)
      PlateMirror(
        source: source,
        box: PlateBox(left + i * step, top, width, height),
        glyphHeight: glyphHeight ?? height,
        alphabet: alphabet,
        editable: editable,
      ),
  ]);
}

/// [count] identical rules stepping by [stepX] across and [stepY] down: a
/// stippled separator, or any other repeated mark. Both steps default to 0, so
/// a caller names only the axis the run moves along.
List<PlateRule> plateStipple({
  required int count,
  required double left,
  required double top,
  required double width,
  required double height,
  double stepX = 0,
  double stepY = 0,
}) {
  _checkCount(count, 'plateStipple');
  return List<PlateRule>.unmodifiable(<PlateRule>[
    for (var i = 0; i < count; i++)
      PlateRule(
        box: PlateBox(left + i * stepX, top + i * stepY, width, height),
      ),
  ]);
}

void _checkCount(int count, String caller) {
  if (count < 0) {
    throw ArgumentError.value(count, 'count', '$caller needs count >= 0');
  }
}
