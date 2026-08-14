import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/plate_card_bloc.dart';
import '../tools.dart';
import '../widgets/digit_row.dart';
import '../widgets/plate_frame.dart';
import '../widgets/plate_items.dart';
import '../widgets/remove_button.dart';

class BicyclePlateNumber extends StatefulWidget {
  const BicyclePlateNumber({
    super.key,
    required this.activeColor,
    required this.inactiveColor,
    required this.backgroundColor,
    this.spacingScale = 6,
    this.removeIcon,
    this.textStyle,
    this.itemBorderRadius,
  });

  final Color activeColor;
  final Color inactiveColor;
  final Color backgroundColor;
  final double spacingScale;
  final Widget? removeIcon;
  final TextStyle? textStyle;
  final BorderRadius? itemBorderRadius;

  @override
  State<BicyclePlateNumber> createState() => _BicyclePlateNumberState();
}

class _BicyclePlateNumberState extends State<BicyclePlateNumber> {
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
      final controller = TextEditingController();
      controller.text = (plateNumber.values[i] ?? '').toString();
      controllers.add(controller);
      focusNodes.add(FocusNode());
    }
  }

  Widget _digitItem(int index, {required VoidCallback onCompleted}) {
    return IntegerPlateItem(
      activeColor: widget.activeColor,
      inactiveColor: widget.inactiveColor,
      borderRadius: widget.itemBorderRadius,
      textStyle: widget.textStyle,
      focusNode: focusNodes[index],
      controller: controllers[index],
      onCompleted: onCompleted,
      onChanged: (value) => BlocProvider.of<PlateCardBloc>(
        context,
      ).add(ValueIsChanged(index: index, value: value)),
      onRemoved: () {
        BlocProvider.of<PlateCardBloc>(
          context,
        ).add(ValueIsChanged(index: index, value: ''));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            vertical: widget.spacingScale * 2.5,
            horizontal: widget.spacingScale,
          ),
          child: PlateFrame(
            isCompleted: plateNumber.isCompleted(),
            activeColor: widget.activeColor,
            inactiveColor: widget.inactiveColor,
            backgroundColor: widget.backgroundColor,
            borderWidth: widget.spacingScale,
            child: IntrinsicHeight(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: widget.spacingScale * 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: widget.spacingScale),
                        DigitRow(
                          gap: widget.spacingScale * 2,
                          items: [
                            _digitItem(
                              2,
                              onCompleted: () => focusNodes[3].requestFocus(),
                            ),
                            _digitItem(
                              1,
                              onCompleted: () => focusNodes[2].requestFocus(),
                            ),
                            _digitItem(
                              0,
                              onCompleted: () => focusNodes[1].requestFocus(),
                            ),
                          ],
                        ),
                        SizedBox(height: widget.spacingScale / 2),
                        DigitRow(
                          gap: widget.spacingScale * 2,
                          items: [
                            _digitItem(
                              7,
                              onCompleted: () => focusNodes[7].unfocus(),
                            ),
                            _digitItem(
                              6,
                              onCompleted: () => focusNodes[7].requestFocus(),
                            ),
                            _digitItem(
                              5,
                              onCompleted: () => focusNodes[6].requestFocus(),
                            ),
                            _digitItem(
                              4,
                              onCompleted: () => focusNodes[5].requestFocus(),
                            ),
                            BlocBuilder<PlateCardBloc, PlateCardState>(
                              builder: (BuildContext context, state) {
                                return _digitItem(
                                  3,
                                  onCompleted: () =>
                                      focusNodes[4].requestFocus(),
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: widget.spacingScale),
                      ],
                    ),
                    SizedBox(width: widget.spacingScale * 8),
                    Expanded(
                      child: Container(
                        color: plateNumber.isCompleted()
                            ? widget.activeColor
                            : widget.inactiveColor,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            RemoveButton(
                              defaultRemoveIcon: widget.removeIcon,
                              onPressed: () => BlocProvider.of<PlateCardBloc>(
                                context,
                              ).add(RemovePlateCard()),
                              activeColor: widget.activeColor,
                              inactiveColor: widget.inactiveColor,
                            ),
                          ],
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
