import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/core/bridge/database/contact_groups.dart'
    as rust_contact_groups;
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/database/app/contact_groups/table.dart'
    as db_contact_groups;
import 'package:twonly/core/database/app/contact_groups/table.dart';
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/services/home_widget.service.dart';
import 'package:twonly/src/utils/contact_name.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/contact_groups.comp.dart';
import 'package:twonly/src/visual/components/custom_color_picker_dialog.comp.dart';
import 'package:twonly/src/visual/components/emoji_picker.bottom.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/components/verification_badge.comp.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';

class ContactGroupSettingsView extends StatefulWidget {
  const ContactGroupSettingsView({
    this.contactGroup,
    this.initialShowAsShortcut = false,
    this.initialShareStories = false,
    super.key,
  });

  final ContactGroup? contactGroup;
  final bool initialShowAsShortcut;
  final bool initialShareStories;

  @override
  State<ContactGroupSettingsView> createState() =>
      _ContactGroupSettingsViewState();
}

class _MemberEntry {
  const _MemberEntry({
    required this.name,
    required this.messageCount,
    this.contact,
    this.group,
  });

  final String name;
  final int messageCount;
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
  final TextEditingController _memberFilterController = TextEditingController();
  late int _backgroundColor;
  late int _textColor;
  late bool _showAsShortcut;
  late bool _showAsLabel;
  late bool _shareStories;
  String? _emoji;
  bool _saving = false;
  String _memberFilter = '';
  List<Contact> _contacts = [];
  List<Group> _groups = [];
  Map<String, Group> _directChats = {};
  Map<String, List<Contact>> _groupContacts = {};
  Map<String, List<String>> _groupMemberNames = {};
  final Set<int> _selectedUserIds = {};
  final Set<String> _selectedGroupIds = {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Widgets on the home screen configured with this contact group. Its
  /// members are what makes those widgets able to receive anything, so the
  /// group cannot be deleted while any of them is still placed.
  int _widgetCount = 0;
  bool _widgetUsageLoaded = false;

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
    _showAsLabel =
        contactGroup?.showAsLabel ??
        !(widget.initialShowAsShortcut || widget.initialShareStories);
    _shareStories = contactGroup?.shareStories ?? widget.initialShareStories;
    _emoji = contactGroup?.emoji;
    if (contactGroup != null) unawaited(_loadWidgetUsage(contactGroup.id));

    _subscriptions.add(
      watchRustDatabase(
        (control) => rust_contacts.watchContacts(
          input: db_contacts.ContactQuery(
            filter: db_contacts.ContactFilter.accepted,
            ids: Int64List(0),
          ),
          control: control,
        ),
      ).listen((contacts) {
        if (!mounted) return;
        setState(() => _contacts = contacts);
      }),
    );
    _subscriptions.add(
      watchRustDatabase(
        (control) => rust_groups.watchGroups(
          input: const db_groups.GroupQuery(
            filter: db_groups.GroupFilter.chatList,
          ),
          control: control,
        ),
      ).listen((groups) {
        if (!mounted) return;
        final actualGroups = groups
            .where((group) => !group.isDirectChat && !group.deletedContent)
            .toList();
        setState(() {
          _groups = actualGroups;
          _directChats = {
            for (final group in groups)
              if (group.isDirectChat) group.groupId: group,
          };
        });
      }),
    );
    _subscriptions.add(
      watchRustDatabase(
        (control) => rust_groups
            .watchGroupContacts(
              input: const db_groups.GroupMembersQuery(
                orderForChats: true,
              ),
              control: control,
            )
            .map(joinedGroupContacts),
      ).listen((members) {
        if (!mounted) return;
        final names = <String, List<String>>{};
        final contacts = <String, List<Contact>>{};
        for (final (contact, member) in members) {
          contacts.putIfAbsent(member.groupId, () => []).add(contact);
          names
              .putIfAbsent(member.groupId, () => [])
              .add(getContactDisplayName(contact));
        }
        for (final entry in names.entries) {
          entry.value.sort(
            (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
          );
        }
        setState(() {
          _groupMemberNames = names;
          _groupContacts = contacts;
        });
      }),
    );
    if (contactGroup != null) {
      unawaited(_loadMembers(contactGroup.id));
    }
  }

  Future<void> _loadMembers(int contactGroupId) async {
    final members = await rust_contact_groups.getContactGroupMembers(
      id: contactGroupId,
      transaction: currentDatabaseSession(),
    );
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
    _memberFilterController.dispose();
    super.dispose();
  }

  List<_MemberEntry> get _members {
    final messageCounts = <int, int>{};
    for (final chat in _directChats.values) {
      for (final contact in _groupContacts[chat.groupId] ?? const <Contact>[]) {
        messageCounts.update(
          contact.userId,
          (count) => count + chat.totalMediaCounter,
          ifAbsent: () => chat.totalMediaCounter,
        );
      }
    }
    // A direct chat can outlive a stale accepted flag. Include its contact as
    // well as accepted friends, without reviving blocked or removed contacts.
    final contacts = <int, Contact>{
      for (final groupId in _directChats.keys)
        for (final contact in _groupContacts[groupId] ?? const <Contact>[])
          if (!contact.blocked &&
              !contact.deletedByUser &&
              !contact.accountDeleted)
            contact.userId: contact,
      for (final contact in _contacts) contact.userId: contact,
    };
    final entries =
        <_MemberEntry>[
          for (final contact in contacts.values)
            _MemberEntry(
              name: getContactDisplayName(contact),
              messageCount: messageCounts[contact.userId] ?? 0,
              contact: contact,
            ),
          for (final group in _groups)
            _MemberEntry(
              name: group.groupName,
              messageCount: group.totalMediaCounter,
              group: group,
            ),
        ]..sort(
          (a, b) {
            final byCount = b.messageCount.compareTo(a.messageCount);
            return byCount != 0
                ? byCount
                : a.name.toLowerCase().compareTo(b.name.toLowerCase());
          },
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
      backgroundColor: context.color.surface,
      builder: (context) => const EmojiPickerBottom(),
    );
    if (result is EmojiLayerData && mounted) {
      setState(() => _emoji = result.text);
    }
  }

  Future<void> _selectColor({required bool background}) async {
    FocusScope.of(context).unfocus();
    final currentColor = background ? _backgroundColor : _textColor;
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: context.color.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                background
                    ? context.lang.contactGroupBackgroundColor
                    : context.lang.contactGroupTextColor,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              Center(child: _labelPreview()),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (background)
                    _colorButton(
                      noContactGroupBackgroundColor,
                      !contactGroupHasBackground(currentColor),
                      () => Navigator.pop(
                        sheetContext,
                        noContactGroupBackgroundColor,
                      ),
                      tooltip: context.lang.contactGroupNoBackground,
                    ),
                  for (final color
                      in background ? _backgroundColors : _textColors)
                    _colorButton(
                      color,
                      currentColor == color,
                      () => Navigator.pop(sheetContext, color),
                    ),
                  IconButton.outlined(
                    tooltip: context.lang.customColor,
                    icon: const Icon(Icons.colorize, size: 18),
                    onPressed: () async {
                      final color = await showDialog<int>(
                        context: sheetContext,
                        builder: (context) => CustomColorPickerDialog(
                          initialColor: Color(currentColor),
                        ),
                      );
                      if (color != null && sheetContext.mounted) {
                        Navigator.pop(sheetContext, color);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
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
          await rust_contact_groups.createContactGroup(
            transaction: currentDatabaseSession(),
            input: db_contact_groups.ContactGroupInput(
              name: name,
              emoji: _emoji,
              textColor: _textColor,
              backgroundColor: _backgroundColor,
              showAsShortcut: _showAsShortcut,
              showAsLabel: _showAsLabel,
              shareStories: _shareStories,
            ),
          );
      if (_isEditing) {
        await rust_contact_groups.updateContactGroup(
          transaction: currentDatabaseSession(),
          id: id,
          input: db_contact_groups.ContactGroupInput(
            name: name,
            emoji: _emoji,
            textColor: _textColor,
            backgroundColor: _backgroundColor,
            showAsShortcut: _showAsShortcut,
            showAsLabel: _showAsLabel,
            shareStories: _shareStories,
          ),
        );
      }
      await rust_contact_groups.replaceContactGroupMembers(
        transaction: currentDatabaseSession(),
        id: id,
        userIds: Int64List.fromList(_selectedUserIds.toList()),
        groupIds: _selectedGroupIds.toList(),
      );
      // A widget's configuration UI lists the groups from the manifest, so a
      // group that was just created or renamed is invisible to it until the
      // manifest is republished.
      unawaited(HomeWidgetService.refreshManifest());
      if (mounted) Navigator.pop(context, id);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadWidgetUsage(int contactGroupId) async {
    final widgets = await HomeWidgetService.placedWidgets();
    final count = widgets
        .where((placed) => placed.contactGroupIds.contains(contactGroupId))
        .length;
    if (!mounted) return;
    setState(() {
      _widgetCount = count;
      _widgetUsageLoaded = true;
    });
  }

  Future<void> _showWidgetTutorial() async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.lang.contactGroupWidgetTutorialTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _widgetTutorialStep(
                1,
                isIOS
                    ? context.lang.contactGroupWidgetTutorialIosStep1
                    : context.lang.contactGroupWidgetTutorialAndroidStep1,
              ),
              _widgetTutorialStep(
                2,
                isIOS
                    ? context.lang.contactGroupWidgetTutorialIosStep2
                    : context.lang.contactGroupWidgetTutorialAndroidStep2,
              ),
              _widgetTutorialStep(
                3,
                isIOS
                    ? context.lang.contactGroupWidgetTutorialIosStep3
                    : context.lang.contactGroupWidgetTutorialAndroidStep3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.lang.ok),
          ),
        ],
      ),
    );
  }

