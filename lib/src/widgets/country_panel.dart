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
            final horizontal = panel.direction == Axis.horizontal;
            // The room the flag leaves, and how many pieces of wording have to
            // share it. A heading and a caption split it evenly; either one
            // alone takes the lot, which is the layout this widget has always
            // had.
            final hasHeading = country.headingLines.isNotEmpty;
            final slackW = horizontal ? (innerW - flag.width).clamp(0.0, innerW) : null;
            final slackH = horizontal ? null : (innerH - flag.height).clamp(0.0, innerH);
            final share = hasHeading ? 0.5 : 1.0;

            final flagBox = SizedBox(width: flag.width, height: flag.height, child: PlateFlag(country: country));
            final children = <Widget>[
              // The heading sits on the far side of the flag from the caption.
              // In the horizontal layout that means pinning to the opposite
              // edge — the caption clings to the end of the panel, the heading
              // to its start. In the vertical one both stay left-aligned,
              // because the panel's two lines of wording share a left margin
              // however the flag between them is centred.
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
                alignment: horizontal ? Alignment.centerRight : Alignment.centerLeft,
                width: slackW == null ? null : slackW * share,
                height: slackH == null ? null : slackH * share,
              ),
            ];
            return Padding(
              padding: resolvedPadding,
              // Flag pinned to one end, caption pinned to the other, with the
              // slack between them (matches a real plate's panel) — or, where
              // there is a heading too, the flag in the middle with a band of
              // wording above and below it. In the vertical layout the wording
              // stays left-aligned but the flag is centred across the panel's
              // width, rather than sharing the wording's left edge.
              child: horizontal
                  ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: children)
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

/// One band of wording in the panel — the heading above the flag, or the
/// caption below it — scaled down to whatever room the flag left it.
///
/// The two are one widget with different lines and a different alignment,
/// because that is all that separates them.
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

  /// Where the wording sits inside the room it is given. Vertical: the box runs
  /// from the flag to the panel's near edge, left-aligned like the flag beside
  /// it. Horizontal: the box runs from the flag to the panel's far edge, and
  /// pinning to that edge mirrors the flag sitting flush against the padding on
  /// its own side, so the gap between them reads as deliberate spacing rather
  /// than as the wording clinging to one side of its box.
  final Alignment alignment;

  /// The band's extent along the axis it shares with the flag; null on the
  /// other axis, which the panel's own cross-axis stretch settles.
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
    final style = TextStyle(color: color, fontWeight: FontWeight.w800, height: 1.0, fontSize: _baseFontSize * scale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [for (final line in lines) Text(line, style: style)],
    );
  }
}
