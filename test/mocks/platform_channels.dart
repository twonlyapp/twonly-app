import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void setupPlatformChannelMocks() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (call) async {
          if (call.method == 'check') {
            return ['wifi'];
          }
          return null;
        },
      );
}
