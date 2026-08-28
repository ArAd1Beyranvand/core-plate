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
                    SizedBox(height: metrics.px(2)),
                    SizedBox(
                      width: metrics.px(220),
                      height: metrics.px(20),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          Positioned(
                            left: metrics.px(8),
                            top: metrics.px(2),
                            child: Container(
                              width: metrics.px(16),
                              height: metrics.px(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha:0.25),
                                    blurRadius: metrics.px(18),
                                    spreadRadius: metrics.px(6),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha:0.15),
                                    blurRadius: metrics.px(28),
                                    spreadRadius: metrics.px(12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: metrics.px(22),
                            top: metrics.px(4),
                            child: Container(
                              width: metrics.px(12),
                              height: metrics.px(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha:0.2),
                                    blurRadius: metrics.px(16),
                                    spreadRadius: metrics.px(5),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha:0.1),
                                    blurRadius: metrics.px(24),
                                    spreadRadius: metrics.px(10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: metrics.px(35),
                            top: metrics.px(3),
                            child: Container(
                              width: metrics.px(14),
                              height: metrics.px(14),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha:0.22),
                                    blurRadius: metrics.px(17),
                                    spreadRadius: metrics.px(5),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha:0.12),
                                    blurRadius: metrics.px(26),
                                    spreadRadius: metrics.px(11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: metrics.px(18),
                            top: metrics.px(1),
                            child: Container(
                              width: metrics.px(18),
                              height: metrics.px(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha:0.28),
                                    blurRadius: metrics.px(20),
                                    spreadRadius: metrics.px(7),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha:0.16),
                                    blurRadius: metrics.px(30),
                                    spreadRadius: metrics.px(13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: metrics.px(8),
                            top: metrics.px(5),
                            child: Container(
                              width: metrics.px(20),
                              height: metrics.px(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha:0.3),
                                    blurRadius: metrics.px(22),
                                    spreadRadius: metrics.px(8),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha:0.18),
                                    blurRadius: metrics.px(32),
                                    spreadRadius: metrics.px(14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: metrics.px(35),
                            top: metrics.px(5),
                            child: Container(
                              width: metrics.px(10),
                              height: metrics.px(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha:0.18),
                                    blurRadius: metrics.px(15),
                                    spreadRadius: metrics.px(4),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha:0.08),
                                    blurRadius: metrics.px(22),
                                    spreadRadius: metrics.px(8),
                                  ),
                                ],
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
