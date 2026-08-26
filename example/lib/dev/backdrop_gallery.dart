import 'package:flutter/material.dart';

import '../poster/backdrop/poster_backdrop.dart';
import '../poster/poster_scale.dart';
import '../poster/poster_tokens.dart';

/// A throwaway gallery for the DESIGN_SPEC.md §6 road backdrop: the live
/// window at the top, then one fixed preview per `PosterTier` so the wedge,
/// the rails and the lane dashes can be checked as the stage box changes
/// shape. Run with:
///
///   flutter run -t lib/dev/backdrop_gallery.dart
void main() => runApp(const BackdropGallery());

class BackdropGallery extends StatelessWidget {
  const BackdropGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: PosterColors.pageBlack,
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: <Widget>[
              const Material(
                color: PosterColors.pageBlack,
                child: TabBar(
                  labelColor: PosterColors.inkDisplay1,
                  unselectedLabelColor: PosterColors.inkMetaWeak,
                  indicatorColor: PosterColors.accent,
                  tabs: <Widget>[
                    Tab(text: 'Live window'),
                    Tab(text: 'Tier previews'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    // Full-screen: resize the window to sweep every tier.
                    const PosterMetricsScope(child: PosterBackdrop()),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const <Widget>[
                          _Preview(
                            label: 'wide — 1920 × 1080 (design canvas)',
                            width: 1920,
                            height: 1080,
                          ),
                          _Preview(
                            label: 'wide — 1280 × 720',
                            width: 1280,
                            height: 720,
                          ),
                          _Preview(
                            label: 'medium — 900 × 620',
                            width: 900,
                            height: 620,
                          ),
                          _Preview(
                            label: 'compact — 420 × 780 (portrait)',
                            width: 420,
                            height: 780,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.label,
    required this.width,
    required this.height,
  });

  final String label;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: PosterFonts.martianMono,
                fontSize: 12,
                color: PosterColors.inkMetaWeak,
              ),
            ),
          ),
          // Each preview scales its own box down to fit the gallery column
          // while keeping the stage's real aspect ratio, so PosterMetrics sees
          // the size the tier is meant to be.
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double scale = constraints.maxWidth < width
                  ? constraints.maxWidth / width
                  : 1.0;
              return SizedBox(
                width: width * scale,
                height: height * scale,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: const PosterMetricsScope(child: PosterBackdrop()),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
