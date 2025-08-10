import 'package:protobuf/protobuf.dart';
import 'cursor.dart';
import 'rule_paths.dart';

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

/// Evaluator for repeated fields.
class RepeatedFieldEvaluator implements Evaluator {
  final Evaluator itemEvaluator;
  final int? minItems;
  final int? maxItems;
  final bool? unique;
  
  RepeatedFieldEvaluator({
    required this.itemEvaluator,
    this.minItems,
    this.maxItems,
    this.unique,
  });
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value is! List) {
      cursor.violate(
        message: 'Expected a List',
        constraintId: 'repeated.type',
      );
      return;
    }
    
    final list = value;
    
    // Check min/max items
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
    
    // Check uniqueness
    if (unique == true) {
      final seen = <dynamic>{};
      for (var i = 0; i < list.length; i++) {
        final item = list[i];
        if (!seen.add(item)) {
          cursor.violate(
            message: 'repeated value must contain unique items',
            constraintId: 'repeated.unique',
            rulePath: RulePathBuilder.repeatedConstraint('unique'),
          );
        }
      }
    }
    
    // Evaluate each item
    for (var i = 0; i < list.length; i++) {
      itemEvaluator.evaluate(list[i], cursor.listIndex(i));
    }
  }
}

/// Evaluator for map fields.
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
      );
    }
    
    if (maxPairs != null && map.length > maxPairs!) {
      cursor.violate(
        message: 'value must contain no more than $maxPairs pair(s)',
        constraintId: 'map.max_pairs',
      );
    }
    
    // Evaluate each key-value pair
    map.forEach((key, value) {
      final keyCursor = cursor.mapKey(key);
      
      keyEvaluator?.evaluate(key, keyCursor);
      valueEvaluator?.evaluate(value, keyCursor);
    });
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