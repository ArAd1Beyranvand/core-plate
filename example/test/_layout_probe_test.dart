import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_number_example/poster/callouts/callout_card.dart';
import 'package:plate_number_example/poster/callouts/callout_data.dart';
import 'package:plate_number_example/poster/poster_scale.dart';

Future<void> loadPosterFonts() async {
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

/// Design-space boxes handed to `DeviceFrame` (DESIGN_SPEC §7.1).
const Map<DeviceType, Rect> deviceBoxes = <DeviceType, Rect>{
  DeviceType.desktop: Rect.fromLTWH(1012, 262, 832, 486),
  DeviceType.mobile: Rect.fromLTWH(1300, 206, 364, 698),
  DeviceType.tablet: Rect.fromLTWH(1004, 250, 872, 600),
};

/// Chrome boxes in design space, measured from the running poster.
const Map<String, Rect> chromeBoxes = <String, Rect>{
  'masthead': Rect.fromLTRB(77, 52, 535, 76),
  'links': Rect.fromLTRB(75, 840, 431, 887),
  'meta': Rect.fromLTRB(75, 953, 584, 1001),
  'stamp': Rect.fromLTRB(1619, 944, 1869, 1060),
  'pips': Rect.fromLTRB(1848, 448, 1876, 487),
};

void main() {
  testWidgets('callout geometry in design space', (tester) async {
    await loadPosterFonts();
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final entry in calloutSets.entries) {
      final device = entry.key;
      final box = deviceBoxes[device]!;
      final rects = <int, Rect>{};
      // ignore: avoid_print
      print('--- ${device.name}  device=$box');
      for (final spec in entry.value) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PosterMetricsScope(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      CalloutCard(spec: spec),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        final render = tester.renderObject<RenderBox>(find.byType(CalloutCard));
        // The index chip hangs 28 out on the card's own side and 26 above.
        final chipDx = spec.side == CalloutSide.left ? -28.0 : 28.0;
        final rect = Rect.fromLTWH(
          spec.anchorFx * 1920 + (chipDx < 0 ? chipDx : 0),
          spec.anchorFy * 1080 - 26,
          render.size.width + 28,
          render.size.height + 26,
        );
        rects[spec.index] = rect;
        final flags = <String>[
          if (rect.bottom > 1080) 'BOTTOM+${(rect.bottom - 1080).round()}',
          if (rect.right > 1920) 'RIGHT+${(rect.right - 1920).round()}',
          if (rect.overlaps(box)) 'DEVICE',
          for (final c in chromeBoxes.entries)
            if (rect.overlaps(c.value)) c.key.toUpperCase(),
        ];
        // ignore: avoid_print
        print(
          '  ${spec.index.toString().padLeft(2, '0')} ${spec.side.name.padRight(5)} '
          '${render.size.width.round()}x${render.size.height.round()} '
          'L${rect.left.round()} T${rect.top.round()} '
          'R${rect.right.round()} B${rect.bottom.round()}'
          '${flags.isEmpty ? '' : '  !! ${flags.join(' ')}'}',
        );
      }
      final keys = rects.keys.toList();
      for (int i = 0; i < keys.length; i++) {
        for (int j = i + 1; j < keys.length; j++) {
          if (rects[keys[i]]!.overlaps(rects[keys[j]]!)) {
            // ignore: avoid_print
            print('  !! ${keys[i]} overlaps ${keys[j]}');
          }
        }
      }
    }
  });
}
