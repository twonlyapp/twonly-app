import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/location_metadata.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/filters/datetime_filter.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/filters/image_filter.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/filters/location_filter.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/filters/stickers.dart';

/// Main layer
class FilterLayer extends StatefulWidget {
  // final VoidCallback? onUpdate;

  const FilterLayer({
    required this.layerData,
    super.key,
    // this.onUpdate,
  });
  final FilterLayerData layerData;

  @override
  State<FilterLayer> createState() => _FilterLayerState();
}

class FilterSkeleton extends StatelessWidget {
  const FilterSkeleton({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(child: Container()),
          ?child,
        ],
      ),
    );
  }
}

class FilterText extends StatelessWidget {
  const FilterText(
    this.text, {
    super.key,
    this.fontSize = 24,
    this.color,
  });
  final String text;
  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.start,
      style: TextStyle(
        fontSize: fontSize,
        color: color ?? context.appColor(AppColor.mediaForeground),
        shadows: [
          Shadow(
            color: context.appColor(AppColor.mediaScrim),
            blurRadius: 5,
          ),
        ],
      ),
    );
  }
}

class _FilterLayerState extends State<FilterLayer> {
  final PageController pageController = PageController(initialPage: 1);
  final List<Widget> pages = [
    const FilterSkeleton(),
    const DateTimeFilter(),
    const FilterSkeleton(),
  ];
  StreamSubscription<void>? _userUpdates;
  LocationFilter? _locationFilter;

  @override
  void initState() {
    super.initState();
    _userUpdates = userService.onUserUpdated.listen((_) {
      if (mounted) _refreshLocation();
    });
    _refreshLocation();
    unawaited(initAsync());
  }

  void _refreshLocation() {
    final enabled = LocationMetadataService.stickersEnabled;
    if (enabled == (_locationFilter != null)) return;
    _updatePages(() {
      pages.remove(_locationFilter);
      _locationFilter = enabled ? const LocationFilter() : null;
      if (_locationFilter != null) pages.insert(2, _locationFilter!);
    });
  }

  // Keep the selected filter when location is enabled or image filters arrive.
  // If the selected city is removed, return to the unfiltered photo.
  void _updatePages(VoidCallback update) {
    final index = (widget.layerData.page - 1).clamp(0, pages.length - 1);
    final selected = pages[index];
    final oldPage = widget.layerData.page;
    setState(update);
    final selectedIndex = pages.indexOf(selected);
    final nextPage = selectedIndex < 0 ? 1 : selectedIndex + 1;
    widget.layerData.page = nextPage;
    if (oldPage == nextPage) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          pageController.hasClients &&
          widget.layerData.page == nextPage) {
        pageController.jumpToPage(nextPage);
      }
    });
  }

  Future<void> initAsync() async {
    final stickers =
        (await getStickerIndex())
            .where((x) => x.imageSrc.contains('/imagefilter/'))
            .toList()
          ..sortBy((x) => x.imageSrc);

    if (!mounted) return;
    _updatePages(() {
      for (final sticker in stickers) {
        pages.insert(
          pages.length - 1,
          ImageFilter(imagePath: sticker.imageSrc),
        );
      }
    });
  }

  @override
  void dispose() {
    unawaited(_userUpdates?.cancel());
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      itemCount: pages.length + 2, // Add two for the duplicated pages
      itemBuilder: (context, index) {
        if (index == 0) {
          return pages.last; // Show the last page
        } else if (index == pages.length + 1) {
          return pages.first; // Show the first page
        } else {
          return pages[index - 1]; // Show the actual pages
        }
      },
      onPageChanged: (index) {
        widget.layerData.page = index;
        if (index == 0) {
          // If the user swipes to the first duplicated page, jump to the last page
          pageController.jumpToPage(pages.length);
        } else if (index == pages.length + 1) {
          // If the user swipes to the last duplicated page, jump to the first page
          pageController.jumpToPage(1);
        }
      },
    );
  }
}
