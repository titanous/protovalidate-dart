import 'dart:convert';
import 'package:fixnum/fixnum.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart' as pb;
import 'package:protovalidate/src/gen/google/protobuf/descriptor.pbenum.dart';
import '../cursor.dart';
import '../evaluator.dart';
import '../error.dart';
import '../rule_paths.dart';
import '../shared/string_validators.dart';

/// Evaluator for boolean field rules.
class BoolEvaluator implements Evaluator {
  final bool? constValue;
  
  BoolEvaluator({this.constValue});
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value is! bool) {
      cursor.violate(
        message: 'Expected bool, got ${value.runtimeType}',
        constraintId: 'bool.type',
      );
      return;
    }
    
    if (constValue != null && value != constValue) {
      cursor.violate(
        message: '',  // Empty message to match expected output
        constraintId: 'bool.const',
        rulePath: RulePathBuilder.boolConstraint('const'),
      );
    }
  }
}

/// Base evaluator for numeric field rules.
abstract class NumericEvaluator<T extends Comparable> implements Evaluator {
  final T? constValue;
  final T? lt;
  final T? lte;
  final T? gt;
  final T? gte;
  final List<T>? inValues;
  final List<T>? notInValues;
  
  NumericEvaluator({
    this.constValue,
    this.lt,
    this.lte,
    this.gt,
    this.gte,
    this.inValues,
    this.notInValues,
  });
  
  String get typeName;
  String get constraintPrefix;
  int get ruleFieldNumber;
  
  bool isValidType(dynamic value);
  T toTypedValue(dynamic value);
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (!isValidType(value)) {
      cursor.violate(
        message: '',
        constraintId: '$constraintPrefix.type',
      );
      return;
    }
    
    final typedValue = toTypedValue(value);
    
    // Check const first
    if (constValue != null && typedValue != constValue) {
      cursor.violate(
        message: 'value must equal $constValue',
        constraintId: '$constraintPrefix.const',
        rulePath: RulePathBuilder.numericConstraint(constraintPrefix, ruleFieldNumber, 'const'),
      );
      return; // If const fails, don't check other rules
    }
    
    // Check in/not_in
    if (inValues != null && !inValues!.contains(typedValue)) {
      cursor.violate(
        message: 'value must be in list $inValues',
        constraintId: '$constraintPrefix.in',
        rulePath: RulePathBuilder.numericConstraint(constraintPrefix, ruleFieldNumber, 'in'),
      );
      return;
    }
    
    if (notInValues != null && notInValues!.contains(typedValue)) {
      cursor.violate(
        message: '',
        constraintId: '$constraintPrefix.not_in',
        rulePath: RulePathBuilder.numericConstraint(constraintPrefix, ruleFieldNumber, 'not_in'),
      );
      return;
    }
    
