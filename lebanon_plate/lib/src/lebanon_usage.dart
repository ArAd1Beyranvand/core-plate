/// What a Lebanese plate says the vehicle is for — the **colour** axis.
///
/// Lebanon separates two things that most systems fuse, and this package keeps
/// them separate too:
///
/// - **[LebanonUsage] is the field colour.** White for private, purple for
///   consular, orange for diplomatic, red for public institutions, yellow for
///   driving schools, green for transit, brown for temporary registration, pink
///   for tourism.
/// - **`LebanonLetter` is the letter** printed before the number, which on a
///   white plate encodes the town of registration (B for Beirut, T for Tripoli,
///   …) and on some coloured plates repeats the class (C consular, D
///   diplomatic).
///
/// The two are not derivable from each other. `B 123456` and `Z 123456` are the
/// same usage and different letters; a red مؤسسات plate and a yellow driving
/// school plate both carry `M` and are different usages. Modelling the pair as
/// one enum would produce a value set full of combinations Lebanon does not
/// issue, and would leave a host unable to say "colour this plate red" without
/// also claiming a letter.
///
/// [arabic] and [latin] are the words printed in the blue band beneath (one-line
/// plate) or beside (two-line plate) لبنان. They are the plate's own text, not
/// translations: where a source does not attest the printed word for a class,
/// the field is null and the band carries لبنان alone rather than a word this
/// package invented.
enum LebanonUsage {
  /// Privately owned vehicles — the ordinary plate, black on white.
  ///
  /// This is also what the letter-coded classes that carry no colour of their
  /// own are printed on: judicial (J), religious official (R), parliament (MP)
  /// and motorcycle (M) plates are white plates with a distinguishing letter.
  private(arabic: 'خصوصي', latin: 'PRIVATE', letter: null),

  /// Consular vehicles. Purple field.
  consular(arabic: null, latin: 'CONSULAR', letter: 'C'),

  /// Diplomatic vehicles. Orange field, and the only class whose number is not
  /// a plain serial: it encodes a country code and a car number.
  diplomatic(arabic: null, latin: 'DIPLOMATIC', letter: 'D'),

  /// Public institutions (مؤسسات). Red field.
  ///
  /// Public transport was carried on these red `M` plates before it moved to
  /// its own `P` letter; see [publicTransport].
  publicInstitution(arabic: 'مؤسسات', latin: 'PUBLIC', letter: 'M'),

  /// Public transport — taxis, buses and service vehicles, under the `P`
  /// letter that replaced the older red `M` plate.
  ///
  /// No source consulted names the field colour of a current `P` plate, so
  /// `LebanonThemes.forUsage` prints it red, following the class it was split
  /// out of. That is an inherited default, not an attestation.
  // TODO(p-plate): source the field colour of a current public-transport `P`
  // plate. If it is white, this belongs with the letter-coded classes and the
  // enum entry should go.
  publicTransport(arabic: null, latin: 'PUBLIC TRANSPORT', letter: 'P'),

  /// Driving instructor vehicles. Yellow field.
  drivingSchool(arabic: null, latin: 'DRIVING SCHOOL', letter: 'M'),

  /// Transit and temporary-use vehicles. Green field.
  transit(arabic: null, latin: 'TRANSIT', letter: null),

  /// Temporary registration. Brown field.
  temporary(arabic: null, latin: 'TEMPORARY', letter: null),

  /// Tourism vehicles. Pink field.
  tourism(arabic: null, latin: 'TOURISM', letter: null);

  const LebanonUsage({required this.arabic, required this.latin, required this.letter});

  /// The Arabic word printed in the band under لبنان, or null when no source
  /// names one for this class. Null means "not attested", not "blank by rule" —
  /// a coloured plate almost certainly carries *some* word, and this package
  /// prints nothing rather than a guess.
  final String? arabic;

  /// A Latin caption for host UI — a picker label, a legend, a tooltip.
  ///
  /// **Not plate text.** A Lebanese plate's band is Arabic; this string never
  /// reaches a `PlateCountry`, and `LebanonCountry` captions each band from
  /// [arabic] alone.
  final String latin;

  /// The letter a plate of this class carries, when the class fixes one.
  ///
  /// Null for [private] — where the letter is the town, and is the whole point
  /// of `LebanonLetter` — and for the three classes ([transit], [temporary],
  /// [tourism]) whose lettering no source consulted describes.
  ///
  /// Note that this is not a key: [publicInstitution] and [drivingSchool] both
  /// carry `M` and are told apart by the field colour.
  final String? letter;

  /// Whether this class is printed on a white field.
  ///
  /// True for [private] alone. Every other value is a colour, which is why
  /// `LebanonThemes` has one theme per usage rather than one theme.
  bool get isWhite => this == LebanonUsage.private;

  /// The colour-coded classes, in the order this package documents them.
  static const Set<LebanonUsage> coloured = <LebanonUsage>{
    consular,
    diplomatic,
    publicInstitution,
    publicTransport,
    drivingSchool,
    transit,
    temporary,
    tourism,
  };
}
