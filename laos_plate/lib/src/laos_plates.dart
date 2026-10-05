import 'package:flutter/widgets.dart';
import 'package:plate_alphabet/plate_alphabet.dart';
import 'package:plate_core/plate_core.dart';

import 'laos_colors.dart';
import 'laos_country.dart';
import 'laos_provinces.dart';
import 'laos_themes.dart';
import 'laos_usage.dart';

/// Where the ink sits on the 2001 Lao plates, in plate units.
///
/// Every reference is a photograph. Each was flattened by fitting a line to
/// each plate edge (the first strong colour step in from the car body, along
/// the middle 60% of the side) and warping the quad to 340×150; then the ink
/// was projected onto each axis.
///
/// The canvas is not the article's 520×110 (aspect 4.73): no photographed
/// plate is that shape. The photos measure 2.16–2.30 (median 2.26; the taxable
/// plate's 2.46 is shot from above), which is 340×150 (2.27).
///
/// Measured ink, as target for the goldens:
///
/// * Provincial (5 photos): caption x 54–286.5, y 11–57 including the marks
///   above it; consonant cells centred 40 and 86.5; digit cells centred
///   163.2 + 45.4k; serial row y 65.5–136.3 (70.8 tall, cy 100.9). EV badge
///   x 9.4–36.4, y 9.0–33.2, its letters y 11–31.
/// * Temporary (1 photo): consonants centred 42.4 and 96.2; the digit before
///   the dash 146.1, the dash 178.6, three digits from 211.9 at 45.4; row
///   y 13.5–85.2 (cy 49.4). Expiry row y 113–134.8 (cy 123.9): caption
///   x 15.2–125.5, digits at a pitch of 18.7 in runs of 2, 4, 2 from 165.2,
///   each dash adding 10.8.
/// * International organisation (1 photo): prefix x 22–118.5, row y 35.8–108
///   (cy 71.9); digits 144.4 + 45.4k, the dash run adding 20.4.
/// * Police (1 photo): prefix x 15–135, y 20–78.2; underline x 37.5–111,
///   y 83–89.5; digits 168.2 + 45.4k, y 38.2–109 (cy 73.6).
///
/// The plates' typeface is condensed — a digit is 37 wide and 69 tall — so a
/// normal face's digit at the measured 45.4 pitch is limited by the cell
/// width, not its height: slots scale glyphs down to fit their box. Rendered
/// in DejaVu Sans Bold the serial digits land on their measured centres but
/// stand 49 tall, 69% of the reference; a bigger box cannot help.
///
/// Lao text is sized by width for the same reason. Each glyph below was
/// calibrated by rendering at a known size in Noto Looped Lao Bold and
/// scaling to the measured span: the caption inks 270.5 wide at 40 (target
/// 232.5), "ໝົດກຳນົດ" 84.5 at 24 (target 110.3), "ສທ" 53.5 at 48 (target
/// 96.5) and "ປກສ" 83.1 at 48 (target 120). A narrower host face leaves the
/// text smaller than the photo, never overlapping.
abstract final class _Layout {
  static const double width = 340, height = 150;

  /// Digit pitch, the mean of all five 45-ish runs (45.2–45.8).
  static const double pitch = 45.4;

  /// What a dash adds between two runs at [pitch] (65.8 − 45.4 on both the
  /// temporary and the international plate).
  static const double dashGap = 20.4;

  // Provincial.
  static const double captionCx = 170.2, captionCy = 34, captionGlyph = 34.4;
  static const double serialCy = 100.9, serialBox = 96;
  static const double letterCx = 40, letterPitch = 46.5;
  static const double digitCx = 163.2;
  static const PlateBox evBadge = PlateBox(9.4, 9.0, 27, 24.2);
  static const double evGlyph = 24, evRadius = 2.5;

  // Temporary.
  static const double tempCy = 49.4, tempBox = 96;
  static const double tempLetterCx = 42.4, tempLetterPitch = 53.8;
  static const double tempDigitCx = 146.1;
  static const double expiryCy = 123.9, expiryBox = 40;
  static const double expiryCaptionCx = 70.4, expiryCaptionGlyph = 31.3;
  static const double expiryDigitCx = 165.2, expiryPitch = 18.7;
  static const double expiryDashGap = 10.8;

  // Prefixed.
  static const _Prefixed dashed = _Prefixed(
    cy: 71.9,
    prefixCx: 70.2,
    prefixCy: 71.9,
    prefixWidth: 96.5,
    prefixGlyph: 86.6,
    digitCx: 144.4,
  );
  static const _Prefixed underlined = _Prefixed(
    cy: 73.6,
    prefixCx: 75,
    prefixCy: 49.1,
    prefixWidth: 120,
    prefixGlyph: 69.3,
    digitCx: 168.2,
    underline: PlateBox(37.5, 83, 73.5, 6.5),
  );
  static const double prefixedBox = 96;
}

