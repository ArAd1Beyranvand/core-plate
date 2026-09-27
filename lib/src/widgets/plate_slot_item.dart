import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/plate_alphabet.dart';
import '../model/plate_spec.dart';
import '../model/slot_behavior.dart';
import '../theme/plate_theme.dart';

/// One plate position, driven by [PlateSlot] and [SlotBehavior]. Never reads
/// the bloc; [behavior] is resolved once and switched on, not re-derived.
class PlateSlotItem extends StatelessWidget {
  const PlateSlotItem({
    super.key,
    required this.slot,
    required this.behavior,
    required this.value,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onCompleted,
    required this.onBackspace,
    this.theme,
    this.onPressed,
  });

  final PlateSlot slot;
  final SlotBehavior behavior;
  final String? value;
  final TextEditingController? controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCompleted;
  final VoidCallback? onBackspace;
  final PlateTheme? theme;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? PlateTheme.of(context);
    final isTyped = slot.alphabet.input == AlphabetInput.typed;

    switch (behavior) {
      case SlotBehavior.glyph:
        return _GlyphSlot(slot: slot, value: value, theme: effectiveTheme);

      case SlotBehavior.imeField:
        return _TypedField(
          slot: slot,
          behavior: behavior,
          controller: controller!,
          focusNode: focusNode,
          onChanged: onChanged,
          onCompleted: onCompleted,
          onBackspace: onBackspace,
          theme: effectiveTheme,
        );

      case SlotBehavior.hardwareField:
        if (isTyped) {
          return _TypedField(
            slot: slot,
            behavior: behavior,
            controller: controller!,
            focusNode: focusNode,
            onChanged: onChanged,
            onCompleted: onCompleted,
            onBackspace: onBackspace,
            theme: effectiveTheme,
          );
        }
        return _ChosenSlot(
          slot: slot,
          behavior: behavior,
          value: value,
          focusNode: focusNode,
          onChanged: onChanged,
          onPressed: onPressed,
          onBackspace: onBackspace,
          theme: effectiveTheme,
        );

      case SlotBehavior.externalField:
        if (isTyped) {
          return _TypedField(
            slot: slot,
            behavior: behavior,
            controller: controller!,
            focusNode: focusNode,
            onChanged: onChanged,
            onCompleted: onCompleted,
            onBackspace: onBackspace,
            theme: effectiveTheme,
          );
        }
        return _ChosenSlot(
          slot: slot,
          behavior: behavior,
          value: value,
          focusNode: focusNode,
          onChanged: onChanged,
          onPressed: onPressed,
          onBackspace: onBackspace,
          theme: effectiveTheme,
        );

      case SlotBehavior.sheet:
        return _ChosenSlot(
          slot: slot,
          behavior: behavior,
          value: value,
          focusNode: focusNode,
          onChanged: onChanged,
          onPressed: onPressed,
          onBackspace: onBackspace,
          theme: effectiveTheme,
        );
    }
  }
}

/// Bare rendered character (glyph slot).
class _GlyphSlot extends StatelessWidget {
  const _GlyphSlot({required this.slot, required this.value, required this.theme});

  final PlateSlot slot;
  final String? value;
  final PlateTheme theme;

  @override
  Widget build(BuildContext context) {
    final v = value ?? '';
    return SizedBox(
      width: slot.box.width,
      height: slot.box.height,
      child: v.isEmpty
          ? null
          : Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  slot.alphabet.render(v),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: theme.glyphStyle(slot.box.height, theme.ink),
                ),
              ),
            ),
    );
  }
}

/// TextField restyled to a bare glyph with thin underline.
class _TypedField extends StatelessWidget {
  const _TypedField({
    required this.slot,
    required this.behavior,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onCompleted,
    required this.onBackspace,
    required this.theme,
  });

  final PlateSlot slot;
  final SlotBehavior behavior;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCompleted;
  final VoidCallback? onBackspace;
  final PlateTheme theme;

