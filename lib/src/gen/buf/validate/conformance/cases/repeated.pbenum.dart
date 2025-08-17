// This is a generated file - do not edit.
//
// Generated from buf/validate/conformance/cases/repeated.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

enum AnEnum implements $pb.ProtobufEnum {
  AN_ENUM_UNSPECIFIED(0, _omitEnumNames ? '' : 'AN_ENUM_UNSPECIFIED'),

  AN_ENUM_X(1, _omitEnumNames ? '' : 'AN_ENUM_X'),

  AN_ENUM_Y(2, _omitEnumNames ? '' : 'AN_ENUM_Y'),
  ;

  static final $core.Map<$core.int, AnEnum> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static AnEnum? valueOf($core.int value) => _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const AnEnum(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

enum RepeatedEmbeddedEnumIn_AnotherInEnum implements $pb.ProtobufEnum {
  ANOTHER_IN_ENUM_UNSPECIFIED(
      0, _omitEnumNames ? '' : 'ANOTHER_IN_ENUM_UNSPECIFIED'),

  ANOTHER_IN_ENUM_A(1, _omitEnumNames ? '' : 'ANOTHER_IN_ENUM_A'),

  ANOTHER_IN_ENUM_B(2, _omitEnumNames ? '' : 'ANOTHER_IN_ENUM_B'),
  ;

  static final $core.Map<$core.int, RepeatedEmbeddedEnumIn_AnotherInEnum>
      _byValue = $pb.ProtobufEnum.initByValue(values);
  static RepeatedEmbeddedEnumIn_AnotherInEnum? valueOf($core.int value) =>
      _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const RepeatedEmbeddedEnumIn_AnotherInEnum(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

enum RepeatedEmbeddedEnumNotIn_AnotherNotInEnum implements $pb.ProtobufEnum {
  ANOTHER_NOT_IN_ENUM_UNSPECIFIED(
      0, _omitEnumNames ? '' : 'ANOTHER_NOT_IN_ENUM_UNSPECIFIED'),

  ANOTHER_NOT_IN_ENUM_A(1, _omitEnumNames ? '' : 'ANOTHER_NOT_IN_ENUM_A'),

  ANOTHER_NOT_IN_ENUM_B(2, _omitEnumNames ? '' : 'ANOTHER_NOT_IN_ENUM_B'),
  ;

  static final $core.Map<$core.int, RepeatedEmbeddedEnumNotIn_AnotherNotInEnum>
      _byValue = $pb.ProtobufEnum.initByValue(values);
  static RepeatedEmbeddedEnumNotIn_AnotherNotInEnum? valueOf($core.int value) =>
      _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const RepeatedEmbeddedEnumNotIn_AnotherNotInEnum(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
