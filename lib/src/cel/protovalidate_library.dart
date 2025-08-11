import 'package:cel/cel.dart';
import 'package:cel/src/checker/declaration.dart';
import '../shared/string_validators.dart';

/// Refactored Protovalidate validation functions library for CEL
/// Uses the new parser-based validators for cleaner implementation
class ProtovalidateLibrary extends Library {
  @override
  List<ProgramOption> get programOptions => [
    functions(_createValidationOverloads()),
  ];

  @override
  List<EnvironmentOption> get compileEnvironmentOptions => [
    _declarations(_createFunctionDeclarations()),
  ];
  
  /// Returns an EnvironmentOption that appends the given declarations
  EnvironmentOption _declarations(List<Declaration> declarations) {
    return (Environment e) {
      e.declarations.addAll(declarations);
    };
  }
  
  /// Create function declarations for all our custom validation functions
  List<Declaration> _createFunctionDeclarations() {
    return [
      // String validation functions
      FunctionDeclaration(Overload('isEmail')),
      FunctionDeclaration(Overload('isHostname')),
      FunctionDeclaration(Overload('isIp')),
      FunctionDeclaration(Overload('isIpPrefix')),
      FunctionDeclaration(Overload('isUri')),
      FunctionDeclaration(Overload('isUriRef')),
      
      // Numeric functions
      FunctionDeclaration(Overload('isNan')),
      FunctionDeclaration(Overload('isInf')),
      
      // List functions
      FunctionDeclaration(Overload('unique')),
      
      // Bytes functions
      FunctionDeclaration(Overload('bytesContains')),
      FunctionDeclaration(Overload('bytesStartsWith')),
      FunctionDeclaration(Overload('bytesEndsWith')),
      
      // HTTP header validation
      FunctionDeclaration(Overload('isHttpHeaderName')),
      FunctionDeclaration(Overload('isHttpHeaderValue')),
    ];
  }

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
      
      // Use functionOperator to handle all isIp cases due to CEL-dart overload limitations  
      Overload('isIp', functionOperator: (args) {
        if (args.length == 1 && args[0] is StringValue) {
          // Unary: isIp(string)
          final value = args[0] as StringValue;
          return BooleanValue(StringValidators.isIp(value.value));
        }
        if (args.length == 2 && args[0] is StringValue && args[1] is IntValue) {
          // Binary: isIp(string, int)
          final value = args[0] as StringValue;
          final version = args[1] as IntValue;
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
      
      // Use functionOperator to handle all isIpPrefix cases due to CEL-dart overload limitations
      Overload('isIpPrefix', functionOperator: (args) {
        if (args.length == 1 && args[0] is StringValue) {
          // Unary: isIpPrefix(string)
          final value = args[0] as StringValue;
          return BooleanValue(StringValidators.isIpPrefix(value.value));
        }
        if (args.length == 2 && args[0] is StringValue) {
          final value = args[0] as StringValue;
          if (args[1] is IntValue) {
            // Binary: isIpPrefix(string, int)
            final version = args[1] as IntValue;
            return BooleanValue(StringValidators.isIpPrefix(value.value, version.value.toInt()));
          }
          if (args[1] is BooleanValue) {
            // Binary: isIpPrefix(string, bool)
            final strict = args[1] as BooleanValue;
            return BooleanValue(StringValidators.isIpPrefix(value.value, null, strict.value));
          }
        }
        if (args.length == 3 && 
            args[0] is StringValue && 
            args[1] is IntValue && 
            args[2] is BooleanValue) {
          // Ternary: isIpPrefix(string, int, bool)
          final value = args[0] as StringValue;
          final version = args[1] as IntValue;
          final strict = args[2] as BooleanValue;
          return BooleanValue(StringValidators.isIpPrefix(value.value, version.value.toInt(), strict.value));
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
      
      // Use functionOperator to handle all isInf cases due to CEL-dart overload limitations
      Overload('isInf', functionOperator: (args) {
        if (args.length == 1 && args[0] is DoubleValue) {
          // Unary: isInf(double)
          final value = args[0] as DoubleValue;
          return BooleanValue(value.value.isInfinite);
        }
        if (args.length == 2 && args[0] is DoubleValue && args[1] is IntValue) {
          // Binary: isInf(double, int)
          final value = args[0] as DoubleValue;
          final sign = args[1] as IntValue;
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