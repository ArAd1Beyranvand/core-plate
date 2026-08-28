import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_number_example/poster/callouts/callout_card.dart';
import 'package:plate_number_example/poster/callouts/callout_data.dart';
import 'package:plate_number_example/poster/poster_scale.dart';

void main() {
  for (final entry in calloutSets.entries) {
    for (final spec in entry.value) {
      testWidgets('card ${spec.index} (${entry.key}) has no overflow', (tester) async {
        final errors = <FlutterErrorDetails>[];
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          errors.add(details);
        };
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: PosterMetricsScope(
                  child: CalloutCard(spec: spec),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        FlutterError.onError = prevOnError;
        for (final e in errors) {
          // ignore: avoid_print
          print('OVERFLOW/ERROR on card ${spec.index}: ${e.exceptionAsString()}');
        }
        expect(errors, isEmpty, reason: 'card ${spec.index} produced render errors');
      });
    }
  }
}
