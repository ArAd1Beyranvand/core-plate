import 'package:flutter/material.dart';

import '../cards/bevel_panel.dart';
import '../cards/card_decorations.dart';
import '../cards/dashed_rule.dart';
import '../poster_scale.dart';
import '../poster_tokens.dart';
import 'callout_data.dart';

class CalloutCard extends StatelessWidget {
  const CalloutCard({super.key, required this.spec, this.widthDesignPx});

  final CalloutSpec spec;
  final double? widthDesignPx;

  BevelKind get _bevelKind {
    switch (spec.kind) {
      case CalloutKind.heroIr:
      case CalloutKind.heroDe:
        return BevelKind.hero;
      case CalloutKind.steel:
        return BevelKind.steel;
      case CalloutKind.dark:
        return BevelKind.dark;
    }
  }

  Color? get _groundColor {
    switch (spec.kind) {
      case CalloutKind.heroIr:
        return PosterColors.cardHeroIr;
      case CalloutKind.heroDe:
        return PosterColors.cardHeroDe;
      case CalloutKind.steel:
      case CalloutKind.dark:
        return null;
    }
  }

  Gradient? get _groundGradient {
    switch (spec.kind) {
      case CalloutKind.steel:
      case CalloutKind.dark:
        // Each numbered card gets its own plate-face colour so they don't read
        // as one repeated slab — blues echo the hero cards, 07/08/11 are a
        // green family, 02/03 share a slate tone.
        return PosterGradients.calloutFace(spec.index);
      case CalloutKind.heroIr:
      case CalloutKind.heroDe:
        return null;
    }
  }

  TextStyle _titleStyle(double f) {
    final size = spec.titleSizeDesignPx;
    if (spec.textDirection == TextDirection.rtl) {
      return PosterType.cardTitleFa(f, size);
    }
    switch (spec.kind) {
      case CalloutKind.heroIr:
      case CalloutKind.heroDe:
        if (size >= 40) {
          return PosterType.cardTitleEnHero(f, size);
        } else {
          return PosterType.cardTitleEnSmall(f, size);
        }
      case CalloutKind.steel:
      case CalloutKind.dark:
        return PosterType.cardTitleEnSmall(f, size);
    }
  }

  TextStyle _bodyStyle(double f) {
    if (spec.textDirection == TextDirection.rtl) {
      return PosterType.cardBodyFa(f, spec.bodySizeDesignPx);
    }
    return PosterType.cardBodyEn(f, spec.bodySizeDesignPx);
  }

  Widget _buildTitle(PosterMetrics metrics, TextDirection direction) {
    final baseStyle = _titleStyle(metrics.f);

    if (spec.title.startsWith(RegExp(r'\d'))) {
      final digitMatch = RegExp(r'^(\d+)(.*)').firstMatch(spec.title);
      if (digitMatch != null) {
        final digit = digitMatch.group(1)!;
        final rest = digitMatch.group(2)!;

        return RichText(
          textAlign: spec.isCentered ? TextAlign.center : TextAlign.start,
          text: TextSpan(
            children: [
              TextSpan(
                text: digit,
                style: baseStyle.copyWith(
                  color: const Color(0xFFE53935),
                  fontWeight: FontWeight.w900,
                  fontSize: (baseStyle.fontSize ?? 24) * 1.2,
                ),
              ),
              TextSpan(text: rest, style: baseStyle),
            ],
          ),
        );
      }
    }

    return Text(
      spec.title,
      style: baseStyle,
      textAlign: spec.isCentered ? TextAlign.center : null,
    );
  }

  Color _dashedRuleColor(PosterMetrics metrics) {
    switch (spec.kind) {
      case CalloutKind.heroIr:
      case CalloutKind.heroDe:
        return PosterColors.inkDisplay3.withValues(alpha: 0.5);
      case CalloutKind.steel:
        return PosterColors.inkDisplay3.withValues(alpha: 0.5);
      case CalloutKind.dark:
        return PosterColors.inkDisplay3.withValues(alpha: 0.4);
    }
  }

