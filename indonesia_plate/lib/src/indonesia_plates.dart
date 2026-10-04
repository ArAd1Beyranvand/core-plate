import 'package:plate_core/plate_core.dart';
import 'package:flutter/widgets.dart';

import 'indonesia_alphabets.dart';
import 'indonesia_colors.dart';
import 'indonesia_country.dart';
import 'indonesia_services.dart';

/// Where the ink sits on an Indonesian plate, in millimetres.
///
/// Measured off the Wikimedia "2023 Indonesian plate" SVGs, rendered 1280 px
/// wide. The artwork's aspect ratios are the article's sizes exactly (3.40 =
/// 460/135, 2.39 = 275/115), so the pixels map straight onto millimetres.
///
/// * Car (regular, private): serial ink y 16.9–79.4; cell centres 31.8 78.0 |
///   136.5 182.5 226.4 273.1 | 335.0 383.7 429.6. Expiry `08 · 28` ink y
///   98.8–121.1, digit centres 190.3 205.2 · 248.5 264.2, dot at 227.9. The EV
///   band and the diplomatic trim start at y 90.
/// * Motorcycle: serial ink y 14.6–54.1; centres 25.5 49.1 | 85.6 104.9 129.0
///   153.8 | 199.1 225.0 249.8. Expiry right-aligned, ink y 74.8–99.9, digit
///   centres 182.2 198.8 · 234.2 250.0, dot at 216.4. Band from y 67.
/// * Diplomatic: ink y 15.1–78.7; `CD` centres 35.0 76.2; digit centres
///   180.8 219.6 258.4 | 346.8 385.6 424.4. Its expiry is the car's within
///   1.5 mm and shares those constants.
///
/// **Under-height ink, accepted.** `glyphStyle` sets 0.72 of the slot and a
/// DejaVu Bold cap is ~0.73 of that, so the car's 62.5 mm serial would need a
/// 119 mm slot centred at y 48 — off the top of the plate. Slots are as tall
/// as the canvas allows about the measured centre. The car serial is also
/// narrower here than FE-Schrift: DejaVu Bold is wider, and the glyph is
/// width-limited by its cell. `core_plate` is unchanged.
///
/// Measured off the goldens (DejaVu Bold): every glyph centre within ~4 mm
/// and every row centre within 1 mm of the artwork, but ink heights of car
/// 43.3 / 62.5, motorcycle 23.3 / 39.5, diplomatic 40 / 63.6 and expiry
/// ~16 / 22. The glyphs already fill their cells' width (42.5 mm in a 46 mm
/// car cell, against FE-Schrift's 42), so taller slots would not help: the
/// shortfall is the bold face's aspect against the condensed FE-Schrift and
/// DIN, and closes only with a condensed face in the host's theme.
abstract final class _Layout {
  // Car, 460×135.
  static const double carWidth = 460;
  static const double carHeight = 135;
  static const double carSlotTop = 2;
  static const double carSlotHeight = 92;

  /// One pitch for letters and digits: the measured 46.2 / 45.5 / 47.3 are
  /// within 1 mm of it once each group is centred.
  static const double carPitch = 46;

  /// Extra space between groups: centre-to-centre 58.5 and 61.9 less a pitch.
  static const double carGap = 14;
  static const double carBandTop = 90;

  // Expiry row, shared by car and diplomatic.
  static const double expiryTop = 89;

  /// 22.3 mm of ink over the ~0.53 ink ratio.
  static const double expiryHeight = 42;
  static const double expiryPitch = 15.3;
  static const double carMonthLeft = 182.6;
  static const double carYearLeft = 240.8;
  static const double carDotCentre = 227.9;

  // Motorcycle, 275×115.
  static const double motoWidth = 275;
  static const double motoHeight = 115;
  static const double motoSlotTop = 2;
  static const double motoSlotHeight = 65;
  static const double motoPitch = 24.6;
  static const double motoGapNumber = 7.3;

  /// The number→suffix gap is wider than the prefix→number one in the
  /// artwork (45.3 centre to centre against 31.8).
  static const double motoGapSuffix = 20.4;
  static const double motoBandTop = 67;
  static const double motoExpiryTop = 63;

  /// 25.1 mm of ink over the ~0.53 ink ratio.
  static const double motoExpiryHeight = 48;
  static const double motoExpiryPitch = 16.2;
  static const double motoMonthLeft = 174.1;
  static const double motoYearLeft = 226.1;
  static const double motoDotCentre = 216.4;

