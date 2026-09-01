import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/contact_groups.comp.dart';
import 'package:twonly/src/visual/components/custom_color_picker_dialog.comp.dart';
import 'package:twonly/src/visual/components/emoji_picker.bottom.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/components/verification_badge.comp.dart';
import 'package:twonly/src/visual/decorations/input_text.decoration.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';

class ContactGroupSettingsView extends StatefulWidget {
  const ContactGroupSettingsView({
    this.contactGroup,
    this.initialShowAsShortcut = false,
    super.key,
  });

  final ContactGroup? contactGroup;
  final bool initialShowAsShortcut;

  @override
  State<ContactGroupSettingsView> createState() =>
      _ContactGroupSettingsViewState();
}

class _MemberEntry {
  const _MemberEntry({required this.name, this.contact, this.group});

  final String name;
  final Contact? contact;
  final Group? group;
}

class _ContactGroupSettingsViewState extends State<ContactGroupSettingsView> {
  static const _backgroundColors = [
    0xFFE57373,
    0xFFF06292,
    0xFFBA68C8,
    0xFF7986CB,
    0xFF64B5F6,
    0xFF4DD0E1,
    0xFF4DB6AC,
    0xFF81C784,
    0xFFFFB74D,
    0xFFFF8A65,
    0xFF90A4AE,
    0xFF424242,
  ];
  static const _textColors = [
    0xFFFFFFFF,
    0xFF121212,
    0xFF1B263B,
    0xFF8B0000,
    0xFF004D40,
    0xFF4A148C,
  ];

