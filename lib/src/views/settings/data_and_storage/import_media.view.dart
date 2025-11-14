import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';

class ImportMediaView extends StatefulWidget {
  const ImportMediaView({super.key});

  @override
  State<ImportMediaView> createState() => _ImportMediaViewState();
}

class _ImportMediaViewState extends State<ImportMediaView> {
  double _progress = 0;
  String? _status;
  File? _zipFile;
  bool _isProcessing = false;

  Future<void> _pickAndImportZip() async {
    setState(() {
      _status = null;
      _progress = 0;
      _zipFile = null;
      _isProcessing = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _status = 'No file selected.';
          _isProcessing = false;
        });
        return;
      }

      final pickedPath = result.files.single.path;
      if (pickedPath == null) {
        setState(() {
          _status = 'Selected file has no path.';
          _isProcessing = false;
        });
        return;
      }

      final pickedFile = File(pickedPath);
      if (!pickedFile.existsSync()) {
        setState(() {
          _status = 'Selected file does not exist.';
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _zipFile = pickedFile;
        _status = 'Selected ${p.basename(pickedPath)}';
      });

      await _extractZipToMediaFolder(pickedFile);
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _extractZipToMediaFolder(File zipFile) async {
    setState(() {
      _status = 'Reading archive...';
      _progress = 0;
    });

    try {
      final stream = InputFileStream(zipFile.path);

      final archive = ZipDecoder().decodeStream(stream);

      // Optionally: compute total entries to show progress
      final entries = archive.where((e) => e.isFile).toList();
      final total = entries.length;
      var processed = 0;

      for (final file in entries) {
        if (!file.isFile || file.isSymbolicLink) continue;

        final extSplit = file.name.split('.');
        if (extSplit.isEmpty) continue;
        final ext = extSplit.last;

        late MediaType type;
        switch (ext) {
          case 'webp':
            type = MediaType.image;
          case 'mp4':
            type = MediaType.video;
          case 'gif':
            type = MediaType.gif;
          default:
            continue;
        }

        final mediaFile = await twonlyDB.mediaFilesDao.insertMedia(
          MediaFilesCompanion(
            type: Value(type),
            createdAt: Value(file.lastModDateTime),
            stored: const Value(true),
          ),
        );
        final mediaService = await MediaFileService.fromMedia(mediaFile!);
        await mediaService.storedPath.writeAsBytes(file.content);

        processed++;
        setState(() {
          _progress = total > 0 ? processed / total : 0;
          _status = 'Imported ${file.name}';
        });

        // allow UI to update for large archives
        await Future.delayed(const Duration(milliseconds: 10));
      }

      setState(() {
        _status = 'Import complete. ${entries.length} entries processed.';
        _isProcessing = false;
        _progress = 1;
      });
    } catch (e) {
      setState(() {
        _status = 'Extraction failed: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import memories'),
      ),
      body: Container(
        margin: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Here, you can import exported memories.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (_isProcessing || _zipFile != null)
              LinearProgressIndicator(
                value:
                    _isProcessing ? _progress : (_zipFile != null ? 1.0 : 0.0),
              ),
            const SizedBox(height: 8),
            if (_status != null)
              Text(
                _status!,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_upload),
              label: Text(
                _isProcessing
                    ? 'Processing...'
                    : 'Select memories.zip to import',
              ),
              onPressed: _isProcessing ? null : _pickAndImportZip,
            ),
          ],
        ),
      ),
    );
  }
}
