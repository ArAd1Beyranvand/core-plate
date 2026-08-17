import 'model/plate_number.dart';

extension IsDigit on String {
  bool isDigit() => length == 1 && codeUnitAt(0) >= 0x30 && codeUnitAt(0) <= 0x39;
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
    return !values.any((element) => element == null || element == '');
  }

  bool isEmpty() => !values.any((element) => element != null);
}
