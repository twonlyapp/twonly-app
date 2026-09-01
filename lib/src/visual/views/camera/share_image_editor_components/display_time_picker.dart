import 'package:flutter/material.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/views/camera/share_image_contact_selection_components/select_show_time.dart';

const _displayTimeOptionsInMs = <int?>[
  1000,
  2000,
  3000,
  4000,
  5000,
  6000,
  7000,
  8000,
  9000,
  10000,
  15000,
  20000,
  null, // unlimited
];

/// Lets the user choose how long the receiver may look at the media.
///
/// Videos have no picker, for them this only toggles between playing once and
/// looping. [onChanged] is called whenever the limit was updated, the picker
/// stays open while the user scrolls through the options.
Future<void> showDisplayTimePicker(
  BuildContext context, {
  required MediaFileService mediaService,
  required VoidCallback onChanged,
}) async {
  final media = mediaService.mediaFile;

  if (media.type == MediaType.video) {
    await mediaService.setDisplayLimit(
      (media.displayLimitInMilliseconds == null) ? 0 : null,
    );
    if (!context.mounted) return;
    onChanged();
    return;
  }

  var initialItem = _displayTimeOptionsInMs.length - 1;
  if (media.displayLimitInMilliseconds != null) {
    initialItem = _displayTimeOptionsInMs.indexOf(
      media.displayLimitInMilliseconds,
    );
    if (initialItem == -1) {
      initialItem = _displayTimeOptionsInMs.length - 1;
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.black,
    builder: (sheetContext) {
      return SelectShowTime(
        initialItem: initialItem,
        options: _displayTimeOptionsInMs,
        setMaxShowTime: (maxShowTime, storeAsDefault) async {
          await mediaService.setDisplayLimit(maxShowTime);
          if (!context.mounted) return;
          onChanged();
          if (storeAsDefault) {
            await UserService.update((user) {
              user.defaultShowTime = maxShowTime;
            });
          }
        },
      );
    },
  );
}
