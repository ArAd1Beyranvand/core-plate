import 'package:core_plate_bloc/core_plate_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_core/plate_core.dart';

const _restriction = PlateRestriction(
  group: 'code',
  values: ['09'],
  reason: 'COUNTRY NOT FOUND',
);

const _spec = PlateSpec(
  id: 'test.restricted',
  country: PlateCountry(
    code: 'xx',
    captionLines: ['XX'],
    panelColor: Color(0xFFFFFFFF),
    panelTextColor: Color(0xFF000000),
  ),
  canvasWidth: 200,
  canvasHeight: 100,
  panel: PlatePanel(box: PlateBox(0, 0, 40, 100)),
  textDirection: TextDirection.ltr,
  slots: [
    PlateSlot(
      alphabet: PlateAlphabet.latinDigits,
      box: PlateBox(50, 10, 40, 80),
    ),
    PlateSlot(
      alphabet: PlateAlphabet.latinDigits,
      box: PlateBox(100, 10, 40, 80),
    ),
  ],
  textGroups: [
    PlateTextGroup([0, 1], key: 'code'),
  ],
  restrictions: [_restriction],
);

void main() {
  test('the bloc refuses a value that breaks a restriction', () async {
    final bloc = PlateCardBloc(_spec);
    bloc.add(ValueIsChanged(index: 0, value: '0'));
    bloc.add(ValueIsChanged(index: 1, value: '9'));
    await pumpEventQueue();
    expect(bloc.state.plateNumber.values, ['0', null]);
    expect(bloc.state.rejection, _restriction);

    bloc.add(ValueIsChanged(index: 1, value: '8'));
    await pumpEventQueue();
    expect(bloc.state.plateNumber.values, ['0', '8']);
    expect(bloc.state.rejection, isNull);
    await bloc.close();
  });
}
