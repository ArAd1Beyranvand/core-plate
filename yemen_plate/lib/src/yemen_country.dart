import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'yemen_colors.dart';
import 'yemen_usage.dart';

/// Yemen's plate chrome, as `core_plate`'s [PlateCountry].
///
/// Two things about this file are worth reading before using it.
///
/// **Every constant here has `code: 'ye'`, so they all compare equal.**
/// [PlateCountry] defines equality over the country code alone, which is the
/// right rule — Yemen is one country however its plates are printed — and it
/// means these consts are not distinguishable by `==`. Distinguish plates by
/// [PlateSpec.id] instead, which is what core itself compares.
///
/// **On the northern (System B) constants: this is a slightly odd use of the
/// type, and the next reader deserves the sentence.** A northern plate has no
/// coloured country block. Its country name and its usage word are printed
/// straight onto the field in the top band. But the usage word has to come from
/// *somewhere* on a `const PlateSpec`, and core offers exactly two places for
/// fixed text — a [PlateLabel], whose string is baked into the spec, and
/// [PlateCountry.captionLines]. Putting it in a label would make the spec
/// usage-specific for the country name too and double the number of geometry
/// definitions; putting it here keeps one geometry per shape and varies only
/// the country. So the northern consts carry the usage word as a caption, over
/// a **fully transparent** panel — see [northernPrivate] for why transparent
/// rather than the field colour.
abstract final class YemenCountry {
  // ---------------------------------------------------------------------------
  // System A — the 2026 unified plate.
  //
  // The panel here is a real coloured block: the light blue slab down the right
  // edge. Its colour is the same for all five usages (System A does not colour
  // code by use), so these five consts differ only in their caption lines.
  // ---------------------------------------------------------------------------

  /// The blue side panel with no usage text, for a host that prints its own.
  ///
  /// Not used by any spec in this package — [unifiedFor] resolves the five
  /// captioned variants below instead. It exists because "the panel, without a
  /// usage" is a meaningful value and a consumer building their own spec should
  /// not have to invent it.
  static const PlateCountry unified = PlateCountry(
    code: 'ye',
    captionLines: <String>[],
    panelColor: YemenColors.unifiedSidePanel,
    panelTextColor: YemenColors.unifiedInk,
    // A Yemeni plate carries no flag. Null here, and `flagScale: 0` on every
    // spec's PlatePanel, so the caption gets the block's height instead of a
    // strip being reserved for an image that does not exist.
    flag: null,
  );

  /// خصوصي / PRIV.
  static const PlateCountry unifiedPrivate = PlateCountry(
    code: 'ye',
    captionLines: <String>['خصوصي', 'PRIV.'],
    panelColor: YemenColors.unifiedSidePanel,
    panelTextColor: YemenColors.unifiedInk,
    flag: null,
  );

  /// أجرة / TAXI.
  static const PlateCountry unifiedForHire = PlateCountry(
    code: 'ye',
    captionLines: <String>['أجرة', 'TAXI'],
    panelColor: YemenColors.unifiedSidePanel,
    panelTextColor: YemenColors.unifiedInk,
    flag: null,
  );

  /// نقل / TRANS.
  static const PlateCountry unifiedTransport = PlateCountry(
    code: 'ye',
    captionLines: <String>['نقل', 'TRANS.'],
    panelColor: YemenColors.unifiedSidePanel,
    panelTextColor: YemenColors.unifiedInk,
    flag: null,
  );

  /// حكومي / GOV.
  static const PlateCountry unifiedGovernment = PlateCountry(
    code: 'ye',
    captionLines: <String>['حكومي', 'GOV.'],
    panelColor: YemenColors.unifiedSidePanel,
    panelTextColor: YemenColors.unifiedInk,
    flag: null,
  );

  /// شرطة / POLICE.
  static const PlateCountry unifiedPolice = PlateCountry(
    code: 'ye',
    captionLines: <String>['شرطة', 'POLICE'],
    panelColor: YemenColors.unifiedSidePanel,
    panelTextColor: YemenColors.unifiedInk,
    flag: null,
  );

