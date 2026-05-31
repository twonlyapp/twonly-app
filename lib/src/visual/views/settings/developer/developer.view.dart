import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:restart_app/restart_app.dart';
import 'package:share_plus/share_plus.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/views/onboarding/setup.view.dart';
import 'package:twonly/src/visual/views/settings/developer/user_discovery_developer.view.dart';

class DeveloperSettingsView extends StatefulWidget {
  const DeveloperSettingsView({super.key});

  @override
  State<DeveloperSettingsView> createState() => _DeveloperSettingsViewState();
}

class _DeveloperSettingsViewState extends State<DeveloperSettingsView> {
  bool _isGeneratingMockImages = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _generate1000MockImages() async {
    if (_isGeneratingMockImages) return;
    setState(() {
      _isGeneratingMockImages = true;
    });

    try {
      final now = clock.now();
      const groupId = 'mock_group_gallery';

      // Ensure mock group exists
      await twonlyDB.groupsDao.createNewGroup(
        const GroupsCompanion(
          groupId: Value(groupId),
          groupName: Value('Mock Gallery Group'),
          isDirectChat: Value(false),
          joinedGroup: Value(true),
        ),
      );

      const size = Size(360, 640);

      // Batch database entries using cascades for extreme operational speed and clean linting
      await twonlyDB.batch((batch) async {
        for (var i = 0; i < 1000; i++) {
          final mediaId = 'mock_gen_$i';
          final authorIndex = i % 12;
          final contactId = 9000000 + authorIndex;

          late DateTime itemDate;
          if (i < 200) {
            // Spread over the last month
            itemDate = now.subtract(Duration(minutes: i * 216));
          } else if (i < 400) {
            // Spread between 1 month and 1 year ago
            final localI = i - 200;
            itemDate = now.subtract(
              Duration(days: 30, minutes: localI * 2412),
            );
          } else if (i < 600) {
            // Around a year ago
            final localI = i - 400;
            itemDate = now.subtract(
              Duration(days: 365, minutes: localI * 216),
            );
          } else if (i < 800) {
            // Around three years ago
            final localI = i - 600;
            itemDate = now.subtract(
              Duration(days: 1095, minutes: localI * 216),
            );
          } else {
            // Around four years ago
            final localI = i - 800;
            itemDate = now.subtract(
              Duration(days: 1460, minutes: localI * 216),
            );
          }

          batch
            ..insert(
              twonlyDB.contacts,
              ContactsCompanion(
                userId: Value(contactId),
                username: Value('mock_user_$authorIndex'),
                displayName: Value('Author $authorIndex'),
              ),
              mode: InsertMode.insertOrReplace,
            )
            ..insert(
              twonlyDB.mediaFiles,
              MediaFilesCompanion(
                mediaId: Value(mediaId),
                type: const Value(MediaType.image),
                stored: const Value(true),
                createdAt: Value(itemDate),
                createdAtMonth: Value(DateFormat('MMMM yyyy').format(itemDate)),
              ),
              mode: InsertMode.insertOrReplace,
            )
            ..insert(
              twonlyDB.messages,
              MessagesCompanion(
                messageId: Value('mock_msg_$i'),
                groupId: const Value(groupId),
                senderId: Value(contactId),
                type: const Value('media'),
                mediaId: Value(mediaId),
                mediaStored: const Value(true),
                openedAt: Value(now),
                createdAt: Value(itemDate),
              ),
              mode: InsertMode.insertOrReplace,
            );
        }
      });

      // Render custom vector avatars and background colors efficiently
      for (var i = 0; i < 1000; i++) {
        final mediaId = 'mock_gen_$i';
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        // Background color
        final hue = (i * 137.5) % 360;
        final bgColor = HSLColor.fromAHSL(1, hue, 0.65, 0.45).toColor();
        canvas.drawRect(Offset.zero & size, Paint()..color = bgColor);

        // Avatar vector representation on it
        final center = Offset(size.width / 2, size.height / 2);
        final avatarBgPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.25);
        canvas.drawCircle(center, 120, avatarBgPaint);

        final eyePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        final mouthPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round;

        const eyeOffset = 35.0;
        final eyeRadius = 12.0 + (i % 5) * 2;
        canvas
          ..drawCircle(
            center + const Offset(-eyeOffset, -20),
            eyeRadius,
            eyePaint,
          )
          ..drawCircle(
            center + const Offset(eyeOffset, -20),
            eyeRadius,
            eyePaint,
          );

        final mouthRect = Rect.fromCenter(
          center: center + const Offset(0, 20),
          width: 60,
          height: 40,
        );
        final startAngle = 0.2 + (i % 3) * 0.1;
        final sweepAngle = 2.7 - (i % 3) * 0.2;
        canvas.drawArc(mouthRect, startAngle, sweepAngle, false, mouthPaint);

        final textSpan = TextSpan(
          text: '#$i',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: ui.TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset((size.width - textPainter.width) / 2, size.height - 80),
        );

        final picture = recorder.endRecording();
        final img = await picture.toImage(
          size.width.toInt(),
          size.height.toInt(),
        );
        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final bytes = byteData.buffer.asUint8List();
          final mediaFile = MediaFile(
            mediaId: mediaId,
            type: MediaType.image,
            stored: true,
            requiresAuthentication: false,
            isDraftMedia: false,
            isFavorite: false,
            hasCropAnalyzed: false,
            hasThumbnail: false,
            createdAt: now,
          );
          final mediaService = MediaFileService(mediaFile);

          if (!mediaService.storedPath.parent.existsSync()) {
            mediaService.storedPath.parent.createSync(recursive: true);
          }
          mediaService.storedPath.writeAsBytesSync(bytes);
          mediaService.thumbnailPath.writeAsBytesSync(bytes);
        }
      }

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
      if (mounted) {
        setState(() {
          _isGeneratingMockImages = false;
        });
      }
    }
  }

  Future<void> toggleDeveloperSettings() async {
    await UserService.update((u) => u.isDeveloper = !u.isDeveloper);
  }

  Future<void> toggleVideoStabilization() async {
    await UserService.update(
      (u) => u.videoStabilizationEnabled = !u.videoStabilizationEnabled,
    );
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
                title: const Text('User ID'),
                subtitle: Text(userService.currentUser.userId.toString()),
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
                title: const Text('Share local database'),
                onTap: () async {
                  final dbCopyPath =
                      '${AppEnvironment.cacheDir}/twonly_copy.sqlite';
                  final dbCopyFile = File(dbCopyPath);
                  if (dbCopyFile.existsSync()) {
                    dbCopyFile.deleteSync();
                  }
                  try {
                    await twonlyDB.customStatement("VACUUM INTO '$dbCopyPath'");
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
                title: const Text('Toggle Video Stabilization'),
                onTap: toggleVideoStabilization,
                trailing: Switch.adaptive(
                  value: userService.currentUser.videoStabilizationEnabled,
                  onChanged: (a) => toggleVideoStabilization(),
                ),
              ),
              ListTile(
                title: const Text('Delete all (!) app data'),
                onTap: () async {
                  final ok = await showAlertDialog(
                    context,
                    'Sure?',
                    'If you do not have a backup, you have to register with a new account.',
                  );
                  if (ok) {
                    await deleteLocalUserData();
                    await Restart.restartApp(
                      notificationTitle: 'Account successfully deleted',
                      notificationBody: 'Click here to open the app again',
                      forceKill: true,
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Reduce flames'),
                onTap: () => context.push(Routes.settingsDeveloperReduceFlames),
              ),
              if (!kReleaseMode)
                ListTile(
                  title: const Text('Make it possible to reset flames'),
                  onTap: () async {
                    final chats = await twonlyDB.groupsDao.getAllDirectChats();

                    for (final chat in chats) {
                      await twonlyDB.groupsDao.updateGroup(
                        chat.groupId,
                        GroupsCompanion(
                          flameCounter: const Value(0),
                          maxFlameCounter: const Value(365),
                          lastFlameCounterChange: Value(clock.now()),
                          maxFlameCounterFrom: Value(
                            clock.now().subtract(const Duration(days: 1)),
                          ),
                        ),
                      );
                    }
                    await HapticFeedback.heavyImpact();
                  },
                ),
              if (!kReleaseMode)
                ListTile(
                  title: const Text('Automated Testing'),
                  onTap: () =>
                      context.push(Routes.settingsDeveloperAutomatedTesting),
                ),
              if (kDebugMode)
                ListTile(
                  title: const Text('Generate 1000 Mock Images'),
                  trailing: _isGeneratingMockImages
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                        )
                      : null,
                  onTap: _isGeneratingMockImages
                      ? null
                      : _generate1000MockImages,
                ),
              ListTile(
                title: const Text('Reopen Setup'),
                onTap: () async {
                  await UserService.update((u) {
                    u.currentSetupPage = SetupPages.profile.name;
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