/// One measured prefixed layout. [prefixWidth] is the ink span of the
/// photographed prefix and [prefixGlyph] the size that fills it; a prefix
/// with more letters is drawn smaller to fit, since no photo shows one.
class _Prefixed {
  const _Prefixed({
    required this.cy,
    required this.prefixCx,
    required this.prefixCy,
    required this.prefixWidth,
    required this.prefixGlyph,
    required this.digitCx,
    this.underline,
  });

  final double cy, prefixCx, prefixCy, prefixWidth, prefixGlyph, digitCx;
  final PlateBox? underline;
}

/// Accumulates one spec's slots, groups and printed marks.
class _Builder {
  final List<PlateSlot> slots = <PlateSlot>[];
  final List<PlateTextGroup> groups = <PlateTextGroup>[];
  final List<PlateLabel> labels = <PlateLabel>[];

  /// [count] cells centred from [firstCx] at [pitch]; returns the next cell's
  /// centre.
  double run(
    String key,
    PlateAlphabet alphabet,
    int count,
    double firstCx,
    double pitch,
    double cy,
    double box,
  ) {
    final start = slots.length;
    slots.addAll(
      plateRegister(
        alphabet: alphabet,
        count: count,
        left: firstCx - pitch / 2,
        top: cy - box / 2,
        width: pitch,
        height: box,
      ),
    );
    groups.add(
      PlateTextGroup(<int>[
        for (var i = start; i < slots.length; i++) i,
      ], key: key),
    );
    return firstCx + count * pitch;
  }

  /// Digit runs separated by dashes, starting at [firstCx].
  void dashed(
    List<(String, int)> runs,
    double firstCx,
    double pitch,
    double gap,
    double cy,
    double box,
  ) {
    var cx = firstCx;
    for (var i = 0; i < runs.length; i++) {
      if (i > 0) {
        // The dash sits midway between the two runs' facing cells.
        final dashCx = cx - pitch / 2 + gap / 2;
        labels.add(_text('-', dashCx, cy, gap + pitch / 2, box, box));
        cx += gap;
      }
      cx = run(
        runs[i].$1,
        LaosAlphabets.digits,
        runs[i].$2,
        cx,
        pitch,
        cy,
        box,
      );
    }
  }
}

PlateLabel _text(
  String text,
  double cx,
  double cy,
  double width,
  double height,
  double glyph, {
  Color? color,
}) => PlateLabel(
  text: text,
  box: PlateBox(cx - width / 2, cy - height / 2, width, height),
  glyphHeight: glyph,
  color: color,
);

/// Laos's licence plates: three designs, thirteen categories.
///
/// * Provincial — the province's name over two consonants and four digits.
///   Groups `letters`, `serial`.
/// * Temporary — two consonants, a digit, a dash and three digits, over
///   "ໝົດກຳນົດ" (expiry) and a date printed 2-4-2. Groups `letters`,
///   `digit`, `serial`, `expiryLead`, `expiryYear`, `expiryTail`.
/// * Prefixed — fixed letters and digits on one row: `code` and `serial` for
///   the international organisations' 2-2, `serial` for the police and
///   defence plates' four.
///
/// Pair each with its theme in [themeOf].
///
/// The article lists no Israel-specific value (it gives no mission codes).
/// Not implemented: the pre-2001 series, which the article only dates.
abstract final class LaosPlates {
  static final Map<String, PlateSpec> _cache = <String, PlateSpec>{};

  /// [province] is printed on provincial plates and ignored by the others.
  static PlateSpec of(
    LaosCategory category, {
    LaosProvince province = LaosProvince.vientianeCapital,
  }) {
    final id = category.design == LaosDesign.provincial
        ? 'la.${category.id}.${province.id}'
        : 'la.${category.id}';
    return _cache[id] ??= switch (category.design) {
      LaosDesign.provincial => _provincial(id, category, province),
      LaosDesign.temporary => _temporary(id),
      LaosDesign.prefixed => _prefixed(id, category),
    };
  }

  static PlateTheme themeOf(LaosCategory category) => switch (category.id) {
    'private' => LaosThemes.yellow,
    'private_ev' => LaosThemes.amber,
    'government' => LaosThemes.government,
    'taxable_company' => LaosThemes.taxable,
    'company' || 'company_ev' || 'temporary' => LaosThemes.white,
    'public_security' || 'national_defence' => LaosThemes.security,
    _ => LaosThemes.international,
  };

