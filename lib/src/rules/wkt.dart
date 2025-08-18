import 'package:protobuf/protobuf.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';
import 'package:protovalidate/src/gen/google/protobuf/duration.pb.dart'
    as pb_duration;
import 'package:protovalidate/src/gen/google/protobuf/timestamp.pb.dart'
    as pb_timestamp;
import 'package:protovalidate/src/gen/google/protobuf/any.pb.dart' as pb_any;
import 'package:protovalidate/src/gen/google/protobuf/wrappers.pb.dart';
import '../evaluator.dart';
import '../cursor.dart';
import '../rule_paths.dart';
import 'scalar.dart';

/// Evaluator for Duration well-known type validation.
class DurationEvaluator implements Evaluator {
  final DurationRules rules;

  DurationEvaluator({required this.rules});

  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) {
      return;
    }

    if (value is! pb_duration.Duration) {
      cursor.violate(
        message: 'expected google.protobuf.Duration',
        constraintId: 'duration.type',
      );
      return;
    }

    final durationNanos = _durationToNanos(value);

    // Handle const rule
    if (rules.hasConst_2()) {
      final constNanos = _durationToNanos(rules.const_2);
      if (durationNanos != constNanos) {
        cursor.violate(
          message: 'value must equal ${_formatDuration(rules.const_2)}',
          constraintId: 'duration.const',
          rulePath: RulePathBuilder.durationConstraint('const'),
        );
      }
    }

    // Handle exclusive range combinations first
    if (rules.hasGt() && rules.hasLt()) {
      final gtNanos = _durationToNanos(rules.gt);
      final ltNanos = _durationToNanos(rules.lt);
      
      // Check for exclusive range (value must be > gt OR < lt)
      if (gtNanos >= ltNanos) {
        // This is an exclusive range: value must be > gt OR < lt
        if (durationNanos <= gtNanos && durationNanos >= ltNanos) {
          cursor.violate(
            message: 'value must be greater than ${_formatDuration(rules.gt)} or less than ${_formatDuration(rules.lt)}',
            constraintId: 'duration.gt_lt_exclusive',
            rulePath: RulePathBuilder.durationConstraint('gt'),
          );
          return; // Don't check individual constraints
        }
      } else {
        // This is an inclusive range: value must be > gt AND < lt
        if (durationNanos <= gtNanos || durationNanos >= ltNanos) {
          cursor.violate(
            message: 'value must be greater than ${_formatDuration(rules.gt)} and less than ${_formatDuration(rules.lt)}',
            constraintId: 'duration.gt_lt',
            rulePath: RulePathBuilder.durationConstraint('gt'),
          );
          return; // Don't check individual constraints
        }
      }
    }
    
    if (rules.hasGte() && rules.hasLte()) {
      final gteNanos = _durationToNanos(rules.gte);
      final lteNanos = _durationToNanos(rules.lte);
      
      // Check for exclusive range (value must be >= gte OR <= lte)
      if (gteNanos > lteNanos) {
        // This is an exclusive range: value must be >= gte OR <= lte
        if (durationNanos < gteNanos && durationNanos > lteNanos) {
          cursor.violate(
            message: 'value must be greater than or equal to ${_formatDuration(rules.gte)} or less than or equal to ${_formatDuration(rules.lte)}',
            constraintId: 'duration.gte_lte_exclusive',
            rulePath: RulePathBuilder.durationConstraint('gte'),
          );
          return; // Don't check individual constraints
        }
      } else {
        // This is an inclusive range: value must be >= gte AND <= lte
        if (durationNanos < gteNanos || durationNanos > lteNanos) {
          cursor.violate(
            message: 'value must be greater than or equal to ${_formatDuration(rules.gte)} and less than or equal to ${_formatDuration(rules.lte)}',
            constraintId: 'duration.gte_lte',
            rulePath: RulePathBuilder.durationConstraint('gte'),
          );
          return; // Don't check individual constraints
        }
      }
    }

    // Handle individual lt/lte/gt/gte rules (only if no combination was handled above)
    if (rules.hasLt() && !rules.hasGt()) {
      final ltNanos = _durationToNanos(rules.lt);
      if (durationNanos >= ltNanos) {
        cursor.violate(
          message: '',
          constraintId: 'duration.lt',
          rulePath: RulePathBuilder.durationConstraint('lt'),
        );
      }
    }

    if (rules.hasLte() && !rules.hasGte()) {
      final lteNanos = _durationToNanos(rules.lte);
      if (durationNanos > lteNanos) {
        cursor.violate(
          message: '',
          constraintId: 'duration.lte',
          rulePath: RulePathBuilder.durationConstraint('lte'),
        );
      }
    }

    if (rules.hasGt() && !rules.hasLt()) {
      final gtNanos = _durationToNanos(rules.gt);
      if (durationNanos <= gtNanos) {
        cursor.violate(
          message: '',
          constraintId: 'duration.gt',
          rulePath: RulePathBuilder.durationConstraint('gt'),
        );
      }
    }

    if (rules.hasGte() && !rules.hasLte()) {
      final gteNanos = _durationToNanos(rules.gte);
      if (durationNanos < gteNanos) {
        cursor.violate(
          message: '',
          constraintId: 'duration.gte',
          rulePath: RulePathBuilder.durationConstraint('gte'),
        );
      }
    }

    // Handle in/not_in rules
    if (rules.in_7.isNotEmpty) {
      final inSet = rules.in_7.map(_durationToNanos).toSet();
      if (!inSet.contains(durationNanos)) {
        cursor.violate(
          message: '',
          constraintId: 'duration.in',
          rulePath: RulePathBuilder.durationConstraint('in'),
        );
      }
    }

    if (rules.notIn.isNotEmpty) {
      final notInSet = rules.notIn.map(_durationToNanos).toSet();
      if (notInSet.contains(durationNanos)) {
        cursor.violate(
          message: '',
          constraintId: 'duration.not_in',
          rulePath: RulePathBuilder.durationConstraint('not_in'),
        );
      }
    }
  }

  /// Formats a Duration for display in error messages.
  String _formatDuration(pb_duration.Duration duration) {
    if (duration.nanos == 0) {
      return '${duration.seconds}s';
    } else {
      return '${duration.seconds}s ${duration.nanos}ns';
    }
  }

  /// Converts a Duration to total nanoseconds.
  Int64 _durationToNanos(pb_duration.Duration duration) {
    return duration.seconds * Int64(1000000000) + Int64(duration.nanos);
  }
}

