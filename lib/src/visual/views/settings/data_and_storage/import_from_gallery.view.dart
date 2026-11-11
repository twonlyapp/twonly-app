import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:twonly/src/services/android_photo_picker.service.dart';
import 'package:twonly/src/services/mediafiles/gallery_import.service.dart';
import 'package:twonly/src/utils/misc.dart' show AppColor, ShortCutsExtension;
import 'package:twonly/src/visual/components/selectable_thumbnail.comp.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/themes/light.dart';

class ImportFromGalleryView extends StatefulWidget {
  const ImportFromGalleryView({super.key});

  @override
  State<ImportFromGalleryView> createState() => _ImportFromGalleryViewState();
}

class _ImportFromGalleryViewState extends State<ImportFromGalleryView> {
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasPermission = false;
  List<AssetEntity> _assets = [];
  final Set<String> _selectedAssetIds = {};
  bool _showingAllImages = false;

  /// Set once an import started; the screen then only shows its progress.
  GalleryImportJob? _job;

  bool get _isImporting => _job != null;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _launchAndroidPicker();
      });
    } else {
      _checkPermissionAndLoad();
    }
  }

  @override
  void dispose() {
    _job
      ?..onProgress = null
      ..cancel();
    super.dispose();
  }

  Future<void> _launchAndroidPicker() async {
    final uris = await AndroidPhotoPickerService.pickImages();
    if (!mounted) return;
    if (uris.isEmpty) {
      Navigator.pop(context);
      return;
    }
    await _runImport([for (final uri in uris) AndroidUriSource(uri)]);
  }

  Future<void> _startImport() async {
    if (_selectedAssetIds.isEmpty) return;
    await _runImport([
      for (final asset in _assets)
        if (_selectedAssetIds.contains(asset.id)) GalleryAssetSource(asset),
    ]);
  }

  Future<void> _runImport(List<GalleryImportSource> sources) async {
    final job = GalleryImportJob(sources)
      ..onProgress = (_) {
        if (mounted) setState(() {});
      };
    setState(() => _job = job);
    final result = await job.run();
    if (mounted && !result.cancelled) {
      unawaited(HapticFeedback.mediumImpact());
    }
  }

  void _finish() {
    Navigator.of(context).pop(true);
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
      AssetPathEntity? album;
      if (_showingAllImages) {
        final albums = await PhotoManager.getAssetPathList(onlyAll: true);
        album = albums.firstOrNull;
      } else {
        final albums = await PhotoManager.getAssetPathList();
        for (final candidate in albums) {
          if (candidate.name.toLowerCase() == 'twonly') {
            album = candidate;
            break;
          }
        }
      }

      if (album == null) {
        setState(() {
          _assets = [];
          _isLoading = false;
        });
        return;
      }

      final count = await album.assetCountAsync;
      final assets = await album.getAssetListRange(start: 0, end: count);

      setState(() {
        _assets = assets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = context.lang.importGalleryLoadError(e.toString());
        _isLoading = false;
      });
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedAssetIds.length == _assets.length) {
        _selectedAssetIds.clear();
      } else {
        _selectedAssetIds
          ..clear()
          ..addAll(_assets.map((asset) => asset.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    final isAllSelected =
        _assets.isNotEmpty && _selectedAssetIds.length == _assets.length;

    return PopScope(
      // Leaving mid-import would cut items off half-way; the back gesture
      // asks the import to stop instead and the summary offers to leave.
      canPop: job == null || job.progress.finished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) job?.cancel();
      },
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          title: Text(context.lang.settingsStorageScanGalleryTitle),
          automaticallyImplyLeading: job == null || job.progress.finished,
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
        body: job != null
            ? _ImportProgressView(
                progress: job.progress,
                onStop: job.cancel,
                onDone: _finish,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isLoading && _hasPermission)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.1),
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
                      context.lang.importGalleryImportCount(
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
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: context.color.onSurfaceVariant,
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
              Icon(
                Icons.error_outline,
                size: 64,
                color: context.color.error,
              ),
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
              Icon(
                Icons.photo_album_outlined,
                size: 64,
                color: context.color.onSurfaceVariant,
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
                style: TextStyle(color: context.color.onSurfaceVariant),
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
}

class _ImportProgressView extends StatelessWidget {
  const _ImportProgressView({
    required this.progress,
    required this.onStop,
    required this.onDone,
  });

  final GalleryImportProgress progress;
  final VoidCallback onStop;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final colors = context.color;
    final finished = progress.finished;
    final stopping = progress.cancelled && !finished;

    final String title;
    final String subtitle;
    if (finished && progress.cancelled) {
      title = lang.importGalleryStoppedTitle;
      subtitle = lang.importGalleryProgressCount(
        progress.processed,
        progress.total,
      );
    } else if (finished) {
      title = lang.importGalleryDoneTitle;
      subtitle = lang.importGalleryProgressCount(
        progress.processed,
        progress.total,
      );
    } else {
      title = stopping
          ? lang.importGalleryStopping
          : lang.importGalleryProgressTitle;
      subtitle = lang.importGalleryProgressHint;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          children: [
            const Spacer(),
            _ProgressRing(progress: progress),
            const SizedBox(height: 32),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                title,
                key: ValueKey(title),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                _StatTile(
                  icon: Icons.check_circle_rounded,
                  color: colors.primary,
                  value: progress.imported,
                  label: lang.importGalleryImportedLabel,
                ),
                const SizedBox(width: 12),
                _StatTile(
                  icon: Icons.error_rounded,
                  color: progress.failed > 0
                      ? colors.error
                      : colors.onSurfaceVariant,
                  value: progress.failed,
                  label: lang.importGalleryFailedLabel,
                ),
                const SizedBox(width: 12),
                _StatTile(
                  icon: Icons.hourglass_bottom_rounded,
                  color: colors.onSurfaceVariant,
                  value: progress.total - progress.processed,
                  label: lang.importGalleryRemainingLabel,
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: finished
                  ? MyButton(
                      onPressed: onDone,
                      child: Text(lang.importGalleryDone),
                    )
                  : MyButton(
                      variant: MyButtonVariant.secondary,
                      onPressed: stopping ? null : onStop,
                      child: Text(
                        stopping
                            ? lang.importGalleryStopping
                            : lang.importGalleryStop,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress});

  final GalleryImportProgress progress;

  static const double _size = 176;

  @override
  Widget build(BuildContext context) {
    final colors = context.color;
    final done = progress.finished && !progress.cancelled;

    return SizedBox.square(
      dimension: _size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress.fraction),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
                backgroundColor: colors.surfaceContainerHighest,
                color: progress.failed > 0 && progress.finished
                    ? colors.tertiary
                    : colors.primary,
              ),
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: done
                      ? Icon(
                          Icons.check_rounded,
                          key: const ValueKey('done'),
                          size: 88,
                          color: colors.primary,
                        )
                      : Column(
                          key: const ValueKey('progress'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(value * 100).round()}%',
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                            ),
                            Text(
                              context.lang.importGalleryProgressCount(
                                progress.processed,
                                progress.total,
                              ),
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: context.color.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.color.onSurfaceVariant,
              ),
            ),
          ],
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
                  color: context.color.surfaceContainerHigh,
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
              Positioned.fill(
                child: Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    color: context.appColor(AppColor.mediaForeground),
                    size: 32,
                    shadows: [
                      Shadow(
                        color: context.appColor(AppColor.mediaScrim),
                        blurRadius: 6,
                      ),
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
