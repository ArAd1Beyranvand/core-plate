import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../model/plate_asset.dart';
import '../model/plate_country.dart';

/// A country's flag, rendered from the asset the country ships and sized to
/// fill its parent.
///
/// Every country now ships a vector (or raster) of its own flag — see
/// [PlateAsset]. There is one rendering path: a detailed emblem (fine script
/// around a border, say) that a pre-quantized shared bitmap format would read
/// as pixelation at plate scale (~20px tall) stays crisp because the raw
/// vector is drawn at the exact device-pixel size.
///
/// A country with no flag asset renders nothing.
class PlateFlag extends StatelessWidget {
  const PlateFlag({super.key, required this.country, this.borderRadius});

  /// The country whose [PlateCountry.flag] asset to render.
  final PlateCountry country;

  /// Optional corner rounding, in logical pixels. When null the flag is drawn
  /// as a plain rectangle.
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final asset = country.flag;
    if (asset == null) return const SizedBox.shrink();

    final Widget flag = switch (asset) {
      SvgPlateAsset() => SvgPicture.asset(
        asset.path,
        package: asset.package,
        fit: BoxFit.fill,
      ),
      RasterPlateAsset() => Image.asset(
        asset.path,
        package: asset.package,
        fit: BoxFit.fill,
      ),
    };

    if (borderRadius == null) return flag;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius!),
      child: flag,
    );
  }
}
