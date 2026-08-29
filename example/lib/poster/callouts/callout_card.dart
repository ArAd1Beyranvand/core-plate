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
  /// horizontal leg along its bottom — with the body starting at the top of
  /// the vertical leg, to its right.
  Widget _buildLRuleBody(PosterMetrics metrics, TextDirection direction) {
    final Color ruleColor = _dashedRuleColor(metrics);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: metrics.px(16)),
                  child: Directionality(
                    textDirection: direction,
                    child: _buildTitle(metrics, direction),
                  ),
                ),
                const Spacer(),
                SizedBox(height: metrics.px(14)),
                DashedRule.thin(color: ruleColor),
              ],
            ),
          ),
          VerticalDashedRule(color: ruleColor),
          if (spec.body != null)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: metrics.px(16),
                  right: spec.hasEuBadge ? metrics.px(30) : 0,
                ),
                child: Directionality(
                  textDirection: direction,
                  child: Text(spec.body!, style: _bodyStyle(metrics.f)),
                ),
              ),
            ),
        ],
      ),
    );
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
