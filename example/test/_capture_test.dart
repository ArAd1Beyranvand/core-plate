import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_number_example/screens/showcase_screen.dart';

Future<void> _loadFonts() async {
  const families = <String, List<String>>{
    'Archivo': <String>[
      'assets/fonts/Archivo-latin.ttf',
      'assets/fonts/Archivo-latin-ext.ttf',
    ],
    'MartianMono': <String>[
      'assets/fonts/MartianMono-latin.ttf',
      'assets/fonts/MartianMono-latin-ext.ttf',
    ],
    'Newsreader': <String>[
      'assets/fonts/Newsreader-latin.ttf',
      'assets/fonts/Newsreader-latin-ext.ttf',
    ],
    'Vazirmatn': <String>[
      'assets/fonts/Vazirmatn-arabic.ttf',
      'assets/fonts/Vazirmatn-latin.ttf',
      'assets/fonts/Vazirmatn-latin-ext.ttf',
    ],
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      loader.addFont(rootBundle.load(path));
    }
    await loader.load();
  }
}

void main() {
  for (final size in const <Size>[Size(1920, 1080), Size(1512, 982)]) {
    testWidgets('capture ${size.width.toInt()}x${size.height.toInt()}', (
      tester,
    ) async {
      await _loadFonts();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey<String>('capture'),
          child: const MaterialApp(home: ShowcaseScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 32));
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey<String>('capture')),
          );
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final name =
          'build/poster_${size.width.toInt()}x${size.height.toInt()}.png';
      File(name)
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
      // ignore: avoid_print
      print('WROTE $name');
    });
  }
}
