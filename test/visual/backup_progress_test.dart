import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/backup/progress.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/visual/views/settings/backup/components/backup_archive_subtitle.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/components/backup_progress.comp.dart';

Widget app(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('backup stages and actual upload bytes update the progress bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const BackupProgressComp(
          progress: BackupProgress(
            stage: BackupStage.compressing,
            completedBytes: 0,
            totalBytes: 0,
          ),
        ),
      ),
    );
    expect(find.text('Compressing backup…'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      isNull,
    );

    await tester.pumpWidget(
      app(
        const BackupProgressComp(
          progress: BackupProgress(
            stage: BackupStage.uploadingArchive,
            completedBytes: 250000,
            totalBytes: 1000000,
          ),
        ),
      ),
    );
    expect(find.text('Uploading contacts and messages… · 25%'), findsOneWidget);
    expect(find.text('250 KB / 1 MB'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      .25,
    );
  });

  testWidgets('UTC backup dates use local time and the local calendar day', (
    tester,
  ) async {
    // Run with TZ=Europe/Berlin to cover a UTC timestamp on the previous day.
    final timestamp = DateTime.utc(2026, 10, 29, 23, 30);
    final local = timestamp.toLocal();
    await withClock(
      Clock.fixed(DateTime(local.year, local.month, local.day, 12)),
      () async {
        await tester.pumpWidget(
          app(BackupArchiveSubtitle(date: timestamp, size: 32000000)),
        );
        final hour = local.hour.toString().padLeft(2, '0');
        final minute = local.minute.toString().padLeft(2, '0');
        expect(find.text('Today at $hour:$minute • 32 MB'), findsOneWidget);
      },
    );
  });
}
