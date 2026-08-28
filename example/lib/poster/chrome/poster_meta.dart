import 'package:flutter/material.dart';

import '../poster_scale.dart';
import '../poster_tokens.dart';

/// The meta strip from DESIGN_SPEC.md §6 "Chrome", anchored at `.039, .882`.
/// Currently hidden (renders as empty).
///
/// §9.1: in the source this strip is clipped by cards 04/08/12 and the link
/// buttons. P6 builds the chrome to live in its own layer ABOVE the callouts
/// (see the layering comment in the gallery / assembly), so the strip is never
/// clipped here.
class PosterMeta extends StatelessWidget {
  const PosterMeta({super.key});

  static const Color _topHairline = Color(0x2EBCCEEB); // rgba(188,206,235,.18)
  static const Color _bottomHairline = Color(0xB3000000); // rgba(0,0,0,.7)

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    final double hair = metrics.px(1);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: PosterColors.metaStrip,
        border: Border(
          top: BorderSide(color: _topHairline, width: hair),
          bottom: BorderSide(color: _bottomHairline, width: hair),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: metrics.px(20),
          vertical: metrics.px(12),
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}
