import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_icon_button.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';

class MediaViewerMessageInput extends StatelessWidget {
  const MediaViewerMessageInput({
    required this.controller,
    required this.onSubmitted,
    required this.onSendPressed,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSendPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: context.color.surface,
        padding: const EdgeInsets.only(
          bottom: 10,
          left: 20,
          right: 20,
          top: 10,
        ),
        child: Row(
          children: [
            Expanded(
              child: MyInput(
                dense: true,
                autofocus: true,
                controller: controller,
                hintText: context.lang.chatListDetailInput,
                onChanged: (value) {},
                onSubmitted: onSubmitted,
              ),
            ),
            const SizedBox(width: 10),
            MyIconButton(
              icon: const FaIcon(
                FontAwesomeIcons.solidPaperPlane,
                size: 20,
              ),
              onPressed: onSendPressed,
            ),
          ],
        ),
      ),
    );
  }
}
