import '../cursor.dart';

/// Base interface for evaluating rules on a value.
/// Following the pattern from protovalidate-es for cleaner composition.
abstract class Eval<V> {
  /// Evaluates the rules for the given value.
  void eval(V val, Cursor cursor);

  /// Remove any dead code paths.
  /// Return true if this is now a no-op.
  bool prune();
}

/// The no-op evaluator.
class EvalNoop<T> implements Eval<T> {
  static final _instance = EvalNoop._();

  EvalNoop._();

  static EvalNoop<T> get<T>() => _instance as EvalNoop<T>;

  @override
  void eval(T val, Cursor cursor) {
    // No-op
  }

  @override
  bool prune() => true;
}

/// Evaluate many rules.
class EvalMany<T> implements Eval<T> {
  List<Eval<T>> _many;

  EvalMany(List<Eval<T>> evals) : _many = List.from(evals);

  void add(List<Eval<T>> evals) {
    _many.addAll(evals);
  }

  @override
  void eval(T val, Cursor cursor) {
    for (final e in _many) {
      e.eval(val, cursor);
      if (cursor.failFast && cursor.violated) {
        break;
      }
    }
  }

  @override
  bool prune() {
    _many = _many.where((e) => !e.prune()).toList();
    return _many.isEmpty;
  }
}

/// Evaluate all items in a list.
class EvalListItems<T> implements Eval<List<T>> {
  final Condition<T> condition;
  final Eval<T> pass;

  EvalListItems({
    required this.condition,
    required this.pass,
  });

  @override
  void eval(List<T> val, Cursor cursor) {
    for (int i = 0; i < val.length; i++) {
      final item = val[i];
      if (condition.check(item)) {
        pass.eval(item, cursor.listIndex(i));
        if (cursor.failFast && cursor.violated) {
          break;
        }
      }
    }
  }

  @override
  bool prune() {
    return pass.prune() || condition.never;
  }
}

/// Evaluate key and value of all entries in a map.
class EvalMapEntries<K, V> implements Eval<Map<K, V>> {
  final Condition<K> keyCondition;
  final Eval<K> keyEval;
  final Condition<V> valueCondition;
  final Eval<V> valueEval;

  EvalMapEntries({
    required this.keyCondition,
    required this.keyEval,
    required this.valueCondition,
    required this.valueEval,
  });

  @override
  void eval(Map<K, V> val, Cursor cursor) {
    if (keyCondition.never && valueCondition.never) {
      return;
    }

    for (final entry in val.entries) {
      final c = cursor.mapKey(entry.key);
      if (keyCondition.check(entry.key)) {
        keyEval.eval(entry.key, c);
        if (cursor.failFast && cursor.violated) {
          return;
        }
      }
      if (valueCondition.check(entry.value)) {
        valueEval.eval(entry.value, c);
        if (cursor.failFast && cursor.violated) {
          return;
        }
      }
    }
  }

  @override
  bool prune() {
    final key = keyEval.prune() || keyCondition.never;
    final value = valueEval.prune() || valueCondition.never;
    return key && value;
  }
}

/// Condition for filtering evaluations.
abstract class Condition<T> {
  /// Check if the condition passes for the given value.
  bool check(T value);

  /// True if this condition will never pass.
  bool get never;
}

/// Always pass condition.
class AlwaysCondition<T> implements Condition<T> {
  @override
  bool check(T value) => true;

  @override
  bool get never => false;
}

/// Never pass condition.
class NeverCondition<T> implements Condition<T> {
  @override
  bool check(T value) => false;

  @override
  bool get never => true;
}

/// Condition that checks if value is not null/empty.
class NotEmptyCondition<T> implements Condition<T> {
  @override
  bool check(T value) {
    if (value == null) return false;
    if (value is String) return value.isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }

  @override
  bool get never => false;
}

/// Eval that applies a simple validation function.
class EvalFunc<T> implements Eval<T> {
  final void Function(T value, Cursor cursor) func;
  bool _pruned = false;

  EvalFunc(this.func);

  @override
  void eval(T val, Cursor cursor) {
    if (!_pruned) {
      func(val, cursor);
    }
  }

  @override
  bool prune() {
    // Simple functions are never pruned unless explicitly marked
    return _pruned;
  }

  void markPruned() {
    _pruned = true;
  }
}
