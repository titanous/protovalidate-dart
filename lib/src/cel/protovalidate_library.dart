import 'package:cel/cel.dart';
import '../shared/string_validators.dart';

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
          return BooleanValue(StringValidators.isValidEmail(value.value));
        }
        return BooleanValue(false);
      }),
      
      Overload('isHostname', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isValidHostname(value.value));
        }
        return BooleanValue(false);
      }),
      
      Overload('isIp', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isValidIP(value.value));
        }
        return BooleanValue(false);
      }),
      
      Overload('isIpv4', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isValidIPv4(value.value));
        }
        return BooleanValue(false);
      }),
      
      Overload('isIpv6', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isValidIPv6(value.value));
        }
        return BooleanValue(false);
      }),
      
      Overload('isUri', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isValidURI(value.value));
        }
        return BooleanValue(false);
      }),
      
      Overload('isUriRef', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isValidURIRef(value.value));
        }
        return BooleanValue(false);
      }),
      
      Overload('isUuid', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isValidUUID(value.value));
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
          return BooleanValue(StringValidators.isValidAddress(value.value));
        }
        return BooleanValue(false);
      }),
      
      // Host and port validation function
      Overload('isHostAndPort', binaryOperator: (value, portRequired) {
        if (value is StringValue && portRequired is BooleanValue) {
          return BooleanValue(StringValidators.isValidHostAndPort(value.value, portRequired: portRequired.value));
        }
        return BooleanValue(false);
      }),
      
      // IP prefix validation functions with multiple overloads
      // isIpPrefix(string) - any version, non-strict
      Overload('isIpPrefix', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isValidIPPrefix(value.value, version: null, strict: false));
        }
        return BooleanValue(false);
      }),
      
      // isIpPrefix(string, int) - specific version, non-strict
      Overload('isIpPrefix', binaryOperator: (value, version) {
        if (value is StringValue && version is IntValue) {
          return BooleanValue(StringValidators.isValidIPPrefix(value.value, version: version.value.toInt(), strict: false));
        }
        return BooleanValue(false);
      }),
      
      // isIpPrefix(string, bool) - any version, with strict mode
      Overload('isIpPrefix', binaryOperator: (value, strict) {
        if (value is StringValue && strict is BooleanValue) {
          return BooleanValue(StringValidators.isValidIPPrefix(value.value, version: null, strict: strict.value));
        }
        return BooleanValue(false);
      }),
      
      // isIpPrefix(string, int, bool) - specific version with strict mode
      Overload('isIpPrefix', functionOperator: (args) {
        if (args.length == 3 && args[0] is StringValue && args[1] is IntValue && args[2] is BooleanValue) {
          final value = args[0] as StringValue;
          final version = args[1] as IntValue;
          final strict = args[2] as BooleanValue;
          return BooleanValue(StringValidators.isValidIPPrefix(value.value, version: version.value.toInt(), strict: strict.value));
        }
        return BooleanValue(false);
      }),
      
      // IP with prefix length validation functions
      Overload('isIpv4WithPrefixLen', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isValidIPv4WithPrefixLen(value.value));
        }
        return BooleanValue(false);
      }),
      
      Overload('isIpv6WithPrefixLen', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isValidIPv6WithPrefixLen(value.value));
        }
        return BooleanValue(false);
      }),
      
      Overload('isIpWithPrefixLen', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(_isValidIpWithPrefixLen(value.value, null));
        }
        return BooleanValue(false);
      }),
      
      // Case-insensitive UUID validation (TUUID)
      Overload('isTuuid', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isValidTUUID(value.value));
        }
        return BooleanValue(false);
      }),
    ];
  }
  
  // Helper functions
  bool _isUnique(List<dynamic> list) {
    final seen = <String>{};
    for (final item in list) {
      final key = item.toString();
      if (seen.contains(key)) return false;
      seen.add(key);
    }
    return true;
  }
  
  bool _isValidIpWithPrefixLen(String value, int? version) {
    if (version == 4) return StringValidators.isValidIPv4WithPrefixLen(value);
    if (version == 6) return StringValidators.isValidIPv6WithPrefixLen(value);
    return StringValidators.isValidIPWithPrefixLen(value);
  }
}
