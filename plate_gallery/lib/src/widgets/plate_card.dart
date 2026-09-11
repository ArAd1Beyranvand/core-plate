import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';

import '../catalogue.dart';

/// One plate with its label — the unit the catalogue is made of.
///
/// The merge of the sample-card pair the two showcase apps each carried, which
/// were the most divergent of the four shared widgets. Nothing here names a
/// country: everything that varies per country arrives on the [GalleryEntry],
/// including the livery, which for Gaza is a fact about the value rather than a
/// choice — see [GalleryEntry.themeFor].
///
/// [PlateView] rather than `ShowPlate` because it takes a [PlateTheme] and a
/// [PlateCountry]: a northern Yemeni plate's colour *is* its usage class, so a
/// green government plate rendered white would be a different plate.
class PlateCard extends StatefulWidget {
  const PlateCard({super.key, required this.entry, this.onTap});

  final GalleryEntry entry;

  /// Opens this entry in the playground. Null makes the card inert.
  final VoidCallback? onTap;

  /// Every card is drawn to the same height and takes its width from the spec's
  /// own aspect ratio, so a long car plate and a square motorcycle plate sit on
  /// one row without either being distorted.
  static const double plateHeight = 74;

  @override
  State<PlateCard> createState() => _PlateCardState();
}

class _PlateCardState extends State<PlateCard> {
  /// Scoped to this card. One controller shared across the page would make
  /// every plate on it show the same value.
  late final PlateController _plate = PlateController(spec: widget.entry.spec, values: widget.entry.sampleValues);

  @override
  void dispose() {
    _plate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GalleryEntry entry = widget.entry;
    final PlateSpec spec = entry.spec;
    final PlateTheme? livery = entry.themeFor(_plate.values);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: SizedBox(
                  height: PlateCard.plateHeight,
                  width: PlateCard.plateHeight * spec.canvasWidth / spec.canvasHeight,
                  child: PlateView(controller: _plate, theme: livery, country: entry.country),
                ),
              ),
              const SizedBox(height: 12),
              Text(entry.label, style: theme.textTheme.titleSmall),
              Text(
                entry.note ?? spec.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The cards of one section, in as many columns as fit at a comfortable width.
///
/// [Wrap] rather than [GridView] on purpose: a Yemeni car plate is 3.5 times as
/// wide as it is tall and a two-line Palestinian one is nearly square, so a
/// fixed aspect ratio would letterbox one or crop the other.
class PlateCardGrid extends StatelessWidget {
  const PlateCardGrid({super.key, required this.entries, this.onTap});

  final List<GalleryEntry> entries;
  final ValueChanged<GalleryEntry>? onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final int columns = (constraints.maxWidth / 280).floor().clamp(1, 4);
      const double gap = 12;
      final double width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      final ValueChanged<GalleryEntry>? onTap = this.onTap;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: <Widget>[
          for (final GalleryEntry entry in entries)
            SizedBox(
              width: width,
              child: PlateCard(
                key: ValueKey<String>(entry.id),
                entry: entry,
                onTap: onTap == null ? null : () => onTap(entry),
              ),
            ),
        ],
      );
    },
  );
}
