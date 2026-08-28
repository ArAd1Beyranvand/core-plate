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

    final TextStyle stampStyle = PosterType.stamp(metrics.f);

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
                  vertical: metrics.px(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    RichText(
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
                    SizedBox(height: metrics.px(4)),
                    SizedBox(
                      width: metrics.px(180),
                      height: metrics.px(8),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: metrics.px(10),
                            child: Container(
                              width: metrics.px(20),
                              height: metrics.px(2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(metrics.px(1)),
                              ),
                            ),
                          ),
                          Positioned(
                            right: metrics.px(20),
                            child: Container(
                              width: metrics.px(16),
                              height: metrics.px(2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(metrics.px(1)),
                              ),
                            ),
                          ),
                          Positioned(
                            right: metrics.px(2),
                            child: Container(
                              width: metrics.px(32),
                              height: metrics.px(3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(metrics.px(1.5)),
                              ),
                            ),
                          ),
                          Positioned(
                            right: metrics.px(8),
                            bottom: metrics.px(2),
                            child: Container(
                              width: metrics.px(24),
                              height: metrics.px(2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(metrics.px(1)),
                              ),
                            ),
                          ),
                        ],
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