  Widget _widgetTutorialStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: context.color.primaryContainer,
            foregroundColor: context.color.onPrimaryContainer,
            child: Text('$number'),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    final contactGroup = widget.contactGroup;
    if (contactGroup == null) return;
    if (_widgetCount > 0) {
      // Deleting would silently strip the widget of everyone allowed to send to
      // it, leaving a placed widget that can never fill up again. Neither
      // platform lets the app take the widget down, so the user has to.
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.lang.deleteContactGroup),
          content: Text(
            context.lang.contactGroupDeleteBlockedByWidget(_widgetCount),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.lang.ok),
            ),
          ],
        ),
      );
      return;
    }
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
    await rust_contact_groups.deleteContactGroup(
      transaction: currentDatabaseSession(),
      id: contactGroup.id,
    );
    unawaited(HomeWidgetService.refreshManifest());
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
            color: selected ? context.color.onSurface : context.color.outline,
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

  Widget _labelPreview() {
    final hasBackground = contactGroupHasBackground(_backgroundColor);
    return Container(
      padding: hasBackground
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
          : EdgeInsets.zero,
      decoration: hasBackground
          ? BoxDecoration(
              color: Color(_backgroundColor),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Text(
        _nameController.text.trim().isEmpty
            ? context.lang.contactGroupNamePlaceholder
            : _nameController.text.trim(),
        style: TextStyle(
          color: Color(_textColor),
          fontSize: contactGroupFontSize(13, _backgroundColor),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _featureOptions({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Material(
        color: context.color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              icon: FaIcon(
                FontAwesomeIcons.trashCan,
                size: 18,
                color: context.color.error,
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
      body: GestureDetector(
        // The name and filter fields sit in a long scrolling page, so tapping
        // anywhere that is not a control should put the keyboard away.
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            MyInput(
              controller: _nameController,
              autofocus: !_isEditing,
              hintText: context.lang.contactGroupNamePlaceholder,
              inputFormatters: [LengthLimitingTextInputFormatter(24)],
              onChanged: (_) => setState(() {}),
            ),
            const Divider(height: 40),
            Text(
              context.lang.contactGroupFeatures,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(context.lang.contactGroupShareStories),
              subtitle: Text(context.lang.contactGroupShareStoriesSubtitle),
              value: _shareStories,
              onChanged: (value) => setState(() => _shareStories = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(context.lang.contactGroupShowAsLabel),
              subtitle: Text(context.lang.contactGroupShowAsLabelSubtitle),
              value: _showAsLabel,
              onChanged: (value) => setState(() => _showAsLabel = value),
            ),
            if (_showAsLabel)
              _featureOptions(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.format_color_fill),
                      title: Text(context.lang.contactGroupBackgroundColor),
                      trailing: _colorButton(
                        _backgroundColor,
                        false,
                        () => _selectColor(background: true),
                      ),
                      onTap: () => _selectColor(background: true),
                    ),
                    ListTile(
                      leading: const Icon(Icons.format_color_text),
                      title: Text(context.lang.contactGroupTextColor),
                      trailing: _colorButton(
                        _textColor,
                        false,
                        () => _selectColor(background: false),
                      ),
                      onTap: () => _selectColor(background: false),
                    ),
                  ],
                ),
              ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(context.lang.contactGroupShowAsShortcut),
              subtitle: Text(context.lang.contactGroupShowAsShortcutSubtitle),
              value: _showAsShortcut,
              onChanged: (value) => setState(() => _showAsShortcut = value),
            ),
            if (_showAsShortcut)
              _featureOptions(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(Icons.emoji_emotions_outlined),
                  title: Text(context.lang.selectEmoji),
                  trailing: Text(
                    _emoji ?? '+',
                    style: const TextStyle(fontSize: 24),
                  ),
                  onTap: _selectEmoji,
                ),
              ),
            if (_isEditing && _widgetUsageLoaded)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.widgets_outlined,
                  color: context.color.primary,
                ),
                title: Text(context.lang.contactGroupUsedByWidget),
                subtitle: Text(
                  _widgetCount > 0
                      ? context.lang.contactGroupUsedByWidgetSubtitle(
                          _widgetCount,
                        )
                      : context.lang.contactGroupAddWidgetSubtitle,
                ),
                trailing: _widgetCount == 0
                    ? const Icon(Icons.chevron_right)
                    : null,
                onTap: _widgetCount == 0 ? _showWidgetTutorial : null,
              ),
            const Divider(height: 40),
            Text(
              context.lang.contactGroupMembers,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            MyInput(
              controller: _memberFilterController,
              dense: true,
              fontWeight: FontWeight.normal,
              hintText: context.lang.shareImageSearchAllContacts,
              prefixIcon: const Icon(Icons.search, size: 20),
              onChanged: (value) => setState(() => _memberFilter = value),
            ),
            for (final entry in members) _memberTile(entry),
          ],
        ),
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
      // Filtering and sorting must keep each avatar and badge with its member.
      key: ValueKey(
        contact != null
            ? 'contact:${contact.userId}'
            : 'group:${group!.groupId}',
      ),
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
