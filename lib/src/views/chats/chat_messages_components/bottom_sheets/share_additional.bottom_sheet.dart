import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/shared/select_contacts.view.dart';

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
    final selectedContacts = await context.navPush(
      SelectContactsView(
        text: SelectedContactViewText(
          title: context.lang.shareContactsTitle,
          submitButton: (_, __) => context.lang.shareContactsSubmit,
          submitIcon: FontAwesomeIcons.shareNodes,
        ),
      ),
    ) as List<int>?;
    if (selectedContacts != null && selectedContacts.isNotEmpty) {
      await insertAndSendContactShareMessage(
        widget.group.groupId,
        selectedContacts,
      );
    }
    if (mounted) {
      Navigator.pop(context);
    }
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
                children: [
                  GestureDetector(
                    onTap: openShareContactView,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.color.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const FaIcon(FontAwesomeIcons.circleUser),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.lang.shareContactsMenu,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
