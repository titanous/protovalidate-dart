import 'dart:io';
import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';
import 'package:protovalidate/src/gen/google/protobuf/descriptor.pb.dart';
import 'package:protovalidate/src/gen/google/protobuf/descriptor.pbenum.dart';
import 'evaluator.dart';
import 'cursor.dart';
import 'field_path.dart';
import 'error.dart';
import 'rule_paths.dart';
import 'ignore_conditions.dart';
import 'utils/zero_value_checker.dart';
import 'utils/field_type_mapper.dart';
import 'rules/enum.dart';

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

    // Get field value - use getFieldOrNull for enums to preserve unknown values
    var fieldValue = message.getField(field.tagNumber);
    final hasValue = message.hasField(field.tagNumber);
    
    // For enum fields, check for unknown enum values using getFieldOrNull
    if ((field.type == PbFieldType.OE || field.type == PbFieldType.PE) && hasValue) {
      final rawValue = message.getFieldOrNull(field.tagNumber);
      if (rawValue != null && rawValue.toString().contains('UNKNOWN_ENUM_VALUE_')) {
        // This is an unknown enum value, extract the raw integer
        fieldValue = (rawValue as dynamic).value as int;
      }
    }

    // For proto3 implicit presence fields, getField() returns the default value automatically
    // No need to manually provide defaults since the protobuf library handles this now

    // Check required constraint first
    bool isRequiredViolation = false;
    if (required) {
      if (field.isMapField) {
        // For maps, treat empty maps as "not set" for required validation
        isRequiredViolation =
            !hasValue || ZeroValueChecker.isZeroValue(fieldValue);
      } else {
        // For other fields, use normal presence check
        isRequiredViolation = !hasValue;
      }
    }

    if (isRequiredViolation) {
      // Add the field to the cursor before violating
      final fieldCursor = cursor.field(field);
      fieldCursor.violate(
        message: 'value is required',
        constraintId: 'required',
        rulePath: RulePath.fromFieldRules()
            .constraint('required', 25, FieldDescriptorProto_Type.TYPE_BOOL),
      );
      return;
    }

    // For fields with IGNORE_IF_ZERO_VALUE, skip validation based on presence semantics
    if (ignore == Ignore.IGNORE_IF_ZERO_VALUE) {
      // Special handling for maps and repeated fields - they should be ignored if zero value
      // regardless of presence semantics
      if (field.isMapField || field.isRepeated) {
        if (ZeroValueChecker.isZeroValue(fieldValue)) {
          return;
        }
      } else if (hasPresence) {
        // For fields with presence (proto3 optional, proto2, messages), only skip if not set
        if (!hasValue) {
          return; // Skip unset fields
        }
        // If set explicitly, validate even if zero value
      } else {
        // For fields without presence (proto3 scalars), skip if zero value
        if (!hasValue || ZeroValueChecker.isZeroValue(fieldValue)) {
          return;
        }
      }
    }

    // For fields with explicit presence, skip validation if not set
    // (unless explicitly required, which was already checked above)
    // Exception: repeated fields should always validate even if empty
    // For proto3 scalars without explicit presence, always validate the default value
    if (hasPresence && !hasValue && !required && !field.isRepeated) {
      return;
    }

    // For proto3 scalars without explicit presence that weren't set, we have default value
    // Continue with validation using the default value - this is critical for
    // validating constraints like const, in, etc. on unset proto3 fields

    // For repeated fields that weren't set, provide empty list
    if (field.isRepeated && !hasValue) {
      fieldValue = <dynamic>[];
    }

    // Create a cursor for this field
    final fieldCursor = cursor.field(field);

    // Evaluate the field value
    valueEvaluator.evaluate(fieldValue, fieldCursor);
  }

}

/// Items-only evaluator for repeated fields following Go/ES architecture
/// Only handles item validation - field-level constraints handled by CEL
class RepeatedItemsOnlyEvaluator implements Evaluator {
  final Evaluator itemEvaluator;
  final bool unwrapWrapperTypes;
  final Ignore ignoreRule;
  final bool addItemsRulePrefix;

