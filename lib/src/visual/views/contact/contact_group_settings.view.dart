import 'dart:async';

import 'package:flutter/foundation.dart' show setEquals;
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
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';
import 'package:twonly/src/visual/views/shared/select_contacts.view.dart';

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
  static const _quickEmojis = [
    '❤️',
    '⭐',
    '🔥',
    '🏠',
    '👨‍👩‍👧',
    '💼',
    '🎉',
    '⚽',
    '🎮',
  ];

  /// More members than this collapse into a "+n" chip that opens the picker.
  static const _visibleMemberChips = 12;

  late final TextEditingController _nameController;
  final _pickerMembers = ValueNotifier<List<ContactPickerEntry>>([]);
  late int _backgroundColor;
  late int _textColor;
  late bool _showAsShortcut;
  late bool _showAsLabel;
  late bool _shareStories;
  String? _emoji;
  bool _saving = false;
  bool _membersLoaded = false;
  List<Contact> _contacts = [];
  List<Group> _groups = [];
  Map<String, Group> _directChats = {};
  Map<String, List<Contact>> _groupContacts = {};
  Map<String, List<String>> _groupMemberNames = {};
  final Set<int> _selectedUserIds = {};
  final Set<String> _selectedGroupIds = {};
  final Set<int> _savedUserIds = {};
  final Set<String> _savedGroupIds = {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Widgets on the home screen configured with this contact group. Its
  /// members are what makes those widgets able to receive anything, so the
  /// group cannot be deleted while any of them is still placed.
  int _widgetCount = 0;
  bool _widgetUsageLoaded = false;

  bool get _isEditing => widget.contactGroup != null;

  /// Save only appears once there is something to store: a name for a new
  /// group, or any difference from the stored one.
  bool get _canSave {
    if (!_membersLoaded || _nameController.text.trim().isEmpty) return false;
    final saved = widget.contactGroup;
    if (saved == null) return true;
    return _nameController.text.trim() != saved.name ||
        _emoji != saved.emoji ||
        _backgroundColor != saved.backgroundColor ||
        _textColor != saved.textColor ||
        _showAsShortcut != saved.showAsShortcut ||
        _showAsLabel != saved.showAsLabel ||
        _shareStories != saved.shareStories ||
        !setEquals(_selectedUserIds, _savedUserIds) ||
        !setEquals(_selectedGroupIds, _savedGroupIds);
  }

  @override
  void initState() {
    super.initState();
    final contactGroup = widget.contactGroup;
    _nameController = TextEditingController(text: contactGroup?.name ?? '');
    _backgroundColor = contactGroup?.backgroundColor ?? _backgroundColors[4];
    _textColor = contactGroup?.textColor ?? _textColors[0];
    _showAsShortcut =
        contactGroup?.showAsShortcut ?? widget.initialShowAsShortcut;
    _showAsLabel = contactGroup?.showAsLabel ?? false;
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
        _refreshPickerMembers();
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
        _refreshPickerMembers();
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
        _refreshPickerMembers();
      }),
    );
    if (contactGroup != null) {
      unawaited(_loadMembers(contactGroup.id));
    } else {
      _membersLoaded = true;
    }
  }

  Future<void> _loadMembers(int contactGroupId) async {
    final members = await rust_contact_groups.getContactGroupMembers(
      id: contactGroupId,
      transaction: currentDatabaseSession(),
    );
    if (!mounted) return;
    setState(() {
      _membersLoaded = true;
      _selectedUserIds
        ..clear()
        ..addAll(members.where((m) => m.userId != null).map((m) => m.userId!));
      _selectedGroupIds
        ..clear()
        ..addAll(
          members.where((m) => m.groupId != null).map((m) => m.groupId!),
        );
      _savedUserIds
        ..clear()
        ..addAll(_selectedUserIds);
      _savedGroupIds
        ..clear()
        ..addAll(_selectedGroupIds);
    });
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _nameController.dispose();
    _pickerMembers.dispose();
    super.dispose();
  }

  List<ContactPickerEntry> get _members {
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
        <ContactPickerEntry>[
          for (final contact in contacts.values)
            ContactPickerEntry(
              name: getContactDisplayName(contact),
              messageCount: messageCounts[contact.userId] ?? 0,
              contact: contact,
            ),
          for (final group in _groups)
            ContactPickerEntry(
              name: group.groupName,
              messageCount: group.totalMediaCounter,
              group: group,
              memberNames: _groupMemberNames[group.groupId] ?? const [],
            ),
        ]..sort(
          (a, b) {
            final byCount = b.messageCount.compareTo(a.messageCount);
            return byCount != 0
                ? byCount
                : a.name.toLowerCase().compareTo(b.name.toLowerCase());
          },
        );
    return entries;
  }

  void _refreshPickerMembers() => _pickerMembers.value = _members;

  Future<void> _selectMembers() async {
    FocusScope.of(context).unfocus();
    final selection = await Navigator.push<(List<int>, List<String>)>(
      context,
      MaterialPageRoute(
        builder: (pickerContext) => SelectContactsView(
          text: SelectedContactView(
            title: context.lang.selectMembers,
            submitButton: (count, _) =>
                context.lang.contactGroupMemberCount(count),
            submitIcon: FontAwesomeIcons.check,
          ),
          members: _pickerMembers,
          alreadySelected: _selectedUserIds.toList(),
          alreadySelectedGroupIds: _selectedGroupIds.toList(),
          isAlreadySelectedLocked: false,
          allowEmptySelection: true,
          onSubmit: (userIds, groupIds) =>
              Navigator.pop(pickerContext, (userIds, groupIds)),
        ),
      ),
    );
    if (selection == null || !mounted) return;
    setState(() {
      _selectedUserIds
        ..clear()
        ..addAll(selection.$1);
      _selectedGroupIds
        ..clear()
        ..addAll(selection.$2);
    });
  }

  Future<void> _selectEmoji() async {
    final result = await showModalBottomSheet<dynamic>(
      isScrollControlled: true,
      context: context,
      backgroundColor: context.color.surface,
      builder: (context) => const EmojiPickerBottom(),
    );
    if (result is EmojiLayerData && mounted) {
      setState(() => _emoji = result.text);
    }
  }

  void _setColor(int color, {required bool background}) {
    FocusScope.of(context).unfocus();
    setState(() {
      if (background) {
        _backgroundColor = color;
      } else {
        _textColor = color;
      }
    });
  }

  Future<void> _pickCustomColor({required bool background}) async {
    FocusScope.of(context).unfocus();
    final color = await showDialog<int>(
      context: context,
      builder: (context) => CustomColorPickerDialog(
        initialColor: Color(background ? _backgroundColor : _textColor),
      ),
    );
    if (color == null || !mounted) return;
    _setColor(color, background: background);
  }

  bool _isSelected(ContactPickerEntry entry) {
    final contact = entry.contact;
    return contact != null
        ? _selectedUserIds.contains(contact.userId)
        : _selectedGroupIds.contains(entry.group!.groupId);
  }

  void _removeMember(ContactPickerEntry entry) {
    setState(() {
      final contact = entry.contact;
      if (contact != null) {
        _selectedUserIds.remove(contact.userId);
      } else {
        _selectedGroupIds.remove(entry.group!.groupId);
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
          MyButton(
            variant: MyButtonVariant.text,
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
            MyButton(
              variant: MyButtonVariant.text,
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
          MyButton(
            variant: MyButtonVariant.text,
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.lang.cancel),
          ),
          MyButton(
            variant: MyButtonVariant.error,
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

  Widget _colorSwatch(
    int color, {
    required bool selected,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final none = color == noContactGroupBackgroundColor;
    final swatch = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? context.color.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: none ? context.color.surface : Color(color),
            shape: BoxShape.circle,
            border: Border.all(color: context.color.outlineVariant),
          ),
          child: none
              ? Icon(
                  Icons.format_color_reset,
                  size: 16,
                  color: context.color.onSurfaceVariant,
                )
              : null,
        ),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: tooltip == null
          ? swatch
          : Tooltip(message: tooltip, child: swatch),
    );
  }

  Widget _colorPalette({required bool background}) {
    final current = background ? _backgroundColor : _textColor;
    final palette = background ? _backgroundColors : _textColors;
    final hasColor = !background || contactGroupHasBackground(current);
    final isCustom = hasColor && !palette.contains(current);
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (background)
          _colorSwatch(
            noContactGroupBackgroundColor,
            selected: !hasColor,
            onTap: () => _setColor(
              noContactGroupBackgroundColor,
              background: background,
            ),
            tooltip: context.lang.contactGroupNoBackground,
          ),
        for (final color in palette)
          _colorSwatch(
            color,
            selected: current == color,
            onTap: () => _setColor(color, background: background),
          ),
        if (isCustom)
          _colorSwatch(
            current,
            selected: true,
            onTap: () => _pickCustomColor(background: background),
          ),
        Tooltip(
          message: context.lang.customColor,
          child: GestureDetector(
            onTap: () => _pickCustomColor(background: background),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Color(0xFFE57373),
                    Color(0xFFFFB74D),
                    Color(0xFFFFF176),
                    Color(0xFF81C784),
                    Color(0xFF64B5F6),
                    Color(0xFFBA68C8),
                    Color(0xFFE57373),
                  ],
                ),
              ),
              child: const Icon(Icons.add, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emojiChoice(String emoji) {
    final selected = _emoji == emoji;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () => setState(() => _emoji = emoji),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? context.color.primaryContainer
                : context.color.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? context.color.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }

  Widget _emojiOptions() {
    final emoji = _emoji;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // An emoji picked from the full picker stays visible and selected.
        if (emoji != null && !_quickEmojis.contains(emoji)) _emojiChoice(emoji),
        for (final emoji in _quickEmojis) _emojiChoice(emoji),
        Tooltip(
          message: context.lang.selectEmoji,
          child: GestureDetector(
            onTap: _selectEmoji,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.color.outlineVariant),
              ),
              child: Icon(
                Icons.add_reaction_outlined,
                size: 20,
                color: context.color.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
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

  Widget _labelOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.color.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _labelPreview(),
        ),
        const SizedBox(height: 16),
        _optionCaption(context.lang.contactGroupBackgroundColor),
        _colorPalette(background: true),
        const SizedBox(height: 12),
        _optionCaption(context.lang.contactGroupTextColor),
        _colorPalette(background: false),
      ],
    );
  }

  Widget _optionCaption(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 3, bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: context.color.onSurfaceVariant,
        ),
      ),
    );
  }

  /// A feature and its options share one card, so the options read as part of
  /// the switch above them and fold away with it.
  Widget _card({required Widget header, Widget? options}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: context.color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              header,
              if (options != null) ...[
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: context.color.outlineVariant,
                ),
                Padding(padding: const EdgeInsets.all(16), child: options),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.color.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _membersCard() {
    final selected = _pickerMembers.value.where(_isSelected).toList()
      ..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    final visible = selected.take(_visibleMemberChips).toList();
    final hidden = selected.length - visible.length;
    return _card(
      header: Column(
        children: [
          if (selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final entry in visible)
                      InputChip(
                        key: ValueKey(
                          entry.contact != null
                              ? 'member:contact:${entry.contact!.userId}'
                              : 'member:group:${entry.group!.groupId}',
                        ),
                        avatar: entry.contact != null
                            ? AvatarIcon(
                                contactId: entry.contact!.userId,
                                fontSize: 10,
                              )
                            : AvatarIcon(group: entry.group, fontSize: 10),
                        label: Text(entry.name),
                        onDeleted: () => _removeMember(entry),
                      ),
                    if (hidden > 0)
                      ActionChip(
                        label: Text('+$hidden'),
                        onPressed: _selectMembers,
                      ),
                  ],
                ),
              ),
            ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const Icon(Icons.person_add_alt_1_outlined),
            title: Text(context.lang.selectMembers),
            trailing: const Icon(Icons.chevron_right),
            enabled: _membersLoaded,
            onTap: _selectMembers,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      floatingActionButton: !_saving && !_canSave
          ? null
          : MyButton(
              variant: MyButtonVariant.primaryMiddle,
              onPressed: _saving ? null : _save,
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
        // Tapping outside controls should put the keyboard away.
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
            const SizedBox(height: 28),
            _sectionTitle(
              context.lang.contactGroupMembers,
              trailing: _selectedUserIds.isEmpty && _selectedGroupIds.isEmpty
                  ? null
                  : context.lang.contactGroupMemberCount(
                      _selectedUserIds.length + _selectedGroupIds.length,
                    ),
            ),
            _membersCard(),
            const SizedBox(height: 16),
            _sectionTitle(context.lang.contactGroupFeatures),
            _card(
              header: SwitchListTile.adaptive(
                title: Text(context.lang.contactGroupShareStories),
                subtitle: Text(context.lang.contactGroupShareStoriesSubtitle),
                value: _shareStories,
                onChanged: (value) => setState(() => _shareStories = value),
              ),
            ),
            _card(
              header: SwitchListTile.adaptive(
                title: Text(context.lang.contactGroupShowAsLabel),
                subtitle: Text(context.lang.contactGroupShowAsLabelSubtitle),
                value: _showAsLabel,
                onChanged: (value) => setState(() => _showAsLabel = value),
              ),
              options: _showAsLabel ? _labelOptions() : null,
            ),
            _card(
              header: SwitchListTile.adaptive(
                title: Text(context.lang.contactGroupShowAsShortcut),
                subtitle: Text(context.lang.contactGroupShowAsShortcutSubtitle),
                value: _showAsShortcut,
                onChanged: (value) => setState(() => _showAsShortcut = value),
              ),
              options: _showAsShortcut ? _emojiOptions() : null,
            ),
            if (_isEditing && _widgetUsageLoaded)
              _card(
                header: ListTile(
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
              ),
          ],
        ),
      ),
    );
  }
}
