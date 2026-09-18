/// The letter printed before the number, and what each one means.
///
/// A Lebanese plate is one letter and up to six digits. On an ordinary white
/// plate the letter is the **town of registration**; a handful of letters
/// instead mark a class of vehicle or of holder, and a few of those come with a
/// field colour, which is `LebanonUsage` and not this enum. See the doc on
/// `LebanonUsage` for why the two axes are separate types.
///
/// The list is closed as far as the sources go, and [inUse] records the one
/// letter — `K`, Baalbek — that is documented as issued but not currently in
/// service. It is exposed and never enforced: `K` plates are on the road, and a
/// validator that rejected one would be wrong about the fleet.
enum LebanonLetter {
  /// Pre-1998 registrations, issued without a town code.
  ///
  /// No town, and no successor: `A` was the general series before the town
  /// letters, and a surviving `A` plate — especially a short number — trades as
  /// a vanity plate.
  a('A', town: null, governorate: null, description: 'General series, pre-1998'),

  /// Beirut, the capital.
  b('B', town: 'Beirut', governorate: 'Beirut', description: 'Beirut'),

  /// Aley, in Mount Lebanon.
  y('Y', town: 'Aley', governorate: 'Mount Lebanon', description: 'Aley'),

  /// Jounieh, in Mount Lebanon.
  g('G', town: 'Jounieh', governorate: 'Mount Lebanon', description: 'Jounieh'),

  /// Nabatieh.
  n('N', town: 'Nabatieh', governorate: 'Nabatieh', description: 'Nabatieh'),

  /// Ouzai, in Mount Lebanon.
  o('O', town: 'Ouzai', governorate: 'Mount Lebanon', description: 'Ouzai'),

  /// Sidon, in South Lebanon.
  s('S', town: 'Sidon', governorate: 'South Lebanon', description: 'Sidon'),

  /// Tripoli, in North Lebanon.
  t('T', town: 'Tripoli', governorate: 'North Lebanon', description: 'Tripoli'),

  /// Baalbek, in the Beqaa. Documented, and not currently issued.
  k('K', town: 'Baalbek', governorate: 'Beqaa', description: 'Baalbek', inUse: false),

  /// Zahleh, in the Beqaa.
  z('Z', town: 'Zahleh', governorate: 'Beqaa', description: 'Zahleh'),

  /// Serving judges. A white plate; the letter is the whole distinction.
  j('J', town: null, governorate: null, description: 'Judicial'),

  /// Higher-ranking officials of the eighteen recognised sects.
  r('R', town: null, governorate: null, description: 'Religious official'),

  /// Motorcycles, and private commercial vehicles.
  ///
  /// Also the letter on the red public-institution plate and on the yellow
  /// driving-school plate — three different plates, one letter, told apart by
  /// the field colour. See `LebanonUsage`.
  m('M', town: null, governorate: null, description: 'Motorcycle / commercial'),

  /// Consular vehicles. Purple field.
  c('C', town: null, governorate: null, description: 'Consular'),

  /// Diplomatic vehicles. Orange field.
  d('D', town: null, governorate: null, description: 'Diplomatic'),

  /// Public transport.
  p('P', town: null, governorate: null, description: 'Public transport'),

  /// Members of parliament — a two-glyph letter, and the one entry whose
  /// [character] is not a single character.
  ///
  /// `MP` plates are numbered 1..128 and are held for the duration of a term,
  /// then returned. `LebanonValidator` enforces that range; it is the only
  /// number range in the whole system that is documented.
  mp('MP', town: null, governorate: null, description: 'Member of parliament');

  const LebanonLetter(
    this.character, {
    required this.town,
    required this.governorate,
    required this.description,
    this.inUse = true,
  });

  /// The glyph (or, for [mp], the two glyphs) printed on the plate.
  ///
  /// This is what goes in the letter slot, and it is what a `PlateController`
  /// stores: `LebanonAlphabets.letters` accepts exactly these strings.
  final String character;

  /// The town whose registry issues this letter, or null when the letter marks
  /// a class rather than a place.
  final String? town;

  /// The governorate [town] sits in, or null with it.
  final String? governorate;

  /// A short English label for host UI.
  final String description;

  /// Whether the letter is currently issued.
  ///
  /// False for [k] alone. Advisory: plates carrying a letter that is no longer
  /// issued remain valid, so nothing in this package refuses one.
  final bool inUse;

  /// Whether this letter names a town of registration rather than a class.
  bool get isTownCode => town != null;

  /// The letter whose [character] is [character], or null.
  ///
  /// Case-insensitive, because a host reading a plate off a text field has no
  /// reason to normalise first. `'mp'` and `'MP'` both resolve to [mp].
  static LebanonLetter? fromCharacter(String character) {
    final String key = character.toUpperCase();
    for (final LebanonLetter l in values) {
      if (l.character == key) return l;
    }
    return null;
  }

  /// Every letter's glyph, in declaration order — the accepted set behind
  /// `LebanonAlphabets.letters`, and the order a picker should show.
  static const List<String> characters = <String>[
    'A',
    'B',
    'Y',
    'G',
    'N',
    'O',
    'S',
    'T',
    'K',
    'Z',
    'J',
    'R',
    'M',
    'C',
    'D',
    'P',
    'MP',
  ];

  /// The letters that name a town.
  static List<LebanonLetter> get townCodes => values.where((LebanonLetter l) => l.isTownCode).toList(growable: false);
}
