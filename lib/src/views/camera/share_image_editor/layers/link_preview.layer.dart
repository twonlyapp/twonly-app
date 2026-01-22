import 'package:flutter/material.dart';
import 'package:twonly/src/views/camera/share_image_editor/layer_data.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/cards/custom.card.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/cards/mastodon.card.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/cards/twitter.card.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/cards/youtube.card.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parse_link.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/base.dart';
import 'package:twonly/src/views/components/loader.dart';

class LinkPreviewLayer extends StatefulWidget {
  const LinkPreviewLayer({
    required this.layerData,
    super.key,
    this.onUpdate,
  });
  final LinkPreviewLayerData layerData;
  final VoidCallback? onUpdate;

  @override
  State<LinkPreviewLayer> createState() => _LinkPreviewLayerState();
}

class _LinkPreviewLayerState extends State<LinkPreviewLayer> {
  Metadata? metadata;

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  Future<void> initAsync() async {
    if (widget.layerData.metadata == null) {
      widget.layerData.metadata =
          await getMetadata(widget.layerData.link.toString());
      if (widget.layerData.metadata == null) {
        widget.layerData.error = true;
      }
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.layerData.error) {
      return Container();
    }
    final meta = widget.layerData.metadata;
    late Widget child;
    if (meta == null) {
      child = const ThreeRotatingDots(size: 30);
    } else if (meta.title == null) {
      return Container();
    } else if (meta.vendor == Vendor.mastodonSocialMediaPosting) {
      child = MastodonPostCard(info: meta);
    } else if (meta.vendor == Vendor.twitterPosting) {
      child = TwitterPostCard(info: meta);
    } else if (meta.vendor == Vendor.youtubeVideo) {
      child = YouTubePostCard(info: meta);
    } else {
      child = CustomLinkCard(info: meta);
    }

    return Center(
      child: child,
    );
  }
}
