import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/main_camera_controller.dart';
import 'package:url_launcher/url_launcher.dart';

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
            if (mainController.scannedUrl != null)
              _buildScannedUrlTile(context, mainController.scannedUrl!),
          ],
        ),
      ),
    );
  }

  Widget _buildScannedUrlTile(BuildContext context, String url) {
    return GestureDetector(
      onTap: () {
        launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
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
