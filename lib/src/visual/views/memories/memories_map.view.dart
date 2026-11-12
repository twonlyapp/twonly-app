import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart'
    as db_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/performance_tracking.service.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/helpers/map_style.helper.dart';
import 'package:twonly/src/visual/helpers/memory_map.helper.dart';
import 'package:twonly/src/visual/helpers/memory_map_countries.helper.dart';
import 'package:twonly/src/visual/views/memories/components/memories_map_gallery.comp.dart';
import 'package:twonly/src/visual/views/memories/synchronized_viewer.view.dart';

class MemoriesMapView extends StatefulWidget {
  const MemoriesMapView({
    this.favoritesOnly = false,
    this.initialMedia,
    super.key,
  }) : storyItems = null,
       onOpenStories = null;

  /// Stories share the Memories map's camera, viewport filtering and gallery.
  const MemoriesMapView.stories({
    required Stream<List<MemoryItem>> this.storyItems,
    required Future<void> Function(List<MemoryItem>, int) this.onOpenStories,
    super.key,
  }) : favoritesOnly = false,
       initialMedia = null;

  final bool favoritesOnly;
  final MediaFile? initialMedia;
  final Stream<List<MemoryItem>>? storyItems;
  final Future<void> Function(List<MemoryItem>, int)? onOpenStories;
  bool get isStories => storyItems != null;

  @override
  State<MemoriesMapView> createState() => _MemoriesMapViewState();
}

class _MemoriesMapViewState extends State<MemoriesMapView> {
  static const _rawSource = 'memory-locations';
  static const _clusterSource = 'memory-clusters';
  static const _heatmap = 'memory-heatmap';
  static const _clusters = 'memory-cluster-circles';
  static const _counts = 'memory-cluster-counts';
  static const _markers = 'memory-markers';
  static const _storySourcePrefix = 'story-locations-';

