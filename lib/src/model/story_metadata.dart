import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/utils/database_values.dart';

const storyLifetime = Duration(hours: 24);
const maxStoryLifetime = Duration(days: 30);

AdditionalMessageData? storyMetadata(List<int>? bytes) {
  if (bytes == null) return null;
  try {
    return AdditionalMessageData.fromBuffer(bytes);
  } on Object {
    return null;
  }
}

DateTime storyDeadline(DateTime postedAt, List<int>? metadata) {
  final data = storyMetadata(metadata);
  final maximum = postedAt.add(maxStoryLifetime);
  if (data == null || !data.hasStoryExpiresAtMs()) {
    return postedAt.add(storyLifetime);
  }
  // Compare integers before constructing a DateTime: an untrusted protobuf
  // timestamp can exceed Dart's supported date range.
  final milliseconds = data.storyExpiresAtMs.toInt();
  return DateTime.fromMillisecondsSinceEpoch(
    milliseconds.clamp(-8640000000000000, maximum.millisecondsSinceEpoch),
  );
}

DateTime messageStoryDeadline(StoredMessage message) =>
    storyDeadline(message.createdAt, message.additionalMessageData);

PhotoLocationData? storyLocation(StoredMessage message) {
  final data = storyMetadata(message.additionalMessageData);
  if (data == null || !data.hasPhotoLocation()) return null;
  final location = data.photoLocation;
  if (!location.latitude.isFinite ||
      !location.longitude.isFinite ||
      location.latitude < -90 ||
      location.latitude > 90 ||
      location.longitude < -180 ||
      location.longitude > 180) {
    return null;
  }
  return location;
}
