import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/camera_preview_controller_view.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/action_button.dart';

class CameraTopActions extends StatelessWidget {
  const CameraTopActions({
    required this.selectedCameraDetails,
    required this.hasAudioPermission,
    required this.onSwitchCamera,
    required this.onToggleFlash,
    required this.onRequestMicrophone,
    super.key,
  });

  final SelectedCameraDetails selectedCameraDetails;
  final bool hasAudioPermission;
  final VoidCallback onSwitchCamera;
  final VoidCallback onToggleFlash;
  final VoidCallback onRequestMicrophone;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 5,
      top: 0,
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ActionButton(
                Icons.repeat_rounded,
                tooltipText: context.lang.switchFrontAndBackCamera,
                onPressed: onSwitchCamera,
              ),
              ActionButton(
                selectedCameraDetails.isFlashOn
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                tooltipText: context.lang.toggleFlashLight,
                color: selectedCameraDetails.isFlashOn
                    ? Colors.white
                    : Colors.white.withAlpha(160),
                onPressed: onToggleFlash,
              ),
              if (!hasAudioPermission)
                ActionButton(
                  Icons.mic_off_rounded,
                  color: Colors.white.withAlpha(160),
                  tooltipText: 'Allow microphone access for video recording.',
                  onPressed: onRequestMicrophone,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
