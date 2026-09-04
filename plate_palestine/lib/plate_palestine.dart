/// Palestine's licence plates for the `core_plate` library.
///
/// Data, not code: two [PlateCountry] families (the West Bank's `ف / P` block
/// and Gaza's flag), the alphabets, the usage-derived themes, and the
/// [PlateSpec] consts the core widget layer paints. Nothing here knows about
/// any other country package.
///
/// The West Bank and Gaza are **two designs**, not one plate with a flag
/// swapped in — see `PSWestBankPlates` and `PSGazaPlates`. Colour is derived
/// from usage, never chosen — see `PSThemes.forUsage`.
///
/// ```dart
/// PlateCanvas(
///   spec: PSWestBankPlates.modernCar,
///   theme: PSThemes.forUsage(PSUsage.private),
///   onChooseCharacter: showMyPicker, // the host's; core ships no picker
/// );
/// ```
library;

/// Every colour a Palestinian plate is printed in, all `// CALIBRATE`.
export 'src/palestine_colors.dart';

/// The colour schemes a plate is printed in, and the usage -> theme lookups.
export 'src/palestine_themes.dart';

/// The country blocks: the West Bank's `ف / P` ink and Gaza's flag.
export 'src/palestine_country.dart';

/// The character sets a Palestinian plate slot can be drawn over.
export 'src/palestine_alphabets.dart';

/// The closed set of governorate letters a modern West Bank plate can end in.
export 'src/palestine_governorates.dart';

/// What a plate is licensed for, and the legacy/Gaza usage-code maps.
export 'src/palestine_usage.dart';

/// The West Bank plate specs.
export 'src/west_bank_plates.dart';

/// The Gaza plate specs.
export 'src/gaza_plates.dart';

/// The advisory validators, one per scheme.
export 'src/palestine_validators.dart';

/// Synthetic-serial generation for demos and tests.
export 'src/palestine_serial_generator.dart';
