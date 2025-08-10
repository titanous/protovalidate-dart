import 'package:protobuf/protobuf.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/predefined_rules_proto2.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/predefined_rules_proto_editions.pb.dart';
import '../evaluator.dart';
import '../error.dart' as error;
import '../cursor.dart';
import '../field_path.dart';

/// Checks and applies predefined rules on field rules.
class PredefinedRulesChecker {
  /// Checks for predefined extensions on float rules.
  static Evaluator? checkFloatRules(FloatRules rules) {
    // Check proto2 extensions
    if (rules.hasExtension(Predefined_rules_proto2.floatAbsRangeProto2)) {
      final absRange = rules.getExtension(Predefined_rules_proto2.floatAbsRangeProto2) as double;
      return PredefinedFloatAbsRangeEvaluator(absRange, 'float.abs_range.proto2');
    }
    
    
    // Check editions extensions
    if (rules.hasExtension(Predefined_rules_proto_editions.floatAbsRangeEdition2023)) {
      final absRange = rules.getExtension(Predefined_rules_proto_editions.floatAbsRangeEdition2023) as double;
      return PredefinedFloatAbsRangeEvaluator(absRange, 'float.abs_range.edition_2023');
    }
    
    return null;
  }
  
  /// Checks for predefined extensions on double rules.
  static Evaluator? checkDoubleRules(DoubleRules rules) {
    // Check proto2 extensions
    if (rules.hasExtension(Predefined_rules_proto2.doubleAbsRangeProto2)) {
      final absRange = rules.getExtension(Predefined_rules_proto2.doubleAbsRangeProto2) as double;
      return PredefinedDoubleAbsRangeEvaluator(absRange, 'double.abs_range.proto2');
    }
    
    
    // Check editions extensions
    if (rules.hasExtension(Predefined_rules_proto_editions.doubleAbsRangeEdition2023)) {
      final absRange = rules.getExtension(Predefined_rules_proto_editions.doubleAbsRangeEdition2023) as double;
      return PredefinedDoubleAbsRangeEvaluator(absRange, 'double.abs_range.edition_2023');
    }
    
    return null;
  }
  
  /// Checks for predefined extensions on int32 rules.
  static Evaluator? checkInt32Rules(Int32Rules rules) {
    // Check proto2 extensions
    if (rules.hasExtension(Predefined_rules_proto2.int32AbsInProto2)) {
      final absIn = rules.getExtension(Predefined_rules_proto2.int32AbsInProto2) as List<int>;
      return PredefinedInt32AbsInEvaluator(absIn, 'int32.abs_in.proto2');
    }
    
    
    // Check editions extensions
    if (rules.hasExtension(Predefined_rules_proto_editions.int32AbsInEdition2023)) {
      final absIn = rules.getExtension(Predefined_rules_proto_editions.int32AbsInEdition2023) as List<int>;
      return PredefinedInt32AbsInEvaluator(absIn, 'int32.abs_in.edition_2023');
    }
    
    return null;
  }
  
  /// Checks for predefined extensions on int64 rules.
  static Evaluator? checkInt64Rules(Int64Rules rules) {
    // Check proto2 extensions
    if (rules.hasExtension(Predefined_rules_proto2.int64AbsInProto2)) {
      final absIn = rules.getExtension(Predefined_rules_proto2.int64AbsInProto2) as List;
      return PredefinedInt64AbsInEvaluator(absIn, 'int64.abs_in.proto2');
    }
    
    
    // Check editions extensions
    if (rules.hasExtension(Predefined_rules_proto_editions.int64AbsInEdition2023)) {
      final absIn = rules.getExtension(Predefined_rules_proto_editions.int64AbsInEdition2023) as List;
      return PredefinedInt64AbsInEvaluator(absIn, 'int64.abs_in.edition_2023');
    }
    
    return null;
  }
  
  /// Checks for predefined extensions on uint32 rules.
  static Evaluator? checkUInt32Rules(UInt32Rules rules) {
    // Check proto2 extensions
    if (rules.hasExtension(Predefined_rules_proto2.uint32EvenProto2)) {
      final even = rules.getExtension(Predefined_rules_proto2.uint32EvenProto2) as bool;
      if (even) {
        return PredefinedUInt32EvenEvaluator('uint32.even.proto2');
      }
    }
    
    
    // Check editions extensions
    if (rules.hasExtension(Predefined_rules_proto_editions.uint32EvenEdition2023)) {
      final even = rules.getExtension(Predefined_rules_proto_editions.uint32EvenEdition2023) as bool;
      if (even) {
        return PredefinedUInt32EvenEvaluator('uint32.even.edition_2023');
      }
    }
    
    return null;
  }
  
