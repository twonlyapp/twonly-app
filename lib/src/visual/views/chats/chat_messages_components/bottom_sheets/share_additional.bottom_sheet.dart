import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor.view.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/bottom_sheets/share_location.bottom_sheet.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/bottom_sheets/webxdc_store.bottom_sheet.dart';
import 'package:twonly/src/visual/views/memories/memories_picker.view.dart';
import 'package:twonly/src/visual/views/shared/select_contacts.view.dart';

class ShareAdditionalView extends StatefulWidget {
  const ShareAdditionalView({
    required this.group,
    required this.onDismiss,
    super.key,
  });

  final Group group;
  final VoidCallback onDismiss;

  @override
  State<ShareAdditionalView> createState() => _ShareAdditionalViewState();
}

class _ShareAdditionalViewState extends State<ShareAdditionalView> {
  Future<void> openShareContactView() async {
    final group = widget.group;
    final lang = context.lang;
    widget.onDismiss();
    final selectedContacts =
        await context.navPush(
              SelectContactsView(
                text: SelectedContactView(
                  title: lang.shareContactsTitle,
                  submitButton: (_, _) => lang.shareContactsSubmit,
                  submitIcon: FontAwesomeIcons.shareNodes,
                ),
              ),
            )
            as List<int>?;
    if (selectedContacts != null && selectedContacts.isNotEmpty) {
      await RustApi.insertAndSendContactShare(
        groupId: group.groupId,
        contactIds: Int64List.fromList(selectedContacts),
      );
      if (group.isDirectChat) {
        final members = joinedGroupContacts(
          await watchRustDatabase(
            (control) => rust_groups.watchGroupContacts(
              input: db_groups.GroupMembersQuery(
                groupId: group.groupId,
                orderForChats: true,
              ),
              control: control,
            ),
          ).first,
        ).map((row) => row.$1).toList(growable: false);
        if (members.isNotEmpty) {
          await rust_contacts.updateContact(
            id: members.first.userId,
            patch: ContactPatch(
              askForFriendPromotions: NullableInt(
                value: databaseNullableFlag(false),
              ),
            ),
            transaction: currentDatabaseSession(),
          );
        }
      }
    }
  }

  Future<void> openAppStore() async {
    widget.onDismiss();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WebxdcStoreView(group: widget.group),
    );
  }

  Future<void> openLocationSharing() async {
    widget.onDismiss();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ShareLocationView(group: widget.group),
    );
  }

  /// Picks an image from the memories (or the device gallery) and opens it in
  /// the editor, addressed to this chat.
  Future<void> openMemories() async {
    // Dismissing removes this panel, so the navigator is taken beforehand.
    final navigator = Navigator.of(context);
    final title = context.lang.memoriesMenu;
    widget.onDismiss();
    final path = await navigator.push<String>(
      MaterialPageRoute(
        builder: (context) => MemoriesPickerView(title: title),
      ),
    );
    if (path == null) return;

    final mediaId = await RustApi.initializeMediaUpload(
      mediaType: MediaType.image.name,
      displayLimitInMilliseconds: userService.currentUser.defaultShowTime,
      isDraftMedia: false,
    );
    final mediaService = await MediaFileService.fromMediaId(mediaId);
    if (mediaService == null) {
      Log.error('Could not create new media file for a memory share');
      return;
    }
    File(path).copySync(mediaService.originalPath.path);

    await navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => ShareImageEditorView(
          mediaFileService: mediaService,
          sharedFromGallery: true,
          sendToGroup: widget.group,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: ColoredBox(
        color: context.color.surfaceContainer,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Expanded(
                child: _entry(
                  icon: const FaIcon(FontAwesomeIcons.circleUser),
                  label: context.lang.shareContactsMenu,
                  onTap: openShareContactView,
                ),
              ),
              Expanded(
                child: _entry(
                  icon: const Icon(Icons.photo_library_outlined),
                  label: context.lang.memoriesMenu,
                  onTap: openMemories,
                ),
              ),
              Expanded(
                child: _entry(
                  icon: const Icon(Icons.apps_rounded),
                  label: context.lang.webxdcStoreMenu,
                  onTap: openAppStore,
                ),
              ),
              Expanded(
                child: _entry(
                  icon: const Icon(Icons.location_on_outlined),
                  label: context.lang.liveLocationMenu,
                  onTap: openLocationSharing,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entry({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.color.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: icon,
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
