import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/plate_card_bloc.dart';
import '../model/plate_number.dart';
import '../theme/plate_theme.dart';
import '../constants.dart';
import '../tools.dart';
import '../widgets/country_panel.dart';
import '../widgets/plate_frame.dart';
import '../widgets/plate_items.dart';
import 'letter_picker.dart';

/// The car plate widget.
///
/// Layout is expressed entirely in a fixed 520x110 plate space and scaled to
/// fit its parent by a single [FittedBox]. Every child is absolutely
/// positioned so the layout is pixel-identical in both [PlateMode.input] and
/// [PlateMode.display].
class CarPlateNumber extends StatefulWidget {
  const CarPlateNumber({
    super.key,
    this.mode = PlateMode.input,
    this.theme,
    this.onChooseLetter,
    this.onRemove,
    this.showRemoveButton = false,
    this.letterInputMode,
    this.onActiveSlotChanged,
  });

  final PlateMode mode;
  final PlateTheme? theme;

  /// How the plate letter is entered. Null resolves to
  /// [defaultLetterInputMode] for the current platform.
  final LetterInputMode? letterInputMode;

  /// Fires whenever the active (focused) slot changes, reporting the plate
  /// index that now holds focus, or null when focus leaves the plate. Primarily
  /// for [LetterInputMode.hostKeypad], so an app-supplied letter pad can show
  /// itself when the letter slot (index 2) becomes active — including when the
  /// focus chain lands there after the first digit group completes — and hide
  /// itself when focus moves on.
  final ValueChanged<int?>? onActiveSlotChanged;

  /// Optional escape hatch to override the default letter-picker sheet.
  final Future<String?> Function()? onChooseLetter;

  /// Called when the (external) remove button is pressed.
  final VoidCallback? onRemove;

  /// Whether to render the remove button in a column below the plate.
  final bool showRemoveButton;

  @override
  State<CarPlateNumber> createState() => _CarPlateNumberState();
}

class _CarPlateNumberState extends State<CarPlateNumber> {
  // ---- Plate-space geometry (520 x 110). Tune here. ----
  static const double _plateW = 520;
  static const double _plateH = 110;

  static const double _panelLeft = 5;
  static const double _panelTop = 5;
  static const double _panelW = 52;
  static const double _panelH = 100;

  static const double _slotTop = 17;
  static const double _digitSlotH = 76;
  static const double _letterSlotH = 76;

  static const double _d0Left = 65;
  static const double _d1Left = 120;
  static const double _letterLeft = 175;
  static const double _d3Left = 238;
  static const double _d4Left = 293;
  static const double _d5Left = 348;

  static const double _dividerX = 404;
  static const double _dividerTop = 14;
  static const double _dividerW = 5;
  static const double _dividerH = 82;

  static const double _provTextLeft = 412;
  static const double _provTextTop = 18;
  static const double _provTextW = 103;
  static const double _provTextH = 16;

  static const double _provSlotTop = 40;
  static const double _provSlotH = 52;
  static const double _provSlotW = 32;
  static const double _d6Left = 428;
  static const double _d7Left = 466;

