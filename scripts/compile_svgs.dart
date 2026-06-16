// ignore_for_file: avoid_print

import 'dart:io';

Future<void> main() async {
  final iconsDir = Directory('assets/icons');
  if (!iconsDir.existsSync()) {
    print(
      'Error: assets/icons directory does not exist at ${iconsDir.absolute.path}',
    );
    exit(1);
  }

  print('Locating SVG files recursively under assets/icons...');
  final svgFiles = <File>[];
  try {
    await for (final entity in iconsDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.svg')) {
        svgFiles.add(entity);
      }
    }
  } catch (e) {
    print('Error while scanning directory: $e');
    exit(1);
  }

  if (svgFiles.isEmpty) {
    print('No SVG files found in assets/icons.');
    return;
  }

  print('Found ${svgFiles.length} SVG file(s) to convert.');

  var compiledCount = 0;
  var failedCount = 0;

  for (final svgFile in svgFiles) {
    final inputPath = svgFile.path;
    final outputPath = '$inputPath.vec';

    print('Compiling: $inputPath -> $outputPath');

    // Run the vector_graphics_compiler tool
    final result = await Process.run('dart', [
      'run',
      'vector_graphics_compiler',
      '-i',
      inputPath,
      '-o',
      outputPath,
    ]);

    if (result.exitCode == 0) {
      print('  [Success] Compiled $outputPath');
      compiledCount++;
    } else {
      print(
        '  [Error] Failed to compile $inputPath (Exit Code: ${result.exitCode})',
      );
      if (result.stdout.toString().isNotEmpty) {
        print('  stdout: ${result.stdout}');
      }
      if (result.stderr.toString().isNotEmpty) {
        print('  stderr: ${result.stderr}');
      }
      failedCount++;
    }
  }

  print('\n----------------------------------------');
  print('Summary:');
  print('  Successfully compiled: $compiledCount');
  print('  Failed compilation:    $failedCount');
  print('----------------------------------------');

  if (failedCount > 0) {
    exit(1);
  }
}
