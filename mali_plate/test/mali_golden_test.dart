import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_plate/mali_plate.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Roboto');
    for (final path in const [
      '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
    ]) {
      final file = File(path);
      if (!file.existsSync()) continue;
      loader.addFont(file.readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await loader.load();
  });

  group('Mali Plate Goldens', () {
    testWidgets('standard plate renders', (WidgetTester tester) async {
      final spec = MaliPlates.all['standard']!();
      await tester.binding.window.physicalSizeTestValue = const Size(1040, 220);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 520,
                height: 110,
                child: CustomPaint(
                  painter: _PlatePainter(spec),
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(CustomPaint),
        matchesGoldenFile('mali_standard.png'),
      );
    });
  });
}

class _PlatePainter extends CustomPainter {
  _PlatePainter(this.spec);

  final PlateSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    // Paint the plate background
    final paint = Paint()..color = MaliColors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), 15),
      paint,
    );

    // Paint border
    final borderPaint = Paint()
      ..color = MaliColors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), 15),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(_PlatePainter oldDelegate) => false;
}