  /// Title boxed by an L of dashed rule — vertical leg down its right edge,
  /// horizontal leg along its bottom — with the body flowing around it: the
  /// first lines sit in the column right of the vertical leg, the rest run
  /// full width under the horizontal one.
  Widget _buildLRuleBody(PosterMetrics metrics, TextDirection direction) {
    final Color ruleColor = _dashedRuleColor(metrics);
    final TextStyle bodyStyle = _bodyStyle(metrics.f);
    final Widget title = DashedLBorder(
      color: ruleColor,
      child: Directionality(
        textDirection: direction,
        child: _buildTitle(metrics, direction),
      ),
    );

    if (spec.body == null) return title;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // The L sizes itself to the title, so measure the title to learn how
        // deep and how wide the notch the body has to flow around is.
        final TextPainter titlePainter = TextPainter(
          text: TextSpan(text: spec.title, style: _titleStyle(metrics.f)),
          textDirection: direction,
        )..layout();
        final double notchWidth =
            titlePainter.width + metrics.px(DashedLBorder.defaultInset + 2);
        final double notchHeight =
            titlePainter.height + metrics.px(DashedLBorder.defaultInset + 2);

        final double gap = metrics.px(14);
        final double trailing = spec.hasEuBadge ? metrics.px(30) : 0;
        final double columnWidth =
            constraints.maxWidth - notchWidth - gap - trailing;

        final int split = columnWidth <= 0
            ? 0
            : _splitBodyAt(
                text: spec.body!,
                style: bodyStyle,
                direction: direction,
                width: columnWidth,
                height: notchHeight,
              );
        final String beside = spec.body!.substring(0, split).trimRight();
        final String below = spec.body!.substring(split).trimLeft();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                title,
                SizedBox(width: gap),
                if (beside.isNotEmpty)
                  SizedBox(
                    width: columnWidth,
                    child: Directionality(
                      textDirection: direction,
                      child: Text(beside, style: bodyStyle),
                    ),
                  ),
              ],
            ),
            if (below.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: metrics.px(6), right: trailing),
                child: Directionality(
                  textDirection: direction,
                  child: Text(below, style: bodyStyle),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Index in [text] of the first character that no longer fits in a [width]
  /// by [height] column — i.e. where the body has to drop below the L.
  int _splitBodyAt({
    required String text,
    required TextStyle style,
    required TextDirection direction,
    required double width,
    required double height,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
    )..layout(maxWidth: width);

    final List<LineMetrics> lines = painter.computeLineMetrics();
    double consumed = 0;
    int lastFitting = -1;
    for (int i = 0; i < lines.length; i++) {
      consumed += lines[i].height;
      if (consumed > height) break;
      lastFitting = i;
    }
    if (lastFitting < 0) return 0;
    if (lastFitting == lines.length - 1) return text.length;

    // End of the last fitting line: probe just past its right edge.
    return painter
        .getPositionForOffset(Offset(width, lines[lastFitting].baseline))
        .offset;
  }

  @override
  Widget build(BuildContext context) {
    final metrics = PosterMetrics.of(context);
    final direction = spec.textDirection;

    Widget cardContent = Padding(
      padding: EdgeInsets.fromLTRB(
        metrics.px(24),
        spec.isCentered ? metrics.px(18) : metrics.px(22),
        metrics.px(24),
        spec.isCentered ? metrics.px(18) : metrics.px(22),
      ),
      child: spec.hasLRule
          ? _buildLRuleBody(metrics, direction)
          : Column(
              mainAxisAlignment: spec.isCentered
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              crossAxisAlignment: spec.isCentered
                  ? CrossAxisAlignment.center
                  : (direction == TextDirection.rtl
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start),
              children: <Widget>[
                // Title
                Directionality(
                  textDirection: direction,
                  child: _buildTitle(metrics, direction),
                ),
                if (!spec.isCentered) SizedBox(height: metrics.px(14)),

                // Dashed rule
                if (spec.hasDashedRule && !spec.hasDivider)
                  DashedRule.thin(color: _dashedRuleColor(metrics)),
                if (spec.hasDivider) const TwoToneDivider(),

                if (!spec.isCentered) SizedBox(height: metrics.px(14)),

                // Body
                if (spec.body != null)
                  Directionality(
                    textDirection: direction,
                    child: Text(spec.body!, style: _bodyStyle(metrics.f)),
                  ),

                // Footer (card 05)
                if (spec.hasFooter) ...[
                  SizedBox(height: metrics.px(12)),
                  const IrFlagFooter(),
                ],
              ],
            ),
    );

    // Build decorations
    if (spec.hasIrFlag) {
      // Card 01
      cardContent = Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          cardContent,
          Positioned(
            left: metrics.px(22),
            top: metrics.px(22),
            bottom: metrics.px(22),
            child: const IrFlagStrip(width: 26),
          ),
        ],
      );
    }

    if (spec.hasFadedFlag) {
      // Card 02
      cardContent = Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          cardContent,
          Positioned(
            right: metrics.px(20),
            top: metrics.px(20),
            bottom: metrics.px(20),
            child: const FadedFlagStrip(width: 5),
          ),
        ],
      );
    }

    if (spec.hasEuBadge) {
      // Card 09
      cardContent = Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          cardContent,
          Positioned(
            right: metrics.px(14),
            top: metrics.px(22),
            child: const EuBadgeColumn(width: 34),
          ),
        ],
      );
    }

    if (spec.hasFlareTag) {
      // Card 09
      cardContent = Stack(
        children: <Widget>[
          cardContent,
          Positioned(right: 0, bottom: metrics.px(14), child: const RedTag()),
        ],
      );
    }

    if (spec.hasDeBranding) {
      // Card 10
      cardContent = Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          cardContent,
          Positioned(
            right: metrics.px(16),
            top: metrics.px(16),
            bottom: metrics.px(16),
            child: const DeStrip(width: 8),
          ),
        ],
      );
    }

    // Main card with bevel panel
    final Widget card = BevelPanel(
      style: BevelStyle.byKind[_bevelKind]!,
      groundColor: _groundColor,
      groundGradient: _groundGradient,
      child: SizedBox(
        width: metrics.px(widthDesignPx ?? spec.widthFx * 1920),
        child: cardContent,
      ),
    );

    return card;
  }
}
