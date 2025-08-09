import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';
import 'evaluator.dart';
import 'cursor.dart';
import 'error.dart';
import 'rules/scalar.dart';
import 'rules/string.dart';
import 'rules/repeated.dart';
import 'rules/map.dart';
import 'rules/enum.dart';
import 'rules/message.dart';
import 'rule_extractor.dart';

/// Plans validation for messages by building evaluation trees.
/// Similar to ES Planner class.
class ValidationPlanner {
  /// Cache of compiled message evaluators.
  final Map<Type, Evaluator> _messageCache = {};
  
  /// Whether to validate legacy required fields.
  final bool legacyRequired;
  
  /// Rule extractor for getting validation rules from descriptors.
  final RuleExtractor ruleExtractor;
  
  ValidationPlanner({
    this.legacyRequired = false,
    RuleExtractor? ruleExtractor,
  }) : ruleExtractor = ruleExtractor ?? RuleExtractor();
  
  /// Plans validation for a message type.
  Evaluator planMessage(GeneratedMessage message) {
    final messageType = message.runtimeType;
    
    // Check cache
    final cached = _messageCache[messageType];
    if (cached != null) {
      return cached;
    }
    
    // Get message rules from extensions
    final messageRules = ruleExtractor.getMessageRules(message);
    
    // Build composite evaluator
    final evaluator = CompositeEvaluator([]);
    _messageCache[messageType] = evaluator;
    
    // Add field evaluators
    evaluator.add(planFields(message, messageRules));
    
    // Add message-level CEL rules (future)
    if (messageRules != null && messageRules.cel.isNotEmpty) {
      // TODO: Add CEL evaluation
    }
    
    // Add oneof validation
    evaluator.add(planOneofs(message));
    
    // Prune no-op evaluators
    evaluator.prune();
    
    return evaluator;
  }
  
  /// Plans field validation.
  Evaluator planFields(GeneratedMessage message, MessageRules? messageRules) {
    final evaluators = <Evaluator>[];
    
    for (final field in message.info_.fieldInfo.values) {
      final fieldEvaluator = planField(field, message);
      if (fieldEvaluator != null) {
        evaluators.add(fieldEvaluator);
      }
    }
    
    if (evaluators.isEmpty) {
      return NoOpEvaluator();
    }
    
    return CompositeEvaluator(evaluators);
  }
  
  /// Plans validation for a single field.
  Evaluator? planField(FieldInfo field, GeneratedMessage message) {
    // Get field rules from extensions
    final fieldRules = ruleExtractor.getFieldRules(message, field);
    
    // Handle required validation
    if (fieldRules != null && fieldRules.required_25 && 
        fieldRules.ignore != Ignore.ALWAYS) {
      // Add required field evaluator
      return FieldRequiredEvaluator(field);
    }
    
    // Handle legacy required (proto2)
    if (legacyRequired && field.isRequired) {
      return FieldRequiredEvaluator(field);
    }
    
    // Plan based on field kind
    Evaluator? valueEvaluator;
    
    if (field.isRepeated && !field.isMapField) {
      valueEvaluator = planList(field, fieldRules);
    } else if (field.isMapField) {
      valueEvaluator = planMap(field, fieldRules);
    } else if (field.isEnum) {
      valueEvaluator = planEnum(field, fieldRules);
    } else {
      // Scalar or message field
      final fieldType = field.type;
      if (_isMessageField(fieldType)) {
        valueEvaluator = planMessageField(field, fieldRules);
      } else {
        valueEvaluator = planScalar(field, fieldRules);
      }
    }
    
    if (valueEvaluator == null) {
      return null;
    }
    
    // Wrap with field evaluator that handles field access and ignore conditions
    return FieldEvaluator(
      field: field,
      valueEvaluator: valueEvaluator,
      ignore: fieldRules?.ignore ?? Ignore.DEFAULT,
    );
  }
  
  /// Plans list/repeated field validation.
  Evaluator? planList(FieldInfo field, FieldRules? fieldRules) {
    // Get repeated rules
    final repeatedRules = fieldRules?.repeated;
    
    // Build item evaluator based on list element type
    Evaluator? itemEvaluator;
    
    if (field.isEnum) {
      itemEvaluator = planEnumValue(field, repeatedRules?.items);
    } else if (_isMessageField(field.type)) {
      itemEvaluator = planMessageValue(field, repeatedRules?.items);
    } else {
      itemEvaluator = planScalarValue(field, repeatedRules?.items);
    }
    
    // Build list evaluator
    final evaluators = <Evaluator>[];
    
    // Add standard repeated rules
    if (repeatedRules != null) {
      evaluators.add(RepeatedRulesEvaluator(repeatedRules));
    }
    
    // Add item validation
    if (itemEvaluator != null) {
      evaluators.add(RepeatedItemsEvaluator(itemEvaluator));
    }
    
    // Add CEL rules
    if (fieldRules != null && fieldRules.cel.isNotEmpty) {
      // TODO: Add CEL evaluation
    }
    
    if (evaluators.isEmpty) {
      return null;
    }
    
    return CompositeEvaluator(evaluators);
  }
  
