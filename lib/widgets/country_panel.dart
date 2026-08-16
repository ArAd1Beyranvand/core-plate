import 'package:flutter/widgets.dart';

import '../model/plate_country.dart';
import '../theme/plate_theme.dart';
import 'plate_flag.dart';

/// The coloured block on the left of a plate: the flag over the country
/// caption (e.g. "I.R." / "IRAN"). Sized by its parent (square-ish); always
/// laid out LTR even inside an RTL plate.
///
/// Everything country-specific (flag, caption, panel colours) comes from
/// [country]; adding a new country is a new [PlateCountry], not a new widget.
class CountryPanel extends StatelessWidget {
  const CountryPanel({super.key, this.theme, this.country = PlateCountry.iran});

  /// Colours to paint with. Falls back to [PlateTheme.of] / standard when null.
  /// Only used for values that are not country-specific.
  final PlateTheme? theme;

  /// The country whose flag, caption and panel colours to render.
  final PlateCountry country;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: country.panelColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pad = constraints.maxHeight * 0.10;
            return Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PlateFlag(countryCode: country.code),
                  SizedBox(height: pad * 0.6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: _Caption(
                        lines: country.captionLines,
                        color: country.panelTextColor,
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
  const _Caption({required this.lines, required this.color});

  final List<String> lines;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: color,
      fontWeight: FontWeight.w800,
      height: 1.0,
      fontSize: 24,
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
