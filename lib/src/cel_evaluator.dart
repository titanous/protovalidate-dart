import 'package:cel/cel.dart' as cel;
import 'package:protobuf/protobuf.dart';

import 'evaluator.dart';
import 'cursor.dart';
import 'error.dart' as err;
import 'gen/buf/validate/validate.pb.dart';
import 'gen/google/protobuf/descriptor.pb.dart';
import 'gen/google/protobuf/timestamp.pb.dart';
import 'cel/protovalidate_library.dart';
import 'rule_paths.dart';

/// CEL evaluator for custom expression rules
class CELEvaluator implements Evaluator {
  final List<CompiledExpression> expressions;
  final FieldDescriptorProto? fieldDescriptor;

  CELEvaluator({
    required this.expressions,
    this.fieldDescriptor,
  });

  @override
  void evaluate(dynamic value, Cursor cursor) {
    for (final expr in expressions) {
      expr.evaluate(value, cursor);
    }
  }

  bool get tautology => expressions.isEmpty;
}

/// A compiled CEL expression ready for evaluation
class CompiledExpression {
  final cel.Program program;
  final Rule source;
  final String? message;
  final String? id;
  final int celIndex;

  CompiledExpression({
    required this.program,
    required this.source,
    this.message,
    this.id,
    required this.celIndex,
  });

  void evaluate(dynamic value, Cursor cursor) {
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
      } else if (result is Exception) {
        // CEL evaluation error
        cursor.violate(
          message: 'CEL evaluation error: ${result.toString()}',
          constraintId: 'cel.error',
        );
      } else {
        // Unexpected result type
        cursor.violate(
          message: 'CEL expression must return a boolean, got: ${result.runtimeType}',
          constraintId: 'cel.type_error',
        );
      }
    } catch (e) {
      // Runtime error during evaluation
      cursor.violate(
        message: 'CEL evaluation failed: $e',
        constraintId: 'cel.runtime_error',
      );
    }
  }

  Map<String, dynamic> _createActivation(dynamic value, Cursor cursor) {
    final activation = <String, dynamic>{};
    
    // Add 'this' - the current value being validated
    activation['this'] = value;
    
    // Add 'now' - current timestamp
    activation['now'] = Timestamp.fromDateTime(DateTime.now());
    
    // Add 'rules' - the validation rules (if available)
    // This is typically the entire rules structure for the field
    // It's used for cross-referencing other rules in CEL expressions
    if (source.hasMessage()) {
      activation['rules'] = source;
    }
    
    // Add 'rule' - the current rule being evaluated
    activation['rule'] = source;
    
    return activation;
  }

  void _addViolation(Cursor cursor, dynamic value) {
    final violationMessage = message ?? 
        'value must satisfy CEL expression \'${source.expression}\'';
    
    cursor.violate(
      constraintId: id ?? 'cel.expression',
      message: violationMessage,
      rulePath: RulePathBuilder.celConstraint(celIndex),
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
    
    for (int i = 0; i < rules.length; i++) {
      final rule = rules[i];
      if (rule.hasExpression()) {
        try {
          final expr = _compileExpression(rule, i);
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

  CompiledExpression? _compileExpression(Rule rule, int index) {
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
      celIndex: index,
    );
  }

  static cel.Environment _createDefaultEnvironment() {
    // Create a CEL environment with protobuf support and validation functions
    final env = cel.Environment.standard();
    
    // Apply the ProtovalidateLibrary to add custom validation functions
    final library = ProtovalidateLibrary();
    library.toEnvironmentOption()(env);
    
    return env;
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

  bool get tautology => celEvaluator.tautology;
}