/// Evaluator for Timestamp well-known type validation.
class TimestampEvaluator implements Evaluator {
  final TimestampRules rules;

  TimestampEvaluator({required this.rules});

  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) {
      return;
    }

    if (value is! pb_timestamp.Timestamp) {
      cursor.violate(
        message: 'expected google.protobuf.Timestamp',
        constraintId: 'timestamp.type',
      );
      return;
    }

    final timestampNanos = _timestampToNanos(value);

    // Handle const rule
    if (rules.hasConst_2()) {
      final constNanos = _timestampToNanos(rules.const_2);
      if (timestampNanos != constNanos) {
        cursor.violate(
          message: '',
          constraintId: 'timestamp.const',
          rulePath: RulePathBuilder.timestampConstraint('const'),
        );
      }
    }

    // Handle combined gte/lte constraints first
    if (rules.hasGte() && rules.hasLte()) {
      final gteNanos = _timestampToNanos(rules.gte);
      final lteNanos = _timestampToNanos(rules.lte);
      
      if (lteNanos < gteNanos) {
        // Exclusive range: lte < gte, value must be outside [lte, gte]
        // Invalid if: lte < value < gte
        if (lteNanos < timestampNanos && timestampNanos < gteNanos) {
          cursor.violate(
            message: '',
            constraintId: 'timestamp.gte_lte_exclusive',
            rulePath: RulePathBuilder.timestampConstraint('gte'),
          );
          return;
        }
      } else {
        // Normal range: lte >= gte, check individual violations
        // Invalid if: value < gte OR value > lte
        if (timestampNanos < gteNanos || timestampNanos > lteNanos) {
          cursor.violate(
            message: '',
            constraintId: 'timestamp.gte_lte',
            rulePath: RulePathBuilder.timestampConstraint('gte'),
          );
          return;
        }
      }
    }

    // Handle combined gt/lt constraints
    if (rules.hasGt() && rules.hasLt()) {
      final gtNanos = _timestampToNanos(rules.gt);
      final ltNanos = _timestampToNanos(rules.lt);
      
      if (ltNanos < gtNanos) {
        // Exclusive range: lt < gt, value must be outside [lt, gt]
        // Invalid if: lt <= value <= gt
        if (ltNanos <= timestampNanos && timestampNanos <= gtNanos) {
          cursor.violate(
            message: '',
            constraintId: 'timestamp.gt_lt_exclusive',
            rulePath: RulePathBuilder.timestampConstraint('gt'),
          );
          return;
        }
      } else {
        // Normal range: lt >= gt, check individual violations  
        // Invalid if: value <= gt OR value >= lt
        if (timestampNanos <= gtNanos || timestampNanos >= ltNanos) {
          cursor.violate(
            message: '',
            constraintId: 'timestamp.gt_lt',
            rulePath: RulePathBuilder.timestampConstraint('gt'),
          );
          return;
        }
      }
    }

    // Handle individual constraints (only if not part of combined constraints)
    if (rules.hasLt() && !rules.hasGt() && timestampNanos >= _timestampToNanos(rules.lt)) {
      cursor.violate(
        message: '',
        constraintId: 'timestamp.lt',
        rulePath: RulePathBuilder.timestampConstraint('lt'),
      );
    }

    if (rules.hasLte() && !rules.hasGte() && timestampNanos > _timestampToNanos(rules.lte)) {
      cursor.violate(
        message: '',
        constraintId: 'timestamp.lte',
        rulePath: RulePathBuilder.timestampConstraint('lte'),
      );
    }

    if (rules.hasGt() && !rules.hasLt() && timestampNanos <= _timestampToNanos(rules.gt)) {
      cursor.violate(
        message: '',
        constraintId: 'timestamp.gt',
        rulePath: RulePathBuilder.timestampConstraint('gt'),
      );
    }

    if (rules.hasGte() && !rules.hasLte() && timestampNanos < _timestampToNanos(rules.gte)) {
      cursor.violate(
        message: '',
        constraintId: 'timestamp.gte',
        rulePath: RulePathBuilder.timestampConstraint('gte'),
      );
    }

    // Handle lt_now/gt_now rules
    if (rules.hasLtNow() && rules.ltNow) {
      final nowNanos = _nowNanos();
      if (timestampNanos >= nowNanos) {
        cursor.violate(
          message: '',
          constraintId: 'timestamp.lt_now',
          rulePath: RulePathBuilder.timestampConstraint('lt_now'),
        );
      }
    }

    if (rules.hasGtNow() && rules.gtNow) {
      final nowNanos = _nowNanos();
      if (timestampNanos <= nowNanos) {
        cursor.violate(
          message: '',
          constraintId: 'timestamp.gt_now',
          rulePath: RulePathBuilder.timestampConstraint('gt_now'),
        );
      }
    }

    // Handle within rule
    if (rules.hasWithin()) {
      final nowNanos = _nowNanos();
      final withinNanos = _durationToNanos(rules.within);
      final diff = (timestampNanos - nowNanos).abs();
      if (diff > withinNanos) {
        cursor.violate(
          message: '',
          constraintId: 'timestamp.within',
          rulePath: RulePathBuilder.timestampConstraint('within'),
        );
      }
    }
  }

  /// Converts a Timestamp to total nanoseconds since Unix epoch.
  Int64 _timestampToNanos(pb_timestamp.Timestamp timestamp) {
    return timestamp.seconds * Int64(1000000000) + Int64(timestamp.nanos);
  }

  /// Converts a Duration to total nanoseconds.
  Int64 _durationToNanos(pb_duration.Duration duration) {
    return duration.seconds * Int64(1000000000) + Int64(duration.nanos);
  }

  /// Gets the current time in nanoseconds since Unix epoch.
  Int64 _nowNanos() {
    final now = DateTime.now();
    final micros = now.microsecondsSinceEpoch;
    return Int64(micros) * Int64(1000);
  }
}

