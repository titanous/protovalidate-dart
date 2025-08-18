import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';
import 'package:path/path.dart' as p;

/// Generator that creates a TypeRegistry for all conformance test messages
class ConformanceRegistryGenerator extends Generator {
  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) async {
    // Only generate for the registry file
    if (!buildStep.inputId.path.endsWith('conformance_registry.dart')) {
      return null;
    }

    // Find all .pb.dart files in conformance cases
    final pbFiles = <AssetId>[];
    final glob = Glob('lib/src/gen/buf/validate/conformance/cases/**.pb.dart');

    await for (final asset in buildStep.findAssets(glob)) {
      if (!asset.path.contains('.pbenum.dart') &&
          !asset.path.contains('.pbjson.dart') &&
          !asset.path.contains('.pbserver.dart') &&
          !asset.path.contains('.pbgrpc.dart')) {
        pbFiles.add(asset);
      }
    }

    // Collect message classes from each file
    final messagesByPackage = <String, List<String>>{};
    final imports = <String>[];

    for (final assetId in pbFiles) {
      final content = await buildStep.readAsString(assetId);
      final relativePath = p.relative(assetId.path, from: 'lib');

      // Determine package alias - check the full path to be more specific
      String packageAlias = '';
      String packageKey = 'main';

      if (assetId.path.contains('/other_package/')) {
        packageAlias = 'other_package';
        packageKey = 'other_package';
      } else if (assetId.path.contains('/yet_another_package/')) {
        packageAlias = 'yet_another_package';
        packageKey = 'yet_another_package';
      } else if (assetId.path.contains('/repeated.pb.dart')) {
        packageAlias = 'repeated_lib';
        packageKey = 'repeated';
      }

      // Add import
      if (packageAlias.isNotEmpty) {
        imports.add(
            "import 'package:protovalidate/$relativePath' as $packageAlias;");
      } else {
        imports.add("import 'package:protovalidate/$relativePath';");
      }

      // Extract message classes
      final classPattern = RegExp(
          r'^class\s+(\w+)\s+extends\s+\$pb\.GeneratedMessage\s*\{',
          multiLine: true);
      final matches = classPattern.allMatches(content);

      for (final match in matches) {
        final className = match.group(1)!;
        // Skip map entry classes
        if (!className.endsWith('Entry')) {
          messagesByPackage.putIfAbsent(packageKey, () => []).add(className);
        }
      }
    }

    // Generate the output
    final buffer = StringBuffer();

    buffer.writeln("import 'package:protobuf/protobuf.dart';");
    buffer.writeln(
        "import 'package:protovalidate/src/gen/google/protobuf/any.pb.dart';");
    buffer.writeln('');
    buffer.writeln('// Conformance test message imports');

    for (final import in imports..sort()) {
      buffer.writeln(import);
    }

    buffer.writeln('');
    buffer.writeln(
        '/// Creates a TypeRegistry containing all conformance test message types');
    buffer.writeln('TypeRegistry createConformanceRegistry() {');
    buffer.writeln('  return TypeRegistry([');

    // Add main package messages first
    if (messagesByPackage.containsKey('main')) {
      final mainMessages = messagesByPackage['main']!..sort();
      for (final className in mainMessages) {
        buffer.writeln('    $className(),');
      }
    }

    // Add other package messages with prefixes
    for (final entry in messagesByPackage.entries) {
      if (entry.key == 'main') continue;

      final prefix = _getPrefix(entry.key);
      final messages = entry.value..sort();

      for (final className in messages) {
        buffer.writeln('    $prefix.$className(),');
      }
    }

    buffer.writeln('  ]);');
    buffer.writeln('}');
    buffer.writeln('');
    buffer.writeln('/// Helper to unpack an Any message using a TypeRegistry');
    buffer.writeln(
        'GeneratedMessage? unpackAnyWithRegistry(Any any, TypeRegistry registry) {');
    buffer.writeln('  final typeUrl = any.typeUrl;');
    buffer.writeln('  if (typeUrl.isEmpty) return null;');
    buffer.writeln('');
    buffer.writeln('  final typeName = typeUrl.split(\'/\').last;');
    buffer.writeln('  final builderInfo = registry.lookup(typeName);');
    buffer.writeln('');
    buffer.writeln('  if (builderInfo == null) return null;');
    buffer
        .writeln('  if (builderInfo.createEmptyInstance == null) return null;');
    buffer.writeln('');
    buffer.writeln('  final message = builderInfo.createEmptyInstance!();');
    buffer.writeln('');
    buffer.writeln('  // Check if the type matches');
    buffer.writeln('  if (!any.canUnpackInto(message)) return null;');
    buffer.writeln('');
    buffer.writeln('  // Unpack the message');
    buffer.writeln('  return any.unpackInto(message);');
    buffer.writeln('}');

    return buffer.toString();
  }

  String _getPrefix(String packageKey) {
    switch (packageKey) {
      case 'other_package':
        return 'other_package';
      case 'yet_another_package':
        return 'yet_another_package';
      case 'repeated':
        return 'repeated_lib';
      default:
        return '';
    }
  }
}
