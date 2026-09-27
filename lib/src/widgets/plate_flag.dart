import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../model/plate_asset.dart';
import '../model/plate_country.dart';

/// Renders a country's flag from its asset; first frame pays the parse cost.
/// Warms the asset in `didChangeDependencies` if animating plates into view.
class PlateFlag extends StatelessWidget {
  const PlateFlag({super.key, required this.country, this.borderRadius});

  final PlateCountry country;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final asset = country.flag;
    if (asset == null) return const SizedBox.shrink();

    Widget flag = switch (asset) {
      SvgPlateAsset() => SvgPicture.asset(asset.path, package: asset.package, fit: BoxFit.fill),
      RasterPlateAsset() => Image.asset(asset.path, package: asset.package, fit: BoxFit.fill),
    };

    if (borderRadius != null) {
      flag = ClipRRect(borderRadius: BorderRadius.circular(borderRadius!), child: flag);
    }

    final borderColor = country.flagBorderColor;
    if (borderColor == null) return flag;
    return Container(
      foregroundDecoration: BoxDecoration(border: Border.all(color: borderColor, width: 1)),
      child: flag,
    );
  }
}
