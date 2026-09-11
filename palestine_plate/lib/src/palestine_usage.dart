/// What a plate is licensed for. **This is what decides its colour** — see
/// `PSThemes.forUsage`.
///
/// A usage is not always readable off the plate. The legacy West Bank scheme
/// (1994 – July 2018) encodes it in the last two digits, and the Gaza scheme
/// encodes it in the last two digits, so for those two [PSLegacyUsage.forCode]
/// and `PSThemes.forGazaUsageCode` can answer from the value alone. The modern
/// West Bank scheme (`D · DDDD · L`) encodes **no usage at all**: the trailing
/// letter is a governorate, and the four digits are a running serial. A host
/// that renders a modern plate supplies the usage from whatever record it has,
/// and [PSUsage.private] is the default because private cars are the
/// overwhelming majority of what is on the road.
enum PSUsage {
  /// An ordinary car. Legacy codes 40–49 and 90–98; the default everywhere
  /// else. Green on white.
  private,

  /// A leased vehicle. Legacy code 32. Printed the same as [private] — the
  /// distinction is administrative, not visual.
  leased,

  /// Taxi, service and bus. Legacy code 30. **White on green** — the one West
  /// Bank usage that inverts the plate.
  publicTransport,

  /// A Palestinian Authority government vehicle. Legacy code 99. Red on white.
  government,

  /// Duty-exempt: ambulance, fire, civil defence. Legacy code 31. Red on white,
  /// the same as [government].
  exempt,

  /// Police. Modern scheme only — the legacy scheme has no code for it, so
  /// there is nothing to read this off a plate with; a host names it. Green on
  /// white.
  police,

  /// A dealer or inspection plate. Not a usage code in either scheme: it is a
  /// different plate, `PSWestBankPlates.modernTrade`, white on blue.
  tradePlate,

  /// A commercial vehicle or truck. **Gaza only** — Gaza codes 10–19. The West
  /// Bank schemes have no commercial class, so this never comes back from
  /// [PSLegacyUsage.forCode].
  commercial,

  /// A municipality vehicle. **Gaza only** — Gaza codes 40–49. Note that the
  /// same two digits mean [private] in the legacy West Bank scheme: the two
  /// code spaces are unrelated and must never be read with the wrong map.
  municipality,
}

/// The legacy (1994 – July 2018) West Bank usage classes, keyed by the two
/// digits that end the plate.
///
/// Only the codes below are legal. **Anything else is an invalid plate**, not
/// an unknown usage: [forCode] returns null and
/// `PSWestBankLegacyValidator` rejects it.
abstract final class PSLegacyUsage {
  /// The usage the two-digit code [code] denotes, or null when [code] is not a
  /// legal usage class.
  ///
  /// Takes a `String` rather than an `int` because that is the shape a slot
  /// value has, and because `'07'` and `'7'` are different plates. A [code]
  /// that is not exactly two digits is never legal.
  static PSUsage? forCode(String code) {
    if (code.length != 2) return null;
    final n = int.tryParse(code);
    if (n == null) return null;
    // Guards the case `int.tryParse` accepts and a plate does not: '+9', ' 9'.
    if (code.codeUnits.any((u) => u < 0x30 || u > 0x39)) return null;

    if (n >= 40 && n <= 49) return PSUsage.private;
    if (n >= 90 && n <= 98) return PSUsage.private;
    if (n == 99) return PSUsage.government;
    if (n == 30) return PSUsage.publicTransport;
    if (n == 31) return PSUsage.exempt;
    if (n == 32) return PSUsage.leased;
    return null;
  }

  /// Every legal legacy usage code, ascending. The generator draws from this,
  /// so it cannot emit one that [forCode] would reject.
  static const List<String> codes = [
    '30', '31', '32', //
    '40', '41', '42', '43', '44', '45', '46', '47', '48', '49', //
    '90', '91', '92', '93', '94', '95', '96', '97', '98', '99', //
  ];

  /// The legacy district codes, and the district each denotes.
  ///
  /// **`0` and `2` are not in this map and are not legal.** They are not
  /// "unassigned"; a plate carrying one is invalid. That is why
  /// `PSAlphabets.districtDigits` leaves them out of the alphabet outright:
  /// they are not characters a district slot accepts.
  ///
  /// The pre-1995 / post-1995 split is a registration date, not a place: `4`
  /// and `7` are the same territory, registered either side of the handover.
  static const Map<String, String> districts = {
    '1': 'Gaza Strip, registered before 1995',
    '3': 'Gaza Strip, registered after 1995',
    '4': 'Northern West Bank, before 1995',
    '7': 'Northern West Bank, after 1995',
    '5': 'Central West Bank, before 1995',
    '6': 'Central West Bank, after 1995',
    '8': 'Southern West Bank (Bethlehem, Hebron), before 1995',
    '9': 'Southern West Bank (Bethlehem, Hebron), after 1995',
  };

  /// The legal district digits, in the order the alphabet lists them.
  static const List<String> districtCodes = ['1', '3', '4', '5', '6', '7', '8', '9'];
}

/// The Gaza usage classes, keyed by the two digits that end the plate.
///
/// These drive **glyph colour only**. A Gaza plate's field is always white; the
/// design does not invert for public transport the way the West Bank's does.
/// See `PSThemes.forGazaUsageCode`.
abstract final class PSGazaUsage {
  /// The usage the two-digit code [code] denotes, or null when [code] is not a
  /// legal Gaza usage class.
  ///
  /// `30`–`39` and `60`–`99` are unallocated and therefore invalid — note the
  /// difference from the legacy West Bank scheme, where `30`, `31` and `32`
  /// are all legal. The two schemes' code spaces are unrelated.
  static PSUsage? forCode(String code) {
    if (code.length != 2) return null;
    if (code.codeUnits.any((u) => u < 0x30 || u > 0x39)) return null;
    final n = int.parse(code);

    if (n <= 9) return PSUsage.private;
    if (n <= 19) return PSUsage.commercial;
    if (n <= 29) return PSUsage.publicTransport;
    if (n >= 40 && n <= 49) return PSUsage.municipality;
    if (n >= 50 && n <= 59) return PSUsage.government;
    return null;
  }

  /// Every legal Gaza usage code, ascending.
  static List<String> get codes => [
    for (var n = 0; n <= 29; n++) n.toString().padLeft(2, '0'),
    for (var n = 40; n <= 59; n++) n.toString().padLeft(2, '0'),
  ];
}