/// Evaluator for Any well-known type validation.
class AnyEvaluator implements Evaluator {
  final AnyRules rules;

  AnyEvaluator({required this.rules});

  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) {
      return;
    }

    if (value is! pb_any.Any) {
      cursor.violate(
        message: 'expected google.protobuf.Any',
        constraintId: 'any.type',
      );
      return;
    }

    final typeUrl = value.typeUrl;

    // Handle in rule
    if (rules.in_2.isNotEmpty) {
      if (!rules.in_2.contains(typeUrl)) {
        cursor.violate(
          message: 'type URL must be in the allow list',
          constraintId: 'any.in',
          rulePath: RulePathBuilder.anyConstraint('in'),
        );
      }
    }

    // Handle not_in rule
    if (rules.notIn.isNotEmpty) {
      if (rules.notIn.contains(typeUrl)) {
        cursor.violate(
          message: 'type URL must not be in the block list',
          constraintId: 'any.not_in',
          rulePath: RulePathBuilder.anyConstraint('not_in'),
        );
      }
    }
  }
}

/// Base evaluator for wrapper types.
abstract class WrapperEvaluator implements Evaluator {
  /// Unwraps the value from a wrapper message.
  dynamic unwrapValue(GeneratedMessage wrapper);

  /// Gets the underlying evaluator for the wrapped type.
  Evaluator getUnderlyingEvaluator();

  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) {
      // Null wrappers are allowed
      return;
    }

    if (value is! GeneratedMessage) {
      cursor.violate(
        message: 'expected wrapper type',
        constraintId: 'wrapper.type',
      );
      return;
    }

    // Unwrap the value and evaluate with underlying evaluator
    final unwrapped = unwrapValue(value);
    getUnderlyingEvaluator().evaluate(unwrapped, cursor);
  }
}

