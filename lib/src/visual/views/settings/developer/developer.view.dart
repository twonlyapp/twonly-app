import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:restart_app/restart_app.dart';
import 'package:share_plus/share_plus.dart';
import 'package:twonly/core/bridge/api.dart' as rust_api;
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/diagnostics.dart'
    as rust_diagnostics;
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/bridge/memory_importer.dart';
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/core/database/app/diagnostics/table.dart';
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/components/store_review_prompt.comp.dart';
import 'package:twonly/src/visual/views/onboarding/setup.view.dart';
import 'package:twonly/src/visual/views/settings/backup/components/backup_reminder_sheet.comp.dart';
import 'package:twonly/src/visual/views/settings/developer/database_sizes_developer.view.dart';
import 'package:twonly/src/visual/views/settings/developer/home_widget_developer.view.dart';
import 'package:twonly/src/visual/views/settings/developer/user_discovery_developer.view.dart';

class DeveloperSettingsView extends StatefulWidget {
  const DeveloperSettingsView({super.key});

  @override
  State<DeveloperSettingsView> createState() => _DeveloperSettingsViewState();
}

class _DeveloperSettingsViewState extends State<DeveloperSettingsView> {
  bool _isGeneratingMockImages = false;
  bool _isGeneratingFlashbackImages = false;
  bool _isGeneratingMockMessages = false;
  bool _isGeneratingMockContacts = false;

  @override
  void initState() {
    super.initState();
  }

  /// Stores a rendered image for every entry and adds it to memories. Only
  /// media files are created: no chat, group or message.
  Future<void> _seedMockImages(
    List<({String mediaId, DateTime date, String label})> entries,
  ) async {
    final now = clock.now();
    for (final (index, entry) in entries.indexed) {
      final bytes = await _renderMockImage(index, entry.label);
      if (bytes == null) continue;
      final mediaService = MediaFileService(
        MediaFile(
          mediaId: entry.mediaId,
          typeName: MediaType.image.name,
          stored: true,
          requiresAuthentication: false,
          isDraftMedia: false,
          isWidgetMedia: false,
          isFavorite: false,
          hasCropAnalyzed: false,
          hasThumbnail: false,
          galleryExportPending: false,
          cloudStateName: CloudState.none.name,
          createdAtSeconds: databaseSeconds(now),
        ),
      );
      mediaService.storedPath.parent.createSync(recursive: true);
      mediaService.storedPath.writeAsBytesSync(bytes);
      mediaService.thumbnailPath.writeAsBytesSync(bytes);
    }

    // The files are in place before memories sees the rows.
    await rust_diagnostics.seedMockGallery(
      items: [
        for (final entry in entries)
          MockGalleryItem(
            mediaId: entry.mediaId,
            createdAt: entry.date.millisecondsSinceEpoch ~/ 1000,
            month: DateFormat('MMMM yyyy').format(entry.date),
          ),
      ],
      transaction: currentDatabaseSession(),
    );
  }

  /// A colored card with a face and [label], so every mock image is unique.
  Future<Uint8List?> _renderMockImage(int seed, String label) async {
    const size = Size(360, 640);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final hue = (seed * 137.5) % 360;
    final bgColor = HSLColor.fromAHSL(1, hue, 0.65, 0.45).toColor();
    canvas.drawRect(Offset.zero & size, Paint()..color = bgColor);

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      120,
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );

    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final mouthPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    const eyeOffset = 35.0;
    final eyeRadius = 12.0 + (seed % 5) * 2;
    canvas
      ..drawCircle(center + const Offset(-eyeOffset, -20), eyeRadius, eyePaint)
      ..drawCircle(center + const Offset(eyeOffset, -20), eyeRadius, eyePaint);

