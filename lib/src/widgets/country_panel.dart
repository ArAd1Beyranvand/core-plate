import 'package:flutter/widgets.dart';

import '../model/plate_country.dart';
import '../model/plate_spec.dart';
import '../theme/plate_theme.dart';
import 'plate_flag.dart';

/// Coloured block on left of plate: flag and country caption, laid out LTR
/// regardless of plate direction. Everything country-specific is a [PlateCountry].
class CountryPanel extends StatelessWidget {
  const CountryPanel({
    super.key,
    required this.panel,
    this.theme,
    required this.country,
    this.paintBlock = true,
  });

  final PlateTheme? theme;
  final PlateCountry country;
  final PlatePanel panel;

  /// False when the plate's background already paints the block as a
  /// [PlateFill.panel] region — the panel then lays out only the flag and
  /// wording, so no box edge of its own sits against the border.
  final bool paintBlock;

  @override
  Widget build(BuildContext context) {
    // Outside the ColoredBox, so the shape cuts the block's own colour and not
    // just what is laid out on it. Absent for every country whose block is the
    // plain rectangle of `panel.box` — see [PlatePanel.shape].
    final shape = panel.shape;
    if (shape != null) {
      return ClipPath(
        clipper: shape,
        child: _Block(
          panel: panel,
          theme: theme,
          country: country,
          paintBlock: paintBlock,
        ),
      );
    }
    return _Block(
      panel: panel,
      theme: theme,
      country: country,
      paintBlock: paintBlock,
    );
  }
}

/// The block itself: the country's colour, and the flag and wording on it.
class _Block extends StatelessWidget {
  const _Block({
    required this.panel,
    required this.theme,
    required this.country,
    required this.paintBlock,
  });

  final bool paintBlock;
  final PlateTheme? theme;
  final PlateCountry country;
  final PlatePanel panel;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: paintBlock ? country.panelColor : const Color(0x00000000),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final uniformPad = constraints.maxHeight * 0.10;
            final resolvedPadding = panel.padding ?? EdgeInsets.all(uniformPad);
            final innerW = constraints.maxWidth - resolvedPadding.horizontal;
            final innerH = constraints.maxHeight - resolvedPadding.vertical;
            final flag = _flagSize(
              panel: panel,
              country: country,
              innerW: innerW,
              innerH: innerH,
            );
            final horizontal = panel.direction == Axis.horizontal;
            // The room the flag leaves, and how many pieces of wording have to
            // share it. A heading and a caption split it evenly; either one
            // alone takes the lot, which is the layout this widget has always
            // had.
            final hasHeading = country.headingLines.isNotEmpty;
            final slackW = horizontal
                ? (innerW - flag.width).clamp(0.0, innerW)
                : null;
            final slackH = horizontal
                ? null
                : (innerH - flag.height).clamp(0.0, innerH);
            final share = hasHeading ? 0.5 : 1.0;

            final flagBox = SizedBox(
              width: flag.width,
              height: flag.height,
              child: PlateFlag(country: country),
            );
            final children = <Widget>[
              if (hasHeading)
                _PanelWording(
                  lines: country.headingLines,
                  color: country.panelTextColor,
                  scale: panel.captionScale,
                  alignment: Alignment.centerLeft,
                  width: slackW == null ? null : slackW * share,
                  height: slackH == null ? null : slackH * share,
                ),
              horizontal ? flagBox : Center(child: flagBox),
              _PanelWording(
                lines: country.captionLines,
                color: country.panelTextColor,
                scale: panel.captionScale,
                alignment: horizontal
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                width: slackW == null ? null : slackW * share,
                height: slackH == null ? null : slackH * share,
              ),
            ];
            return Padding(
              padding: resolvedPadding,
              child: horizontal
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: children,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: children,
                    ),
            );
          },
        ),
      ),
    );
  }
}

Size _flagSize({
  required PlatePanel panel,
  required PlateCountry country,
  required double innerW,
  required double innerH,
}) {
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

/// One band of wording (heading or caption), scaled to available space.
class _PanelWording extends StatelessWidget {
  const _PanelWording({
    required this.lines,
    required this.color,
    required this.scale,
    required this.alignment,
    required this.width,
    required this.height,
  });

  final List<String> lines;
  final Color color;
  final double scale;
  final Alignment alignment;
  final double? width, height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: _Caption(lines: lines, color: color, scale: scale),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.lines, required this.color, this.scale = 1.0});

  final List<String> lines;
  final Color color;
  final double scale;

  static const double _baseFontSize = 24.0;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: color,
      fontWeight: FontWeight.w800,
      height: 1.0,
      fontSize: _baseFontSize * scale,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [for (final line in lines) Text(line, style: style)],
    );
  }
}
