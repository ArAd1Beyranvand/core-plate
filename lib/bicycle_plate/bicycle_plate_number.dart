import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/plate_card_bloc.dart';
import '../model/plate_number.dart';
import '../theme/plate_theme.dart';
import '../tools.dart';
import '../widgets/country_panel.dart';
import '../widgets/plate_frame.dart';
import '../widgets/plate_items.dart';

/// The bicycle (motorcycle) plate widget.
///
/// Layout is expressed entirely in a fixed 175x110 plate space and scaled to
/// fit its parent by a single [FittedBox]. Every child is absolutely
/// positioned so the layout is pixel-identical in both [PlateMode.input] and
/// [PlateMode.display].
class BicyclePlateNumber extends StatefulWidget {
  const BicyclePlateNumber({
    super.key,
    this.mode = PlateMode.input,
    this.theme,
    this.onRemove,
    this.showRemoveButton = false,
  });

  final PlateMode mode;
  final PlateTheme? theme;

  /// Called when the (external) remove button is pressed.
  final VoidCallback? onRemove;

  /// Whether to render the remove button in a column below the plate.
  final bool showRemoveButton;

  @override
  State<BicyclePlateNumber> createState() => _BicyclePlateNumberState();
}

class _BicyclePlateNumberState extends State<BicyclePlateNumber> {
  // ---- Plate-space geometry (175 x 110). Tune here. ----
  static const double _plateW = 175;
  static const double _plateH = 110;

  static const double _panelLeft = 8;
  static const double _panelTop = 8;
  static const double _panelW = 56;
  static const double _panelH = 46;

  // Top row (province digits): slotHeight 36, width 22, top 13.
  static const double _topTop = 13;
  static const double _topSlotH = 36;
  static const double _topSlotW = 22;
  static const double _d0Left = 74;
  static const double _d1Left = 104;
  static const double _d2Left = 134;

  // Bottom row (serial digits): slotHeight 44, width 27, top 58.
  static const double _bottomTop = 58;
  static const double _bottomSlotH = 44;
  static const double _bottomSlotW = 27;
  static const double _d3Left = 8;
  static const double _d4Left = 41;
  static const double _d5Left = 74;
  static const double _d6Left = 107;
  static const double _d7Left = 140;

  /// Plate positions that own an editable digit field.
  static const List<int> _digitPositions = [0, 1, 2, 3, 4, 5, 6, 7];

  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    for (final p in _digitPositions) {
      _controllers[p] = TextEditingController();
      _focusNodes[p] = FocusNode();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  bool get _isInput => widget.mode == PlateMode.input;

  void _focus(int position) {
    final node = _focusNodes[position];
    if (node != null) {
      node.requestFocus();
    }
  }

  Widget _digit(PlateCardBloc bloc, PlateNumber plate, int position, double slotHeight) {
    final controller = _controllers[position]!;
    final focusNode = _focusNodes[position]!;
    final value = plate.values[position];

    // Determines the next position in the focus chain (null unfocuses).
    final int? next = position < 7 ? position + 1 : null;

    return IntegerPlateItem(
      focusNode: focusNode,
      controller: controller,
      onChanged: (v) => bloc.add(ValueIsChanged(index: position, value: v)),
      onCompleted: _isInput
          ? () {
              if (next == null) {
                focusNode.unfocus();
              } else {
                _focus(next);
              }
            }
          : null,
      onRemoved: _isInput
          ? () => bloc.add(ValueIsChanged(index: position, value: ''))
          : null,
      slotHeight: slotHeight,
      mode: widget.mode,
      theme: widget.theme,
      value: _isInput ? null : value,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? PlateTheme.of(context);
    final bloc = context.read<PlateCardBloc>();

    final plate = context.select<PlateCardBloc, PlateNumber>(
      (b) => b.state.plateNumber,
    );

    // Push bloc state into the controllers so a programmatically-filled plate
    // shows on screen. Assign .value (not .text) to avoid resetting the
    // selection and fighting the field mid-frame.
    for (final p in _digitPositions) {
      final c = _controllers[p]!;
      final v = plate.values[p] as String? ?? '';
      if (c.text != v) {
        c.value = TextEditingValue(
          text: v,
          selection: TextSelection.collapsed(offset: v.length),
        );
      }
    }

    final fitted = FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: _plateW,
        height: _plateH,
        child: Stack(
          children: [
            Positioned.fill(
              child: PlateFrame(
                aspectRatio: theme.motorcycleAspect,
                isCompleted: plate.isCompleted(),
                theme: theme.copyWith(borderWidthRatio: 0.07),
                child: const SizedBox.expand(),
              ),
            ),

            // Country panel.
            const Positioned(
              left: _panelLeft,
              top: _panelTop,
              width: _panelW,
              height: _panelH,
              child: CountryPanel(),
            ),

            // Top row (province).
            _positioned(_d0Left, _topTop, _topSlotW, _topSlotH,
                _digit(bloc, plate, 0, _topSlotH)),
            _positioned(_d1Left, _topTop, _topSlotW, _topSlotH,
                _digit(bloc, plate, 1, _topSlotH)),
            _positioned(_d2Left, _topTop, _topSlotW, _topSlotH,
                _digit(bloc, plate, 2, _topSlotH)),

            // Bottom row (serial).
            _positioned(_d3Left, _bottomTop, _bottomSlotW, _bottomSlotH,
                _digit(bloc, plate, 3, _bottomSlotH)),
            _positioned(_d4Left, _bottomTop, _bottomSlotW, _bottomSlotH,
                _digit(bloc, plate, 4, _bottomSlotH)),
            _positioned(_d5Left, _bottomTop, _bottomSlotW, _bottomSlotH,
                _digit(bloc, plate, 5, _bottomSlotH)),
            _positioned(_d6Left, _bottomTop, _bottomSlotW, _bottomSlotH,
                _digit(bloc, plate, 6, _bottomSlotH)),
            _positioned(_d7Left, _bottomTop, _bottomSlotW, _bottomSlotH,
                _digit(bloc, plate, 7, _bottomSlotH)),
          ],
        ),
      ),
    );

    if (!widget.showRemoveButton) {
      return fitted;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        fitted,
        IconButton(
          onPressed: widget.onRemove,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  // The item widgets derive their own width from slotHeight; the Positioned
  // width just needs to contain them, and Center keeps the glyph inside the
  // declared box.
  Widget _positioned(
      double left, double top, double width, double height, Widget child) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Center(child: child),
    );
  }
}
