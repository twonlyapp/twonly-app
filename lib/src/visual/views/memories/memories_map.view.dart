import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/helpers/map_style.helper.dart';
import 'package:twonly/src/visual/helpers/memory_map.helper.dart';
import 'package:twonly/src/visual/views/memories/components/memories_map_gallery.comp.dart';
import 'package:twonly/src/visual/views/memories/synchronized_viewer.view.dart';

class MemoriesMapView extends StatefulWidget {
  const MemoriesMapView({
    this.favoritesOnly = false,
    this.initialMedia,
    super.key,
  });

  final bool favoritesOnly;
  final MediaFile? initialMedia;

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

  final _sheetController = DraggableScrollableController();
  final _activeMediaId = ValueNotifier<String?>(null);
  StreamSubscription<List<MediaFile>>? _subscription;
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
  bool _styleReady = false;
  bool _layersReady = false;
  bool _failed = false;
  bool _loadingViewport = true;
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
    _subscribe();
  }

  void _subscribe() {
    unawaited(_subscription?.cancel());
    _subscription = twonlyDB.mediaFilesDao
        .watchGeotaggedMemories(favoritesOnly: widget.favoritesOnly)
        .listen(
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
    if (!mounted) return;
    final valid = files.where((file) => _point(file).isValid).toList();
    setState(() {
      _loadingMemories = false;
      _items = valid
          .map(
            (file) => MemoryItem(
              mediaService: MediaFileService(file),
              messages: [],
            ),
          )
          .toList();
      _points = valid.map(_point).toList();
      if (_points.isEmpty) {
        _epoch++;
        _map = null;
        _initialCamera = null;
        _lastCamera = null;
        _layersReady = false;
        _styleReady = false;
        _appliedPadding = null;
        _loadingViewport = true;
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
        await map.setGeoJsonSource(_clusterSource, data);
      });
      _scheduleViewport();
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
    _styleReady = true;
    _layersReady = false;
    final epoch = _epoch;
    final data = memoryMapGeoJson(_points);
    _enqueue((map) async {
      final layerIds = await map.getLayerIds();
      final sourceIds = await map.getSourceIds();
      final steps = <Future<void> Function()>[
        for (final layer in [_counts, _markers, _clusters, _heatmap])
          if (layerIds.contains(layer)) () => map.removeLayer(layer),
        for (final source in [_clusterSource, _rawSource])
          if (sourceIds.contains(source)) () => map.removeSource(source),
        () => map.addSource(_rawSource, GeojsonSourceProperties(data: data)),
        () => map.addSource(
          _clusterSource,
          GeojsonSourceProperties(
            data: data,
            cluster: true,
            clusterMaxZoom: 16,
          ),
        ),
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
      await map.setGeoJsonSource(_clusterSource, latest);
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
    setState(() => _sheetSize = _sheetController.size);
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
    if (_mapSize.isEmpty || !_layersReady) return;
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
    if (!_current(epoch, map) || request != _viewportRequest) return;
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
        [_clusters, _markers],
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
        final zoom = await map.getClusterExpansionZoom(
          _clusterSource,
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
                elevation: 4,
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

  Widget _buildContent(BuildContext context) => _loadingMemories
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
                      : context.lang.memoriesMapNoLocations,
                  textAlign: TextAlign.center,
                ),
                if (_failed)
                  TextButton(
                    onPressed: _retry,
                    child: Text(context.lang.manualVerificationRetry),
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
                if (!_styleReady && !_failed)
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
