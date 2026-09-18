import 'package:flutter/widgets.dart';

import '../model/plate_country.dart';
import '../model/plate_spec.dart';
import '../theme/plate_theme.dart';
import 'plate_flag.dart';

/// The coloured block on the left of a plate: the flag over the country
/// caption (a short code beside the flag). Sized by its parent (square-ish);
/// always laid out LTR even inside an RTL plate.
///
/// Everything country-specific (flag, caption, panel colours) comes from
/// [country]; adding a new country is a new [PlateCountry], not a new widget.
class CountryPanel extends StatelessWidget {
  const CountryPanel({super.key, required this.panel, this.theme, required this.country});

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
            final flag = _flagSize(panel: panel, country: country, innerW: innerW, innerH: innerH);
            final caption = SizedBox(
              width: panel.direction == Axis.horizontal ? (innerW - flag.width).clamp(0.0, innerW) : null,
              height: panel.direction == Axis.vertical ? (innerH - flag.height).clamp(0.0, innerH) : null,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _Caption(lines: country.captionLines, color: country.panelTextColor, scale: panel.captionScale),
              ),
            );
            final flagBox = SizedBox(width: flag.width, height: flag.height, child: PlateFlag(country: country));
            return Padding(
              padding: resolvedPadding,
              // Flag pinned to one end, caption pinned to the other, with the
              // slack between them (matches a real plate's panel).
              child: panel.direction == Axis.horizontal
                  ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [flagBox, caption])
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [flagBox, caption],
                    ),
            );
          },
        ),
      ),
    );
  }
}

/// The flag's size inside the panel: [PlatePanel.flagScale] of the axis that
/// is shared with the caption ([Axis.horizontal] scales width, [Axis.vertical]
/// scales height), clamped to the other axis so the flag never overflows.
Size _flagSize({required PlatePanel panel, required PlateCountry country, required double innerW, required double innerH}) {
  if (panel.direction == Axis.horizontal) {
    var flagH = innerH * panel.flagScale;
    var flagW = flagH * country.flagAspectRatio;
    if (flagW > innerW) {
      flagW = innerW;
      flagH = flagW / country.flagAspectRatio;
    }
    return Size(flagW, flagH);
  }
  var flagW = innerW * panel.flagScale;
  var flagH = flagW / country.flagAspectRatio;
  if (flagH > innerH) {
    flagH = innerH;
    flagW = flagH * country.flagAspectRatio;
  }
  return Size(flagW, flagH);
}

class _Caption extends StatelessWidget {
  const _Caption({required this.lines, required this.color, this.scale = 1.0});

  final List<String> lines;
  final Color color;
  final double scale;

  static const double _baseFontSize = 24.0;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: color, fontWeight: FontWeight.w800, height: 1.0, fontSize: _baseFontSize * scale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [for (final line in lines) Text(line, style: style)],
    );
  }
}
