import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/base.dart';

class YouTubePostCard extends StatelessWidget {
  const YouTubePostCard({required this.info, super.key});
  final Metadata info;

  @override
  Widget build(BuildContext context) {
    const ytBlack = Color(0xFF0F0F0F);
    const ytWhite = Colors.white;
    const ytRed = Color.fromARGB(255, 255, 1, 51);

    return FractionallySizedBox(
      widthFactor: 0.8,
      child: Container(
        decoration: BoxDecoration(
          color: ytBlack,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: info.image ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.white10),
                      errorWidget: (context, url, error) => const ColoredBox(
                        color: Colors.white10,
                        child: Icon(
                          Icons.play_circle_outline,
                          color: ytWhite,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.youtube,
                    color: ytRed,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          substringBy(info.title ?? 'Video Title', 600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ytWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
