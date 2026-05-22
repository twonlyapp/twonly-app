import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart' show FaIcon, FontAwesomeIcons;
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/profile_qr_code.comp.dart';
import 'package:twonly/src/visual/themes/light.dart';

class EmptyChatListComp extends StatelessWidget {
  const EmptyChatListComp({super.key});

  Future<void> _shareProfile(BuildContext context) async {
    try {
      final pubKey = await getUserPublicKey();
      final params = ShareParams(
        text: 'https://me.twonly.eu/${userService.currentUser.username}#${base64Url.encode(pubKey)}',
      );
      await SharePlus.instance.share(params);
    } catch (e) {
      if (context.mounted) {
        await context.push(Routes.chatsAddNewUser);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(
            height: 24,
            width: double.infinity,
          ),
          const Text(
            'Find your first friend',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let friends scan your QR code, or share them your profile.',
            style: TextStyle(
              fontSize: 14,
              color: context.color.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          const Center(child: ProfileQrCodeComp()),
          const SizedBox(height: 36),
          // 3. Action Buttons
          // Button 1: Share Profile (Full Width)
          FilledButton.icon(
            style: primaryColorButtonStyle,
            onPressed: () => _shareProfile(context),
            icon: const FaIcon(FontAwesomeIcons.shareNodes, size: 20),
            label: const Text(
              'Share your profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Button Row: Scan QR Code & Enter Username
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: secondaryGreyButtonStyle(context),
                  onPressed: () => context.push(Routes.cameraQRScanner),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Scan QR Code',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: secondaryGreyButtonStyle(context),
                  onPressed: () => context.push(Routes.chatsAddNewUser),
                  icon: const Icon(Icons.person_add_rounded, size: 20),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Add by Username',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
