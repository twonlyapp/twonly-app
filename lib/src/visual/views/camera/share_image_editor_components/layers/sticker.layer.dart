import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/action_button.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';

class StickerLayer extends StatefulWidget {
  const StickerLayer({required this.layerData, this.onUpdate, super.key});

  final StickerLayerData layerData;
  final VoidCallback? onUpdate;

  @override
  State<StickerLayer> createState() => _StickerLayerState();
}

class _StickerLayerState extends State<StickerLayer> {
  double initialRotation = 0;
  Offset initialOffset = Offset.zero;
  Offset initialFocalPoint = Offset.zero;
  double initialSize = 1;
  bool deleteLayer = false;
  bool twoPointersWereDown = false;
  final GlobalKey outlineKey = GlobalKey();
  final GlobalKey stickerKey = GlobalKey();
  int pointers = 0;
  bool display = false;

  @override
  void initState() {
    super.initState();
    if (widget.layerData.offset.dy == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          widget.layerData.offset = Offset(
            MediaQuery.sizeOf(context).width / 2 - 110,
            MediaQuery.sizeOf(context).height / 2 - 210,
          );
          display = true;
        });
      });
    } else {
      display = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!display || widget.layerData.isDeleted) return const SizedBox.shrink();
    return Stack(
      key: outlineKey,
      children: [
        Positioned(
          left: widget.layerData.offset.dx,
          top: widget.layerData.offset.dy,
          child: Listener(
            onPointerDown: (_) => setState(() => pointers++),
            onPointerUp: (_) {
              setState(() {
                pointers = pointers > 0 ? pointers - 1 : 0;
                if (pointers == 0) twoPointersWereDown = false;
                if (deleteLayer) {
                  widget.layerData.isDeleted = true;
                  widget.onUpdate?.call();
                }
              });
            },
            child: GestureDetector(
              onScaleStart: (details) {
                initialSize = widget.layerData.size;
                initialRotation = widget.layerData.rotation;
                initialOffset = widget.layerData.offset;
                initialFocalPoint = details.focalPoint;
              },
              onScaleUpdate: (details) async {
                if (twoPointersWereDown && details.pointerCount != 2) return;
                final outline =
                    outlineKey.currentContext?.findRenderObject() as RenderBox?;
                final sticker =
                    stickerKey.currentContext?.findRenderObject() as RenderBox?;
                if (outline == null || sticker == null) return;
                final center =
                    widget.layerData.offset +
                    Offset(sticker.size.width / 2, sticker.size.height / 2);
                final overDelete =
                    center.dy > outline.size.height - 80 &&
                    center.dx > MediaQuery.sizeOf(context).width / 2 - 30 &&
                    center.dx < MediaQuery.sizeOf(context).width / 2 + 20;
                if (overDelete && !deleteLayer) {
                  await HapticFeedback.heavyImpact();
                }
                if (!mounted) return;
                setState(() {
                  deleteLayer = overDelete;
                  twoPointersWereDown = details.pointerCount >= 2;
                  widget.layerData.size = (initialSize * details.scale).clamp(
                    42.0,
                    420.0,
                  );
                  widget.layerData.rotation =
                      initialRotation + details.rotation;
                  widget.layerData.offset =
                      initialOffset + (details.focalPoint - initialFocalPoint);
                });
              },
              child: Transform.rotate(
                angle: widget.layerData.rotation,
                key: stickerKey,
                child: Padding(
                  padding: const EdgeInsets.all(36),
                  child: _StickerImage(layerData: widget.layerData),
                ),
              ),
            ),
          ),
        ),
        if (pointers > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: ActionButton(
                FontAwesomeIcons.trashCan,
                tooltipText: '',
                color: deleteLayer
                    ? context.appColor(AppColor.recording)
                    : context.appColor(AppColor.mediaForeground),
              ),
            ),
          ),
      ],
    );
  }
}

class _StickerImage extends StatelessWidget {
  const _StickerImage({required this.layerData});

  final StickerLayerData layerData;

  @override
  Widget build(BuildContext context) {
    final aspect = layerData.width / layerData.height;
    final width = aspect >= 1 ? layerData.size : layerData.size * aspect;
    final height = aspect >= 1 ? layerData.size / aspect : layerData.size;
    return SizedBox(
      width: width,
      height: height,
      child: Opacity(
        opacity: layerData.opacity,
        child: Image.memory(
          layerData.webp,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
