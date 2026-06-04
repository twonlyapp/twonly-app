import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'
    show FaIcon, FontAwesomeIcons;
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/profile_qr_code.comp.dart'
    show ProfileQrCodeComp;
import 'package:twonly/src/visual/elements/my_button.element.dart';

class EmptyChatListComp extends StatelessWidget {
  const EmptyChatListComp({super.key});

  Future<void> _shareProfile(BuildContext context) async {
    try {
      final pubKey = await getUserPublicKey();
      final params = ShareParams(
        text:
            'https://me.twonly.eu/${userService.currentUser.username}#${base64Url.encode(pubKey)}',
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
          Text(
            context.lang.emptyChatListTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.lang.emptyChatListDesc,
            style: TextStyle(
              fontSize: 14,
              color: context.color.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          const Center(child: ProfileQrCodeComp()),
          const SizedBox(height: 36),
          MyButton(
            onPressed: () => _shareProfile(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.shareNodes, size: 20),
                const SizedBox(width: 8),
                Text(
                  context.lang.emptyChatListShareBtn,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MyButton(
                variant: MyButtonVariant.secondaryDense,
                onPressed: () => context.push(Routes.cameraQRScanner),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      context.lang.emptyChatListScanBtn,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              MyButton(
                variant: MyButtonVariant.secondaryDense,
                onPressed: () => context.push(Routes.chatsAddNewUser),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      context.lang.emptyChatListAddUsernameBtn,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
