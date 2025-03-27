import 'package:flutter/material.dart';
import 'package:twonly/src/components/image_editor/data/layer.dart';
import 'package:twonly/src/components/image_editor/layers/filters/datetime_filter.dart';
import 'package:twonly/src/components/image_editor/layers/filters/image_filter.dart';
import 'package:twonly/src/components/image_editor/layers/filters/location_filter.dart';

/// Main layer
class FilterLayer extends StatefulWidget {
  final FilterLayerData layerData;
  // final VoidCallback? onUpdate;

  const FilterLayer({
    super.key,
    required this.layerData,
    // this.onUpdate,
  });

  @override
  State<FilterLayer> createState() => _FilterLayerState();
}

class FilterSceleton extends StatelessWidget {
  const FilterSceleton({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
  const FilterText(this.text,
      {super.key, this.fontSize = 24, this.color = Colors.white});
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
        shadows: [
          Shadow(
            color: const Color.fromARGB(122, 0, 0, 0),
            blurRadius: 5.0,
          )
        ],
      ),
    );
  }
}

class _FilterLayerState extends State<FilterLayer> {
  final PageController pageController = PageController();
  final List<Widget> pages = [
    FilterSceleton(),
    DateTimeFilter(),
    LocationFilter(),
    ImageFilter(imagePath: "random/lol.png"),
    ImageFilter(imagePath: "random/hide_the_pain.png"),
    ImageFilter(imagePath: "random/yolo.png"),
    ImageFilter(imagePath: "random/chillen.png"),
    ImageFilter(imagePath: "random/avocardio.png"),
    ImageFilter(imagePath: "random/duck.png"),
    FilterSceleton(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pageController.jumpToPage(1);
    });
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
