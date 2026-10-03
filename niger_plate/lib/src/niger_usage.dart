/// The liveries Wikipedia's artwork exists for. Government (blue on white),
/// military, and diplomatic plates are described in prose only.
// TODO(niger-usages): add the other groups once an image of each is sourced.
enum NigerUsage {
  /// Black on white.
  private('Private'),

  /// Black on orange.
  commercial('Commercial');

  const NigerUsage(this.english);

  final String english;
}
