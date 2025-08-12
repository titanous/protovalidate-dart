import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart' as pb;
import 'package:protovalidate/src/gen/google/protobuf/descriptor.pbenum.dart';

/// Represents a field path through a protobuf message structure.
/// This implementation matches the reference Go/TypeScript implementations.
class FieldPath {
  final List<pb.FieldPathElement> _elements;
  
  FieldPath() : _elements = [];
  
  FieldPath._(List<pb.FieldPathElement> elements) : _elements = List.from(elements);
  
  /// Creates a copy of this path.
  FieldPath clone() => FieldPath._(_elements);
  
  /// Adds a field to the path.
  FieldPath field(FieldInfo field) {
    final newPath = clone();
    newPath._elements.add(_createFieldElement(field));
    return newPath;
  }
  
  /// Adds a list index to the current field path.
  /// This modifies the last field element to include the index.
  FieldPath listIndex(int index) {
    if (_elements.isEmpty) {
      throw StateError('Cannot add list index to empty field path');
    }
    
    final newPath = clone();
    final lastElement = newPath._elements.last;
    
    // Create a new element with the index
    newPath._elements[newPath._elements.length - 1] = pb.FieldPathElement()
      ..fieldNumber = lastElement.fieldNumber
      ..fieldName = lastElement.fieldName
      ..fieldType = lastElement.fieldType
      ..index = Int64(index);
      
    return newPath;
  }
  
  /// Adds a map key to the current field path.
  /// This modifies the last field element to include the key.
  FieldPath mapKey(dynamic key) {
    if (_elements.isEmpty) {
      throw StateError('Cannot add map key to empty field path');
    }
    
    final newPath = clone();
    final lastElement = newPath._elements.last;
    
    // Create a new element with the appropriate key
    final newElement = pb.FieldPathElement()
      ..fieldNumber = lastElement.fieldNumber
      ..fieldName = lastElement.fieldName
      ..fieldType = lastElement.fieldType;
    
    // Set the key value and keyType based on the key's type
    if (key is String) {
      newElement.stringKey = key;
      newElement.keyType = FieldDescriptorProto_Type.TYPE_STRING;
    } else if (key is bool) {
      newElement.boolKey = key;
      newElement.keyType = FieldDescriptorProto_Type.TYPE_BOOL;
    } else if (key is int) {
      newElement.intKey = Int64(key);
      newElement.keyType = FieldDescriptorProto_Type.TYPE_INT64;
    } else if (key is Int64) {
      newElement.intKey = key;
      newElement.keyType = FieldDescriptorProto_Type.TYPE_INT64;
    } else {
      // Convert to string as fallback
      newElement.stringKey = key.toString();
      newElement.keyType = FieldDescriptorProto_Type.TYPE_STRING;
    }
    
    // Set valueType - this is a basic assumption, ideally we'd have type info
    newElement.valueType = FieldDescriptorProto_Type.TYPE_STRING;
    
    newPath._elements[newPath._elements.length - 1] = newElement;
    return newPath;
  }
  
  /// Returns the string representation of this path.
  String toFieldPathString() {
    if (_elements.isEmpty) return '';
    
    final buffer = StringBuffer();
    for (var i = 0; i < _elements.length; i++) {
      final element = _elements[i];
      
      if (i > 0) {
        buffer.write('.');
      }
      
      buffer.write(element.fieldName);
      
      // Add subscript if present
      if (element.hasIndex()) {
        buffer.write('[${element.index}]');
      } else if (element.hasBoolKey()) {
        buffer.write('[${element.boolKey}]');
      } else if (element.hasIntKey()) {
        buffer.write('[${element.intKey}]');
      } else if (element.hasUintKey()) {
        buffer.write('[${element.uintKey}]');
      } else if (element.hasStringKey()) {
        buffer.write('["${element.stringKey}"]');
      }
    }
    return buffer.toString();
  }
  
  /// Converts this path to protobuf FieldPathElements.
  List<pb.FieldPathElement> toProtoElements() {
    return List.unmodifiable(_elements);
  }
  
  pb.FieldPathElement _createFieldElement(FieldInfo field) {
    final element = pb.FieldPathElement()
      ..fieldNumber = field.tagNumber
      ..fieldName = field.name;
    
    // Set field type based on FieldInfo type
    element.fieldType = _getFieldType(field);
    
    return element;
  }
  
