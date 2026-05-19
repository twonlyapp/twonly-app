import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:twonly/src/utils/avatars.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/qr.utils.dart';

class ProfileQrCodeComp extends StatefulWidget {
  const ProfileQrCodeComp({
    this.size = 250,
    this.showAvatar = true,
    super.key,
  });

  final double size;
  final bool showAvatar;

  @override
  State<ProfileQrCodeComp> createState() => _ProfileQrCodeCompState();
}

class _ProfileQrCodeCompState extends State<ProfileQrCodeComp> {
  String? _qrCode;
  Uint8List? _userAvatar;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final qr = await QrCodeUtils.publicProfileLink();
    final avatar = widget.showAvatar ? await getUserAvatar() : null;
    if (mounted) {
      setState(() {
        _qrCode = qr;
        _userAvatar = avatar;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _qrCode == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      // padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.color.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: QrImageView.withQr(
        qr: QrCode.fromData(
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
        embeddedImage: (widget.showAvatar && _userAvatar != null)
            ? MemoryImage(_userAvatar!)
            : null,
        embeddedImageStyle: QrEmbeddedImageStyle(
          size: const Size(60, 66),
          embeddedImageShape: EmbeddedImageShape.square,
          shapeColor: context.color.primary,
          safeArea: true,
        ),
        size: widget.size,
      ),
    );
  }
}
