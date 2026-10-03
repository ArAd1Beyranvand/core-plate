/// The private and commercial liveries have Wikipedia artwork. The other four
/// are built from the article's prose alone — no image of any of them was
/// found — so their colours and layout are unverified.
enum NigerUsage {
  /// Black on white.
  private('Private'),

  /// Black on orange.
  commercial('Commercial'),

  /// Blue on white, `12345ARN6`. Unverified.
  stateTransport('State transport'),

  /// White on black, with the flag at the left. Unverified.
  military('Military'),

  /// Orange on green, `123CMD RN`: chairman of a mission. Unverified.
  diplomaticChief('Diplomatic chairman'),

  /// Orange on green, `123CD4 RN`: mission staff. Unverified.
  diplomaticStaff('Diplomatic staff');

  const NigerUsage(this.english);

  final String english;
}
