import 'package:flutter/widgets.dart';
import 'package:plate_core/plate_core.dart';

import 'riyadh_colors.dart';

/// Riyadh as a `PlateCountry`. The strip's colour is the panel colour, so
/// the category is the country: pass the one matching the spec to the canvas.
/// The strip's wording and symbol are labels on the spec, not captions here;
/// the emblem (Wikimedia `Emblem_of_Saudi_Arabia.svg`, in one ink) is the flag.
abstract final class RiyadhCountry {
  static final PlateCountry private = _strip(RiyadhColors.white);
  static final PlateCountry publicTransport = _strip(RiyadhColors.yellow);
  static final PlateCountry commercial = _strip(RiyadhColors.blue);
  static final PlateCountry temporary = _strip(RiyadhColors.silver);
  static final PlateCountry diplomatic = _strip(RiyadhColors.green);

  /// Category id (as in the goldens) -> country.
  static final Map<String, PlateCountry> byCategory = <String, PlateCountry>{
    'private': private,
    'public_transport': publicTransport,
    'commercial': commercial,
    'temporary': temporary,
    'diplomatic': diplomatic,
  };
}

PlateCountry _strip(Color color) => PlateCountry(
  code: 'ye',
  captionLines: const <String>[],
  panelColor: color,
  panelTextColor: RiyadhColors.ink,
  flag: const SvgPlateAsset('assets/riyadh/emblem.svg', package: 'yemen_plate'),
  flagAspectRatio: 610 / 662.42,
);
