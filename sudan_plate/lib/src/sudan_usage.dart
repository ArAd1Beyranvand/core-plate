/// The 2009-series liveries a reference photograph exists for.
///
/// The traffic police list eight groups (ملاكى private, تجارى commercial,
/// شرطة police, حكومى government, إستثمار investment, مواتر motorcycles,
/// هيئات دبلوماسية diplomatic, منظمات organisations), but only these three
/// are photographed on the 2009 plate. Government plates on record are the
/// older yellow series; diplomatic, UN and NGO plates are a separate
/// two-row design.
// TODO(sudan-usages): add the other groups with a reference image each.
enum SudanUsage {
  /// Black on white.
  private('Private'),

  /// White on teal: buses and taxis.
  transport('Bus and taxi'),

  /// White on black.
  commercial('Commercial');

  const SudanUsage(this.english);

  final String english;
}
