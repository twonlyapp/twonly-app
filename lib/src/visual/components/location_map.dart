import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/helpers/map_style.helper.dart';

/// Same MapLibre renderer and map styles as Memories, with one current point.
class LocationMap extends StatefulWidget {
  const LocationMap({
    required this.latitude,
    required this.longitude,
    this.interactive = false,
    super.key,
  });
  final double latitude;
  final double longitude;
  final bool interactive;
  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  static const _pointSource = 'current-location';
  static const _pointLayer = 'current-location-marker';

  MapLibreMapController? _map;
  Animation<double>? _routeAnimation;
  bool _closing = false;
  bool _markerReady = false;
  String? _style;
  bool _ready = false;
  bool _failed = false;
  int _generation = 0;
  Timer? _timeout;
  Future<void> _operations = Future.value();
  LatLng get _point => LatLng(widget.latitude, widget.longitude);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (!identical(animation, _routeAnimation)) {
      _routeAnimation?.removeStatusListener(_handleRouteAnimation);
      _routeAnimation = animation;
      animation?.addStatusListener(_handleRouteAnimation);
      _closing = animation?.status == AnimationStatus.reverse;
    }
    final style = mapStyleForBrightness(Theme.of(context).brightness);
    if (style != _style) {
      _style = style;
      _map = null;
      _markerReady = false;
      _ready = false;
      _failed = false;
      _generation++;
      _startTimeout();
    }
  }

  // Like WebxdcAppView, pause native rendering before the first closing
  // frame. The route animation covers app-bar back, system back and gestures.
  void _handleRouteAnimation(AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      setState(() => _closing = true);
      _timeout?.cancel();
      unawaited(_setMapPaused(true));
    } else if (status == AnimationStatus.forward ||
        (status == AnimationStatus.completed && _closing)) {
      setState(() => _closing = false);
      if (!_ready) _startTimeout();
      unawaited(_setMapPaused(false));
    }
  }

  Future<void> _setMapPaused(bool paused) async {
    final map = _map;
    final generation = _generation;
    if (map == null || map.isDisposed) return;
    try {
      if (paused) {
        await map.pauseMap();
      } else {
        await map.resumeMap();
        if (mounted && generation == _generation && !_closing && _ready) {
          _updatePoint();
        }
      }
    } catch (error) {
      if (mounted && generation == _generation && !map.isDisposed) {
        Log.error('Could not change location map rendering: $error');
      }
    }
  }

  void _startTimeout() {
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 20), () {
      if (mounted && !_ready) setState(() => _failed = true);
    });
  }

  @override
  void didUpdateWidget(covariant LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready &&
        (widget.latitude != oldWidget.latitude ||
            widget.longitude != oldWidget.longitude)) {
      _updatePoint();
    }
  }

  void _updatePoint() {
    final map = _map;
    final generation = _generation;
    if (map == null || _closing) return;
    _operations = _operations.then((_) async {
      if (!mounted || generation != _generation || map.isDisposed || _closing) {
        return;
      }
      try {
        final data = <String, dynamic>{
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'geometry': {
                'type': 'Point',
                'coordinates': [widget.longitude, widget.latitude],
              },
              'properties': <String, dynamic>{},
            },
          ],
        };
        if (!_markerReady) {
          await map.addGeoJsonSource(_pointSource, data);
          if (!mounted || generation != _generation || map.isDisposed) {
            return;
          }
          await map.addCircleLayer(
            _pointSource,
            _pointLayer,
            const CircleLayerProperties(
              circleRadius: 9,
              circleColor: '#337eae',
              circleStrokeColor: '#ffffff',
              circleStrokeWidth: 3,
            ),
            enableInteraction: false,
          );
          if (!mounted || generation != _generation || map.isDisposed) {
            return;
          }
          _markerReady = true;
        } else {
          await map.setGeoJsonSource(_pointSource, data);
        }
        if (!mounted ||
            generation != _generation ||
            map.isDisposed ||
            _closing) {
          return;
        }
        await map.moveCamera(CameraUpdate.newLatLng(_point));
      } on Object {
        if (mounted && generation == _generation) {
          setState(() => _failed = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_handleRouteAnimation);
    _generation++;
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generation = _generation;
    // Pausing only freezes the native surface. Remove inline previews from
    // painting during the chat's closing animation so that frame cannot linger
    // above the surrounding Flutter content. Keep their state for canceled pops.
    return Offstage(
      offstage: !widget.interactive && _closing,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MapLibreMap(
            key: ValueKey(_generation),
            styleString: _style!,
            initialCameraPosition: CameraPosition(target: _point, zoom: 14),
            // Initialize our marker inside _updatePoint's guarded operations.
            // Plugin annotation managers initialize before this widget's style
            // callback and can throw uncaught styleNotFound during teardown.
            annotationOrder: const [],
            scrollGesturesEnabled: widget.interactive,
            zoomGesturesEnabled: widget.interactive,
            rotateGesturesEnabled: widget.interactive,
            tiltGesturesEnabled: false,
            onMapCreated: (map) {
              if (mounted && generation == _generation) {
                _map = map;
                if (_closing) unawaited(_setMapPaused(true));
              }
            },
            onStyleLoadedCallback: () {
              if (!mounted || generation != _generation) return;
              _timeout?.cancel();
              setState(() {
                _ready = true;
                _failed = false;
              });
              _updatePoint();
            },
          ),
          if (!_ready && !_failed)
            const Center(child: CircularProgressIndicator()),
          if (_failed)
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.lang.memoriesMapLoadError,
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _generation++;
                          _map = null;
                          _markerReady = false;
                          _ready = false;
                          _failed = false;
                          _startTimeout();
                        }),
                        child: Text(context.lang.manualVerificationRetry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
