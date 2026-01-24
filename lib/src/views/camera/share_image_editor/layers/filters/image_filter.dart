import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/filter.layer.dart';

class ImageFilter extends StatelessWidget {
  const ImageFilter({required this.imagePath, super.key});
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
            imageUrl: 'https://twonly.eu/$imagePath',
            height: 150,
          ),
        ),
      ),
    );
  }
}