/// Evaluator for BoolValue wrapper.
class BoolValueEvaluator extends WrapperEvaluator {
  final BoolRules? rules;

  BoolValueEvaluator({this.rules});

  @override
  dynamic unwrapValue(GeneratedMessage wrapper) {
    return (wrapper as BoolValue).value;
  }

  @override
  Evaluator getUnderlyingEvaluator() {
    if (rules != null) {
      return BoolEvaluator(
        constValue: rules!.hasConst_1() ? rules!.const_1 : null,
      );
    }
    return NoOpEvaluator();
  }
}

/// Evaluator for BytesValue wrapper.
class BytesValueEvaluator extends WrapperEvaluator {
  final BytesRules? rules;

  BytesValueEvaluator({this.rules});

  @override
  dynamic unwrapValue(GeneratedMessage wrapper) {
    return (wrapper as BytesValue).value;
  }

  @override
  Evaluator getUnderlyingEvaluator() {
    if (rules != null) {
      return BytesEvaluator(
        constValue: rules!.hasConst_1() ? rules!.const_1 : null,
        len: rules!.hasLen() ? rules!.len.toInt() : null,
        minLen: rules!.hasMinLen() ? rules!.minLen.toInt() : null,
        maxLen: rules!.hasMaxLen() ? rules!.maxLen.toInt() : null,
        pattern: rules!.hasPattern() ? rules!.pattern : null,
        prefix: rules!.hasPrefix() ? rules!.prefix : null,
        suffix: rules!.hasSuffix() ? rules!.suffix : null,
        contains: rules!.hasContains() ? rules!.contains : null,
        inValues: rules!.in_8.isNotEmpty ? rules!.in_8 : null,
        notInValues: rules!.notIn.isNotEmpty ? rules!.notIn : null,
        ip: rules!.hasIp() ? rules!.ip : null,
        ipv4: rules!.hasIpv4() ? rules!.ipv4 : null,
        ipv6: rules!.hasIpv6() ? rules!.ipv6 : null,
      );
    }
    return NoOpEvaluator();
  }
}

/// Evaluator for DoubleValue wrapper.
class DoubleValueEvaluator extends WrapperEvaluator {
  final DoubleRules? rules;

  DoubleValueEvaluator({this.rules});

  @override
  dynamic unwrapValue(GeneratedMessage wrapper) {
    return (wrapper as DoubleValue).value;
  }