  // Diplomatic.
  static const double dipSlotTop = 2;
  static const double dipSlotHeight = 90;
  static const double missionLeft = 14.6;
  static const double missionWidth = 82;
  static const double dipPitch = 38.8;

  /// Right edge of each three-digit group's last cell; a shorter group keeps
  /// its right edge.
  static const double dipCountryRight = 277.8;
  static const double dipSerialRight = 443.8;

  /// The dot is 3 mm of ink.
  static const double dotGlyph = 14;
  static const double dotWidth = 10;

  // Military and police, 460×138. See `IndonesiaPlates.military`.
  static const double serviceHeight = 138;
  static const double servicePitch = 37;

  /// Last digit centre to first suffix centre is ~71 on every plate: a
  /// pitch for the dash and this much more.
  static const double dashGap = 34;
  static const double dashWidth = 30;

  /// The serial is 62.8 mm of ink centred at y 90.3 (Army); 94 is as tall as
  /// the plate allows about that centre.
  ///
  /// Measured off the goldens (DejaVu Bold): Army serial ink y 69.5–109.3,
  /// x 149–435 against 58.9–121.8, x ~142–438; police serial y 79.3–116.4
  /// against 75.6–124.7, region y 17.7–50.5 against 15.3–55.7. Centres and
  /// widths agree within ~2 mm; the heights are 63–81% because the bold face
  /// is width-limited in a 37 mm cell, as on the civilian plates.
  static const double milSlotTop = 44;
  static const double milSlotHeight = 94;

  /// The mark: Army star y 19.9–56.3, Navy anchor y 14.7–57.3, both ~40 wide
  /// and centred over the serial.
  static const double markTop = 16;
  static const double markWidth = 42;
  static const double markHeight = 41;

  /// The crest sits inside its square with this much clear on every side.
  static const double emblemMargin = 6;

  static const double policePitch = 35.5;
  static const double policeRim = 6.5;
  static const double policeDividerCentre = 136.4;
  static const double policeDividerWidth = 6.4;

  /// Horizontal divider y 61.1–65.0.
  static const double policeRuleCentre = 63;
  static const double policeRuleWidth = 4;

  /// Region numeral ink y 15.3–55.7: a 71 mm slot from the top.
  static const double regionTop = 0;
  static const double regionHeight = 71;
  static const double regionWidth = 160;

  /// Serial ink y 75.6–124.7 (49 mm, centre 100); 76 mm reaches the bottom.
  static const double policeSlotTop = 62;
  static const double policeSlotHeight = 76;
}

/// One registration's shape: 1–2 area letters, 1–4 digits, 0–3 suffix
/// letters (`B 1945 PKL`).
typedef IndonesiaFormat = ({int prefix, int digits, int suffix});

/// Indonesia's 2023-series geometries.
///
/// * [car] — 460×135, FE-Schrift serial over a centred `MM · YY` expiry row.
/// * [motorcycle] — 275×115, DIN serial over a right-aligned expiry row.
/// * [diplomatic] — the car plate with `CD`/`CC`, the mission's number and
///   the vehicle's, always over a band.
///
/// [car] and [motorcycle] take `band: true` for an electric vehicle: the
/// lower region is then filled in the theme's divider colour, which the EV
/// themes set to blue. The usage classes — private, public, government,
/// free-trade zone — are themes on the same spec.
///
/// Text groups: `prefix`, `number`, `suffix` (if any), `month`, `year`;
/// diplomatic: `mission`, `country`, `serial`, `month`, `year`; military:
/// `number`, `suffix`; police: `region`, `number`, `suffix`.
///
/// ## Military and police
///
/// No artwork exists — Commons has photographs only — so these are measured
/// off photographs, each normalised to 460 mm wide. No size is documented:
/// the civilian width is kept and the height is the median measured aspect
/// (3.31, 3.37, 3.14, 3.41, 3.29), 460×138.
///
/// * [military] — a yellow rim; on the left a red square with the TNI crest
///   in yellow, closed by a yellow upright running rim to rim; the service's
///   field with its mark centred at the top and the serial `NNNNN-SS` in
///   yellow below. The square and upright are background columns. Army:
///   square to x 123, upright 123–137, star x 262–301, serial centres 160
///   196 233.5 271 308, dash 343.5, suffix 379.5 422. Navy: upright
///   115–124, anchor x 270–308. Content is centred on the field.
/// * [police] — the same frame on near-black, the square left in the field
///   colour with the Polri crest; the field is split by a 4 mm yellow rule at
///   y 63 into the region numeral (ink y 15–56, centre x 298) over the
///   serial (ink y 76–125, centres 190.5 226 261.5 297, dash 332, suffix 368
///   404). Upright 133–140.
///
/// The crests are PNG decals cut from the Commons insignia SVGs and recoloured
/// yellow; the star, anchor and roundel are drawn shapes, shipped as PNGs
/// because a decal is the only way to put an image above the background.
/// The Air Force roundel's height is estimated: its photograph is skewed.
///
/// Not implemented: the former (pre-2023) designs; the Ministry of Defence,
/// prosecution-service, House and `RI`/`INDONESIA` plates, known only from
/// photographs too poor to measure; the Navy plate with an expiry row; the
/// red-on-white dealer plate, which has no reference artwork. The faint
/// Korlantas watermark at bottom left is omitted.
abstract final class IndonesiaPlates {
  static const List<int> prefixLengths = <int>[1, 2];
  static const List<int> digitLengths = <int>[1, 2, 3, 4];
  static const List<int> suffixLengths = <int>[0, 1, 2, 3];

