import 'package:plate_core/plate_core.dart';
import 'package:flutter/widgets.dart';

import 'yemen_colors.dart';
import 'yemen_usage.dart';

/// Yemen's plate chrome. All have `code: 'ye'`; they compare equal by [PlateCountry]'s
/// equality rule, so distinguish plates by [PlateSpec.id]. Northern consts carry the
/// usage word as a caption over a transparent panel (see [northernPrivate]).
abstract final class YemenCountry {
  // System A: the blue side panel carries usage captions; colour is the same for all uses.

  /// The blue side panel with no usage text. Not used by specs in this package;
  /// [unifiedFor] below picks the captioned variants.
  static const PlateCountry unified = PlateCountry(
    code: 'ye',
    captionLines: <String>[],
    panelColor: YemenColors.unifiedSidePanel,
    panelTextColor: YemenColors.unifiedInk,
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

  /// The unified panel captioned for [usage], or [unified] (uncaptioned)
  /// if System A does not issue this usage — returns blank panel instead of throwing.
  static PlateCountry unifiedFor(YemenUsage usage) => switch (usage) {
    YemenUsage.private => unifiedPrivate,
    YemenUsage.forHire => unifiedForHire,
    YemenUsage.transport => unifiedTransport,
    YemenUsage.government => unifiedGovernment,
    YemenUsage.police => unifiedPolice,
    YemenUsage.military => unified,
  };

  // System B: transparent panel carries the usage word in ink colour; no coloured block.

  /// الیمن - خصوصي, black ink, on transparent panel. Transparent avoids a coloured
  /// rectangle appearing if the host mistakenly pairs this with the wrong theme.
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

  /// White ink on green, no usage word (source unclear — see [YemenUsage.government]).
  static const PlateCountry northernGovernment = PlateCountry(
    code: 'ye',
    captionLines: <String>[],
    panelColor: _transparent,
    panelTextColor: YemenColors.lightInk,
    flag: null,
  );

  /// White ink on black, no usage word.
  static const PlateCountry northernMilitaryClassic = PlateCountry(
    code: 'ye',
    captionLines: <String>[],
    panelColor: _transparent,
    panelTextColor: YemenColors.lightInk,
    flag: null,
  );

  /// Red ink on white, no usage word. Not referenced by specs; distinguished from
  /// [northernMilitaryClassic] by [YemenThemes], not by this const.
  static const PlateCountry northernMilitaryModern = PlateCountry(
    code: 'ye',
    captionLines: <String>[],
    panelColor: _transparent,
    panelTextColor: YemenColors.militaryRed,
    flag: null,
  );

  /// The northern block for [usage], or [northernMilitaryClassic] if System B
  /// does not issue this usage — falls back to [northernGovernment] for police.
  static PlateCountry northernFor(YemenUsage usage) => switch (usage) {
    YemenUsage.private => northernPrivate,
    YemenUsage.forHire => northernForHire,
    YemenUsage.transport => northernTransport,
    YemenUsage.government => northernGovernment,
    YemenUsage.military => northernMilitaryClassic,
    YemenUsage.police => northernGovernment,
  };

  static const Color _transparent = Color(0x00000000);
}
