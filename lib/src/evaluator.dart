import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/src/gen/google/protobuf/descriptor.pbenum.dart';
import 'cursor.dart';
import 'error.dart';
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
      final keyType = _convertPbFieldTypeToDescriptorType(keyFieldType!);
      final valueType = _convertPbFieldTypeToDescriptorType(valueFieldType!);
      return cursor.mapKeyWithTypes(key, keyType, valueType);
    } else {
      return cursor.mapKey(key);
    }
  }

  /// Converts PbFieldType to FieldDescriptorProto_Type.
  FieldDescriptorProto_Type _convertPbFieldTypeToDescriptorType(int pbFieldType) {
    // For packed fields, we need to extract the base type by removing the packed bit
    final baseType = pbFieldType & ~0x4; // Remove PACKED_BIT (0x4)
    
    // Map PbFieldType to FieldDescriptorProto_Type
    if (baseType == PbFieldType.OB || baseType == PbFieldType.PB || baseType == PbFieldType.QB) {
      return FieldDescriptorProto_Type.TYPE_BOOL;
    } else if (baseType == PbFieldType.O3 || baseType == PbFieldType.P3 || baseType == PbFieldType.Q3) {
      return FieldDescriptorProto_Type.TYPE_INT32;
    } else if (baseType == PbFieldType.O6 || baseType == PbFieldType.P6 || baseType == PbFieldType.Q6) {
      return FieldDescriptorProto_Type.TYPE_INT64;
    } else if (baseType == PbFieldType.OU3 || baseType == PbFieldType.PU3 || baseType == PbFieldType.QU3) {
      return FieldDescriptorProto_Type.TYPE_UINT32;
    } else if (baseType == PbFieldType.OU6 || baseType == PbFieldType.PU6 || baseType == PbFieldType.QU6) {
      return FieldDescriptorProto_Type.TYPE_UINT64;
    } else if (baseType == PbFieldType.OS3 || baseType == PbFieldType.PS3 || baseType == PbFieldType.QS3) {
      return FieldDescriptorProto_Type.TYPE_SINT32;
    } else if (baseType == PbFieldType.OS6 || baseType == PbFieldType.PS6 || baseType == PbFieldType.QS6) {
      return FieldDescriptorProto_Type.TYPE_SINT64;
    } else if (baseType == PbFieldType.OSF3 || baseType == PbFieldType.PSF3 || baseType == PbFieldType.QSF3) {
      return FieldDescriptorProto_Type.TYPE_SFIXED32;
    } else if (baseType == PbFieldType.OSF6 || baseType == PbFieldType.PSF6 || baseType == PbFieldType.QSF6) {
      return FieldDescriptorProto_Type.TYPE_SFIXED64;
    } else if (baseType == PbFieldType.OF3 || baseType == PbFieldType.PF3 || baseType == PbFieldType.QF3) {
      return FieldDescriptorProto_Type.TYPE_FIXED32;
    } else if (baseType == PbFieldType.OF6 || baseType == PbFieldType.PF6 || baseType == PbFieldType.QF6) {
      return FieldDescriptorProto_Type.TYPE_FIXED64;
    } else if (baseType == PbFieldType.OF || baseType == PbFieldType.PF || baseType == PbFieldType.QF) {
      return FieldDescriptorProto_Type.TYPE_FLOAT;
    } else if (baseType == PbFieldType.OD || baseType == PbFieldType.PD || baseType == PbFieldType.QD) {
      return FieldDescriptorProto_Type.TYPE_DOUBLE;
    } else if (baseType == PbFieldType.OS || baseType == PbFieldType.PS || baseType == PbFieldType.QS) {
      return FieldDescriptorProto_Type.TYPE_STRING;
    } else if (baseType == PbFieldType.OY || baseType == PbFieldType.PY || baseType == PbFieldType.QY) {
      return FieldDescriptorProto_Type.TYPE_BYTES;
    } else if (baseType == PbFieldType.OE || baseType == PbFieldType.PE || baseType == PbFieldType.QE) {
      return FieldDescriptorProto_Type.TYPE_ENUM;
    } else if (baseType == PbFieldType.OM || baseType == PbFieldType.PM || baseType == PbFieldType.QM) {
      return FieldDescriptorProto_Type.TYPE_MESSAGE;
    } else {
      // Default fallback
      return FieldDescriptorProto_Type.TYPE_STRING;
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