import '../cursor.dart';
import '../rule_paths.dart';

/// Strategy interface for string format validation
abstract class StringFormatValidator {
  /// The name of the format being validated
  String get formatName;
  
  /// Error message for empty values
  String get emptyMessage;
  
  /// Error message for invalid format
  String get invalidMessage;
  
  /// Validates the format (implemented by subclasses)
  bool isValidFormat(String value);
  
  /// Default implementation that handles empty check and format validation
  void validate(String value, Cursor cursor) {
    if (value.isEmpty) {
      cursor.violate(
        message: emptyMessage,
        constraintId: 'string.${formatName}_empty',
        rulePath: RulePathBuilder.stringConstraint(formatName),
      );
    } else if (!isValidFormat(value)) {
      cursor.violate(
        message: invalidMessage,
        constraintId: 'string.$formatName',
        rulePath: RulePathBuilder.stringConstraint(formatName),
      );
    }
  }
}

/// Email format validator
class EmailValidator extends StringFormatValidator {
  @override
  String get formatName => 'email';
  
  @override
  String get emptyMessage => '';
  
  @override
  String get invalidMessage => 'String must be a valid email address';
  
  @override
  bool isValidFormat(String value) {
    // Simple email validation regex
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(value);
  }
}

/// Hostname format validator
class HostnameValidator extends StringFormatValidator {
  @override
  String get formatName => 'hostname';
  
  @override
  String get emptyMessage => '';
  
  @override
  String get invalidMessage => 'String must be a valid hostname';
  
  @override
  bool isValidFormat(String value) {
    // Simple hostname validation
    if (value.length > 253) return false;
    final parts = value.split('.');
    for (final part in parts) {
      if (part.isEmpty || part.length > 63) return false;
      if (!RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$').hasMatch(part)) return false;
    }
    return true;
  }
}

/// IP address (v4 or v6) format validator
class IpValidator extends StringFormatValidator {
  @override
  String get formatName => 'ip';
  
  @override
  String get emptyMessage => 'value is empty, which is not a valid IP address';
  
  @override
  String get invalidMessage => 'String must be a valid IP address';
  
  @override
  bool isValidFormat(String value) {
    return _isValidIPv4(value) || _isValidIPv6(value);
  }
  
  bool _isValidIPv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }
  
  bool _isValidIPv6(String value) {
    // Basic IPv6 validation - could be more comprehensive
    try {
      final parts = value.split(':');
      if (parts.length > 8) return false;
      for (final part in parts) {
        if (part.isNotEmpty) {
          int.parse(part, radix: 16);
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// IPv4 format validator
class Ipv4Validator extends StringFormatValidator {
  @override
  String get formatName => 'ipv4';
  
  @override
  String get emptyMessage => 'value is empty, which is not a valid IPv4 address';
  
  @override
  String get invalidMessage => 'String must be a valid IPv4 address';
  
  @override
  bool isValidFormat(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }
}

/// IPv6 format validator
class Ipv6Validator extends StringFormatValidator {
  @override
  String get formatName => 'ipv6';
  
  @override
  String get emptyMessage => 'value is empty, which is not a valid IPv6 address';
  
  @override
  String get invalidMessage => 'String must be a valid IPv6 address';
  
  @override
  bool isValidFormat(String value) {
    // Basic IPv6 validation - could be more comprehensive
    try {
      final parts = value.split(':');
      if (parts.length > 8) return false;
      for (final part in parts) {
        if (part.isNotEmpty) {
          int.parse(part, radix: 16);
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// URI format validator
class UriValidator extends StringFormatValidator {
  @override
  String get formatName => 'uri';
  
  @override
  String get emptyMessage => 'value is empty, which is not a valid URI';
  
  @override
  String get invalidMessage => 'String must be a valid URI';
  
  @override
  bool isValidFormat(String value) {
    try {
      Uri.parse(value);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Registry for string format validators
class StringFormatValidatorRegistry {
  static final Map<String, StringFormatValidator> _validators = {
    'email': EmailValidator(),
    'hostname': HostnameValidator(),
    'ip': IpValidator(),
    'ipv4': Ipv4Validator(),
    'ipv6': Ipv6Validator(),
    'uri': UriValidator(),
  };
  
  /// Gets a validator for the specified format
  static StringFormatValidator? getValidator(String format) {
    return _validators[format];
  }
  
  /// Registers a custom validator
  static void registerValidator(String format, StringFormatValidator validator) {
    _validators[format] = validator;
  }
}