  static final Map<(IndonesiaFormat, bool), PlateSpec> _car =
      <(IndonesiaFormat, bool), PlateSpec>{};
  static final Map<(IndonesiaFormat, bool), PlateSpec> _moto =
      <(IndonesiaFormat, bool), PlateSpec>{};
  static final Map<(int, int), PlateSpec> _dip = <(int, int), PlateSpec>{};

  static PlateSpec car({
    int prefix = 2,
    int digits = 4,
    int suffix = 3,
    bool band = false,
  }) {
    final IndonesiaFormat f = _check(prefix, digits, suffix);
    return _car[(f, band)] ??= _serialSpec(f, band: band, motorcycle: false);
  }

  static PlateSpec motorcycle({
    int prefix = 2,
    int digits = 4,
    int suffix = 3,
    bool band = false,
  }) {
    final IndonesiaFormat f = _check(prefix, digits, suffix);
    return _moto[(f, band)] ??= _serialSpec(f, band: band, motorcycle: true);
  }

  /// [countryDigits] and [serialDigits] are each 1–3.
  static PlateSpec diplomatic({int countryDigits = 3, int serialDigits = 3}) {
    if (countryDigits < 1 ||
        countryDigits > 3 ||
        serialDigits < 1 ||
        serialDigits > 3) {
      throw ArgumentError(
        'A diplomatic plate has 1–3 digits per group '
        '(got $countryDigits and $serialDigits).',
      );
    }
    return _dip[(countryDigits, serialDigits)] ??= _diplomaticSpec(
      countryDigits,
      serialDigits,
    );
  }

  static const List<int> serviceDigitLengths = <int>[4, 5];

  static final Map<(IndonesiaService, int), PlateSpec> _mil =
      <(IndonesiaService, int), PlateSpec>{};
  static final Map<int, PlateSpec> _police = <int, PlateSpec>{};

  /// A TNI plate for [service], with a [digits]-digit number (4 or 5).
  static PlateSpec military(IndonesiaService service, {int digits = 5}) {
    _checkService(digits);
    return _mil[(service, digits)] ??= _militarySpec(service, digits);
  }

  /// A Polri plate with a [digits]-digit number (4 or 5).
  static PlateSpec police({int digits = 4}) {
    _checkService(digits);
    return _police[digits] ??= _policeSpec(digits);
  }

  static void _checkService(int digits) {
    if (!serviceDigitLengths.contains(digits)) {
      throw ArgumentError(
        'A military or police number is 4 or 5 digits (got $digits).',
      );
    }
  }

  static PlateDecal _asset(String file, PlateBox box) => PlateDecal(
    image: AssetImage('assets/$file', package: 'indonesia_plate'),
    box: box,
  );

  /// The crest inside the square left of an upright at [dividerStart].
  static PlateDecal _emblem(String file, double rim, double dividerStart) {
    const double m = _Layout.emblemMargin;
    return _asset(
      file,
      PlateBox(
        rim + m,
        rim + m,
        dividerStart - rim - 2 * m,
        _Layout.serviceHeight - 2 * rim - 2 * m,
      ),
    );
  }

