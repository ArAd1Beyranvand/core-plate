import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/plate_card_bloc.dart';
import '../constants.dart';
import '../model/plate_number.dart';
import '../theme/plate_theme.dart';
import '../tools.dart';

/// One character rendered in plate style: [PlateTheme.ink], heavy weight,
/// Persian numerals. Sized from [slotHeight] — never MediaQuery.
///
/// This is the single source of truth for how a glyph looks, so display mode
/// and input mode stay pixel-identical.
class PlateDigit extends StatelessWidget {
  const PlateDigit({
    super.key,
    required this.char,
    required this.slotHeight,
    this.theme,
    this.color,
  });

  final String char;
  final double slotHeight;
  final PlateTheme? theme;

  /// Overrides the glyph colour (defaults to [PlateTheme.ink]). Used for the
  /// dimmed placeholder in an empty letter slot.
  final Color? color;

  static TextStyle styleFor(double slotHeight, Color color) => TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: slotHeight * 0.72,
        height: 1.0,
      );

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? PlateTheme.of(context);
    return Text(
      toPersianDigits(char),
      textAlign: TextAlign.center,
      style: styleFor(slotHeight, color ?? effectiveTheme.ink),
    );
  }
}

/// A digit position. In [PlateMode.display] it is a bare glyph on the plate
/// face. In [PlateMode.input] it keeps a real [TextField] (deliberate — the
/// fields are how the user types) restyled to look like the bare glyph, with a
/// thin underline instead of a box.
class IntegerPlateItem extends StatelessWidget {
  const IntegerPlateItem({
    super.key,
    required this.focusNode,
    required this.onChanged,
    required this.controller,
    required this.onCompleted,
    required this.slotHeight,
    this.mode = PlateMode.input,
    this.theme,
    this.onRemoved,
    this.value,
  });

  final FocusNode focusNode;
  final void Function(String) onChanged;
  final void Function()? onCompleted;
  final void Function()? onRemoved;
  final TextEditingController controller;
  final double slotHeight;
  final PlateMode mode;
  final PlateTheme? theme;

  /// The current ASCII value, used in display mode.
  final String? value;

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? PlateTheme.of(context);

    if (mode == PlateMode.display) {
      return SizedBox(
        width: slotHeight * 0.62,
        height: slotHeight,
        child: Center(
          child: PlateDigit(
            char: value ?? '',
            slotHeight: slotHeight,
            theme: effectiveTheme,
          ),
        ),
      );
    }

    // TODO(persian-input): the controller keeps ASCII so the bloc stays ASCII;
    // a two-way TextInputFormatter that displays Persian while storing ASCII is
    // fiddly to get right (cursor/selection), so the field shows ASCII for now.
    final isEmpty = controller.text.isEmpty;
    final underlineColor =
        isEmpty ? effectiveTheme.inactiveColor : effectiveTheme.activeColor;

    return SizedBox(
      width: slotHeight * 0.62,
      height: slotHeight,
      child: Theme(
        data: ThemeData.light().copyWith(
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: effectiveTheme.activeColor.withValues(alpha: 0.3),
            cursorColor: effectiveTheme.activeColor,
            selectionHandleColor: effectiveTheme.activeColor,
          ),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          style: PlateDigit.styleFor(slotHeight, effectiveTheme.ink),
          cursorColor: effectiveTheme.activeColor,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: slotHeight * 0.12),
            filled: false,
            counterText: '',
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: effectiveTheme.inactiveColor),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: underlineColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: effectiveTheme.activeColor),
            ),
          ),
          onChanged: (value) {
            if (value.isDigit()) {
              onChanged(value);
              if (value != '') {
                if (onCompleted != null) onCompleted!();
              }
            } else {
              controller.text = '';
              if (onRemoved != null) onRemoved!();
            }
          },
          maxLength: 1,
          keyboardType: TextInputType.number,
        ),
      ),
    );
  }
}

