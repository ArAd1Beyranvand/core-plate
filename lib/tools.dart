import 'model/plate_number.dart';

extension IsDigit on String {
  bool isDigit() {
    switch (this) {
      case '0':
        return true;
      case '1':
        return true;
      case '2':
        return true;
      case '3':
        return true;
      case '4':
        return true;
      case '5':
        return true;
      case '6':
        return true;
      case '7':
        return true;
      case '8':
        return true;
      case '9':
        return true;
      default:
        return false;
    }
  }
}

/// Maps ASCII digits 0-9 to their Persian (Eastern Arabic) equivalents.
/// For RENDERING only — bloc/controller state stays ASCII.
String toPersianDigits(String input) {
  const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    if (char.isDigit()) {
      buffer.write(persian[int.parse(char)]);
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString();
}

extension Tools on PlateNumber {
  bool isCompleted() {
    final res = !values.any((element) => element == null || element == '');
    return res;
  }

  bool isEmpty() => !values.any((element) => element != null);
}
