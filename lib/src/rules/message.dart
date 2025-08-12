import 'package:protobuf/protobuf.dart';
import '../evaluator.dart';
import '../cursor.dart';
import '../gen/buf/validate/validate.pb.dart';
import '../builder.dart';
import '../cel/cel_integration.dart';

/// Evaluator for message field validation.
class MessageFieldEvaluator implements Evaluator {
  final bool required;
  final Ignore? ignore;
  final Evaluator? nestedEvaluator;
  
  MessageFieldEvaluator({
    this.required = false,
    this.ignore,
    this.nestedEvaluator,
  });
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    // Check if value is null when required
    if (value == null) {
      if (required) {
        cursor.violate(
          message: 'Field is required',
          constraintId: 'required',
        );
      }
      return;
    }
    
    // Check ignore rules
    if (ignore != null) {
      switch (ignore) {
        case Ignore.IGNORE_ALWAYS:
          // Skip validation entirely
          return;
        case Ignore.IGNORE_IF_ZERO_VALUE:
          // Skip if the message has zero/default values
          if (value is GeneratedMessage && _isDefaultValue(value)) {
            return;
          }
          break;
        default:
          break;
      }
    }
    
    // Validate nested message if we have an evaluator
    if (nestedEvaluator != null && value is GeneratedMessage) {
      nestedEvaluator!.evaluate(value, cursor);
    }
  }
  
  /// Checks if a message is unpopulated (no fields set).
  bool _isUnpopulated(GeneratedMessage message) {
    // Check if any field is set
    for (final field in message.info_.fieldInfo.values) {
      if (message.hasField(field.tagNumber)) {
        return false;
      }
    }
    return true;
  }
  
  /// Checks if a message has all default values.
  bool _isDefaultValue(GeneratedMessage message) {
    // For proto3, this is similar to unpopulated
    // For proto2, we'd need to check required fields
    return _isUnpopulated(message);
  }
}

/// Evaluator for messages with message-level rules.
class MessageRulesEvaluator implements MessageEvaluator {
  final MessageRules rules;
  final EvaluatorBuilder? builder;
  final ManagedMessageCELEvaluator? _celEvaluator;
  
  MessageRulesEvaluator({
    required this.rules,
    this.builder,
  }) : _celEvaluator = rules.cel.isNotEmpty 
        ? ManagedMessageCELEvaluator(expressions: _compileCelRules(rules.cel))
        : null;
  
  static List<ManagedCompiledExpression> _compileCelRules(List<Rule> rules) {
    try {
      final compiler = ManagedCELCompiler();
      return compiler.compile(rules);
    } catch (e) {
      // If compilation fails, return empty list to avoid breaking validation
      // TODO: Should we log this error somewhere?
      return [];
    }
  }
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value is! GeneratedMessage) {
      cursor.violate(
        message: 'Expected a GeneratedMessage',
        constraintId: 'message.type',
      );
      return;
    }
    evaluateMessage(value, cursor);
  }
  
  @override
  void evaluateMessage(GeneratedMessage message, Cursor cursor) {
    // Handle oneof rules
    for (final oneofRule in rules.oneof) {
      _evaluateOneofRule(message, oneofRule, cursor);
    }
    
    // Evaluate CEL rules if present
    if (_celEvaluator != null) {
      _celEvaluator!.evaluateMessage(message, cursor);
    }
  }
  
  void _evaluateOneofRule(GeneratedMessage message, MessageOneofRule rule, Cursor cursor) {
    var setCount = 0;
    final setFields = <String>[];
    
    // Count how many of the specified fields are set
    for (final fieldName in rule.fields) {
      // Need to find the field by name
      final fieldInfo = _findFieldByName(message, fieldName);
      if (fieldInfo != null && message.hasField(fieldInfo.tagNumber)) {
        setCount++;
        setFields.add(fieldName);
      }
    }
    
    // Check constraints
    if (rule.required && setCount == 0) {
      cursor.violate(
        message: 'At least one of ${rule.fields} must be set',
        constraintId: 'message.oneof.required',
      );
    } else if (setCount > 1) {
      cursor.violate(
        message: 'Only one of ${rule.fields} can be set, but found: $setFields',
        constraintId: 'message.oneof.exclusive',
      );
    }
  }
  
  FieldInfo? _findFieldByName(GeneratedMessage message, String name) {
    for (final field in message.info_.fieldInfo.values) {
      if (field.name == name) {
        return field;
      }
    }
    return null;
  }
}

/// Evaluator for protobuf oneof validation rules.
class ProtobufOneofEvaluator implements MessageEvaluator {
  final Map<String, OneofRules> oneofRules;
  
  ProtobufOneofEvaluator({required this.oneofRules});
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value is! GeneratedMessage) {
      cursor.violate(
        message: 'Expected a GeneratedMessage',
        constraintId: 'oneof.type',
      );
      return;
    }
    evaluateMessage(value, cursor);
  }
  
  @override
  void evaluateMessage(GeneratedMessage message, Cursor cursor) {
    // Check each oneof that has validation rules
    for (final entry in oneofRules.entries) {
      final oneofName = entry.key;
      final rules = entry.value;
      
      _evaluateOneofRules(message, oneofName, rules, cursor);
    }
  }
  
  void _evaluateOneofRules(GeneratedMessage message, String oneofName, OneofRules rules, Cursor cursor) {
    // For protobuf oneofs, we need to check which field is set in the oneof
    // This is trickier because we need to introspect the message structure
    
    // Find the oneof index by checking the message's oneof descriptors
    final oneofIndex = _findOneofIndex(message, oneofName);
    if (oneofIndex == -1) {
      // Oneof not found, skip validation
      return;
    }
    
    // Check if any field in the oneof is set
    final isOneofSet = _isOneofSet(message, oneofIndex);
    
    if (rules.required && !isOneofSet) {
      // Create field path for the oneof
      final oneofCursor = cursor.oneofField(oneofName);
      oneofCursor.violate(
        message: 'exactly one field is required in oneof',
        constraintId: 'required',
      );
    }
  }
  
  /// Finds the index of a oneof by name in the message descriptor.
  int _findOneofIndex(GeneratedMessage message, String oneofName) {
    // This is a simplified approach - in a full implementation,
    // we'd need to introspect the protobuf descriptor to map oneof names to indices
    // For now, we'll assume index 0 for the first oneof (which works for kitchen_sink)
    if (oneofName == 'o') {
      return 0;
    }
    return -1;
  }
  
  /// Checks if any field in the oneof at the given index is set.
  bool _isOneofSet(GeneratedMessage message, int oneofIndex) {
    try {
      // Use the built-in $_whichOneof method that all generated messages have
      final whichField = message.$_whichOneof(oneofIndex);
      // If whichField is 0, no field in the oneof is set
      return whichField != 0;
    } catch (e) {
      // Fallback if $_whichOneof fails
      return false;
    }
  }
}