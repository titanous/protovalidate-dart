import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart' as pb;
import 'package:protovalidate/src/gen/google/protobuf/descriptor.pbenum.dart';

/// Represents a path element in a protobuf message field path.
abstract class PathElement {
  String toFieldPathString();
  pb.FieldPathElement toProto();
}

/// A field element in the path.
class FieldElement implements PathElement {
  final FieldInfo field;
  
  FieldElement(this.field);
  
  @override
  String toFieldPathString() => field.name;
  
  @override
  pb.FieldPathElement toProto() {
    final element = pb.FieldPathElement()
      ..fieldNumber = field.tagNumber
      ..fieldName = field.name;
    
    // Set field type based on FieldInfo type
    element.fieldType = _getFieldType(field);
    
    return element;
  }
  
  FieldDescriptorProto_Type _getFieldType(FieldInfo field) {
    // Map PbFieldType to FieldDescriptorProto_Type
    // This is a simplified mapping - in production you'd want a complete mapping
    if (field.type == PbFieldType.OB || field.type == PbFieldType.PB) {
      return FieldDescriptorProto_Type.TYPE_BOOL;
    } else if (field.type == PbFieldType.O3 || field.type == PbFieldType.P3) {
      return FieldDescriptorProto_Type.TYPE_INT32;
    } else if (field.type == PbFieldType.O6 || field.type == PbFieldType.P6) {
      return FieldDescriptorProto_Type.TYPE_INT64;
    } else if (field.type == PbFieldType.OU3 || field.type == PbFieldType.PU3) {
      return FieldDescriptorProto_Type.TYPE_UINT32;
    } else if (field.type == PbFieldType.OU6 || field.type == PbFieldType.PU6) {
      return FieldDescriptorProto_Type.TYPE_UINT64;
    } else if (field.type == PbFieldType.OF || field.type == PbFieldType.PF) {
      return FieldDescriptorProto_Type.TYPE_FLOAT;
    } else if (field.type == PbFieldType.OD || field.type == PbFieldType.PD) {
      return FieldDescriptorProto_Type.TYPE_DOUBLE;
    } else if (field.type == PbFieldType.OS || field.type == PbFieldType.PS) {
      return FieldDescriptorProto_Type.TYPE_STRING;
    } else if (field.type == PbFieldType.OY || field.type == PbFieldType.PY) {
      return FieldDescriptorProto_Type.TYPE_BYTES;
    } else if (field.type == PbFieldType.OE || field.type == PbFieldType.PE) {
      return FieldDescriptorProto_Type.TYPE_ENUM;
    } else if (field.type == PbFieldType.OM || field.type == PbFieldType.PM) {
      return FieldDescriptorProto_Type.TYPE_MESSAGE;
    } else {
      // Default to string for unknown types
      return FieldDescriptorProto_Type.TYPE_STRING;
    }
  }
}

/// A list index element in the path.
class ListElement implements PathElement {
  final int index;
  
  ListElement(this.index);
  
  @override
  String toFieldPathString() => '[$index]';
  
  @override
  pb.FieldPathElement toProto() {
    return pb.FieldPathElement()
      ..index = Int64(index);
  }
}

/// A map key element in the path.
class MapKeyElement implements PathElement {
  final dynamic key;
  
  MapKeyElement(this.key);
  
  @override
  String toFieldPathString() {
    if (key is String) {
      return '["$key"]';
    }
    return '[$key]';
  }
  
  @override
  pb.FieldPathElement toProto() {
    final element = pb.FieldPathElement();
    
    if (key is String) {
      element.stringKey = key;
    } else if (key is bool) {
      element.boolKey = key;
    } else if (key is int) {
      element.intKey = Int64(key);
    } else {
      // Convert to string as fallback
      element.stringKey = key.toString();
    }
    
    return element;
  }
}

/// Represents a field path through a protobuf message structure.
class FieldPath {
  final List<PathElement> _elements;
  
  FieldPath() : _elements = [];
  
  FieldPath._(List<PathElement> elements) : _elements = List.from(elements);
  
  /// Creates a copy of this path.
  FieldPath clone() => FieldPath._(_elements);
  
  /// Adds a field to the path.
  FieldPath field(FieldInfo field) {
    final newPath = clone();
    newPath._elements.add(FieldElement(field));
    return newPath;
  }
  
  /// Adds a list index to the path.
  FieldPath listIndex(int index) {
    final newPath = clone();
    newPath._elements.add(ListElement(index));
    return newPath;
  }
  
  /// Adds a map key to the path.
  FieldPath mapKey(dynamic key) {
    final newPath = clone();
    newPath._elements.add(MapKeyElement(key));
    return newPath;
  }
  
  /// Returns the string representation of this path.
  String toFieldPathString() {
    if (_elements.isEmpty) return '';
    
    final buffer = StringBuffer();
    for (var i = 0; i < _elements.length; i++) {
      final element = _elements[i];
      final str = element.toFieldPathString();
      
      if (i == 0 || str.startsWith('[')) {
        buffer.write(str);
      } else {
        buffer.write('.');
        buffer.write(str);
      }
    }
    return buffer.toString();
  }
  
  /// Converts this path to protobuf FieldPathElements.
  List<pb.FieldPathElement> toProtoElements() {
    return _elements.map((e) => e.toProto()).toList();
  }
  
  @override
  String toString() => toFieldPathString();
}