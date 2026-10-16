import 'package:flutter/material.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';

Color getMessageColorFromType(
  Message message,
  MediaFile? mediaFile,
  BuildContext context,
) {
  if (message.type == MessageType.restoreFlameCounter.name) {
    return context.appColor(AppColor.messageRestore);
  }
  if (message.type == MessageType.text.name) {
    return context.appColor(AppColor.messageText);
  }
  if (message.isWidgetMedia) {
    return context.appColor(AppColor.messageWidget);
  }
  if (mediaFile == null) return context.color.onSurface;
  if (mediaFile.requiresAuthentication) return context.color.primary;
  return switch (mediaFile.type) {
    MediaType.video => context.appColor(AppColor.messageVideo),
    MediaType.audio => context.appColor(AppColor.messageAudio),
    _ => context.appColor(AppColor.messageImage),
  };
}
