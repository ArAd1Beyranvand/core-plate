import 'package:flutter/material.dart';

import '../poster/cards/bevel_panel.dart';
import '../poster/cards/card_decorations.dart';
import '../poster/cards/dashed_rule.dart';
import '../poster/poster_scale.dart';
import '../poster/poster_tokens.dart';

/// A throwaway gallery for the DESIGN_SPEC.md §4 bevel primitives: every
/// [BevelStyle] at a realistic card size, LTR and RTL, with and without screw
/// dots, over the stage black. Run with:
///
///   flutter run -t lib/dev/bevel_gallery.dart
void main() => runApp(const BevelGallery());

class BevelGallery extends StatelessWidget {
  const BevelGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: PosterColors.stageBlack,
        appBar: AppBar(
          backgroundColor: PosterColors.pageBlack,
          foregroundColor: PosterColors.inkDisplay1,
          title: const Text('Bevel panels'),
        ),
        body: PosterMetricsScope(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                _Label('hero — IR ground, screw dots'),
                _Sample(
                  kind: BevelKind.hero,
                  widthDesignPx: 536,
                  screws: true,
                ),
                _Gap(),
                _Label('hero — DE ground, EU badge + red tag, no screws'),
                _Sample(
                  kind: BevelKind.hero,
                  german: true,
                  widthDesignPx: 400,
                  euBadge: true,
                  redTag: true,
                ),
                _Gap(),
                _Label('steel — dashed rule, DE strip'),
                _Sample(
                  kind: BevelKind.steel,
                  widthDesignPx: 350,
                  screws: true,
                  dashedRule: true,
                  deStrip: true,
                ),
                _Gap(),
                _Label('dark — LTR, no screws'),
                _Sample(kind: BevelKind.dark, widthDesignPx: 366),
                _Gap(),
                _Label('dark — RTL, screws right'),
                _Sample(
                  kind: BevelKind.dark,
                  widthDesignPx: 306,
                  rtl: true,
                  screws: true,
                ),
                _Gap(),
                _Label('hero — RTL (card 05): divider, flag footer, IR strip'),
                _Sample(
                  kind: BevelKind.hero,
                  widthDesignPx: 386,
                  rtl: true,
                  screws: true,
                  divider: true,
                  flagFooter: true,
                  irStrip: true,
                ),
                _Gap(),
                _Label('dashed rules — 8/16 at 2px, 10/20 at 3px'),
                _RuleRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: PosterType.metaWeak(metrics.f).copyWith(fontSize: 13),
      ),
    );
  }
}

class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) => const SizedBox(height: 56);
}

class _Sample extends StatelessWidget {
  const _Sample({
    required this.kind,
    required this.widthDesignPx,
    this.german = false,
    this.rtl = false,
    this.screws = false,
    this.dashedRule = false,
    this.divider = false,
    this.flagFooter = false,
    this.irStrip = false,
    this.deStrip = false,
    this.euBadge = false,
    this.redTag = false,
  });

  final BevelKind kind;
  final double widthDesignPx;
  final bool german;
  final bool rtl;
  final bool screws;
  final bool dashedRule;
  final bool divider;
  final bool flagFooter;
  final bool irStrip;
  final bool deStrip;
  final bool euBadge;
  final bool redTag;

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    final bool hero = kind == BevelKind.hero;

    final Widget panel = BevelPanel(
      style: BevelStyle.byKind[kind]!,
      groundColor: bevelGroundColor(kind, german: german),
      groundGradient: bevelGroundGradient(kind),
      screws: screws ? const ScrewDots() : null,
      width: widthDesignPx,
      padding: const EdgeInsets.fromLTRB(40, 38, 40, 38),
      child: Column(
        crossAxisAlignment:
            rtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            rtl ? 'حالت‌های خاص' : 'COUNTRIES',
            style: (hero
                    ? PosterType.cardEyebrowHero(metrics.f)
                    : kind == BevelKind.steel
                        ? PosterType.cardEyebrowSteel(metrics.f)
                        : PosterType.cardEyebrowDark(metrics.f))
                .copyWith(
              color: hero ? PosterColors.inkDisplayCut : null,
            ),
          ),
          SizedBox(height: metrics.px(18)),
          Text(
            rtl ? 'کلیدهای فارسی' : 'Two countries,\none widget',
            textAlign: rtl ? TextAlign.right : TextAlign.left,
            style: (rtl
                    ? PosterType.cardTitleFa(metrics.f, 34)
                    : hero
                        ? PosterType.cardTitleEnHero(metrics.f, 52)
                        : PosterType.cardTitleEnSmall(metrics.f, 34))
                .copyWith(color: PosterColors.inkDisplay1),
          ),
          if (divider) ...<Widget>[
            SizedBox(height: metrics.px(18)),
            const TwoToneDivider(),
          ],
          if (dashedRule) ...<Widget>[
            SizedBox(height: metrics.px(18)),
            const DashedRule.thin(color: Color(0x8CE2EEFF)),
          ],
          SizedBox(height: metrics.px(18)),
          Text(
            rtl
                ? 'آن‌هایی که معمولاً از قلم می‌افتند.'
                : 'Iranian and German plates ship in the box.',
            textAlign: rtl ? TextAlign.right : TextAlign.left,
            style: (rtl
                    ? PosterType.cardBodyFa(metrics.f, 19)
                    : PosterType.cardBodyEn(metrics.f, 20))
                .copyWith(color: PosterColors.inkDisplay3),
          ),
          if (flagFooter) ...<Widget>[
            SizedBox(height: metrics.px(22)),
            const IrFlagFooter(),
          ],
          if (redTag) ...<Widget>[
            SizedBox(height: metrics.px(22)),
            const RedTag(),
          ],
        ],
      ),
    );

    final Widget stacked = Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        panel,
        if (irStrip)
          Positioned(
            left: rtl ? null : metrics.px(22),
            right: rtl ? metrics.px(22) : null,
            top: metrics.px(22),
            bottom: metrics.px(22),
            child: const IrFlagStrip(),
          ),
        if (deStrip)
          Positioned(
            right: metrics.px(16),
            top: metrics.px(16),
            bottom: metrics.px(16),
            child: const DeStrip(),
          ),
        if (euBadge)
          Positioned(
            left: metrics.px(16),
            top: metrics.px(16),
            bottom: metrics.px(16),
            child: const EuBadgeColumn(),
          ),
      ],
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 40, top: 40),
        child: Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: stacked,
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const <Widget>[
        SizedBox(
          width: 420,
          child: DashedRule.thin(color: Color(0xB8E2EEFF)),
        ),
        SizedBox(height: 24),
        SizedBox(
          width: 420,
          child: DashedRule.thick(color: Color(0x52E2EEFF)),
        ),
      ],
    );
  }
}
