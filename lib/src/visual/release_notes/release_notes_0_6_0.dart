import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/release_notes.comp.dart';

ReleaseNotesData releaseNotes060(BuildContext context) {
  final lang = context.lang;
  return ReleaseNotesData(
    version: '0.6.0',
    title: lang.releaseNotesTitle,
    introduction: lang.releaseNotesIntroduction,
    additionalChangesTitle: lang.releaseNotesAlsoImproved,
    closeLabel: lang.close,
    features: [
      ReleaseNoteFeature(
        icon: const FaIcon(FontAwesomeIcons.noteSticky),
        title: lang.releaseNotesStickers,
        description: lang.releaseNotesStickersDescription,
      ),
      ReleaseNoteFeature(
        icon: const FaIcon(FontAwesomeIcons.tableCellsLarge),
        title: lang.releaseNotesWidgets,
        description: lang.releaseNotesWidgetsDescription,
      ),
      ReleaseNoteFeature(
        icon: const FaIcon(FontAwesomeIcons.circlePlay),
        title: lang.releaseNotesStories,
        description: lang.releaseNotesStoriesDescription,
      ),
      ReleaseNoteFeature(
        icon: const FaIcon(FontAwesomeIcons.gamepad),
        title: lang.releaseNotesMiniGames,
        description: lang.releaseNotesMiniGamesDescription,
      ),
    ],
    additionalChanges: [
      lang.releaseNotesReliableMessages,
      lang.releaseNotesImprovedUi,
      lang.releaseNotesCustomAvatars,
      lang.releaseNotesArabic,
    ],
  );
}
