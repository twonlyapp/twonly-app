import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/components/image_editor/data/layer.dart';
import 'package:twonly/src/views/camera_to_share/share_image_editor_view.dart';

/// Text layer
class TextLayer extends StatefulWidget {
  final TextLayerData layerData;
  final VoidCallback? onUpdate;

  const TextLayer({
    super.key,
    required this.layerData,
    this.onUpdate,
  });
  @override
  createState() => _TextViewState();
}

class _TextViewState extends State<TextLayer> {
  double initialRotation = 0;
  bool deleteLayer = false;
  bool isDeleted = false;
  bool elementIsScaled = false;
  final GlobalKey _widgetKey = GlobalKey(); // Create a GlobalKey
  final TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.layerData.offset.dy == 0) {
      // Set the initial offset to the center of the screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          widget.layerData.offset =
              Offset(0, MediaQuery.of(context).size.height / 2 - 30);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isDeleted) return Container();

    if (widget.layerData.isEditing) {
      return Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom - 100,
        left: 0,
        right: 0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(100),
          ),
          child: TextField(
            controller: textController,
            autofocus: true,
            onEditingComplete: () {
              setState(() {
                widget.layerData.isEditing = false;
                widget.layerData.text = textController.text;
              });
            },
            onTapOutside: (a) {
              widget.layerData.text = textController.text;
              Future.delayed(Duration(milliseconds: 100), () {
                setState(() {
                  widget.layerData.isEditing = false;
                });
              });
            },
            decoration: InputDecoration(
              border: InputBorder.none, // Keine Umrandung
              contentPadding: EdgeInsets.zero, // Kein Padding
            ),
            // widget.layerData.text.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
            ),
          ),
        ),
      );
    }
    return Stack(
      key: _widgetKey,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: widget.layerData.offset.dy,
          child: GestureDetector(
            onScaleStart: (d) {
              setState(() {
                elementIsScaled = true;
              });
            },
            onScaleEnd: (d) {
              if (deleteLayer) isDeleted = true;
              elementIsScaled = false;
              setState(() {});
            },
            onTap: () {
              setState(() {
                widget.layerData.isEditing = true;
              });
            },
            onScaleUpdate: (detail) {
              if (detail.pointerCount == 1) {
                widget.layerData.offset = Offset(
                    0, widget.layerData.offset.dy + detail.focalPointDelta.dy);
              }
              final RenderBox renderBox =
                  _widgetKey.currentContext!.findRenderObject() as RenderBox;

              if (widget.layerData.offset.dy > renderBox.size.height - 80) {
                deleteLayer = true;
              } else {
                deleteLayer = false;
              }
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(100),
              ),
              child: Text(
                widget.layerData.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),
        if (elementIsScaled)
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: GestureDetector(
                onTapUp: (d) {
                  textController.text = "";
                },
                child: FaIcon(
                  FontAwesomeIcons.trashCan,
                  shadows: ShareImageEditorView.iconShadow,
                  color: deleteLayer ? Colors.red : Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
