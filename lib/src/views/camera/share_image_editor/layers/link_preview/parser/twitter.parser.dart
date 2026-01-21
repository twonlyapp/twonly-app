import 'package:html/dom.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/base.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/util.dart';

/// Parses [Metadata] from `<meta property='twitter:*'>` tags.
class TwitterParser with BaseMetaInfo {
  TwitterParser(this._document, this._url);
  final Document? _document;
  final String _url;

  @override
  String? get title =>
      getProperty(_document, attribute: 'name', property: 'twitter:title') ??
      getProperty(_document, property: 'twitter:title');

  @override
  String? get desc =>
      getProperty(
        _document,
        attribute: 'name',
        property: 'twitter:description',
      ) ??
      getProperty(_document, property: 'twitter:description');

  @override
  String? get image =>
      getProperty(_document, attribute: 'name', property: 'twitter:image') ??
      getProperty(_document, property: 'twitter:image');

  @override
  Vendor? get vendor =>
      _url.startsWith('https://x.com/') && _url.contains('/status/')
          ? Vendor.twitterPosting
          : null;
}
