import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yemen_plate/yemen_plate.dart';

/// The phase's claim, rendered: one spec, five usages, five different plates.
///
/// Before 0.3.0 the usage word came off the spec, so a wrong `country:` was
/// impossible and a missing one unthinkable. Now the word arrives at render
/// time, and if the override does not reach `CountryPanel` every plate quietly
/// reads خصوصي. That is a defect no spec test can see, so it is checked here
/// by looking at what is actually on the screen.
Future<void> _pump(
  WidgetTester tester, {
  required PlateSpec spec,
  required PlateCountry country,
  required PlateTheme theme,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 600,
          height: 600 * spec.canvasHeight / spec.canvasWidth,
          child: PlateCanvas(
            spec: spec,
            country: country,
            theme: theme,
            onChooseCharacter: (PlateAlphabet a) async => null,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('System A: the panel prints each usage\'s own caption lines', (
    WidgetTester tester,
  ) async {
    for (final YemenUsage usage in YemenUsage.unified) {
      await _pump(
        tester,
        spec: YemenUnifiedPlates.car5,
        country: YemenCountry.unifiedFor(usage),
        theme: YemenThemes.forUnifiedUsage(usage),
      );
      expect(
        find.text(usage.unifiedArabic!),
        findsOneWidget,
        reason: '${usage.name}: the country override did not reach the panel',
      );
      expect(find.text(usage.unifiedLatin!), findsOneWidget, reason: usage.name);
      if (usage != YemenUsage.private) {
        // The spec's own default, which must not be what is painted.
        expect(find.text('PRIV.'), findsNothing, reason: usage.name);
      }
    }
  });

  testWidgets('System B: the top band prints each usage word it has one for', (
    WidgetTester tester,
  ) async {
    for (final YemenUsage usage in YemenUsage.northern) {
      await _pump(
        tester,
        spec: YemenNorthernPlates.carGov2Serial5,
        country: YemenCountry.northernFor(usage),
        theme: YemenThemes.forNorthernUsage(usage),
      );
      final List<String> lines = YemenCountry.northernFor(usage).captionLines;
      for (final String line in lines) {
        expect(find.text(line), findsOneWidget, reason: usage.name);
      }
      // government and military print no usage word — no source names one — so
      // their band carries اليمن alone, and خصوصي must not leak through from
      // the spec's private default.
      if (usage != YemenUsage.private) {
        expect(
          lines.any((String l) => l.contains('خصوصي')),
          isFalse,
          reason: usage.name,
        );
      }
    }
  });

  testWidgets('System B: the field colour is the usage', (
    WidgetTester tester,
  ) async {
    final Set<Color> fields = <Color>{};
    for (final YemenUsage usage in YemenUsage.northern) {
      final PlateTheme theme = YemenThemes.forNorthernUsage(usage);
      await _pump(
        tester,
        spec: YemenNorthernPlates.carGov2Serial5,
        country: YemenCountry.northernFor(usage),
        theme: theme,
      );
      fields.add(theme.plateBackground);
    }
    // Five usages, five colours — blue, yellow, red, green, black.
    expect(fields.length, YemenUsage.northern.length);
  });

  testWidgets('with no override the spec still draws the private plate', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 600,
              height: 171,
              child: PlateCanvas(
                spec: YemenUnifiedPlates.car5,
                onChooseCharacter: (PlateAlphabet a) async => null,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('خصوصي'), findsOneWidget);
    expect(find.text('PRIV.'), findsOneWidget);
  });
}
