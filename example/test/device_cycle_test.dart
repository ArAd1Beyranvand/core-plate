import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_number_example/device_preview/device_config.dart';
import 'package:plate_number_example/showcase/device_cycle.dart';

void main() {
  testWidgets('advances desktop -> mobile -> tablet -> desktop on demand',
      (tester) async {
    final controller = DeviceCycleController();
    final seen = <DeviceType>[];

    await tester.pumpWidget(
      DeviceCycle(
        controller: controller,
        onDeviceChanged: seen.add,
        builder: (context, device) => Text(
          device.name,
          textDirection: TextDirection.ltr,
        ),
      ),
    );

    expect(find.text('desktop'), findsOneWidget);

    controller.advance();
    await tester.pump();
    expect(find.text('mobile'), findsOneWidget);

    controller.advance();
    await tester.pump();
    expect(find.text('tablet'), findsOneWidget);

    controller.advance();
    await tester.pump();
    expect(find.text('desktop'), findsOneWidget);

    expect(seen, [DeviceType.mobile, DeviceType.tablet, DeviceType.desktop]);
  });
}