  @override
  Evaluator getUnderlyingEvaluator() {
    if (rules != null) {
      return DoubleEvaluator(
        constValue: rules!.hasConst_1() ? rules!.const_1 : null,
        lt: rules!.hasLt() ? rules!.lt : null,
        lte: rules!.hasLte() ? rules!.lte : null,
        gt: rules!.hasGt() ? rules!.gt : null,
        gte: rules!.hasGte() ? rules!.gte : null,
        inValues: rules!.in_6.isNotEmpty ? rules!.in_6 : null,
        notInValues: rules!.notIn.isNotEmpty ? rules!.notIn : null,
        finite: rules!.hasFinite() ? rules!.finite : null,
      );
    }
    return NoOpEvaluator();
  }
}

/// Evaluator for FloatValue wrapper.
class FloatValueEvaluator extends WrapperEvaluator {
  final FloatRules? rules;

  FloatValueEvaluator({this.rules});

  @override
  dynamic unwrapValue(GeneratedMessage wrapper) {
    return (wrapper as FloatValue).value;
  }

  @override
  Evaluator getUnderlyingEvaluator() {
    if (rules != null) {
      return FloatEvaluator(
        constValue: rules!.hasConst_1() ? rules!.const_1 : null,
        lt: rules!.hasLt() ? rules!.lt : null,
        lte: rules!.hasLte() ? rules!.lte : null,
        gt: rules!.hasGt() ? rules!.gt : null,
        gte: rules!.hasGte() ? rules!.gte : null,
        inValues: rules!.in_6.isNotEmpty ? rules!.in_6 : null,
        notInValues: rules!.notIn.isNotEmpty ? rules!.notIn : null,
        finite: rules!.hasFinite() ? rules!.finite : null,
      );
    }
    return NoOpEvaluator();
  }
}

/// Evaluator for Int32Value wrapper.
class Int32ValueEvaluator extends WrapperEvaluator {
  final Int32Rules? rules;

  Int32ValueEvaluator({this.rules});

  @override
  dynamic unwrapValue(GeneratedMessage wrapper) {
    return (wrapper as Int32Value).value;
  }

  @override
  Evaluator getUnderlyingEvaluator() {
    if (rules != null) {
      return Int32Evaluator(
        constValue: rules!.hasConst_1() ? rules!.const_1 : null,
        lt: rules!.hasLt() ? rules!.lt : null,
        lte: rules!.hasLte() ? rules!.lte : null,
        gt: rules!.hasGt() ? rules!.gt : null,
        gte: rules!.hasGte() ? rules!.gte : null,
        inValues: rules!.in_6.isNotEmpty ? rules!.in_6 : null,
        notInValues: rules!.notIn.isNotEmpty ? rules!.notIn : null,
      );
    }
    return NoOpEvaluator();
  }
}

/// Evaluator for Int64Value wrapper.
class Int64ValueEvaluator extends WrapperEvaluator {
  final Int64Rules? rules;

  Int64ValueEvaluator({this.rules});

  @override
  dynamic unwrapValue(GeneratedMessage wrapper) {
    return (wrapper as Int64Value).value;
  }

  @override
  Evaluator getUnderlyingEvaluator() {
    if (rules != null) {
      return Int64Evaluator(
        constValue: rules!.hasConst_1() ? rules!.const_1 : null,
        lt: rules!.hasLt() ? rules!.lt : null,
        lte: rules!.hasLte() ? rules!.lte : null,
        gt: rules!.hasGt() ? rules!.gt : null,
        gte: rules!.hasGte() ? rules!.gte : null,
        inValues: rules!.in_6.isNotEmpty ? rules!.in_6 : null,
        notInValues: rules!.notIn.isNotEmpty ? rules!.notIn : null,
      );
    }
    return NoOpEvaluator();
  }
}

/// Evaluator for StringValue wrapper.
class StringValueEvaluator extends WrapperEvaluator {
  final StringRules? rules;

  StringValueEvaluator({this.rules});

  @override
  dynamic unwrapValue(GeneratedMessage wrapper) {
    return (wrapper as StringValue).value;
  }