    // Handle range constraints with proper combination logic
    _evaluateRangeConstraints(typedValue, cursor);
  }
  
  void _evaluateRangeConstraints(T typedValue, Cursor cursor) {
    // Determine if we have contradictory ranges (exclusive logic)
    bool hasExclusiveRange = _hasExclusiveRange();
    
    if (hasExclusiveRange) {
      _evaluateExclusiveRange(typedValue, cursor);
    } else {
      _evaluateInclusiveRange(typedValue, cursor);
    }
  }
  
  bool _hasExclusiveRange() {
    // Check for contradictory constraints that create exclusive ranges:
    // gt > lt (e.g., gt: 10, lt: 0) - value must be > 10 OR < 0
    // gte > lte (e.g., gte: 256, lte: 128) - value must be >= 256 OR <= 128
    
    if (gt != null && lt != null && gt!.compareTo(lt!) >= 0) {
      return true;
    }
    
    if (gte != null && lte != null && gte!.compareTo(lte!) > 0) {
      return true;
    }
    
    return false;
  }
  
  void _evaluateExclusiveRange(T typedValue, Cursor cursor) {
    // For exclusive ranges, the value is valid if it satisfies ANY constraint
    bool valid = false;
    String? primaryConstraint;
    String? fieldName;
    
    if (gt != null && lt != null && gt!.compareTo(lt!) >= 0) {
      // Exclusive gt_lt: value must be > gt OR < lt
      valid = typedValue.compareTo(gt!) > 0 || typedValue.compareTo(lt!) < 0;
      primaryConstraint = 'gt_lt_exclusive';
      fieldName = 'gt';
    } else if (gte != null && lte != null && gte!.compareTo(lte!) > 0) {
      // Exclusive gte_lte: value must be >= gte OR <= lte  
      valid = typedValue.compareTo(gte!) >= 0 || typedValue.compareTo(lte!) <= 0;
      primaryConstraint = 'gte_lte_exclusive';
      fieldName = 'gte';
    }
    
    if (!valid && primaryConstraint != null && fieldName != null) {
      cursor.violate(
        message: '',
        constraintId: '$constraintPrefix.$primaryConstraint',
        rulePath: RulePathBuilder.numericConstraint(constraintPrefix, ruleFieldNumber, fieldName),
      );
    }
  }
  
  void _evaluateInclusiveRange(T typedValue, Cursor cursor) {
    // For inclusive ranges, check each constraint individually
    
    // Combined gt_lt (inclusive range): must satisfy BOTH gt AND lt
    if (gt != null && lt != null && gt!.compareTo(lt!) < 0) {
      // This is an inclusive range (e.g., gt: 0, lt: 10)
      if (!(typedValue.compareTo(gt!) > 0 && typedValue.compareTo(lt!) < 0)) {
        // Violates the combined constraint - report the field that was violated
        // If value <= gt, it violates the "gt" constraint
        // If value >= lt, it violates the "lt" constraint (value is above the range)
        if (typedValue.compareTo(lt!) >= 0) {
          // Value is above the range, report 'gt' as per expected output
          cursor.violate(
            message: '',
            constraintId: '$constraintPrefix.gt_lt',
            rulePath: RulePathBuilder.numericConstraint(constraintPrefix, ruleFieldNumber, 'gt'),
          );
        } else {
          // Value is below the range
          cursor.violate(
            message: '',
            constraintId: '$constraintPrefix.gt_lt',
            rulePath: RulePathBuilder.numericConstraint(constraintPrefix, ruleFieldNumber, 'gt'),
          );
        }
        return;
      }
    }
    
    // Combined gte_lte (inclusive range): must satisfy BOTH gte AND lte
    if (gte != null && lte != null && gte!.compareTo(lte!) <= 0) {
      // This is an inclusive range (e.g., gte: 128, lte: 256)
      if (!(typedValue.compareTo(gte!) >= 0 && typedValue.compareTo(lte!) <= 0)) {
        // Violates the combined constraint - report the field that was violated
        // If value > lte, it violates the range (above the range), report 'gte'
        // If value < gte, it violates the range (below the range), report 'gte'
        if (typedValue.compareTo(lte!) > 0) {
          // Value is above the range, report 'gte' as per expected output
          cursor.violate(
            message: '',
            constraintId: '$constraintPrefix.gte_lte',
            rulePath: RulePathBuilder.numericConstraint(constraintPrefix, ruleFieldNumber, 'gte'),
          );
        } else {
          // Value is below the range
          cursor.violate(
            message: '',
            constraintId: '$constraintPrefix.gte_lte',
            rulePath: RulePathBuilder.numericConstraint(constraintPrefix, ruleFieldNumber, 'gte'),
          );
        }
        return;
      }
    }
    
    // Individual constraint checks (when not part of a range)
    if (lt != null && gt == null && typedValue.compareTo(lt!) >= 0) {
      cursor.violate(
        message: '',
        constraintId: '$constraintPrefix.lt',
        rulePath: RulePathBuilder.numericConstraint(constraintPrefix, ruleFieldNumber, 'lt'),
      );
    }
    
    if (lte != null && gte == null && typedValue.compareTo(lte!) > 0) {
      cursor.violate(
        message: '',
        constraintId: '$constraintPrefix.lte',
        rulePath: RulePathBuilder.numericConstraint(constraintPrefix, ruleFieldNumber, 'lte'),
      );
    }
    
    if (gt != null && lt == null && typedValue.compareTo(gt!) <= 0) {
      cursor.violate(
        message: '',
        constraintId: '$constraintPrefix.gt',
        rulePath: RulePathBuilder.numericConstraint(constraintPrefix, ruleFieldNumber, 'gt'),
      );
    }
    
    if (gte != null && lte == null && typedValue.compareTo(gte!) < 0) {
      cursor.violate(
        message: '',
        constraintId: '$constraintPrefix.gte',
        rulePath: RulePathBuilder.numericConstraint(constraintPrefix, ruleFieldNumber, 'gte'),
      );
    }
  }
  
  List<pb.FieldPathElement> _buildRulePath(String fieldName, int fieldNumber) {
    return [
      pb.FieldPathElement()
        ..fieldNumber = ruleFieldNumber
        ..fieldName = constraintPrefix
        ..fieldType = FieldDescriptorProto_Type.TYPE_MESSAGE,
      pb.FieldPathElement()
        ..fieldNumber = fieldNumber
        ..fieldName = fieldName
        ..fieldType = _getFieldTypeFromName(fieldName),
    ];
  }
  
  FieldDescriptorProto_Type _getFieldTypeFromName(String fieldName) {
    // Return the appropriate type based on the field name
    switch (fieldName) {
      case 'finite':
        return FieldDescriptorProto_Type.TYPE_BOOL;
      case 'const':
      case 'lt':
      case 'lte':
      case 'gt':
      case 'gte':
        // Return the appropriate type based on the constraint prefix
        switch (constraintPrefix) {
          case 'float':
            return FieldDescriptorProto_Type.TYPE_FLOAT;
          case 'double':
            return FieldDescriptorProto_Type.TYPE_DOUBLE;
          case 'int32':
            return FieldDescriptorProto_Type.TYPE_INT32;
          case 'int64':
            return FieldDescriptorProto_Type.TYPE_INT64;
          case 'uint32':
            return FieldDescriptorProto_Type.TYPE_UINT32;
          case 'uint64':
            return FieldDescriptorProto_Type.TYPE_UINT64;
          default:
            return FieldDescriptorProto_Type.TYPE_INT32;
        }
      case 'in':
      case 'not_in':
        // Return the same type as the constraint prefix for the element type
        switch (constraintPrefix) {
          case 'float':
            return FieldDescriptorProto_Type.TYPE_FLOAT;
          case 'double':
            return FieldDescriptorProto_Type.TYPE_DOUBLE;
          case 'int32':
            return FieldDescriptorProto_Type.TYPE_INT32;
          case 'int64':
            return FieldDescriptorProto_Type.TYPE_INT64;
          case 'uint32':
            return FieldDescriptorProto_Type.TYPE_UINT32;
          case 'uint64':
            return FieldDescriptorProto_Type.TYPE_UINT64;
          case 'string':
            return FieldDescriptorProto_Type.TYPE_STRING;
          case 'bytes':
            return FieldDescriptorProto_Type.TYPE_BYTES;
          default:
            return FieldDescriptorProto_Type.TYPE_INT32;
        }
      default:
        return FieldDescriptorProto_Type.TYPE_INT32;
    }
  }
  
  String _getFieldNameFromNumber(int fieldNumber) {
    switch (fieldNumber) {
      case 1: return 'const';
      case 2: return 'lt';
      case 3: return 'lte';
      case 4: return 'gt';
      case 5: return 'gte';
      case 6: return 'in';
      case 7: return 'not_in';
      default: return 'unknown';
    }
  }
}

/// Evaluator for int32 field rules.
class Int32Evaluator extends NumericEvaluator<int> {
  Int32Evaluator({
    super.constValue,
    super.lt,
    super.lte,
    super.gt,
    super.gte,
    super.inValues,
    super.notInValues,
  });
  
  @override
  String get typeName => 'int32';
  
  @override
  String get constraintPrefix => 'int32';
  
  @override
  int get ruleFieldNumber => 3; // int32 field number in validate.proto
  
  @override
  bool isValidType(dynamic value) => value is int;
  
  @override
  int toTypedValue(dynamic value) => value as int;
}

/// Evaluator for int64 field rules.
class Int64Evaluator extends NumericEvaluator<Int64> {
  Int64Evaluator({
    Int64? constValue,
    Int64? lt,
    Int64? lte,
    Int64? gt,
    Int64? gte,
    List<Int64>? inValues,
    List<Int64>? notInValues,
  }) : super(
    constValue: constValue,
    lt: lt,
    lte: lte,
    gt: gt,
    gte: gte,
    inValues: inValues,
    notInValues: notInValues,
  );
  
  @override
  String get typeName => 'int64';
  
  @override
  String get constraintPrefix => 'int64';
  
  @override
  int get ruleFieldNumber => 4;
  
  @override
  bool isValidType(dynamic value) => value is Int64;
  
  @override
  Int64 toTypedValue(dynamic value) => value as Int64;
}

/// Evaluator for uint32 field rules.
class UInt32Evaluator extends NumericEvaluator<int> {
  UInt32Evaluator({
    super.constValue,
    super.lt,
    super.lte,
    super.gt,
    super.gte,
    super.inValues,
    super.notInValues,
  });
  
  @override
  String get typeName => 'uint32';
  
  @override
  String get constraintPrefix => 'uint32';
  
  @override
  int get ruleFieldNumber => 5;
  
  @override
  bool isValidType(dynamic value) => value is int && value >= 0;
  
  @override
  int toTypedValue(dynamic value) => value as int;
}

