import 'package:flutter/material.dart';

/// A blocky "pixel dissolve": the child is broken into a grid of blocks that
/// each fade their own opacity out (or in) in a random, glitchy order as
/// [progress] runs. [progress] 1 = fully present, 0 = fully gone.
///
/// The fade is done by painting [coverColor] — the colour showing behind the
/// child — over each block at rising opacity, so a fully-covered block reads as
/// having faded to nothing. Each block picks up its own stable reveal threshold
/// (so the order looks scattered, not a clean sweep) with a little per-frame
/// jitter on the wavefront; bump [seed] every frame to make that edge fizz.
class PixelDissolve extends StatelessWidget {
  const PixelDissolve({
    super.key,
    required this.child,
    required this.progress,
    required this.seed,
    required this.coverColor,
    this.blockSize = 24,
  });

  final Widget child;

  /// 1 = fully present (no-op), 0 = every block faded to nothing.
  final double progress;

  /// Reseeds the wavefront jitter; bump per frame for shimmer.
  final int seed;

  /// The colour showing behind the child — painted over blocks as they fade, so
  /// a covered block reads as gone.
  final Color coverColor;

  /// Approximate side of each dissolve block, in logical px.
  final double blockSize;

  @override
  Widget build(BuildContext context) {
    if (progress >= 0.999) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _DissolvePainter(
                progress: progress,
                seed: seed,
                cover: coverColor,
                blockSize: blockSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DissolvePainter extends CustomPainter {
  const _DissolvePainter({
    required this.progress,
    required this.seed,
    required this.cover,
    required this.blockSize,
  });

  final double progress;
  final int seed;
  final Color cover;
  final double blockSize;

  /// How far past its threshold a block travels while fading, as a fraction of
  /// [progress]. Small, so each block's opacity animates quickly but smoothly.
  static const _fadeBand = 0.18;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final cols = (size.width / blockSize).ceil().clamp(1, 220);
    final rows = (size.height / blockSize).ceil().clamp(1, 220);
    final bw = size.width / cols;
    final bh = size.height / rows;
    final paint = Paint();

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        // Stable per-block threshold, mapped into [_fadeBand, 1] so that at
        // progress 1 every block is fully present and at progress 0 every block
        // has fully faded — the dissolve is complete exactly when progress
        // hits 0, with nothing left mid-fade for the resize to start over.
        final threshold =
            _fadeBand + _rand(c * 92821 + r * 68917) * (1 - _fadeBand);
        // A small per-frame wobble so the fading wavefront fizzes instead of
        // marching cleanly.
        final wobble =
            (_rand(c * 40503 + r * 51787 + seed * 15485863) - 0.5) * 0.05;
        final t = threshold + wobble;
        // Block is fully present while progress >= t, fully gone once progress
        // drops to t - _fadeBand, its opacity animating across that window.
        final coverAlpha =
            1 - ((progress - (t - _fadeBand)) / _fadeBand).clamp(0.0, 1.0);
        if (coverAlpha <= 0.001) continue;
        paint.color = cover.withOpacity(coverAlpha.clamp(0.0, 1.0));
        // +1 to close the seams between neighbouring blocks.
        canvas.drawRect(Rect.fromLTWH(c * bw, r * bh, bw + 1, bh + 1), paint);
      }
    }
  }

  /// Cheap deterministic hash → [0, 1).
  double _rand(int n) {
    var x = n & 0x7fffffff;
    x = (x ^ (x >> 13)) * 1274126177;
    x &= 0x7fffffff;
    return (x % 100000) / 100000.0;
  }

  @override
  bool shouldRepaint(_DissolvePainter old) =>
      old.progress != progress || old.seed != seed || old.cover != cover;
}
