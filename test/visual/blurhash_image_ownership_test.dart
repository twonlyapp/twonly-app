import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'disposing one image stream leaves the decoded image and other streams usable',
    () async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(
        recorder,
      ).drawColor(const ui.Color(0xff123456), ui.BlendMode.src);
      final picture = recorder.endRecording();
      final original = await picture.toImage(2, 2);
      picture.dispose();

      Future<(ImageStreamCompleter, ImageStreamListener, ImageInfo)>
      load() async {
        final completer = UiImage(original).loadImage(
          UiImage(original),
          (buffer, {getTargetSize}) => throw UnimplementedError(),
        );
        final ready = Completer<ImageInfo>();
        final listener = ImageStreamListener(
          (info, _) => ready.complete(info),
          onError: ready.completeError,
        );
        completer.addListener(listener);
        return (completer, listener, await ready.future);
      }

      final (first, listener1, info1) = await load();
      info1.dispose();
      first.removeListener(listener1);
      // Evicting the first completer used to dispose the shared decoded handle.
      final (second, listener2, info2) = await load();
      original.dispose();
      final clone = info2.clone();
      expect(await clone.image.toByteData(), isNotNull);
      clone.dispose();
      info2.dispose();
      second.removeListener(listener2);
    },
  );
}