/// Evaluator for uint64 field rules.
class UInt64Evaluator extends NumericEvaluator<Int64> {
  UInt64Evaluator({
    Int64? constValue,
    Int64? lt,
    Int64? lte,
    Int64? gt,
    Int64? gte,
    List<Int64>? inValues,
    List<Int64>? notInValues,
  }) : super(
    constValue: constValue,
    lt: lt,
    lte: lte,
    gt: gt,
    gte: gte,
    inValues: inValues,
    notInValues: notInValues,
  );
  
  @override
  String get typeName => 'uint64';
  
  @override
  String get constraintPrefix => 'uint64';
  
  @override
  int get ruleFieldNumber => 6;
  
  @override
  bool isValidType(dynamic value) => value is Int64 && !value.isNegative;
  
  @override
  Int64 toTypedValue(dynamic value) => value as Int64;
}

/// Evaluator for float field rules.
class FloatEvaluator extends NumericEvaluator<double> {
  final bool? finite;
  
  FloatEvaluator({
    super.constValue,
    super.lt,
    super.lte,
    super.gt,
    super.gte,
    super.inValues,
    super.notInValues,
    this.finite,
  });
  
  @override
  String get typeName => 'float';
  
  @override
  String get constraintPrefix => 'float';
  
  @override
  int get ruleFieldNumber => 1;
  
  @override
  bool isValidType(dynamic value) => value is double;
  
  @override
  double toTypedValue(dynamic value) => value as double;
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (!isValidType(value)) {
      cursor.violate(
        message: '',
        constraintId: '$constraintPrefix.type',
      );
      return;
    }
    
    final floatValue = value as double;
    
    // Handle NaN specially - NaN should fail all comparison constraints
    if (floatValue.isNaN) {
      // Check for combined constraints first (ranges)
      if (gt != null && lt != null) {
        if (gt! >= lt!) {
          cursor.violate(
            message: '',
            constraintId: 'float.gt_lt_exclusive',
            rulePath: RulePathBuilder.numericConstraint('float', 1, 'gt'),
          );
        } else {
          cursor.violate(
            message: '',
            constraintId: 'float.gt_lt',
            rulePath: RulePathBuilder.numericConstraint('float', 1, 'gt'),
          );
        }
        return;
      }
      if (gte != null && lte != null) {
        if (gte! > lte!) {
          cursor.violate(
            message: '',
            constraintId: 'float.gte_lte_exclusive',
            rulePath: RulePathBuilder.numericConstraint('float', 1, 'gte'),
          );
        } else {
          cursor.violate(
            message: '',
            constraintId: 'float.gte_lte',
            rulePath: RulePathBuilder.numericConstraint('float', 1, 'gte'),
          );
        }
        return;
      }
      
      // Individual constraint checks (when not part of a range)
      if (gt != null) {
        cursor.violate(
          message: '',
          constraintId: 'float.gt',
          rulePath: RulePathBuilder.numericConstraint('float', 1, 'gt'),
        );
        return;
      }
      if (gte != null) {
        cursor.violate(
          message: '',
          constraintId: 'float.gte',
          rulePath: RulePathBuilder.numericConstraint('float', 1, 'gte'),
        );
        return;
      }
      if (lt != null) {
        cursor.violate(
          message: '',
          constraintId: 'float.lt',
          rulePath: RulePathBuilder.numericConstraint('float', 1, 'lt'),
        );
        return;
      }
      if (lte != null) {
        cursor.violate(
          message: '',
          constraintId: 'float.lte',
          rulePath: RulePathBuilder.numericConstraint('float', 1, 'lte'),
        );
        return;
      }
    }
    
    // For non-NaN values, use the base implementation
    super.evaluate(value, cursor);
    
    // Check finite
    if (finite == true && !floatValue.isFinite) {
      cursor.violate(
        message: 'value must be finite',
        constraintId: 'float.finite',
        rulePath: RulePathBuilder.numericConstraint('float', 1, 'finite'),
      );
    }
  }
}

/// Evaluator for double field rules.
class DoubleEvaluator extends NumericEvaluator<double> {
  final bool? finite;
  
  DoubleEvaluator({
    super.constValue,
    super.lt,
    super.lte,
    super.gt,
    super.gte,
    super.inValues,
    super.notInValues,
    this.finite,
  });
  
  @override
  String get typeName => 'double';
  
  @override
  String get constraintPrefix => 'double';
  
  @override
  int get ruleFieldNumber => 2;
  
  @override
  bool isValidType(dynamic value) => value is double;
  
  @override
  double toTypedValue(dynamic value) => value as double;
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (!isValidType(value)) {
      cursor.violate(
        message: '',
        constraintId: '$constraintPrefix.type',
      );
      return;
    }
    
    final doubleValue = value as double;
    
    // Handle NaN specially - NaN should fail all comparison constraints
    if (doubleValue.isNaN) {
      // Check for combined constraints first (ranges)
      if (gt != null && lt != null) {
        if (gt! >= lt!) {
          cursor.violate(
            message: '',
            constraintId: 'double.gt_lt_exclusive',
            rulePath: RulePathBuilder.numericConstraint('double', 2, 'gt'),
          );
        } else {
          cursor.violate(
            message: '',
            constraintId: 'double.gt_lt',
            rulePath: RulePathBuilder.numericConstraint('double', 2, 'gt'),
          );
        }
        return;
      }
      if (gte != null && lte != null) {
        if (gte! > lte!) {
          cursor.violate(
            message: '',
            constraintId: 'double.gte_lte_exclusive',
            rulePath: RulePathBuilder.numericConstraint('double', 2, 'gte'),
          );
        } else {
          cursor.violate(
            message: '',
            constraintId: 'double.gte_lte',
            rulePath: RulePathBuilder.numericConstraint('double', 2, 'gte'),
          );
        }
        return;
      }
      
      // Individual constraint checks (when not part of a range)
      if (gt != null) {
        cursor.violate(
          message: '',
          constraintId: 'double.gt',
          rulePath: RulePathBuilder.numericConstraint('double', 2, 'gt'),
        );
        return;
      }
      if (gte != null) {
        cursor.violate(
          message: '',
          constraintId: 'double.gte',
          rulePath: RulePathBuilder.numericConstraint('double', 2, 'gte'),
        );
        return;
      }
      if (lt != null) {
        cursor.violate(
          message: '',
          constraintId: 'double.lt',
          rulePath: RulePathBuilder.numericConstraint('double', 2, 'lt'),
        );
        return;
      }
      if (lte != null) {
        cursor.violate(
          message: '',
          constraintId: 'double.lte',
          rulePath: RulePathBuilder.numericConstraint('double', 2, 'lte'),
        );
        return;
      }
    }
    
    // For non-NaN values, use the base implementation
    super.evaluate(value, cursor);
    