/// The letter position. In [PlateMode.display] it is a bare Persian letter. In
/// [PlateMode.input] it is a tappable slot with an underline and a `?`
/// placeholder when empty.
class StringPlateItem extends StatelessWidget {
  const StringPlateItem({
    super.key,
    required this.onPressed,
    required this.indexInPlateTypes,
    required this.slotHeight,
    this.mode = PlateMode.input,
    this.theme,
    this.defaultLetterIcon,
    this.letterInputMode = LetterInputMode.picker,
    this.focusNode,
    this.onLetterTyped,
  });

  final VoidCallback? onPressed;
  final int indexInPlateTypes;
  final double slotHeight;
  final PlateMode mode;
  final PlateTheme? theme;
  final Widget? defaultLetterIcon;

  /// How the letter is entered. In [LetterInputMode.keyboard] and
  /// [LetterInputMode.hostKeypad] the slot takes focus instead of opening a
  /// picker sheet.
  final LetterInputMode letterInputMode;

  /// Focus node for keyboard/hostKeypad mode, so the focus-advance chain can
  /// land here.
  final FocusNode? focusNode;

  /// Fired in keyboard mode when a valid Persian letter is typed (or '' on
  /// Backspace).
  final ValueChanged<String>? onLetterTyped;

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? PlateTheme.of(context);

    return BlocBuilder<PlateCardBloc, PlateCardState>(
      builder: (BuildContext context, PlateCardState state) {
        final value = state.plateNumber.values[indexInPlateTypes];
        final isEmpty = value == null || value.isEmpty;

        if (mode == PlateMode.display) {
          return SizedBox(
            width: slotHeight * 0.72,
            height: slotHeight,
            child: Center(
              child: isEmpty
                  ? const SizedBox.shrink()
                  : Text(
                      value,
                      textAlign: TextAlign.center,
                      style: PlateDigit.styleFor(
                          slotHeight, effectiveTheme.ink),
                    ),
            ),
          );
        }

        final letter = isEmpty
            ? defaultLetterIcon ??
                Text(
                  '؟',
                  textAlign: TextAlign.center,
                  style: PlateDigit.styleFor(
                      slotHeight, effectiveTheme.inactiveColor),
                )
            : Text(
                value,
                textAlign: TextAlign.center,
                style: PlateDigit.styleFor(slotHeight, effectiveTheme.ink),
              );

        Widget slot(Color underlineColor) => SizedBox(
              width: slotHeight * 0.72,
              height: slotHeight,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: underlineColor),
                  ),
                ),
                child: Center(child: letter),
              ),
            );

        final restingColor = isEmpty
            ? effectiveTheme.inactiveColor
            : effectiveTheme.activeColor;

        // Both keyboard and hostKeypad make the slot focusable and drive the
        // underline off focus rather than opening a sheet. Only keyboard mode
        // consumes key events; hostKeypad receives its letter from the app's
        // on-screen pad via the bloc, so it just claims focus on tap.
        if (letterInputMode == LetterInputMode.keyboard ||
            letterInputMode == LetterInputMode.hostKeypad) {
          final bool isKeyboard = letterInputMode == LetterInputMode.keyboard;
          return Focus(
            focusNode: focusNode,
            onKeyEvent: isKeyboard
                ? (node, event) {
                    if (event is! KeyDownEvent) return KeyEventResult.ignored;
                    if (event.logicalKey == LogicalKeyboardKey.backspace) {
                      onLetterTyped?.call('');
                      return KeyEventResult.handled;
                    }
                    final ch = event.character;
                    if (ch != null &&
                        ch.length == 1 &&
                        persianCarPlateLetters.contains(ch)) {
                      onLetterTyped?.call(ch);
                      return KeyEventResult.handled;
                    }
                    // Everything else (digits, arrows, ...) reaches the next
                    // field.
                    return KeyEventResult.ignored;
                  }
                : null,
            child: Builder(
              builder: (context) {
                final hasFocus = Focus.of(context).hasFocus;
                return GestureDetector(
                  onTap: () => focusNode?.requestFocus(),
                  child: slot(
                    hasFocus ? effectiveTheme.activeColor : restingColor,
                  ),
                );
              },
            ),
          );
        }

        return InkWell(
          onTap: onPressed,
          child: slot(restingColor),
        );
      },
    );
  }
}