  /// Checks for predefined extensions on uint64 rules.
  static Evaluator? checkUInt64Rules(UInt64Rules rules) {
    // Check proto2 extensions
    if (rules.hasExtension(Predefined_rules_proto2.uint64EvenProto2)) {
      final even = rules.getExtension(Predefined_rules_proto2.uint64EvenProto2) as bool;
      if (even) {
        return PredefinedUInt64EvenEvaluator('uint64.even.proto2');
      }
    }
    
    
    // Check editions extensions
    if (rules.hasExtension(Predefined_rules_proto_editions.uint64EvenEdition2023)) {
      final even = rules.getExtension(Predefined_rules_proto_editions.uint64EvenEdition2023) as bool;
      if (even) {
        return PredefinedUInt64EvenEvaluator('uint64.even.edition_2023');
      }
    }
    
    return null;
  }
  
  /// Similar methods for other types...
  static Evaluator? checkStringRules(StringRules rules) {
    // Check proto2 extensions
    if (rules.hasExtension(Predefined_rules_proto2.stringValidPathProto2)) {
      final validPath = rules.getExtension(Predefined_rules_proto2.stringValidPathProto2) as bool;
      if (validPath) {
        return PredefinedStringValidPathEvaluator('string.valid_path.proto2');
      }
    }
    
    
    // Check editions extensions
    if (rules.hasExtension(Predefined_rules_proto_editions.stringValidPathEdition2023)) {
      final validPath = rules.getExtension(Predefined_rules_proto_editions.stringValidPathEdition2023) as bool;
      if (validPath) {
        return PredefinedStringValidPathEvaluator('string.valid_path.edition_2023');
      }
    }
    
    return null;
  }
  
  /// Checks for predefined extensions on repeated rules.
  static Evaluator? checkRepeatedRules(RepeatedRules rules) {
    // Check proto2 extensions
    if (rules.hasExtension(Predefined_rules_proto2.repeatedAtLeastFiveProto2)) {
      final atLeastFive = rules.getExtension(Predefined_rules_proto2.repeatedAtLeastFiveProto2) as bool;
      if (atLeastFive) {
        return PredefinedRepeatedAtLeastFiveEvaluator('repeated.at_least_five.proto2');
      }
    }
    
    
    // Check editions extensions
    if (rules.hasExtension(Predefined_rules_proto_editions.repeatedAtLeastFiveEdition2023)) {
      final atLeastFive = rules.getExtension(Predefined_rules_proto_editions.repeatedAtLeastFiveEdition2023) as bool;
      if (atLeastFive) {
        return PredefinedRepeatedAtLeastFiveEvaluator('repeated.at_least_five.edition_2023');
      }
    }
    
    return null;
  }
  
  /// Checks for predefined extensions on enum rules.
  static Evaluator? checkEnumRules(EnumRules rules) {
    // Check proto2 extensions
    if (rules.hasExtension(Predefined_rules_proto2.enumNonZeroProto2)) {
      final nonZero = rules.getExtension(Predefined_rules_proto2.enumNonZeroProto2) as bool;
      if (nonZero) {
        return PredefinedEnumNonZeroEvaluator('enum.non_zero.proto2');
      }
    }
    
    // Proto3 messages use proto2 extensions, no separate proto3 extensions
    
    // Check editions extensions
    if (rules.hasExtension(Predefined_rules_proto_editions.enumNonZeroEdition2023)) {
      final nonZero = rules.getExtension(Predefined_rules_proto_editions.enumNonZeroEdition2023) as bool;
      if (nonZero) {
        return PredefinedEnumNonZeroEvaluator('enum.non_zero.edition_2023');
      }
    }
    
    return null;
  }
  
  /// Add more type checking methods for sint32, sint64, fixed32, fixed64, sfixed32, sfixed64, bytes, bool, duration, timestamp
}

// Evaluator implementations for predefined rules

class PredefinedFloatAbsRangeEvaluator implements Evaluator {
  final double absRange;
  final String ruleId;
  
  PredefinedFloatAbsRangeEvaluator(this.absRange, this.ruleId);
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) return;
    
    final floatValue = value as double;
    if (floatValue.abs() > absRange) {
      cursor.violate(
        message: 'float value is out of range',
        constraintId: ruleId,
        rulePath: RulePath.fromFieldRules().predefinedExtension(ruleId.replaceAll('.', '_')),
      );
    }
  }
}

