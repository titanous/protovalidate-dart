import 'package:protobuf/protobuf.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';
import 'package:protovalidate/src/gen/google/protobuf/duration.pb.dart' as pb_duration;
import 'package:protovalidate/src/gen/google/protobuf/timestamp.pb.dart' as pb_timestamp;
import 'package:protovalidate/src/gen/google/protobuf/any.pb.dart' as pb_any;
import 'package:protovalidate/src/gen/google/protobuf/wrappers.pb.dart';
import '../evaluator.dart';
import '../cursor.dart';
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
          message: 'value must equal ${rules.const_2.seconds}s ${rules.const_2.nanos}ns',
          constraintId: 'duration.const',
        );
      }
    }
    
    // Handle lt/lte/gt/gte rules
    if (rules.hasLt()) {
      final ltNanos = _durationToNanos(rules.lt);
      if (durationNanos >= ltNanos) {
        cursor.violate(
          message: 'value must be less than ${rules.lt.seconds}s ${rules.lt.nanos}ns',
          constraintId: 'duration.lt',
        );
      }
    }
    
    if (rules.hasLte()) {
      final lteNanos = _durationToNanos(rules.lte);
      if (durationNanos > lteNanos) {
        cursor.violate(
          message: 'value must be less than or equal to ${rules.lte.seconds}s ${rules.lte.nanos}ns',
          constraintId: 'duration.lte',
        );
      }
    }
    
    if (rules.hasGt()) {
      final gtNanos = _durationToNanos(rules.gt);
      if (durationNanos <= gtNanos) {
        cursor.violate(
          message: 'value must be greater than ${rules.gt.seconds}s ${rules.gt.nanos}ns',
          constraintId: 'duration.gt',
        );
      }
    }
    
    if (rules.hasGte()) {
      final gteNanos = _durationToNanos(rules.gte);
      if (durationNanos < gteNanos) {
        cursor.violate(
          message: 'value must be greater than or equal to ${rules.gte.seconds}s ${rules.gte.nanos}ns',
          constraintId: 'duration.gte',
        );
      }
    }
    
    // Handle in/not_in rules
    if (rules.in_7.isNotEmpty) {
      final inSet = rules.in_7.map(_durationToNanos).toSet();
      if (!inSet.contains(durationNanos)) {
        cursor.violate(
          message: 'value must be in list',
          constraintId: 'duration.in',
        );
      }
    }
    
    if (rules.notIn.isNotEmpty) {
      final notInSet = rules.notIn.map(_durationToNanos).toSet();
      if (notInSet.contains(durationNanos)) {
        cursor.violate(
          message: 'value must not be in list',
          constraintId: 'duration.not_in',
        );
      }
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
          message: 'value must equal ${rules.const_2.seconds}s ${rules.const_2.nanos}ns',
          constraintId: 'timestamp.const',
        );
      }
    }
    
    // Handle lt/lte/gt/gte rules
    if (rules.hasLt()) {
      final ltNanos = _timestampToNanos(rules.lt);
      if (timestampNanos >= ltNanos) {
        cursor.violate(
          message: 'value must be less than ${rules.lt.seconds}s ${rules.lt.nanos}ns',
          constraintId: 'timestamp.lt',
        );
      }
    }
    
    if (rules.hasLte()) {
      final lteNanos = _timestampToNanos(rules.lte);
      if (timestampNanos > lteNanos) {
        cursor.violate(
          message: 'value must be less than or equal to ${rules.lte.seconds}s ${rules.lte.nanos}ns',
          constraintId: 'timestamp.lte',
        );
      }
    }
    
    if (rules.hasGt()) {
      final gtNanos = _timestampToNanos(rules.gt);
      if (timestampNanos <= gtNanos) {
        cursor.violate(
          message: 'value must be greater than ${rules.gt.seconds}s ${rules.gt.nanos}ns',
          constraintId: 'timestamp.gt',
        );
      }
    }
    
    if (rules.hasGte()) {
      final gteNanos = _timestampToNanos(rules.gte);
      if (timestampNanos < gteNanos) {
        cursor.violate(
          message: 'value must be greater than or equal to ${rules.gte.seconds}s ${rules.gte.nanos}ns',
          constraintId: 'timestamp.gte',
        );
      }
    }
    
    // Handle lt_now/gt_now rules
    if (rules.hasLtNow() && rules.ltNow) {
      final nowNanos = _nowNanos();
      if (timestampNanos >= nowNanos) {
        cursor.violate(
          message: 'value must be less than now',
          constraintId: 'timestamp.lt_now',
        );
      }
    }
    
    if (rules.hasGtNow() && rules.gtNow) {
      final nowNanos = _nowNanos();
      if (timestampNanos <= nowNanos) {
        cursor.violate(
          message: 'value must be greater than now',
          constraintId: 'timestamp.gt_now',
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
          message: 'value must be within ${rules.within.seconds}s ${rules.within.nanos}ns of now',
          constraintId: 'timestamp.within',
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
        );
      }
    }
    
    // Handle not_in rule
    if (rules.notIn.isNotEmpty) {
      if (rules.notIn.contains(typeUrl)) {
        cursor.violate(
          message: 'type URL must not be in the block list',
          constraintId: 'any.not_in',
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
        wellKnownRegex: rules!.hasWellKnownRegex() ? (rules!.wellKnownRegex.value > 0) : null,
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