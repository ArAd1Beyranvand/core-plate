/// Yemen's licence plates for the `core_plate` library.
///
/// **Yemen has two current plate systems, not one current and one legacy.**
/// System A is the 2026 unified white plate (light blue side panel, 4–6 digit number,
/// two-digit side code). System B is the 1993 northern format (stacked registers split
/// by a rule, 1–2 digit governorate code, up to 6-digit serial, colour-coded by usage).
/// The two are separate namespaces; usage picks a country block and a theme at render
/// time.
///
/// The south issues its own: Aden's lighthouse plate, Taiz's temporary plate,
/// and the coloured-strip plates of Hadhramaut, Al Mahrah, Shabwah and Marib.
/// Those are measured off the Wikipedia artwork; the rest is not:
///
/// Every dimension and colour is marked `// CALIBRATE` — proportioned from photographs,
/// not measured from a standard.
library;

/// The five usage classes, their Arabic and Latin words on each system, and
/// which system issues which.
export 'src/common/yemen_usage.dart';

/// The 22 governorates, their codes, and the advisory `underHouthiControl`
/// flag — exposed, never enforced.
export 'src/common/yemen_governorates.dart';

/// The colour values both systems are printed in. Every one is a calibration
/// target.
export 'src/common/yemen_colors.dart';

/// The digit alphabets, including the restricted tens place of a northern
/// governorate code.
export 'src/common/yemen_alphabets.dart';

/// The country blocks — the unified plate's blue side panel and the northern
/// plate's transparent usage word.
export 'src/common/yemen_country.dart';

/// One theme for System A, six for System B, and the two lookups that pick
/// between them by usage.
export 'src/common/yemen_themes.dart';

/// System A: six specs — car and motorcycle, four to six number digits.
export 'src/unified/unified_plates.dart';

/// System B: four car specs, plus one motorcycle spec whose geometry is
/// unverified and marked `@Deprecated` because of it.
export 'src/northern/northern_plates.dart';

/// Hadhramaut, Al Mahrah, Shabwah and Marib: the coloured-strip plates, one
/// spec per governorate and layout, the strip colour on the country block.
export 'src/southern/governorate_plates.dart';

/// Aden's two sizes and Taiz's temporary plate.
export 'src/southern/aden_taiz_plates.dart';

/// The two advisory validators — one per system, neither of which bars a
/// keystroke.
export 'src/common/yemen_validators.dart';

/// Seeded value generators for demos, fixtures and goldens. Pure Dart.
export 'src/common/yemen_serial_generator.dart';

/// Riyadh: five categories in the US and EU sizes, a coloured strip with the
/// emblem, Arabic and Latin rows.
export 'src/riyadh/riyadh_colors.dart';
export 'src/riyadh/riyadh_country.dart';
export 'src/riyadh/riyadh_themes.dart';
export 'src/riyadh/riyadh_plates.dart';
export 'src/riyadh/riyadh_validators.dart';
export 'package:plate_alphabet/plate_alphabet.dart' show RiyadhAlphabets;
