import 'package:cel/cel.dart' as cel;
import 'package:protobuf/protobuf.dart';
import '../error.dart';
import '../cursor.dart';
import '../gen/buf/validate/validate.pb.dart';
import '../gen/google/protobuf/timestamp.pb.dart';
import '../evaluator.dart';
import 'protovalidate_library.dart';

/// Simplified CEL manager that integrates with existing infrastructure
class SimpleCelManager {
  static SimpleCelManager? _instance;
  
  /// CEL environment with protovalidate functions
  final cel.Environment env;
  
  /// Cache of compiled programs by expression
  final Map<String, cel.Program> _programCache = {};
  
  SimpleCelManager._() : env = _createEnvironment();
  
  factory SimpleCelManager() {
    _instance ??= SimpleCelManager._();
    return _instance!;
  }
  
  /// Compile a CEL expression
  cel.Program compile(String expression) {
    // Check cache
    if (_programCache.containsKey(expression)) {
      return _programCache[expression]!;
    }
    
    // Compile new expression
    final ast = env.compile(expression);
    final program = env.makeProgram(ast);
    _programCache[expression] = program;
    return program;
  }
  
  /// Evaluate a compiled program with bindings
  dynamic evaluate(cel.Program program, Map<String, dynamic> bindings) {
    return program.evaluate(bindings);
  }
  
  static cel.Environment _createEnvironment() {
    // Create CEL environment with protovalidate functions
    final env = cel.Environment.standard();
    
    // Apply the ProtovalidateLibrary to add custom validation functions
    final library = ProtovalidateLibrary();
    library.toEnvironmentOption()(env);
    
    return env;
  }
}

/// Enhanced compiled expression with CEL manager integration
class ManagedCompiledExpression {
  final cel.Program program;
  final Rule source;
  final SimpleCelManager manager;
  
  ManagedCompiledExpression({
    required this.program,
    required this.source,
    required this.manager,
  });
  
  void evaluate(dynamic value, Cursor cursor) {
    try {
      // Create activation with standard variables
      final bindings = <String, dynamic>{
        'this': value,
        'now': Timestamp.fromDateTime(DateTime.now()),
      };
      
      // Add rules and rule if available
      if (source.hasMessage()) {
        bindings['rules'] = source;
      }
      bindings['rule'] = source;
      
      // Evaluate the CEL program
      final result = manager.evaluate(program, bindings);
      
      // Handle the result
      if (result is bool) {
        if (!result) {
          _addViolation(cursor);
        }
      } else if (result is String) {
        if (result.isNotEmpty) {
          _addViolation(cursor, customMessage: result);
        }
      } else if (result is Exception) {
        cursor.violate(
          message: 'CEL evaluation error: ${result.toString()}',
          constraintId: 'cel.error',
        );
      } else {
        cursor.violate(
          message: 'CEL expression must return a boolean or string, got: ${result.runtimeType}',
          constraintId: 'cel.type_error',
        );
      }
    } catch (e) {
      cursor.violate(
        message: 'CEL evaluation failed: $e',
        constraintId: 'cel.runtime_error',
      );
    }
  }
  
  void _addViolation(Cursor cursor, {String? customMessage}) {
    final message = source.message.isNotEmpty 
        ? source.message 
        : customMessage ?? 'value must satisfy CEL expression \'${source.expression}\'';
    
    cursor.violate(
      constraintId: source.id.isNotEmpty ? source.id : 'cel.expression',
      message: message,
    );
  }
}

/// Enhanced CEL compiler using the SimpleCelManager
class ManagedCELCompiler {
  final SimpleCelManager manager;
  
  ManagedCELCompiler() : manager = SimpleCelManager();
  
  /// Compile a set of Rules into managed expressions
  List<ManagedCompiledExpression> compile(List<Rule> rules) {
    final compiled = <ManagedCompiledExpression>[];
    
    for (final rule in rules) {
      if (rule.hasExpression() && rule.expression.isNotEmpty) {
        try {
          final program = manager.compile(rule.expression);
          compiled.add(ManagedCompiledExpression(
            program: program,
            source: rule,
            manager: manager,
          ));
        } catch (e) {
          throw CompilationError(
            'Failed to compile CEL expression "${rule.expression}": $e',
          );
        }
      }
    }
    
    return compiled;
  }
}

/// CEL evaluator using managed expressions
class ManagedCELEvaluator implements Evaluator {
  final List<ManagedCompiledExpression> expressions;
  
  ManagedCELEvaluator({required this.expressions});
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    for (final expr in expressions) {
      expr.evaluate(value, cursor);
      if (cursor.failFast && cursor.violated) {
        break;
      }
    }
  }
  
  bool get tautology => expressions.isEmpty;
}

/// Message-level CEL evaluator using managed expressions
class ManagedMessageCELEvaluator extends MessageEvaluator {
  final List<ManagedCompiledExpression> expressions;
  
  ManagedMessageCELEvaluator({required this.expressions});
  
  @override
  void evaluateMessage(GeneratedMessage message, Cursor cursor) {
    for (final expr in expressions) {
      expr.evaluate(message, cursor);
      if (cursor.failFast && cursor.violated) {
        break;
      }
    }
  }
  
  bool get tautology => expressions.isEmpty;
}