    // Check finite
    if (finite == true && !doubleValue.isFinite) {
      cursor.violate(
        message: 'value must be finite',
        constraintId: 'double.finite',
        rulePath: RulePathBuilder.numericConstraint('double', 2, 'finite'),
      );
    }
  }
}

/// Evaluator for string field rules.
class StringRulesEvaluator implements Evaluator {
  final String? constValue;
  final int? len;
  final int? lenBytes;
  final int? minLen;
  final int? maxLen;
  final int? minBytes;
  final int? maxBytes;
  final String? pattern;
  final String? prefix;
  final String? suffix;
  final String? contains;
  final String? notContains;
  final List<String>? inValues;
  final List<String>? notInValues;
  
  // Format validators
  final bool? email;
  final bool? hostname;
  final bool? ip;
  final bool? ipv4;
  final bool? ipv6;
  final bool? uri;
  final bool? uriRef;
  final bool? address;
  final bool? uuid;
  final bool? ipPrefix;
  final bool? ipv4Prefix;
  final bool? ipv6Prefix;
  final pb.KnownRegex? wellKnownRegex;
  final bool? strict;
  final bool? ipWithPrefixlen;
  final bool? ipv4WithPrefixlen;
  final bool? ipv6WithPrefixlen;
  final bool? tuuid;
  final bool? hostAndPort;
  
  // Cached compiled pattern
  RegExp? _compiledPattern;
  
  /// Compiles a regex pattern, handling PCRE-style flags like (?i)
  static RegExp? _compilePattern(String pattern) {
    // Handle case-insensitive flag (?i) at the beginning
    if (pattern.startsWith('(?i)')) {
      final cleanPattern = pattern.substring(4); // Remove (?i)
      return RegExp(cleanPattern, caseSensitive: false);
    }
    return RegExp(pattern);
  }
  
