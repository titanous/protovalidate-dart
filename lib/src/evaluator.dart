import 'package:protobuf/protobuf.dart';
import 'cursor.dart';
import 'error.dart';
import 'rule_paths.dart';
import 'utils/field_type_mapper.dart';

/// Base interface for all evaluators.
abstract class Evaluator {
  /// Evaluates the given value against validation rules.
  void evaluate(dynamic value, Cursor cursor);
}

/// Context passed during validation evaluation.
class ValidationContext {
  /// Whether to fail fast on first violation.
  final bool failFast;

  /// The current message being validated.
  final GeneratedMessage message;

  /// Any additional context data.
  final Map<String, dynamic> data = {};

  ValidationContext({
    required this.failFast,
    required this.message,
  });
}

/// Base evaluator for field-level validation.
abstract class FieldEvaluator implements Evaluator {
  final FieldInfo fieldInfo;

  FieldEvaluator(this.fieldInfo);

  @override
  void evaluate(dynamic value, Cursor cursor) {
    final fieldCursor = cursor.field(fieldInfo);
    evaluateField(value, fieldCursor);
  }

  /// Evaluates the field value.
  void evaluateField(dynamic value, Cursor cursor);
}

/// Evaluator for message-level validation.
abstract class MessageEvaluator implements Evaluator {
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

  /// Evaluates the message.
  void evaluateMessage(GeneratedMessage message, Cursor cursor);
}

/// Evaluator for repeated field constraints (min_items, max_items, unique).
/// This evaluator handles field-level constraints only.
/// Item validation is handled separately by RepeatedFieldItemsEvaluator.
// Old RepeatedFieldEvaluator removed - now using unified version in field_evaluator.dart

/// Evaluator for map fields.
class MapFieldEvaluator implements Evaluator {
  final Evaluator? keyEvaluator;
  final Evaluator? valueEvaluator;
  final int? minPairs;
  final int? maxPairs;
  final int? keyFieldType;
  final int? valueFieldType;

  MapFieldEvaluator({
    this.keyEvaluator,
    this.valueEvaluator,
    this.minPairs,
    this.maxPairs,
    this.keyFieldType,
    this.valueFieldType,
  });

  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value is! Map) {
      cursor.violate(
        message: 'Expected a Map',
        constraintId: 'map.type',
      );
      return;
    }

    final map = value;

    // Check min/max pairs
    if (minPairs != null && map.length < minPairs!) {
      cursor.violate(
        message: 'value must contain at least $minPairs pair(s)',
        constraintId: 'map.min_pairs',
        rulePath: RulePathBuilder.mapConstraint('min_pairs'),
      );
    }

    if (maxPairs != null && map.length > maxPairs!) {
      cursor.violate(
        message: 'value must contain no more than $maxPairs pair(s)',
        constraintId: 'map.max_pairs',
        rulePath: RulePathBuilder.mapConstraint('max_pairs'),
      );
    }

    // Evaluate each key-value pair
    map.forEach((key, value) {
      final keyCursor = _createMapKeyCursor(cursor, key);

      keyEvaluator?.evaluate(key, keyCursor);
      valueEvaluator?.evaluate(value, keyCursor);
    });
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

/// Composite evaluator that runs multiple evaluators.
class CompositeEvaluator implements Evaluator {
  final List<Evaluator> evaluators;

  CompositeEvaluator(this.evaluators);

  @override
  void evaluate(dynamic value, Cursor cursor) {
    for (final evaluator in evaluators) {
      evaluator.evaluate(value, cursor);

      // Stop if we've violated and are in fail-fast mode
      if (cursor.failFast && cursor.violated) {
        break;
      }
    }
  }
}

/// No-op evaluator that does nothing.
class NoOpEvaluator implements Evaluator {
  @override
  void evaluate(dynamic value, Cursor cursor) {
    // Does nothing
  }
}

/// Evaluator for embedded message fields.
/// This wraps a message evaluator and handles field path updates.
class EmbeddedMessageEvaluator implements Evaluator {
  final Evaluator messageEvaluator;

  EmbeddedMessageEvaluator(this.messageEvaluator);

  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) {
      // Null messages are allowed for optional fields
      return;
    }

    if (value is! GeneratedMessage) {
      cursor.violate(
        message: 'Expected a GeneratedMessage',
        constraintId: 'message.type',
      );
      return;
    }

    // Evaluate the nested message
    messageEvaluator.evaluate(value, cursor);
  }
}

/// Wraps an evaluator to add map.keys rule path context
class MapKeysEvaluator implements Evaluator {
  final Evaluator wrapped;

  MapKeysEvaluator(this.wrapped);

  @override
  void evaluate(dynamic value, Cursor cursor) {
    // Add map.keys prefix to rule path
    final mapKeysPath = RulePathBuilder.mapConstraint('keys');
    final prefixedCursor = PrefixedRulePathCursor(cursor, mapKeysPath);

    // Store initial violation count
    final initialViolations = cursor.violations.length;

    // Evaluate with prefixed cursor
    wrapped.evaluate(value, prefixedCursor);

    // Mark new violations as forKey
    _markNewViolationsForKey(cursor, initialViolations);
  }

  /// Marks violations added after initialCount as forKey violations
  void _markNewViolationsForKey(Cursor cursor, int initialCount) {
    cursor.markViolationsForKey(initialCount);
  }
}

/// Wraps an evaluator to add map.values rule path context
class MapValuesEvaluator implements Evaluator {
  final Evaluator wrapped;

  MapValuesEvaluator(this.wrapped);

  @override
  void evaluate(dynamic value, Cursor cursor) {
    // Add map.values prefix to rule path
    final mapValuesPath = RulePathBuilder.mapConstraint('values');
    final prefixedCursor = PrefixedRulePathCursor(cursor, mapValuesPath);
    wrapped.evaluate(value, prefixedCursor);
  }
}
