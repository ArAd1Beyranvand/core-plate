import 'package:flutter/material.dart';

enum CalloutKind { heroIr, heroDe, steel, dark }
enum CalloutSide { left, right }

class CalloutSpec {
  const CalloutSpec({
    required this.index,
    required this.kind,
    required this.side,
    required this.textDirection,
    required this.anchorFx,
    required this.anchorFy,
    required this.widthFx,
    required this.eyebrow,
    required this.title,
    this.body,
    required this.titleSizeDesignPx,
    required this.bodySizeDesignPx,
    this.hasIrFlag = false,
    this.hasFadedFlag = false,
    this.hasEuBadge = false,
    this.hasFlareTag = false,
    this.hasDivider = false,
    this.hasFooter = false,
    this.hasDeBranding = false,
    this.hasDashedRule = true,
    this.hasLRule = false,
    this.isCentered = false,
  });

  final int index;
  final CalloutKind kind;
  final CalloutSide side;
  final TextDirection textDirection;
  final double anchorFx;
  final double anchorFy;
  final double widthFx;
  final String eyebrow;
  final String title;
  final String? body;
  final double titleSizeDesignPx;
  final double bodySizeDesignPx;
  final bool hasIrFlag;
  final bool hasFadedFlag;
  final bool hasEuBadge;
  final bool hasFlareTag;
  final bool hasDivider;
  final bool hasFooter;
  final bool hasDeBranding;
  final bool hasDashedRule;

  /// Wraps the title in an L-shaped dashed rule — down its right edge and
  /// along its bottom — with the body set to the right of the vertical leg.
  final bool hasLRule;
  final bool isCentered;
}

const Map<DeviceType, List<CalloutSpec>> calloutSets = {
  DeviceType.desktop: [
    CalloutSpec(
      index: 1,
      kind: CalloutKind.heroIr,
      side: CalloutSide.left,
      textDirection: TextDirection.ltr,
      anchorFx: 0.326,
      anchorFy: 0.122,
      widthFx: 0.279,
      eyebrow: 'COUNTRIES',
      title: '2 countries,\none widget',
      body: 'Iranian and German plates ship in the box — same widget, one const swapped.',
      titleSizeDesignPx: 62,
      bodySizeDesignPx: 24,
      hasIrFlag: true,
    ),
    CalloutSpec(
      index: 3,
      kind: CalloutKind.steel,
      side: CalloutSide.right,
      textDirection: TextDirection.ltr,
      anchorFx: 0.862,
      anchorFy: 0.122,
      widthFx: 0.182,
      eyebrow: 'VARIANTS',
      title: 'Cars and\nmotorbikes',
      body: null,
      titleSizeDesignPx: 36,
      bodySizeDesignPx: 20,
      hasDashedRule: false,
      isCentered: true,
    ),
    CalloutSpec(
      index: 4,
      kind: CalloutKind.dark,
      side: CalloutSide.left,
      textDirection: TextDirection.rtl,
      anchorFx: 0.560,
      anchorFy: 0.760,
      widthFx: 0.197,
      eyebrow: 'متن باز',
      title: 'ساخت ایران متن باز',
      body: null,
      titleSizeDesignPx: 34,
      bodySizeDesignPx: 0,
      hasDashedRule: false,
      isCentered: true,
    ),
  ],
  DeviceType.mobile: [
    CalloutSpec(
      index: 5,
      kind: CalloutKind.heroIr,
      side: CalloutSide.left,
      textDirection: TextDirection.rtl,
      anchorFx: 0.433,
      anchorFy: 0.206,
      widthFx: 0.201,
      eyebrow: 'تنظیمات',
      title: 'هر بخش از پلاک\nقابل تنظیم',
      body: 'رنگ، اندازه، پرچم و رفتار صفحه کلید همه در دست تو.',
      titleSizeDesignPx: 50,
      bodySizeDesignPx: 23,
      hasDivider: true,
      hasFooter: true,
    ),
    CalloutSpec(
      index: 6,
      kind: CalloutKind.steel,
      side: CalloutSide.right,
      textDirection: TextDirection.ltr,
      anchorFx: 0.863,
      anchorFy: 0.320,
      widthFx: 0.127,
      eyebrow: 'VALIDATION',
      title: 'Checks as\nyou type',
      body: 'Plate rules are verified field by field.',
      titleSizeDesignPx: 34,
      bodySizeDesignPx: 19,
    ),
    CalloutSpec(
      index: 7,
      kind: CalloutKind.dark,
      side: CalloutSide.right,
      textDirection: TextDirection.rtl,
      anchorFx: 0.826,
      anchorFy: 0.037,
      widthFx: 0.159,
      eyebrow: 'حالت های خاص',
      title: 'حالت های خاص هندل شده',
      body: 'آن هایی که معمولاً\nاز قلم می افتند.',
      titleSizeDesignPx: 34,
      bodySizeDesignPx: 19,
    ),
  ],
  DeviceType.tablet: [
    CalloutSpec(
      index: 9,
      kind: CalloutKind.heroDe,
      side: CalloutSide.right,
      textDirection: TextDirection.ltr,
      anchorFx: 0.811,
      anchorFy: 0.059,
      // Wide enough that the body column beside the L's vertical leg still
      // reads as prose; the anchor clamps the card back onto the canvas.
      widthFx: 0.270,
      eyebrow: 'RULES',
      title: 'Live\nvalidation',
      body: 'Forbidden district and serial combinations flare red as you type — before submit, not after.',
      titleSizeDesignPx: 42,
      bodySizeDesignPx: 23,
      hasEuBadge: true,
      hasFlareTag: true,
      hasLRule: true,
    ),
    CalloutSpec(
      index: 12,
      kind: CalloutKind.dark,
      side: CalloutSide.left,
      textDirection: TextDirection.rtl,
      anchorFx: 0.560,
      anchorFy: 0.830,
      widthFx: 0.191,
      eyebrow: 'مقیاس',
      title: 'همه چیز قابل تنظیم',
      body: null,
      titleSizeDesignPx: 34,
      bodySizeDesignPx: 0,
      hasDashedRule: false,
      isCentered: true,
    ),
  ],
};

enum DeviceType { desktop, mobile, tablet }