class PredefinedDoubleAbsRangeEvaluator implements Evaluator {
  final double absRange;
  final String ruleId;
  
  PredefinedDoubleAbsRangeEvaluator(this.absRange, this.ruleId);
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) return;
    
    final doubleValue = value as double;
    if (doubleValue.abs() > absRange) {
      cursor.violate(
        message: 'double value is out of range',
        constraintId: ruleId,
        rulePath: RulePath.fromFieldRules().predefinedExtension(ruleId.replaceAll('.', '_')),
      );
    }
  }
}

class PredefinedInt32AbsInEvaluator implements Evaluator {
  final List<int> absIn;
  final String ruleId;
  
  PredefinedInt32AbsInEvaluator(this.absIn, this.ruleId);
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) return;
    
    final intValue = value as int;
    final absValue = intValue.abs();
    
    if (!absIn.contains(absValue)) {
      cursor.violate(
        message: 'value must be in absolute value of list',
        constraintId: ruleId,
        rulePath: RulePath.fromFieldRules().predefinedExtension(ruleId.replaceAll('.', '_')),
      );
    }
  }
}

class PredefinedInt64AbsInEvaluator implements Evaluator {
  final List absIn;
  final String ruleId;
  
  PredefinedInt64AbsInEvaluator(this.absIn, this.ruleId);
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) return;
    
    final intValue = value as Int64;
    final absValue = intValue.abs();
    
    // Extract Int64 values from wrappers if necessary
    final absValues = absIn.map((v) {
      if (v is Int64) return v;
      if (v is GeneratedMessage && v.hasField(1)) {
        // Wrapper type
        return v.getField(1) as Int64;
      }
      return Int64(v as int);
    }).toList();
    
    if (!absValues.contains(absValue)) {
      cursor.violate(
        message: 'value must be in absolute value of list',
        constraintId: ruleId,
        rulePath: RulePath.fromFieldRules().predefinedExtension(ruleId.replaceAll('.', '_')),
      );
    }
  }
}

class PredefinedUInt32EvenEvaluator implements Evaluator {
  final String ruleId;
  
  PredefinedUInt32EvenEvaluator(this.ruleId);
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) return;
    
    final uintValue = value as int;
    if (uintValue % 2 != 0) {
      cursor.violate(
        message: 'uint32 value is not even',
        constraintId: ruleId,
        rulePath: RulePath.fromFieldRules().predefinedExtension(ruleId.replaceAll('.', '_')),
      );
    }
  }
}

class PredefinedUInt64EvenEvaluator implements Evaluator {
  final String ruleId;
  
  PredefinedUInt64EvenEvaluator(this.ruleId);
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) return;
    
    final uintValue = value is Int64 ? value : Int64(value as int);
    if (uintValue % Int64(2) != Int64.ZERO) {
      cursor.violate(
        message: 'uint64 value is not even',
        constraintId: ruleId,
        rulePath: RulePath.fromFieldRules().predefinedExtension(ruleId.replaceAll('.', '_')),
      );
    }
  }
}

class PredefinedStringValidPathEvaluator implements Evaluator {
  final String ruleId;
  
  PredefinedStringValidPathEvaluator(this.ruleId);
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) return;
    
    final stringValue = value as String;
    // A valid path should not start with "../"
    if (stringValue.startsWith('../')) {
      cursor.violate(
        message: 'not a valid path: `$stringValue`',
        constraintId: ruleId,
        rulePath: RulePath.fromFieldRules().predefinedExtension(ruleId.replaceAll('.', '_')),
      );
    }
  }
}

class PredefinedRepeatedAtLeastFiveEvaluator implements Evaluator {
  final String ruleId;
  
  PredefinedRepeatedAtLeastFiveEvaluator(this.ruleId);
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) return;
    
    final list = value as List;
    if (list.length < 5) {
      cursor.violate(
        message: 'repeated field must have at least five values',
        constraintId: ruleId,
        rulePath: RulePath.fromFieldRules().predefinedExtension(ruleId.replaceAll('.', '_')),
      );
    }
  }
}

class PredefinedEnumNonZeroEvaluator implements Evaluator {
  final String ruleId;
  
  PredefinedEnumNonZeroEvaluator(this.ruleId);
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) return;
    
    // Check if enum value is zero (unspecified)
    final enumValue = value is ProtobufEnum ? value.value : value as int;
    if (enumValue == 0) {
      cursor.violate(
        message: 'enum value is not non-zero',
        constraintId: ruleId,
        rulePath: RulePath.fromFieldRules().predefinedExtension(ruleId.replaceAll('.', '_')),
      );
    }
  }
}