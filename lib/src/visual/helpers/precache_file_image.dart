import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:twonly/src/utils/log.dart';

/// A failed preload must leave the image available for a later retry.
Future<bool> precacheFileImage(
  File file,
  BuildContext context, {
  required String source,
}) async {
  var succeeded = true;
  final provider = FileImage(file);
  // precacheImage completes its future successfully even when decoding fails.
  // Only its onError callback receives image stream failures.
  await precacheImage(
    provider,
    context,
    onError: (error, stackTrace) {
      succeeded = false;
      Log.warn('Could not precache image in $source', error, stackTrace);
    },
  );
  if (!succeeded) await provider.evict();
  return succeeded;
}
