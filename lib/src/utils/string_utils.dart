/// String utility functions for protovalidate-dart
class StringUtils {
  /// Convert camelCase to snake_case
  static String toSnakeCase(String camelCase) {
    final result = StringBuffer();
    for (int i = 0; i < camelCase.length; i++) {
      final char = camelCase[i];
      if (i > 0 && char.toUpperCase() == char && char.toLowerCase() != char) {
        result.write('_');
        result.write(char.toLowerCase());
      } else {
        result.write(char.toLowerCase());
      }
    }
    return result.toString();
  }
}