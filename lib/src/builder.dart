import 'package:protobuf/protobuf.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';
import 'descriptor_rules.dart';
import 'evaluator.dart';
import 'rules/scalar.dart';
import 'error.dart';
import 'cursor.dart';

/// Builds evaluators from validation rules.
class EvaluatorBuilder {
  /// Cache of compiled evaluators by message type.
  final Map<Type, Evaluator> _cache = {};
  
  /// Optional descriptor rules for extracting validation rules from FileDescriptorSet.
  final DescriptorRules? descriptorRules;
  
  EvaluatorBuilder({this.descriptorRules});
  
  /// Builds an evaluator for the given message type.
  Evaluator buildForMessage(GeneratedMessage message) {
    final messageType = message.runtimeType;
    
    // Check cache
    if (_cache.containsKey(messageType)) {
      return _cache[messageType]!;
    }
    
    // Build evaluator
    final evaluator = _buildMessageEvaluator(message);
    _cache[messageType] = evaluator;
    return evaluator;
  }
  
  /// Builds a message evaluator.
  Evaluator _buildMessageEvaluator(GeneratedMessage message) {
    final evaluators = <Evaluator>[];
    
    // Build field evaluators
    for (final field in message.info_.fieldInfo.values) {
      final fieldEvaluator = _buildFieldEvaluator(field, message);
      if (fieldEvaluator != null) {
        evaluators.add(fieldEvaluator);
      }
    }
    
    if (evaluators.isEmpty) {
      // Return a no-op evaluator
      return NoOpEvaluator();
    }
    
    return CompositeEvaluator(evaluators);
  }
  
  /// Builds a field evaluator.
  Evaluator? _buildFieldEvaluator(FieldInfo field, GeneratedMessage message) {
    // Try to get field rules from the descriptor if available
    FieldRules? fieldRules;
    if (descriptorRules != null) {
      final messageTypeName = descriptorRules!.getFullTypeName(message);
      fieldRules = descriptorRules!.getFieldRules(messageTypeName, field.name);
    }
    
    // If we have field rules, build evaluator from them
    if (fieldRules != null) {
      final evaluator = buildFromFieldRules(fieldRules);
      if (evaluator != null) {
        return FieldValidatorWrapper(field, evaluator, rules: fieldRules);
      }
    }
    
    // Fall back to basic type validation
    // Handle repeated fields
    if (field.isRepeated && !field.isMapField) {
      final itemEvaluator = _buildScalarEvaluator(field);
      if (itemEvaluator != null) {
        return FieldValidatorWrapper(
          field,
          RepeatedFieldEvaluator(itemEvaluator: itemEvaluator),
        );
      }
    }
    
    // Handle map fields
    if (field.isMapField) {
      // For now, skip map validation
      return null;
    }
    
    // Handle scalar fields
    final scalarEvaluator = _buildScalarEvaluator(field);
    if (scalarEvaluator != null) {
      return FieldValidatorWrapper(field, scalarEvaluator);
    }
    
    return null;
  }
  
  /// Builds a scalar evaluator based on field type.
  Evaluator? _buildScalarEvaluator(FieldInfo field) {
    // For now, create basic type validators
    // In a full implementation, we would read the actual rules from extensions
    
    switch (field.type) {
      case PbFieldType.OB:
      case PbFieldType.PB:
        return BoolEvaluator();
        
      case PbFieldType.O3:
      case PbFieldType.P3:
      case PbFieldType.OS3:
      case PbFieldType.PS3:
      case PbFieldType.OSF3:
      case PbFieldType.PSF3:
        return Int32Evaluator();
        
      case PbFieldType.O6:
      case PbFieldType.P6:
      case PbFieldType.OS6:
      case PbFieldType.PS6:
      case PbFieldType.OSF6:
      case PbFieldType.PSF6:
        return Int64Evaluator();
        
      case PbFieldType.OU3:
      case PbFieldType.PU3:
      case PbFieldType.OU3:
      case PbFieldType.PU3:
        return UInt32Evaluator();
        
      case PbFieldType.OU6:
      case PbFieldType.PU6:
        return UInt64Evaluator();
        
      case PbFieldType.OF:
      case PbFieldType.PF:
        return FloatEvaluator();
        
      case PbFieldType.OD:
      case PbFieldType.PD:
        return DoubleEvaluator();
        
      default:
        return null;
    }
  }
  
