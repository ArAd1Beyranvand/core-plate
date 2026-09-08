/// Yemen's licence plates for the `core_plate` library.
///
/// **Yemen has two current plate systems, not one current and one legacy.**
/// Read that before anything else in this package makes sense:
///
/// - **System A**, `YemenUnifiedPlates` — the unified white plate the
///   internationally recognised government began issuing in mid-2026. A wide
///   plate with a light blue side panel, a vehicle number of four to six
///   digits, and a two-digit code stacked in the panel. Usage is a word in the
///   panel; the field is white for every usage.
/// - **System B**, `YemenNorthernPlates` — the 1993 format, still in force
///   across the Houthi-controlled north and still the larger share of the
///   fleet. Two stacked registers split by a rule: a governorate code of one or
///   two digits above, a serial of up to six below. Usage is the **field
///   colour** — blue private, yellow for hire, red transport, green
///   government, black military.
///
/// The two are separate namespaces on purpose. There is no `YemenSystem` enum
/// and no version flag selecting between them, because there is no
/// before-and-after to select: which system a plate belongs to is a fact about
/// where the vehicle was registered, and a host that knows that fact reaches
/// for one namespace and never sees the other.
///
/// Data, not code: two [PlateCountry] families, two [PlateAlphabet]s, seven
/// [PlateTheme]s, eleven [PlateSpec]s and two advisory [PlateValidator]s. There
/// is not a widget in this package — `PlateCanvas` and `ShowPlate` from
/// `core_plate` draw all of it.
///
/// **A usage selects a country block and a theme, not a spec.** Eleven specs is
/// one per geometry: four northern car layouts, one northern motorcycle layout,
/// and three number lengths each for the unified car and motorcycle. The usage
/// class rides on the two things that actually vary with it — the country block
/// carrying the usage word (System B) or the panel's caption lines (System A),
/// and the theme carrying the field colour (System B) — and `PlateCanvas` takes
/// both at render time. Each spec's own `country` is the private block, the
/// default for a caller who passes no override.
///
/// ```dart
/// PlateCanvas(
///   spec: YemenNorthernPlates.carGov2Serial5,
///   country: YemenCountry.northernFor(YemenUsage.private),
///   theme: YemenThemes.forNorthernUsage(YemenUsage.private),
///   validator: const YemenNorthernValidator(),
///   ...
/// )
/// ```
///
/// Every dimension and every colour in this package is marked `// CALIBRATE`.
/// They are proportioned from photographs and published descriptions, not
/// measured from a standard, and the README's "What it does not ship" says what
/// else is missing.
library;

/// The five usage classes, their Arabic and Latin words on each system, and
/// which system issues which.
export 'src/yemen_usage.dart';

/// The 22 governorates, their codes, and the advisory `underHouthiControl`
/// flag — exposed, never enforced.
export 'src/yemen_governorates.dart';

/// The colour values both systems are printed in. Every one is a calibration
/// target.
export 'src/yemen_colors.dart';

/// The digit alphabets, including the restricted tens place of a northern
/// governorate code.
export 'src/yemen_alphabets.dart';

/// The country blocks — the unified plate's blue side panel and the northern
/// plate's transparent usage word.
export 'src/yemen_country.dart';

/// One theme for System A, six for System B, and the two lookups that pick
/// between them by usage.
export 'src/yemen_themes.dart';

/// System A: six specs — car and motorcycle, four to six number digits.
export 'src/unified_plates.dart';

/// System B: four car specs, plus one motorcycle spec whose geometry is
/// unverified and marked `@Deprecated` because of it.
export 'src/northern_plates.dart';

/// The two advisory validators — one per system, neither of which bars a
/// keystroke.
export 'src/yemen_validators.dart';

/// Seeded value generators for demos, fixtures and goldens. Pure Dart.
export 'src/yemen_serial_generator.dart';
