import 'package:flutter/material.dart';

import '../device_preview/device_config.dart';
import 'annotation_callout.dart';

/// The two left-hand and two right-hand callouts shown for one device.
@immutable
class CalloutSet {
  const CalloutSet({required this.left, required this.right});

  /// Exactly two callouts, top then bottom.
  final List<AnnotationCallout> left;
  final List<AnnotationCallout> right;
}

const Map<DeviceType, CalloutSet> calloutSets = {
  DeviceType.desktop: CalloutSet(
    left: [
      AnnotationCallout(
        index: '01',
        label: 'کشورها',
        title: 'پشتیبانی از دو کشور',
        body: 'پلاک ایران و آلمان، بدون یک خط تغییر در ویجت‌ها.',
        side: CalloutSide.left,
      ),
      AnnotationCallout(
        index: '03',
        label: 'VARIANTS',
        title: 'Cars and motorbikes',
        body: 'Single-row and two-row plates, same package.',
        side: CalloutSide.left,
      ),
    ],
    right: [
      AnnotationCallout(
        index: '02',
        label: 'COUNTRIES',
        title: 'Two countries, one widget',
        body: 'Iranian and German plates ship in the box.',
        side: CalloutSide.right,
      ),
      AnnotationCallout(
        index: '04',
        label: 'متن‌باز',
        title: 'ساخته‌ٔ ایران، متن‌باز',
        body: 'کد کامل روی گیت‌هاب، آزاد برای همه.',
        side: CalloutSide.right,
      ),
    ],
  ),
  DeviceType.mobile: CalloutSet(
    left: [
      AnnotationCallout(
        index: '05',
        label: 'VALIDATION',
        title: 'Checks as you type',
        body: 'Plate rules are verified field by field.',
        side: CalloutSide.left,
      ),
      AnnotationCallout(
        index: '07',
        label: 'حالت‌های خاص',
        title: 'خیلی از حالت‌های خاص هندل شده',
        body: 'آن‌هایی که معمولاً از قلم می‌افتند، از قبل دیده شده‌اند.',
        side: CalloutSide.left,
      ),
    ],
    right: [
      AnnotationCallout(
        index: '06',
        label: 'تنظیمات',
        title: 'قابل تنظیم',
        body: 'هر بخش از پلاک را به دلخواه خودت تغییر بده.',
        side: CalloutSide.right,
      ),
      AnnotationCallout(
        index: '08',
        label: 'THEMING',
        title: 'Yours to configure',
        body: 'Colours, sizes, flags and keyboard behaviour.',
        side: CalloutSide.right,
      ),
    ],
  ),
  DeviceType.tablet: CalloutSet(
    left: [
      AnnotationCallout(
        index: '09',
        label: 'کیبورد',
        title: 'کیبورد اختصاصی',
        body: 'صفحه‌کلید مخصوص پلاک، مستقیم روی صفحه.',
        side: CalloutSide.left,
      ),
      AnnotationCallout(
        index: '11',
        label: 'SOURCE',
        title: 'On GitHub and pub.dev',
        body: 'Open source, ready to drop into your app.',
        side: CalloutSide.left,
      ),
    ],
    right: [
      AnnotationCallout(
        index: '10',
        label: 'PLATFORMS',
        title: 'Everywhere but iOS',
        body: 'Every Flutter target we could test on.',
        side: CalloutSide.right,
      ),
      AnnotationCallout(
        index: '12',
        label: 'پلتفرم',
        title: 'طراحی‌شده برای ویندوز، وب، اندروید و لینوکس',
        body: 'یک کد، چهار پلتفرم.',
        side: CalloutSide.right,
      ),
    ],
  ),
};
