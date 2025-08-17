// This is a generated file - do not edit.
//
// Generated from buf/validate/conformance/cases/enums.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

enum TestEnum implements $pb.ProtobufEnum {
  TEST_ENUM_UNSPECIFIED(0, _omitEnumNames ? '' : 'TEST_ENUM_UNSPECIFIED'),

  TEST_ENUM_ONE(1, _omitEnumNames ? '' : 'TEST_ENUM_ONE'),

  TEST_ENUM_TWO(2, _omitEnumNames ? '' : 'TEST_ENUM_TWO'),
  ;

  static final $core.Map<$core.int, TestEnum> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static TestEnum? valueOf($core.int value) => _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const TestEnum(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

enum TestEnumAlias implements $pb.ProtobufEnum {
  TEST_ENUM_ALIAS_UNSPECIFIED(
      0, _omitEnumNames ? '' : 'TEST_ENUM_ALIAS_UNSPECIFIED'),

  TEST_ENUM_ALIAS_A(1, _omitEnumNames ? '' : 'TEST_ENUM_ALIAS_A'),

  TEST_ENUM_ALIAS_B(2, _omitEnumNames ? '' : 'TEST_ENUM_ALIAS_B'),

  TEST_ENUM_ALIAS_C(3, _omitEnumNames ? '' : 'TEST_ENUM_ALIAS_C'),
  ;

  static const TestEnumAlias TEST_ENUM_ALIAS_ALPHA = TEST_ENUM_ALIAS_A;
  static const TestEnumAlias TEST_ENUM_ALIAS_BETA = TEST_ENUM_ALIAS_B;
  static const TestEnumAlias TEST_ENUM_ALIAS_GAMMA = TEST_ENUM_ALIAS_C;

  static final $core.Map<$core.int, TestEnumAlias> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static TestEnumAlias? valueOf($core.int value) => _byValue[value];

  static TestEnumAlias? valueByName($core.String name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    switch (name) {
      case 'TEST_ENUM_ALIAS_ALPHA':
        return TEST_ENUM_ALIAS_A;
      case 'TEST_ENUM_ALIAS_BETA':
        return TEST_ENUM_ALIAS_B;
      case 'TEST_ENUM_ALIAS_GAMMA':
        return TEST_ENUM_ALIAS_C;
      default:
        return null;
    }
  }

  static const $core.List<TestEnumAlias> valuesWithAliases = <TestEnumAlias>[
    TEST_ENUM_ALIAS_UNSPECIFIED,
    TEST_ENUM_ALIAS_A,
    TEST_ENUM_ALIAS_B,
    TEST_ENUM_ALIAS_C,
    TEST_ENUM_ALIAS_ALPHA,
    TEST_ENUM_ALIAS_BETA,
    TEST_ENUM_ALIAS_GAMMA,
  ];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const TestEnumAlias(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
