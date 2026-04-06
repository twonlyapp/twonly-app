import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/share_image_editor/action_button.dart';
import 'package:twonly/src/views/camera/share_image_editor/layer_data.dart';

class BackgroundLayer extends StatefulWidget {
  const BackgroundLayer({
    required this.layerData,
    super.key,
    this.onUpdate,
  });
  final BackgroundLayerData layerData;
  final VoidCallback? onUpdate;

  @override
  State<BackgroundLayer> createState() => _BackgroundLayerState();
}

class _BackgroundLayerState extends State<BackgroundLayer> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.layerData.imageLoaded = true;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final scImage = widget.layerData.image.image;
    if (scImage == null || scImage.image == null) return Container();
    return Stack(
      children: [
        Positioned.fill(
          child: PhotoView.customChild(
            enableRotation: true,
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            backgroundDecoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Container(
              width: widget.layerData.image.width.toDouble(),
              height: widget.layerData.image.height.toDouble(),
              padding: EdgeInsets.zero,
              color: Colors.transparent,
              child: CustomPaint(
                painter: UiImagePainter(scImage.image!),
              ),
            ),
          ),
        ),
        if (widget.layerData.isEditing)
          Positioned(
            top: 5,
            left: 5,
            right: 50,
            child: Row(
              children: [
                ActionButton(
                  FontAwesomeIcons.check,
                  tooltipText: context.lang.imageEditorDrawOk,
                  onPressed: () async {
                    widget.layerData.isEditing = false;
                    widget.onUpdate!();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class UiImagePainter extends CustomPainter {
  UiImagePainter(this.image);
  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final sizes = applyBoxFit(BoxFit.contain, imageSize, size);

    final destRect = Alignment.center.inscribe(
      sizes.destination,
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, imageSize.width, imageSize.height),
      destRect,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant UiImagePainter oldDelegate) {
    return image != oldDelegate.image;
  }
}
