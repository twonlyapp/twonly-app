import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/avatars.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/qr.dart';

class PublicProfileView extends StatefulWidget {
  const PublicProfileView({super.key});

  @override
  State<PublicProfileView> createState() => _PublicProfileViewState();
}

class _PublicProfileViewState extends State<PublicProfileView> {
  Uint8List? _qrCode;
  Uint8List? _userAvatar;

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  Future<void> initAsync() async {
    _qrCode = await getProfileQrCodeData();
    _userAvatar = await getUserAvatar();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Container(width: double.infinity),
          const SizedBox(
            height: 30,
          ),
          if (_qrCode != null && _userAvatar != null)
            Container(
              child: Container(
                decoration: BoxDecoration(
                  color: context.color.primary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
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
                  eyeStyle: const QrEyeStyle(
                    color: Colors.black,
                    borderRadius: 2,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    color: Colors.black,
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
            ),
          Text(
            gUser.displayName,
            style: const TextStyle(fontSize: 24),
          ),
          Text(
            gUser.username,
            style: const TextStyle(fontSize: 18),
          )
          // QR Code,,,
          // Display Name
          // username...
        ],
      ),
    );
  }
}
