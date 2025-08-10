import 'package:protobuf/protobuf.dart';
import '../evaluator.dart';
import '../cursor.dart';
import '../gen/buf/validate/validate.pb.dart';

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
    if (value is! ProtobufEnum) {
      cursor.violate(
        message: 'Expected an enum value',
        constraintId: 'enum.type',
      );
      return;
    }
    
    final enumValue = value.value;
    
    // Check const rule
    if (rules.hasConst_1()) {
      if (enumValue != rules.const_1) {
        cursor.violate(
          message: 'Value must be exactly ${rules.const_1}',
          constraintId: 'enum.const',
        );
      }
    }
    
    // Check defined_only rule
    if (rules.definedOnly == true && enumValueNames != null) {
      // Check if the value is in the list of defined values
      final isDefined = enumValueNames!.containsKey(enumValue);
      if (!isDefined) {
        cursor.violate(
          message: 'Value must be one of the defined enum values',
          constraintId: 'enum.defined_only',
        );
      }
    }
    
    // Check in rule
    if (rules.in_3.isNotEmpty) {
      if (!rules.in_3.contains(enumValue)) {
        cursor.violate(
          message: 'value must be in list ${rules.in_3}',
          constraintId: 'enum.in',
        );
      }
    }
    
    // Check not_in rule
    if (rules.notIn.isNotEmpty) {
      if (rules.notIn.contains(enumValue)) {
        cursor.violate(
          message: 'value must not be in list ${rules.notIn}',
          constraintId: 'enum.not_in',
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
    if (value is! ProtobufEnum) {
      cursor.violate(
        message: 'Expected an enum value',
        constraintId: 'enum.type',
      );
      return;
    }
    
    // If definedOnly is true and we have enum info, validate
    if (definedOnly && enumValueNames != null) {
      final enumValue = value.value;
      final isDefined = enumValueNames!.containsKey(enumValue);
      if (!isDefined) {
        cursor.violate(
          message: 'Value must be one of the defined enum values',
          constraintId: 'enum.defined_only',
        );
      }
    }
  }
}