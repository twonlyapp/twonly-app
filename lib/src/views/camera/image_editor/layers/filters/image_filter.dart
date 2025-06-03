import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/views/camera/image_editor/layers/filter_layer.dart';

class ImageFilter extends StatelessWidget {
  const ImageFilter({super.key, required this.imagePath});
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return FilterSkeleton(
      child: Positioned(
        bottom: 50,
        left: 10,
        right: 10,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: "https://twonly.eu/$imagePath",
            height: 150,
          ),
        ),
      ),
    );
  }
}