  /// Plate positions that own an editable digit field.
  static const List<int> _digitPositions = [0, 1, 3, 4, 5, 6, 7];

  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};

  /// Focus node for the letter slot, used only in keyboard input mode.
  final FocusNode _letterFocusNode = FocusNode();

  /// Resolved once per build from [CarPlateNumber.letterInputMode].
  late LetterInputMode _letterInputMode;

  /// The plate index that last held focus, so [_handleFocusChange] only
  /// notifies on real transitions.
  int? _activeSlot;

  @override
  void initState() {
    super.initState();
    for (final p in _digitPositions) {
      _controllers[p] = TextEditingController();
      _focusNodes[p] = FocusNode()..addListener(_handleFocusChange);
    }
    _letterFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.removeListener(_handleFocusChange);
      f.dispose();
    }
    _letterFocusNode.removeListener(_handleFocusChange);
    _letterFocusNode.dispose();
    super.dispose();
  }

  /// Reports the plate index that now holds focus (index 2 is the letter slot),
  /// or null when focus has left the plate, whenever it changes.
  void _handleFocusChange() {
    int? active;
    for (final entry in _focusNodes.entries) {
      if (entry.value.hasFocus) {
        active = entry.key;
        break;
      }
    }
    active ??= _letterFocusNode.hasFocus ? 2 : null;

    if (active != _activeSlot) {
      _activeSlot = active;
      widget.onActiveSlotChanged?.call(active);
    }
  }

  bool get _isInput => widget.mode == PlateMode.input;

  void _focus(int position) {
    final node = _focusNodes[position];
    if (node != null) {
      node.requestFocus();
    }
  }

  Future<void> _chooseLetter(PlateCardBloc bloc) async {
    String? selected;
    if (widget.onChooseLetter != null) {
      selected = await widget.onChooseLetter!();
    } else {
      var index = 0;
      selected = await showModalBottomSheet<String>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 180,
                child: LetterPicker(
                  onSelectedItemChanged: (i) => index = i,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(sheetContext)
                    .pop(persianCarPlateLetters[index]),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      );
    }
    if (selected == null) return;
    bloc.add(ValueIsChanged(index: 2, value: selected));
    _focus(3);
  }

  Widget _digit(PlateCardBloc bloc, PlateNumber plate, int position, double slotHeight) {
    final controller = _controllers[position]!;
    final focusNode = _focusNodes[position]!;
    final value = plate.values[position];

    // Determines the next position in the focus chain.
    int? next;
    switch (position) {
      case 0:
        next = 1;
        break;
      case 1:
        next = -1; // triggers the letter picker
        break;
      case 3:
        next = 4;
        break;
      case 4:
        next = 5;
        break;
      case 5:
        next = 6;
        break;
      case 6:
        next = 7;
        break;
      case 7:
        next = null;
        break;
    }

    return IntegerPlateItem(
      focusNode: focusNode,
      controller: controller,
      onChanged: (v) => bloc.add(ValueIsChanged(index: position, value: v)),
      onCompleted: _isInput
          ? () {
              if (next == null) {
                focusNode.unfocus();
              } else if (next == -1) {
                // keyboard and hostKeypad both just move focus to the letter
                // slot; only picker opens the modal sheet.
                if (_letterInputMode == LetterInputMode.keyboard ||
                    _letterInputMode == LetterInputMode.hostKeypad) {
                  _letterFocusNode.requestFocus();
                } else {
                  _chooseLetter(bloc);
                }
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

    _letterInputMode = widget.letterInputMode ?? defaultLetterInputMode();

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
                aspectRatio: theme.carAspect,
                isCompleted: plate.isCompleted(),
                theme: theme,
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

            // Left digits.
            _positioned(_d0Left, _slotTop, _digitSlotItemW, _digitSlotH,
                _digit(bloc, plate, 0, _digitSlotH)),
            _positioned(_d1Left, _slotTop, _digitSlotItemW, _digitSlotH,
                _digit(bloc, plate, 1, _digitSlotH)),

            // Letter picker.
            _positioned(_letterLeft, _slotTop, _letterSlotItemW, _letterSlotH,
                StringPlateItem(
                  onPressed: _isInput &&
                          _letterInputMode == LetterInputMode.picker
                      ? () => _chooseLetter(bloc)
                      : null,
                  indexInPlateTypes: 2,
                  slotHeight: _letterSlotH,
                  mode: widget.mode,
                  theme: theme,
                  letterInputMode:
                      _isInput ? _letterInputMode : LetterInputMode.picker,
                  focusNode: _letterFocusNode,
                  onLetterTyped: (char) {
                    bloc.add(ValueIsChanged(index: 2, value: char));
                    if (char.isNotEmpty) _focus(3);
                  },
                )),

            // Middle digits.
            _positioned(_d3Left, _slotTop, _digitSlotItemW, _digitSlotH,
                _digit(bloc, plate, 3, _digitSlotH)),
            _positioned(_d4Left, _slotTop, _digitSlotItemW, _digitSlotH,
                _digit(bloc, plate, 4, _digitSlotH)),
            _positioned(_d5Left, _slotTop, _digitSlotItemW, _digitSlotH,
                _digit(bloc, plate, 5, _digitSlotH)),

            // Divider.
            Positioned(
              left: _dividerX,
              top: _dividerTop,
              width: _dividerW,
              height: _dividerH,
              child: ColoredBox(color: theme.dividerColor),
            ),

            // Province label.
            Positioned(
              left: _provTextLeft,
              top: _provTextTop,
              width: _provTextW,
              height: _provTextH,
              child: Text(
                'ایران',
                textAlign: TextAlign.center,
                style: PlateDigit.styleFor(16, theme.ink),
              ),
            ),

            // Province digits.
            _positioned(_d6Left, _provSlotTop, _provSlotW, _provSlotH,
                _digit(bloc, plate, 6, _provSlotH)),
            _positioned(_d7Left, _provSlotTop, _provSlotW, _provSlotH,
                _digit(bloc, plate, 7, _provSlotH)),
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

  // Item widths are derived from slotHeight by the item widgets themselves;
  // the Positioned width just needs to be wide enough to contain them and is
  // centred by aligning the child. We wrap in a Center so the intrinsic item
  // sits inside the declared box.
  static const double _digitSlotItemW = 47;
  static const double _letterSlotItemW = 55;

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