  StringRulesEvaluator({
    this.constValue,
    this.len,
    this.lenBytes,
    this.minLen,
    this.maxLen,
    this.minBytes,
    this.maxBytes,
    this.pattern,
    this.prefix,
    this.suffix,
    this.contains,
    this.notContains,
    this.inValues,
    this.notInValues,
    this.email,
    this.hostname,
    this.ip,
    this.ipv4,
    this.ipv6,
    this.uri,
    this.uriRef,
    this.address,
    this.uuid,
    this.ipPrefix,
    this.ipv4Prefix,
    this.ipv6Prefix,
    this.wellKnownRegex,
    this.strict,
    this.ipWithPrefixlen,
    this.ipv4WithPrefixlen,
    this.ipv6WithPrefixlen,
    this.tuuid,
    this.hostAndPort,
  }) {
    // Compile pattern once during construction
    if (pattern != null) {
      try {
        _compiledPattern = _compilePattern(pattern!);
      } catch (e) {
        // Pattern compilation error will be caught during validation
      }
    }
  }
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value is! String) {
      cursor.violate(
        message: 'Expected string, got ${value.runtimeType}',
        constraintId: 'string.type',
      );
      return;
    }
    
    final stringValue = value;
    
    // Check const
    if (constValue != null && stringValue != constValue) {
      cursor.violate(
        message: 'value must equal `$constValue`',
        constraintId: 'string.const',
        rulePath: RulePathBuilder.stringConstraint('const'),
      );
    }
    
    // Check exact length (count runes, not UTF-16 code units)
    final runeLength = stringValue.runes.length;
    if (len != null && runeLength != len) {
      cursor.violate(
        message: 'value length must be $len characters',
        constraintId: 'string.len',
        rulePath: RulePathBuilder.stringConstraint('len'),
      );
    }
    
    // Check exact byte length (UTF-8 bytes)
    if (lenBytes != null) {
      final utf8ByteLength = utf8.encode(stringValue).length;
      if (utf8ByteLength != lenBytes) {
        cursor.violate(
          message: 'value length must be $lenBytes bytes',
          constraintId: 'string.len_bytes',
          rulePath: RulePathBuilder.stringConstraint('len_bytes'),
        );
      }
    }
    
    // Check min length (count runes, not UTF-16 code units)
    if (minLen != null && stringValue.runes.length < minLen!) {
      cursor.violate(
        message: 'value length must be at least $minLen characters',
        constraintId: 'string.min_len',
        rulePath: RulePathBuilder.stringConstraint('min_len'),
      );
    }
    
    // Check max length (count runes, not UTF-16 code units)
    if (maxLen != null && stringValue.runes.length > maxLen!) {
      cursor.violate(
        message: 'value length must be at most $maxLen characters',
        constraintId: 'string.max_len',
        rulePath: RulePathBuilder.stringConstraint('max_len'),
      );
    }
    
    // Check min bytes
    if (minBytes != null) {
      final utf8ByteLength = utf8.encode(stringValue).length;
      if (utf8ByteLength < minBytes!) {
        cursor.violate(
          message: '',
          constraintId: 'string.min_bytes',
          rulePath: RulePathBuilder.stringConstraint('min_bytes'),
        );
      }
    }
    
    // Check max bytes
    if (maxBytes != null) {
      final utf8ByteLength = utf8.encode(stringValue).length;
      if (utf8ByteLength > maxBytes!) {
        cursor.violate(
          message: '',
          constraintId: 'string.max_bytes',
          rulePath: RulePathBuilder.stringConstraint('max_bytes'),
        );
      }
    }
    
    // Check pattern
    if (pattern != null) {
      if (_compiledPattern == null) {
        cursor.violate(
          message: 'Invalid regex pattern: $pattern',
          constraintId: 'string.pattern.compile_error',
        );
      } else if (!_compiledPattern!.hasMatch(stringValue)) {
        cursor.violate(
          message: 'String must match pattern: $pattern',
          constraintId: 'string.pattern',
          rulePath: RulePathBuilder.stringConstraint('pattern'),
        );
      }
    }
    
    // Check prefix
    if (prefix != null && !stringValue.startsWith(prefix!)) {
      cursor.violate(
        message: '',
        constraintId: 'string.prefix',
        rulePath: RulePathBuilder.stringConstraint('prefix'),
      );
    }
    
    // Check suffix
    if (suffix != null && !stringValue.endsWith(suffix!)) {
      cursor.violate(
        message: '',
        constraintId: 'string.suffix',
        rulePath: RulePathBuilder.stringConstraint('suffix'),
      );
    }
    
    // Check contains
    if (contains != null && !stringValue.contains(contains!)) {
      cursor.violate(
        message: '',
        constraintId: 'string.contains',
        rulePath: RulePathBuilder.stringConstraint('contains'),
      );
    }
    
    // Check not_contains
    if (notContains != null && stringValue.contains(notContains!)) {
      cursor.violate(
        message: '',
        constraintId: 'string.not_contains',
        rulePath: RulePathBuilder.stringConstraint('not_contains'),
      );
    }
    
    // Check in
    if (inValues != null && !inValues!.contains(stringValue)) {
      cursor.violate(
        message: 'value must be in list [${inValues!.join(", ")}]',
        constraintId: 'string.in',
        rulePath: RulePathBuilder.stringConstraint('in'),
      );
    }
    
    // Check not_in
    if (notInValues != null && notInValues!.contains(stringValue)) {
      cursor.violate(
        message: 'value must not be in list [${notInValues!.join(", ")}]',
        constraintId: 'string.not_in',
        rulePath: RulePathBuilder.stringConstraint('not_in'),
      );
    }
    
    // Format validators
    _validateFormats(stringValue, cursor);
  }
  
  void _validateFormats(String value, Cursor cursor) {
    // Email validation
    if (email == true) {
      if (value.isEmpty) {
        cursor.violate(
          message: '',
          constraintId: 'string.email_empty',
          rulePath: RulePathBuilder.stringConstraint('email'),
        );
      } else if (!_isValidEmail(value)) {
        cursor.violate(
          message: 'String must be a valid email address',
          constraintId: 'string.email',
          rulePath: RulePathBuilder.stringConstraint('email'),
        );
      }
    }
    
    // Hostname validation
    if (hostname == true) {
      if (value.isEmpty) {
        cursor.violate(
          message: '',
          constraintId: 'string.hostname_empty',
          rulePath: RulePathBuilder.stringConstraint('hostname'),
        );
      } else if (!_isValidHostname(value)) {
        cursor.violate(
          message: 'String must be a valid hostname',
          constraintId: 'string.hostname',
          rulePath: RulePathBuilder.stringConstraint('hostname'),
        );
      }
    }
    
    // IP validation (v4 or v6)
    if (ip == true) {
      if (value.isEmpty) {
        cursor.violate(
          message: 'value is empty, which is not a valid IP address',
          constraintId: 'string.ip_empty',
          rulePath: RulePathBuilder.stringConstraint('ip'),
        );
      } else if (!_isValidIP(value)) {
        cursor.violate(
          message: 'String must be a valid IP address',
          constraintId: 'string.ip',
          rulePath: RulePathBuilder.stringConstraint('ip'),
        );
      }
    }
    
    // IPv4 validation
    if (ipv4 == true) {
      if (value.isEmpty) {
        cursor.violate(
          message: 'value is empty, which is not a valid IPv4 address',
          constraintId: 'string.ipv4_empty',
          rulePath: RulePathBuilder.stringConstraint('ipv4'),
        );
      } else if (!_isValidIPv4(value)) {
        cursor.violate(
          message: 'String must be a valid IPv4 address',
          constraintId: 'string.ipv4',
          rulePath: RulePathBuilder.stringConstraint('ipv4'),
        );
      }
    }
    
    // IPv6 validation
    if (ipv6 == true) {
      if (value.isEmpty) {
        cursor.violate(
          message: 'value is empty, which is not a valid IPv6 address',
          constraintId: 'string.ipv6_empty',
          rulePath: RulePathBuilder.stringConstraint('ipv6'),
        );
      } else if (!_isValidIPv6(value)) {
        cursor.violate(
          message: 'String must be a valid IPv6 address',
          constraintId: 'string.ipv6',
          rulePath: RulePathBuilder.stringConstraint('ipv6'),
        );
      }
    }
    
    // URI validation
    if (uri == true) {
      if (value.isEmpty) {
        cursor.violate(
          message: '',
          constraintId: 'string.uri_empty',
          rulePath: RulePathBuilder.stringConstraint('uri'),
        );
      } else if (!_isValidURI(value)) {
        cursor.violate(
          message: '',
          constraintId: 'string.uri',
          rulePath: RulePathBuilder.stringConstraint('uri'),
        );
      }
    }
    
    // URI reference validation
    if (uriRef == true && !_isValidURIRef(value)) {
      cursor.violate(
        message: 'String must be a valid URI reference',
        constraintId: 'string.uri_ref',
        rulePath: RulePathBuilder.stringConstraint('uri_ref'),
      );
    }
    
    // UUID validation
    if (uuid == true) {
      if (value.isEmpty) {
        cursor.violate(
          message: '',
          constraintId: 'string.uuid_empty',
          rulePath: RulePathBuilder.stringConstraint('uuid'),
        );
      } else if (!_isValidUUID(value)) {
        cursor.violate(
          message: '',
          constraintId: 'string.uuid',
          rulePath: RulePathBuilder.stringConstraint('uuid'),
        );
      }
    }
    
    // Address validation (IP or hostname)
    if (address == true) {
      if (value.isEmpty) {
        cursor.violate(
          message: 'value is empty, which is not a valid hostname or IP address',
          constraintId: 'string.address_empty',
          rulePath: RulePathBuilder.stringConstraint('address'),
        );
      } else if (!_isValidAddress(value)) {
        cursor.violate(
          message: 'value must be a valid hostname or IP address',
          constraintId: 'string.address',
          rulePath: RulePathBuilder.stringConstraint('address'),
        );
      }
    }
    
    // IP prefix validation (any version)
    if (ipPrefix == true) {
      if (value.isEmpty) {
        cursor.violate(
          message: '',
          constraintId: 'string.ip_prefix_empty',
          rulePath: RulePathBuilder.stringConstraint('ip_prefix'),
        );
      } else if (!_isValidIPPrefix(value)) {
        cursor.violate(
          message: 'String must be a valid IP prefix',
          constraintId: 'string.ip_prefix',
          rulePath: RulePathBuilder.stringConstraint('ip_prefix'),
        );
      }
    }
    
    // IPv4 prefix validation
    if (ipv4Prefix == true) {
      if (value.isEmpty) {
        cursor.violate(
          message: '',
          constraintId: 'string.ipv4_prefix_empty',
          rulePath: RulePathBuilder.stringConstraint('ipv4_prefix'),
        );
      } else if (!_isValidIPv4Prefix(value)) {
        cursor.violate(
          message: '',
          constraintId: 'string.ipv4_prefix',
          rulePath: RulePathBuilder.stringConstraint('ipv4_prefix'),
        );
      }
    }
    
    // IPv6 prefix validation
    if (ipv6Prefix == true) {
      if (value.isEmpty) {
        cursor.violate(
          message: '',
          constraintId: 'string.ipv6_prefix_empty',
          rulePath: RulePathBuilder.stringConstraint('ipv6_prefix'),
        );
      } else if (!_isValidIPv6Prefix(value)) {
        cursor.violate(
          message: '',
          constraintId: 'string.ipv6_prefix',
          rulePath: RulePathBuilder.stringConstraint('ipv6_prefix'),
        );
      }
    }
    
    // IP with prefix length validation
    if (ipWithPrefixlen == true) {
      if (value.isEmpty) {
        cursor.violate(
          message: 'value is empty, which is not a valid IP with prefix length',
          constraintId: 'string.ip_with_prefixlen_empty',
          rulePath: RulePathBuilder.stringConstraint('ip_with_prefixlen'),
        );
      } else if (!_isValidIPWithPrefixLen(value)) {
        cursor.violate(
          message: 'value must be a valid IP with prefix length',
          constraintId: 'string.ip_with_prefixlen',
          rulePath: RulePathBuilder.stringConstraint('ip_with_prefixlen'),
        );
      }
    }
    
    // IPv4 with prefix length validation
    if (ipv4WithPrefixlen == true) {
      if (value.isEmpty) {
        cursor.violate(
          message: 'value is empty, which is not a valid IPv4 with prefix length',
          constraintId: 'string.ipv4_with_prefixlen_empty',
          rulePath: RulePathBuilder.stringConstraint('ipv4_with_prefixlen'),
        );
      } else if (!_isValidIPv4WithPrefixLen(value)) {
        cursor.violate(
          message: 'value must be a valid IPv4 with prefix length',
          constraintId: 'string.ipv4_with_prefixlen',
          rulePath: RulePathBuilder.stringConstraint('ipv4_with_prefixlen'),
        );
      }
    }
    
    // IPv6 with prefix length validation
    if (ipv6WithPrefixlen == true) {
      if (value.isEmpty) {
        cursor.violate(
          message: 'value is empty, which is not a valid IPv6 with prefix length',
          constraintId: 'string.ipv6_with_prefixlen_empty',
          rulePath: RulePathBuilder.stringConstraint('ipv6_with_prefixlen'),
        );
      } else if (!_isValidIPv6WithPrefixLen(value)) {
        cursor.violate(
          message: 'value must be a valid IPv6 with prefix length',
          constraintId: 'string.ipv6_with_prefixlen',
          rulePath: RulePathBuilder.stringConstraint('ipv6_with_prefixlen'),
        );
      }
    }
    
    // TUUID validation
    if (tuuid == true) {
      if (value.isEmpty) {
        cursor.violate(
          message: '',
          constraintId: 'string.tuuid_empty',
          rulePath: RulePathBuilder.stringConstraint('tuuid'),
        );
      } else if (!_isValidTUUID(value)) {
        cursor.violate(
          message: '',
          constraintId: 'string.tuuid',
          rulePath: RulePathBuilder.stringConstraint('tuuid'),
        );
      }
    }
    
    // Host and port validation
    if (hostAndPort == true) {
      if (value.isEmpty) {
        cursor.violate(
          message: 'value is empty, which is not a valid host and port',
          constraintId: 'string.host_and_port_empty',
          rulePath: RulePathBuilder.stringConstraint('host_and_port'),
        );
      } else if (!_isValidHostAndPort(value)) {
        cursor.violate(
          message: 'value must be a valid host and port',
          constraintId: 'string.host_and_port',
          rulePath: RulePathBuilder.stringConstraint('host_and_port'),
        );
      }
    }
    
    // Well-known regex validation
    if (wellKnownRegex != null && wellKnownRegex != pb.KnownRegex.KNOWN_REGEX_UNSPECIFIED) {
      _validateWellKnownRegex(value, cursor);
    }
  }
  
  void _validateWellKnownRegex(String value, Cursor cursor) {
    switch (wellKnownRegex) {
      case pb.KnownRegex.KNOWN_REGEX_HTTP_HEADER_NAME:
        if (value.isEmpty) {
          cursor.violate(
            message: '',
            constraintId: 'string.well_known_regex.header_name_empty',
            rulePath: RulePathBuilder.stringConstraint('well_known_regex'),
          );
        } else if (!_isValidHTTPHeaderName(value)) {
          cursor.violate(
            message: '',
            constraintId: 'string.well_known_regex.header_name',
            rulePath: RulePathBuilder.stringConstraint('well_known_regex'),
          );
        }
        break;
      case pb.KnownRegex.KNOWN_REGEX_HTTP_HEADER_VALUE:
        if (!_isValidHTTPHeaderValue(value)) {
          cursor.violate(
            message: '',
            constraintId: 'string.well_known_regex.header_value',
            rulePath: RulePathBuilder.stringConstraint('well_known_regex'),
          );
        }
        break;
      default:
        // Unknown regex type
        break;
    }
  }
  
  // Email validation
  bool _isValidEmail(String value) {
    return StringValidators.isEmail(value);
  }
  
  // Hostname validation
  bool _isValidHostname(String value) {
    return StringValidators.isHostname(value);
  }
  
  // IP validation (v4 or v6)
  bool _isValidIP(String value) {
    return StringValidators.isIp(value);
  }
  
  // IPv4 validation
  bool _isValidIPv4(String value) {
    return StringValidators.isIp(value, 4);
  }
  
  // IPv6 validation
  bool _isValidIPv6(String value) {
    return StringValidators.isIp(value, 6);
  }
  
  // URI validation
  bool _isValidURI(String value) {
    return StringValidators.isUri(value);
  }
  
  // URI reference validation (can be relative)
  bool _isValidURIRef(String value) {
    return StringValidators.isUriRef(value);
  }
  
  // UUID validation
  bool _isValidUUID(String value) {
    return StringValidators.isUuid(value);
  }
  
  // Address validation (IP or hostname)
  bool _isValidAddress(String value) {
    return StringValidators.isAddress(value);
  }
  
  // IP prefix validation (any version)
  bool _isValidIPPrefix(String value) {
    return StringValidators.isIpPrefix(value);
  }
  
  // IPv4 prefix validation
  bool _isValidIPv4Prefix(String value) {
    // IPv4 prefix validation should enforce that the host portion is zero (strict mode)
    return StringValidators.isIpPrefix(value, 4, true);
  }
  
  // IPv6 prefix validation
  bool _isValidIPv6Prefix(String value) {
    // IPv6 prefix validation should enforce that the host portion is zero (strict mode)
    return StringValidators.isIpPrefix(value, 6, true);
  }
  
  // IP with prefix length validation
  bool _isValidIPWithPrefixLen(String value) {
    return StringValidators.isIpPrefix(value);
  }
  
  // IPv4 with prefix length validation
  bool _isValidIPv4WithPrefixLen(String value) {
    return StringValidators.isIpPrefix(value, 4);
  }
  
  // IPv6 with prefix length validation
  bool _isValidIPv6WithPrefixLen(String value) {
    return StringValidators.isIpPrefix(value, 6);
  }
  
  // TUUID validation
  bool _isValidTUUID(String value) {
    return StringValidators.isTuuid(value);
  }
  
  // Host and port validation
  bool _isValidHostAndPort(String value) {
    return StringValidators.isHostAndPort(value, true);
  }
  
  // HTTP header name validation
  bool _isValidHTTPHeaderName(String value) {
    // Use the strict field to determine validation mode
    // If strict is not specified, default to true (strict mode)
    return StringValidators.isHttpHeaderName(value, strict ?? true);
  }
  
  // HTTP header value validation
  bool _isValidHTTPHeaderValue(String value) {
    // For header values, use the strict field if available, otherwise default to true (strict)
    return StringValidators.isHttpHeaderValue(value, strict ?? true);
  }

  List<pb.FieldPathElement> _buildStringRulePath(String fieldName, int fieldNumber) {
    return [
      pb.FieldPathElement()
        ..fieldNumber = 14  // string field number in FieldRules
        ..fieldName = 'string'
        ..fieldType = FieldDescriptorProto_Type.TYPE_MESSAGE,
      pb.FieldPathElement()
        ..fieldNumber = fieldNumber
        ..fieldName = fieldName
        ..fieldType = _getStringFieldType(fieldName),
    ];
  }

  FieldDescriptorProto_Type _getStringFieldType(String fieldName) {
    switch (fieldName) {
      case 'const':
      case 'pattern':
      case 'prefix':
      case 'suffix':
      case 'contains':
      case 'not_contains':
        return FieldDescriptorProto_Type.TYPE_STRING;
      case 'len':
      case 'min_len':
      case 'max_len':
      case 'min_bytes':
      case 'max_bytes':
        return FieldDescriptorProto_Type.TYPE_UINT64;
      case 'in':
      case 'not_in':
        return FieldDescriptorProto_Type.TYPE_STRING; // repeated string
      case 'email':
      case 'hostname':
      case 'ip':
      case 'ipv4':
      case 'ipv6':
      case 'uri':
      case 'uri_ref':
      case 'address':
      case 'uuid':
      case 'ipv4_prefix':
      case 'ipv6_prefix':
      case 'well_known_regex':
        return FieldDescriptorProto_Type.TYPE_ENUM;
      default:
        return FieldDescriptorProto_Type.TYPE_STRING;
    }
  }
}

