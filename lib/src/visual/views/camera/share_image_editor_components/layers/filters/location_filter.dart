import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/src/services/location_metadata.service.dart';
import 'package:twonly/src/visual/components/location_sticker.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/filter.layer.dart';

class LocationFilter extends StatefulWidget {
  const LocationFilter({super.key});

  @override
  State<LocationFilter> createState() => _LocationFilterState();
}

class _LocationFilterState extends State<LocationFilter>
    with WidgetsBindingObserver {
  String? _place;
  String? _locale;
  Timer? _retry;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_locale != locale) {
      _locale = locale;
      _place = null;
      unawaited(_loadPlace());
    }
  }

  Future<void> _loadPlace() async {
    _retry?.cancel();
    final request = ++_request;
    final place = await LocationMetadataService.currentCity(
      languageTag: _locale,
      onLocationAvailable: (coordinates) {
        if (mounted && request == _request) {
          setState(() => _place = coordinates);
        }
      },
    );
    if (!mounted || request != _request) return;
    setState(() => _place = place);
    if (place == null &&
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _retry = Timer(const Duration(seconds: 5), () => unawaited(_loadPlace()));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadPlace());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _retry?.cancel();
      _request++;
    }
  }

  @override
  void dispose() {
    _request++;
    _retry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FilterSkeleton(
    child: Positioned(
      bottom: 80,
      left: 40,
      right: 40,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: LocationSticker(city: _place),
        ),
      ),
    ),
  );
}
