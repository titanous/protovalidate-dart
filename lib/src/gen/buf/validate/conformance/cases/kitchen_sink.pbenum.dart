// This is a generated file - do not edit.
//
// Generated from buf/validate/conformance/cases/kitchen_sink.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

enum ComplexTestEnum implements $pb.ProtobufEnum {
  COMPLEX_TEST_ENUM_UNSPECIFIED(
      0, _omitEnumNames ? '' : 'COMPLEX_TEST_ENUM_UNSPECIFIED'),

  COMPLEX_TEST_ENUM_ONE(1, _omitEnumNames ? '' : 'COMPLEX_TEST_ENUM_ONE'),

  COMPLEX_TEST_ENUM_TWO(2, _omitEnumNames ? '' : 'COMPLEX_TEST_ENUM_TWO'),
  ;

  static final $core.Map<$core.int, ComplexTestEnum> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static ComplexTestEnum? valueOf($core.int value) => _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const ComplexTestEnum(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
