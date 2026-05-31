import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/misc.dart' show ShortCutsExtension, sha256File;
import 'package:twonly/src/visual/components/selectable_thumbnail.comp.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/themes/light.dart';

class ImportFromGalleryView extends StatefulWidget {
  const ImportFromGalleryView({super.key});

  @override
  State<ImportFromGalleryView> createState() => _ImportFromGalleryViewState();
}

class _ImportFromGalleryViewState extends State<ImportFromGalleryView> {
  bool _isLoading = true;
  bool _isImporting = false;
  String? _errorMessage;
  bool _hasPermission = false;
  List<AssetEntity> _assets = [];
  final Set<String> _selectedAssetIds = {};
  bool _showingAllImages = false;
  double _importProgress = 0;
  String _importStatus = '';

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoad();
  }

  Future<void> _checkPermissionAndLoad() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ps = await PhotoManager.requestPermissionExtend();
      if (ps.isAuth || ps.hasAccess) {
        setState(() {
          _hasPermission = true;
        });
        await _loadMedia();
      } else {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
          _errorMessage = context.lang.importGalleryPermissionRequired;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = context.lang.importGalleryPermissionError(e.toString());
      });
    }
  }

  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_showingAllImages) {
        final albums = await PhotoManager.getAssetPathList(onlyAll: true);
        if (albums.isEmpty) {
          setState(() {
            _assets = [];
            _isLoading = false;
          });
          return;
        }
        final recentAlbum = albums.first;
        final count = await recentAlbum.assetCountAsync;
        final assets = await recentAlbum.getAssetListRange(
          start: 0,
          end: count,
        );

        setState(() {
          _assets = assets;
          _isLoading = false;
        });
      } else {
        final albums = await PhotoManager.getAssetPathList();

        AssetPathEntity? twonlyAlbum;
        for (final album in albums) {
          if (album.name.toLowerCase() == 'twonly') {
            twonlyAlbum = album;
            break;
          }
        }

        if (twonlyAlbum == null) {
          setState(() {
            _assets = [];
            _isLoading = false;
          });
          return;
        }

        final count = await twonlyAlbum.assetCountAsync;
        final assets = await twonlyAlbum.getAssetListRange(
          start: 0,
          end: count,
        );

        setState(() {
          _assets = assets;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = context.lang.importGalleryLoadError(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<DateTime> getImageCreationTime(AssetEntity asset, File file) async {
    final dates = <DateTime>[asset.createDateTime];

    if (!file.existsSync()) {
      return asset.createDateTime;
    }

    // Read the EXIF data
    try {
      final bytes = await file.readAsBytes();
      final data = await readExifFromBytes(bytes);

      for (final key in data.keys) {
        if (key.toLowerCase().contains('datetime') || key.contains('Time')) {
          final time = data[key]?.printable;
          if (time != null) {
            try {
              dates.add(
                DateFormat('yyyy:MM:dd HH:mm:ss').parse(time),
              );
            } catch (e) {
              // Ignore unparseable formats
            }
          }
        }
      }
    } catch (e) {
      // Ignore EXIF reading errors
    }

    // Return the oldest available date
    return dates.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedAssetIds.length == _assets.length) {
        _selectedAssetIds.clear();
      } else {
        _selectedAssetIds.clear();
        for (final asset in _assets) {
          _selectedAssetIds.add(asset.id);
        }
      }
    });
  }

  Future<void> _startImport() async {
    if (_selectedAssetIds.isEmpty) return;

    setState(() {
      _isImporting = true;
      _importProgress = 0;
      _importStatus = context.lang.importGalleryStarting;
    });

    final selectedAssets = _assets
        .where((a) => _selectedAssetIds.contains(a.id))
        .toList();
    final total = selectedAssets.length;
    var importedCount = 0;
    var duplicated = 0;
    var failedCount = 0;

    for (final asset in selectedAssets) {
      try {
        setState(() {
          _importStatus = context.lang.importGalleryImportingOf(
            importedCount + failedCount + 1,
            total,
          );
          _importProgress = (importedCount + failedCount) / total;
        });

        final file = await asset.file;
        if (file == null || !file.existsSync()) {
          failedCount++;
          continue;
        }

        final hash = Uint8List.fromList(await sha256File(file));

        final exsits = await twonlyDB.mediaFilesDao.getMediaByHash(hash);
        if (exsits.isNotEmpty) {
          duplicated += 1;
          continue;
        }

        final createdAt = await getImageCreationTime(asset, file);

        // Determine media type
        late final MediaType type;
        if (asset.type == AssetType.video) {
          type = MediaType.video;
        } else if (file.path.toLowerCase().endsWith('.gif')) {
          type = MediaType.gif;
        } else {
          type = MediaType.image;
        }

        final mediaFile = await twonlyDB.mediaFilesDao.insertOrUpdateMedia(
          MediaFilesCompanion(
            type: Value(type),
            createdAt: Value(createdAt),
            storedFileHash: Value(hash),
            stored: const Value(true),
          ),
        );

        if (mediaFile != null) {
          final mediaService = MediaFileService(mediaFile);
          await mediaService.storedPath.parent.create(recursive: true);
          await file.copy(mediaService.storedPath.path);

          await mediaService.calculateAndSaveSize();
          await mediaService.createThumbnail();

          importedCount++;
        } else {
          failedCount++;
        }
      } catch (e) {
        failedCount++;
      }
    }

    setState(() {
      _isImporting = false;
    });

    if (mounted) {
      showSnackbar(
        context,
        context.lang.importGalleryComplete(
          importedCount,
          duplicated,
          failedCount,
        ),
        level: SnackbarLevel.success,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAllSelected =
        _assets.isNotEmpty && _selectedAssetIds.length == _assets.length;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(context.lang.settingsStorageScanGalleryTitle),
        actions: [
          if (!_isLoading && _assets.isNotEmpty && !_isImporting)
            IconButton(
              icon: Icon(
                isAllSelected ? Icons.deselect : Icons.select_all,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: isAllSelected
                  ? context.lang.importGalleryDeselectAll
                  : context.lang.importGallerySelectAll,
              onPressed: _toggleSelectAll,
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isLoading && !_isImporting && _hasPermission)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.lang.importGalleryFilterTwonly,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: !_showingAllImages,
                        onChanged: (value) {
                          setState(() {
                            _showingAllImages = !value;
                            _selectedAssetIds.clear();
                          });
                          _loadMedia();
                        },
                      ),
                    ],
                  ),
                ),
              Expanded(child: _buildBody()),
            ],
          ),
          if (_isImporting) _buildImportingOverlay(),
        ],
      ),
      bottomNavigationBar:
          _assets.isEmpty ||
              _isLoading ||
              _isImporting ||
              _selectedAssetIds.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: primaryColorButtonStyle,
                  onPressed: _startImport,
                  child: Text(
                    _selectedAssetIds.isEmpty
                        ? context.lang.importGallerySelectToImport
                        : context.lang.importGalleryImportCount(
                            _selectedAssetIds.length,
                          ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (!_hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? context.lang.importGalleryPermissionDenied,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkPermissionAndLoad,
                child: Text(context.lang.importGalleryGrantAccess),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: PhotoManager.openSetting,
                child: Text(context.lang.importGalleryOpenSettings),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkPermissionAndLoad,
                child: Text(context.lang.importGalleryTryAgain),
              ),
            ],
          ),
        ),
      );
    }

    if (_assets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.photo_album_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _showingAllImages
                    ? context.lang.importGalleryNoImagesFound
                    : context.lang.importGalleryAlbumNotFound,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _showingAllImages
                    ? context.lang.importGalleryNoImagesFoundDesc
                    : context.lang.importGalleryAlbumNotFoundDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkPermissionAndLoad,
                child: Text(context.lang.importGalleryRefresh),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        4,
        4,
        4,
        MediaQuery.of(context).padding.bottom + 80,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 9 / 16,
      ),
      itemCount: _assets.length,
      itemBuilder: (context, index) {
        final asset = _assets[index];
        final isSelected = _selectedAssetIds.contains(asset.id);
        return GalleryThumbnailWidget(
          asset: asset,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedAssetIds.remove(asset.id);
              } else {
                _selectedAssetIds.add(asset.id);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildImportingOverlay() {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator.adaptive(),
              const SizedBox(height: 24),
              Text(
                _importStatus,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _importProgress),
            ],
          ),
        ),
      ),
    );
  }
}

class GalleryThumbnailWidget extends StatefulWidget {
  const GalleryThumbnailWidget({
    required this.asset,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final AssetEntity asset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<GalleryThumbnailWidget> createState() => _GalleryThumbnailWidgetState();
}

class _GalleryThumbnailWidgetState extends State<GalleryThumbnailWidget> {
  late final Future<Uint8List?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = widget.asset.thumbnailData;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SelectableThumbnailComp(
        isSelected: widget.isSelected,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<Uint8List?>(
              future: _thumbnailFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.data != null) {
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                  );
                }
                return ColoredBox(
                  color: Colors.grey.withValues(alpha: 0.1),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    ),
                  ),
                );
              },
            ),
            if (widget.asset.type == AssetType.video)
              const Positioned.fill(
                child: Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 32,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 6),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
