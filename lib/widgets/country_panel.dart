import 'package:flutter/widgets.dart';

import '../model/plate_country.dart';
import '../model/plate_spec.dart';
import '../theme/plate_theme.dart';
import 'plate_flag.dart';

/// The coloured block on the left of a plate: the flag over the country
/// caption (e.g. "I.R." / "IRAN"). Sized by its parent (square-ish); always
/// laid out LTR even inside an RTL plate.
///
/// Everything country-specific (flag, caption, panel colours) comes from
/// [country]; adding a new country is a new [PlateCountry], not a new widget.
class CountryPanel extends StatelessWidget {
  const CountryPanel({
    super.key,
    required this.panel,
    this.theme,
    this.country = PlateCountry.iran,
  });

  /// Colours to paint with. Falls back to [PlateTheme.of] / standard when null.
  /// Only used for values that are not country-specific.
  final PlateTheme? theme;

  /// The country whose flag, caption and panel colours to render.
  final PlateCountry country;

  /// Layout of the flag + caption inside the block. Only [PlatePanel.flagScale],
  /// [PlatePanel.captionScale] and [PlatePanel.padding] are read here; the box
  /// positions the panel on the plate and is the canvas's concern.
  final PlatePanel panel;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: country.panelColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final uniformPad = constraints.maxHeight * 0.10;
            final resolvedPadding = panel.padding ?? EdgeInsets.all(uniformPad);
            final innerW = constraints.maxWidth - resolvedPadding.horizontal;
            final innerH = constraints.maxHeight - resolvedPadding.vertical;
            // Flag: scale the width by flagScale; height follows the
            // country's flag aspect ratio, clamped to the available height so
            // small panels never overflow.
            var flagW = innerW * panel.flagScale;
            var flagH = flagW / country.flagAspectRatio;
            if (flagH > innerH) {
              flagH = innerH;
              flagW = flagH * country.flagAspectRatio;
            }
            final captionH = (innerH - flagH).clamp(0.0, innerH);
            return Padding(
              padding: resolvedPadding,
              // Flag pinned to the top, caption pinned to the bottom, with the
              // slack between them (matches a real Iranian plate's panel).
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: flagW,
                    height: flagH,
                    child: PlateFlag(countryCode: country.code),
                  ),
                  SizedBox(
                    height: captionH,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: _Caption(
                        lines: country.captionLines,
                        color: country.panelTextColor,
                        scale: panel.captionScale,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.lines, required this.color, this.scale = 1.0});

  final List<String> lines;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: color,
      fontWeight: FontWeight.w800,
      height: 1.0,
      fontSize: 24 * scale,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in lines) Text(line, style: style),
      ],
    );
  }
}
