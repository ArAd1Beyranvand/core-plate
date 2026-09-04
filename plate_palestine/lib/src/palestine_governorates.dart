/// The governorate a modern (post-July-2018) West Bank plate's trailing letter
/// stands for.
///
/// The set is **closed**. Thirteen letters were allocated and thirteen are
/// issued; a letter outside this enum is not a governorate this package has not
/// heard of, it is a plate that does not exist.
///
/// **There is no `I` and no `O`.** The sequence runs `... G H J K ...`: `H`
/// (Ramallah) is followed by `J` (Jerusalem), and `N` (Yatta) is the last
/// letter. `I` and `O` are omitted for the reason every plate scheme omits
/// them — at plate scale, in the condensed face these are printed in, `I` is
/// indistinguishable from `1` and from a sans-serif `J`, and `O` from `0`. Two
/// consequences worth writing down:
///
/// - **Never emit them.** [PSSerialGenerator] cannot, and
///   `PSWestBankModernValidator` rejects them by name.
/// - **In an OCR confusion matrix they are guaranteed misreads, not
///   candidates.** A recogniser that returns `I` has read a `1` or a `J`; one
///   that returns `O` has read a `0`. Map them, do not score them.
///
/// `P`, `Q`, `R`, `S` and `T` are a separate case: they *were* allocated, to
/// Gaza's governorates, and were never issued — Gaza left the Palestinian
/// Authority's numbering in 2012 and has run its own design since. They are
/// listed in [reservedGazaLetters] and rejected by the validator, because a
/// West Bank plate ending in `P` is not a Gaza plate, it is nothing.
enum PSGovernorate {
  jenin('A', 'جنين', 'Jenin'),
  tulkarm('B', 'طولكرم', 'Tulkarm'),
  tubas('C', 'طوباس', 'Tubas'),
  nablus('D', 'نابلس', 'Nablus'),
  qalqilya('E', 'قلقيلية', 'Qalqilya'),
  salfit('F', 'سلفيت', 'Salfit'),
  jericho('G', 'أريحا', 'Jericho'),
  ramallah('H', 'رام الله', 'Ramallah'),

  /// The gap. `I` is not skipped between [ramallah] and here by accident.
  jerusalem('J', 'القدس', 'Jerusalem'),
  bethlehem('K', 'بيت لحم', 'Bethlehem'),
  hebron('L', 'الخليل', 'Hebron'),
  dura('M', 'دورا', 'Dura'),
  yatta('N', 'يطا', 'Yatta');

  const PSGovernorate(this.letter, this.arabicName, this.englishName);

  /// The single Latin capital printed on the plate.
  final String letter;
  final String arabicName;
  final String englishName;

  /// Every issued letter, in allocation order — which is also the order
  /// `PSAlphabets.governorateLetters` presents them in, so a picker's wheel
  /// reads `A B C D E F G H J K L M N`.
  static const List<String> letters = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'J',
    'K',
    'L',
    'M',
    'N',
  ];

  /// The two letters that are never issued anywhere in the scheme, and are
  /// misreads rather than values. See the enum doc.
  static const List<String> confusableLetters = ['I', 'O'];

  /// Allocated to Gaza's governorates under the pre-2012 Palestinian Authority
  /// scheme and never issued. Rejected on a West Bank plate; a real Gaza plate
  /// carries no letter at all.
  static const List<String> reservedGazaLetters = ['P', 'Q', 'R', 'S', 'T'];

  /// The governorate [letter] stands for, or null when it is not an issued
  /// letter. Null covers `I`, `O`, the reserved Gaza letters and everything
  /// else — the caller decides which of those it wants to say something about.
  static PSGovernorate? byLetter(String letter) {
    for (final g in PSGovernorate.values) {
      if (g.letter == letter) return g;
    }
    return null;
  }
}
