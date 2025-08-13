import 'package:protobuf/protobuf.dart';
import '../evaluator.dart';
import '../cursor.dart';
import '../gen/buf/validate/validate.pb.dart';
import '../rule_paths.dart';

/// Evaluator for enum field validation rules.
class EnumRulesEvaluator implements Evaluator {
  final EnumRules rules;
  final Map<int, String>? enumValueNames;
  
  EnumRulesEvaluator({
    required this.rules,
    this.enumValueNames,
  });
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    // Handle both ProtobufEnum and raw int values
    int enumValue;
    bool isUnknownEnum = false;
    
    if (value is ProtobufEnum) {
      enumValue = value.value;
    } else if (value is int) {
      enumValue = value;
    } else {
      // Check if this is an unknown enum value by checking the string representation
      final valueStr = value.toString();
      if (valueStr.startsWith('UNKNOWN_ENUM_VALUE_')) {
        isUnknownEnum = true;
        // Extract the integer value from the unknown enum
        enumValue = (value as dynamic).value as int;
      } else {
        cursor.violate(
          message: 'Expected an enum value',
          constraintId: 'enum.type',
        );
        return;
      }
    }
    
    // Check const rule
    if (rules.hasConst_1()) {
      if (enumValue != rules.const_1) {
        cursor.violate(
          message: 'value must equal ${rules.const_1}',
          constraintId: 'enum.const',
          rulePath: RulePathBuilder.enumConstraint('const'),
        );
      }
    }
    
    // Check defined_only rule
    if (rules.definedOnly == true) {
      // If we detected an unknown enum value, it's definitely not defined
      if (isUnknownEnum) {
        cursor.violate(
          message: 'value must be one of the defined enum values',
          constraintId: 'enum.defined_only',
          rulePath: RulePathBuilder.enumConstraint('defined_only'),
        );
      } else if (enumValueNames != null && !enumValueNames!.containsKey(enumValue)) {
        cursor.violate(
          message: 'value must be one of the defined enum values',
          constraintId: 'enum.defined_only',
          rulePath: RulePathBuilder.enumConstraint('defined_only'),
        );
      } else if (enumValueNames == null) {
        // Without proper enum descriptor info, we can't validate defined_only
        // This is a limitation of the current implementation
        // Log a warning or skip validation
      }
    }
    
    // Check in rule
    if (rules.in_3.isNotEmpty) {
      if (!rules.in_3.contains(enumValue)) {
        cursor.violate(
          message: '',
          constraintId: 'enum.in',
          rulePath: RulePathBuilder.enumConstraint('in'),
        );
      }
    }
    
    // Check not_in rule
    if (rules.notIn.isNotEmpty) {
      if (rules.notIn.contains(enumValue)) {
        cursor.violate(
          message: 'value must not be in list [${rules.notIn.join(", ")}]',
          constraintId: 'enum.not_in',
          rulePath: RulePathBuilder.enumConstraint('not_in'),
        );
      }
    }
  }
}

/// Simple enum evaluator for when we have no specific rules.
class EnumEvaluator implements Evaluator {
  final bool definedOnly;
  final Map<int, String>? enumValueNames;
  
  EnumEvaluator({
    this.definedOnly = false,
    this.enumValueNames,
  });
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    // Handle both ProtobufEnum and raw int values
    int enumValue;
    if (value is ProtobufEnum) {
      enumValue = value.value;
    } else if (value is int) {
      enumValue = value;
    } else {
      cursor.violate(
        message: 'Expected an enum value',
        constraintId: 'enum.type',
      );
      return;
    }
    
    // If definedOnly is true and we have enum info, validate
    if (definedOnly && enumValueNames != null) {
      if (!enumValueNames!.containsKey(enumValue)) {
        cursor.violate(
          message: 'value must be one of the defined enum values',
          constraintId: 'enum.defined_only',
        );
      }
    }
  }
}