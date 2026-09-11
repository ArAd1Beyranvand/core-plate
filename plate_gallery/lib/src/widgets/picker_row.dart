import 'package:flutter/material.dart';

/// A labelled row of choice chips, wrapping onto as many lines as it needs.
///
/// One copy of the near-identical picker row both showcase apps carried.
class PickerRow extends StatelessWidget {
  const PickerRow({
    super.key,
    required this.label,
    required this.children,
    this.note,
  });

  final String label;
  final String? note;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? note = this.note;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: children),
          if (note != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One chip per value of [values], selected when it equals [selected].
///
/// Both apps wrote the chip loop out at every picker; only the label function
/// varied, so it is a parameter. A null [onSelected] disables the chips.
class ChipPicker<T> extends StatelessWidget {
  const ChipPicker({
    super.key,
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.note,
  });

  final String label;
  final List<T> values;
  final T? selected;
  final String Function(T value) labelOf;
  final ValueChanged<T>? onSelected;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final ValueChanged<T>? onSelected = this.onSelected;
    return PickerRow(
      label: label,
      note: note,
      children: <Widget>[
        for (final T value in values)
          ChoiceChip(
            label: Text(labelOf(value)),
            selected: value == selected,
            onSelected: onSelected == null ? null : (_) => onSelected(value),
          ),
      ],
    );
  }
}
