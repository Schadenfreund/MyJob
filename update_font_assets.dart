/// Automatically detects fonts and updates pubspec.yaml
/// Run: dart update_font_assets.dart
library;

import 'dart:io';

void main() async {
  print('🔍 Scanning fonts directory...\n');

  final fontsDir = Directory('assets/fonts');

  if (!await fontsDir.exists()) {
    print('❌ assets/fonts directory does not exist');
    print('   Creating it...');
    await fontsDir.create(recursive: true);
    print('   ✅ Created assets/fonts/');
  }

  // Find all subdirectories and TTF files
  final assetPaths = <String>{
    'assets/',
    'assets/fonts/',
  };

  await for (final entity in fontsDir.list(recursive: true)) {
    if (entity is Directory) {
      final relativePath = entity.path.replaceAll('\\', '/');
      assetPaths.add('$relativePath/');
    }
  }

  print('📁 Found asset paths:');
  for (final path in assetPaths) {
    print('   - $path');
  }

  // Read current pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  final content = await pubspecFile.readAsString();

  // Find flutter section
  final lines = content.split('\n');
  final newLines = <String>[];
  bool inFlutterSection = false;
  bool inAssetsSection = false;
  bool assetsWritten = false;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    // Detect flutter section
    if (line.trim().startsWith('flutter:')) {
      inFlutterSection = true;
      newLines.add(line);
      continue;
    }

    // Detect assets section
    if (inFlutterSection && line.trim().startsWith('assets:')) {
      inAssetsSection = true;
      // Skip existing assets section - we'll replace it
      newLines.add(line);

      // Add all detected asset paths
      for (final assetPath in assetPaths.toList()..sort()) {
        newLines.add('    - $assetPath');
      }
      assetsWritten = true;

      // Skip old asset entries
      while (i + 1 < lines.length && lines[i + 1].trim().startsWith('-')) {
        i++;
      }
      continue;
    }

    // If we're past flutter section and haven't written assets, add them
    if (inFlutterSection &&
        !assetsWritten &&
        !line.startsWith(' ') &&
        line.isNotEmpty) {
      newLines.add('');
      newLines.add('  assets:');
      for (final assetPath in assetPaths.toList()..sort()) {
        newLines.add('    - $assetPath');
      }
      assetsWritten = true;
      inFlutterSection = false;
    }

    newLines.add(line);
  }

  // Write updated pubspec.yaml
  await pubspecFile.writeAsString(newLines.join('\n'));

  print('\n✅ Updated pubspec.yaml');
  print('\n📝 Next steps:');
  print('   1. Run: flutter pub get');
  print('   2. Run: flutter build windows');
  print('   3. Fonts will be bundled automatically!');
}
