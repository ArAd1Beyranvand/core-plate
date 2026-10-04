import 'package:plate_core/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebanon_plate/lebanon_plate.dart';

/// Goldens for both geometries and a spread of the colour classes.
///
/// The private/diplomatic pair off `oneLine` is the point of this file: one
/// spec, rendered twice with only `country:` and `theme:` differing, is the
/// country/theme split shown as pixels. If the two are wired correctly the
/// images differ in field colour and nothing else — same band, same letter,
/// same digits.
///
/// Regenerate with `flutter test --update-goldens` after a deliberate change.
void main() {
  Future<void> renderGolden(
    WidgetTester tester, {
    required PlateSpec spec,
    required LebanonUsage usage,
    required List<String?> values,
    required String name,
  }) async {
    final theme = LebanonThemes.forUsage(usage);
    final controller = PlateController.fromValues(spec, values);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 520,
              height: 520 * spec.canvasHeight / spec.canvasWidth,
              child: PlateThemeScope(
                theme: theme,
                child: PlateView(
                  controller: controller,
                  theme: theme,
                  country: LebanonCountry.forUsage(usage),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(PlateView),
      matchesGoldenFile('goldens/$name.png'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  }

  const List<String?> beirut = <String?>['B', '1', '2', '3', '4', '5', '6'];

  group('one spec, two usages', () {
    testWidgets('private (white)', (tester) async {
      await renderGolden(
        tester,
        spec: LebanonPlates.oneLine,
        usage: LebanonUsage.private,
        values: beirut,
        name: 'lb_one_line_private',
      );
    });

    testWidgets('diplomatic (orange)', (tester) async {
      await renderGolden(
        tester,
        spec: LebanonPlates.oneLine,
        usage: LebanonUsage.diplomatic,
        values: const <String?>['D', '1', '2', '3', '4', '5', '6'],
        name: 'lb_one_line_diplomatic',
      );
    });

    testWidgets('consular (purple, light ink)', (tester) async {
      await renderGolden(
        tester,
        spec: LebanonPlates.oneLine,
        usage: LebanonUsage.consular,
        values: const <String?>['C', '1', '2', '3', '4', '5', '6'],
        name: 'lb_one_line_consular',
      );
    });
  });

  group('the other geometry', () {
    testWidgets('two-line private', (tester) async {
      await renderGolden(
        tester,
        spec: LebanonPlates.twoLine,
        usage: LebanonUsage.private,
        values: beirut,
        name: 'lb_two_line_private',
      );
    });

    testWidgets('two-line public institution (red, مؤسسات on the band)', (
      tester,
    ) async {
      await renderGolden(
        tester,
        spec: LebanonPlates.twoLine,
        usage: LebanonUsage.publicInstitution,
        values: const <String?>['M', '1', '2', '3', '4', '5', '6'],
        name: 'lb_two_line_public_institution',
      );
    });
  });

  group('short numbers keep the six-digit pitch', () {
    testWidgets('a parliament plate, three digits on a full-size face', (
      tester,
    ) async {
      await renderGolden(
        tester,
        spec: LebanonPlates.oneLineOf(digits: 3)!,
        usage: LebanonUsage.private,
        values: const <String?>['MP', '1', '2', '8'],
        name: 'lb_one_line_mp3',
      );
    });
  });
}
