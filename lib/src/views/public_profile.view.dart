import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/utils/avatars.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/qr.dart';
import 'package:twonly/src/views/components/better_list_title.dart';

class PublicProfileView extends StatefulWidget {
  const PublicProfileView({super.key});

  @override
  State<PublicProfileView> createState() => _PublicProfileViewState();
}

class _PublicProfileViewState extends State<PublicProfileView> {
  Uint8List? _qrCode;
  Uint8List? _userAvatar;
  Uint8List? _publicKey;

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  Future<void> initAsync() async {
    _qrCode = await getProfileQrCodeData();
    _userAvatar = await getUserAvatar();
    _publicKey = await getUserPublicKey();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
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
          if (_qrCode != null && _userAvatar != null)
            Container(
              decoration: BoxDecoration(
                color: context.color.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: QrImageView.withQr(
                qr: QrCode.fromUint8List(
                  data: _qrCode!,
                  errorCorrectLevel: QrErrorCorrectLevel.M,
                ),
                eyeStyle: QrEyeStyle(
                  color: isDarkMode(context) ? Colors.black : Colors.white,
                  borderRadius: 2,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  color: isDarkMode(context) ? Colors.black : Colors.white,
                  borderRadius: 2,
                ),
                gapless: false,
                embeddedImage: MemoryImage(_userAvatar!),
                embeddedImageStyle: QrEmbeddedImageStyle(
                  size: const Size(60, 66),
                  embeddedImageShape: EmbeddedImageShape.square,
                  shapeColor: context.color.primary,
                  safeArea: true,
                ),
                size: 250,
              ),
            ),
          const SizedBox(height: 20),
          Text(
            gUser.username,
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
                : Text('https://me.twonly.eu/${gUser.username}'),
            onTap: () {
              final params = ShareParams(
                text:
                    'https://me.twonly.eu/${gUser.username}#${base64Url.encode(_publicKey!)}',
              );
              SharePlus.instance.share(params);
            },
          ),
        ],
      ),
    );
  }
}
