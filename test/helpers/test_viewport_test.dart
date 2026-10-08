import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_viewport.dart';

void main() {
  testWidgets('setPhoneView configures 390x844 logical pixels', (WidgetTester tester) async {
    setPhoneView(tester);

    final Size logicalSize = Size(
      tester.view.physicalSize.width / tester.view.devicePixelRatio,
      tester.view.physicalSize.height / tester.view.devicePixelRatio,
    );

    expect(logicalSize, equals(const Size(390, 844)));
  });
}
