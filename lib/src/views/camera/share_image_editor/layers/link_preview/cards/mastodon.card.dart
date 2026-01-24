import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/base.dart';
import 'package:twonly/src/views/components/loader.dart';

class MastodonPostCard extends StatelessWidget {
  const MastodonPostCard({required this.info, super.key});
  final Metadata info;

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF282C37);
    const secondaryTextColor = Color(0xFF9BA3AF);
    const accentColor = Color(0xFF6364FF);

    return FractionallySizedBox(
      widthFactor: 0.8,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.mastodon,
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  substringBy(info.title ?? 'Mastodon User', 37),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (info.desc != null && info.desc != 'null')
              Text(
                substringBy(info.desc!, 1000),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            if (info.image != null && info.image != 'null')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: CachedNetworkImage(
                      imageUrl: info.image!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        height: 150,
                        color: Colors.black12,
                        child: const Center(
                          child: ThreeRotatingDots(size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAction(
                  Icons.repeat,
                  '${info.shareAction ?? 0}',
                  secondaryTextColor,
                ),
                const SizedBox(width: 20),
                _buildAction(
                  Icons.star_border,
                  '${info.likeAction ?? 0}',
                  secondaryTextColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(IconData icon, String count, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        if (count.isNotEmpty && count != '0') ...[
          const SizedBox(width: 5),
          Text(count, style: TextStyle(color: color, fontSize: 13)),
        ],
      ],
    );
  }
}
