import 'package:core_plate/core_plate.dart';
import 'package:core_plate/src/model/plate_asset.dart';

import 'lebanon_colors.dart';
import 'lebanon_usage.dart';

/// Lebanon's blue band, as `core_plate`'s [PlateCountry].
///
/// Three things are worth reading before using this file.
///
/// **Every constant has `code: 'lb'`, so they all compare equal.**
/// [PlateCountry] defines equality over the country code alone — Lebanon is one
/// country however its plates are printed — so these consts are not
/// distinguishable by `==`. Distinguish plates by [PlateSpec.id], which is what
/// core itself compares.
///
/// **The band carries the usage word; the spec carries لبنان.** A
/// `PlateCountry` is a render-time argument and a `PlateSpec` is a compile-time
/// const, so anything that varies with usage has to live here and anything that
/// does not is better off in the spec. The country name does not vary, so it is
/// a [PlateLabel] on each spec in `LebanonPlates`, and these consts differ from
/// one another in exactly two fields: the caption line and, for nothing at all
/// yet, the panel colour. That is why there are two geometries in this package
/// and not two-geometries-times-nine.
///
/// **The band is the same blue on every plate.** Lebanon colour-codes the
/// *field*, not the band — a purple consular plate has the same blue band as a
/// white private one. The colour axis is `LebanonThemes`, not this file, and a
/// panel colour here that varied by usage would be inventing a system.
abstract final class LebanonCountry {
  /// The blue band with no usage word — لبنان alone, which the spec prints.
  ///
  /// The right block for a class whose printed Arabic no source names (see
  /// `LebanonUsage.arabic`), and what [forUsage] returns for all of them.
  static const PlateCountry band = PlateCountry(
    code: 'lb',
    captionLines: <String>[],
    panelColor: LebanonColors.band,
    panelTextColor: LebanonColors.bandInk,
    flag: SvgPlateAsset('assets/cedar.svg', package: 'lebanon_plate'),
  );

  /// خصوصي — the band on an ordinary private plate.
  static const PlateCountry private = PlateCountry(
    code: 'lb',
    captionLines: <String>['خصوصي'],
    panelColor: LebanonColors.band,
    panelTextColor: LebanonColors.bandInk,
    flag: SvgPlateAsset('assets/cedar.svg', package: 'lebanon_plate'),
  );

  /// مؤسسات — the band on a red public-institution plate.
  static const PlateCountry publicInstitution = PlateCountry(
    code: 'lb',
    captionLines: <String>['مؤسسات'],
    panelColor: LebanonColors.band,
    panelTextColor: LebanonColors.bandInk,
    flag: SvgPlateAsset('assets/cedar.svg', package: 'lebanon_plate'),
  );

  /// The band captioned for [usage].
  ///
  /// Falls back to the uncaptioned [band] for every class whose printed Arabic
  /// word this package does not have — which is most of the coloured ones. That
  /// is a gap in the sources, not in the plate: a consular plate's band almost
  /// certainly says something, and printing a plausible word would make this
  /// package a source for a claim it cannot support. `LebanonUsage.arabic` is
  /// the field to check if you want to grey an option out or print your own.
  static PlateCountry forUsage(LebanonUsage usage) => switch (usage.arabic) {
    'خصوصي' => private,
    'مؤسسات' => publicInstitution,
    _ => band,
  };
}
