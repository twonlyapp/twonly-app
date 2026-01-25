import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
// Assuming the same Metadata import structure
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/base.dart';

class TwitterPostCard extends StatelessWidget {
  const TwitterPostCard({required this.info, super.key});
  final Metadata info;

  @override
  Widget build(BuildContext context) {
    // Classic Twitter Brand Colors
    const twitterBlue = Color(0xFF1DA1F2);
    const backgroundWhite = Colors.white;
    const primaryText = Color(0xFF14171A);
    const borderColor = Color(0xFFE1E8ED);

    return FractionallySizedBox(
      widthFactor: 0.9, // Twitter cards often feel a bit wider
      child: Container(
        decoration: BoxDecoration(
          color: backgroundWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.twitter,
                  color: twitterBlue,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    substringBy(info.title ?? 'Twitter User', 37),
                    style: const TextStyle(
                      color: primaryText,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (info.desc != null && info.desc != 'null')
              Text(
                substringBy(info.desc!, info.image == null ? 500 : 300),
                style: const TextStyle(
                  color: primaryText,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            if (info.image != null && info.image != 'null')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: CachedNetworkImage(
                        imageUrl: info.image!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          height: 150,
                          color: const Color(0xFFF5F8FA),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(twitterBlue),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
