import 'package:protobuf/protobuf.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';
import 'package:protovalidate/src/gen/google/protobuf/descriptor.pb.dart';
import 'evaluator.dart';
import 'cursor.dart';
import 'field_path.dart';
import 'error.dart';
import 'rule_paths.dart';

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
    var fieldValue = message.getField(field.tagNumber);
    final hasValue = message.hasField(field.tagNumber);
    
    // For enum fields with defined_only validation, we need to check unknown fields
    // for raw integer values that were not recognized during deserialization
    final unknownField = message.unknownFields.getField(field.tagNumber);
    if (unknownField != null && unknownField.varints.isNotEmpty) {
      // There's an unknown raw value for this field, use the first one
      fieldValue = unknownField.varints.first.toInt();
    }
    
    // For proto3 implicit presence fields, getField() returns the default value automatically
    // No need to manually provide defaults since the protobuf library handles this now
    
    // Check required constraint first
    if (required && !hasValue) {
      // Add the field to the cursor before violating
      final fieldCursor = cursor.field(field);
      fieldCursor.violate(
        message: 'value is required',
        constraintId: 'required',
        rulePath: RulePath.fromFieldRules().constraint('required', 25, FieldDescriptorProto_Type.TYPE_BOOL),
      );
      return;
    }
    
    // For fields with IGNORE_IF_ZERO_VALUE, skip validation based on presence semantics
    if (ignore == Ignore.IGNORE_IF_ZERO_VALUE) {
      // For fields with presence (proto3 optional, proto2, messages), only skip if not set
      if (hasPresence) {
        if (!hasValue) {
          return; // Skip unset fields
        }
        // If set explicitly, validate even if zero value
      } else {
        // For fields without presence (proto3 scalars), skip if zero value
        if (!hasValue || _isZeroValue(fieldValue)) {
          return;
        }
      }
    }
    
    // For fields with presence, skip validation if not set
    // (unless explicitly required, which was already checked above)
    // Exception: repeated fields should always validate even if empty
    if (hasPresence && !hasValue && !required && !field.isRepeated) {
      return;
    }
    
    // For proto3 scalars without presence that weren't set, we now have default value
    // Continue with validation using the default value
    
    // For repeated fields that weren't set, provide empty list
    if (field.isRepeated && !hasValue) {
      fieldValue = <dynamic>[];
    }
    
    // Create a cursor for this field
    final fieldCursor = cursor.field(field);
    
    // Evaluate the field value
    valueEvaluator.evaluate(fieldValue, fieldCursor);
  }
  
  bool _isZeroValue(dynamic value) {
    if (value == null) return true;
    
    // Check for zero values based on type (for IGNORE_IF_ZERO_VALUE)
    if (value is bool && !value) return true;
    if (value is int && value == 0) return true;
    if (value is Int64 && value == Int64.ZERO) return true;
    if (value is double && value == 0.0) return true;
    if (value is String && value.isEmpty) return true;
    if (value is List && value.isEmpty) return true;
    if (value is Map && value.isEmpty) return true;
    // For messages, only consider null/unset as zero value, not empty messages
    // An explicitly created empty message {} is NOT a zero value
    
    return false;
  }
  
}

/// Items-only evaluator for repeated fields following Go/ES architecture
/// Only handles item validation - field-level constraints handled by CEL
class RepeatedItemsOnlyEvaluator implements Evaluator {
  final Evaluator itemEvaluator;
  final bool unwrapWrapperTypes;
  final Ignore ignoreRule;
  
