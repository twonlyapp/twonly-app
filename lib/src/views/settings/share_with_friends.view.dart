import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:twonly/src/utils/misc.dart';

class ShareWithFriendsView extends StatefulWidget {
  const ShareWithFriendsView({super.key});

  @override
  State<ShareWithFriendsView> createState() => _ShareWithFriendsView();
}

class _ShareWithFriendsView extends State<ShareWithFriendsView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.text =
          context.lang.inviteFriendsShareText('https://twonly.eu/install');
    });
  }

  Future<void> _shareText() async {
    final textToShare = _controller.text;
    final params = ShareParams(
      text: textToShare,
    );
    await SharePlus.instance.share(params);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.inviteFriends),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _shareText,
              icon: const FaIcon(FontAwesomeIcons.shareFromSquare),
              label: Text(context.lang.inviteFriendsShareBtn),
            ),
          ],
        ),
      ),
    );
  }
}
