import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/bottom_sheets/webxdc_store.bottom_sheet.dart';
import 'package:twonly/src/visual/views/shared/select_contacts.view.dart';

class ShareAdditionalView extends StatefulWidget {
  const ShareAdditionalView({required this.group, super.key});

  final Group group;

  @override
  State<ShareAdditionalView> createState() => _ShareAdditionalViewState();
}

class _ShareAdditionalViewState extends State<ShareAdditionalView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> openShareContactView() async {
    final selectedContacts =
        await context.navPush(
              SelectContactsView(
                text: SelectedContactView(
                  title: context.lang.shareContactsTitle,
                  submitButton: (_, _) => context.lang.shareContactsSubmit,
                  submitIcon: FontAwesomeIcons.shareNodes,
                ),
              ),
            )
            as List<int>?;
    if (selectedContacts != null && selectedContacts.isNotEmpty) {
      await RustApi.insertAndSendContactShare(
        groupId: widget.group.groupId,
        contactIds: Int64List.fromList(selectedContacts),
      );
      if (widget.group.isDirectChat) {
        final members = await twonlyDB.groupsDao.getGroupContact(
          widget.group.groupId,
        );
        if (members.isNotEmpty) {
          await twonlyDB.contactsDao.updateContact(
            members.first.userId,
            const ContactsCompanion(askForFriendPromotions: Value(false)),
          );
        }
      }
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> openAppStore() async {
    Navigator.pop(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WebxdcStoreView(group: widget.group),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.zero,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          color: context.color.surface,
          boxShadow: const [
            BoxShadow(
              blurRadius: 10.9,
              color: Color.fromRGBO(0, 0, 0, 0.1),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: Colors.grey,
              ),
              height: 3,
              width: 60,
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 32,
                children: [
                  _entry(
                    icon: FontAwesomeIcons.circleUser,
                    label: context.lang.shareContactsMenu,
                    onTap: openShareContactView,
                  ),
                  _entry(
                    icon: Icons.apps_rounded,
                    label: context.lang.webxdcStoreMenu,
                    onTap: openAppStore,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [icon] is an `IconData` or `FaIconData`, matching the rest of the app's
  /// icon handling.
  Widget _entry({
    required dynamic icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.color.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: icon is IconData
                ? Icon(icon)
                : FaIcon(icon as FaIconData?),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