  RepeatedItemsOnlyEvaluator({
    required this.itemEvaluator,
    this.unwrapWrapperTypes = false,
    this.ignoreRule = Ignore.IGNORE_UNSPECIFIED,
  });
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) return;
    
    final list = value as List;
    
    // Only validate individual items - NO field-level constraints
    for (int i = 0; i < list.length; i++) {
      var itemValue = list[i];
      
      // Check ignore rules for item
      if (ignoreRule == Ignore.IGNORE_ALWAYS) {
        continue; // Skip this item entirely
      }
      
      if (ignoreRule == Ignore.IGNORE_IF_ZERO_VALUE && _isZeroValue(itemValue)) {
        continue; // Skip zero values
      }
      
      // Unwrap wrapper types if needed
      if (unwrapWrapperTypes && itemValue is GeneratedMessage) {
        itemValue = _unwrapWrapperValue(itemValue);
      }
      
      // Create cursor with list index and proper rule path prefix for repeated.items
      final itemCursor = cursor.listIndex(i);
      final prefixedCursor = PrefixedRulePathCursor(itemCursor, RulePathBuilder.repeatedItemsBase());
      
      // Evaluate the item with proper rule path prefix
      itemEvaluator.evaluate(itemValue, prefixedCursor);
    }
  }
  
  bool _isZeroValue(dynamic value) {
    if (value == null) return true;
    
    // Check for zero values based on type (for IGNORE_IF_ZERO_VALUE)
    if (value is bool && !value) return true;
    if (value is int && value == 0) return true;
    if (value is Int64 && value == Int64.ZERO) return true;
    if (value is double && value == 0.0) return true;
    if (value is String && value.isEmpty) return true;
    if (value is List && value.isEmpty) return true;
    if (value is Map && value.isEmpty) return true;
    // For messages, only consider null/unset as zero value, not empty messages
    // An explicitly created empty message {} is NOT a zero value
    
    return false;
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

/// Unified evaluator for repeated field validation with field-level and item-level constraints
class RepeatedFieldEvaluator implements Evaluator {
  final int? minItems;
  final int? maxItems;
  final bool? unique;
  final Evaluator? itemEvaluator;
  final bool unwrapWrapperTypes;
  final Ignore ignoreRule;
  
  RepeatedFieldEvaluator({
    this.minItems,
    this.maxItems,
    this.unique,
    this.itemEvaluator,
    this.unwrapWrapperTypes = false,
    this.ignoreRule = Ignore.IGNORE_UNSPECIFIED,
  });
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) return;
    
    final list = value as List;
    
    // Check field-level constraints first
    if (minItems != null && list.length < minItems!) {
      cursor.violate(
        message: 'value must contain at least $minItems item(s)',
        constraintId: 'repeated.min_items',
        rulePath: RulePathBuilder.repeatedConstraint('min_items'),
      );
    }
    
    if (maxItems != null && list.length > maxItems!) {
      cursor.violate(
        message: 'value must contain no more than $maxItems item(s)',
        constraintId: 'repeated.max_items', 
        rulePath: RulePathBuilder.repeatedConstraint('max_items'),
      );
    }
    
    if (unique == true) {
      final seen = <dynamic>{};
      for (int i = 0; i < list.length; i++) {
        final item = list[i];
        if (seen.contains(item)) {
          cursor.violate(
            message: 'repeated value must contain unique items',
            constraintId: 'repeated.unique',
            rulePath: RulePathBuilder.repeatedConstraint('unique'),
          );
          break; // Only report once
        }
        seen.add(item);
      }
    }
    
    // Now validate individual items if we have an item evaluator
    if (itemEvaluator != null) {
      for (int i = 0; i < list.length; i++) {
        var itemValue = list[i];
        
        // Check ignore rules for item
        if (ignoreRule == Ignore.IGNORE_ALWAYS) {
          continue; // Skip this item entirely
        }
        
        if (ignoreRule == Ignore.IGNORE_IF_ZERO_VALUE && _isZeroValue(itemValue)) {
          continue; // Skip zero values
        }
        
        // Unwrap wrapper types if needed
        if (unwrapWrapperTypes && itemValue is GeneratedMessage) {
          itemValue = _unwrapWrapperValue(itemValue);
        }
        
        // Create cursor with list index and proper rule path prefix
        final itemCursor = cursor.listIndex(i);
        final prefixedCursor = PrefixedRulePathCursor(itemCursor, RulePathBuilder.repeatedItemsBase());
        
        // Evaluate the item with proper rule path prefix
        itemEvaluator!.evaluate(itemValue, prefixedCursor);
      }
    }
  }
  
  bool _isZeroValue(dynamic value) {
    if (value == null) return true;
    
    // Check for zero values based on type (for IGNORE_IF_ZERO_VALUE)
    if (value is bool && !value) return true;
    if (value is int && value == 0) return true;
    if (value is Int64 && value == Int64.ZERO) return true;
    if (value is double && value == 0.0) return true;
    if (value is String && value.isEmpty) return true;
    if (value is List && value.isEmpty) return true;
    if (value is Map && value.isEmpty) return true;
    // For messages, only consider null/unset as zero value, not empty messages
    // An explicitly created empty message {} is NOT a zero value
    
    return false;
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
  final int? minPairs;
  final int? maxPairs;
  
  MapFieldEvaluator({
    this.keyEvaluator,
    this.valueEvaluator,
    this.minPairs,
    this.maxPairs,
  });
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) return;
    
    final map = value as Map;
    
    // Check min pairs
    if (minPairs != null && map.length < minPairs!) {
      cursor.violate(
        message: 'map must be at least $minPairs entries',
        constraintId: 'map.min_pairs',
        rulePath: RulePathBuilder.mapConstraint('min_pairs'),
      );
    }
    
    // Check max pairs
    if (maxPairs != null && map.length > maxPairs!) {
      cursor.violate(
        message: 'map must be at most $maxPairs entries',
        constraintId: 'map.max_pairs',
        rulePath: RulePathBuilder.mapConstraint('max_pairs'),
      );
    }
    
    // Validate each entry
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