  /// The unified side panel captioned for [usage], or [unified] (uncaptioned)
  /// for a usage System A does not issue.
  ///
  /// Returning the uncaptioned panel rather than throwing keeps this usable
  /// from a host whose usage picker is shared between the two systems: pick
  /// `military`, switch to the unified system, and you get a plate with a blank
  /// panel rather than a crash. `YemenUsage.onUnified` is the question to ask
  /// first if you want to grey the option out instead.
  static PlateCountry unifiedFor(YemenUsage usage) => switch (usage) {
    YemenUsage.private => unifiedPrivate,
    YemenUsage.forHire => unifiedForHire,
    YemenUsage.transport => unifiedTransport,
    YemenUsage.government => unifiedGovernment,
    YemenUsage.police => unifiedPolice,
    YemenUsage.military => unified,
  };

  // ---------------------------------------------------------------------------
  // System B — the 1993 northern plate.
  //
  // No coloured block. The panel is transparent and carries only the usage
  // word, printed in the ink of that usage's colour scheme.
  // ---------------------------------------------------------------------------

  /// الیمن - خصوصي, black ink — printed on a northern private plate.
  ///
  /// [panelColor] is fully transparent rather than the field's blue, and that
  /// is deliberate. Painting the field colour into the panel block would work
  /// only while the spec and the theme agree: hand this spec
  /// `YemenThemes.northernForHire` by mistake and a blue rectangle appears in
  /// the top band of a yellow plate. A transparent block cannot go wrong, and
  /// the field colour has a home already — `PlateTheme.plateBackground`.
  static const PlateCountry northernPrivate = PlateCountry(
    code: 'ye',
    captionLines: <String>['الیمن - خصوصي'],
    panelColor: _transparent,
    panelTextColor: YemenColors.darkInk,
    flag: null,
  );

  /// اجرة, black ink, on the yellow field. Note the spelling: the northern
  /// plate prints it without the hamza the unified plate uses.
  static const PlateCountry northernForHire = PlateCountry(
    code: 'ye',
    captionLines: <String>['اجرة'],
    panelColor: _transparent,
    panelTextColor: YemenColors.darkInk,
    flag: null,
  );

  /// نقل, black ink, on the red field.
  static const PlateCountry northernTransport = PlateCountry(
    code: 'ye',
    captionLines: <String>['نقل'],
    panelColor: _transparent,
    panelTextColor: YemenColors.darkInk,
    flag: null,
  );

  /// White ink on the green field, and **no usage word**: no source names the
  /// Arabic printed on a northern government plate, so the top band carries
  /// only اليمن. See the TODO on [YemenUsage.government].
  static const PlateCountry northernGovernment = PlateCountry(
    code: 'ye',
    captionLines: <String>[],
    panelColor: _transparent,
    panelTextColor: YemenColors.lightInk,
    flag: null,
  );

  /// White ink on the black field, and no usage word.
  static const PlateCountry northernMilitaryClassic = PlateCountry(
    code: 'ye',
    captionLines: <String>[],
    panelColor: _transparent,
    panelTextColor: YemenColors.lightInk,
    flag: null,
  );

  /// Red ink on the white field, and no usage word.
  ///
  /// No spec in this package references it, and that is not an oversight: a
  /// military plate carries no usage word, so its caption is empty, so the only
  /// field that distinguishes this from [northernMilitaryClassic] —
  /// [PlateCountry.panelTextColor] — has nothing to colour. The two military
  /// printings are told apart by their `PlateTheme`
  /// (`YemenThemes.northernMilitaryClassic` / `.northernMilitaryModern`), and
  /// this const exists so the colour pair is available as data.
  static const PlateCountry northernMilitaryModern = PlateCountry(
    code: 'ye',
    captionLines: <String>[],
    panelColor: _transparent,
    panelTextColor: YemenColors.militaryRed,
    flag: null,
  );

  /// The northern country block for [usage], or [northernMilitaryClassic] for
  /// a usage System B does not issue.
  static PlateCountry northernFor(YemenUsage usage) => switch (usage) {
    YemenUsage.private => northernPrivate,
    YemenUsage.forHire => northernForHire,
    YemenUsage.transport => northernTransport,
    YemenUsage.government => northernGovernment,
    YemenUsage.military => northernMilitaryClassic,
    // System B has no police class. Falling back to the government block —
    // rather than throwing — keeps a shared usage picker usable across the two
    // systems, for the same reason [unifiedFor] falls back. It is a fallback,
    // not a claim that northern police vehicles are registered as government
    // ones; `YemenUsage.onNorthern` is the question to ask if you want to grey
    // the option out instead.
    YemenUsage.police => northernGovernment,
  };

  /// A panel block that paints nothing. See [northernPrivate].
  static const Color _transparent = Color(0x00000000);
}
