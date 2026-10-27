// ignore_for_file: inference_failure_on_function_invocation

import 'package:clock/clock.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/messages.dart' as rust_messages;
import 'package:twonly/core/bridge/database/reactions.dart' as rust_reactions;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/model/message_enums.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pbserver.dart'
    as pb;
import 'package:twonly/src/services/live_location.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/stickers/sticker.service.dart';
import 'package:twonly/src/services/webxdc/webxdc.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/mentions.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/emoji_picker.bottom.dart';
import 'package:twonly/src/visual/components/mention_decoration.dart';
import 'package:twonly/src/visual/components/mention_editing_controller.dart';
import 'package:twonly/src/visual/components/mention_suggestions.dart';
import 'package:twonly/src/visual/components/mention_text.dart';
import 'package:twonly/src/visual/context_menu/context_menu.helper.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/chat_list_entry.dart';
import 'package:twonly/src/visual/views/chats/message_info.view.dart';
import 'package:twonly/src/visual/views/memories/synchronized_viewer.view.dart';

class MessageContextMenu extends StatelessWidget {
  const MessageContextMenu({
    required this.message,
    required this.group,
    required this.child,
    required this.onResponseTriggered,
    required this.galleryItems,
    required this.mediaFileService,
    super.key,
  });
  final Group group;
  final Widget child;
  final StoredMessage message;
  final List<MemoryItem> galleryItems;
  final MediaFileService? mediaFileService;
  final VoidCallback onResponseTriggered;