/// Evaluator for bytes field rules.
class BytesEvaluator implements Evaluator {
  final List<int>? constValue;
  final int? len;
  final int? minLen;
  final int? maxLen;
  final String? pattern;
  final List<int>? prefix;
  final List<int>? suffix;
  final List<int>? contains;
  final List<List<int>>? inValues;
  final List<List<int>>? notInValues;
  
  // Special format validators
  final bool? ip;
  final bool? ipv4;
  final bool? ipv6;
  
  // Cached compiled pattern for hex representation
  RegExp? _compiledPattern;
  
  BytesEvaluator({
    this.constValue,
    this.len,
    this.minLen,
    this.maxLen,
    this.pattern,
    this.prefix,
    this.suffix,
    this.contains,
    this.inValues,
    this.notInValues,
    this.ip,
    this.ipv4,
    this.ipv6,
  }) {
    // Compile pattern once during construction
    if (pattern != null) {
      try {
        _compiledPattern = RegExp(pattern!);
      } catch (e) {
        // Pattern compilation error will be caught during validation
      }
    }
  }
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    // Accept both List<int> and Uint8List
    if (value is! List<int>) {
      cursor.violate(
        message: 'Expected bytes, got ${value.runtimeType}',
        constraintId: 'bytes.type',
      );
      return;
    }
    
