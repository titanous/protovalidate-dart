import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';
import 'utils/zero_value_checker.dart';

/// Base condition interface for determining when to skip validation
abstract class IgnoreCondition<T> {
  /// Check if validation should be skipped for the given value
  bool shouldIgnore(T value);

  /// True if validation should always be skipped
  bool get alwaysIgnore;

  /// True if validation should never be skipped
  bool get neverIgnore;
}

/// Always ignore validation
class AlwaysIgnoreCondition<T> implements IgnoreCondition<T> {
  @override
  bool shouldIgnore(T value) => true;

  @override
  bool get alwaysIgnore => true;

  @override
  bool get neverIgnore => false;
}

/// Never ignore validation (always validate)
class NeverIgnoreCondition<T> implements IgnoreCondition<T> {
  @override
  bool shouldIgnore(T value) => false;

  @override
  bool get alwaysIgnore => false;

  @override
  bool get neverIgnore => true;
}

/// Ignore validation when value is zero/empty
class ZeroValueIgnoreCondition<T> implements IgnoreCondition<T> {
  @override
  bool shouldIgnore(T value) {
    return ZeroValueChecker.isZeroValue(value);
  }

  @override
  bool get alwaysIgnore => false;

  @override
  bool get neverIgnore => false;
}

/// Create appropriate ignore condition based on Ignore enum value
IgnoreCondition<T> createIgnoreCondition<T>(Ignore? ignore) {
  switch (ignore) {
    case Ignore.IGNORE_ALWAYS:
      return AlwaysIgnoreCondition<T>();
    case Ignore.IGNORE_IF_ZERO_VALUE:
      return ZeroValueIgnoreCondition<T>();
    case null:
    case Ignore.IGNORE_UNSPECIFIED:
    default:
      return NeverIgnoreCondition<T>();
  }
}
