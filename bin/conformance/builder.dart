import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'conformance_generator.dart';

/// Exposes the builders for build_runner
Builder conformanceRegistryBuilder(BuilderOptions options) => LibraryBuilder(
      ConformanceRegistryGenerator(),
      generatedExtension: '.conformance.g.dart',
    );
