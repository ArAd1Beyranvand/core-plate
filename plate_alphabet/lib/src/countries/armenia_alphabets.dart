import 'package:plate_core/plate_core.dart';

/// The alphabets an Armenian plate slot is drawn over, and the one piece of
/// Armenian history that is data rather than prose: when each letter became
/// legal.
///
/// **Armenian plates are printed in Latin letters, and always were** — but not
/// because the country writes its registrations in Latin. The four letters the
/// system opened with in 1996 were chosen for their *shapes*: `Լ`/`L`, `Ս`
/// (which reads `s` and looks like `U`), `Տ` (which reads `t` and looks like
/// `S`) and `Օ` (which reads `ô` and looks like `O`). An Armenian read them as
/// Armenian and a foreigner read them as Latin, and the plate did not have to
/// choose. Every letter added since is a plain Latin one with no Armenian
/// counterpart at all, and by 2019 all twenty-six were in use.
///
/// That is why [letters] is simply A-Z and carries no [PlateAlphabet.glyphs]:
/// on a modern plate there is nothing to transliterate. The Armenian script
/// survives on exactly one design — the military plate, whose `ՊՆ` and class
/// letter are Armenian and are not doubling for anything Latin. It gets
/// [militaryClass], the only alphabet here that renders a script.
abstract final class ArmeniaAlphabets {
  /// The two letters in the middle of a civilian number: all twenty-six.
  ///
  /// Restated under an `am.` id rather than reusing
  /// [PlateAlphabet.latinUppercase] so that it and the three class alphabets
  /// below are declared side by side, in the one file that explains why an
  /// Armenian plate's letters are Latin.
  ///
  /// All twenty-six are *accepted*, because all twenty-six are issued. Which
  /// ones may appear on a *civilian* plate is a narrower question than which
  /// ones exist, and it is a validator's to answer, not an alphabet's — see
  /// [stateVehiclesOnly] and `ArmeniaPlateValidator`. An alphabet that barred
  /// `G` would make the rule un-typeable rather than reportable, which is the
  /// one thing `core_plate` asks validation never to do.
  static const PlateAlphabet letters = PlateAlphabet(
    id: 'am.letters',
    characters: <String>[
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z',
    ],
    input: AlphabetInput.typed,
    isNumeric: false,
  );

  /// The class letter on a diplomatic plate: `D` for a diplomat, `T` for a
  /// technician.
  ///
  /// Its own alphabet and not a restriction of [letters], because it is a
  /// different vocabulary rather than a subset of one: `D` here names the
  /// holder of the accreditation, where a `D` in a civilian pair names nothing
  /// at all.
  static const PlateAlphabet diplomaticClass = PlateAlphabet(
    id: 'am.diplomaticClass',
    characters: <String>['D', 'T'],
    input: AlphabetInput.chosen,
    isNumeric: false,
  );

  /// The letter at the tail of a bus number: `S` for a city bus, `L` for a
  /// long-range coach.
  static const PlateAlphabet busClass = PlateAlphabet(
    id: 'am.busClass',
    characters: <String>['S', 'L'],
    input: AlphabetInput.chosen,
    isNumeric: false,
  );

  /// The letter at the tail of a Ministry of Defence number, in Armenian: `Մ`
  /// for a passenger vehicle, `Տ` for a transport one.
  ///
  /// Stored as the ASCII mnemonics `M` and `T` and rendered as the Armenian
  /// letters, which is the [PlateAlphabet.glyphs] contract: storage stays
  /// ASCII, so a stored plate is still readable in a log and sortable in a
  /// database, and only the face is Armenian.
  ///
  /// [AlphabetInput.chosen], not typed: `Մ` is not on a keyboard, and a class
  /// is picked from a list of two rather than spelled.
  static const PlateAlphabet militaryClass = PlateAlphabet(
    id: 'am.militaryClass',
    characters: <String>['M', 'T'],
    input: AlphabetInput.chosen,
    isNumeric: false,
    glyphs: <String, String>{
      'M': 'Մ', // մարդատար — passenger
      'T': 'Տ', // տրանսպորտ — transport
    },
  );

  /// The two letters that are issued only to the state.
  ///
  /// `G` and `I` were brought in at the start of 2015 for the Police and the
  /// Prosecutor's office alone, and only ever doubled: `GG` or `II`, never
  /// beside another letter. No private vehicle carries either, which is a rule
  /// about who may hold a number rather than about which characters exist, so
  /// it lives here as data and is enforced in `ArmeniaPlateValidator`.
  static const Set<String> stateVehiclesOnly = <String>{'G', 'I'};

  /// When each letter entered general civilian use, as year and month.
  ///
  /// The whole of the article's letters timeline, transcribed: the four the
  /// system opened with in 1996, `P` from December 2008, and then the batches
  /// of 2010, 2012, 2013, 2016, 2017, 2018 and 2019. Four of them — `D`, `N`,
  /// `T` and `V` — were issuable for a fee from November 2010 and general from
  /// July 2012, and it is the later date that is recorded: this map answers
  /// "could an ordinary registration carry this letter", and until July 2012
  /// the answer was no without paying for it.
  ///
  /// `G` and `I` are dated 2015 and are in [stateVehiclesOnly]: they entered
  /// use then, but never general use. A caller asking [inUseOn] about a year
  /// gets them; a caller validating a civilian plate does not, and the two
  /// questions are kept apart on purpose.
  ///
  /// Months, not [DateTime]s: a [DateTime] cannot be `const`, and every date
  /// the article gives is a month at best.
  static const Map<String, (int year, int month)>
  introduced = <String, (int, int)>{
    // The four shape-sharing letters the system opened with in 1996.
    'L': (1996, 1),
    'U': (1996, 1), // Ս
    'S': (1996, 1), // Տ
    'O': (1996, 1), // Օ
    // Special plates only until December 2008.
    'P': (2008, 12),
    // For a fee from November 2010; general from July 2012.
    'D': (2012, 7),
    'N': (2012, 7),
    'T': (2012, 7),
    'V': (2012, 7),
    // For a fee from May 2012.
    'A': (2012, 5),
    'M': (2012, 5),
    'Q': (2012, 5),
    'R': (2012, 5),
    // For a fee from October 2013.
    'C': (2013, 10),
    'F': (2013, 10),
    'Z': (2013, 10),
    // Police and Prosecutor's office only, doubled — see [stateVehiclesOnly].
    'G': (2015, 1),
    'I': (2015, 1),
    'X': (2016, 1),
    'B': (2017, 1),
    'H': (2017, 1),
    'J': (2018, 1),
    'W': (2019, 1),
    'Y': (2019, 1),
    'K': (2019, 1),
    'E': (2019, 1),
  };

  /// Whether [letter] was being issued in [month] of [year].
  ///
  /// Case-insensitive, and false for anything that is not one of the
  /// twenty-six. [month] defaults to December so that a caller who knows only
  /// a year gets the letters that year ended with — the reading that matches
  /// "a 2012 plate", which is a plate issued at some point during 2012.
  static bool inUseOn(String letter, int year, {int month = 12}) {
    final start = introduced[letter.toUpperCase()];
    if (start == null) return false;
    return year > start.$1 || (year == start.$1 && month >= start.$2);
  }
}
