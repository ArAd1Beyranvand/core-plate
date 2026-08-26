import 'package:flutter/material.dart';

import '../poster_scale.dart';
import '../poster_tokens.dart';

/// The byline from DESIGN_SPEC.md §6 "Chrome" and §2.
///
/// `ARAD BIRANVAND` (Martian Mono `wght 800`, tracking `.16em`, `#DEE7F4`)
/// set baseline-aligned beside `sole author` (Newsreader `wght 400` italic,
/// `#8E9DB4`), with a 14 design-px gap. Anchored at `.040, .048`.
///
/// The two run on a shared text baseline rather than centre or top, so the
/// italic role sits on the same line as the name's caps — a `Row` with
/// `CrossAxisAlignment.baseline` and an alphabetic baseline.
class PosterMasthead extends StatelessWidget {
  const PosterMasthead({super.key});

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    final double f = metrics.f;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Text('ARAD BIRANVAND', style: PosterType.bylineName(f)),
        SizedBox(width: metrics.px(14)),
        Text('sole author', style: PosterType.bylineRole(f)),
      ],
    );
  }
}
