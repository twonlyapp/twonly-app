import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/loader/three_rotating_dots.loader.dart';

/// A city or country name rendered into the shared media, or dots while loading.
class LocationSticker extends StatelessWidget {
  const LocationSticker({required this.city, super.key});

  final String? city;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.location_on, color: Colors.black, size: 24),
        const SizedBox(width: 6),
        if (city == null)
          Semantics(
            label: context.lang.locationStickerLoading,
            child: const ThreeRotatingDots(size: 22, color: Colors.black),
          )
        else
          Text(
            city!,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
          ),
      ],
    ),
  );
}
