/// Governorates on modern West Bank plates (post-July-2018). Thirteen issued letters;
/// closed set. Missing `I` and `O` (OCR confusion with digits). `P`–`T` reserved
/// for pre-2012 Gaza (never issued West Bank). See [letters], [confusableLetters], [reservedGazaLetters].
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

  /// Issued letters in allocation order (same as PSAlphabets.governorateLetters).
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

  /// Never issued; OCR misreads (I↔1/J, O↔0). See enum doc.
  static const List<String> confusableLetters = ['I', 'O'];

  /// Allocated to pre-2012 Gaza (never issued West Bank). Rejected by validator.
  static const List<String> reservedGazaLetters = ['P', 'Q', 'R', 'S', 'T'];

  /// Governorate for [letter], or null if not issued.
  static PSGovernorate? byLetter(String letter) {
    for (final g in PSGovernorate.values) {
      if (g.letter == letter) return g;
    }
    return null;
  }
}
