import 'package:html/dom.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/base.dart';

class MastodonParser with BaseMetaInfo {
  MastodonParser(this._document);
  final Document? _document;

  @override
  Vendor? get vendor => ((_document?.head?.innerHtml
                  .contains('"repository":"mastodon/mastodon"') ??
              false) &&
          (_document?.head?.innerHtml.contains('SocialMediaPosting') ?? false))
      ? Vendor.mastodonSocialMediaPosting
      : null;
}
