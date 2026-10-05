import 'package:plate_core/plate_core.dart';

/// Diplomatic country codes that no layer may store.
///
/// The article's table gives each mission a block of five codes (`321-325`
/// Iran, `336-340` Israel). The Israel block is refused: every diplomatic
/// spec's `mission` register carries [restriction], so the controller, the
/// input machine, the canvas and the validator all reject it. Nothing in this
/// package will store, generate or render those codes.
abstract final class VietnamMissions {
  /// The error every layer shows for a refused code.
  static const String notFound = 'COUNTRY NOT FOUND';

  /// 336–340 — the block the article lists for Israel.
  static const List<String> refused = <String>[
    '336', '337', '338', '339', '340', //
  ];

  static const PlateRestriction restriction = PlateRestriction(
    group: 'mission',
    values: refused,
    reason: notFound,
  );

  static bool isRefused(String code) => refused.contains(code);
}