  static PlateSpec get private => of(LaosCategory.private);
  static PlateSpec get privateEv => of(LaosCategory.privateEv);
  static PlateSpec get government => of(LaosCategory.government);
  static PlateSpec get company => of(LaosCategory.company);
  static PlateSpec get companyEv => of(LaosCategory.companyEv);
  static PlateSpec get taxableCompany => of(LaosCategory.taxableCompany);
  static PlateSpec get temporary => of(LaosCategory.temporary);
  static PlateSpec get diplomatic => of(LaosCategory.diplomatic);
  static PlateSpec get foreignGuest => of(LaosCategory.foreignGuest);
  static PlateSpec get unitedNations => of(LaosCategory.unitedNations);
  static PlateSpec get financialInstitution =>
      of(LaosCategory.financialInstitution);
  static PlateSpec get publicSecurity => of(LaosCategory.publicSecurity);
  static PlateSpec get nationalDefence => of(LaosCategory.nationalDefence);

  /// Every category, provincial ones registered in Vientiane Capital.
  static List<PlateSpec> get all => <PlateSpec>[
    for (final c in LaosCategory.values) of(c),
  ];

  static PlateSpec _spec(
    String id,
    _Builder b, {
    List<PlateBand> bands = const <PlateBand>[],
    List<PlateRule> rules = const <PlateRule>[],
  }) => PlateSpec(
    id: id,
    country: LaosCountry.laos,
    canvasWidth: _Layout.width,
    canvasHeight: _Layout.height,
    panel: const PlatePanel(box: PlateBox(0, 0, 0, 0)),
    noPanel: true,
    slots: b.slots,
    labels: b.labels,
    bands: bands,
    rules: rules,
    textGroups: b.groups,
  );

  static PlateSpec _provincial(
    String id,
    LaosCategory category,
    LaosProvince province,
  ) {
    const cy = _Layout.serialCy, box = _Layout.serialBox;
    final b = _Builder();
    b.run(
      'letters',
      LaosAlphabets.letters,
      2,
      _Layout.letterCx,
      _Layout.letterPitch,
      cy,
      box,
    );
    b.run(
      'serial',
      LaosAlphabets.digits,
      4,
      _Layout.digitCx,
      _Layout.pitch,
      cy,
      box,
    );
    b.labels.add(
      _text(
        province.caption,
        _Layout.captionCx,
        _Layout.captionCy,
        260,
        48,
        _Layout.captionGlyph,
      ),
    );
    final bands = <PlateBand>[];
    if (category.ev) {
      const e = _Layout.evBadge;
      bands.add(
        const PlateBand(
          box: e,
          color: LaosColors.evGreen,
          topCornerRadius: _Layout.evRadius,
          bottomCornerRadius: _Layout.evRadius,
        ),
      );
      b.labels.add(
        _text(
          'EV',
          e.left + e.width / 2,
          e.top + e.height / 2,
          e.width,
          e.height,
          _Layout.evGlyph,
          color: LaosColors.white,
        ),
      );
    }
    return _spec(id, b, bands: bands);
  }

  static PlateSpec _temporary(String id) {
    const cy = _Layout.tempCy, box = _Layout.tempBox;
    final b = _Builder();
    b.run(
      'letters',
      LaosAlphabets.letters,
      2,
      _Layout.tempLetterCx,
      _Layout.tempLetterPitch,
      cy,
      box,
    );
    b.dashed(
      const <(String, int)>[('digit', 1), ('serial', 3)],
      _Layout.tempDigitCx,
      _Layout.pitch,
      _Layout.dashGap,
      cy,
      box,
    );
    b.labels.add(
      _text(
        'ໝົດກຳນົດ',
        _Layout.expiryCaptionCx,
        _Layout.expiryCy,
        120,
        _Layout.expiryBox,
        _Layout.expiryCaptionGlyph,
      ),
    );
    b.dashed(
      const <(String, int)>[
        ('expiryLead', 2),
        ('expiryYear', 4),
        ('expiryTail', 2),
      ],
      _Layout.expiryDigitCx,
      _Layout.expiryPitch,
      _Layout.expiryDashGap,
      _Layout.expiryCy,
      _Layout.expiryBox,
    );
    return _spec(id, b);
  }

  static PlateSpec _prefixed(String id, LaosCategory category) {
    final l = category.underline ? _Layout.underlined : _Layout.dashed;
    final b = _Builder();
    // The photographed prefixes fill their span; another length keeps the
    // per-letter size of whichever photo had more letters per unit width.
    final letters = category.prefix.runes.length;
    final measured = category.underline ? 3 : 2;
    final glyph = l.prefixGlyph * (letters > measured ? measured / letters : 1);
    b.labels.add(
      _text(
        category.prefix,
        l.prefixCx,
        category.underline ? l.prefixCy : l.cy,
        l.prefixWidth,
        _Layout.prefixedBox,
        glyph,
      ),
    );
    final runs = category.digitRuns;
    b.dashed(
      <(String, int)>[
        if (runs.length == 2) ('code', runs[0]),
        ('serial', runs.last),
      ],
      l.digitCx,
      _Layout.pitch,
      _Layout.dashGap,
      l.cy,
      _Layout.prefixedBox,
    );
    return _spec(
      id,
      b,
      rules: <PlateRule>[if (l.underline != null) PlateRule(box: l.underline!)],
    );
  }
}
