import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/contact_request_badge.comp.dart';
import 'package:twonly/src/visual/components/profile_qr_code.comp.dart';
import 'package:twonly/src/visual/elements/better_list_title.element.dart';

class PublicProfileView extends StatefulWidget {
  const PublicProfileView({super.key});

  @override
  State<PublicProfileView> createState() => _PublicProfileViewState();
}

class _PublicProfileViewState extends State<PublicProfileView> {
  Uint8List? _publicKey;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    _publicKey = await getUserPublicKey();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [
          ContactRequestBadgeComp(),
          SizedBox(width: 15),
        ],
      ),
      body: Column(
        children: [
          Container(width: double.infinity),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => context.push(Routes.settingsHelpFaqVerifyBadge),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: context.color.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(context.lang.verificationBadgeNote),
                  ),
                  const SizedBox(width: 10),
                  const FaIcon(FontAwesomeIcons.angleRight),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const ProfileQrCodeComp(),
          const SizedBox(height: 20),
          Text(
            userService.currentUser.username,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          BetterListTile(
            leading: const FaIcon(FontAwesomeIcons.qrcode),
            text: context.lang.scanOtherProfile,
            onTap: () => context.push(Routes.cameraQRScanner),
          ),
          BetterListTile(
            leading: const FaIcon(
              FontAwesomeIcons.shareFromSquare,
              size: 18,
            ),
            text: context.lang.shareYourProfile,
            subtitle: (_publicKey == null)
                ? null
                : Text(
                    'https://me.twonly.eu/${userService.currentUser.username}',
                  ),
            onTap: () {
              final params = ShareParams(
                text: 'https://me.twonly.eu/${userService.currentUser.username}#${base64Url.encode(_publicKey!)}',
              );
              SharePlus.instance.share(params);
            },
          ),
        ],
      ),
    );
  }
}