    final bytesValue = value;
    
    // Check const
    if (constValue != null && !_bytesEqual(bytesValue, constValue!)) {
      cursor.violate(
        message: 'value must be ${_bytesToHex(constValue!)}',
        constraintId: 'bytes.const',
        rulePath: RulePathBuilder.bytesConstraint('const'),
      );
    }
    
    // Check exact length
    if (len != null && bytesValue.length != len) {
      cursor.violate(
        message: '',
        constraintId: 'bytes.len',
        rulePath: RulePathBuilder.bytesConstraint('len'),
      );
    }
    
    // Check min length
    if (minLen != null && bytesValue.length < minLen!) {
      cursor.violate(
        message: '',
        constraintId: 'bytes.min_len',
        rulePath: RulePathBuilder.bytesConstraint('min_len'),
      );
    }
    
    // Check max length
    if (maxLen != null && bytesValue.length > maxLen!) {
      cursor.violate(
        message: '',
        constraintId: 'bytes.max_len',
        rulePath: RulePathBuilder.bytesConstraint('max_len'),
      );
    }
    
    // Check pattern (on UTF-8 string representation)
    if (pattern != null) {
      if (_compiledPattern == null) {
        cursor.violate(
          message: 'Invalid regex pattern: $pattern',
          constraintId: 'bytes.pattern.compile_error',
          rulePath: RulePathBuilder.bytesConstraint('pattern'),
        );
      } else {
        // Check if bytes are valid UTF-8
        if (!_isValidUtf8(bytesValue)) {
          throw RuntimeError('value must be valid UTF-8 to apply regexp');
        }
        
        // Convert bytes to UTF-8 string for pattern matching
        final stringValue = String.fromCharCodes(bytesValue);
        if (!_compiledPattern!.hasMatch(stringValue)) {
          cursor.violate(
            message: 'value must match regex pattern `$pattern`',
            constraintId: 'bytes.pattern',
            rulePath: RulePathBuilder.bytesConstraint('pattern'),
          );
        }
      }
    }
    
    // Check prefix
    if (prefix != null && !_hasPrefix(bytesValue, prefix!)) {
      cursor.violate(
        message: '',
        constraintId: 'bytes.prefix',
        rulePath: RulePathBuilder.bytesConstraint('prefix'),
      );
    }
    
    // Check suffix
    if (suffix != null && !_hasSuffix(bytesValue, suffix!)) {
      cursor.violate(
        message: '',
        constraintId: 'bytes.suffix',
        rulePath: RulePathBuilder.bytesConstraint('suffix'),
      );
    }
    
    // Check contains
    if (contains != null && !_containsBytes(bytesValue, contains!)) {
      cursor.violate(
        message: '',
        constraintId: 'bytes.contains',
        rulePath: RulePathBuilder.bytesConstraint('contains'),
      );
    }
    
    // Check in
    if (inValues != null) {
      bool found = false;
      for (final allowedValue in inValues!) {
        if (_bytesEqual(bytesValue, allowedValue)) {
          found = true;
          break;
        }
      }
      if (!found) {
        cursor.violate(
          message: '',
          constraintId: 'bytes.in',
          rulePath: RulePathBuilder.bytesConstraint('in'),
        );
      }
    }
    
    // Check not_in
    if (notInValues != null) {
      for (final disallowedValue in notInValues!) {
        if (_bytesEqual(bytesValue, disallowedValue)) {
          cursor.violate(
            message: '',
            constraintId: 'bytes.not_in',
            rulePath: RulePathBuilder.bytesConstraint('not_in'),
          );
          break;
        }
      }
    }
    