  RepeatedItemsOnlyEvaluator({
    required this.itemEvaluator,
    this.unwrapWrapperTypes = false,
    this.ignoreRule = Ignore.IGNORE_UNSPECIFIED,
    this.addItemsRulePrefix = false,
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

      if (ignoreRule == Ignore.IGNORE_IF_ZERO_VALUE &&
          ZeroValueChecker.isZeroValue(itemValue)) {
        continue; // Skip zero values
      }

      // Unwrap wrapper types if needed
      if (unwrapWrapperTypes && itemValue is GeneratedMessage) {
        itemValue = _unwrapWrapperValue(itemValue);
      }

      // Create cursor with list index and conditionally add rule path prefix
      final itemCursor = cursor.listIndex(i);
      final evaluationCursor = addItemsRulePrefix
          ? PrefixedRulePathCursor(
              itemCursor, RulePathBuilder.repeatedItemsBase())
          : itemCursor;

      // Evaluate the item
      itemEvaluator.evaluate(itemValue, evaluationCursor);
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

/// Unified evaluator for repeated field validation with field-level and item-level constraints
class RepeatedFieldEvaluator implements Evaluator {
  final int? minItems;
  final int? maxItems;
  final bool? unique;
  final Evaluator? itemEvaluator;
  final bool unwrapWrapperTypes;
  final Ignore ignoreRule;
  final bool addItemsRulePrefix;

  RepeatedFieldEvaluator({
    this.minItems,
    this.maxItems,
    this.unique,
    this.itemEvaluator,
    this.unwrapWrapperTypes = false,
    this.ignoreRule = Ignore.IGNORE_UNSPECIFIED,
    this.addItemsRulePrefix = true,
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

        if (ignoreRule == Ignore.IGNORE_IF_ZERO_VALUE &&
            ZeroValueChecker.isZeroValue(itemValue)) {
          continue; // Skip zero values
        }

        // Unwrap wrapper types if needed
        if (unwrapWrapperTypes && itemValue is GeneratedMessage) {
          itemValue = _unwrapWrapperValue(itemValue);
        }

        // Create cursor with list index and conditionally add rule path prefix
        final itemCursor = cursor.listIndex(i);
        final evaluationCursor = addItemsRulePrefix
            ? PrefixedRulePathCursor(
                itemCursor, RulePathBuilder.repeatedItemsBase())
            : itemCursor;

        // Evaluate the item
        itemEvaluator!.evaluate(itemValue, evaluationCursor);
      }
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
  final int? minPairs;
  final int? maxPairs;
  final int? keyFieldType;
  final int? valueFieldType;
  final IgnoreCondition<dynamic>? keyIgnoreCondition;
  final IgnoreCondition<dynamic>? valueIgnoreCondition;

  MapFieldEvaluator({
    this.keyEvaluator,
    this.valueEvaluator,
    this.minPairs,
    this.maxPairs,
    this.keyFieldType,
    this.valueFieldType,
    this.keyIgnoreCondition,
    this.valueIgnoreCondition,
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
      final keyCursor = _createMapKeyCursor(cursor, entry.key);

      // Evaluate key if evaluator provided and not ignored
      if (keyEvaluator != null &&
          !(keyIgnoreCondition?.shouldIgnore(entry.key) ?? false)) {
        keyEvaluator!.evaluate(entry.key, keyCursor);
      }

      // Evaluate value if evaluator provided and not ignored
      if (valueEvaluator != null &&
          !(valueIgnoreCondition?.shouldIgnore(entry.value) ?? false)) {
        valueEvaluator!.evaluate(entry.value, keyCursor);
      }
    }
  }

  /// Creates a map key cursor with proper type information if available.
  Cursor _createMapKeyCursor(Cursor cursor, dynamic key) {
    if (keyFieldType != null && valueFieldType != null) {
      final keyType =
          FieldTypeMapper.convertPbFieldTypeToDescriptorType(keyFieldType!);
      final valueType =
          FieldTypeMapper.convertPbFieldTypeToDescriptorType(valueFieldType!);
      return cursor.mapKeyWithTypes(key, keyType, valueType);
    } else {
      return cursor.mapKey(key);
    }
  }
}
