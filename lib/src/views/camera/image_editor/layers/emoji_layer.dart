import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/views/camera/image_editor/action_button.dart';
import 'package:twonly/src/views/camera/image_editor/data/layer.dart';

/// Emoji layer
class EmojiLayer extends StatefulWidget {
  final EmojiLayerData layerData;
  final VoidCallback? onUpdate;

  const EmojiLayer({
    super.key,
    required this.layerData,
    this.onUpdate,
  });

  @override
  createState() => _EmojiLayerState();
}

class _EmojiLayerState extends State<EmojiLayer> {
  double initialRotation = 0;
  Offset initialOffset = Offset.zero;
  Offset initialFocalPoint = Offset.zero;
  double initialScale = 1.0;
  bool deleteLayer = false;
  bool twoPointerWhereDown = false;
  final GlobalKey outlineKey = GlobalKey();
  final GlobalKey emojiKey = GlobalKey();
  int pointers = 0;
  bool display = false;

  @override
  void initState() {
    super.initState();

    if (widget.layerData.offset.dy == 0) {
      // Set the initial offset to the center of the screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          widget.layerData.offset = Offset(
              MediaQuery.of(context).size.width / 2 - (153 / 2),
              MediaQuery.of(context).size.height / 2 - (153 / 2) - 100);
        });
        display = true;
      });
    } else {
      display = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!display) return Container();
    if (widget.layerData.isDeleted) return Container();
    return Stack(
      key: outlineKey,
      children: [
        Positioned(
          left: widget.layerData.offset.dx,
          top: widget.layerData.offset.dy,
          child: Listener(
            onPointerUp: (details) {
              setState(() {
                pointers--;
                if (pointers == 0) {
                  twoPointerWhereDown = false;
                }
                if (deleteLayer) {
                  widget.layerData.isDeleted = true;
                  if (widget.onUpdate != null) {
                    widget.onUpdate!();
                  }
                }
              });
            },
            onPointerDown: (details) {
              setState(() {
                pointers++;
              });
            },
            child: GestureDetector(
              onScaleStart: (details) {
                initialScale = widget.layerData.size;
                initialRotation = widget.layerData.rotation;
                initialOffset = widget.layerData.offset;
                initialFocalPoint =
                    Offset(details.focalPoint.dx, details.focalPoint.dy);

                setState(() {});
              },
              onScaleUpdate: (details) {
                if (twoPointerWhereDown == true && details.pointerCount != 2) {
                  return;
                }
                final RenderBox outlineBox =
                    outlineKey.currentContext!.findRenderObject() as RenderBox;

                final RenderBox emojiBox =
                    emojiKey.currentContext!.findRenderObject() as RenderBox;

                bool isAtTheBottom =
                    (widget.layerData.offset.dy + emojiBox.size.height / 2) >
                        outlineBox.size.height - 80;
                bool isInTheCenter = MediaQuery.of(context).size.width / 2 -
                            30 <
                        (widget.layerData.offset.dx +
                            emojiBox.size.width / 2) &&
                    MediaQuery.of(context).size.width / 2 + 20 >
                        (widget.layerData.offset.dx + emojiBox.size.width / 2);

                if (isAtTheBottom && isInTheCenter) {
                  deleteLayer = true;
                } else {
                  deleteLayer = false;
                }
                setState(() {
                  twoPointerWhereDown = details.pointerCount >= 2;
                  widget.layerData.size = initialScale * details.scale;
                  widget.layerData.rotation =
                      initialRotation + details.rotation;

                  // Update the position based on the translation
                  var dx = (initialOffset.dx) +
                      (details.focalPoint.dx - initialFocalPoint.dx);
                  var dy = (initialOffset.dy) +
                      (details.focalPoint.dy - initialFocalPoint.dy);
                  widget.layerData.offset = Offset(dx, dy);
                });
              },
              child: Transform.rotate(
                angle: widget.layerData.rotation,
                key: emojiKey,
                child: Container(
                  padding: const EdgeInsets.all(44),
                  color: Colors.transparent,
                  child: Text(
                    widget.layerData.text.toString(),
                    style: TextStyle(
                      fontSize: widget.layerData.size,
                    ),
                  ),
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
              child: GestureDetector(
                child: ActionButton(
                  FontAwesomeIcons.trashCan,
                  tooltipText: "",
                  color: deleteLayer ? Colors.red : Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