    // Check IP formats
    _validateIPFormats(bytesValue, cursor);
  }
  
  void _validateIPFormats(List<int> value, Cursor cursor) {
    // IP validation (v4 or v6)
    if (ip == true) {
      if (!_isValidIPBytes(value)) {
        cursor.violate(
          message: 'value must be a valid IP address',
          constraintId: 'bytes.ip',
          rulePath: RulePathBuilder.bytesConstraint('ip'),
        );
      }
    }
    
    // IPv4 validation
    if (ipv4 == true) {
      if (value.length != 4) {
        cursor.violate(
          message: 'value must be a valid IPv4 address',
          constraintId: 'bytes.ipv4',
          rulePath: RulePathBuilder.bytesConstraint('ipv4'),
        );
      }
    }
    
    // IPv6 validation
    if (ipv6 == true) {
      if (value.length != 16) {
        cursor.violate(
          message: 'value must be a valid IPv6 address',
          constraintId: 'bytes.ipv6',
          rulePath: RulePathBuilder.bytesConstraint('ipv6'),
        );
      }
    }
  }
  
  bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  
  bool _hasPrefix(List<int> bytes, List<int> prefix) {
    if (bytes.length < prefix.length) return false;
    for (int i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) return false;
    }
    return true;
  }
  
  bool _hasSuffix(List<int> bytes, List<int> suffix) {
    if (bytes.length < suffix.length) return false;
    final offset = bytes.length - suffix.length;
    for (int i = 0; i < suffix.length; i++) {
      if (bytes[offset + i] != suffix[i]) return false;
    }
    return true;
  }
  
  bool _containsBytes(List<int> bytes, List<int> sequence) {
    if (bytes.length < sequence.length) return false;
    
    for (int i = 0; i <= bytes.length - sequence.length; i++) {
      bool found = true;
      for (int j = 0; j < sequence.length; j++) {
        if (bytes[i + j] != sequence[j]) {
          found = false;
          break;
        }
      }
      if (found) return true;
    }
    return false;
  }
  
  /// Check if bytes represent valid UTF-8
  bool _isValidUtf8(List<int> bytes) {
    try {
      // Use Dart's built-in UTF-8 decoder which throws on invalid sequences
      const utf8Decoder = Utf8Decoder(allowMalformed: false);
      utf8Decoder.convert(bytes);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  String _toHexString(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
  
  String _bytesToHex(List<int> bytes) => _toHexString(bytes);
  
  bool _isValidIPBytes(List<int> bytes) {
    return bytes.length == 4 || bytes.length == 16;
  }
}

/// Evaluator for fixed32 field rules (unsigned).
class Fixed32Evaluator extends NumericEvaluator<int> {
  Fixed32Evaluator({
    super.constValue,
    super.lt,
    super.lte,
    super.gt,
    super.gte,
    super.inValues,
    super.notInValues,
  });
  
  @override
  String get typeName => 'fixed32';
  
  @override
  String get constraintPrefix => 'fixed32';
  
  @override
  int get ruleFieldNumber => 9;
  
  @override
  bool isValidType(dynamic value) => value is int && value >= 0;
  
  @override
  int toTypedValue(dynamic value) => value as int;
}

/// Evaluator for fixed64 field rules (unsigned).
class Fixed64Evaluator extends NumericEvaluator<Int64> {
  Fixed64Evaluator({
    Int64? constValue,
    Int64? lt,
    Int64? lte,
    Int64? gt,
    Int64? gte,
    List<Int64>? inValues,
    List<Int64>? notInValues,
  }) : super(
    constValue: constValue,
    lt: lt,
    lte: lte,
    gt: gt,
    gte: gte,
    inValues: inValues,
    notInValues: notInValues,
  );
  
  @override
  String get typeName => 'fixed64';
  
  @override
  String get constraintPrefix => 'fixed64';
  
  @override
  int get ruleFieldNumber => 10;
  
  @override
  bool isValidType(dynamic value) => value is Int64 && !value.isNegative;
  
  @override
  Int64 toTypedValue(dynamic value) => value as Int64;
}

/// Evaluator for sfixed32 field rules (signed).
class SFixed32Evaluator extends NumericEvaluator<int> {
  SFixed32Evaluator({
    super.constValue,
    super.lt,
    super.lte,
    super.gt,
    super.gte,
    super.inValues,
    super.notInValues,
  });
  
  @override
  String get typeName => 'sfixed32';
  
  @override
  String get constraintPrefix => 'sfixed32';
  
  @override
  int get ruleFieldNumber => 11;
  
  @override
  bool isValidType(dynamic value) => value is int;
  
  @override
  int toTypedValue(dynamic value) => value as int;
}

/// Evaluator for sfixed64 field rules (signed).
class SFixed64Evaluator extends NumericEvaluator<Int64> {
  SFixed64Evaluator({
    Int64? constValue,
    Int64? lt,
    Int64? lte,
    Int64? gt,
    Int64? gte,
    List<Int64>? inValues,
    List<Int64>? notInValues,
  }) : super(
    constValue: constValue,
    lt: lt,
    lte: lte,
    gt: gt,
    gte: gte,
    inValues: inValues,
    notInValues: notInValues,
  );
  
  @override
  String get typeName => 'sfixed64';
  
  @override
  String get constraintPrefix => 'sfixed64';
  
  @override
  int get ruleFieldNumber => 12;
  
  @override
  bool isValidType(dynamic value) => value is Int64;
  
  @override
  Int64 toTypedValue(dynamic value) => value as Int64;
}

/// Evaluator for sint32 field rules (zigzag encoded signed).
class SInt32Evaluator extends NumericEvaluator<int> {
  SInt32Evaluator({
    super.constValue,
    super.lt,
    super.lte,
    super.gt,
    super.gte,
    super.inValues,
    super.notInValues,
  });
  
  @override
  String get typeName => 'sint32';
  
  @override
  String get constraintPrefix => 'sint32';
  
  @override
  int get ruleFieldNumber => 7;
  
  @override
  bool isValidType(dynamic value) => value is int;
  
  @override
  int toTypedValue(dynamic value) => value as int;
}

/// Evaluator for sint64 field rules (zigzag encoded signed).
class SInt64Evaluator extends NumericEvaluator<Int64> {
  SInt64Evaluator({
    Int64? constValue,
    Int64? lt,
    Int64? lte,
    Int64? gt,
    Int64? gte,
    List<Int64>? inValues,
    List<Int64>? notInValues,
  }) : super(
    constValue: constValue,
    lt: lt,
    lte: lte,
    gt: gt,
    gte: gte,
    inValues: inValues,
    notInValues: notInValues,
  );
  
  @override
  String get typeName => 'sint64';
  
  @override
  String get constraintPrefix => 'sint64';
  
  @override
  int get ruleFieldNumber => 8;
  
  @override
  bool isValidType(dynamic value) => value is Int64;
  
  @override
  Int64 toTypedValue(dynamic value) => value as Int64;
}