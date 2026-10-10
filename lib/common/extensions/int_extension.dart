import 'string_extension.dart';

extension IntPersianHelper on int {
  /// Converts English digits in an integer to Persian digits.
  String toPersianDigit() {
    return toString().toPersianDigit();
  }
}

