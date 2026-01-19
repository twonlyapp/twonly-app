import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/views/camera/share_image_editor/layer_data.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/filters/datetime_filter.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/filters/image_filter.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/filters/location_filter.dart';

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
          if (child != null) child!,
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
    this.color = Colors.white,
  });
  final String text;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.start,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        shadows: const [
          Shadow(
            color: Color.fromARGB(122, 0, 0, 0),
            blurRadius: 5,
          ),
        ],
      ),
    );
  }
}

class _FilterLayerState extends State<FilterLayer> {
  final PageController pageController = PageController();
  List<Widget> pages = [
    const FilterSkeleton(),
    const DateTimeFilter(),
    // const LocationFilter(),
    const FilterSkeleton(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pageController.jumpToPage(1);
    });
    unawaited(initAsync());
  }

  Future<void> initAsync() async {
    final stickers = (await getStickerIndex())
        .where((x) => x.imageSrc.contains('/imagefilter/'))
        .toList()
      ..sortBy((x) => x.imageSrc);

    for (final sticker in stickers) {
      pages.insert(pages.length - 1, ImageFilter(imagePath: sticker.imageSrc));
    }
    if (!mounted) return;
    setState(() {});
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
