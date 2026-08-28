import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../poster_scale.dart';
import '../poster_tokens.dart';

/// The inspection stamp from DESIGN_SPEC.md §6 "Chrome", anchored at
/// `.843, .874`, width `.130`.
///
/// Rotated `-6deg`, with a double inner ring
/// (`inset 0 0 0 2px rgba(228,214,188,.34), inset 0 0 0 8px rgba(228,214,188,.14)`)
/// and a single centred Martian Mono line:
///
///   made in IRAN
class InspectionStamp extends StatelessWidget {
  const InspectionStamp({super.key});

  static const Color _ringOuter = Color(0x57E4D6BC); // rgba(228,214,188,.34)
  static const Color _ringInner = Color(0x24E4D6BC); // rgba(228,214,188,.14)

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);

    final TextStyle stampStyle = PosterType.stamp(metrics.f).copyWith(
      fontSize: PosterType.stamp(metrics.f).fontSize! * 1.2,
    );

    return Transform.rotate(
      angle: -6 * math.pi / 180.0,
      child: SizedBox(
        width: metrics.px(250),
        child: DecoratedBox(
          decoration: BoxDecoration(
            // Double inner ring reproduced as two stacked inset borders.
            border: Border.all(color: _ringOuter, width: metrics.px(2)),
          ),
          child: Padding(
            padding: EdgeInsets.all(metrics.px(6)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: _ringInner, width: metrics.px(6)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.px(18),
                  vertical: metrics.px(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF444444),
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFF888888),
                            width: metrics.px(0.5),
                          ),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: metrics.px(12),
                        vertical: metrics.px(4),
                      ),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'made',
                              style: stampStyle.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF239F40),
                              ),
                            ),
                            TextSpan(
                              text: ' ',
                              style: stampStyle.copyWith(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'in',
                              style: stampStyle.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: ' ',
                              style: stampStyle.copyWith(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'IRAN',
                              style: stampStyle.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B0000),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
