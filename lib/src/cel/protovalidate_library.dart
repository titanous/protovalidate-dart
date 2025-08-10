import 'package:cel/cel.dart';
import '../shared/string_validators.dart';

/// Refactored Protovalidate validation functions library for CEL
/// Uses the new parser-based validators for cleaner implementation
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
      
      // isEmail(string) -> bool
      Overload('isEmail', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isEmail(value.value));
        }
        return BooleanValue(false);
      }),
      
      // isHostname(string) -> bool
      Overload('isHostname', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isHostname(value.value));
        }
        return BooleanValue(false);
      }),
      
      // isIp(string) -> bool (any version)
      Overload('isIp', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isIp(value.value));
        }
        return BooleanValue(false);
      }),
      
      // isIp(string, int) -> bool (specific version)
      Overload('isIp', binaryOperator: (value, version) {
        if (value is StringValue && version is IntValue) {
          return BooleanValue(StringValidators.isIp(value.value, version.value.toInt()));
        }
        return BooleanValue(false);
      }),
      
      // isUri(string) -> bool
      Overload('isUri', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isUri(value.value));
        }
        return BooleanValue(false);
      }),
      
      // isUriRef(string) -> bool
      Overload('isUriRef', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isUriRef(value.value));
        }
        return BooleanValue(false);
      }),
      
      // isUuid(string) -> bool
      Overload('isUuid', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isUuid(value.value));
        }
        return BooleanValue(false);
      }),
      
      // isAddress(string) -> bool
      Overload('isAddress', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isAddress(value.value));
        }
        return BooleanValue(false);
      }),
      
      // isHostAndPort(string, bool) -> bool
      Overload('isHostAndPort', binaryOperator: (value, portRequired) {
        if (value is StringValue && portRequired is BooleanValue) {
          return BooleanValue(StringValidators.isHostAndPort(value.value, portRequired.value));
        }
        return BooleanValue(false);
      }),
      
      // IP prefix validation with multiple overloads
      
      // isIpPrefix(string) -> bool (any version, non-strict)
      Overload('isIpPrefix', unaryOperator: (value) {
        if (value is StringValue) {
          return BooleanValue(StringValidators.isIpPrefix(value.value));
        }
        return BooleanValue(false);
      }),
      
      // isIpPrefix(string, int) -> bool (specific version, non-strict)
      Overload('isIpPrefix', binaryOperator: (value, version) {
        if (value is StringValue && version is IntValue) {
          return BooleanValue(StringValidators.isIpPrefix(value.value, version.value.toInt()));
        }
        return BooleanValue(false);
      }),
      
      // isIpPrefix(string, bool) -> bool (any version, with strict mode)
      Overload('isIpPrefix:strict', binaryOperator: (value, strict) {
        if (value is StringValue && strict is BooleanValue) {
          return BooleanValue(StringValidators.isIpPrefix(value.value, null, strict.value));
        }
        return BooleanValue(false);
      }),
      
      // isIpPrefix(string, int, bool) -> bool (specific version with strict mode)
      Overload('isIpPrefix', functionOperator: (args) {
        if (args.length == 3 && 
            args[0] is StringValue && 
            args[1] is IntValue && 
            args[2] is BooleanValue) {
          final value = args[0] as StringValue;
          final version = args[1] as IntValue;
          final strict = args[2] as BooleanValue;
          return BooleanValue(StringValidators.isIpPrefix(
            value.value, 
            version.value.toInt(), 
            strict.value
          ));
        }
        return BooleanValue(false);
      }),
      
      // Numeric functions
      
      // isNan(double) -> bool
      Overload('isNan', unaryOperator: (value) {
        if (value is DoubleValue) {
          return BooleanValue(value.value.isNaN);
        }
        return BooleanValue(false);
      }),
      
      // isInf(double) -> bool (any infinity)
      Overload('isInf', unaryOperator: (value) {
        if (value is DoubleValue) {
          return BooleanValue(value.value.isInfinite);
        }
        return BooleanValue(false);
      }),
      
      // isInf(double, int) -> bool (specific sign)
      Overload('isInf', binaryOperator: (value, sign) {
        if (value is DoubleValue && sign is IntValue) {
          return BooleanValue(StringValidators.isInf(value.value, sign.value.toInt()));
        }
        return BooleanValue(false);
      }),
      
      // List functions
      
      // unique(list) -> bool
      Overload('unique', unaryOperator: (value) {
        if (value is ListValue) {
          return BooleanValue(StringValidators.unique(value.value));
        }
        return BooleanValue(false);
      }),
      
      // Bytes functions
      
      // bytesContains(bytes, bytes) -> bool
      Overload('bytesContains', binaryOperator: (bytes, sub) {
        if (bytes is BytesValue && sub is BytesValue) {
          return BooleanValue(StringValidators.bytesContains(bytes.value, sub.value));
        }
        return BooleanValue(false);
      }),
      
      // bytesStartsWith(bytes, bytes) -> bool
      Overload('bytesStartsWith', binaryOperator: (bytes, prefix) {
        if (bytes is BytesValue && prefix is BytesValue) {
          return BooleanValue(StringValidators.bytesStartsWith(bytes.value, prefix.value));
        }
        return BooleanValue(false);
      }),
      
      // bytesEndsWith(bytes, bytes) -> bool
      Overload('bytesEndsWith', binaryOperator: (bytes, suffix) {
        if (bytes is BytesValue && suffix is BytesValue) {
          return BooleanValue(StringValidators.bytesEndsWith(bytes.value, suffix.value));
        }
        return BooleanValue(false);
      }),
      
      // HTTP header validation
      
      // isHttpHeaderName(string, bool) -> bool
      Overload('isHttpHeaderName', binaryOperator: (value, strict) {
        if (value is StringValue && strict is BooleanValue) {
          return BooleanValue(StringValidators.isHttpHeaderName(value.value, strict.value));
        }
        return BooleanValue(false);
      }),
      
      // isHttpHeaderValue(string, bool) -> bool
      Overload('isHttpHeaderValue', binaryOperator: (value, strict) {
        if (value is StringValue && strict is BooleanValue) {
          return BooleanValue(StringValidators.isHttpHeaderValue(value.value, strict.value));
        }
        return BooleanValue(false);
      }),
    ];
  }
}