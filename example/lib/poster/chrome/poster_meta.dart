import 'package:flutter/material.dart';

import '../poster_scale.dart';
import '../poster_tokens.dart';

/// The meta strip from DESIGN_SPEC.md §6 "Chrome", anchored at `.039, .882`.
///
/// `plate_number` (a link, meta-strong) │ `pub.dev` │ `MIT` (meta-weak), on a
/// `rgba(9,8,6,.92)` ground, with a top hairline `rgba(188,206,235,.18)`, a
/// bottom hairline `rgba(0,0,0,.7)`, and `rgba(219,200,170,.32)` 1px dividers
/// between the fields.
///
/// §9.1: in the source this strip is clipped by cards 04/08/12 and the link
/// buttons. P6 builds the chrome to live in its own layer ABOVE the callouts
/// (see the layering comment in the gallery / assembly), so the strip is never
/// clipped here.
class PosterMeta extends StatelessWidget {
  const PosterMeta({super.key});

  static const Color _topHairline = Color(0x2EBCCEEB); // rgba(188,206,235,.18)
  static const Color _bottomHairline = Color(0xB3000000); // rgba(0,0,0,.7)
  static const Color _divider = Color(0x52DBC8AA); // rgba(219,200,170,.32)

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    final double f = metrics.f;
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // `plate_number` reads as a link — meta-strong ink.
            Text('plate_number', style: PosterType.metaStrong(f)),
            _Divider(metrics: metrics),
            Text('pub.dev', style: PosterType.metaWeak(f)),
            _Divider(metrics: metrics),
            Text('MIT', style: PosterType.metaWeak(f)),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.metrics});

  final PosterMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: metrics.px(16)),
      child: SizedBox(
        width: metrics.px(1),
        height: metrics.px(18),
        child: const ColoredBox(color: PosterMeta._divider),
      ),
    );
  }
}
