/// Plate usage — determines colour via `PSThemes.forUsage`. Legacy/Gaza schemes
/// encode usage in trailing digits; modern West Bank doesn't. Host supplies usage
/// for modern plates; [PSUsage.private] is the default.
enum PSUsage {
  /// Ordinary car (legacy 40–49, 90–98; default elsewhere). Green on white.
  private,

  /// Leased vehicle (legacy 32). Green on white (same visual as private).
  leased,

  /// Taxi, service, bus (legacy 30). White on green — only inverted West Bank usage.
  publicTransport,

  /// Government vehicles (legacy 99). Red on white.
  government,

  /// Duty-exempt: ambulance, fire, civil defence (legacy 31). Red on white.
  exempt,

  /// Police (modern scheme only). Green on white.
  police,

  /// Dealer/inspection plate (different design: PSWestBankPlates.modernTrade). White on blue.
  tradePlate,

  /// Commercial/trucks (Gaza only, codes 10–19). Not in West Bank schemes.
  commercial,

  /// Municipality vehicles (Gaza only, codes 40–49). Different from West Bank private (40–49).
  municipality,
}

/// Legacy West Bank usage classes (1994–July 2018), keyed by trailing digits.
/// Only these codes are legal; anything else is invalid (forCode returns null).
abstract final class PSLegacyUsage {
  /// Usage for two-digit [code], or null if not legal. Takes String (slots use String; '07' ≠ '7').
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

  /// Every legal legacy usage code, ascending (generator draws from this).
  static const List<String> codes = [
    '30', '31', '32', //
    '40', '41', '42', '43', '44', '45', '46', '47', '48', '49', //
    '90', '91', '92', '93', '94', '95', '96', '97', '98', '99', //
  ];

  /// Legacy district codes: 1,3–9 (0,2 invalid; barred at alphabet level).
  /// Pre-1995/post-1995 is registration date, not place (4/7 are same territory).
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

  /// Legal district digits, in alphabet order.
  static const List<String> districtCodes = ['1', '3', '4', '5', '6', '7', '8', '9'];
}

/// Gaza usage classes, keyed by trailing digits. Drive glyph colour only
/// (field always white; no inversion like West Bank). See PSThemes.forGazaUsageCode.
abstract final class PSGazaUsage {
  /// Usage for Gaza [code], or null if invalid. Codes 30–39, 60–99 unallocated
  /// (differs from legacy West Bank; code spaces are unrelated).
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
