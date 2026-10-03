/// The twenty-two governorate codes a 1993 northern plate carries in its upper
/// register.
///
/// The list is **closed**: codes run 1 to 22 inclusive, `0` is not a code, and
/// nothing above 22 is either. `YemenNorthernValidator` enforces exactly that
/// range and nothing more.
///
/// Each value carries its English name, its Arabic name, and
/// [underHouthiControl]. Read the doc on that field before using it: it is
/// exposed, and it is never enforced.
enum YemenGovernorate {
  /// The capital municipality, distinct from the surrounding governorate.
  sanaaCity(1, 'Sanaa (City)', 'أمانة العاصمة', underHouthiControl: true),
  sanaaGovernorate(2, 'Sanaa (Governorate)', 'صنعاء', underHouthiControl: true),
  aden(3, 'Aden', 'عدن', underHouthiControl: false),
  taiz(4, 'Taiz', 'تعز', underHouthiControl: false),
  hadhramaut(5, 'Hadhramaut', 'حضرموت', underHouthiControl: false),
  alHudaydah(6, 'Al Hudaydah', 'الحديدة', underHouthiControl: true),
  ibb(7, 'Ibb', 'إب', underHouthiControl: true),
  hajjah(8, 'Hajjah', 'حجة', underHouthiControl: true),
  dhamar(9, 'Dhamar', 'ذمار', underHouthiControl: true),
  saada(10, 'Saada', 'صعدة', underHouthiControl: true),
  abyan(11, 'Abyan', 'أبين', underHouthiControl: false),
  lahij(12, 'Lahij', 'لحج', underHouthiControl: false),
  alBayda(13, 'Al Bayda', 'البيضاء', underHouthiControl: true),
  alMahwit(14, 'Al Mahwit', 'المحويت', underHouthiControl: true),
  shabwah(15, 'Shabwah', 'شبوة', underHouthiControl: false),
  marib(16, 'Marib', 'مأرب', underHouthiControl: false),
  alMahrah(17, 'Al Mahrah', 'المهرة', underHouthiControl: false),
  alJawf(18, 'Al Jawf', 'الجوف', underHouthiControl: true),
  amran(19, 'Amran', 'عمران', underHouthiControl: true),
  dhale(20, 'Dhale', 'الضالع', underHouthiControl: false),
  raymah(21, 'Raymah', 'ريمة', underHouthiControl: true),
  socotra(22, 'Socotra', 'سقطرى', underHouthiControl: false);

  const YemenGovernorate(
    this.code,
    this.englishName,
    this.arabicName, {
    required this.underHouthiControl,
  });

  /// The number printed in the plate's upper register, 1..22.
  final int code;

  final String englishName;
  final String arabicName;

  /// Whether this governorate sits where the 1993 northern format is genuinely
  /// current. Advisory, coarse, never enforced. Taiz/Al Jawf/Hadhramaut/Marib are
  /// split; this field uses the registration authority's location. Northern plates
  /// appear outside the north. Validator checks 1..22 range, not control status.
  /// Use to sort, caption, warn. Do not use to refuse a plate.
  // TODO(control-map): consumer who needs current control should carry their own map.
  final bool underHouthiControl;

  /// The governorate with [code], or null if outside 1..22. Lookup for the upper
  /// register. Null on half-entered plates (e.g., `0` or `2` as state of typing `20`).
  static YemenGovernorate? fromCode(int code) {
    for (final g in values) {
      if (g.code == code) return g;
    }
    return null;
  }

  /// The governorate the upper register [digits] name, or null if empty, non-numeric, or outside 1..22.
  /// Accepts zero-padded (`'07'`) and bare (`'7'`) two-digit registers.
  static YemenGovernorate? fromDigits(String digits) {
    final parsed = int.tryParse(digits);
    return parsed == null ? null : fromCode(parsed);
  }

  /// The lowest legal governorate code. `0` is not one.
  static const int minCode = 1;

  /// The highest legal governorate code.
  static const int maxCode = 22;
}
