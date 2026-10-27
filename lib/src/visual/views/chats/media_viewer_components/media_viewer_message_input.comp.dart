import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/mention_decoration.dart';
import 'package:twonly/src/visual/components/mention_editing_controller.dart';
import 'package:twonly/src/visual/components/mention_suggestions.dart';
import 'package:twonly/src/visual/elements/my_icon_button.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';

class MediaViewerMessageInput extends StatelessWidget {
  const MediaViewerMessageInput({
    required this.controller,
    required this.safeAreaBottomPadding,
    required this.onSubmitted,
    required this.onSendPressed,
    this.group,
    this.focusNode,
    super.key,
  });

  final TextEditingController controller;
  final double safeAreaBottomPadding;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSendPressed;
  final Group? group;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final keyboardBottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomOffset = keyboardBottomInset > safeAreaBottomPadding
        ? keyboardBottomInset - safeAreaBottomPadding
        : 0.0;

    final input = MyInput(
      dense: true,
      autofocus: true,
      fontWeight: FontWeight.normal,
      controller: controller,
      focusNode: focusNode,
      hintText: context.lang.chatListDetailInput,
      onChanged: (value) {},
      onSubmitted: onSubmitted,
    );
    return Positioned(
      bottom: bottomOffset,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (group != null &&
                focusNode != null &&
                controller is MentionEditingController)
              MentionSuggestions(
                group: group!,
                controller: controller as MentionEditingController,
                focusNode: focusNode!,
              ),
            Row(
              children: [
                Expanded(
                  child: controller is MentionEditingController
                      ? MentionInputBackground(
                          controller: controller as MentionEditingController,
                          child: input,
                        )
                      : input,
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
          ],
        ),
      ),
    );
  }
}
