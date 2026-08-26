import 'package:flutter/material.dart';

import '../poster/backdrop/poster_backdrop.dart';
import '../poster/poster_scale.dart';
import '../poster/poster_tokens.dart';
import '../showcase/device_stage.dart';

/// The showcase screen: a device cycling through form factors, typing plates.
///
/// The poster itself is assembled in P9. For now this is the bootstrap stage
/// plus P4's road backdrop behind it, so the backdrop can be seen in the real
/// app and not only in `lib/dev/backdrop_gallery.dart`. P9 replaces this whole
/// layout — the device moves right-of-centre and the chrome, callouts and
/// sweep arrive around it.
class ShowcaseScreen extends StatelessWidget {
  const ShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PosterTokens.bg,
      body: const PosterMetricsScope(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            PosterBackdrop(),
            Center(child: DeviceStage()),
          ],
        ),
      ),
    );
  }
}
