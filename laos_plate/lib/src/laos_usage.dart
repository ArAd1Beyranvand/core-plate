import 'package:flutter/foundation.dart';

/// Which of the three layouts a category is printed in. Closed: the library
/// owns the layouts; new categories are new [LaosCategory] values.
enum LaosDesign {
  /// Province name over two consonants and four digits.
  provincial,

  /// One large register and an expiry date, no province.
  temporary,

  /// A fixed prefix and digits on one row, no province.
  prefixed,
}

/// A plate category: its design and the few things that vary within one.
@immutable
class LaosCategory {
  const LaosCategory._(
    this.id,
    this.name,
    this.design, {
    this.ev = false,
    this.prefix = '',
    this.meaning = '',
    this.digitRuns = const <int>[],
    this.underline = false,
  });

  /// Stable identifier, used in spec ids.
  final String id;

  /// English name, as the article gives it.
  final String name;

  final LaosDesign design;

  /// Whether the green EV badge sits in the top-left corner (since 2024).
  final bool ev;

  /// The fixed letters before the digits of a [LaosDesign.prefixed] plate.
  final String prefix;

  /// The article's gloss of [prefix].
  final String meaning;

  /// The digit groups after [prefix], a dash between each.
  final List<int> digitRuns;

  /// Whether [prefix] is underlined, as on the police plate.
  final bool underline;

  static const LaosCategory private = LaosCategory._(
    'private',
    'Private',
    LaosDesign.provincial,
  );
  static const LaosCategory privateEv = LaosCategory._(
    'private_ev',
    'Private (electric)',
    LaosDesign.provincial,
    ev: true,
  );
  static const LaosCategory government = LaosCategory._(
    'government',
    'Government',
    LaosDesign.provincial,
  );
  static const LaosCategory company = LaosCategory._(
    'company',
    'Private company',
    LaosDesign.provincial,
  );
  static const LaosCategory companyEv = LaosCategory._(
    'company_ev',
    'Private company (electric)',
    LaosDesign.provincial,
    ev: true,
  );
  static const LaosCategory taxableCompany = LaosCategory._(
    'taxable_company',
    'Company (1% paid tax)',
    LaosDesign.provincial,
  );
  static const LaosCategory temporary = LaosCategory._(
    'temporary',
    'Temporary',
    LaosDesign.temporary,
  );
  static const LaosCategory diplomatic = LaosCategory._(
    'diplomatic',
    'International organization: diplomatic',
    LaosDesign.prefixed,
    prefix: 'ສທ',
    meaning: 'Diplomatic',
    digitRuns: <int>[2, 2],
  );
  static const LaosCategory foreignGuest = LaosCategory._(
    'foreign_guest',
    'International organization: foreigner guest',
    LaosDesign.prefixed,
    prefix: 'ຂຕ',
    meaning: 'Foreigner guest',
    digitRuns: <int>[2, 2],
  );
  static const LaosCategory unitedNations = LaosCategory._(
    'united_nations',
    'International organization: United Nations',
    LaosDesign.prefixed,
    prefix: 'ສປຊ',
    meaning: 'United Nations',
    digitRuns: <int>[2, 2],
  );
  static const LaosCategory financialInstitution = LaosCategory._(
    'financial_institution',
    'International organization: international financial institution',
    LaosDesign.prefixed,
    prefix: 'ສງ',
    meaning: 'International financial institution',
    digitRuns: <int>[2, 2],
  );
  static const LaosCategory publicSecurity = LaosCategory._(
    'public_security',
    'Police: public security',
    LaosDesign.prefixed,
    prefix: 'ປກສ',
    meaning: 'Public security',
    digitRuns: <int>[4],
    underline: true,
  );
  static const LaosCategory nationalDefence = LaosCategory._(
    'national_defence',
    'Military: national defence',
    LaosDesign.prefixed,
    prefix: 'ກທ',
    meaning: 'National defence',
    digitRuns: <int>[4],
    underline: true,
  );

  static const List<LaosCategory> values = <LaosCategory>[
    private,
    privateEv,
    government,
    company,
    companyEv,
    taxableCompany,
    temporary,
    diplomatic,
    foreignGuest,
    unitedNations,
    financialInstitution,
    publicSecurity,
    nationalDefence,
  ];

  @override
  String toString() => 'LaosCategory.$id';
}