  /// Builds an evaluator from field rules.
  Evaluator? buildFromFieldRules(FieldRules rules) {
    // Build evaluator based on the type in the rules
    if (rules.hasBool_13()) {
      return _buildBoolEvaluator(rules.bool_13);
    }
    if (rules.hasInt32()) {
      return _buildInt32Evaluator(rules.int32);
    }
    if (rules.hasInt64()) {
      return _buildInt64Evaluator(rules.int64);
    }
    if (rules.hasUint32()) {
      return _buildUInt32Evaluator(rules.uint32);
    }
    if (rules.hasUint64()) {
      return _buildUInt64Evaluator(rules.uint64);
    }
    if (rules.hasFloat()) {
      return _buildFloatEvaluator(rules.float);
    }
    if (rules.hasDouble_2()) {
      return _buildDoubleEvaluator(rules.double_2);
    }
    
    return null;
  }
  
  Evaluator _buildBoolEvaluator(BoolRules rules) {
    return BoolEvaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
    );
  }
  
  Evaluator _buildInt32Evaluator(Int32Rules rules) {
    return Int32Evaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      lt: rules.hasLt() ? rules.lt : null,
      lte: rules.hasLte() ? rules.lte : null,
      gt: rules.hasGt() ? rules.gt : null,
      gte: rules.hasGte() ? rules.gte : null,
      inValues: rules.in_6.isNotEmpty ? rules.in_6 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
    );
  }
  
  Evaluator _buildInt64Evaluator(Int64Rules rules) {
    return Int64Evaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      lt: rules.hasLt() ? rules.lt : null,
      lte: rules.hasLte() ? rules.lte : null,
      gt: rules.hasGt() ? rules.gt : null,
      gte: rules.hasGte() ? rules.gte : null,
      inValues: rules.in_6.isNotEmpty ? rules.in_6 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
    );
  }
  
  Evaluator _buildUInt32Evaluator(UInt32Rules rules) {
    return UInt32Evaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      lt: rules.hasLt() ? rules.lt : null,
      lte: rules.hasLte() ? rules.lte : null,
      gt: rules.hasGt() ? rules.gt : null,
      gte: rules.hasGte() ? rules.gte : null,
      inValues: rules.in_6.isNotEmpty ? rules.in_6 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
    );
  }
  
  Evaluator _buildUInt64Evaluator(UInt64Rules rules) {
    return UInt64Evaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      lt: rules.hasLt() ? rules.lt : null,
      lte: rules.hasLte() ? rules.lte : null,
      gt: rules.hasGt() ? rules.gt : null,
      gte: rules.hasGte() ? rules.gte : null,
      inValues: rules.in_6.isNotEmpty ? rules.in_6 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
    );
  }
  
  Evaluator _buildFloatEvaluator(FloatRules rules) {
    return FloatEvaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      lt: rules.hasLt() ? rules.lt : null,
      lte: rules.hasLte() ? rules.lte : null,
      gt: rules.hasGt() ? rules.gt : null,
      gte: rules.hasGte() ? rules.gte : null,
      inValues: rules.in_6.isNotEmpty ? rules.in_6 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
      finite: rules.hasFinite() ? rules.finite : null,
    );
  }
  
  Evaluator _buildDoubleEvaluator(DoubleRules rules) {
    return DoubleEvaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      lt: rules.hasLt() ? rules.lt : null,
      lte: rules.hasLte() ? rules.lte : null,
      gt: rules.hasGt() ? rules.gt : null,
      gte: rules.hasGte() ? rules.gte : null,
      inValues: rules.in_6.isNotEmpty ? rules.in_6 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
      finite: rules.hasFinite() ? rules.finite : null,
    );
  }
}

/// Wrapper that evaluates a field value.
class FieldValidatorWrapper implements Evaluator {
  final FieldInfo field;
  final Evaluator evaluator;
  final FieldRules? rules;
  
  FieldValidatorWrapper(this.field, this.evaluator, {this.rules});
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value is! GeneratedMessage) {
      return;
    }
    
    final message = value as GeneratedMessage;
    final fieldValue = message.getField(field.tagNumber);
    
    // Check if we should skip validation based on ignore rules
    // For proto3, if field is not set and doesn't have const or required rules, skip
    final hasField = message.hasField(field.tagNumber);
    
    // Always validate if there's a const rule or required rule
    final hasConstRule = rules?.hasBool_13() == true && rules!.bool_13.hasConst_1();
    final hasRequiredRule = rules?.hasRequired() == true && rules!.required;
    
    if (!hasField && !hasConstRule && !hasRequiredRule) {
      // Skip validation for unset fields without const/required rules
      return;
    }
    
    final fieldCursor = cursor.field(field);
    evaluator.evaluate(fieldValue, fieldCursor);
  }
}

/// No-op evaluator that does nothing.
class NoOpEvaluator implements Evaluator {
  @override
  void evaluate(dynamic value, Cursor cursor) {
    // Do nothing
  }
}