import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    Uint8List? avatarBytes;
    if (widget.showAvatar) {
      final avatarPath = await getUserAvatar();
      if (avatarPath != null) {
        avatarBytes = await File(avatarPath).readAsBytes();
      } else {
        final data = await rootBundle.load('assets/images/default_avatar.png');
        avatarBytes = data.buffer.asUint8List();
      }
    }
    if (mounted) {
      setState(() {
        _qrCode = qr;
        _userAvatar = avatarBytes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loaded = !_isLoading && _qrCode != null;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: loaded
            ? Container(
                key: const ValueKey('qr_code_container'),
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
              )
            : const SizedBox.shrink(key: ValueKey('qr_code_placeholder')),
      ),
    );
  }
}
