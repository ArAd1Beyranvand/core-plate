import 'package:flutter/material.dart';

import '../../device_preview/device_config.dart' show DeviceType;
import '../poster_scale.dart';
import 'form_factor_pips.dart';
import 'inspection_stamp.dart';
import 'poster_links.dart';
import 'poster_masthead.dart';
import 'poster_wordmark.dart';

/// The always-on-screen chrome layer from DESIGN_SPEC.md §6, composited above
/// the callouts.
///
/// §9.1 records two layering bugs in the source: cards 04/08/12 and the link
/// buttons overlap and clip the meta strip. The fix chosen for this port is to
/// give the chrome its OWN layer, stacked ABOVE the callout layer — so the
/// meta strip, the links, the wordmark and the stamp are never clipped by a
/// card. Callers must stack this after (on top of) the callout layer; the
/// device stage stays below both. This decision is deliberate — see the top of
/// the assembly in `showcase_screen.dart` (P9) and this comment.
///
/// Every element is placed by its §6 fractional anchor via [PosterMetrics].
/// Anchors are the element's top-left in design fractions unless the element
/// is naturally right-aligned (pips, stamp), in which case the anchor marks
/// its right/near edge and the element lays out from there.
class PosterChrome extends StatelessWidget {
  const PosterChrome({super.key, required this.device});

  /// The current form factor, driving the stamp and the active pip.
  final DeviceType device;

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    final Size size = metrics.size;

    // Fractional anchors from §6's chrome table.
    final Offset byline = Offset(0.040 * size.width, 0.048 * size.height);
    final Offset wordmark = Offset(0.036 * size.width, 0.172 * size.height);
    final Offset stamp = Offset(0.843 * size.width, 0.874 * size.height);
    final Offset pips = Offset(0.977 * size.width, 0.415 * size.height);

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: byline.dx,
          top: byline.dy,
          child: const PosterMasthead(),
        ),
        Positioned(
          left: wordmark.dx,
          top: wordmark.dy,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const PosterWordmark(),
              SizedBox(height: metrics.px(32)),
              const PosterLinks(),
            ],
          ),
        ),
        // The pips anchor at their right edge (`.977`), so pin `right` rather
        // than `left` and let the right-aligned column grow leftward.
        Positioned(
          right: size.width - pips.dx,
          top: pips.dy,
          child: FormFactorPips(device: device),
        ),
        Positioned(
          left: stamp.dx,
          top: stamp.dy,
          child: const InspectionStamp(),
        ),
      ],
    );
  }
}
