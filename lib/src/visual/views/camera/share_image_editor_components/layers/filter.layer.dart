import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/filters/datetime_filter.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/filters/flashback_filter.dart';
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
  late final PageController pageController = PageController(
    initialPage: widget.layerData.page,
  );
  late final List<Widget> pages = [
    const FilterSkeleton(),
    if (widget.layerData.flashbackLabel case final label?)
      FlashbackFilter(label: label),
    const DateTimeFilter(),
    if (userService.currentUser.locationFilter)
      LocationFilter(layerData: widget.layerData),
    const FilterSkeleton(),
  ];

  @override
  void initState() {
    super.initState();
    if (userService.currentUser.locationFilter) _requestLocation();
    _syncLocationSelection();
    unawaited(initAsync());
  }

  void _requestLocation() {
    final data = widget.layerData;
    data.locationRequest ??= () async {
      try {
        return data.location = await RustApi.filterLocation();
      } on Object catch (error) {
        Log.warn('Location filter has no location: $error');
        return null;
      }
    }();
  }

  /// Only the location filter's page sends coordinates.
  void _syncLocationSelection() {
    final index = widget.layerData.page - 1;
    widget.layerData.locationSelected =
        index >= 0 && index < pages.length && pages[index] is LocationFilter;
  }

  // Keep the selected filter when the image filters arrive.
  void _updatePages(VoidCallback update) {
    final index = (widget.layerData.page - 1).clamp(0, pages.length - 1);
    final selected = pages[index];
    final oldPage = widget.layerData.page;
    setState(update);
    final selectedIndex = pages.indexOf(selected);
    final nextPage = selectedIndex < 0 ? 1 : selectedIndex + 1;
    widget.layerData.page = nextPage;
    _syncLocationSelection();
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
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: PageView.builder(
            controller: pageController,
            itemCount: pages.length + 2, // Add two for the duplicated pages
            itemBuilder: (context, index) {
              if (index == 0) {
                return pages.last; // Show the last page
              } else if (index == pages.length + 1) {
                return pages.first; // Show the first page
              } else {
                final page = pages[index - 1];
                // The editable map sits above the carousel so dragging or pinching
                // it cannot be claimed by the carousel's swipe gesture.
                return page is LocationFilter ? const FilterSkeleton() : page;
              }
            },
            onPageChanged: (index) {
              setState(() {
                widget.layerData.page = index;
                _syncLocationSelection();
              });
              if (index == 0) {
                // If the user swipes to the first duplicated page, jump to the last page
                pageController.jumpToPage(pages.length);
              } else if (index == pages.length + 1) {
                // If the user swipes to the last duplicated page, jump to the first page
                pageController.jumpToPage(1);
              }
            },
          ),
        ),
        if (widget.layerData.locationSelected)
          Positioned.fill(child: LocationFilter(layerData: widget.layerData)),
      ],
    );
  }
}