  /// `NNNNN-SS` centred on [centre], from [top]: slots, the dash and groups
  /// starting at slot [first].
  static ({List<PlateSlot> slots, PlateLabel dash, List<PlateTextGroup> groups})
  _serviceSerial({
    required int digits,
    required double centre,
    required double top,
    required double height,
    required double pitch,
    int first = 0,
  }) {
    final double left = centre - ((digits + 2) * pitch + _Layout.dashGap) / 2;
    final double numberRight = left + digits * pitch;
    final double suffixLeft = numberRight + _Layout.dashGap;
    final double dashCentre = (numberRight + suffixLeft) / 2;
    return (
      slots: <PlateSlot>[
        ...plateRegister(
          alphabet: IndonesiaAlphabets.digits,
          count: digits,
          left: left,
          top: top,
          width: pitch,
          height: height,
        ),
        ...plateRegister(
          alphabet: IndonesiaAlphabets.digits,
          count: 2,
          left: suffixLeft,
          top: top,
          width: pitch,
          height: height,
        ),
      ],
      dash: PlateLabel(
        text: '-',
        box: PlateBox(
          dashCentre - _Layout.dashWidth / 2,
          top,
          _Layout.dashWidth,
          height,
        ),
        glyphHeight: height,
      ),
      groups: <PlateTextGroup>[
        PlateTextGroup(<int>[
          for (int i = first; i < first + digits; i++) i,
        ], key: 'number'),
        PlateTextGroup(<int>[
          first + digits,
          first + digits + 1,
        ], key: 'suffix'),
      ],
    );
  }

  static PlateSpec _militarySpec(IndonesiaService s, int digits) {
    final double dividerStart = s.dividerCentre - s.dividerWidth / 2;
    final double fieldCentre =
        (s.dividerCentre + s.dividerWidth / 2 + _Layout.carWidth - s.rim) / 2;
    final serial = _serviceSerial(
      digits: digits,
      centre: fieldCentre,
      top: _Layout.milSlotTop,
      height: _Layout.milSlotHeight,
      pitch: _Layout.servicePitch,
    );
    return PlateSpec(
      id: 'id.military.${s.id}.$digits',
      country: IndonesiaCountry.indonesia,
      canvasWidth: _Layout.carWidth,
      canvasHeight: _Layout.serviceHeight,
      noPanel: true,
      panel: const PlatePanel(box: PlateBox(0, 0, 0, _Layout.serviceHeight)),
      background: PlateSection.columns(<PlatePart>[
        PlatePart(
          const PlateSection.fill(PlateFill.color(IndonesiaColors.serviceRed)),
          end: s.dividerCentre,
          divider: s.dividerWidth,
        ),
        const PlatePart(PlateSection.plain),
      ]),
      slots: serial.slots,
      labels: <PlateLabel>[serial.dash],
      decals: <PlateDecal>[
        _emblem('tni_emblem.png', s.rim, dividerStart),
        if (s.mark case final String mark)
          _asset(
            mark,
            PlateBox(
              fieldCentre - _Layout.markWidth / 2,
              _Layout.markTop,
              _Layout.markWidth,
              _Layout.markHeight,
            ),
          ),
      ],
      textGroups: serial.groups,
    );
  }

  static PlateSpec _policeSpec(int digits) {
    const double dividerEnd =
        _Layout.policeDividerCentre + _Layout.policeDividerWidth / 2;
    const double fieldCentre =
        (dividerEnd + _Layout.carWidth - _Layout.policeRim) / 2;
    final serial = _serviceSerial(
      digits: digits,
      centre: fieldCentre,
      top: _Layout.policeSlotTop,
      height: _Layout.policeSlotHeight,
      pitch: _Layout.policePitch,
      first: 1,
    );
    return PlateSpec(
      id: 'id.police.$digits',
      country: IndonesiaCountry.indonesia,
      canvasWidth: _Layout.carWidth,
      canvasHeight: _Layout.serviceHeight,
      noPanel: true,
      panel: const PlatePanel(box: PlateBox(0, 0, 0, _Layout.serviceHeight)),
      background: const PlateSection.columns(<PlatePart>[
        PlatePart(
          PlateSection.plain,
          end: _Layout.policeDividerCentre,
          divider: _Layout.policeDividerWidth,
        ),
        PlatePart(
          PlateSection.rows(<PlatePart>[
            PlatePart(
              PlateSection.plain,
              end: _Layout.policeRuleCentre,
              divider: _Layout.policeRuleWidth,
            ),
            PlatePart(PlateSection.plain),
          ]),
        ),
      ]),
      slots: <PlateSlot>[
        const PlateSlot(
          alphabet: IndonesiaAlphabets.policeRegions,
          box: PlateBox(
            fieldCentre - _Layout.regionWidth / 2,
            _Layout.regionTop,
            _Layout.regionWidth,
            _Layout.regionHeight,
          ),
        ),
        ...serial.slots,
      ],
      labels: <PlateLabel>[serial.dash],
      decals: <PlateDecal>[
        _emblem(
          'polri_emblem.png',
          _Layout.policeRim,
          _Layout.policeDividerCentre - _Layout.policeDividerWidth / 2,
        ),
      ],
      textGroups: <PlateTextGroup>[
        const PlateTextGroup(<int>[0], key: 'region'),
        ...serial.groups,
      ],
    );
  }