  final _sheetController = DraggableScrollableController();
  final _activeMediaId = ValueNotifier<String?>(null);
  StreamSubscription<Object?>? _subscription;
  final Map<int, Uint8List> _avatarImages = {};
  final Set<int> _installedAvatars = {};
  final Set<int> _storySenders = {};
  MapLibreMapController? _map;
  Animation<double>? _routeAnimation;
  bool _closing = false;
  List<MemoryItem> _items = [];
  List<MemoryMapPoint> _points = [];
  List<MemoryItem> _visibleItems = [];
  CameraPosition? _initialCamera;
  CameraPosition? _lastCamera;
  Size _mapSize = Size.zero;
  String? _style;
  bool _loadingMemories = true;
  bool _loadingCountries = true;
  List<MemoryMapCountry> _countries = [];
  bool _styleReady = false;
  bool _layersReady = false;
  bool _failed = false;
  bool _loadingViewport = true;
  bool _visibleItemsLocked = false;
  int _epoch = 0;
  int _mapGeneration = 0;
  int _viewportRequest = 0;
  double _sheetSize = MemoriesMapGallery.initialSize;
  double? _appliedPadding;
  Timer? _loadTimeout;
  Timer? _viewportDebounce;
  Future<void> _operations = Future.value();

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_onSheetChanged);
    unawaited(_loadCountries());
    _subscribe();
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await loadMemoryMapCountries();
      if (mounted) _countries = countries;
    } catch (error) {
      Log.warn('Could not load map country boundaries: $error');
    } finally {
      if (mounted) setState(() => _loadingCountries = false);
    }
  }

  void _subscribe() {
    unawaited(_subscription?.cancel());
    if (widget.isStories) {
      _subscription = widget.storyItems!.listen(
        _onItems,
        onError: (Object error, StackTrace stack) {
          Log.error('Could not load story map: $error');
          if (mounted) {
            setState(() {
              _loadingMemories = false;
              _failed = true;
            });
          }
        },
      );
      return;
    }
    _subscription =
        watchRustDatabase(
          (control) => rust_mediafiles
              .watchMediaFiles(
                input: db_mediafiles.MediaQuery(
                  filter: db_mediafiles.MediaFilter.geotagged,
                  favoritesOnly: widget.favoritesOnly,
                ),
                control: control,
              )
              .map(orderedMediaFiles),
        ).listen(
          _onMemories,
          onError: (Object error, StackTrace stack) {
            Log.error('Could not load map memories: $error');
            if (mounted) {
              setState(() {
                _loadingMemories = false;
                _failed = true;
              });
            }
          },
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (!identical(animation, _routeAnimation)) {
      _routeAnimation?.removeStatusListener(_handleRouteAnimation);
      _routeAnimation = animation;
      animation?.addStatusListener(_handleRouteAnimation);
    }
    final style = mapStyleForBrightness(Theme.of(context).brightness);
    if (style == _style) return;
    _style = style;
    _epoch++;
    _styleReady = false;
    _layersReady = false;
    _appliedPadding = null;
    _failed = false;
    _startLoadTimeout();
  }

  // Like WebxdcAppView, stop native rendering before the first closing frame.
  // Watching the route also covers system back and cancelled back gestures;
  // waiting for dispose would keep rendering throughout the transition.
  void _handleRouteAnimation(AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      _closing = true;
      _viewportDebounce?.cancel();
      unawaited(_setMapPaused(true));
    } else if (status == AnimationStatus.forward ||
        (status == AnimationStatus.completed && _closing)) {
      _closing = false;
      unawaited(_setMapPaused(false));
      _scheduleViewport();
    }
  }

  Future<void> _setMapPaused(bool paused) async {
    final map = _map;
    if (map == null || map.isDisposed) return;
    try {
      if (paused) {
        await map.pauseMap();
      } else {
        await map.resumeMap();
      }
    } catch (error) {
      if (mounted && !map.isDisposed) {
        Log.error('Could not change memory map rendering: $error');
      }
    }
  }

  void _onMemories(List<MediaFile> files) {
    _onItems(
      files
          .map(
            (file) => MemoryItem(
              mediaService: MediaFileService(file),
              messages: [],
            ),
          )
          .toList(),
    );
  }

  MemoryMapPoint _itemPoint(MemoryItem item) {
    if (!widget.isStories) return _point(item.mediaService.mediaFile);
    final message = item.messages.first;
    final location = storyLocation(message);
    return MemoryMapPoint(
      mediaId: item.mediaService.mediaFile.mediaId,
      latitude: location?.latitude ?? double.nan,
      longitude: location?.longitude ?? double.nan,
      senderId: message.senderId,
    );
  }

  void _onItems(List<MemoryItem> items) {
    if (!mounted) return;
    final valid = items.where((item) => _itemPoint(item).isValid).toList();
    setState(() {
      _loadingMemories = false;
      _items = valid;
      _points = valid.map(_itemPoint).toList();
      if (_visibleItemsLocked) {
        // Keep the selection while expanded, but still reflect deletions and
        // changes to the selected memories.
        final visibleIds = _visibleItems
            .map((item) => item.mediaService.mediaFile.mediaId)
            .toSet();
        _visibleItems = _items
            .where(
              (item) =>
                  visibleIds.contains(item.mediaService.mediaFile.mediaId),
            )
            .toList();
      }
      if (_points.isEmpty) {
        _epoch++;
        _map = null;
        _initialCamera = null;
        _lastCamera = null;
        _layersReady = false;
        _styleReady = false;
        _appliedPadding = null;
        _loadingViewport = true;
        _visibleItemsLocked = false;
        _visibleItems = [];
        _sheetSize = MemoriesMapGallery.initialSize;
      }
    });
    if (_points.isNotEmpty && _map == null) _startLoadTimeout();
    if (_layersReady) {
      final epoch = _epoch;
      _enqueue((map) async {
        final data = memoryMapGeoJson(_points);
        await map.setGeoJsonSource(_rawSource, data);
        if (!_current(epoch, map) || !_layersReady) return;
        if (widget.isStories) {
          await _syncStorySources(map, epoch);
        } else {
          await map.setGeoJsonSource(_clusterSource, data);
        }
        if (!_current(epoch, map)) return;
      });
      _scheduleViewport();
    }
  }

  Future<ui.Codec> _avatarCodec(int sender) async {
    try {
      final path = await PerformanceTracking.resolveAvatar(sender);
      if (path != null) {
        return await ui.instantiateImageCodec(await File(path).readAsBytes());
      }
    } on Object catch (error) {
      Log.warn('Could not render story map avatar: $error');
    }
    final fallback = await rootBundle.load('assets/images/default_avatar.png');
    return ui.instantiateImageCodec(
      fallback.buffer.asUint8List(
        fallback.offsetInBytes,
        fallback.lengthInBytes,
      ),
    );
  }

  Future<void> _installAvatars(
    MapLibreMapController map,
    int epoch, {
    Iterable<int>? senders,
  }) async {
    for (final sender
        in senders ?? _points.map((p) => p.senderId).whereType<int>().toSet()) {
      if (!_current(epoch, map)) return;
      if (_installedAvatars.contains(sender)) continue;
      var bytes = _avatarImages[sender];
      if (bytes == null) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        const center = Offset(48, 48);
        final codec = await _avatarCodec(sender);
        final frame = await codec.getNextFrame();
        codec.dispose();
        canvas
          ..save()
          ..clipPath(
            Path()..addOval(Rect.fromCircle(center: center, radius: 42)),
          )
          ..drawImageRect(
            frame.image,
            Rect.fromLTWH(
              0,
              0,
              frame.image.width.toDouble(),
              frame.image.height.toDouble(),
            ),
            const Rect.fromLTWH(6, 6, 84, 84),
            Paint()..filterQuality = FilterQuality.medium,
          )
          ..restore();
        final picture = recorder.endRecording();
        final ui.Image image;
        try {
          image = await picture.toImage(96, 96);
        } finally {
          picture.dispose();
          frame.image.dispose();
        }
        final ByteData? data;
        try {
          data = await image.toByteData(format: ui.ImageByteFormat.png);
        } finally {
          image.dispose();
        }
        if (data == null) continue;
        bytes = data.buffer.asUint8List();
        _avatarImages[sender] = bytes;
      }
      if (!_current(epoch, map)) return;
      await map.addImage('story-avatar-$sender', bytes);
      if (_current(epoch, map)) _installedAvatars.add(sender);
    }
  }

  String _storySource(int sender) => '$_storySourcePrefix$sender';
  String _storyLayer(int sender, {required bool clustered}) =>
      '${clustered ? _clusters : _markers}-$sender';

  /// A source per author prevents native clustering from combining people.
  Future<void> _syncStorySources(MapLibreMapController map, int epoch) async {
    final bySender = <int, List<MemoryMapPoint>>{};
    for (final point in _points) {
      final sender = point.senderId;
      if (sender != null) bySender.putIfAbsent(sender, () => []).add(point);
    }
    // Images must exist before native symbol layout resolves their IDs.
    await _installAvatars(map, epoch, senders: bySender.keys);
    if (!_current(epoch, map)) return;
    for (final sender in _storySenders.difference(bySender.keys.toSet())) {
      for (final clustered in [true, false]) {
        await map.removeLayer(_storyLayer(sender, clustered: clustered));
        if (!_current(epoch, map)) return;
      }
      await map.removeSource(_storySource(sender));
      if (!_current(epoch, map)) return;
      _storySenders.remove(sender);
    }
    for (final entry in bySender.entries) {
      final sender = entry.key;
      final source = _storySource(sender);
      final data = memoryMapGeoJson(entry.value);
      if (_storySenders.contains(sender)) {
        await map.setGeoJsonSource(source, data);
        if (!_current(epoch, map)) return;
        continue;
      }
      await map.addSource(
        source,
        GeojsonSourceProperties(
          data: data,
          cluster: true,
          clusterMaxZoom: 16,
          // Cluster IDs are local to a source. Retain it for tap-to-zoom.
          clusterProperties: {
            'storySource': [
              [
                'coalesce',
                ['accumulated'],
                ['get', 'storySource'],
              ],
              ['literal', source],
            ],
          },
        ),
      );
      if (!_current(epoch, map)) return;
      for (final clustered in [true, false]) {
        await map.addSymbolLayer(
          source,
          _storyLayer(sender, clustered: clustered),
          SymbolLayerProperties(
            iconImage: 'story-avatar-$sender',
            // Single stories use 0.55; clusters grow gently and stop at
            // 0.65, even for very large collections.
            iconSize: clustered
                ? const [
                    'interpolate',
                    ['linear'],
                    ['get', 'point_count'],
                    2,
                    0.6,
                    20,
                    0.65,
                  ]
                : 0.55,
            iconAllowOverlap: true,
            iconIgnorePlacement: true,
            textFont: const ['Noto Sans Regular'],
          ),
          filter: clustered
              ? ['has', 'point_count']
              : [
                  '!',
                  ['has', 'point_count'],
                ],
          enableInteraction: false,
        );
        if (!_current(epoch, map)) return;
      }
      _storySenders.add(sender);
    }
  }

  MemoryMapPoint _point(MediaFile file) => MemoryMapPoint(
    mediaId: file.mediaId,
    latitude: file.locationLatitude ?? double.nan,
    longitude: file.locationLongitude ?? double.nan,
  );

  void _startLoadTimeout() {
    _loadTimeout?.cancel();
    _loadTimeout = Timer(const Duration(seconds: 20), () {
      if (mounted && !_layersReady && _points.isNotEmpty) {
        setState(() => _failed = true);
      }
    });
  }

  bool _current(int epoch, MapLibreMapController map) =>
      mounted && epoch == _epoch && identical(map, _map) && !map.isDisposed;

  /// Serialize native style operations. An epoch stops a previous theme's
  /// pending work from overwriting a newly loaded style.
  void _enqueue(Future<void> Function(MapLibreMapController) operation) {
    final epoch = _epoch;
    final map = _map;
    if (map == null) return;
    _operations = _operations.then((_) async {
      if (!_current(epoch, map)) return;
      try {
        await operation(map);
      } catch (error) {
        if (!_current(epoch, map)) return;
        Log.error('Memory map operation failed: $error');
        setState(() => _failed = true);
      }
    });
  }

  void _onStyleLoaded() {
    _installedAvatars.clear();
    _storySenders.clear();
    _styleReady = true;
    _layersReady = false;
    final epoch = _epoch;
    final data = memoryMapGeoJson(_points);
    _enqueue((map) async {
      final layerIds = (await map.getLayerIds()).cast<String>();
      final sourceIds = (await map.getSourceIds()).cast<String>();
      final steps = <Future<void> Function()>[
        for (final layer in [_counts, _markers, _clusters, _heatmap])
          if (layerIds.contains(layer)) () => map.removeLayer(layer),
        for (final layer in layerIds.where(
          (id) => id.startsWith('$_clusters-') || id.startsWith('$_markers-'),
        ))
          () => map.removeLayer(layer),
        for (final source in [_clusterSource, _rawSource])
          if (sourceIds.contains(source)) () => map.removeSource(source),
        for (final source in sourceIds.where(
          (id) => id.startsWith(_storySourcePrefix),
        ))
          () => map.removeSource(source),
        () => map.addSource(_rawSource, GeojsonSourceProperties(data: data)),
        if (!widget.isStories)
          () => map.addSource(
            _clusterSource,
            GeojsonSourceProperties(
              data: data,
              cluster: true,
              clusterMaxZoom: 16,
            ),
          ),
        if (widget.isStories) () => _syncStorySources(map, epoch),
        if (!widget.isStories)
          () => map.addHeatmapLayer(
            _rawSource,
            _heatmap,
            const HeatmapLayerProperties(
              heatmapRadius: [
                'interpolate',
                ['linear'],
                ['zoom'],
                2,
                16,
                12,
                36,
              ],
              heatmapIntensity: [
                'interpolate',
                ['linear'],
                ['zoom'],
                2,
                0.6,
                12,
                1.5,
              ],
              heatmapOpacity: [
                'interpolate',
                ['linear'],
                ['zoom'],
                9,
                0.8,
                13,
                0,
              ],
              heatmapColor: [
                'interpolate',
                ['linear'],
                ['heatmap-density'],
                0,
                'rgba(33,102,172,0)',
                0.2,
                '#67a9cf',
                0.4,
                '#a6d96a',
                0.6,
                '#fee08b',
                0.8,
                '#f46d43',
                1,
                '#d73027',
              ],
            ),
            maxzoom: 13,
          ),
        if (!widget.isStories)
          () => map.addCircleLayer(
            _clusterSource,
            _clusters,
            const CircleLayerProperties(
              circleColor: '#337eae',
              circleRadius: [
                'step',
                ['get', 'point_count'],
                18,
                20,
                23,
                100,
                28,
              ],
              circleStrokeColor: '#ffffff',
              circleStrokeWidth: 2,
            ),
            minzoom: 9,
            filter: ['has', 'point_count'],
            enableInteraction: false,
          ),
        if (!widget.isStories)
          () => map.addCircleLayer(
            _clusterSource,
            _markers,
            const CircleLayerProperties(
              circleColor: '#337eae',
              circleRadius: 7,
              circleStrokeColor: '#ffffff',
              circleStrokeWidth: 2,
            ),
            minzoom: 9,
            filter: [
              '!',
              ['has', 'point_count'],
            ],
            enableInteraction: false,
          ),
        if (!widget.isStories)
          () => map.addSymbolLayer(
            _clusterSource,
            _counts,
            const SymbolLayerProperties(
              textField: [
                'to-string',
                ['get', 'point_count_abbreviated'],
              ],
              textSize: 13,
              textFont: ['Noto Sans Regular'],
              textColor: '#ffffff',
              textAllowOverlap: true,
              textIgnorePlacement: true,
            ),
            minzoom: 9,
            filter: ['has', 'point_count'],
            enableInteraction: false,
          ),
      ];
      for (final step in steps) {
        if (!_current(epoch, map)) return;
        await step();
      }
      if (!_current(epoch, map)) return;
      // The database may have emitted while the layers were being installed.
      final latest = memoryMapGeoJson(_points);
      await map.setGeoJsonSource(_rawSource, latest);
      if (!_current(epoch, map)) return;
      if (widget.isStories) {
        await _syncStorySources(map, epoch);
      } else {
        await map.setGeoJsonSource(_clusterSource, latest);
      }
      if (!_current(epoch, map)) return;
      await _updatePadding(map);
      if (!_current(epoch, map)) return;
      _loadTimeout?.cancel();
      setState(() {
        _layersReady = true;
        _failed = false;
      });
      _scheduleViewport();
    });
  }

  void _onSheetChanged() {
    if (!_sheetController.isAttached || !mounted) return;
    final size = _sheetController.size;
    if (size == _sheetSize) return;
    setState(() {
      // Expanding the gallery must not discard the photos being browsed as
      // the map's visible area gets smaller. Shrinking resumes map filtering;
      // snapping to the normal or collapsed position must leave it unlocked.
      if (size <= MemoriesMapGallery.initialSize || size < _sheetSize) {
        _visibleItemsLocked = false;
      } else if (!_loadingViewport) {
        _visibleItemsLocked = true;
      }
      _sheetSize = size;
    });
    _scheduleViewport();
  }

  Future<void> _updatePadding(MapLibreMapController map) async {
    final padding = _sheetSize * _mapSize.height;
    if (_appliedPadding == padding) return;
    _appliedPadding = padding;
    await map.setPadding(bottom: padding);
  }

  void _scheduleViewport() {
    if (_closing) return;
    _viewportRequest++;
    _viewportDebounce?.cancel();
    _viewportDebounce = Timer(const Duration(milliseconds: 120), () {
      _enqueue((map) async {
        if (!_layersReady) return;
        final epoch = _epoch;
        await _updatePadding(map);
        if (!_current(epoch, map)) return;
        await _refreshVisible(map);
      });
    });
  }

  Future<void> _refreshVisible(MapLibreMapController map) async {
    final request = _viewportRequest;
    final epoch = _epoch;
    final visibleHeight = _mapSize.height * (1 - _sheetSize);
    if (_mapSize.isEmpty || !_layersReady || _visibleItemsLocked) return;
    // Android's native projection takes physical pixels. UIKit and the web
    // renderer use logical points, matching Flutter's layout coordinates.
    final projectionScale =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? MediaQuery.devicePixelRatioOf(context)
        : 1.0;
    final corners = await Future.wait([
      map.toLatLng(const math.Point<double>(0, 0)),
      map.toLatLng(
        math.Point<double>(
          _mapSize.width * projectionScale,
          visibleHeight * projectionScale,
        ),
      ),
    ]);
    if (!_current(epoch, map) ||
        request != _viewportRequest ||
        _visibleItemsLocked) {
      return;
    }
    final visibleIds = _points
        .where(
          (point) => memoryMapContains(
            point,
            south: math.min(corners[0].latitude, corners[1].latitude),
            north: math.max(corners[0].latitude, corners[1].latitude),
            west: corners[0].longitude,
            east: corners[1].longitude,
          ),
        )
        .map((p) => p.mediaId)
        .toSet();
    setState(() {
      _visibleItems = _items
          .where(
            (item) => visibleIds.contains(item.mediaService.mediaFile.mediaId),
          )
          .toList();
      _loadingViewport = false;
    });
  }

  Future<void> _onMapTap(math.Point<double> point, LatLng coordinates) async {
    final map = _map;
    final epoch = _epoch;
    if (map == null || !_layersReady) return;
    try {
      final features = await map.queryRenderedFeaturesInRect(
        Rect.fromCenter(
          center: Offset(point.x, point.y),
          width: 24,
          height: 24,
        ),
        widget.isStories
            ? [
                for (final sender in _storySenders)
                  for (final clustered in [true, false])
                    _storyLayer(sender, clustered: clustered),
              ]
            : [_clusters, _markers],
        null,
      );
      if (!_current(epoch, map) || features.isEmpty) return;
      final feature = Map<String, dynamic>.from(features.first as Map);
      final properties = Map<String, dynamic>.from(
        feature['properties'] as Map,
      );
      final geometry = Map<String, dynamic>.from(feature['geometry'] as Map);
      final position = geometry['coordinates'] as List;
      final target = LatLng(
        (position[1] as num).toDouble(),
        (position[0] as num).toDouble(),
      );
      final clusterId = properties['cluster_id'] as num?;
      if (clusterId != null) {
        final source = widget.isStories
            ? properties['storySource'] as String?
            : _clusterSource;
        if (source == null ||
            (widget.isStories &&
                !_storySenders.any(
                  (sender) => _storySource(sender) == source,
                ))) {
          return;
        }
        final zoom = await map.getClusterExpansionZoom(
          source,
          clusterId.toInt(),
        );
        if (!_current(epoch, map)) return;
        await map.animateCamera(
          CameraUpdate.newLatLngZoom(target, zoom.toDouble()),
        );
      } else {
        final id = properties['mediaId'] as String?;
        final index = _items.indexWhere(
          (item) => item.mediaService.mediaFile.mediaId == id,
        );
        if (index >= 0) await _openViewer(List.of(_items), index);
      }
    } catch (error) {
      Log.error('Could not select map location: $error');
    }
  }

  Future<void> _openViewer(List<MemoryItem> items, int index) async {
    if (widget.onOpenStories != null) {
      await widget.onOpenStories!(items, index);
      if (mounted) _scheduleViewport();
      return;
    }
    _activeMediaId.value = items[index].mediaService.mediaFile.mediaId;
    await Navigator.push<void>(
      context,
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) =>
            SynchronizedImageViewerScreen(
              galleryItems: items,
              initialIndex: index,
              activeMediaIdNotifier: _activeMediaId,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    if (mounted) _scheduleViewport();
  }

  void _retry() {
    setState(() {
      _epoch++;
      _mapGeneration++;
      _map = null;
      _styleReady = false;
      _layersReady = false;
      _appliedPadding = null;
      _failed = false;
    });
    _subscribe();
    _startLoadTimeout();
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_handleRouteAnimation);
    _epoch++;
    _viewportDebounce?.cancel();
    _loadTimeout?.cancel();
    unawaited(_subscription?.cancel());
    _sheetController
      ..removeListener(_onSheetChanged)
      ..dispose();
    _activeMediaId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark,
    child: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildContent(context),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              bottom: false,
              right: false,
              minimum: const EdgeInsets.all(16),
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                elevation: widget.isStories ? 0 : 4,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: BackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildContent(BuildContext context) =>
      _loadingMemories || _loadingCountries
      ? const Center(child: CircularProgressIndicator())
      : _points.isEmpty
      ? Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off_outlined, size: 56),
                const SizedBox(height: 16),
                Text(
                  _failed
                      ? context.lang.memoriesMapLoadError
                      : widget.isStories
                      ? context.lang.storyMapNoLocations
                      : context.lang.memoriesMapNoLocations,
                  textAlign: TextAlign.center,
                ),
                if (_failed)
                  TextButton(
                    onPressed: _retry,
                    child: Text(context.lang.manualVerificationRetry),
                  )
                else if (!widget.isStories)
                  StreamBuilder<void>(
                    stream: userService.onUserUpdated,
                    builder: (context, _) =>
                        userService.currentUser.storeLocationInMemories
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: MyButton(
                              variant: MyButtonVariant.primaryMiddle,
                              onPressed: () =>
                                  context.push<void>(Routes.settingsMemories),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.settings_outlined),
                                  const SizedBox(width: 8),
                                  Text(context.lang.importGalleryOpenSettings),
                                ],
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ),
        )
      : LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            if (size != _mapSize) {
              _mapSize = size;
              _scheduleViewport();
            }
            final initialMedia = widget.initialMedia;
            final initialPoint = initialMedia == null
                ? null
                : _point(initialMedia);
            _initialCamera ??= initialPoint != null && initialPoint.isValid
                ? CameraPosition(target: initialPoint.coordinates, zoom: 14)
                : mostPopulatedMemoryCamera(
                    _points,
                    countries: _countries,
                    width: size.width,
                    height: size.height * (1 - MemoriesMapGallery.initialSize),
                  );
            return Stack(
              children: [
                Positioned.fill(
                  child: MapLibreMap(
                    key: ValueKey(_mapGeneration),
                    styleString: _style!,
                    initialCameraPosition: _lastCamera ?? _initialCamera,
                    trackCameraPosition: true,
                    annotationOrder: const [],
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    attributionButtonPosition:
                        AttributionButtonPosition.topRight,
                    attributionButtonMargins: math.Point(
                      16,
                      MediaQuery.paddingOf(context).top + 16,
                    ),
                    onMapCreated: (map) {
                      _map = map;
                      if (_closing) unawaited(_setMapPaused(true));
                    },
                    onStyleLoadedCallback: _onStyleLoaded,
                    onCameraMove: (camera) {
                      _lastCamera = camera;
                      _viewportRequest++;
                    },
                    onCameraIdle: _scheduleViewport,
                    onMapClick: _onMapTap,
                  ),
                ),
                if (!widget.isStories && !_styleReady && !_failed)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 16,
                    left: 80,
                    child: const Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
                if (_failed)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 80,
                    left: 16,
                    right: 16,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(context.lang.memoriesMapLoadError),
                            TextButton(
                              onPressed: _retry,
                              child: Text(
                                context.lang.manualVerificationRetry,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                MemoriesMapGallery(
                  stories: widget.isStories,
                  controller: _sheetController,
                  items: _visibleItems,
                  isLoading: _loadingViewport && !_failed,
                  onTap: (index) => _openViewer(List.of(_visibleItems), index),
                ),
              ],
            );
          },
        );
}
