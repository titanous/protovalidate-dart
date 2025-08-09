import 'package:protobuf/protobuf.dart';
import '../evaluator.dart';
import '../cursor.dart';
import '../gen/buf/validate/validate.pb.dart';
import '../builder.dart';

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
  
  MessageRulesEvaluator({
    required this.rules,
    this.builder,
  });
  
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
    
    // CEL rules would be evaluated here
    // For now, we skip CEL support
    if (rules.cel.isNotEmpty) {
      // TODO: Implement CEL evaluation
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