  static IndonesiaFormat _check(int prefix, int digits, int suffix) {
    if (!prefixLengths.contains(prefix) ||
        !digitLengths.contains(digits) ||
        !suffixLengths.contains(suffix)) {
      throw ArgumentError(
        'An Indonesian registration is 1–2 letters, 1–4 digits and 0–3 '
        'letters (got $prefix, $digits and $suffix).',
      );
    }
    return (prefix: prefix, digits: digits, suffix: suffix);
  }

  static PlateSection _background(double bandTop) =>
      PlateSection.rows(<PlatePart>[
        PlatePart(PlateSection.plain, end: bandTop),
        const PlatePart(PlateSection.fill(PlateFill.divider)),
      ]);

  /// `MM · YY` from [monthLeft] and [yearLeft]. [color] is null to follow the
  /// theme's ink.
  static ({List<PlateSlot> slots, PlateLabel dot}) _expiry({
    required double monthLeft,
    required double yearLeft,
    required double dotCentre,
    required double top,
    required double height,
    required double pitch,
    Color? color,
  }) => (
    slots: <PlateSlot>[
      ...plateRegister(
        alphabet: IndonesiaAlphabets.digits,
        count: 2,
        left: monthLeft,
        top: top,
        width: pitch,
        height: height,
        color: color,
      ),
      ...plateRegister(
        alphabet: IndonesiaAlphabets.digits,
        count: 2,
        left: yearLeft,
        top: top,
        width: pitch,
        height: height,
        color: color,
      ),
    ],
    dot: PlateLabel(
      text: '•',
      box: PlateBox(
        dotCentre - _Layout.dotWidth / 2,
        top,
        _Layout.dotWidth,
        height,
      ),
      glyphHeight: _Layout.dotGlyph,
      color: color,
    ),
  );

  static List<PlateTextGroup> _expiryGroups(int first) => <PlateTextGroup>[
    PlateTextGroup(<int>[first, first + 1], key: 'month'),
    PlateTextGroup(<int>[first + 2, first + 3], key: 'year'),
  ];

