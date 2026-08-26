import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/contact_labels.comp.dart';
import 'package:twonly/src/visual/components/label_editor_bottom_sheet.comp.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

class SelectContactLabelsView extends StatefulWidget {
  const SelectContactLabelsView({
    required this.contactId,
    super.key,
  });

  final int contactId;

  @override
  State<SelectContactLabelsView> createState() =>
      _SelectContactLabelsViewState();
}

class _SelectContactLabelsViewState extends State<SelectContactLabelsView> {
  Contact? _contact;
  List<Label> _allLabels = [];
  Set<int> _selectedLabelIds = {};

  late StreamSubscription<Contact?> _contactSub;
  late StreamSubscription<List<Label>> _allLabelsSub;
  late StreamSubscription<List<Label>> _contactLabelsSub;

  @override
  void initState() {
    super.initState();
    _contactSub = twonlyDB.contactsDao.watchContact(widget.contactId).listen((
      contact,
    ) {
      if (mounted) {
        setState(() {
          _contact = contact;
        });
      }
    });

    _allLabelsSub = twonlyDB.labelsDao.watchAllLabels().listen((labels) {
      if (mounted) {
        setState(() {
          _allLabels = labels;
        });
      }
    });

    _contactLabelsSub = twonlyDB.labelsDao
        .watchContactLabels(widget.contactId)
        .listen((labels) {
          if (mounted) {
            setState(() {
              _selectedLabelIds = labels.map((l) => l.id).toSet();
            });
          }
        });
  }

  @override
  void dispose() {
    _contactSub.cancel();
    _allLabelsSub.cancel();
    _contactLabelsSub.cancel();
    super.dispose();
  }

  Future<void> _toggleLabel(int labelId) async {
    final newSet = Set<int>.from(_selectedLabelIds);
    if (newSet.contains(labelId)) {
      newSet.remove(labelId);
    } else {
      if (newSet.length >= 3) {
        showSnackbar(
          context,
          context.lang.contactLabelsMaxLimit,
          level: SnackbarLevel.warning,
        );
        return;
      }
      newSet.add(labelId);
    }

    setState(() {
      _selectedLabelIds = newSet;
    });

    await twonlyDB.labelsDao.setContactLabels(
      widget.contactId,
      _selectedLabelIds.toList(),
    );
  }

  Future<void> _createLabel() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LabelEditorBottomSheet(),
    );

    if (result != null && mounted) {
      final name = result['name'] as String;
      final bgColor = result['backgroundColor'] as int;
      final textColor = result['textColor'] as int;

      await twonlyDB.labelsDao.createLabel(name, textColor, bgColor);
    }
  }

  Future<void> _editLabel(Label label) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LabelEditorBottomSheet(label: label),
    );

    if (result != null && mounted) {
      final name = result['name'] as String;
      final bgColor = result['backgroundColor'] as int;
      final textColor = result['textColor'] as int;

      await twonlyDB.labelsDao.updateLabel(label.id, name, textColor, bgColor);
    }
  }

  Future<void> _deleteLabel(Label label) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.lang.deleteLabel),
        content: Text(context.lang.deleteLabelConfirmation),
        actions: [
          Row(
            children: [
              Expanded(
                child: MyButton(
                  variant: MyButtonVariant.text,
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(context.lang.cancel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MyButton(
                  variant: MyButtonVariant.errorMiddle,
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(context.lang.deleteLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if ((confirm ?? false) && mounted) {
      await twonlyDB.labelsDao.deleteLabel(label.id);
    }
  }

  Widget _buildContactHeader() {
    if (_contact == null) return const SizedBox.shrink();
    final contact = _contact!;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          AvatarIcon(contactId: contact.userId, fontSize: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getContactDisplayName(contact, maxLength: 25),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (getContactDisplayName(contact) != contact.username)
                  Text(
                    '@${contact.username}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                const SizedBox(height: 6),
                ContactLabels(contactId: contact.userId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.contactLabelsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: context.lang.createLabel,
            onPressed: _createLabel,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildContactHeader(),
          Expanded(
            child: _allLabels.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.lang.contactLabelsSubtitleEmpty,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        MyButton(
                          variant: MyButtonVariant.primaryMiddle,
                          onPressed: _createLabel,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, size: 20),
                              const SizedBox(width: 6),
                              Text(context.lang.createLabel),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _allLabels.length,
                    itemBuilder: (context, index) {
                      final label = _allLabels[index];
                      final isSelected = _selectedLabelIds.contains(label.id);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleLabel(label.id),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Color(label.backgroundColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                label.name,
                                style: TextStyle(
                                  color: Color(label.textColor),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        secondary: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: context.lang.editLabel,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _editLabel(label),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: FaIcon(
                                    FontAwesomeIcons.penToSquare,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Tooltip(
                              message: context.lang.deleteLabel,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _deleteLabel(label),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: FaIcon(
                                    FontAwesomeIcons.trashCan,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
