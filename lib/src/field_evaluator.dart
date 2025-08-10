import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';
import 'package:protovalidate/src/gen/google/protobuf/descriptor.pb.dart';
import 'evaluator.dart';
import 'cursor.dart';
import 'field_path.dart';
import 'error.dart';

/// FieldEvaluator performs validation on a single message field.
/// This architecture matches the Go/ES implementations for proper field handling.
class FieldEvaluator implements Evaluator {
  /// The field being validated
  final FieldInfo field;
  
  /// The evaluator to apply to the field's value
  final Evaluator valueEvaluator;
  
  /// Whether the field is required to be set
  final bool required;
  
  /// Whether the field has presence (distinguishes between unset and default)
  final bool hasPresence;
  
  /// Ignore conditions for this field
  final Ignore ignore;
  
  /// Field rules for this field
  final FieldRules? rules;
  
  FieldEvaluator({
    required this.field,
    required this.valueEvaluator,
    this.required = false,
    this.hasPresence = false,
    this.ignore = Ignore.IGNORE_UNSPECIFIED,
    this.rules,
  });
  
  /// Check if this field should always skip validation
  bool get shouldIgnoreAlways => ignore == Ignore.IGNORE_ALWAYS;
  
  /// Check if this field should skip validation when empty/zero
  bool get shouldIgnoreEmpty => 
      hasPresence || ignore == Ignore.IGNORE_IF_ZERO_VALUE;
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    // The value here is the entire message
    final message = value as GeneratedMessage;
    
    // Always skip if IGNORE_ALWAYS is set
    if (shouldIgnoreAlways) {
      return;
    }
    
    // Get field value
    final fieldValue = message.getField(field.tagNumber);
    final hasValue = message.hasField(field.tagNumber);
    
    // Check required constraint first
    if (required && !hasValue) {
      cursor.violate(
        message: 'value is required',
        constraintId: 'required',
        rulePath: RulePath.fromFieldRules().constraint('required', 1000, FieldDescriptorProto_Type.TYPE_BOOL),
      );
      return;
    }
    
    // For fields with IGNORE_IF_ZERO_VALUE, skip validation for default values
    if (ignore == Ignore.IGNORE_IF_ZERO_VALUE && _isDefaultValue(fieldValue)) {
      return;
    }
    
    // For fields with presence, skip validation if not set
    // (unless explicitly required, which was already checked above)
    if (hasPresence && !hasValue && !required) {
      return;
    }
    
    // Create a cursor for this field
    final fieldCursor = cursor.field(field);
    
    // Evaluate the field value
    valueEvaluator.evaluate(fieldValue, fieldCursor);
  }
  
  bool _isDefaultValue(dynamic value) {
    if (value == null) return true;
    
    // Check for default values based on type
    if (value is bool && !value) return true;
    if (value is int && value == 0) return true;
    if (value is double && value == 0.0) return true;
    if (value is String && value.isEmpty) return true;
    if (value is List && value.isEmpty) return true;
    if (value is Map && value.isEmpty) return true;
    if (value is GeneratedMessage) {
      // For messages, check if all fields are default
      for (final f in value.info_.fieldInfo.values) {
        if (value.hasField(f.tagNumber)) {
          return false;
        }
      }
      return true;
    }
    
    return false;
  }
}

/// Evaluator for repeated fields that properly iterates through items
class RepeatedFieldItemsEvaluator implements Evaluator {
  final Evaluator itemEvaluator;
  final bool unwrapWrapperTypes;
  
  RepeatedFieldItemsEvaluator({
    required this.itemEvaluator,
    this.unwrapWrapperTypes = false,
  });
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) return;
    
    final list = value as List;
    for (int i = 0; i < list.length; i++) {
      var itemValue = list[i];
      
      // Unwrap wrapper types if needed
      if (unwrapWrapperTypes && itemValue is GeneratedMessage) {
        itemValue = _unwrapWrapperValue(itemValue);
      }
      
      // Create cursor with list index
      final itemCursor = cursor.listIndex(i);
      
      // Evaluate the item
      itemEvaluator.evaluate(itemValue, itemCursor);
    }
  }
  
  dynamic _unwrapWrapperValue(GeneratedMessage wrapper) {
    // Check if this is a wrapper type and unwrap the value
    final wrapperTypes = [
      'google.protobuf.DoubleValue',
      'google.protobuf.FloatValue', 
      'google.protobuf.Int64Value',
      'google.protobuf.UInt64Value',
      'google.protobuf.Int32Value',
      'google.protobuf.UInt32Value',
      'google.protobuf.BoolValue',
      'google.protobuf.StringValue',
      'google.protobuf.BytesValue',
    ];
    
    final typeName = wrapper.info_.qualifiedMessageName;
    if (wrapperTypes.contains(typeName)) {
      // Wrapper types have a single field with tag 1 named 'value'
      if (wrapper.hasField(1)) {
        return wrapper.getField(1);
      }
    }
    
    return wrapper;
  }
}

/// Evaluator for map fields that properly iterates through entries
class MapFieldEvaluator implements Evaluator {
  final Evaluator? keyEvaluator;
  final Evaluator? valueEvaluator;
  
  MapFieldEvaluator({
    this.keyEvaluator,
    this.valueEvaluator,
  });
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) return;
    
    final map = value as Map;
    for (final entry in map.entries) {
      // Create cursor with map key
      final keyCursor = cursor.mapKey(entry.key);
      
      // Evaluate key if evaluator provided
      keyEvaluator?.evaluate(entry.key, keyCursor);
      
      // Evaluate value if evaluator provided  
      valueEvaluator?.evaluate(entry.value, keyCursor);
    }
  }
}