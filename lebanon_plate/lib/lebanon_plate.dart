/// Lebanon's licence plates for the `core_plate` library.
///
/// Two geometries (one-line and two-line) and eight colour fields (one per
/// `LebanonUsage`). `LebanonLetter` is the town or class code; those two axes
/// are separate by design — `B 123456` and `Z 123456` are the same usage,
/// different letters; a red مؤسسات and a yellow driving-school plate both
/// carry `M` but are different usages.
///
/// A usage selects a theme and a country band via `LebanonThemes.forUsage()`
/// and `LebanonCountry.forUsage()`, not a spec. Dimensions and colours marked
/// `// CALIBRATE` are from photographs, not standards.
library;

/// The colour-coded usage classes, their Arabic and Latin words, and the letter
/// each class fixes when it fixes one.
export 'src/lebanon_usage.dart';

/// The seventeen plate letters, the towns they stand for, and the one that is
/// no longer issued.
export 'src/lebanon_letters.dart';

/// The colour values a Lebanese plate is printed in. Every one is a calibration
/// target.
export 'src/lebanon_colors.dart';

/// The two alphabets: Latin digits, and the closed letter set.
export 'src/lebanon_alphabets.dart';

/// The blue identification band, as a `PlateCountry`.
export 'src/lebanon_country.dart';

/// One theme per usage — the file Lebanon is interesting for.
export 'src/lebanon_themes.dart';

/// The two geometries, and their short-number variants.
export 'src/lebanon_plates.dart';

/// The advisory validator, which does not bar a keystroke.
export 'src/lebanon_validators.dart';

/// Seeded value generators for demos, fixtures and goldens. Pure Dart.
export 'src/lebanon_serial_generator.dart';