  /// Plans map field validation.
  Evaluator? planMap(FieldInfo field, FieldRules? fieldRules) {
    // Get map rules
    final mapRules = fieldRules?.map;
    
    // Build key and value evaluators
    Evaluator? keyEvaluator = planScalarValue(field, mapRules?.keys);
    Evaluator? valueEvaluator;
    
    if (field.isEnum) {
      valueEvaluator = planEnumValue(field, mapRules?.values);
    } else if (_isMessageField(field.valueFieldType!)) {
      valueEvaluator = planMessageValue(field, mapRules?.values);
    } else {
      valueEvaluator = planScalarValue(field, mapRules?.values);
    }
    
    // Build map evaluator
    final evaluators = <Evaluator>[];
    
    // Add standard map rules
    if (mapRules != null) {
      evaluators.add(MapRulesEvaluator(mapRules));
    }
    
    // Add key/value validation
    if (keyEvaluator != null || valueEvaluator != null) {
      evaluators.add(MapEntriesEvaluator(
        keyEvaluator: keyEvaluator,
        valueEvaluator: valueEvaluator,
      ));
    }
    
    // Add CEL rules
    if (fieldRules != null && fieldRules.cel.isNotEmpty) {
      // TODO: Add CEL evaluation
    }
    
    if (evaluators.isEmpty) {
      return null;
    }
    
    return CompositeEvaluator(evaluators);
  }
  
  /// Plans enum field validation.
  Evaluator? planEnum(FieldInfo field, FieldRules? fieldRules) {
    return planEnumValue(field, fieldRules);
  }
  
  /// Plans enum value validation.
  Evaluator? planEnumValue(FieldInfo field, FieldRules? fieldRules) {
    final enumRules = fieldRules?.enum_16;
    
    if (enumRules == null) {
      return null;
    }
    
    return EnumRulesEvaluator(enumRules);
  }
  
  /// Plans message field validation.
  Evaluator? planMessageField(FieldInfo field, FieldRules? fieldRules) {
    return planMessageValue(field, fieldRules);
  }
  
  /// Plans message value validation.
  Evaluator? planMessageValue(FieldInfo field, FieldRules? fieldRules) {
    final messageRules = fieldRules?.message;
    
    final evaluators = <Evaluator>[];
    
    // Add skip validation
    if (messageRules != null && messageRules.skip) {
      return null;
    }
    
    // Add required validation
    if (messageRules != null && messageRules.required_26) {
      evaluators.add(MessageRequiredEvaluator());
    }
    
    // TODO: Add nested message validation by recursively planning
    
    // Add CEL rules
    if (fieldRules != null && fieldRules.cel.isNotEmpty) {
      // TODO: Add CEL evaluation
    }
    
    if (evaluators.isEmpty) {
      return null;
    }
    
    return CompositeEvaluator(evaluators);
  }
  
  /// Plans scalar field validation.
  Evaluator? planScalar(FieldInfo field, FieldRules? fieldRules) {
    return planScalarValue(field, fieldRules);
  }
  
