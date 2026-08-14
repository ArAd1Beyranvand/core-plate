import 'dart:ffi' as ffi;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/plate_card_bloc.dart';
import '../constants.dart';
import '../tools.dart';
import '../widgets/plate_frame.dart';
import '../widgets/plate_items.dart';
import '../widgets/remove_button.dart';
import 'letter_picker.dart';

class CarPlateNumber extends StatefulWidget {
  const CarPlateNumber({
    super.key,
    required this.activeColor,
    required this.inactiveColor,
    required this.backgroundColor,
    this.spacingScale = 6,
    this.letterIcon,
    this.countryName,
    this.removeIcon,
    this.chooseLetterTextStyle,
    this.itemBorderRadius,
    this.numberTextStyle,
    this.letterTextStyle,
    this.onChooseLetter,
  });

  final Color activeColor;
  final Color inactiveColor;
  final Color backgroundColor;
  final double spacingScale;
  final Widget? letterIcon;
  final Widget? countryName;
  final Widget? removeIcon;
  final TextStyle? chooseLetterTextStyle;
  final TextStyle? numberTextStyle;
  final TextStyle? letterTextStyle;
  final BorderRadius? itemBorderRadius;
  final void Function(FocusNode? nextFocus)? onChooseLetter;

  @override
  State<CarPlateNumber> createState() => _CarPlateNumberState();
}

class _CarPlateNumberState extends State<CarPlateNumber> {
  List<FocusNode> focusNodes = [];
  List<TextEditingController> controllers = [];

  @override
  void initState() {
    super.initState();
    final plateNumber = BlocProvider.of<PlateCardBloc>(
      context,
    ).state.plateNumber;
    final valueTypes = plateNumber.valueTypes;
    for (int i = 0; i < valueTypes.length; i++) {
      final valueType = valueTypes[i];
      if (valueType == ffi.Int) {
        final controller = TextEditingController();
        controller.text = (plateNumber.values[i] ?? '').toString();
        controllers.add(controller);
      }
      focusNodes.add(FocusNode());
    }
  }

  Future<void> _pickLetter(BuildContext context) async {
    final bloc = BlocProvider.of<PlateCardBloc>(context);
    String selectedValue = '';
    await showModalBottomSheet<String>(
      context: context,
      builder: (builder) {
        return LetterPicker(
          sizeScale: widget.spacingScale * 16,
          textStyle: widget.chooseLetterTextStyle,
          onSelectedItemChanged: (int value) {
            selectedValue = persianCarPlateLetters[value];
          },
        );
      },
    );
    bloc.add(ValueIsChanged(index: 2, value: selectedValue));
  }

  Widget _digitItem(
    int controllerIndex,
    int position, {
    required VoidCallback onCompleted,
  }) {
    final bloc = BlocProvider.of<PlateCardBloc>(context);
    return IntegerPlateItem(
      backgroundColor: widget.backgroundColor,
      inactiveColor: widget.inactiveColor,
      activeColor: widget.activeColor,
      borderRadius: widget.itemBorderRadius,
      textStyle: widget.numberTextStyle,
      focusNode: focusNodes[controllerIndex],
      controller: controllers[controllerIndex],
      onCompleted: onCompleted,
      onChanged: (value) =>
          bloc.add(ValueIsChanged(index: position, value: value)),
      onRemoved: () => bloc.add(ValueIsChanged(index: position, value: '')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<PlateCardBloc>(context);
    return BlocBuilder<PlateCardBloc, PlateCardState>(
      builder: (BuildContext context, PlateCardState state) {
        final plateNumber = state.plateNumber;
        if (state.plateNumber.isEmpty()) {
          for (TextEditingController controller in controllers) {
            controller.text = "";
          }
        }
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: widget.spacingScale * 3,
            horizontal: widget.spacingScale,
          ),
          child: PlateFrame(
            isCompleted: plateNumber.isCompleted(),
            activeColor: widget.activeColor,
            inactiveColor: widget.inactiveColor,
            backgroundColor: widget.backgroundColor,
            borderWidth: widget.spacingScale / 1.5,
            child: IntrinsicHeight(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        SizedBox(height: widget.spacingScale * 2),
                        widget.countryName ?? const Text('Iran'),
                        SizedBox(height: widget.spacingScale),
                        Row(
                          children: [
                            Container(width: widget.spacingScale),
                            Row(
                              children: [
                                _digitItem(
                                  6,
                                  7,
                                  onCompleted: () => focusNodes[6].unfocus(),
                                ),
                                SizedBox(width: widget.spacingScale / 1.5),
                                _digitItem(
                                  5,
                                  6,
                                  onCompleted: () =>
                                      focusNodes[6].requestFocus(),
                                ),
                              ],
                            ),
                            Container(width: widget.spacingScale),
                          ],
                        ),
                        SizedBox(height: widget.spacingScale),
                      ],
                    ),
                    VerticalDivider(
                      color: plateNumber.isCompleted()
                          ? widget.activeColor
                          : widget.inactiveColor,
                      width: widget.spacingScale / 3,
                      thickness: widget.spacingScale / 3,
                    ),
                    SizedBox(width: widget.spacingScale),
                    Row(
                      children: [
                        _digitItem(
                          4,
                          5,
                          onCompleted: () => focusNodes[5].requestFocus(),
                        ),
                        SizedBox(width: widget.spacingScale / 1.5),
                        _digitItem(
                          3,
                          4,
                          onCompleted: () => focusNodes[4].requestFocus(),
                        ),
                        SizedBox(width: widget.spacingScale / 1.5),
                        _digitItem(
                          2,
                          3,
                          onCompleted: () => focusNodes[3].requestFocus(),
                        ),
                        SizedBox(width: widget.spacingScale / 1.5),
                        StringPlateItem(
                          width: (widget.spacingScale * 5).toInt(),
                          height: (widget.spacingScale * 10).toInt(),
                          defaultLetterIcon: widget.letterIcon,
                          borderRadius: widget.itemBorderRadius,
                          textStyle: widget.letterTextStyle,
                          indexInPlateTypes: 2,
                          activeColor: widget.activeColor,
                          inactiveColor: widget.inactiveColor,
                          onPressed: widget.onChooseLetter != null
                              ? () {
                                  widget.onChooseLetter!(focusNodes[2]);
                                }
                              : () => _pickLetter(context),
                        ),
                        SizedBox(width: widget.spacingScale / 1.5),
                        _digitItem(
                          1,
                          1,
                          onCompleted: widget.onChooseLetter != null
                              ? () {
                                  widget.onChooseLetter!(focusNodes[2]);
                                }
                              : () async {
                                  await _pickLetter(context);
                                  focusNodes[2].requestFocus();
                                },
                        ),
                        SizedBox(width: widget.spacingScale / 1.5),
                        _digitItem(
                          0,
                          0,
                          onCompleted: () => focusNodes[1].requestFocus(),
                        ),
                      ],
                    ),
                    SizedBox(width: widget.spacingScale),
                    Flexible(
                      child: Container(
                        color: plateNumber.isCompleted()
                            ? widget.activeColor
                            : widget.inactiveColor,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: RemoveButton(
                            defaultRemoveIcon: widget.removeIcon,
                            onPressed: () => bloc.add(RemovePlateCard()),
                            activeColor: widget.activeColor,
                            inactiveColor: widget.inactiveColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
