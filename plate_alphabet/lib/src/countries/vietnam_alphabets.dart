import 'package:plate_core/plate_core.dart';

import '../plate_alphabet.dart';

/// The alphabets behind Vietnamese slots.
///
/// [series] is the civil serial letter: the article says a civil plate omits
/// I, J, O, Q and W and includes Đ. [letters] is all of A–Z, for the military
/// unit code, the `T` of a temporary plate and the NG/QT/NN status code, none
/// of which follow the civil rule. [seriesOrDigit] is the second cell of a
/// motorcycle's `NN-LN` / `NN-LL` series. The rules live in the validators;
/// these only say what a key may type.
abstract final class VietnamAlphabets {
  static const PlateAlphabet digits = PlateAlphabetDigits.english;

  static const List<String> _series = <String>[
    'A', 'B', 'C', 'D', 'Đ', 'E', 'F', 'G', 'H', 'K', 'L', 'M', 'N', //
    'P', 'R', 'S', 'T', 'U', 'V', 'X', 'Y', 'Z',
  ];

  static const PlateAlphabet series = PlateAlphabet(
    id: 'vn.series',
    characters: _series,
    input: AlphabetInput.typed,
    isNumeric: false,
  );

  static const PlateAlphabet seriesOrDigit = PlateAlphabet(
    id: 'vn.seriesOrDigit',
    characters: <String>[
      ..._series, '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', //
    ],
    input: AlphabetInput.typed,
    isNumeric: false,
  );

  static const PlateAlphabet letters = PlateAlphabet(
    id: 'vn.letters',
    characters: <String>[
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
      'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    ],
    input: AlphabetInput.typed,
    isNumeric: false,
  );
}
