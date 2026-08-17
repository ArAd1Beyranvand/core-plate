import 'package:country_flags/country_flags.dart';
import 'package:flutter/widgets.dart';

/// A national flag rendered from a proper SVG vector source (via the
/// `country_flags` package / jovial_svg), sized to fill its parent.
///
/// Flags are looked up by ISO 3166-1 alpha-2 code (e.g. `ir`). The intrinsic
/// aspect ratio of each flag is preserved, so at plate scale (~20px tall) the
/// artwork stays crisp instead of the hand-drawn approximation it replaces.
class PlateFlag extends StatelessWidget {
  const PlateFlag({super.key, required this.countryCode, this.borderRadius});

  /// ISO 3166-1 alpha-2 country code, case-insensitive.
  final String countryCode;

  /// Optional corner rounding, in logical pixels. When null the flag is drawn
  /// as a plain rectangle.
  final double? borderRadius;

  /// Below this width, flags are rendered at [_supersampleWidth] and scaled
  /// down instead of being asked to draw at their true (tiny) size.
  ///
  /// `country_flags` compiles each SVG to a quantized binary format ahead of
  /// time; on a detailed flag (Iran's emblem, its Kufic-script border) that
  /// quantization is coarse enough relative to a ~20px-tall plate flag to
  /// read as pixelation rather than fine detail. Rendering at a larger fixed
  /// size and letting [FittedBox] downscale the result keeps the same
  /// vector draw (so the quantization step size is unchanged) but shrinks it
  /// with filtering, which hides the artefact the way downsampling a raster
  /// image would.
  static const double _supersampleWidth = 96;

  @override
  Widget build(BuildContext context) {
    // country_flags requires an explicit size; let the parent decide it and
    // preserve the flag's intrinsic aspect ratio.
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _resolveSize(constraints);
        final shape = borderRadius == null
            ? const Rectangle()
            : RoundedRectangle(borderRadius!);
        if (size.width >= _supersampleWidth) {
          return CountryFlag.fromCountryCode(
            countryCode,
            theme: ImageTheme(width: size.width, height: size.height, shape: shape),
          );
        }
        final renderSize = Size(
          _supersampleWidth,
          _supersampleWidth * size.height / size.width,
        );
        return SizedBox.fromSize(
          size: size,
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox.fromSize(
              size: renderSize,
              child: CountryFlag.fromCountryCode(
                countryCode,
                theme: ImageTheme(
                  width: renderSize.width,
                  height: renderSize.height,
                  shape: shape,
                ),
              ),
            ),
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
