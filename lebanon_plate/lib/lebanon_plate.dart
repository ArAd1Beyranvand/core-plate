/// Lebanon's licence plates for the `core_plate` library.
///
/// **Lebanon is two shapes and many colours** — the mirror image of most of the
/// systems this workspace models, which are many shapes and few colours. Read
/// that before anything else here makes sense:
///
/// - **Two geometries.** `LebanonPlates.oneLine`, the long European-proportioned
///   plate with the blue band down its left edge, and `LebanonPlates.twoLine`,
///   the shorter and taller plate with the band across its top. Both are
///   current; which one a vehicle carries is a matter of what fits its
///   mounting.
/// - **Two axes on top of that, and they are independent.** `LebanonUsage` is
///   the **field colour** — white private, purple consular, orange diplomatic,
///   red public institutions, yellow driving school, green transit, brown
///   temporary, pink tourism. `LebanonLetter` is the **letter** before the
///   number, which on a white plate is the town of registration (B Beirut, T
///   Tripoli, S Sidon, Z Zahleh, …) and on some coloured ones repeats the
///   class.
///
/// Those two are separate types on purpose. `B 123456` and `Z 123456` are the
/// same usage and different letters; a red مؤسسات plate and a yellow driving
/// school plate both carry `M`. One enum crossing them would be full of
/// combinations Lebanon does not issue.
///
/// Data, not code: one [PlateCountry] family, two [PlateAlphabet]s, eight
/// [PlateTheme]s, two standard [PlateSpec]s (twelve counting the short-number
/// variants) and one advisory [PlateValidator]. There is not a widget in this
/// package — `PlateCanvas` and `ShowPlate` from `core_plate` draw all of it.
///
/// **A usage selects a theme and a country block, not a spec.**
///
/// ```dart
/// PlateCanvas(
///   spec: LebanonPlates.oneLine,
///   country: LebanonCountry.forUsage(LebanonUsage.diplomatic),
///   theme: LebanonThemes.forUsage(LebanonUsage.diplomatic),
///   validator: const LebanonValidator(),
///   onChooseCharacter: (alphabet) async => null,
/// )
/// ```
///
/// Every dimension and every colour in this package is marked `// CALIBRATE`.
/// They are proportioned from photographs and published descriptions, not
/// measured from a standard, and the README's "What it does not ship" says what
/// else is missing — starting with the cedar.
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
