/// Constructors for the *regular* parts of a plate face.
///
/// A real plate is not a bag of rectangles: it is a small number of registers —
/// runs of equal cells at a constant pitch, separated by wider gaps.
/// [PlateTextGroup] already declares which slots form a register; these say
/// where the cells sit. Writing a register out cell by cell is a for-loop
/// unrolled by hand, and a hand-unrolled loop drifts: one rounded coordinate is
/// invisible until someone measures the plate.
///
/// These build the ordinary [PlateSlot] / [PlateMirror] / [PlateRule] types and
/// nothing else. The widget layer reads `spec.slots` exactly as before and
/// cannot tell a generated register from a literal one. An *irregular* element —
/// an isolated cell, a label, a decal, a divider that straddles a gap — stays a
/// literal: forcing it through a register constructor is worse than writing the
/// four numbers.
///
/// A list these return is `final`, not `const`, so a spec built from one is a
/// `static final` rather than a `static const`. That costs nothing: it is
/// initialised lazily, once per isolate, and [PlateSpec] equality is over `id`
/// alone, so const canonicalisation was never load-bearing for identity.
library;

import 'plate_alphabet.dart';
import 'plate_box.dart';
import 'plate_spec.dart';

/// [count] equal cells over [alphabet], the first at [left], each [width] wide
/// and [height] tall at [top], stepping by [pitch] — which defaults to [width],
/// i.e. flush cells with no gap between them.
///
/// Pass an explicit [pitch] for a gapped register, where the cells are narrower
/// than their stride.
List<PlateSlot> plateRegister({
  required PlateAlphabet alphabet,
  required int count,
  required double left,
  required double top,
  required double width,
  required double height,
  double? pitch,
}) {
  _checkCount(count, 'plateRegister');
  final step = pitch ?? width;
  return List<PlateSlot>.unmodifiable(<PlateSlot>[
    for (var i = 0; i < count; i++)
      PlateSlot(
        alphabet: alphabet,
        box: PlateBox(left + i * step, top, width, height),
      ),
  ]);
}

/// [count] flush cells filling `[left, right)` exactly — the same register as
/// [plateRegister], expressed by the span it must fill rather than by the width
/// of one cell.
///
/// Prefer this wherever the register is defined by its bounds: it cannot round
/// wrong. A run of four, five or six cells across one span produces three
/// different cell widths from one declaration, and every one of them ends flush
/// at [right].
List<PlateSlot> plateRegisterAcross({
  required PlateAlphabet alphabet,
  required int count,
  required double left,
  required double right,
  required double top,
  required double height,
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
  );
}

/// One [PlateMirror] per entry of [sources], laid out as a register: the echo
/// band a plate that prints its number twice needs.
///
/// The mirrors come out in [sources] order, so the echo reads in the same
/// direction as the slots it echoes. [glyphHeight] defaults to [height], and
/// [alphabet] null renders through each source slot's own alphabet — the
/// [PlateMirror] default.
List<PlateMirror> plateEcho({
  required Iterable<int> sources,
  required double left,
  required double top,
  required double width,
  required double height,
  double? pitch,
  double? glyphHeight,
  PlateAlphabet? alphabet,
}) {
  final step = pitch ?? width;
  final list = sources.toList(growable: false);
  var i = 0;
  return List<PlateMirror>.unmodifiable(<PlateMirror>[
    for (final source in list)
      PlateMirror(
        source: source,
        box: PlateBox(left + i++ * step, top, width, height),
        glyphHeight: glyphHeight ?? height,
        alphabet: alphabet,
      ),
  ]);
}

/// [count] identical rules stepping by [stepX] across and [stepY] down: a
/// stippled separator, or any other repeated mark.
///
/// Both steps default to 0, so a caller states the one axis the run moves along
/// and says nothing about the other.
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
      PlateRule(box: PlateBox(left + i * stepX, top + i * stepY, width, height)),
  ]);
}

void _checkCount(int count, String caller) {
  if (count < 0) {
    throw ArgumentError.value(count, 'count', '$caller needs count >= 0');
  }
}
