// ignore_for_file: prefer_null_aware_method_calls

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/providers/image_editor.provider.dart';
import 'package:twonly/src/views/camera/share_image_editor/action_button.dart';
import 'package:twonly/src/views/camera/share_image_editor/data/layer.dart';

/// Text layer
class TextLayer extends StatefulWidget {
  const TextLayer({
    required this.layerData,
    super.key,
    this.onUpdate,
  });
  final TextLayerData layerData;
  final VoidCallback? onUpdate;
  @override
  State<TextLayer> createState() => _TextViewState();
}

class _TextViewState extends State<TextLayer> {
  double initialRotation = 0;
  bool deleteLayer = false;
  double localBottom = 0;
  bool isDeleted = false;
  bool elementIsScaled = false;
  final GlobalKey _widgetKey = GlobalKey(); // Create a GlobalKey
  final TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    textController.text = widget.layerData.text;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mq = MediaQuery.of(context);
      final globalDesiredBottom = mq.viewInsets.bottom + mq.viewPadding.bottom;
      final parentBox = context.findRenderObject() as RenderBox?;
      if (parentBox != null) {
        final parentTopGlobal = parentBox.localToGlobal(Offset.zero).dy;
        final screenHeight = mq.size.height;
        localBottom = (screenHeight - globalDesiredBottom) -
            parentTopGlobal -
            (parentBox.size.height);
      }

      if (widget.layerData.offset.dy == 0) {
        setState(() {
          widget.layerData.offset = Offset(
            0,
            MediaQuery.of(context).size.height / 2 -
                150 +
                (widget.layerData.textLayersBefore * 40),
          );
          textController.text = widget.layerData.text;
        });
      }
    });
  }

  Future<void> onEditionComplete() async {
    Future.delayed(const Duration(milliseconds: 10), () async {
      setState(() {
        widget.layerData.isDeleted = textController.text == '';
        widget.layerData.isEditing = false;
        widget.layerData.text = textController.text;
      });

      if (!mounted) return;

      await context
          .read<ImageEditorProvider>()
          .updateSomeTextViewIsAlreadyEditing(false);
      if (widget.onUpdate != null) {
        widget.onUpdate!();
      }
    });
  }

  double maxBottomInset = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.layerData.isDeleted) return Container();

    final bottom = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).viewPadding.bottom;

    // On Android it is possible to close the keyboard without `onEditingComplete` is triggered.
    if (maxBottomInset > bottom) {
      // prevent that the text element will be disappearing in case the keyboard just switches for example to the emoji page
      if (bottom < 20) {
        maxBottomInset = 0;
        if (widget.layerData.isEditing) {
          widget.layerData.isEditing = false;
          onEditionComplete();
        }
      }
    } else {
      maxBottomInset = bottom;
    }

    if (widget.layerData.isEditing) {
      return Positioned(
        bottom: bottom - localBottom,
        left: 0,
        right: 0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(100),
          ),
          child: TextField(
            controller: textController,
            autofocus: true,
            maxLines: null,
            minLines: 1,
            onEditingComplete: onEditionComplete,
            onTapOutside: (a) async {
              widget.layerData.text = textController.text;
              Future.delayed(const Duration(milliseconds: 100), () async {
                if (context.mounted) {
                  widget.layerData.isDeleted = textController.text == '';
                  widget.layerData.isEditing = false;
                  await context
                      .read<ImageEditorProvider>()
                      .updateSomeTextViewIsAlreadyEditing(false);
                  if (widget.onUpdate != null) {
                    widget.onUpdate!();
                  }
                  if (mounted) setState(() {});
                }
              });

              await context
                  .read<ImageEditorProvider>()
                  .updateSomeTextViewIsAlreadyEditing(false);
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
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
              if (deleteLayer) {
                widget.layerData.isDeleted = true;
                textController.text = '';
              }
              elementIsScaled = false;
              if (widget.onUpdate != null) {
                widget.onUpdate!();
              }
              setState(() {});
            },
            onTap: (context
                    .watch<ImageEditorProvider>()
                    .someTextViewIsAlreadyEditing)
                ? null
                : () async {
                    await context
                        .read<ImageEditorProvider>()
                        .updateSomeTextViewIsAlreadyEditing(true);
                    widget.layerData.isEditing = true;
                    if (mounted) setState(() {});
                  },
            onScaleUpdate: (detail) async {
              if (detail.pointerCount == 1) {
                widget.layerData.offset = Offset(
                  0,
                  widget.layerData.offset.dy + detail.focalPointDelta.dy,
                );
              }
              final renderBox =
                  _widgetKey.currentContext!.findRenderObject()! as RenderBox;

              if (widget.layerData.offset.dy > renderBox.size.height - 80) {
                if (!deleteLayer) {
                  await HapticFeedback.heavyImpact();
                }
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
                style: const TextStyle(
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
                  textController.text = '';
                },
                child: ActionButton(
                  FontAwesomeIcons.trashCan,
                  tooltipText: '',
                  color: deleteLayer ? Colors.red : Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