  @override
  Widget build(BuildContext context) {
    final isEmpty = controller.text.isEmpty;
    final underlineColor = isEmpty ? theme.inactiveColor : theme.activeColor;

    final readOnly = behavior == SlotBehavior.externalField;

    return SizedBox(
      width: slot.box.width,
      height: slot.box.height,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
          if (event.logicalKey != LogicalKeyboardKey.backspace) return KeyEventResult.ignored;
          if (!readOnly && controller.text.isNotEmpty) return KeyEventResult.ignored;
          onBackspace?.call();
          return KeyEventResult.handled;
        },
        child: ListenableBuilder(
          listenable: focusNode,
          builder: (context, _) => TextField(
            controller: controller,
            focusNode: focusNode,
            readOnly: readOnly,
            onTapOutside: readOnly ? (PointerDownEvent _) {} : null,
            showCursor: readOnly ? focusNode.hasFocus : null,
            textAlign: TextAlign.center,
            style: theme.glyphStyle(slot.box.height, theme.ink),
            cursorColor: theme.activeColor,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: slot.box.height * 0.12),
              filled: false,
              counterText: '',
              hintText: slot.alphabet.placeholder,
              hintStyle: theme.glyphStyle(slot.box.height, theme.inactiveColor),
              border: UnderlineInputBorder(borderSide: BorderSide(color: theme.inactiveColor)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: underlineColor)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.activeColor)),
            ),
            onChanged: (typed) {
              if (slot.alphabet.accepts(typed)) {
                onChanged(slot.alphabet.canonical(typed));
                if (typed != '') {
                  if (onCompleted != null) onCompleted!();
                }
              } else {
                controller.text = '';
                onChanged('');
              }
            },
            maxLength: 1,
            keyboardType: behavior == SlotBehavior.hardwareField
                ? TextInputType.none
                : slot.alphabet.isNumeric
                ? TextInputType.number
                : TextInputType.text,
          ),
        ),
      ),
    );
  }
}

/// Focusable slot with underline; placeholder glyph when empty.
class _ChosenSlot extends StatelessWidget {
  const _ChosenSlot({
    required this.slot,
    required this.behavior,
    required this.value,
    required this.focusNode,
    required this.onChanged,
    required this.onPressed,
    required this.onBackspace,
    required this.theme,
  });

  final PlateSlot slot;
  final SlotBehavior behavior;
  final String? value;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onPressed;
  final VoidCallback? onBackspace;
  final PlateTheme theme;

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == null || value!.isEmpty;

    final letter = isEmpty
        ? Text(
            slot.alphabet.placeholder,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: theme.glyphStyle(slot.box.height, theme.inactiveColor),
          )
        : Text(
            slot.alphabet.render(value!),
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: theme.glyphStyle(slot.box.height, theme.ink),
          );

    Widget slotBox(Color underlineColor) => SizedBox(
      width: slot.box.width,
      height: slot.box.height,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: underlineColor)),
        ),
        child: Center(
          child: FittedBox(fit: BoxFit.scaleDown, child: letter),
        ),
      ),
    );

    final restingColor = isEmpty ? theme.inactiveColor : theme.activeColor;

    if (behavior == SlotBehavior.sheet) {
      return InkWell(onTap: onPressed, child: slotBox(restingColor));
    }

    final consumesKeys = behavior == SlotBehavior.hardwareField;
    return Focus(
      focusNode: focusNode,
      onKeyEvent: consumesKeys
          ? (node, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              if (event.logicalKey == LogicalKeyboardKey.backspace) {
                if (isEmpty) {
                  onBackspace?.call();
                } else {
                  onChanged('');
                }
                return KeyEventResult.handled;
              }
              final ch = event.character;
              if (ch != null && ch.length == 1 && slot.alphabet.accepts(ch)) {
                onChanged(slot.alphabet.canonical(ch));
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            }
          : null,
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return GestureDetector(
            onTap: () => focusNode.requestFocus(),
            child: slotBox(hasFocus ? theme.activeColor : restingColor),
          );
        },
      ),
    );
  }
}
