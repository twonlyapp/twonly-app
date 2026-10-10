import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/bottom_sheets/share_location.bottom_sheet.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/bottom_sheets/webxdc_store.bottom_sheet.dart';
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
        final members = await twonlyDB.groupsDao.getGroupContact(
          group.groupId,
        );
        if (members.isNotEmpty) {
          await twonlyDB.contactsDao.updateContact(
            members.first.userId,
            const ContactsCompanion(askForFriendPromotions: Value(false)),
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
