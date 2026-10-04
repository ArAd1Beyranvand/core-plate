import 'package:plate_core/core_plate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _field = Color(0xFFFFFFFF);
const _ink = Color(0xFF3C875D);
const _inactive = Color(0x669BC1AB);

const _mono = PlateTheme.monochrome(
  field: _field,
  ink: _ink,
  inactive: _inactive,
  borderWidthRatio: 0.027,
  plateRadiusRatio: 0.10,
);

void main() {
  test('monochrome fuses border, ink, divider and active onto one colour', () {
    expect(_mono.plateBorder, _ink);
    expect(_mono.ink, _ink);
    expect(_mono.dividerColor, _ink);
    expect(_mono.activeColor, _ink);
    expect(_mono.plateBackground, _field);
    expect(_mono.inactiveColor, _inactive);
  });

  test('monochrome is usable in a const context', () {
    const t = PlateTheme.monochrome(
      field: _field,
      ink: _ink,
      inactive: _inactive,
      borderWidthRatio: 0.027,
      plateRadiusRatio: 0.10,
    );
    expect(identical(t, _mono), isTrue);
  });

  test('alertColor defaults to 0xFFF87171 and is overridable', () {
    expect(_mono.alertColor, const Color(0xFFF87171));
    const t = PlateTheme.monochrome(
      field: _field,
      ink: _ink,
      inactive: _inactive,
      borderWidthRatio: 0.027,
      plateRadiusRatio: 0.10,
      alertColor: Color(0xFF123456),
    );
    expect(t.alertColor, const Color(0xFF123456));
  });

  test('copyWith(activeColor:) leaves ink alone', () {
    final alerted = _mono.copyWith(activeColor: const Color(0xFFF87171));
    expect(alerted.activeColor, const Color(0xFFF87171));
    expect(alerted.ink, _ink);
    expect(alerted.plateBorder, _ink);
    expect(alerted.dividerColor, _ink);
  });

  test('monochrome equals the equivalent longhand literal', () {
    expect(
      _mono,
      const PlateTheme(
        plateBackground: _field,
        plateBorder: _ink,
        ink: _ink,
        dividerColor: _ink,
        borderWidthRatio: 0.027,
        plateRadiusRatio: 0.10,
        activeColor: _ink,
        inactiveColor: _inactive,
      ),
    );
  });
}
