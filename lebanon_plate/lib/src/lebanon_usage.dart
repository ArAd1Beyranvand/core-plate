/// The field colour of a Lebanese plate — separate from [LebanonLetter].
///
/// The two are separate by design: `B 123456` and `Z 123456` are the same
/// usage, different letters; a red مؤسسات and yellow driving-school plate both
/// carry `M` but are different usages. One enum would be full of unissued
/// combinations.
///
/// [arabic] and [latin] are the words printed in the band. Where unattested,
/// [arabic] is null and the band carries لبنان alone.
enum LebanonUsage {
  /// Privately owned vehicles, and letter-coded classes without a colour:
  /// judicial (J), religious (R), parliament (MP), motorcycle (M).
  private(arabic: 'خصوصي', latin: 'PRIVATE', letter: null),

  /// Consular vehicles, purple field, letter C.
  consular(arabic: null, latin: 'CONSULAR', letter: 'C'),

  /// Diplomatic vehicles, orange field, letter D.
  diplomatic(arabic: null, latin: 'DIPLOMATIC', letter: 'D'),

  /// Public institutions مؤسسات, red field, letter M.
  publicInstitution(arabic: 'مؤسسات', latin: 'PUBLIC', letter: 'M'),

  /// Public transport (taxis, buses, services), letter P. Inherited red from
  /// its former red `M` classification; current field colour is unattested.
  // TODO(p-plate): source the field colour of current P plates
  publicTransport(arabic: null, latin: 'PUBLIC TRANSPORT', letter: 'P'),

  /// Driving school vehicles, yellow field, letter M.
  drivingSchool(arabic: null, latin: 'DRIVING SCHOOL', letter: 'M'),

  /// Transit and temporary vehicles, green field.
  transit(arabic: null, latin: 'TRANSIT', letter: null),

  /// Temporary registration, brown field.
  temporary(arabic: null, latin: 'TEMPORARY', letter: null),

  /// Tourism vehicles, pink field.
  tourism(arabic: null, latin: 'TOURISM', letter: null);

  const LebanonUsage({required this.arabic, required this.latin, required this.letter});

  /// The Arabic word printed in the band under لبنان, or null when no source
  /// names one for this class. Null means "not attested", not "blank by rule" —
  /// a coloured plate almost certainly carries *some* word, and this package
  /// prints nothing rather than a guess.
  final String? arabic;

  /// Latin label for host UI, not plate text.
  final String latin;

  /// The fixed letter for this class, if any; null for [private] (where letter
  /// is the town) and [transit], [temporary], [tourism] (unattested).
  /// Note: [publicInstitution] and [drivingSchool] both carry `M`.
  final String? letter;

  /// True only for [private].
  bool get isWhite => this == LebanonUsage.private;

  /// The colour-coded classes.
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
