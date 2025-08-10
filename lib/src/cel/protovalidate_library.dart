import 'package:cel/cel.dart';

/// Protovalidate validation functions library for CEL
/// Implements all validation functions defined in the protovalidate specification
class ProtovalidateLibrary extends Library {
  @override
  List<ProgramOption> get programOptions => [
    functions(_createValidationOverloads()),
  ];

  @override
  List<EnvironmentOption> get compileEnvironmentOptions => [];

  List<Overload> _createValidationOverloads() {
    return [
      // String validation functions
      Overload('isEmail', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(_isValidEmail(value.value));
        }
        return BooleanValue(false);
      }),
      
      Overload('isHostname', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(_isValidHostname(value.value));
        }
        return BooleanValue(false);
      }),
      
      Overload('isIp', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(_isValidIp(value.value));
        }
        return BooleanValue(false);
      }),
      
      Overload('isIpv4', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(_isValidIpv4(value.value));
        }
        return BooleanValue(false);
      }),
      
      Overload('isIpv6', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(_isValidIpv6(value.value));
        }
        return BooleanValue(false);
      }),
      
      Overload('isUri', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(_isValidUri(value.value));
        }
        return BooleanValue(false);
      }),
      
      Overload('isUriRef', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(_isValidUriRef(value.value));
        }
        return BooleanValue(false);
      }),
      
      Overload('isUuid', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(_isValidUuid(value.value));
        }
        return BooleanValue(false);
      }),
      
      // List functions
      Overload('unique', unaryOperator: (value) {
        if (value is ListValue) {
          return BooleanValue(_isUnique(value.value));
        }
        return BooleanValue(false);
      }),
      
      // Numeric functions
      Overload('isNan', unaryOperator: (value) {
        if (value is DoubleValue) {
          return BooleanValue(value.value.isNaN);
        }
        return BooleanValue(false);
      }),
      
      Overload('isInf', unaryOperator: (value) {
        if (value is DoubleValue) {
          return BooleanValue(value.value.isInfinite);
        }
        return BooleanValue(false);
      }),
      
      // Binary version of isInf with sign parameter
      Overload('isInf', binaryOperator: (value, sign) {
        if (value is DoubleValue && sign is IntValue) {
          final isInf = value.value.isInfinite;
          if (!isInf) return BooleanValue(false);
          
          final signValue = sign.value.toInt();
          if (signValue == 0) return BooleanValue(true); // Any infinity
          if (signValue > 0) return BooleanValue(value.value.isInfinite && value.value > 0);
          if (signValue < 0) return BooleanValue(value.value.isInfinite && value.value < 0);
        }
        return BooleanValue(false);
      }),

      // Additional string format validation functions
      Overload('isAddress', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(_isValidAddress(value.value));
        }
        return BooleanValue(false);
      }),
    ];
  }

  // String validation implementations following protovalidate specifications
  bool _isValidEmail(String value) {
    if (value.isEmpty || value.length > 254) return false;
    
    // Basic email validation - more comprehensive than simple regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9]([a-zA-Z0-9._-]*[a-zA-Z0-9])?@[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$'
    );
    
    if (!emailRegex.hasMatch(value)) return false;
    
    // Check for valid local and domain parts
    final parts = value.split('@');
    if (parts.length != 2) return false;
    
    final local = parts[0];
    final domain = parts[1];
    
    // Local part validation
    if (local.isEmpty || local.length > 64) return false;
    if (local.startsWith('.') || local.endsWith('.')) return false;
    if (local.contains('..')) return false;
    
    // Domain part validation
    if (domain.isEmpty || domain.length > 253) return false;
    
    return _isValidHostname(domain);
  }

  bool _isValidHostname(String value) {
    if (value.isEmpty || value.length > 253) return false;
    if (value.endsWith('.')) {
      value = value.substring(0, value.length - 1);
    }
    
    // Split into labels
    final labels = value.split('.');
    if (labels.isEmpty) return false;
    
    for (final label in labels) {
      if (label.isEmpty || label.length > 63) return false;
      if (label.startsWith('-') || label.endsWith('-')) return false;
      
      // Check that label contains only valid characters
      final labelRegex = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$');
      if (!labelRegex.hasMatch(label)) return false;
    }
    
    return true;
  }

  bool _isValidIp(String value) {
    return _isValidIpv4(value) || _isValidIpv6(value);
  }

  bool _isValidIpv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    
    for (final part in parts) {
      if (part.isEmpty) return false;
      
      // No leading zeros unless it's just "0"
      if (part.length > 1 && part.startsWith('0')) return false;
      
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }

  bool _isValidIpv6(String value) {
    if (value.isEmpty) return false;
    
    // Handle IPv6 with embedded IPv4
    String ipv6Part = value;
    if (value.contains('.')) {
      final lastColon = value.lastIndexOf(':');
      if (lastColon == -1) return false;
      
      final ipv4Part = value.substring(lastColon + 1);
      if (!_isValidIpv4(ipv4Part)) return false;
      
      ipv6Part = value.substring(0, lastColon + 1) + '0:0';
    }
    
    // Handle :: notation
    final doubleColonCount = '::'.allMatches(ipv6Part).length;
    if (doubleColonCount > 1) return false;
    
    List<String> parts;
    if (doubleColonCount == 1) {
      final splitParts = ipv6Part.split('::');
      if (splitParts.length != 2) return false;
      
      final leftParts = splitParts[0].isEmpty ? <String>[] : splitParts[0].split(':');
      final rightParts = splitParts[1].isEmpty ? <String>[] : splitParts[1].split(':');
      
      final totalParts = leftParts.length + rightParts.length;
      if (totalParts > 8) return false;
      
      parts = List<String>.from(leftParts);
      for (int i = 0; i < 8 - totalParts; i++) {
        parts.add('0');
      }
      parts.addAll(rightParts);
    } else {
      parts = ipv6Part.split(':');
      if (parts.length != 8) return false;
    }
    
    // Validate each part
    for (final part in parts) {
      if (part.isEmpty && doubleColonCount == 0) return false;
      if (part.length > 4) return false;
      
      if (part.isNotEmpty) {
        final hexRegex = RegExp(r'^[0-9a-fA-F]+$');
        if (!hexRegex.hasMatch(part)) return false;
      }
    }
    
    return true;
  }

  bool _isValidUri(String value) {
    try {
      final uri = Uri.parse(value);
      return uri.hasScheme && uri.scheme.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  bool _isValidUriRef(String value) {
    try {
      Uri.parse(value);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _isValidUuid(String value) {
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$', caseSensitive: false);
    return uuidRegex.hasMatch(value);
  }

  bool _isValidAddress(String value) {
    // Address validation - can be IP or hostname
    return _isValidIp(value) || _isValidHostname(value);
  }

  bool _isUnique(List<dynamic> list) {
    final seen = <dynamic>{};
    for (final item in list) {
      if (seen.contains(item)) {
        return false;
      }
      seen.add(item);
    }
    return true;
  }
}