  FieldDescriptorProto_Type _getFieldType(FieldInfo field) {
    // Map fields are special - they're TYPE_MESSAGE in protobuf
    if (field.isMapField) {
      return FieldDescriptorProto_Type.TYPE_MESSAGE;
    }
    
    // For packed fields, we need to extract the base type by removing the packed bit
    final baseType = field.type & ~0x4; // Remove PACKED_BIT (0x4)
    
    // Map PbFieldType to FieldDescriptorProto_Type
    // Note: O = optional, P = repeated, Q = required (proto2 only)
    if (baseType == PbFieldType.OB || baseType == PbFieldType.PB || baseType == PbFieldType.QB) {
      return FieldDescriptorProto_Type.TYPE_BOOL;
    } else if (baseType == PbFieldType.O3 || baseType == PbFieldType.P3 || baseType == PbFieldType.Q3) {
      return FieldDescriptorProto_Type.TYPE_INT32;
    } else if (baseType == PbFieldType.O6 || baseType == PbFieldType.P6 || baseType == PbFieldType.Q6) {
      return FieldDescriptorProto_Type.TYPE_INT64;
    } else if (baseType == PbFieldType.OU3 || baseType == PbFieldType.PU3 || baseType == PbFieldType.QU3) {
      return FieldDescriptorProto_Type.TYPE_UINT32;
    } else if (baseType == PbFieldType.OU6 || baseType == PbFieldType.PU6 || baseType == PbFieldType.QU6) {
      return FieldDescriptorProto_Type.TYPE_UINT64;
    } else if (baseType == PbFieldType.OS3 || baseType == PbFieldType.PS3 || baseType == PbFieldType.QS3) {
      return FieldDescriptorProto_Type.TYPE_SINT32;
    } else if (baseType == PbFieldType.OS6 || baseType == PbFieldType.PS6 || baseType == PbFieldType.QS6) {
      return FieldDescriptorProto_Type.TYPE_SINT64;
    } else if (baseType == PbFieldType.OSF3 || baseType == PbFieldType.PSF3 || baseType == PbFieldType.QSF3) {
      return FieldDescriptorProto_Type.TYPE_SFIXED32;
    } else if (baseType == PbFieldType.OSF6 || baseType == PbFieldType.PSF6 || baseType == PbFieldType.QSF6) {
      return FieldDescriptorProto_Type.TYPE_SFIXED64;
    } else if (baseType == PbFieldType.OF3 || baseType == PbFieldType.PF3 || baseType == PbFieldType.QF3) {
      return FieldDescriptorProto_Type.TYPE_FIXED32;
    } else if (baseType == PbFieldType.OF6 || baseType == PbFieldType.PF6 || baseType == PbFieldType.QF6) {
      return FieldDescriptorProto_Type.TYPE_FIXED64;
    } else if (baseType == PbFieldType.OF || baseType == PbFieldType.PF || baseType == PbFieldType.QF) {
      return FieldDescriptorProto_Type.TYPE_FLOAT;
    } else if (baseType == PbFieldType.OD || baseType == PbFieldType.PD || baseType == PbFieldType.QD) {
      return FieldDescriptorProto_Type.TYPE_DOUBLE;
    } else if (baseType == PbFieldType.OS || baseType == PbFieldType.PS || baseType == PbFieldType.QS) {
      return FieldDescriptorProto_Type.TYPE_STRING;
    } else if (baseType == PbFieldType.OY || baseType == PbFieldType.PY || baseType == PbFieldType.QY) {
      return FieldDescriptorProto_Type.TYPE_BYTES;
    } else if (baseType == PbFieldType.OE || baseType == PbFieldType.PE || baseType == PbFieldType.QE) {
      return FieldDescriptorProto_Type.TYPE_ENUM;
    } else if (baseType == PbFieldType.OM || baseType == PbFieldType.PM || baseType == PbFieldType.QM) {
      return FieldDescriptorProto_Type.TYPE_MESSAGE;
    } else if (field.isRepeated) {
      // For repeated fields, we need to check the value type
      // This is a fallback - ideally we'd have more type info
      return FieldDescriptorProto_Type.TYPE_MESSAGE;
    } else {
      // Default to string for unknown types
      return FieldDescriptorProto_Type.TYPE_STRING;
    }
  }
  
