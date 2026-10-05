import 'package:flutter/foundation.dart';

/// A registering province: the name printed across the top of a provincial
/// plate.
///
/// [caption] for Vientiane Capital is the photographed plates' own text. The
/// others are the provinces' Lao names from Wikidata (`lo` labels of the
/// items behind en.wikipedia's "Provinces of Laos") without their leading
/// ແຂວງ ("province"): no reference photo shows another province's plate, so
/// whether plates print that word is not known.
@immutable
class LaosProvince {
  const LaosProvince._(this.id, this.name, this.caption);

  /// Stable identifier, used in spec ids.
  final String id;

  /// English name.
  final String name;

  /// The Lao name on the plate.
  final String caption;

  static const LaosProvince vientianeCapital = LaosProvince._(
    'vientiane_capital',
    'Vientiane Capital',
    'ນະຄອນຫຼວງວຽງຈັນ',
  );
  static const LaosProvince attapeu = LaosProvince._(
    'attapeu',
    'Attapeu',
    'ອັດຕະປື',
  );
  static const LaosProvince bokeo = LaosProvince._('bokeo', 'Bokeo', 'ບໍ່ແກ້ວ');
  static const LaosProvince bolikhamsai = LaosProvince._(
    'bolikhamsai',
    'Bolikhamsai',
    'ບໍລິຄຳໄຊ',
  );
  static const LaosProvince champasak = LaosProvince._(
    'champasak',
    'Champasak',
    'ຈຳປາສັກ',
  );
  static const LaosProvince houaphanh = LaosProvince._(
    'houaphanh',
    'Houaphanh',
    'ຫົວພັນ',
  );
  static const LaosProvince khammouane = LaosProvince._(
    'khammouane',
    'Khammouane',
    'ຄຳມ່ວນ',
  );
  static const LaosProvince luangNamtha = LaosProvince._(
    'luang_namtha',
    'Luang Namtha',
    'ຫຼວງນໍ້າທາ',
  );
  static const LaosProvince luangPrabang = LaosProvince._(
    'luang_prabang',
    'Luang Prabang',
    'ຫຼວງພະບາງ',
  );
  static const LaosProvince oudomxay = LaosProvince._(
    'oudomxay',
    'Oudomxay',
    'ອຸດົມໄຊ',
  );
  static const LaosProvince phongsaly = LaosProvince._(
    'phongsaly',
    'Phongsaly',
    'ຜົ້ງສາລີ',
  );
  static const LaosProvince sainyabuli = LaosProvince._(
    'sainyabuli',
    'Sainyabuli',
    'ໄຊຍະບູລີ',
  );
  static const LaosProvince salavan = LaosProvince._(
    'salavan',
    'Salavan',
    'ສາລະວັນ',
  );
  static const LaosProvince savannakhet = LaosProvince._(
    'savannakhet',
    'Savannakhet',
    'ສະຫວັນນະເຂດ',
  );
  static const LaosProvince sekong = LaosProvince._(
    'sekong',
    'Sekong',
    'ເຊກອງ',
  );
  static const LaosProvince vientiane = LaosProvince._(
    'vientiane',
    'Vientiane Province',
    'ວຽງຈັນ',
  );
  static const LaosProvince xaisomboun = LaosProvince._(
    'xaisomboun',
    'Xaisomboun',
    'ໄຊສົມບູນ',
  );
  static const LaosProvince xiangkhouang = LaosProvince._(
    'xiangkhouang',
    'Xiangkhouang',
    'ຊຽງຂວາງ',
  );

  static const List<LaosProvince> values = <LaosProvince>[
    vientianeCapital,
    attapeu,
    bokeo,
    bolikhamsai,
    champasak,
    houaphanh,
    khammouane,
    luangNamtha,
    luangPrabang,
    oudomxay,
    phongsaly,
    sainyabuli,
    salavan,
    savannakhet,
    sekong,
    vientiane,
    xaisomboun,
    xiangkhouang,
  ];

  @override
  String toString() => 'LaosProvince.$id';
}
