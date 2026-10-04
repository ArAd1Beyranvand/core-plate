import 'package:flutter/foundation.dart';

/// One branch of the Indonesian armed forces (TNI), as drawn on its plate:
/// the rim, where the crest square ends, and the mark over the serial.
///
/// A data class rather than an enum so a host can add a service the package
/// does not ship (the Ministry of Defence, say). Its colours are a theme —
/// `IndonesiaThemes.army` and the rest — and [rim] must equal that theme's
/// border, in millimetres on the 138 mm plate.
///
/// Measured off photographs; see `IndonesiaPlates.military`.
@immutable
class IndonesiaService {
  const IndonesiaService({
    required this.id,
    required this.name,
    required this.rim,
    required this.dividerCentre,
    required this.dividerWidth,
    this.mark,
  });

  final String id;
  final String name;

  /// The yellow rim's width.
  final double rim;

  /// The x of the yellow upright between the crest square and the field.
  final double dividerCentre;
  final double dividerWidth;

  /// File name of the mark over the serial, in this package's `assets/`;
  /// null for none.
  final String? mark;

  /// TNI-AD. Rim and divider 14 mm, centre x 130; a yellow star.
  static const IndonesiaService army = IndonesiaService(
    id: 'army',
    name: 'Army',
    rim: 14,
    dividerCentre: 130,
    dividerWidth: 14,
    mark: 'mark_star.png',
  );

  /// TNI-AL. Divider 9 mm at x 119.5; a yellow anchor.
  static const IndonesiaService navy = IndonesiaService(
    id: 'navy',
    name: 'Navy',
    rim: 9,
    dividerCentre: 119.5,
    dividerWidth: 9,
    mark: 'mark_anchor.png',
  );

  /// TNI-AU. Divider 8 mm at x 116; the red-and-white pentagon roundel.
  static const IndonesiaService airForce = IndonesiaService(
    id: 'airForce',
    name: 'Air Force',
    rim: 9,
    dividerCentre: 116,
    dividerWidth: 8,
    mark: 'mark_roundel.png',
  );

  /// TNI headquarters (Mabes TNI): red field, no mark. Only a night photo
  /// was found, so the divider is the Navy's.
  static const IndonesiaService armedForces = IndonesiaService(
    id: 'armedForces',
    name: 'TNI Headquarters',
    rim: 9,
    dividerCentre: 119.5,
    dividerWidth: 9,
  );

  static const List<IndonesiaService> all = <IndonesiaService>[
    army,
    navy,
    airForce,
    armedForces,
  ];
}