  @override
  Evaluator getUnderlyingEvaluator() {
    if (rules != null) {
      return StringRulesEvaluator(
        constValue: rules!.hasConst_1() ? rules!.const_1 : null,
        len: rules!.hasLen() ? rules!.len.toInt() : null,
        minLen: rules!.hasMinLen() ? rules!.minLen.toInt() : null,
        maxLen: rules!.hasMaxLen() ? rules!.maxLen.toInt() : null,
        minBytes: rules!.hasMinBytes() ? rules!.minBytes.toInt() : null,
        maxBytes: rules!.hasMaxBytes() ? rules!.maxBytes.toInt() : null,
        pattern: rules!.hasPattern() ? rules!.pattern : null,
        prefix: rules!.hasPrefix() ? rules!.prefix : null,
        suffix: rules!.hasSuffix() ? rules!.suffix : null,
        contains: rules!.hasContains() ? rules!.contains : null,
        notContains: rules!.hasNotContains() ? rules!.notContains : null,
        inValues: rules!.in_10.isNotEmpty ? rules!.in_10 : null,
        notInValues: rules!.notIn.isNotEmpty ? rules!.notIn : null,
        email: rules!.hasEmail() ? rules!.email : null,
        hostname: rules!.hasHostname() ? rules!.hostname : null,
        ip: rules!.hasIp() ? rules!.ip : null,
        ipv4: rules!.hasIpv4() ? rules!.ipv4 : null,
        ipv6: rules!.hasIpv6() ? rules!.ipv6 : null,
        uri: rules!.hasUri() ? rules!.uri : null,
        uriRef: rules!.hasUriRef() ? rules!.uriRef : null,
        address: rules!.hasAddress() ? rules!.address : null,
        uuid: rules!.hasUuid() ? rules!.uuid : null,
        wellKnownRegex:
            rules!.hasWellKnownRegex() ? rules!.wellKnownRegex : null,
      );
    }
    return NoOpEvaluator();
  }
}

/// Evaluator for UInt32Value wrapper.
class UInt32ValueEvaluator extends WrapperEvaluator {
  final UInt32Rules? rules;

  UInt32ValueEvaluator({this.rules});

  @override
  dynamic unwrapValue(GeneratedMessage wrapper) {
    return (wrapper as UInt32Value).value;
  }

  @override
  Evaluator getUnderlyingEvaluator() {
    if (rules != null) {
      return UInt32Evaluator(
        constValue: rules!.hasConst_1() ? rules!.const_1 : null,
        lt: rules!.hasLt() ? rules!.lt : null,
        lte: rules!.hasLte() ? rules!.lte : null,
        gt: rules!.hasGt() ? rules!.gt : null,
        gte: rules!.hasGte() ? rules!.gte : null,
        inValues: rules!.in_6.isNotEmpty ? rules!.in_6 : null,
        notInValues: rules!.notIn.isNotEmpty ? rules!.notIn : null,
      );
    }
    return NoOpEvaluator();
  }
}

/// Evaluator for UInt64Value wrapper.
class UInt64ValueEvaluator extends WrapperEvaluator {
  final UInt64Rules? rules;

  UInt64ValueEvaluator({this.rules});

  @override
  dynamic unwrapValue(GeneratedMessage wrapper) {
    return (wrapper as UInt64Value).value;
  }

  @override
  Evaluator getUnderlyingEvaluator() {
    if (rules != null) {
      return UInt64Evaluator(
        constValue: rules!.hasConst_1() ? rules!.const_1 : null,
        lt: rules!.hasLt() ? rules!.lt : null,
        lte: rules!.hasLte() ? rules!.lte : null,
        gt: rules!.hasGt() ? rules!.gt : null,
        gte: rules!.hasGte() ? rules!.gte : null,
        inValues: rules!.in_6.isNotEmpty ? rules!.in_6 : null,
        notInValues: rules!.notIn.isNotEmpty ? rules!.notIn : null,
      );
    }
    return NoOpEvaluator();
  }
}

/// No-op evaluator that does nothing.
class NoOpEvaluator implements Evaluator {
  @override
  void evaluate(dynamic value, Cursor cursor) {
    // Do nothing
  }
}

/// Evaluator for Google protobuf wrapper types that delegates to scalar evaluators.
/// These evaluators extract the .value field from wrapper types and delegate validation
/// to the appropriate scalar evaluator.

/// Wrapper evaluator for BoolValue.
class BoolWrapperEvaluator implements Evaluator {
  final Evaluator delegate;

