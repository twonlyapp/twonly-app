import 'package:twonly/src/visual/components/release_notes.comp.dart';
import 'package:twonly/src/visual/release_notes/release_notes_0_6_0.dart';

/// All release notices, oldest first. Append new ones at the end.
final List<ReleaseNotice> releaseNotices = [
  ReleaseNotice(
    version: releaseNotes060Version,
    show: (context) =>
        showReleaseNotesBottomSheet(context, releaseNotes060(context)),
  ),
];

/// New accounts already start with everything announced so far.
String get latestReleaseNoticeVersion => releaseNotices.last.version;
