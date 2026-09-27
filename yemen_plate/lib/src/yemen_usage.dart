/// What a Yemeni plate says the vehicle is for. One enum, two systems with
/// different value sets: System A has `police`, System B has `military`. Use
/// [onUnified] and [onNorthern] to filter. Labels are the plate's own text;
/// note that [forHire] spells its Arabic word differently on each system.
enum YemenUsage {
  /// Privately owned vehicles.
  private(unifiedArabic: 'خصوصي', unifiedLatin: 'PRIV.', northernArabic: 'خصوصي'),

  /// Taxis and buses — vehicles carrying people for a fare.
  forHire(unifiedArabic: 'أجرة', unifiedLatin: 'TAXI', northernArabic: 'اجرة'),

  /// Goods vehicles: pick-ups, trucks and trailers.
  transport(unifiedArabic: 'نقل', unifiedLatin: 'TRANS.', northernArabic: 'نقل'),

  /// State-owned vehicles. Northern: no source names the Arabic word.
  // TODO(northern-labels): source the Arabic usage word on northern green plate.
  government(unifiedArabic: 'حكومي', unifiedLatin: 'GOV.', northernArabic: null),

  /// Police vehicles. System A only.
  police(unifiedArabic: 'شرطة', unifiedLatin: 'POLICE', northernArabic: null),

  /// Military vehicles. System B only. Comes in two forms: [YemenMilitaryStyle.classic]
  /// (black/white) and [YemenMilitaryStyle.modern] (white/red). No source names the word.
  // TODO(northern-labels): source the Arabic usage word on northern military plate.
  military(unifiedArabic: null, unifiedLatin: null, northernArabic: null);

  const YemenUsage({required this.unifiedArabic, required this.unifiedLatin, required this.northernArabic});

  /// Arabic line on System A plate (null if System A doesn't issue this usage).
  final String? unifiedArabic;

  /// Latin line on System A plate (null if System A doesn't issue this usage).
  final String? unifiedLatin;

  /// Usage word on System B plate (null if System B doesn't issue or source is unclear).
  final String? northernArabic;

  /// System A (2026 unified) issues this usage.
  bool get onUnified => unifiedLatin != null;

  /// System B (1993 northern) issues this usage. Derived from [unifiedLatin],
  /// not [northernArabic], which is null for usages the north does issue.
  bool get onNorthern => this != YemenUsage.police;

  /// The usages a System A plate can carry.
  static const Set<YemenUsage> unified = <YemenUsage>{private, forHire, transport, government, police};

  /// The usages a System B plate can carry.
  static const Set<YemenUsage> northern = <YemenUsage>{private, forHire, transport, government, military};
}

/// The two military plate printings. Not a sixth [YemenUsage] — both mean "military",
/// differ only in colours, and are selected by [YemenThemes.forNorthernUsage] style param.
enum YemenMilitaryStyle {
  classic,
  modern,
}
