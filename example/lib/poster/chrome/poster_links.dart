import 'package:flutter/material.dart';

import '../cards/bevel_panel.dart';
import '../poster_scale.dart';
import '../poster_tokens.dart';

/// The two link buttons from DESIGN_SPEC.md §6 "Chrome": `PUB.DEV` and
/// `GITHUB`, anchored at `.039, .778`.
///
/// Each is a [BevelPanel] (link-button ground) with a `CustomPainter` icon
/// (18 design px) and a Martian Mono `wght 700` `.20em` label, padding
/// `13 18 14`, gap 10. On hover the ground goes to `#EDEFF3` and the label and
/// icon invert to dark.
///
/// `url_launcher` is NOT a dependency of `example/pubspec.yaml`, and §6 says
/// to add one only if it is already present — so the tap is a deliberate
/// no-op here. Reported to the migration owner; wire a launcher in later if
/// desired.
class PosterLinks extends StatelessWidget {
  const PosterLinks({super.key});

  static const String pubDevUrl = 'https://pub.dev/packages/plate_number';
  static const String githubUrl =
      'https://github.com/ArAd1Beyranvand/plate-number-upgrade';

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _LinkButton(
          label: 'PUB.DEV',
          url: pubDevUrl,
          iconBuilder: (Color color) => _CubeIcon(color: color),
        ),
        SizedBox(height: metrics.px(8)),
        _LinkButton(
          label: 'GITHUB',
          url: githubUrl,
          iconBuilder: (Color color) => _OctocatIcon(color: color),
        ),
      ],
    );
  }
}

typedef _IconBuilder = Widget Function(Color color);

class _LinkButton extends StatefulWidget {
  const _LinkButton({
    required this.label,
    required this.url,
    required this.iconBuilder,
  });

  final String label;
  final String url;
  final _IconBuilder iconBuilder;

  @override
  State<_LinkButton> createState() => _LinkButtonState();
}

class _LinkButtonState extends State<_LinkButton> {
  bool _hovered = false;

  void _onTap() {
    // No-op: url_launcher is not a dependency (see class doc). The button
    // still reads as interactive so the composition is faithful.
  }

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    final bool hovered = _hovered;

    // Ground and content invert on hover.
    final Color contentColor =
        hovered ? const Color(0xFF12141B) : PosterColors.inkDisplay1;
    final double iconSize = metrics.px(29);

    final Widget panel = BevelPanel(
      style: BevelStyle.dark,
      groundColor: hovered ? PosterGradients.linkButtonHover : PosterColors.cardHeroDe,
      groundGradient: hovered ? null : null,
      screenGrain: false,
      shadow: BevelShadow.none,
      padding: const EdgeInsets.fromLTRB(29, 21, 29, 22),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: widget.iconBuilder(contentColor),
          ),
          SizedBox(width: metrics.px(8)),
          Text(
            widget.label,
            style: PosterType.linkLabel(metrics.f * 1.6).copyWith(color: contentColor),
          ),
        ],
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _onTap,
        child: panel,
      ),
    );
  }
}

/// A wireframe cube — the pub.dev mark, redrawn per §6 (icon 18px).
class _CubeIcon extends StatelessWidget {
  const _CubeIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CubePainter(color));
  }
}

class _CubePainter extends CustomPainter {
  const _CubePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Isometric-ish cube: a top rhombus, two visible side faces, and the
    // three interior edges meeting at the centre.
    final Offset top = Offset(w * 0.5, h * 0.06);
    final Offset right = Offset(w * 0.94, h * 0.29);
    final Offset bottom = Offset(w * 0.5, h * 0.52);
    final Offset left = Offset(w * 0.06, h * 0.29);
    final Offset botRight = Offset(w * 0.94, h * 0.71);
    final Offset botLeft = Offset(w * 0.06, h * 0.71);
    final Offset botCentre = Offset(w * 0.5, h * 0.94);

    final Path outline = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(botRight.dx, botRight.dy)
      ..lineTo(botCentre.dx, botCentre.dy)
      ..lineTo(botLeft.dx, botLeft.dy)
      ..lineTo(left.dx, left.dy)
      ..close();
    canvas.drawPath(outline, stroke);

    // Interior Y — the three edges into the centre.
    final Path inner = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(right.dx, right.dy)
      ..moveTo(bottom.dx, bottom.dy)
      ..lineTo(botCentre.dx, botCentre.dy);
    canvas.drawPath(inner, stroke);
  }

  @override
  bool shouldRepaint(_CubePainter oldDelegate) => oldDelegate.color != color;
}

/// A circled octocat — the GitHub mark, redrawn per §6 (icon 18px).
class _OctocatIcon extends StatelessWidget {
  const _OctocatIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _OctocatPainter(color));
  }
}

class _OctocatPainter extends CustomPainter {
  const _OctocatPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final Offset c = size.center(Offset.zero);
    final Paint fill = Paint()..color = color;
    final Paint ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07;

    // Enclosing circle.
    canvas.drawCircle(c, w * 0.46, ring);

    // A compact octocat silhouette: head, two ears, and the trailing tentacle.
    final double r = w * 0.30;
    final Path cat = Path();

    // Head.
    cat.addOval(Rect.fromCircle(center: c.translate(0, -w * 0.02), radius: r));

    // Ears.
    cat.moveTo(c.dx - r * 0.75, c.dy - r * 0.75);
    cat.lineTo(c.dx - r * 1.15, c.dy - r * 1.25);
    cat.lineTo(c.dx - r * 0.30, c.dy - r * 0.95);
    cat.close();
    cat.moveTo(c.dx + r * 0.75, c.dy - r * 0.75);
    cat.lineTo(c.dx + r * 1.15, c.dy - r * 1.25);
    cat.lineTo(c.dx + r * 0.30, c.dy - r * 0.95);
    cat.close();

    // Body / tentacle sweep below the head.
    cat.moveTo(c.dx - r * 0.55, c.dy + r * 0.55);
    cat.quadraticBezierTo(
      c.dx, c.dy + r * 1.5,
      c.dx + r * 0.55, c.dy + r * 0.55,
    );
    cat.quadraticBezierTo(
      c.dx + r * 0.2, c.dy + r * 1.1,
      c.dx, c.dy + r * 0.5,
    );
    cat.close();

    canvas.drawPath(cat, fill);
    // Eyes are below perceptible detail at 18px, so the silhouette is left
    // clean rather than muddied with sub-pixel dots.
  }

  @override
  bool shouldRepaint(_OctocatPainter oldDelegate) =>
      oldDelegate.color != color;
}
