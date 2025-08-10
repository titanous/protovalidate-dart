import 'package:cel/cel.dart' as cel;
import 'package:protobuf/protobuf.dart';
import 'package:fixnum/fixnum.dart';

import 'evaluator.dart';
import 'cursor.dart';
import 'error.dart' as err;
import 'gen/buf/validate/validate.pb.dart';
import 'gen/google/protobuf/descriptor.pb.dart';
import 'gen/google/protobuf/timestamp.pb.dart';
import 'gen/google/protobuf/duration.pb.dart';

/// CEL evaluator for custom expression rules
class CELEvaluator extends Evaluator {
  final List<CompiledExpression> expressions;
  final FieldDescriptorProto? fieldDescriptor;

  CELEvaluator({
    required this.expressions,
    this.fieldDescriptor,
  });

  @override
  bool evaluate(dynamic value, Cursor cursor) {
    for (final expr in expressions) {
      final result = expr.evaluate(value, cursor);
      if (!result) {
        return false;
      }
    }
    return true;
  }

  @override
  bool get tautology => expressions.isEmpty;
}

/// A compiled CEL expression ready for evaluation
class CompiledExpression {
  final cel.Program program;
  final Rule source;
  final String? message;
  final String? id;

  CompiledExpression({
    required this.program,
    required this.source,
    this.message,
    this.id,
  });

  bool evaluate(dynamic value, Cursor cursor) {
    try {
      // Create activation with standard variables
      final activation = _createActivation(value, cursor);
      
      // Evaluate the CEL program
      final result = program.evaluate(activation);
      
      // Handle the result
      if (result is bool) {
        if (!result) {
          _addViolation(cursor, value);
        }
        return result;
      } else if (result is Exception) {
        // CEL evaluation error
        cursor.violate(
          message: 'CEL evaluation error: ${result.toString()}',
          constraintId: 'cel.error',
        );
        return false;
      } else {
        // Unexpected result type
        cursor.violate(
          message: 'CEL expression must return a boolean, got: ${result.runtimeType}',
          constraintId: 'cel.type_error',
        );
        return false;
      }
    } catch (e) {
      // Runtime error during evaluation
      cursor.violate(
        message: 'CEL evaluation failed: $e',
        constraintId: 'cel.runtime_error',
      );
      return false;
    }
  }

  Map<String, dynamic> _createActivation(dynamic value, Cursor cursor) {
    final activation = <String, dynamic>{};
    
    // Add 'this' - the current value being validated
    activation['this'] = value;
    
    // Add 'now' - current timestamp
    activation['now'] = Timestamp.fromDateTime(DateTime.now());
    
    // TODO: Add other standard variables as needed:
    // - 'rules' - the validation rules
    // - 'rule' - the current rule being evaluated
    
    return activation;
  }

  void _addViolation(Cursor cursor, dynamic value) {
    final violationMessage = message ?? 
        'value must satisfy CEL expression \'${source.expression}\'';
    
    cursor.violate(
      constraintId: id ?? 'cel.expression',
      message: violationMessage,
    );
  }
}

/// Compiles CEL expressions from validation rules
class CELCompiler {
  final cel.Environment environment;
  
  CELCompiler({cel.Environment? env}) 
    : environment = env ?? _createDefaultEnvironment();

  /// Compile a set of Rules into CEL expressions
  List<CompiledExpression> compile(List<Rule> rules) {
    final compiled = <CompiledExpression>[];
    
    for (final rule in rules) {
      if (rule.hasExpression()) {
        try {
          final expr = _compileExpression(rule);
          if (expr != null) {
            compiled.add(expr);
          }
        } catch (e) {
          throw err.CompilationError(
            'Failed to compile CEL expression "${rule.expression}": $e',
          );
        }
      }
    }
    
    return compiled;
  }

  CompiledExpression? _compileExpression(Rule rule) {
    final expression = rule.expression;
    if (expression.isEmpty) {
      return null;
    }

    // Parse and compile the CEL expression
    final ast = environment.compile(expression);
    final program = environment.makeProgram(ast);

    return CompiledExpression(
      program: program,
      source: rule,
      message: rule.hasMessage() ? rule.message : null,
      id: rule.hasId() ? rule.id : null,
    );
  }

  static cel.Environment _createDefaultEnvironment() {
    // Create a CEL environment with protobuf support
    // This will be enhanced as we add more CEL functions
    return cel.Environment.standard();
  }
}

/// Message-level CEL evaluator
class MessageCELEvaluator extends MessageEvaluator {
  final List<CompiledExpression> expressions;

  MessageCELEvaluator({required this.expressions});

  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value is! GeneratedMessage) return;
    evaluateMessage(value, cursor);
  }
  
  @override
  void evaluateMessage(GeneratedMessage message, Cursor cursor) {
    for (final expr in expressions) {
      expr.evaluate(message, cursor);
    }
  }

  @override
  bool get tautology => expressions.isEmpty;
}

/// Field-level CEL evaluator wrapper
class FieldCELEvaluator extends FieldEvaluator {
  final CELEvaluator celEvaluator;
  final FieldDescriptorProto fieldDescriptor;

  FieldCELEvaluator({
    required this.celEvaluator,
    required this.fieldDescriptor,
    required FieldInfo fieldInfo,
  }) : super(fieldInfo);

  @override
  void evaluateField(dynamic value, Cursor cursor) {
    if (value is! GeneratedMessage) return;
    final fieldNumber = fieldDescriptor.number;
    final fieldValue = value.getField(fieldNumber);
    
    if (fieldValue != null) {
      final fieldCursor = cursor.field(fieldInfo);
      celEvaluator.evaluate(fieldValue, fieldCursor);
    }
  }

  @override
  bool get tautology => celEvaluator.tautology;
}