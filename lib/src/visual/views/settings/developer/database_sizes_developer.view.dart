import 'package:flutter/material.dart';
import 'package:twonly/core/backup/backup_archive.dart';
import 'package:twonly/core/bridge/wrapper/backup.dart';
import 'package:twonly/src/utils/misc.dart';

class DatabaseSizesDeveloperView extends StatefulWidget {
  const DatabaseSizesDeveloperView({super.key});

  @override
  State<DatabaseSizesDeveloperView> createState() =>
      _DatabaseSizesDeveloperViewState();
}

class _DatabaseSizesDeveloperViewState
    extends State<DatabaseSizesDeveloperView> {
  late Future<BackupStorageInfo> _storageInfo;

  @override
  void initState() {
    super.initState();
    _storageInfo = RustBackupArchive.storageInfo();
  }

  Future<void> _reload() async {
    final future = RustBackupArchive.storageInfo();
    setState(() => _storageInfo = future);
    // FutureBuilder displays any failure, including on pull-to-refresh.
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database & Backup Sizes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh sizes',
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<BackupStorageInfo>(
        future: _storageInfo,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load storage sizes.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: _reload,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }
          final info = snapshot.requireData;
          final tableBytes = info.tables.fold<int>(
            0,
            (total, table) => total + table.tableSizeBytes,
          );
          final indexBytes = info.tables.fold<int>(
            0,
            (total, table) => total + table.indexSizeBytes,
          );
          final fileBytes = info.files.fold<int>(
            0,
            (total, file) => total + (file.sizeBytes ?? 0),
          );
          final overhead =
              info.databaseSizeBytes -
              info.freeSizeBytes -
              tableBytes -
              indexBytes;

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const _SectionTitle('Main database · app_db.sqlite'),
                _SizeTile(
                  title: 'Allocated database size',
                  bytes: info.databaseSizeBytes,
                ),
                _SizeTile(title: 'Table data', bytes: tableBytes),
                _SizeTile(title: 'Indexes', bytes: indexBytes),
                _SizeTile(
                  title: 'Free pages',
                  subtitle: 'Allocated space available for reuse',
                  bytes: info.freeSizeBytes,
                ),
                _SizeTile(
                  title: 'Schema and other overhead',
                  bytes: overhead,
                ),
                const Divider(),
                _SectionTitle('Tables · ${info.tables.length}'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Largest first. Sizes include allocated table pages and '
                    'all indexes belonging to each table, including automatic '
                    'indexes. Empty tables can still occupy pages.',
                  ),
                ),
                for (final table in info.tables)
                  _SizeTile(
                    title: table.name,
                    subtitle:
                        '${table.rows} rows · '
                        'data ${formatBytes(table.tableSizeBytes)} · '
                        'indexes ${formatBytes(table.indexSizeBytes)}',
                    bytes: table.tableSizeBytes + table.indexSizeBytes,
                  ),
                const Divider(),
                const _SectionTitle('Contacts & messages backup contents'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Current local file sizes before backup. Database '
                    'snapshots, compression and encryption can change the '
                    'final archive size. Photos and videos use the separate '
                    'memories backup.',
                  ),
                ),
                _SizeTile(title: 'Total source files', bytes: fileBytes),
                for (final file in info.files)
                  _SizeTile(
                    title: file.name,
                    subtitle: _fileDescription(file.name),
                    bytes: file.sizeBytes,
                  ),
                const ListTile(
                  title: Text('backup-manifest.json'),
                  subtitle: Text(
                    'File sizes, checksums and schema versions. '
                    'Generated when the backup is created.',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _fileDescription(String name) => switch (name) {
  'app_db.sqlite' => 'Main database, including the tables above',
  'rust_db.sqlite' => 'Signal sessions, identities and encryption prekeys',
  'twonly.sqlite' => 'Legacy database retained for migration compatibility',
  'user_discovery_config.json' => 'User discovery configuration',
  'user.json' => 'Account settings and preferences',
  _ => 'Backup source file',
};

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _SizeTile extends StatelessWidget {
  const _SizeTile({required this.title, required this.bytes, this.subtitle});

  final String title;
  final String? subtitle;
  final int? bytes;

  @override
  Widget build(BuildContext context) {
    final size = bytes;
    final description = [
      ?subtitle,
      if (size == null) 'Missing · skipped by backup',
    ].join('\n');
    return ListTile(
      title: Text(title),
      subtitle: description.isEmpty ? null : Text(description),
      trailing: size == null
          ? const Text('—')
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatBytes(size)),
                Text(
                  '$size bytes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}
