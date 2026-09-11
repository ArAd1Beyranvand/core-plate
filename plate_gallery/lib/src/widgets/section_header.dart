import 'package:flutter/material.dart';

/// A heading over a run of plates, with the paragraph that says what they are.
///
/// The merge of the section headers both apps carried: a small-caps title, an
/// optional count on the right, and an optional note underneath.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.note, this.count});

  final String title;
  final String? note;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? note = this.note;
    final int? count = this.count;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            if (count != null)
              Text('$count', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        if (note != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(note, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ],
    );
  }
}

/// A titled card the pickers sit in — the other private section both apps had,
/// which wrapped its child in a [Card] rather than heading a scroll region.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: child),
        ),
      ],
    );
  }
}
