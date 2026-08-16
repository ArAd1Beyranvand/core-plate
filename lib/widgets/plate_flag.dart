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

  @override
  Widget build(BuildContext context) {
    // country_flags requires an explicit size; let the parent decide it and
    // preserve the flag's intrinsic aspect ratio.
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _resolveSize(constraints);
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

/// Deprecated thin alias for the Iranian flag. Use
/// `PlateFlag(countryCode: 'ir')` instead.
@Deprecated('Use PlateFlag(countryCode: "ir") instead. '
    'IranFlag will be removed in a future release.')
class IranFlag extends StatelessWidget {
  @Deprecated('Use PlateFlag(countryCode: "ir") instead.')
  const IranFlag({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlateFlag(countryCode: 'ir');
}
