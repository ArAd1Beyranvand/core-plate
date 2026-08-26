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
      title: 'Two countries,\none widget',
      body: 'Iranian and German plates ship in the box — same widget, one const swapped.',
      titleSizeDesignPx: 62,
      bodySizeDesignPx: 24,
      hasIrFlag: true,
    ),
    CalloutSpec(
      index: 2,
      kind: CalloutKind.dark,
      side: CalloutSide.right,
      textDirection: TextDirection.rtl,
      anchorFx: 0.852,
      anchorFy: 0.041,
      widthFx: 0.130,
      eyebrow: 'صفحه‌کلید',
      title: 'کلیدهای فارسی',
      body: 'چیدمان حرف‌های پلاک، از پیش آماده.',
      titleSizeDesignPx: 34,
      bodySizeDesignPx: 19,
      hasFadedFlag: true,
    ),
    CalloutSpec(
      index: 3,
      kind: CalloutKind.steel,
      side: CalloutSide.left,
      textDirection: TextDirection.ltr,
      anchorFx: 0.338,
      anchorFy: 0.569,
      widthFx: 0.182,
      eyebrow: 'VARIANTS',
      title: 'Cars and\nmotorbikes',
      body: 'One-row and two-row plates, same package.',
      titleSizeDesignPx: 36,
      bodySizeDesignPx: 20,
    ),
    CalloutSpec(
      index: 4,
      kind: CalloutKind.dark,
      side: CalloutSide.left,
      textDirection: TextDirection.rtl,
      anchorFx: 0.066,
      anchorFy: 0.826,
      widthFx: 0.197,
      eyebrow: 'متن‌باز',
      title: 'ساخته‌ٔ ایران، آزاد',
      body: null,
      titleSizeDesignPx: 34,
      bodySizeDesignPx: 0,
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
      title: 'هر بخش از پلاک،\nقابل تنظیم',
      body: 'رنگ، اندازه، پرچم و رفتار صفحه‌کلید — همه در دست تو.',
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
      anchorFy: 0.248,
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
      eyebrow: 'حالت‌های خاص',
      title: 'حالت‌های خاص هندل شده',
      body: 'آن‌هایی که معمولاً از قلم می‌افتند.',
      titleSizeDesignPx: 34,
      bodySizeDesignPx: 19,
    ),
    CalloutSpec(
      index: 8,
      kind: CalloutKind.dark,
      side: CalloutSide.left,
      textDirection: TextDirection.ltr,
      anchorFx: 0.082,
      anchorFy: 0.820,
      widthFx: 0.191,
      eyebrow: 'COMPACT',
      title: 'Fits a phone',
      body: 'Twelve keys, one hand, no layout gymnastics.',
      titleSizeDesignPx: 34,
      bodySizeDesignPx: 19,
    ),
  ],
  DeviceType.tablet: [
    CalloutSpec(
      index: 9,
      kind: CalloutKind.heroDe,
      side: CalloutSide.left,
      textDirection: TextDirection.ltr,
      anchorFx: 0.311,
      anchorFy: 0.059,
      widthFx: 0.208,
      eyebrow: 'RULES',
      title: 'Live\nvalidation',
      body: 'Forbidden district and serial combinations flare red as you type — before submit, not after.',
      titleSizeDesignPx: 42,
      bodySizeDesignPx: 18,
      hasEuBadge: true,
      hasFlareTag: true,
    ),
    CalloutSpec(
      index: 10,
      kind: CalloutKind.steel,
      side: CalloutSide.right,
      textDirection: TextDirection.ltr,
      anchorFx: 0.625,
      anchorFy: 0.833,
      widthFx: 0.179,
      eyebrow: 'COUNTRY',
      title: 'Plates are\ndata',
      body: 'A new country is a const, not a new widget. This one is German.',
      titleSizeDesignPx: 36,
      bodySizeDesignPx: 20,
      hasDeBranding: true,
    ),
    CalloutSpec(
      index: 11,
      kind: CalloutKind.dark,
      side: CalloutSide.right,
      textDirection: TextDirection.ltr,
      anchorFx: 0.810,
      anchorFy: 0.033,
      widthFx: 0.167,
      eyebrow: 'TOUCH',
      title: 'Tap to type',
      body: 'An on-screen pad drives the plate, field by field, slot by slot.',
      titleSizeDesignPx: 34,
      bodySizeDesignPx: 19,
    ),
    CalloutSpec(
      index: 12,
      kind: CalloutKind.dark,
      side: CalloutSide.left,
      textDirection: TextDirection.rtl,
      anchorFx: 0.076,
      anchorFy: 0.826,
      widthFx: 0.191,
      eyebrow: 'مقیاس',
      title: 'یک بوم، هر اندازه',
      body: null,
      titleSizeDesignPx: 34,
      bodySizeDesignPx: 0,
    ),
  ],
};

enum DeviceType { desktop, mobile, tablet }
