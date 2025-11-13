import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';

class ExportMediaView extends StatefulWidget {
  const ExportMediaView({super.key});

  @override
  State<ExportMediaView> createState() => _ExportMediaViewState();
}

class _ExportMediaViewState extends State<ExportMediaView> {
  double _progress = 0;
  String? _status;
  File? _zipFile;
  bool _isZipping = false;
  bool _zipSaved = false;

  Future<Directory> _mediaFolder() async {
    final dir = MediaFileService.buildDirectoryPath(
      'stored',
      await getApplicationSupportDirectory(),
    );
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _createZipFromMediaFolder() async {
    setState(() {
      _isZipping = true;
      _progress = 0.0;
      _status = 'Preparing...';
      _zipFile = null;
    });

    try {
      final folder = await _mediaFolder();
      final allFiles =
          folder.listSync(recursive: true).whereType<File>().toList();

      final mediaFiles = allFiles.where((f) {
        final name = p.basename(f.path).toLowerCase();
        if (name.contains('thumbnail')) return false;
        return true;
      }).toList();

      if (mediaFiles.isEmpty) {
        setState(() {
          _status = 'No memories found.';
          _isZipping = false;
        });
        return;
      }

      // compute total bytes for progress
      var totalBytes = 0;
      for (final f in mediaFiles) {
        totalBytes += await f.length();
      }

      final tempDir = await getTemporaryDirectory();
      final zipPath = p.join(
        tempDir.path,
        'memories.zip',
      );
      final encoder = ZipFileEncoder()..create(zipPath);

      var processedBytes = 0;
      for (final f in mediaFiles) {
        final relative = p.relative(f.path, from: folder.path);
        setState(() {
          _status = 'Adding $relative';
        });

        // ZipFileEncoder doesn't give per-file progress; update after adding.
        await encoder.addFile(f, relative);

        processedBytes += await f.length();
        setState(() {
          _progress = totalBytes > 0 ? processedBytes / totalBytes : 0.0;
        });

        await Future.delayed(
          const Duration(milliseconds: 10),
        );
      }

      await encoder.close();

      setState(() {
        _zipFile = File(zipPath);
        _status = 'ZIP created: ${p.basename(zipPath)}';
        _progress = 1.0;
        _isZipping = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isZipping = false;
      });
    }
  }

  Future<void> _saveZip() async {
    if (_zipFile == null) return;
    try {
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save your memories to desired location',
        fileName: p.basename(_zipFile!.path),
        bytes: _zipFile!.readAsBytesSync(),
      );
      if (outputFile == null) return;
      _zipSaved = true;
      _status = 'ZIP stored: ${p.basename(_zipFile!.path)}';
      setState(() {});
    } catch (e) {
      setState(() => _status = 'Save failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export memories'),
      ),
      body: Container(
        margin: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Here, you can export all you memories.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (_isZipping || _zipFile != null)
              LinearProgressIndicator(
                value: _isZipping ? _progress : (_zipFile != null ? 1.0 : 0.0),
              ),
            const SizedBox(height: 8),
            if (_status != null)
              Text(
                _status!,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            if (_zipFile == null)
              ElevatedButton.icon(
                icon: const Icon(Icons.archive),
                label: Text(
                  _isZipping ? 'Zipping...' : 'Create ZIP from mediafiles',
                ),
                onPressed: _isZipping ? null : _createZipFromMediaFolder,
              )
            else if (!_zipSaved)
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt),
                label: const Text('Save ZIP'),
                onPressed: (_zipFile != null && !_isZipping) ? _saveZip : null,
              ),
          ],
        ),
      ),
    );
  }
}
