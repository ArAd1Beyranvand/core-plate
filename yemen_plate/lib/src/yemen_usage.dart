/// What a Yemeni plate says the vehicle is for.
///
/// One enum, two systems, and **not the same five values on each**. System A
/// (the 2026 unified plate) has a `police` class; System B (the 1993 northern
/// plate) has a `military` one, and neither has the other's. Rather than two
/// near-identical enums this is one closed set of six with [onUnified] and
/// [onNorthern] saying which system issues which — so a host that offers a
/// usage picker can filter it, and a lookup that is handed a usage its system
/// does not issue can say so instead of guessing.
///
/// The labels are the plate's own text, not translations. [unifiedArabic] and
/// [unifiedLatin] are the two lines printed in the blue side panel of a System
/// A plate; [northernArabic] is the single word printed beside اليمن in the top
/// band of a System B plate.
///
/// Note that [forHire] spells its Arabic word differently on the two systems —
/// `أجرة` with hamza on the unified plate, `اجرة` without on the northern one.
/// That is not a typo to normalise away: they are two different printings, and
/// this package records what each one prints.
enum YemenUsage {
  /// Privately owned vehicles.
  private(unifiedArabic: 'خصوصي', unifiedLatin: 'PRIV.', northernArabic: 'خصوصي'),

  /// Taxis and buses — vehicles carrying people for a fare.
  forHire(unifiedArabic: 'أجرة', unifiedLatin: 'TAXI', northernArabic: 'اجرة'),

  /// Goods vehicles: pick-ups, trucks and trailers.
  transport(unifiedArabic: 'نقل', unifiedLatin: 'TRANS.', northernArabic: 'نقل'),

  /// State-owned vehicles.
  ///
  /// The northern plate is green with white text, but no source names the
  /// Arabic word printed on it, so [northernArabic] is null and the top band
  /// of a northern government plate carries only اليمن.
  // TODO(northern-labels): source the Arabic usage word on a green (government)
  // northern plate and fill in `northernArabic`. Do not copy حكومي across from
  // the unified table — that is a different system's printing.
  government(unifiedArabic: 'حكومي', unifiedLatin: 'GOV.', northernArabic: null),

  /// Police vehicles. **System A only** — the northern system has no police
  /// class distinct from [government] that any source attests.
  police(unifiedArabic: 'شرطة', unifiedLatin: 'POLICE', northernArabic: null),

  /// Military vehicles. **System B only** — the 2026 unified specification
  /// lists five usages and this is not one of them.
  ///
  /// Comes in two forms, which are a [YemenMilitaryStyle] and not two usages:
  /// the classic black field with white text, and a newer white field with red
  /// text. As with [government], no source names an Arabic usage word for it.
  // TODO(northern-labels): source the Arabic usage word on a military northern
  // plate, if it carries one at all.
  military(unifiedArabic: null, unifiedLatin: null, northernArabic: null);

  const YemenUsage({required this.unifiedArabic, required this.unifiedLatin, required this.northernArabic});

  /// Line 2 of the blue side panel on a System A plate; null when System A
  /// does not issue this usage.
  final String? unifiedArabic;

  /// Line 3 of the blue side panel on a System A plate; null when System A
  /// does not issue this usage.
  final String? unifiedLatin;

  /// The usage word beside اليمن in the top band of a System B plate; null
  /// when System B does not issue this usage, **and also** when it does but no
  /// source names the word. [onNorthern] is the question to ask about issuance;
  /// this field is only the text.
  final String? northernArabic;

  /// Whether the 2026 unified system issues this usage.
  bool get onUnified => unifiedLatin != null;

  /// Whether the 1993 northern system issues this usage.
  ///
  /// Derived from [unifiedLatin] rather than from [northernArabic], which is
  /// null for two usages the northern system does issue. The two systems'
  /// value sets differ by exactly one member each way.
  bool get onNorthern => this != YemenUsage.police;

  /// The usages a System A plate can carry.
  static const Set<YemenUsage> unified = <YemenUsage>{private, forHire, transport, government, police};

  /// The usages a System B plate can carry.
  static const Set<YemenUsage> northern = <YemenUsage>{private, forHire, transport, government, military};
}

/// Which of the two military printings a northern military plate uses.
///
/// This is deliberately not a sixth [YemenUsage]: both forms mean "military",
/// they are the same layout and the same serial grammar, and they differ only
/// in the two colours. Modelling it as a usage would put a colour choice into
/// the field a host filters its usage picker on.
enum YemenMilitaryStyle {
  /// The long-standing form: black field, white text.
  classic,

  /// The newer form: white field, red text.
  modern,
}