  /// Plans scalar value validation.
  Evaluator? planScalarValue(FieldInfo field, FieldRules? fieldRules) {
    if (fieldRules == null) {
      return null;
    }
    
    // Determine scalar type and build appropriate evaluator
    switch (field.type) {
      case PbFieldType.OB:
      case PbFieldType.PB:
        if (fieldRules.hasBool_13()) {
          return BoolEvaluator(
            constValue: fieldRules.bool_13.hasConst_1() ? fieldRules.bool_13.const_1 : null,
          );
        }
        break;
        
      case PbFieldType.O3:
      case PbFieldType.P3:
      case PbFieldType.OS3:
      case PbFieldType.PS3:
      case PbFieldType.OSF3:
      case PbFieldType.PSF3:
        if (fieldRules.hasInt32()) {
          final rules = fieldRules.int32;
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
        break;
        
      case PbFieldType.O6:
      case PbFieldType.P6:
      case PbFieldType.OS6:
      case PbFieldType.PS6:
      case PbFieldType.OSF6:
      case PbFieldType.PSF6:
        if (fieldRules.hasInt64()) {
          final rules = fieldRules.int64;
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
        break;
        
      case PbFieldType.OU3:
      case PbFieldType.PU3:
        if (fieldRules.hasUint32()) {
          final rules = fieldRules.uint32;
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
        break;
        
      case PbFieldType.OU6:
      case PbFieldType.PU6:
        if (fieldRules.hasUint64()) {
          final rules = fieldRules.uint64;
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
        break;
        
      case PbFieldType.OF:
      case PbFieldType.PF:
        if (fieldRules.hasFloat()) {
          final rules = fieldRules.float;
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
        break;
        
      case PbFieldType.OD:
      case PbFieldType.PD:
        if (fieldRules.hasDouble_2()) {
          final rules = fieldRules.double_2;
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
        break;
        
      case PbFieldType.OS:
      case PbFieldType.PS:
      case PbFieldType.QS:
      case PbFieldType.RS:
        if (fieldRules.hasString_14()) {
          return StringRulesEvaluator(fieldRules.string_14);
        }
        break;
        
      case PbFieldType.OY:
      case PbFieldType.PY:
        if (fieldRules.hasBytes_15()) {
          return BytesRulesEvaluator(fieldRules.bytes_15);
        }
        break;
        
      default:
        break;
    }
    
    // Add CEL rules
    if (fieldRules.cel.isNotEmpty) {
      // TODO: Add CEL evaluation
    }
    
    return null;
  }
  
  /// Plans oneof validation.
  Evaluator planOneofs(GeneratedMessage message) {
    final evaluators = <Evaluator>[];
    
    // Get oneof descriptors and check for required
    for (final oneof in message.info_.oneofs) {
      final oneofRules = ruleExtractor.getOneofRules(message, oneof);
      if (oneofRules != null && oneofRules.required_8) {
        evaluators.add(OneofRequiredEvaluator(oneof));
      }
    }
    
    if (evaluators.isEmpty) {
      return NoOpEvaluator();
    }
    
    return CompositeEvaluator(evaluators);
  }
  
  /// Checks if a field type represents a message field.
  bool _isMessageField(int fieldType) {
    return fieldType == PbFieldType.OM ||
           fieldType == PbFieldType.PM ||
           fieldType == PbFieldType.QM;
  }
}

/// Evaluates a field with its value evaluator.
class FieldEvaluator implements Evaluator {
  final FieldInfo field;
  final Evaluator valueEvaluator;
  final Ignore ignore;
  
  FieldEvaluator({
    required this.field,
    required this.valueEvaluator,
    required this.ignore,
  });
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value is! GeneratedMessage) {
      return;
    }
    
    final message = value as GeneratedMessage;
    
    // Check ignore conditions
    if (_shouldIgnore(message)) {
      return;
    }
    
    final fieldValue = message.getField(field.tagNumber);
    final fieldCursor = cursor.field(field);
    valueEvaluator.evaluate(fieldValue, fieldCursor);
  }
  
  bool _shouldIgnore(GeneratedMessage message) {
    switch (ignore) {
      case Ignore.ALWAYS:
        return true;
      case Ignore.IF_UNPOPULATED:
        return !message.hasField(field.tagNumber);
      case Ignore.IF_DEFAULT_VALUE:
        final value = message.getField(field.tagNumber);
        return _isDefaultValue(value);
      default:
        return false;
    }
  }
  
  bool _isDefaultValue(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value == false;
    if (value is int) return value == 0;
    if (value is double) return value == 0.0;
    if (value is String) return value.isEmpty;
    if (value is List) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    return false;
  }
}

/// Evaluates that a field is required.
class FieldRequiredEvaluator implements Evaluator {
  final FieldInfo field;
  
  FieldRequiredEvaluator(this.field);
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value is! GeneratedMessage) {
      return;
    }
    
    final message = value as GeneratedMessage;
    if (!message.hasField(field.tagNumber)) {
      cursor.add(Violation(
        fieldPath: cursor.fieldPath(),
        message: 'field is required',
        constraintId: 'required',
      ));
    }
  }
}

/// Evaluates that a oneof has a value.
class OneofRequiredEvaluator implements Evaluator {
  final OneofInfo oneof;
  
  OneofRequiredEvaluator(this.oneof);
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value is! GeneratedMessage) {
      return;
    }
    
    final message = value as GeneratedMessage;
    bool hasValue = false;
    
    for (final field in oneof.fields) {
      if (message.hasField(field.tagNumber)) {
        hasValue = true;
        break;
      }
    }
    
    if (!hasValue) {
      cursor.add(Violation(
        fieldPath: cursor.fieldPath(),
        message: 'exactly one field is required in oneof',
        constraintId: 'required',
      ));
    }
  }
}

/// Evaluates that a message is required (not null).
class MessageRequiredEvaluator implements Evaluator {
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) {
      cursor.add(Violation(
        fieldPath: cursor.fieldPath(),
        message: 'message is required',
        constraintId: 'required',
      ));
    }
  }
}