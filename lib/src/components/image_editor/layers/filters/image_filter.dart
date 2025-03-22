import 'package:flutter/material.dart';
import 'package:twonly/src/components/image_editor/layers/filter_layer.dart';

class ImageFilter extends StatelessWidget {
  const ImageFilter({super.key, required this.imagePath});
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return FilterSceleton(
      child: Positioned(
        bottom: 50,
        left: 10,
        right: 10,
        child: Center(
          child: Image.asset(
            "assets/filters/$imagePath",
            height: 150,
          ),
        ),
      ),
    );
  }
}
