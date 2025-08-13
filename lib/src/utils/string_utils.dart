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

  /// Convert snake_case to camelCase for Dart field names
  static String toCamelCase(String snakeCase) {
    final parts = snakeCase.split('_');
    if (parts.isEmpty) return snakeCase;
    
    final buffer = StringBuffer(parts.first);
    for (int i = 1; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        buffer.write(parts[i][0].toUpperCase());
        if (parts[i].length > 1) {
          buffer.write(parts[i].substring(1));
        }
      }
    }
    return buffer.toString();
  }
}