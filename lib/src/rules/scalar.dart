import 'package:fixnum/fixnum.dart';
import '../cursor.dart';
import '../evaluator.dart';

/// Evaluator for boolean field rules.
class BoolEvaluator implements Evaluator {
  final bool? constValue;
  
  BoolEvaluator({this.constValue});
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value is! bool) {
      cursor.violate(
        message: 'Expected bool, got ${value.runtimeType}',
        constraintId: 'bool.type',
      );
      return;
    }
    
    if (constValue != null && value != constValue) {
      cursor.violate(
        message: 'Value must be $constValue',
        constraintId: 'bool.const',
      );
    }
  }
}

/// Base evaluator for numeric field rules.
abstract class NumericEvaluator<T extends Comparable> implements Evaluator {
  final T? constValue;
  final T? lt;
  final T? lte;
  final T? gt;
  final T? gte;
  final List<T>? inValues;
  final List<T>? notInValues;
  
  NumericEvaluator({
    this.constValue,
    this.lt,
    this.lte,
    this.gt,
    this.gte,
    this.inValues,
    this.notInValues,
  });
  
  String get typeName;
  String get constraintPrefix;
  
  bool isValidType(dynamic value);
  T toTypedValue(dynamic value);
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (!isValidType(value)) {
      cursor.violate(
        message: 'Expected $typeName, got ${value.runtimeType}',
        constraintId: '$constraintPrefix.type',
      );
      return;
    }
    
    final typedValue = toTypedValue(value);
    
    // Check const
    if (constValue != null && typedValue != constValue) {
      cursor.violate(
        message: 'Value must be $constValue',
        constraintId: '$constraintPrefix.const',
      );
    }
    
    // Check lt
    if (lt != null && typedValue.compareTo(lt!) >= 0) {
      cursor.violate(
        message: 'Value must be less than $lt',
        constraintId: '$constraintPrefix.lt',
      );
    }
    
    // Check lte
    if (lte != null && typedValue.compareTo(lte!) > 0) {
      cursor.violate(
        message: 'Value must be less than or equal to $lte',
        constraintId: '$constraintPrefix.lte',
      );
    }
    
    // Check gt
    if (gt != null && typedValue.compareTo(gt!) <= 0) {
      cursor.violate(
        message: 'Value must be greater than $gt',
        constraintId: '$constraintPrefix.gt',
      );
    }
    
    // Check gte
    if (gte != null && typedValue.compareTo(gte!) < 0) {
      cursor.violate(
        message: 'Value must be greater than or equal to $gte',
        constraintId: '$constraintPrefix.gte',
      );
    }
    
    // Check in
    if (inValues != null && !inValues!.contains(typedValue)) {
      cursor.violate(
        message: 'Value must be one of $inValues',
        constraintId: '$constraintPrefix.in',
      );
    }
    
    // Check not_in
    if (notInValues != null && notInValues!.contains(typedValue)) {
      cursor.violate(
        message: 'Value must not be one of $notInValues',
        constraintId: '$constraintPrefix.not_in',
      );
    }
  }
}

/// Evaluator for int32 field rules.
class Int32Evaluator extends NumericEvaluator<int> {
  Int32Evaluator({
    super.constValue,
    super.lt,
    super.lte,
    super.gt,
    super.gte,
    super.inValues,
    super.notInValues,
  });
  
  @override
  String get typeName => 'int32';
  
  @override
  String get constraintPrefix => 'int32';
  
  @override
  bool isValidType(dynamic value) => value is int;
  
  @override
  int toTypedValue(dynamic value) => value as int;
}

/// Evaluator for int64 field rules.
class Int64Evaluator extends NumericEvaluator<Int64> {
  Int64Evaluator({
    Int64? constValue,
    Int64? lt,
    Int64? lte,
    Int64? gt,
    Int64? gte,
    List<Int64>? inValues,
    List<Int64>? notInValues,
  }) : super(
    constValue: constValue,
    lt: lt,
    lte: lte,
    gt: gt,
    gte: gte,
    inValues: inValues,
    notInValues: notInValues,
  );
  
  @override
  String get typeName => 'int64';
  
  @override
  String get constraintPrefix => 'int64';
  
  @override
  bool isValidType(dynamic value) => value is Int64;
  
  @override
  Int64 toTypedValue(dynamic value) => value as Int64;
}

/// Evaluator for uint32 field rules.
class UInt32Evaluator extends NumericEvaluator<int> {
  UInt32Evaluator({
    super.constValue,
    super.lt,
    super.lte,
    super.gt,
    super.gte,
    super.inValues,
    super.notInValues,
  });
  
  @override
  String get typeName => 'uint32';
  
  @override
  String get constraintPrefix => 'uint32';
  
  @override
  bool isValidType(dynamic value) => value is int && value >= 0;
  
  @override
  int toTypedValue(dynamic value) => value as int;
}

/// Evaluator for uint64 field rules.
class UInt64Evaluator extends NumericEvaluator<Int64> {
  UInt64Evaluator({
    Int64? constValue,
    Int64? lt,
    Int64? lte,
    Int64? gt,
    Int64? gte,
    List<Int64>? inValues,
    List<Int64>? notInValues,
  }) : super(
    constValue: constValue,
    lt: lt,
    lte: lte,
    gt: gt,
    gte: gte,
    inValues: inValues,
    notInValues: notInValues,
  );
  
  @override
  String get typeName => 'uint64';
  
  @override
  String get constraintPrefix => 'uint64';
  
  @override
  bool isValidType(dynamic value) => value is Int64 && !value.isNegative;
  
  @override
  Int64 toTypedValue(dynamic value) => value as Int64;
}

/// Evaluator for float field rules.
class FloatEvaluator extends NumericEvaluator<double> {
  final bool? finite;
  
  FloatEvaluator({
    super.constValue,
    super.lt,
    super.lte,
    super.gt,
    super.gte,
    super.inValues,
    super.notInValues,
    this.finite,
  });
  
  @override
  String get typeName => 'float';
  
  @override
  String get constraintPrefix => 'float';
  
  @override
  bool isValidType(dynamic value) => value is double;
  
  @override
  double toTypedValue(dynamic value) => value as double;
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    super.evaluate(value, cursor);
    
    if (!isValidType(value)) return;
    
    final floatValue = value as double;
    
    // Check finite
    if (finite == true && !floatValue.isFinite) {
      cursor.violate(
        message: 'Value must be finite',
        constraintId: 'float.finite',
      );
    }
  }
}

/// Evaluator for double field rules.
class DoubleEvaluator extends NumericEvaluator<double> {
  final bool? finite;
  
  DoubleEvaluator({
    super.constValue,
    super.lt,
    super.lte,
    super.gt,
    super.gte,
    super.inValues,
    super.notInValues,
    this.finite,
  });
  
  @override
  String get typeName => 'double';
  
  @override
  String get constraintPrefix => 'double';
  
  @override
  bool isValidType(dynamic value) => value is double;
  
  @override
  double toTypedValue(dynamic value) => value as double;
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    super.evaluate(value, cursor);
    
    if (!isValidType(value)) return;
    
    final doubleValue = value as double;
    
    // Check finite
    if (finite == true && !doubleValue.isFinite) {
      cursor.violate(
        message: 'Value must be finite',
        constraintId: 'double.finite',
      );
    }
  }
}