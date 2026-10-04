import 'package:plate_core/plate_core.dart';

/// The alphabets of India's current registration formats. Plates print Latin
/// letters and Western digits only.
abstract final class IndiaAlphabets {
  static const PlateAlphabet digits = PlateAlphabet.latinDigits;

  /// Any letter: state codes, the diplomatic mission type, the military
  /// check letter. Which combinations mean anything is `IndiaValidator`'s call.
  static const PlateAlphabet letters = PlateAlphabet(
    id: 'in.letters',
    characters: <String>[
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
      'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    ],
    input: AlphabetInput.typed,
    isNumeric: false,
  );

  /// RTO series letters, and the Bharat, vintage and temporary suffixes: I and
  /// O are never issued, to avoid confusion with 1 and 0.
  static const PlateAlphabet series = PlateAlphabet(
    id: 'in.series',
    characters: <String>[
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M', //
      'N', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    ],
    input: AlphabetInput.typed,
    isNumeric: false,
  );

  /// The two-letter state and union-territory codes in current use, and the
  /// four former codes still valid on vehicles registered under them
  /// (UA, OR, DN, TS).
  static const Map<String, String> stateNames = <String, String>{
    'AN': 'Andaman and Nicobar Islands',
    'AP': 'Andhra Pradesh',
    'AR': 'Arunachal Pradesh',
    'AS': 'Assam',
    'BR': 'Bihar',
    'CG': 'Chhattisgarh',
    'CH': 'Chandigarh',
    'DD': 'Dadra and Nagar Haveli and Daman and Diu',
    'DL': 'Delhi',
    'GA': 'Goa',
    'GJ': 'Gujarat',
    'HP': 'Himachal Pradesh',
    'HR': 'Haryana',
    'JH': 'Jharkhand',
    'JK': 'Jammu and Kashmir',
    'KA': 'Karnataka',
    'KL': 'Kerala',
    'LA': 'Ladakh',
    'LD': 'Lakshadweep',
    'MH': 'Maharashtra',
    'ML': 'Meghalaya',
    'MN': 'Manipur',
    'MP': 'Madhya Pradesh',
    'MZ': 'Mizoram',
    'NL': 'Nagaland',
    'OD': 'Odisha',
    'PB': 'Punjab',
    'PY': 'Puducherry',
    'RJ': 'Rajasthan',
    'SK': 'Sikkim',
    'TG': 'Telangana',
    'TN': 'Tamil Nadu',
    'TR': 'Tripura',
    'UK': 'Uttarakhand',
    'UP': 'Uttar Pradesh',
    'WB': 'West Bengal',
    'UA': 'Uttaranchal (former)',
    'OR': 'Orissa (former)',
    'DN': 'Dadra and Nagar Haveli (former)',
    'TS': 'Telangana (former)',
  };

  /// Armed-forces vehicle class, the letter after the procurement year.
  static const Map<String, String> militaryClasses = <String, String>{
    'A': 'Motorised two-wheeler',
    'B': 'Light motor vehicle',
    'C': 'Truck under 3 t or pick-up',
    'D': 'Truck over 3 t',
    'E': 'High-mobility vehicle',
    'F': 'Light specialist vehicle',
    'G': 'Trailer',
    'H': 'Truck with material handling',
    'J': 'Snow removal vehicle',
    'K': 'Ambulance',
    'P': 'Generic support vehicle',
    'Q': 'Construction vehicle',
    'R': 'Customised vehicle',
    'X': 'Active combat vehicle',
  };

  /// Trade-certificate vehicle category.
  static const Map<String, String> tradeCategories = <String, String>{
    'A': 'Two-wheeler',
    'B': 'Invalid carriage',
    'C': 'Light motor vehicle',
    'D': 'Medium passenger vehicle',
    'E': 'Medium goods vehicle',
    'F': 'Heavy passenger vehicle',
    'G': 'Heavy goods vehicle',
    'H': 'E-rickshaw',
    'I': 'E-cart',
    'J': 'Other',
  };

  /// Diplomatic mission types that fit two cells. IOD (international
  /// organisation) has three letters and does not fit the diplomatic spec.
  static const Map<String, String> missions = <String, String>{
    'CD': 'Embassy',
    'CC': 'Consulate',
    'UN': 'United Nations',
  };
}
