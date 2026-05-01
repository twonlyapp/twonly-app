import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/qr.utils.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/main_camera_controller.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CameraScannedOverlay extends StatelessWidget {
  const CameraScannedOverlay({
    required this.mainController,
    super.key,
  });

  final MainCameraController mainController;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 8,
      top: 170,
      child: SizedBox(
        height: 200,
        width: 150,
        child: ListView(
          children: [
            ...mainController.scannedNewProfiles.values.map(
              (c) => _buildScannedProfileTile(context, c),
            ),
            ...mainController.contactsVerified.values.map(
              (c) => _buildVerifiedContactTile(context, c),
            ),
            if (mainController.scannedUrl != null)
              _buildScannedUrlTile(context, mainController.scannedUrl!),
          ],
        ),
      ),
    );
  }

  Widget _buildScannedProfileTile(BuildContext context, ScannedNewProfile c) {
    if (c.isLoading) return Container();
    return GestureDetector(
      onTap: () async {
        c.isLoading = true;
        mainController.setState();
        if (await addNewContactFromPublicProfile(c.profile) &&
            context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.lang.requestedUserToastText(c.profile.username),
              ),
              duration: const Duration(seconds: 8),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: context.color.surfaceContainer,
        ),
        child: Row(
          children: [
            Text(c.profile.username),
            Expanded(child: Container()),
            if (c.isLoading)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              ColoredBox(
                color: Colors.transparent,
                child: FaIcon(
                  FontAwesomeIcons.userPlus,
                  color: isDarkMode(context) ? Colors.white : Colors.black,
                  size: 17,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedContactTile(
    BuildContext context,
    ScannedVerifiedContact c,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: context.color.surfaceContainer,
      ),
      child: Row(
        children: [
          AvatarIcon(
            contactId: c.contact.userId,
            fontSize: 14,
          ),
          const SizedBox(width: 10),
          Text(
            getContactDisplayName(c.contact, maxLength: 13),
          ),
          Expanded(child: Container()),
          ColoredBox(
            color: Colors.transparent,
            child: SizedBox(
              width: 30,
              child: Lottie.asset(
                c.verificationOk
                    ? 'assets/animations/success.lottie'
                    : 'assets/animations/failed.lottie',
                repeat: false,
                onLoaded: (p0) {
                  Future.delayed(const Duration(seconds: 4), () {
                    mainController.setState();
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedUrlTile(BuildContext context, String url) {
    return GestureDetector(
      onTap: () {
        launchUrlString(url);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: context.color.surfaceContainer,
        ),
        child: Row(
          children: [
            Text(
              substringBy(url, 25),
              style: const TextStyle(fontSize: 8),
            ),
            Expanded(child: Container()),
            Expanded(child: Container()),
            ColoredBox(
              color: Colors.transparent,
              child: FaIcon(
                FontAwesomeIcons.shareFromSquare,
                color: isDarkMode(context) ? Colors.white : Colors.black,
                size: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
