import 'dart:math';

class PasswordGenerator {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  static String generate({
    int length = 16,
    bool useUppercase = true,
    bool useNumbers = true,
    bool useSymbols = true,
  }) {
    String chars = _lowercase;
    if (useUppercase) chars += _uppercase;
    if (useNumbers) chars += _numbers;
    if (useSymbols) chars += _symbols;

    if (chars.isEmpty) return '';

    final random = Random.secure();
    return List.generate(length, (index) {
      return chars[random.nextInt(chars.length)];
    }).join();
  }
}
