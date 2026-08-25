import 'package:flutter/material.dart';

import '../poster/poster_tokens.dart';
import '../showcase/device_stage.dart';

/// The showcase screen: a device cycling through form factors, typing plates.
///
/// Poster chrome around the device was removed in the poster demolition; this
/// is bootstrap-only until the new poster (per DESIGN_SPEC.md) replaces it.
class ShowcaseScreen extends StatelessWidget {
  const ShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PosterTokens.bg,
      body: const Center(child: DeviceStage()),
    );
  }
}
