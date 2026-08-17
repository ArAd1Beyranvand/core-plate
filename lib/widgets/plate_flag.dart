import 'package:country_flags/country_flags.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A national flag rendered from a proper SVG vector source, sized to fill its
/// parent.
///
/// Flags are looked up by ISO 3166-1 alpha-2 code (e.g. `ir`). The intrinsic
/// aspect ratio of each flag is preserved, so at plate scale (~20px tall) the
/// artwork stays crisp instead of the hand-drawn approximation it replaces.
///
/// Where we ship our own high-fidelity SVG for a country (see [_svgAssets]) it
/// is rendered directly with `flutter_svg`, which rasterises the live vector at
/// the exact device-pixel size. Everything else falls back to the
/// `country_flags` package, which pre-compiles each flag to a quantized binary
/// (`.si`) format ahead of time — fine for simple tricolours, but coarse enough
/// on a detailed emblem (Iran's, its Kufic-script border) to read as pixelation
/// at plate scale. Shipping the raw SVG for those sidesteps the quantization.
class PlateFlag extends StatelessWidget {
  const PlateFlag({super.key, required this.countryCode, this.borderRadius});

  /// ISO 3166-1 alpha-2 country code, case-insensitive.
  final String countryCode;

  /// Optional corner rounding, in logical pixels. When null the flag is drawn
  /// as a plain rectangle.
  final double? borderRadius;

  /// Country codes (lower-case) we ship a crisp SVG asset for, mapped to the
  /// asset path inside this package.
  static const Map<String, String> _svgAssets = {
    'ir': 'assets/flags/Flag_of_Iran.svg',
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _resolveSize(constraints);

        final asset = _svgAssets[countryCode.toLowerCase()];
        if (asset != null) {
          final flag = SvgPicture.asset(
            asset,
            package: 'plate_number',
            width: size.width,
            height: size.height,
            fit: BoxFit.fill,
          );
          if (borderRadius == null) return flag;
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius!),
            child: flag,
          );
        }

        // country_flags requires an explicit size; let the parent decide it and
        // preserve the flag's intrinsic aspect ratio.
        return CountryFlag.fromCountryCode(
          countryCode,
          theme: ImageTheme(
            width: size.width,
            height: size.height,
            shape: borderRadius == null
                ? const Rectangle()
                : RoundedRectangle(borderRadius!),
          ),
        );
      },
    );
  }

  /// Picks a finite width/height from [constraints], falling back to a sensible
  /// default when a dimension is unbounded.
  Size _resolveSize(BoxConstraints constraints) {
    var width = constraints.maxWidth;
    var height = constraints.maxHeight;
    if (!width.isFinite && !height.isFinite) {
      return const Size(21, 12); // 7:4 fallback
    }
    if (!width.isFinite) width = height * 7 / 4;
    if (!height.isFinite) height = width * 4 / 7;
    return Size(width, height);
  }
}
