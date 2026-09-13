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
///
/// **The first frame that shows a flag pays for it.** The vector is parsed, or
/// the bitmap decoded, the first time this widget paints — and if that first
/// paint coincides with the start of an animation (a card sliding in, a spec
/// being swapped), the parse lands inside the animation's first frame and shows
/// as a stutter right at the start. This widget deliberately does not cache
/// across mounts: it cannot know which countries a host is about to show, and
/// holding every flag a process has ever rendered is the host's decision, not
/// core's.
///
/// A host that animates a plate into view should warm the assets first, from
/// `didChangeDependencies` of the screen that is about to show them — a
/// `precacheImage` for a [RasterPlateAsset], and flutter_svg's own cache for an
/// [SvgPlateAsset].
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

    Widget flag = switch (asset) {
      SvgPlateAsset() => SvgPicture.asset(asset.path, package: asset.package, fit: BoxFit.fill),
      RasterPlateAsset() => Image.asset(asset.path, package: asset.package, fit: BoxFit.fill),
    };

    if (borderRadius != null) {
      flag = ClipRRect(borderRadius: BorderRadius.circular(borderRadius!), child: flag);
    }

    final borderColor = country.flagBorderColor;
    if (borderColor == null) return flag;
    // Container's foregroundDecoration, not DecoratedBox: the flag itself is
    // opaque and fills the whole box, so a border painted underneath it would
    // be completely covered rather than framing it.
    return Container(
      foregroundDecoration: BoxDecoration(border: Border.all(color: borderColor, width: 1)),
      child: flag,
    );
  }
}