  Future<void> reopenMediaFile(BuildContext context) async {
    if (message.senderId == null) {
      final isAuth = await authenticateUser(
        context.lang.authRequestReopenImage,
        force: false,
      );
      if (!isAuth) return;
    }

    if (!context.mounted || mediaFileService == null) return;

    if (message.senderId != null) {
      // notify the sender
      await RustApi.sendEncryptedContent(
        contactId: message.senderId!,
        content: pb.EncryptedContent(
          mediaUpdate: pb.EncryptedContent_MediaUpdate(
            type: pb.EncryptedContent_MediaUpdate_Type.REOPENED,
            targetMessageId: message.messageId,
          ),
        ).writeToBuffer(),
        onlySendIfNoReceiptsAreOpen: false,
        onlyReturnEncryptedData: false,
        blocking: true,
      );
      await rust_messages.updateMessages(
        id: message.messageId,
        byMedia: false,
        patch: MessagePatch(
          openedAt: NullableInt(value: databaseNullableSeconds(null)),
        ),
        transaction: currentDatabaseSession(),
      );
      return;
    }
    if (!context.mounted) return;

    final galleryItems = [
      MemoryItem(mediaService: mediaFileService!, messages: []),
    ];

    await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) {
          return SynchronizedImageViewerScreen(
            galleryItems: galleryItems,
            initialIndex: 0,
            activeMediaIdNotifier: ValueNotifier(
              mediaFileService!.mediaFile.mediaId,
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // `late` so the ancestor lookup only runs if the menu is actually
    // opened, rather than once per row on every rebuild.
    late final navigator = Navigator.of(context);
    final isSticker =
        StickerService.decodeAdditional(message.additionalMessageData) != null;
    final isLocation =
        LiveLocationService.decode(message.additionalMessageData) != null;
    return ContextMenu(
      items: () => [
        if (!message.isDeletedFromSender)
          ContextMenuItem(
            title: context.lang.react,
            onTap: () async {
              final layer =
                  await showModalBottomSheet(
                        context: navigator.context,
                        backgroundColor: context.color.surface,
                        builder: (context) {
                          return const EmojiPickerBottom();
                        },
                      )
                      as EmojiLayerData?;
              if (layer == null) return;

              await rust_reactions.updateOwnReaction(
                message: message.messageId,
                emoji: layer.text,
                remove: false,
                transaction: currentDatabaseSession(),
              );

              await RustApi.sendEncryptedContentToGroup(
                groupId: message.groupId,
                content: pb.EncryptedContent(
                  reaction: pb.EncryptedContent_Reaction(
                    targetMessageId: message.messageId,
                    emoji: layer.text,
                    remove: false,
                  ),
                ).writeToBuffer(),
                onlySendIfNoReceiptsAreOpen: false,
              );
            },
            icon: FontAwesomeIcons.faceLaugh,
          ),
        if (!message.isWidgetMedia &&
            (mediaFileService?.canBeOpenedAgain ?? false))
          ContextMenuItem(
            title: context.lang.contextMenuViewAgain,
            onTap: () => reopenMediaFile(navigator.context),
            icon: FontAwesomeIcons.clockRotateLeft,
          ),
        if (!message.isDeletedFromSender)
          ContextMenuItem(
            title: context.lang.reply,
            onTap: () async {
              onResponseTriggered();
            },
            icon: FontAwesomeIcons.reply,
          ),
        if (!message.isDeletedFromSender &&
            message.senderId == null &&
            message.type == MessageType.text.name &&
            !isSticker &&
            !isLocation)
          ContextMenuItem(
            title: context.lang.edit,
            onTap: () async {
              await editTextMessage(navigator.context, message, group);
            },
            icon: FontAwesomeIcons.pencil,
          ),
        if (message.content != null && !isSticker)
          ContextMenuItem(
            title: context.lang.copy,
            onTap: () async {
              final menuContext = navigator.context;
              final text = message.content!;
              final ids = parseMentions(
                text,
              ).map((part) => part.userId).nonNulls.toSet();
              final contacts = ids.isEmpty
                  ? <Contact>[]
                  : await rust_contacts.listContacts(
                      input: ContactQuery(
                        filter: ContactFilter.ids,
                        ids: Int64List.fromList(ids.toList()),
                      ),
                      transaction: currentDatabaseSession(),
                    );
              if (!menuContext.mounted) return;
              final byId = {
                for (final contact in contacts) contact.userId: contact,
              };
              await Clipboard.setData(
                ClipboardData(
                  text: resolveMentions(
                    text,
                    (id) => mentionDisplayName(menuContext, id, byId),
                  ),
                ),
              );
              await HapticFeedback.heavyImpact();
            },
            icon: FontAwesomeIcons.solidCopy,
          ),
        ContextMenuItem(
          title: context.lang.delete,
          onTap: () async {
            final action = await showDeleteMessageOptions(
              navigator.context,
              message,
              group,
              galleryItems,
            );
            if (action == null) return;
            if (message.type == MessageType.webxdcApp.name) {
              // Removing the rows is only half of it. An app is free to keep
              // its whole state in localStorage or IndexedDB, which no database
              // delete reaches, so the instance goes first and takes its origin
              // with it.
              await WebxdcService.deleteInstance(message.messageId);
            }
            if (action == 'delete_for_all') {
              await rust_messages.deleteMessageFromSender(
                id: message.messageId,
                transaction: currentDatabaseSession(),
              );
              await RustApi.sendEncryptedContentToGroup(
                groupId: message.groupId,
                content: pb.EncryptedContent(
                  messageUpdate: pb.EncryptedContent_MessageUpdate(
                    type: pb.EncryptedContent_MessageUpdate_Type.DELETE,
                    senderMessageId: message.messageId,
                  ),
                ).writeToBuffer(),
                onlySendIfNoReceiptsAreOpen: false,
              );
            } else if (action == 'delete_for_me') {
              await rust_messages.deleteMessage(
                id: message.messageId,
                transaction: currentDatabaseSession(),
              );
            }
          },
          icon: FontAwesomeIcons.trash,
        ),
        if (!message.isDeletedFromSender)
          ContextMenuItem(
            title: context.lang.info,
            onTap: () async {
              await navigator.push(
                MaterialPageRoute(
                  builder: (context) {
                    return MessageInfoView(
                      message: message,
                      group: group,
                      galleryItems: galleryItems,
                    );
                  },
                ),
              );
            },
            icon: FontAwesomeIcons.circleInfo,
          ),
      ],
      child: child,
    );
  }
}

Future<String?> showDeleteMessageOptions(
  BuildContext context,
  StoredMessage message,
  Group group,
  List<MemoryItem> galleryItems,
) async {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      // A game changes sides with the last player, but its original author
      // still decides who can delete the shared card for everyone.
      final author = message.type == MessageType.webxdcApp.name
          ? message.originalSenderId
          : message.senderId;
      final isForAll = author == null && !message.isDeletedFromSender;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 40,
        ),
        decoration: BoxDecoration(
          color: context.color.surfaceContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ChatListEntry(
                  group: group,
                  message: message,
                  galleryItems: galleryItems,
                ),
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      // Prevent clicks
                    },
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            // Deleting an app is not the same as deleting a message: the whole
            // update log and everything the app saved on this device go with
            // it, so the sheet says so rather than letting the usual wording
            // stand in for it.
            if (message.type == MessageType.webxdcApp.name) ...[
              Text(
                context.lang.webxdcDeleteConfirm,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.color.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
            ],
            if (isForAll) ...[
              Center(
                child: MyButton(
                  variant: MyButtonVariant.errorMiddle,
                  onPressed: () {
                    Navigator.pop(context, 'delete_for_all');
                  },
                  child: Text(
                    context.lang.deleteOkBtnForAll,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Center(
              child: MyButton(
                variant: isForAll
                    ? MyButtonVariant.secondaryDense
                    : MyButtonVariant.errorMiddle,
                onPressed: () {
                  Navigator.pop(context, 'delete_for_me');
                },
                child: Text(
                  isForAll
                      ? context.lang.deleteOnlyForMe
                      : context.lang.deleteOkBtnForMe,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: MyButton(
                variant: MyButtonVariant.text,
                onPressed: () {
                  Navigator.pop(context, 'cancel');
                },
                child: Text(context.lang.cancel, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> editTextMessage(
  BuildContext context,
  StoredMessage message,
  Group group,
) async {
  final controller = MentionEditingController(text: message.content ?? '');
  final focusNode = FocusNode();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 40,
          ),
          decoration: BoxDecoration(
            color: context.color.surfaceContainer,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MentionSuggestions(
                group: group,
                controller: controller,
                focusNode: focusNode,
              ),
              MentionInputBackground(
                controller: controller,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  maxLines: 4,
                  minLines: 1,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: MyButton(
                      variant: MyButtonVariant.secondaryMiddle,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        context.lang.cancel,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MyButton(
                      variant: MyButtonVariant.primaryMiddle,
                      onPressed: () async {
                        final newText = controller.messageText;
                        if (newText != message.content && newText.isNotEmpty) {
                          final timestamp = clock.now();

                          await rust_messages.editMessage(
                            id: message.messageId,
                            text: newText,
                            timestamp: timestamp.millisecondsSinceEpoch ~/ 1000,
                            transaction: currentDatabaseSession(),
                          );
                          await RustApi.sendEncryptedContentToGroup(
                            groupId: message.groupId,
                            content: pb.EncryptedContent(
                              messageUpdate: pb.EncryptedContent_MessageUpdate(
                                type: pb
                                    .EncryptedContent_MessageUpdate_Type
                                    .EDIT_TEXT,
                                senderMessageId: message.messageId,
                                text: newText,
                                timestamp: Int64(
                                  timestamp.millisecondsSinceEpoch,
                                ),
                              ),
                            ).writeToBuffer(),
                            onlySendIfNoReceiptsAreOpen: false,
                          );
                        }
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        context.lang.ok,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  controller.dispose();
  focusNode.dispose();
}
