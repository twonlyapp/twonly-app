import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/camera_send_to_view.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({
    required this.group,
    required this.quotesMessage,
    required this.textFieldFocus,
    required this.onMessageSend,
    super.key,
  });

  final Group group;
  final FocusNode textFieldFocus;
  final Message? quotesMessage;
  final VoidCallback onMessageSend;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  late final TextEditingController _textFieldController;
  final bool isApple = Platform.isIOS;
  bool _emojiShowing = false;

  Future<void> _sendMessage() async {
    if (_textFieldController.text == '') return;

    await insertAndSendTextMessage(
      widget.group.groupId,
      _textFieldController.text,
      widget.quotesMessage?.messageId,
    );

    _textFieldController.clear();
    _emojiShowing = false;
    widget.onMessageSend();
    setState(() {});
  }

  @override
  void initState() {
    _textFieldController = TextEditingController();
    widget.textFieldFocus.addListener(_handleTextFocusChange);
    super.initState();
  }

  @override
  void dispose() {
    widget.textFieldFocus.removeListener(_handleTextFocusChange);
    widget.textFieldFocus.dispose();
    super.dispose();
  }

  void _handleTextFocusChange() {
    if (widget.textFieldFocus.hasFocus) {
      setState(() {
        _emojiShowing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: 10,
            left: 10,
            top: 10,
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.color.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _emojiShowing = !_emojiShowing;
                            if (_emojiShowing) {
                              widget.textFieldFocus.unfocus();
                            } else {
                              widget.textFieldFocus.requestFocus();
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 8,
                            left: 12,
                            right: 8,
                          ),
                          child: FaIcon(
                            size: 20,
                            _emojiShowing
                                ? FontAwesomeIcons.keyboard
                                : FontAwesomeIcons.faceSmile,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _textFieldController,
                          focusNode: widget.textFieldFocus,
                          keyboardType: TextInputType.multiline,
                          maxLines: 4,
                          minLines: 1,
                          onChanged: (value) {
                            setState(() {});
                          },
                          onSubmitted: (_) {
                            _sendMessage();
                          },
                          style: const TextStyle(fontSize: 17),
                          decoration: InputDecoration(
                            hintText: context.lang.chatListDetailInput,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_textFieldController.text != '')
                IconButton(
                  padding: const EdgeInsets.all(15),
                  icon: FaIcon(
                    color: context.color.primary,
                    FontAwesomeIcons.solidPaperPlane,
                  ),
                  onPressed: _sendMessage,
                )
              else
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.camera),
                  padding: const EdgeInsets.all(15),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return CameraSendToView(widget.group);
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        Offstage(
          offstage: !_emojiShowing,
          child: EmojiPicker(
            textEditingController: _textFieldController,
            onEmojiSelected: (category, emoji) {
              setState(() {});
            },
            onBackspacePressed: () {
              setState(() {});
            },
            config: Config(
              height: 300,
              locale: Localizations.localeOf(context),
              viewOrderConfig: const ViewOrderConfig(
                top: EmojiPickerItem.searchBar,
                // middle: EmojiPickerItem.emojiView,
                bottom: EmojiPickerItem.categoryBar,
              ),
              emojiTextStyle:
                  TextStyle(fontSize: 24 * (Platform.isIOS ? 1.2 : 1)),
              emojiViewConfig: EmojiViewConfig(
                backgroundColor: context.color.surfaceContainer,
              ),
              searchViewConfig: SearchViewConfig(
                backgroundColor: context.color.surfaceContainer,
                buttonIconColor: Colors.white,
              ),
              categoryViewConfig: CategoryViewConfig(
                backgroundColor: context.color.surfaceContainer,
                dividerColor: Colors.white,
                indicatorColor: context.color.primary,
                iconColorSelected: context.color.primary,
                iconColor: context.color.secondary,
              ),
              bottomActionBarConfig: BottomActionBarConfig(
                backgroundColor: context.color.surfaceContainer,
                buttonColor: context.color.surfaceContainer,
                buttonIconColor: context.color.secondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
