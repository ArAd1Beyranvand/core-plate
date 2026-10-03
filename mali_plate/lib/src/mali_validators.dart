/// Advisory validators for Mali plates. Mali plates follow the simple
/// format: 2 letters, 4 digits, 2 letters (XX #### XX).
abstract final class MaliValidators {
  /// Validates that the input is a valid Mali plate serial.
  /// Format: AB1234MD (letters, digits, letters).
  static bool validate(String input) {
    const int totalLength = 8;

    if (input.length != totalLength) {
      return false;
    }

    // First 2 characters must be letters
    for (int i = 0; i < 2; i++) {
      if (!_isLetter(input[i])) {
        return false;
      }
    }

    // Next 4 characters must be digits
    for (int i = 2; i < 6; i++) {
      if (!_isDigit(input[i])) {
        return false;
      }
    }

    // Last 2 characters must be letters
    for (int i = 6; i < 8; i++) {
      if (!_isLetter(input[i])) {
        return false;
      }
    }

    return true;
  }

  static bool _isLetter(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  static bool _isDigit(String char) {
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }
}