  late final TextEditingController _nameController;
  late int _backgroundColor;
  late int _textColor;
  late bool _showAsShortcut;
  late bool _showAsLabel;
  String? _emoji;
  bool _saving = false;
  String _memberFilter = '';
  List<Contact> _contacts = [];
  List<Group> _groups = [];
  Map<String, List<String>> _groupMemberNames = {};
  final Set<int> _selectedUserIds = {};
  final Set<String> _selectedGroupIds = {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  bool get _isEditing => widget.contactGroup != null;

  @override
  void initState() {
    super.initState();
    final contactGroup = widget.contactGroup;
    _nameController = TextEditingController(text: contactGroup?.name ?? '');
    _backgroundColor = contactGroup?.backgroundColor ?? _backgroundColors[4];
    _textColor = contactGroup?.textColor ?? _textColors[0];
    _showAsShortcut =
        contactGroup?.showAsShortcut ?? widget.initialShowAsShortcut;
    _showAsLabel = contactGroup?.showAsLabel ?? !widget.initialShowAsShortcut;
    _emoji = contactGroup?.emoji;

    _subscriptions.add(
      twonlyDB.contactsDao.watchAllAcceptedContacts().listen((contacts) {
        if (!mounted) return;
        setState(() => _contacts = contacts);
      }),
    );
    _subscriptions.add(
      twonlyDB.groupsDao.watchGroupsForChatList().listen((groups) {
        if (!mounted) return;
        final actualGroups = groups
            .where((group) => !group.isDirectChat && !group.deletedContent)
            .toList();
        setState(() => _groups = actualGroups);
      }),
    );
    _subscriptions.add(
      twonlyDB.groupsDao.watchAllGroupMembers().listen((members) {
        if (!mounted) return;
        final names = <String, List<String>>{};
        for (final (contact, member) in members) {
          names
              .putIfAbsent(member.groupId, () => [])
              .add(getContactDisplayName(contact));
        }
        for (final entry in names.entries) {
          entry.value.sort(
            (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
          );
        }
        setState(() => _groupMemberNames = names);
      }),
    );
    if (contactGroup != null) {
      unawaited(_loadMembers(contactGroup.id));
    }
  }

  Future<void> _loadMembers(int contactGroupId) async {
    final members = await twonlyDB.contactGroupsDao.getMembers(contactGroupId);
    if (!mounted) return;
    setState(() {
      _selectedUserIds
        ..clear()
        ..addAll(members.where((m) => m.userId != null).map((m) => m.userId!));
      _selectedGroupIds
        ..clear()
        ..addAll(
          members.where((m) => m.groupId != null).map((m) => m.groupId!),
        );
    });
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _nameController.dispose();
    super.dispose();
  }

  List<_MemberEntry> get _members {
    final entries = <_MemberEntry>[
      for (final contact in _contacts)
        _MemberEntry(name: getContactDisplayName(contact), contact: contact),
      for (final group in _groups)
        _MemberEntry(name: group.groupName, group: group),
    ]..sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    final filter = _memberFilter.trim().toLowerCase();
    if (filter.isEmpty) return entries;
    return entries
        .where((entry) => entry.name.toLowerCase().contains(filter))
        .toList();
  }

  Future<void> _selectEmoji() async {
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      backgroundColor: Colors.black,
      builder: (context) => const EmojiPickerBottom(),
    );
    if (result is EmojiLayerData && mounted) {
      setState(() => _emoji = result.text);
    }
  }

  Future<void> _pickCustomColor({required bool background}) async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => CustomColorPickerDialog(
        initialColor: Color(background ? _backgroundColor : _textColor),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (background) {
        _backgroundColor = selected;
      } else {
        _textColor = selected;
      }
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_showAsShortcut && _emoji == null) {
      showSnackbar(context, context.lang.contactGroupShortcutNeedsEmoji);
      return;
    }
    setState(() => _saving = true);
    try {
      final id =
          widget.contactGroup?.id ??
          await twonlyDB.contactGroupsDao.createContactGroup(
            name: name,
            emoji: _emoji,
            textColor: _textColor,
            backgroundColor: _backgroundColor,
            showAsShortcut: _showAsShortcut,
            showAsLabel: _showAsLabel,
          );
      if (_isEditing) {
        await twonlyDB.contactGroupsDao.updateContactGroup(
          id: id,
          name: name,
          emoji: _emoji,
          textColor: _textColor,
          backgroundColor: _backgroundColor,
          showAsShortcut: _showAsShortcut,
          showAsLabel: _showAsLabel,
        );
      }
      await twonlyDB.contactGroupsDao.replaceMembers(
        id,
        userIds: _selectedUserIds,
        groupIds: _selectedGroupIds,
      );
      if (mounted) Navigator.pop(context, id);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final contactGroup = widget.contactGroup;
    if (contactGroup == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.lang.deleteContactGroup),
        content: Text(context.lang.deleteContactGroupConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.lang.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.lang.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await twonlyDB.contactGroupsDao.deleteContactGroup(contactGroup.id);
    if (mounted) Navigator.pop(context);
  }

  Widget _colorButton(
    int color,
    bool selected,
    VoidCallback onTap, {
    String? tooltip,
  }) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color == noContactGroupBackgroundColor ? null : Color(color),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? (isDarkMode(context) ? Colors.white : Colors.black)
                : Theme.of(context).colorScheme.outline,
            width: selected ? 3 : 1,
          ),
        ),
        child: color == noContactGroupBackgroundColor
            ? const Icon(Icons.format_color_reset, size: 18)
            : selected
            ? const Icon(Icons.check, size: 18)
            : null,
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  Widget _customColorButton({required bool background}) {
    return Tooltip(
      message: context.lang.customColor,
      child: GestureDetector(
        onTap: () => _pickCustomColor(background: background),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: const Icon(Icons.colorize, size: 18),
        ),
      ),
    );
  }

  Widget _nameEditor() {
    final hasBackground = contactGroupHasBackground(_backgroundColor);
    final fontSize = contactGroupFontSize(13, _backgroundColor);
    final style = TextStyle(
      color: Color(_textColor),
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );
    // The field has no intrinsic width, so measure the text to let the badge
    // hug its content just like the rendered label does.
    final painter = TextPainter(
      text: TextSpan(text: _nameController.text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return Center(
      child: Container(
        padding: hasBackground
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
            : EdgeInsets.zero,
        decoration: hasBackground
            ? BoxDecoration(
                color: Color(_backgroundColor),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: SizedBox(
          // Extra space keeps the caret visible behind the last character.
          width: painter.width.clamp(16, 240) + 8,
          child: TextField(
            controller: _nameController,
            autofocus: true,
            maxLength: 24,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.words,
            style: style,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasBackground = contactGroupHasBackground(_backgroundColor);
    final members = _members;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? context.lang.editContactGroup
              : context.lang.createContactGroup,
        ),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: context.lang.deleteContactGroup,
              onPressed: _delete,
              icon: const FaIcon(
                FontAwesomeIcons.trashCan,
                size: 18,
                color: Colors.red,
              ),
            ),
        ],
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      floatingActionButton: MyButton(
        variant: MyButtonVariant.primaryMiddle,
        onPressed: (_saving || _nameController.text.trim().isEmpty)
            ? null
            : _save,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_saving)
              const SizedBox.square(
                dimension: 15,
                child: CircularProgressIndicator.adaptive(strokeWidth: 1),
              )
            else
              const FaIcon(FontAwesomeIcons.check, size: 16),
            const SizedBox(width: 8),
            Text(context.lang.save),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          _nameEditor(),
          const SizedBox(height: 20),
          Text(
            context.lang.contactGroupBackgroundColor,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _colorButton(
                noContactGroupBackgroundColor,
                !hasBackground,
                () => setState(
                  () => _backgroundColor = noContactGroupBackgroundColor,
                ),
                tooltip: context.lang.contactGroupNoBackground,
              ),
              for (final color in _backgroundColors)
                _colorButton(
                  color,
                  _backgroundColor == color,
                  () => setState(() => _backgroundColor = color),
                ),
              _customColorButton(background: true),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            context.lang.contactGroupTextColor,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in _textColors)
                _colorButton(
                  color,
                  _textColor == color,
                  () => setState(() => _textColor = color),
                ),
              _customColorButton(background: false),
            ],
          ),
          const Divider(height: 40),
          Text(
            context.lang.contactGroupFeatures,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(context.lang.contactGroupShowAsLabel),
            subtitle: Text(context.lang.contactGroupShowAsLabelSubtitle),
            value: _showAsLabel,
            onChanged: (value) => setState(() => _showAsLabel = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(context.lang.contactGroupShowAsShortcut),
            subtitle: Text(context.lang.contactGroupShowAsShortcutSubtitle),
            value: _showAsShortcut,
            onChanged: (value) => setState(() => _showAsShortcut = value),
          ),
          if (_showAsShortcut)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.lang.selectEmoji),
              trailing: Text(
                _emoji ?? '+',
                style: const TextStyle(fontSize: 24),
              ),
              onTap: _selectEmoji,
            ),
          const Divider(height: 40),
          Text(
            context.lang.contactGroupMembers,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => setState(() => _memberFilter = value),
            decoration: getInputDecoration(
              context,
              context.lang.shareImageSearchAllContacts,
            ),
          ),
          for (final entry in members) _memberTile(entry),
        ],
      ),
    );
  }

  void _toggleEntry(_MemberEntry entry) {
    setState(() {
      final contact = entry.contact;
      if (contact != null) {
        if (!_selectedUserIds.add(contact.userId)) {
          _selectedUserIds.remove(contact.userId);
        }
      } else if (!_selectedGroupIds.add(entry.group!.groupId)) {
        _selectedGroupIds.remove(entry.group!.groupId);
      }
    });
  }

  Widget _memberTile(_MemberEntry entry) {
    final contact = entry.contact;
    final group = entry.group;
    final selected = contact != null
        ? _selectedUserIds.contains(contact.userId)
        : _selectedGroupIds.contains(group!.groupId);
    final memberNames = group == null
        ? const <String>[]
        : _groupMemberNames[group.groupId] ?? const <String>[];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: contact != null
          ? AvatarIcon(contactId: contact.userId, fontSize: 14)
          : AvatarIcon(group: group, fontSize: 14),
      title: Row(
        children: [
          Flexible(
            child: Text(
              entry.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          VerificationBadgeComp(
            contact: contact,
            group: group,
            showOnlyIfVerified: true,
            clickable: false,
            size: 12,
          ),
        ],
      ),
      subtitle: memberNames.isEmpty
          ? null
          : Text(
              memberNames.join(', '),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).disabledColor,
              ),
            ),
      trailing: Checkbox.adaptive(
        value: selected,
        onChanged: (_) => _toggleEntry(entry),
      ),
      onTap: () => _toggleEntry(entry),
    );
  }
}