  @override
  String toString() => toFieldPathString();
}

/// A helper class for building rule paths following the protobuf schema hierarchy
class RulePath {
  final List<pb.FieldPathElement> _elements;
  
  RulePath() : _elements = [];
  
  RulePath._(List<pb.FieldPathElement> elements) : _elements = List.from(elements);
  
  /// Creates a copy of this path.
  RulePath clone() => RulePath._(_elements);
  
  /// Creates a rule path starting from FieldRules
  static RulePath fromFieldRules() {
    final rulePath = RulePath();
    // Note: FieldRules is the root, no element needed for it
    return rulePath;
  }
  
  /// Adds a specific rule type (e.g., "string", "int32", "repeated")
  RulePath ruleType(String typeName, int fieldNumber) {
    final newPath = clone();
    newPath._elements.add(pb.FieldPathElement()
      ..fieldNumber = fieldNumber
      ..fieldName = typeName
      ..fieldType = FieldDescriptorProto_Type.TYPE_MESSAGE);
    return newPath;
  }
  
  /// Adds a specific rule constraint (e.g., "const", "min_len")
  RulePath constraint(String constraintName, int fieldNumber, FieldDescriptorProto_Type fieldType) {
    final newPath = clone();
    newPath._elements.add(pb.FieldPathElement()
      ..fieldNumber = fieldNumber
      ..fieldName = constraintName
      ..fieldType = fieldType);
    return newPath;
  }
  
  /// Adds a predefined extension rule (with field number 1161)
  RulePath predefinedExtension(String extensionName) {
    final newPath = clone();
    // Predefined extensions use field number 1161
    newPath._elements.add(pb.FieldPathElement()
      ..fieldNumber = 1161
      ..fieldName = '[buf.validate.conformance.cases.$extensionName]'
      ..fieldType = FieldDescriptorProto_Type.TYPE_BOOL);
    return newPath;
  }
  
  /// Helper to append a RulePathElement to this path
  RulePath append(RulePathElement element) {
    final newPath = clone();
    newPath._elements.add(element.toProto());
    return newPath;
  }
  
  /// Helper to append all elements from another RulePath
  RulePath appendPath(RulePath other) {
    final newPath = clone();
    newPath._elements.addAll(other.toProtoElements());
    return newPath;
  }
  
  /// Adds an index to the last element in the rule path (for array access like cel[0])
  RulePath index(int index) {
    if (_elements.isEmpty) {
      throw StateError('Cannot add index to empty rule path');
    }
    
    final newPath = clone();
    final lastElement = newPath._elements.last;
    
    // Create a new element with the index
    newPath._elements[newPath._elements.length - 1] = pb.FieldPathElement()
      ..fieldNumber = lastElement.fieldNumber
      ..fieldName = lastElement.fieldName
      ..fieldType = lastElement.fieldType
      ..index = Int64(index);
      
    return newPath;
  }
  
  /// Converts this path to protobuf FieldPathElements.
  List<pb.FieldPathElement> toProtoElements() {
    return List.unmodifiable(_elements);
  }
  
  /// Converts this path to a string representation (e.g., "repeated.items.string.in")
  String toRulePathString() {
    return _elements
        .map((element) {
          if (element.hasIndex()) {
            // For array-style access like cel[0]
            return '${element.fieldName}[${element.index}]';
          }
          return element.fieldName;
        })
        .join('.');
  }
}

/// Helper class for creating rule path elements
class RulePathElement {
  final pb.FieldPathElement _element;
  
  RulePathElement._(this._element);
  
  /// Creates a predefined extension element
  static RulePathElement predefinedExtension(String extensionId) {
    // Extract the extension name from the rule ID (e.g., "uint64.even.proto2" -> "uint64_even_proto2")
    final extensionName = extensionId.replaceAll('.', '_');
    return RulePathElement._(pb.FieldPathElement()
      ..fieldNumber = 1161
      ..fieldName = '[buf.validate.conformance.cases.$extensionName]'
      ..fieldType = FieldDescriptorProto_Type.TYPE_BOOL);
  }
  
  pb.FieldPathElement toProto() => _element;
}