    final mouthRect = Rect.fromCenter(
      center: center + const Offset(0, 20),
      width: 60,
      height: 40,
    );
    final startAngle = 0.2 + (seed % 3) * 0.1;
    final sweepAngle = 2.7 - (seed % 3) * 0.2;
    canvas.drawArc(mouthRect, startAngle, sweepAngle, false, mouthPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: size.width - 32);
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, size.height - 120),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _generate1000MockImages() async {
    if (!kDebugMode || _isGeneratingMockImages) return;
    setState(() => _isGeneratingMockImages = true);

    try {
      final now = clock.now();
      final entries = <({String mediaId, DateTime date, String label})>[];
      for (var i = 0; i < 1000; i++) {
        final DateTime date;
        if (i < 200) {
          // Spread over the last month
          date = now.subtract(Duration(minutes: i * 216));
        } else if (i < 400) {
          // Spread between 1 month and 1 year ago
          date = now.subtract(Duration(days: 30, minutes: (i - 200) * 2412));
        } else if (i < 600) {
          // Around a year ago
          date = now.subtract(Duration(days: 365, minutes: (i - 400) * 216));
        } else if (i < 800) {
          // Around three years ago
          date = now.subtract(Duration(days: 1095, minutes: (i - 600) * 216));
        } else {
          // Around four years ago
          date = now.subtract(Duration(days: 1460, minutes: (i - 800) * 216));
        }
        entries.add((mediaId: 'mock_gen_$i', date: date, label: '#$i'));
      }

      await _seedMockImages(entries);

      if (mounted) {
        showSnackbar(
          context,
          'Successfully generated 1000 mock images!',
          level: SnackbarLevel.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackbar(context, 'Error generating images: $e');
      }
    } finally {
      if (mounted) setState(() => _isGeneratingMockImages = false);
    }
  }

  /// Three stored images on today's date, exactly one to five years ago, so
  /// the memories flashbacks show "One year ago", "2 years ago", ...
  Future<void> _generateFlashbackMockImages() async {
    if (!kDebugMode || _isGeneratingFlashbackImages) return;
    setState(() => _isGeneratingFlashbackImages = true);

    try {
      final now = clock.now();
      final entries = <({String mediaId, DateTime date, String label})>[];
      for (var years = 1; years <= 5; years++) {
        for (var i = 0; i < 3; i++) {
          final date = DateTime(
            now.year - years,
            now.month,
            now.day,
            9 + i * 4,
          );
          // Feb 29 does not exist in every year.
          if (date.month != now.month || date.day != now.day) continue;
          entries.add((
            mediaId: 'mock_gen_flashback_${years}y_$i',
            date: date,
            label:
                '${years == 1 ? '1 year' : '$years years'} ago\n'
                '${DateFormat('dd.MM.yyyy HH:mm').format(date)}',
          ));
        }
      }

      await _seedMockImages(entries);

      if (mounted) {
        showSnackbar(
          context,
          'Generated ${entries.length} flashback images.',
          level: SnackbarLevel.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackbar(context, 'Error generating images: $e');
      }
    } finally {
      if (mounted) setState(() => _isGeneratingFlashbackImages = false);
    }
  }

  Future<void> _generate40MockContacts() async {
    if (!kDebugMode || _isGeneratingMockContacts) return;

    setState(() => _isGeneratingMockContacts = true);
    try {
      await withDatabaseTransaction(() async {
        final contacts = await rust_contacts.listContacts(
          input: db_contacts.ContactQuery(
            filter: db_contacts.ContactFilter.all,
            ids: Int64List(0),
          ),
          transaction: currentDatabaseSession(),
        );
        final usedIds = {
          userService.currentUser.userId,
          ...contacts.map((contact) => contact.userId),
        };
        var nextNumber = 1;
        for (final contact in contacts) {
          if (contact.userId < 0 &&
              contact.userDiscoveryExcluded &&
              contact.username ==
                  'debug_contact_${(-contact.userId).toString().padLeft(2, '0')}') {
            // Replace the invalid contacts generated by the earlier version.
            await rust_contacts.deleteContact(
              id: contact.userId,
              transaction: currentDatabaseSession(),
            );
          } else if (contact.username.startsWith('debug_contact_')) {
            final number = int.tryParse(
              contact.username.substring('debug_contact_'.length),
            );
            if (number != null && number >= nextNumber) nextNumber = number + 1;
          }
        }

        // Direct-chat creation requires non-negative IDs. Skip existing IDs,
        // including our own account and contacts from earlier batches.
        var nextId = 1000000000;
        for (var i = 0; i < 40; i++) {
          while (usedIds.contains(nextId)) {
            nextId++;
          }
          final id = nextId++;
          final number = (nextNumber + i).toString().padLeft(2, '0');
          await rust_contacts.upsertContact(
            patch: db_contacts.ContactPatch(
              userId: id,
              username: 'debug_contact_$number',
              displayName: NullableText(value: 'Debug Contact $number'),
              accepted: true,
              signalVersion: 'v2',
              userDiscoveryExcluded: true,
            ),
            transaction: currentDatabaseSession(),
          );
        }
      });

      if (mounted) {
        showSnackbar(
          context,
          'Generated 40 mock contacts.',
          level: SnackbarLevel.success,
        );
      }
    } catch (error) {
      if (mounted) showSnackbar(context, 'Could not generate contacts: $error');
    } finally {
      if (mounted) setState(() => _isGeneratingMockContacts = false);
    }
  }

  Future<void> _generate1000RandomMessages() async {
    if (!kDebugMode || _isGeneratingMockMessages) return;

    final groups = await rust_groups.listGroups(
      input: const db_groups.GroupQuery(filter: db_groups.GroupFilter.all),
      transaction: currentDatabaseSession(),
    );
    groups.sort((a, b) => a.groupName.compareTo(b.groupName));
    if (!mounted) return;
    if (groups.isEmpty) {
      showSnackbar(context, 'No groups available for message generation.');
      return;
    }

    final group = await showDialog<Group>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Generate messages in group'),
        children: [
          for (final group in groups)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, group),
              child: Text(group.groupName),
            ),
        ],
      ),
    );
    if (group == null || !mounted) return;

    setState(() => _isGeneratingMockMessages = true);
    try {
      final now = clock.now();
      final idPrefix = 'debug_${now.microsecondsSinceEpoch}';
      final inserted = await rust_diagnostics.seedMockMessages(
        group: group.groupId,
        count: 1000,
        now: now.millisecondsSinceEpoch ~/ 1000,
        prefix: idPrefix,
        transaction: currentDatabaseSession(),
      );
      if (inserted == 0) {
        if (mounted) {
          showSnackbar(context, 'The selected group has no active members.');
        }
        return;
      }

      if (mounted) {
        showSnackbar(
          context,
          'Generated 1000 messages in ${group.groupName}.',
          level: SnackbarLevel.success,
        );
      }
    } catch (error) {
      if (mounted) showSnackbar(context, 'Could not generate messages: $error');
    } finally {
      if (mounted) setState(() => _isGeneratingMockMessages = false);
    }
  }

  Future<void> toggleDeveloperSettings() async {
    await UserService.update((u) => u.isDeveloper = !u.isDeveloper);
  }

  Future<void> toggleDatabaseLogging() async {
    await UserService.update(
      (u) => u.enableDatabaseLogging = !u.enableDatabaseLogging,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Settings'),
      ),
      body: StreamBuilder<void>(
        stream: userService.onUserUpdated,
        builder: (context, _) {
          return ListView(
            children: [
              ListTile(
                title: const Text('Show Developer Settings'),
                onTap: toggleDeveloperSettings,
                trailing: Switch.adaptive(
                  value: userService.currentUser.isDeveloper,
                  onChanged: (_) => toggleDeveloperSettings(),
                ),
              ),
              ListTile(
                title: const Text('Enable Database Logging'),
                onTap: toggleDatabaseLogging,
                trailing: Switch.adaptive(
                  value: userService.currentUser.enableDatabaseLogging,
                  onChanged: (_) => toggleDatabaseLogging(),
                ),
              ),
              ListTile(
                title: const Text('Informations'),
                onTap: () => context.push(Routes.settingsDeveloperInformations),
              ),
              ListTile(
                title: const Text('Database & Backup Sizes'),
                onTap: () =>
                    context.navPush(const DatabaseSizesDeveloperView()),
              ),
              ListTile(
                title: const Text('Show Retransmission Database'),
                onTap: () => context.push(
                  Routes.settingsDeveloperRetransmissionDatabase,
                ),
              ),
              ListTile(
                title: const Text('Show User Discovery Database'),
                onTap: () =>
                    context.navPush(const UserDiscoveryDeveloperView()),
              ),
              ListTile(
                title: const Text('Home Widget State'),
                onTap: () => context.navPush(const HomeWidgetDeveloperView()),
              ),
              ListTile(
                title: const Text('Share local database'),
                onTap: () async {
                  final dbCopyPath =
                      '${AppEnvironment.cacheDir}/twonly_copy.sqlite';
                  final dbCopyFile = File(dbCopyPath);
                  if (dbCopyFile.existsSync()) {
                    dbCopyFile.deleteSync();
                  }
                  try {
                    await rust_diagnostics.exportDebugDatabase(
                      path: dbCopyPath,
                    );
                    if (dbCopyFile.existsSync()) {
                      await SharePlus.instance.share(
                        ShareParams(
                          files: [XFile(dbCopyPath)],
                          text: 'twonly Database',
                        ),
                      );
                    }
                  } catch (e) {
                    Log.error('Failed to create database copy: $e');
                  }
                },
              ),
              ListTile(
                title: const Text('Reopen Setup'),
                onTap: () async {
                  await UserService.update((u) {
                    u.currentSetupPage = SetupPages.profile.name;
                  });
                },
              ),
              ListTile(
                title: Text(
                  'Delete all app data',
                  style: TextStyle(color: context.color.error),
                ),
                onTap: () async {
                  final ok = await showAlertDialog(
                    context,
                    'Sure?',
                    'If you do not have a backup, you have to register with a new account.',
                  );
                  if (ok) {
                    await deleteLocalUserData(removeCredentials: true);
                    await Restart.restartApp(
                      notificationTitle: 'Account successfully deleted',
                      notificationBody: 'Click here to open the app again',
                      forceKill: true,
                    );
                  }
                },
              ),
              if (kDebugMode) ...[
                const Divider(),
                ListTile(
                  title: const Text('Preview Mailbox Sync'),
                  onTap: () => unawaited(rust_api.RustApi.previewMailboxSync()),
                ),
                ListTile(
                  title: const Text('Preview Memory Import'),
                  onTap: () => unawaited(RustMemoryImporter.previewProgress()),
                ),
                ListTile(
                  title: const Text('Show Backup Reminder'),
                  onTap: () => unawaited(
                    showBackupReminderSheet(
                      context,
                      BackupReminder.missingBackup,
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Show Trusted Friends Reminder'),
                  onTap: () => unawaited(
                    showBackupReminderSheet(
                      context,
                      BackupReminder.passwordlessRecovery,
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Show Store Review Prompt'),
                  onTap: () => unawaited(showStoreReviewPromptSheet(context)),
                ),
                ListTile(
                  title: const Text('Make it possible to reset flames'),
                  onTap: () async {
                    final chats = await rust_groups.listGroups(
                      input: const db_groups.GroupQuery(
                        filter: db_groups.GroupFilter.direct,
                      ),
                      transaction: currentDatabaseSession(),
                    );

                    for (final chat in chats) {
                      await rust_groups.updateGroup(
                        id: chat.groupId,
                        patch: GroupPatch(
                          flameCounter: 0,
                          maxFlameCounter: 365,
                          lastFlameCounterChange: NullableInt(
                            value: databaseNullableSeconds(clock.now()),
                          ),
                          maxFlameCounterFrom: NullableInt(
                            value: databaseNullableSeconds(
                              clock.now().subtract(const Duration(days: 1)),
                            ),
                          ),
                        ),
                        transaction: currentDatabaseSession(),
                      );
                    }
                    await HapticFeedback.heavyImpact();
                  },
                ),
                ListTile(
                  title: const Text('Automated Testing'),
                  onTap: () =>
                      context.push(Routes.settingsDeveloperAutomatedTesting),
                ),
                ListTile(
                  title: const Text('Generate 40 Mock Contacts'),
                  trailing: _isGeneratingMockContacts
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        )
                      : null,
                  onTap: _isGeneratingMockContacts
                      ? null
                      : _generate40MockContacts,
                ),
                ListTile(
                  title: const Text('Generate 1000 Random Messages'),
                  trailing: _isGeneratingMockMessages
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        )
                      : null,
                  onTap: _isGeneratingMockMessages
                      ? null
                      : _generate1000RandomMessages,
                ),
                ListTile(
                  title: const Text('Generate 1000 Mock Images'),
                  trailing: _isGeneratingMockImages
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        )
                      : null,
                  onTap: _isGeneratingMockImages
                      ? null
                      : _generate1000MockImages,
                ),
                ListTile(
                  title: const Text('Generate Flashback Mock Images'),
                  subtitle: const Text(
                    'Stored images from exactly 1 to 5 years ago today',
                  ),
                  trailing: _isGeneratingFlashbackImages
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        )
                      : null,
                  onTap: _isGeneratingFlashbackImages
                      ? null
                      : _generateFlashbackMockImages,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
