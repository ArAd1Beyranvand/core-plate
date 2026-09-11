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

  const YemenGovernorate(this.code, this.englishName, this.arabicName, {required this.underHouthiControl});

  /// The number printed in the plate's upper register, 1..22.
  final int code;

  final String englishName;
  final String arabicName;

  /// Whether this governorate sits in the territory the 1993 northern format
  /// is genuinely current in.
  ///
  /// **Advisory, coarse, and never enforced.** Three things about it:
  ///
  /// 1. It is a per-governorate boolean over a front line that does not
  ///    respect governorate boundaries. Taiz, Al Jawf, Hadhramaut and Marib
  ///    are all split in practice, and this field flattens each of them to one
  ///    bit — the bit for where the registration authority sits.
  /// 2. Northern plates are on the road outside the north and southern
  ///    governorate codes appear on northern plates, because vehicles move and
  ///    registrations predate the split.
  /// 3. A validator that rejected a southern governorate code on a northern
  ///    plate would therefore be wrong on the facts as well as making a
  ///    political claim the data does not support. `YemenNorthernValidator`
  ///    checks the 1..22 range and stops there.
  ///
  /// Use it to sort a picker, to caption a list, or to warn. Do not use it to
  /// refuse a plate.
  // TODO(control-map): this snapshot is coarse and dates from the brief this
  // package was written against. A consumer who needs current control lines
  // should carry their own map rather than trusting an enum baked into a
  // published package.
  final bool underHouthiControl;

  /// The governorate with [code], or null when [code] is outside 1..22.
  ///
  /// The lookup a host reaches for after reading the upper register off a
  /// plate. Returning null rather than throwing keeps it usable on a
  /// half-entered plate, where `0` and `2` are both ordinary intermediate
  /// states of typing `20`.
  static YemenGovernorate? fromCode(int code) {
    for (final g in values) {
      if (g.code == code) return g;
    }
    return null;
  }

  /// The governorate the upper register [digits] name, or null when [digits]
  /// is empty, not a number, or outside 1..22.
  ///
  /// Accepts a zero-padded two-digit register (`'07'`) as well as a bare one
  /// (`'7'`): the plate has two cells and a code below ten may be printed in
  /// either.
  static YemenGovernorate? fromDigits(String digits) {
    final parsed = int.tryParse(digits);
    return parsed == null ? null : fromCode(parsed);
  }

  /// The lowest legal governorate code. `0` is not one.
  static const int minCode = 1;

  /// The highest legal governorate code.
  static const int maxCode = 22;
}