  BoolWrapperEvaluator(this.delegate);

  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) {
      delegate.evaluate(null, cursor);
      return;
    }

    if (value is! BoolValue) {
      cursor.violate(
        message: 'Expected bool, got ${value.runtimeType}',
        constraintId: 'bool.type',
      );
      return;
    }

    // Extract the wrapped value and delegate to scalar evaluator
    delegate.evaluate(value.value, cursor);
  }
}

/// Wrapper evaluator for Int32Value.
class Int32WrapperEvaluator implements Evaluator {
  final Evaluator delegate;

  Int32WrapperEvaluator(this.delegate);

  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) {
      delegate.evaluate(null, cursor);
      return;
    }

    if (value is! Int32Value) {
      cursor.violate(
        message: 'Expected int32, got ${value.runtimeType}',
        constraintId: 'int32.type',
      );
      return;
    }

    delegate.evaluate(value.value, cursor);
  }
}

/// Wrapper evaluator for Int64Value.
class Int64WrapperEvaluator implements Evaluator {
  final Evaluator delegate;

  Int64WrapperEvaluator(this.delegate);

  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) {
      delegate.evaluate(null, cursor);
      return;
    }

    if (value is! Int64Value) {
      cursor.violate(
        message: 'Expected int64, got ${value.runtimeType}',
        constraintId: 'int64.type',
      );
      return;
    }

    delegate.evaluate(value.value, cursor);
  }
}

/// Wrapper evaluator for UInt32Value.
class UInt32WrapperEvaluator implements Evaluator {
  final Evaluator delegate;

  UInt32WrapperEvaluator(this.delegate);

  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) {
      delegate.evaluate(null, cursor);
      return;
    }

    if (value is! UInt32Value) {
      cursor.violate(
        message: 'Expected uint32, got ${value.runtimeType}',
        constraintId: 'uint32.type',
      );
      return;
    }

    delegate.evaluate(value.value, cursor);
  }
}

/// Wrapper evaluator for UInt64Value.
class UInt64WrapperEvaluator implements Evaluator {
  final Evaluator delegate;

  UInt64WrapperEvaluator(this.delegate);

  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) {
      delegate.evaluate(null, cursor);
      return;
    }

    if (value is! UInt64Value) {
      cursor.violate(
        message: 'Expected uint64, got ${value.runtimeType}',
        constraintId: 'uint64.type',
      );
      return;
    }

    delegate.evaluate(value.value, cursor);
  }
}

/// Wrapper evaluator for FloatValue.
class FloatWrapperEvaluator implements Evaluator {
  final Evaluator delegate;

  FloatWrapperEvaluator(this.delegate);

  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) {
      delegate.evaluate(null, cursor);
      return;
    }

    if (value is! FloatValue) {
      cursor.violate(
        message: 'Expected float, got ${value.runtimeType}',
        constraintId: 'float.type',
      );
      return;
    }

    delegate.evaluate(value.value, cursor);
  }
}

/// Wrapper evaluator for DoubleValue.
class DoubleWrapperEvaluator implements Evaluator {
  final Evaluator delegate;

  DoubleWrapperEvaluator(this.delegate);

  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) {
      delegate.evaluate(null, cursor);
      return;
    }

    if (value is! DoubleValue) {
      cursor.violate(
        message: 'Expected double, got ${value.runtimeType}',
        constraintId: 'double.type',
      );
      return;
    }

    delegate.evaluate(value.value, cursor);
  }
}

/// Wrapper evaluator for StringValue.
class StringWrapperEvaluator implements Evaluator {
  final Evaluator delegate;

  StringWrapperEvaluator(this.delegate);

  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) {
      delegate.evaluate(null, cursor);
      return;
    }

    if (value is! StringValue) {
      cursor.violate(
        message: 'Expected string, got ${value.runtimeType}',
        constraintId: 'string.type',
      );
      return;
    }

    delegate.evaluate(value.value, cursor);
  }
}

/// Wrapper evaluator for BytesValue.
class BytesWrapperEvaluator implements Evaluator {
  final Evaluator delegate;

  BytesWrapperEvaluator(this.delegate);

  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value == null) {
      delegate.evaluate(null, cursor);
      return;
    }

    if (value is! BytesValue) {
      cursor.violate(
        message: 'Expected bytes, got ${value.runtimeType}',
        constraintId: 'bytes.type',
      );
      return;
    }

    delegate.evaluate(value.value, cursor);
  }
}
