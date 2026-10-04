import 'package:plate_core/core_plate.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';

const _digits = PlateAlphabet.latinDigits;
const _letters = PlateAlphabet.latinUppercase;

List<double> _lefts(Iterable<dynamic> items) => [
  for (final i in items) (i.box as PlateBox).left,
];

void main() {
  group('plateRegister', () {
    test('lays N flush cells at the given pitch', () {
      final cells = plateRegister(
        alphabet: _digits,
        count: 5,
        left: 140,
        top: 60,
        width: 78,
        height: 120,
      );

      expect(_lefts(cells), [140, 218, 296, 374, 452]);
      expect(cells.every((c) => c.box.width == 78), isTrue);
      expect(
        cells.every((c) => c.box.top == 60 && c.box.height == 120),
        isTrue,
      );
      expect(cells.every((c) => c.alphabet == _digits), isTrue);
    });

    test('pitch defaults to width, and is honoured when given', () {
      final flush = plateRegister(
        alphabet: _digits,
        count: 3,
        left: 0,
        top: 0,
        width: 40,
        height: 10,
      );
      expect(_lefts(flush), [0, 40, 80]);

      // A gapped register: cells narrower than their stride.
      final gapped = plateRegister(
        alphabet: _digits,
        count: 3,
        left: 0,
        top: 0,
        width: 40,
        height: 10,
        pitch: 55,
      );
      expect(_lefts(gapped), [0, 55, 110]);
      expect(gapped.every((c) => c.box.width == 40), isTrue);
    });

    test('color reaches every cell, and defaults to the theme ink', () {
      const white = Color(0xFFFFFFFF);
      final coloured = plateRegister(
        alphabet: _digits,
        count: 3,
        left: 0,
        top: 0,
        width: 10,
        height: 10,
        color: white,
      );
      expect(coloured.every((c) => c.color == white), isTrue);

      final across = plateRegisterAcross(
        alphabet: _digits,
        count: 2,
        left: 0,
        right: 20,
        top: 0,
        height: 10,
        color: white,
      );
      expect(across.every((c) => c.color == white), isTrue);

      final plain = plateRegister(
        alphabet: _digits,
        count: 2,
        left: 0,
        top: 0,
        width: 10,
        height: 10,
      );
      expect(plain.every((c) => c.color == null), isTrue);
    });

    test('degenerate counts', () {
      expect(
        plateRegister(
          alphabet: _digits,
          count: 0,
          left: 5,
          top: 0,
          width: 10,
          height: 10,
        ),
        isEmpty,
      );

      final one = plateRegister(
        alphabet: _digits,
        count: 1,
        left: 5,
        top: 0,
        width: 10,
        height: 10,
      );
      expect(_lefts(one), [5]);

      expect(
        () => plateRegister(
          alphabet: _digits,
          count: -1,
          left: 0,
          top: 0,
          width: 10,
          height: 10,
        ),
        throwsArgumentError,
      );
    });
  });

  group('plateRegisterAcross', () {
    test('fills the span exactly, whatever the count', () {
      // Yemen's northern serial: four, five or six cells, all filling
      // x in [140, 530). This is the case the hand-written version got wrong.
      final six = plateRegisterAcross(
        alphabet: _digits,
        count: 6,
        left: 140,
        right: 530,
        top: 60,
        height: 120,
      );
      expect(six.first.box.width, 65);
      expect(_lefts(six), [140, 205, 270, 335, 400, 465]);
      expect(six.last.box.right, 530);

      final four = plateRegisterAcross(
        alphabet: _digits,
        count: 4,
        left: 140,
        right: 530,
        top: 60,
        height: 120,
      );
      expect(four.first.box.width, 97.5);
      expect(_lefts(four), [140, 237.5, 335, 432.5]);
      // The property the hand-written run broke: it ended at 531.
      expect(four.last.box.right, 530);

      final five = plateRegisterAcross(
        alphabet: _digits,
        count: 5,
        left: 140,
        right: 530,
        top: 60,
        height: 120,
      );
      expect(five.first.box.width, 78);
      expect(five.last.box.right, 530);
    });

    test('degenerate counts', () {
      expect(
        plateRegisterAcross(
          alphabet: _digits,
          count: 0,
          left: 0,
          right: 100,
          top: 0,
          height: 10,
        ),
        isEmpty,
      );

      final one = plateRegisterAcross(
        alphabet: _letters,
        count: 1,
        left: 20,
        right: 100,
        top: 0,
        height: 10,
      );
      expect(_lefts(one), [20]);
      expect(one.single.box.width, 80);

      expect(
        () => plateRegisterAcross(
          alphabet: _digits,
          count: -2,
          left: 0,
          right: 100,
          top: 0,
          height: 10,
        ),
        throwsArgumentError,
      );
    });
  });

  group('plateEcho', () {
    test('one mirror per source, in order, laid out as a register', () {
      final echo = plateEcho(
        sources: [2, 3, 4, 5],
        left: 140,
        top: 200,
        width: 60,
        height: 40,
        alphabet: _digits,
      );

      expect([for (final m in echo) m.source], [2, 3, 4, 5]);
      expect(_lefts(echo), [140, 200, 260, 320]);
      // glyphHeight defaults to height.
      expect(echo.every((m) => m.glyphHeight == 40), isTrue);
      expect(echo.every((m) => m.alphabet == _digits), isTrue);
    });

    test(
      'glyphHeight and alphabet are overridable; pitch defaults to width',
      () {
        final echo = plateEcho(
          sources: [0, 1],
          left: 0,
          top: 0,
          width: 30,
          height: 40,
          pitch: 50,
          glyphHeight: 25,
        );

        expect(_lefts(echo), [0, 50]);
        expect(echo.every((m) => m.glyphHeight == 25), isTrue);
        // Null alphabet renders through the source slot's own — the PlateMirror
        // default, preserved rather than substituted here.
        expect(echo.every((m) => m.alphabet == null), isTrue);
      },
    );

    test('an empty source list yields no mirrors', () {
      expect(
        plateEcho(sources: const [], left: 0, top: 0, width: 10, height: 10),
        isEmpty,
      );
    });
  });

  group('plateStipple', () {
    test('steps down a column', () {
      // Yemen's separator strip: 24 dots of 9x7 at x=838, pitch 12.
      final dots = plateStipple(
        count: 24,
        left: 838,
        top: 1,
        width: 9,
        height: 7,
        stepY: 12,
      );

      expect(dots.length, 24);
      expect(dots.first.box.top, 1);
      expect(dots[1].box.top, 13);
      expect(dots.last.box.top, 277);
      expect(dots.every((r) => r.box.left == 838), isTrue);
      expect(dots.every((r) => r.box.width == 9 && r.box.height == 7), isTrue);
    });

    test('steps across a row, and both steps default to zero', () {
      final across = plateStipple(
        count: 3,
        left: 10,
        top: 5,
        width: 4,
        height: 4,
        stepX: 20,
      );
      expect(_lefts(across), [10, 30, 50]);
      expect(across.every((r) => r.box.top == 5), isTrue);

      // No step at all: a legal, if pointless, stack of coincident rules.
      final stacked = plateStipple(
        count: 2,
        left: 0,
        top: 0,
        width: 1,
        height: 1,
      );
      expect(_lefts(stacked), [0, 0]);
    });

    test('degenerate counts', () {
      expect(
        plateStipple(count: 0, left: 0, top: 0, width: 1, height: 1),
        isEmpty,
      );
      expect(
        () => plateStipple(count: -1, left: 0, top: 0, width: 1, height: 1),
        throwsArgumentError,
      );
    });
  });

  group('the returned lists', () {
    test('are unmodifiable, and never shared between calls', () {
      final a = plateRegister(
        alphabet: _digits,
        count: 2,
        left: 0,
        top: 0,
        width: 10,
        height: 10,
      );
      final b = plateRegister(
        alphabet: _digits,
        count: 2,
        left: 0,
        top: 0,
        width: 10,
        height: 10,
      );

      expect(identical(a, b), isFalse);
      expect(
        () => a.add(
          const PlateSlot(alphabet: _digits, box: PlateBox(0, 0, 1, 1)),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => plateStipple(
          count: 1,
          left: 0,
          top: 0,
          width: 1,
          height: 1,
        ).clear(),
        throwsUnsupportedError,
      );
      expect(
        () => plateEcho(
          sources: const [0],
          left: 0,
          top: 0,
          width: 1,
          height: 1,
        ).clear(),
        throwsUnsupportedError,
      );
    });
  });
}
