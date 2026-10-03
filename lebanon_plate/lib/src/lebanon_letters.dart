/// The letter on a Lebanese plate. On white plates, the town of registration
/// (B Beirut, T Tripoli, etc.). On coloured plates, the class letter. See
/// `LebanonUsage` for why the two axes are separate. [inUse] is advisory:
/// `K` is documented issued but not current, yet is never rejected.
enum LebanonLetter {
  /// Pre-1998 general series.
  a(
    'A',
    town: null,
    governorate: null,
    description: 'General series, pre-1998',
  ),
  b('B', town: 'Beirut', governorate: 'Beirut', description: 'Beirut'),
  y('Y', town: 'Aley', governorate: 'Mount Lebanon', description: 'Aley'),
  g('G', town: 'Jounieh', governorate: 'Mount Lebanon', description: 'Jounieh'),
  n('N', town: 'Nabatieh', governorate: 'Nabatieh', description: 'Nabatieh'),
  o('O', town: 'Ouzai', governorate: 'Mount Lebanon', description: 'Ouzai'),
  s('S', town: 'Sidon', governorate: 'South Lebanon', description: 'Sidon'),
  t('T', town: 'Tripoli', governorate: 'North Lebanon', description: 'Tripoli'),

  /// Baalbek, not currently issued.
  k(
    'K',
    town: 'Baalbek',
    governorate: 'Beqaa',
    description: 'Baalbek',
    inUse: false,
  ),
  z('Z', town: 'Zahleh', governorate: 'Beqaa', description: 'Zahleh'),
  j('J', town: null, governorate: null, description: 'Judicial'),
  r('R', town: null, governorate: null, description: 'Religious official'),

  /// Also on public-institution and driving-school plates (told apart by colour).
  m('M', town: null, governorate: null, description: 'Motorcycle / commercial'),
  c('C', town: null, governorate: null, description: 'Consular'),
  d('D', town: null, governorate: null, description: 'Diplomatic'),
  p('P', town: null, governorate: null, description: 'Public transport'),

  /// Two glyphs; numbered 1..128 (validated).
  mp('MP', town: null, governorate: null, description: 'Member of parliament');

  const LebanonLetter(
    this.character, {
    required this.town,
    required this.governorate,
    required this.description,
    this.inUse = true,
  });

  final String character;
  final String? town;
  final String? governorate;
  final String description;
  final bool inUse;

  bool get isTownCode => town != null;

  /// Case-insensitive lookup; `'mp'` and `'MP'` both return [mp].
  static LebanonLetter? fromCharacter(String character) {
    final String key = character.toUpperCase();
    for (final LebanonLetter l in values) {
      if (l.character == key) return l;
    }
    return null;
  }

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

  static List<LebanonLetter> get townCodes =>
      values.where((LebanonLetter l) => l.isTownCode).toList(growable: false);
}