  static PlateSpec _serialSpec(
    IndonesiaFormat f, {
    required bool band,
    required bool motorcycle,
  }) {
    final double width = motorcycle ? _Layout.motoWidth : _Layout.carWidth;
    final double height = motorcycle ? _Layout.motoHeight : _Layout.carHeight;
    final double pitch = motorcycle ? _Layout.motoPitch : _Layout.carPitch;
    final double gapNumber = motorcycle
        ? _Layout.motoGapNumber
        : _Layout.carGap;
    final double gapSuffix = motorcycle
        ? _Layout.motoGapSuffix
        : _Layout.carGap;
    final double top = motorcycle ? _Layout.motoSlotTop : _Layout.carSlotTop;
    final double slotHeight = motorcycle
        ? _Layout.motoSlotHeight
        : _Layout.carSlotHeight;

    final double content =
        (f.prefix + f.digits + f.suffix) * pitch +
        gapNumber +
        (f.suffix > 0 ? gapSuffix : 0);
    final double left = (width - content) / 2;
    final double numberLeft = left + f.prefix * pitch + gapNumber;
    final double suffixLeft = numberLeft + f.digits * pitch + gapSuffix;

    final expiry = motorcycle
        ? _expiry(
            monthLeft: _Layout.motoMonthLeft,
            yearLeft: _Layout.motoYearLeft,
            dotCentre: _Layout.motoDotCentre,
            top: _Layout.motoExpiryTop,
            height: _Layout.motoExpiryHeight,
            pitch: _Layout.motoExpiryPitch,
          )
        : _expiry(
            monthLeft: _Layout.carMonthLeft,
            yearLeft: _Layout.carYearLeft,
            dotCentre: _Layout.carDotCentre,
            top: _Layout.expiryTop,
            height: _Layout.expiryHeight,
            pitch: _Layout.expiryPitch,
          );

    final int n = f.prefix + f.digits;
    final int serial = n + f.suffix;
    return PlateSpec(
      id:
          'id.${motorcycle ? 'motorcycle' : 'car'}'
          '.${f.prefix}${f.digits}${f.suffix}${band ? '.band' : ''}',
      country: IndonesiaCountry.indonesia,
      canvasWidth: width,
      canvasHeight: height,
      noPanel: true,
      panel: PlatePanel(box: PlateBox(0, 0, 0, height)),
      background: band
          ? _background(motorcycle ? _Layout.motoBandTop : _Layout.carBandTop)
          : PlateSection.plain,
      slots: <PlateSlot>[
        ...plateRegister(
          alphabet: IndonesiaAlphabets.letters,
          count: f.prefix,
          left: left,
          top: top,
          width: pitch,
          height: slotHeight,
        ),
        ...plateRegister(
          alphabet: IndonesiaAlphabets.digits,
          count: f.digits,
          left: numberLeft,
          top: top,
          width: pitch,
          height: slotHeight,
        ),
        if (f.suffix > 0)
          ...plateRegister(
            alphabet: IndonesiaAlphabets.letters,
            count: f.suffix,
            left: suffixLeft,
            top: top,
            width: pitch,
            height: slotHeight,
          ),
        ...expiry.slots,
      ],
      labels: <PlateLabel>[expiry.dot],
      textGroups: <PlateTextGroup>[
        PlateTextGroup(<int>[
          for (int i = 0; i < f.prefix; i++) i,
        ], key: 'prefix'),
        PlateTextGroup(<int>[
          for (int i = f.prefix; i < n; i++) i,
        ], key: 'number'),
        if (f.suffix > 0)
          PlateTextGroup(<int>[
            for (int i = n; i < serial; i++) i,
          ], key: 'suffix'),
        ..._expiryGroups(serial),
      ],
    );
  }

  /// The expiry on the band is white on both the black trim and the EV blue,
  /// whatever the serial's ink, so its colour is the design's own.
  static PlateSpec _diplomaticSpec(int countryDigits, int serialDigits) {
    final expiry = _expiry(
      monthLeft: _Layout.carMonthLeft,
      yearLeft: _Layout.carYearLeft,
      dotCentre: _Layout.carDotCentre,
      top: _Layout.expiryTop,
      height: _Layout.expiryHeight,
      pitch: _Layout.expiryPitch,
      color: IndonesiaColors.white,
    );
    final int serialEnd = 1 + countryDigits + serialDigits;
    return PlateSpec(
      id: 'id.diplomatic.$countryDigits$serialDigits',
      country: IndonesiaCountry.indonesia,
      canvasWidth: _Layout.carWidth,
      canvasHeight: _Layout.carHeight,
      noPanel: true,
      panel: const PlatePanel(box: PlateBox(0, 0, 0, _Layout.carHeight)),
      background: _background(_Layout.carBandTop),
      slots: <PlateSlot>[
        const PlateSlot(
          alphabet: IndonesiaAlphabets.missionCodes,
          box: PlateBox(
            _Layout.missionLeft,
            _Layout.dipSlotTop,
            _Layout.missionWidth,
            _Layout.dipSlotHeight,
          ),
        ),
        ...plateRegister(
          alphabet: IndonesiaAlphabets.digits,
          count: countryDigits,
          left: _Layout.dipCountryRight - countryDigits * _Layout.dipPitch,
          top: _Layout.dipSlotTop,
          width: _Layout.dipPitch,
          height: _Layout.dipSlotHeight,
        ),
        ...plateRegister(
          alphabet: IndonesiaAlphabets.digits,
          count: serialDigits,
          left: _Layout.dipSerialRight - serialDigits * _Layout.dipPitch,
          top: _Layout.dipSlotTop,
          width: _Layout.dipPitch,
          height: _Layout.dipSlotHeight,
        ),
        ...expiry.slots,
      ],
      labels: <PlateLabel>[expiry.dot],
      textGroups: <PlateTextGroup>[
        const PlateTextGroup(<int>[0], key: 'mission'),
        PlateTextGroup(<int>[
          for (int i = 1; i <= countryDigits; i++) i,
        ], key: 'country'),
        PlateTextGroup(<int>[
          for (int i = 1 + countryDigits; i < serialEnd; i++) i,
        ], key: 'serial'),
        ..._expiryGroups(serialEnd),
      ],
    );
  }
}
