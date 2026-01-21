import 'package:html/dom.dart';

import 'base.dart';
import 'util.dart';

/// Parses [Metadata] from `<meta attribute: 'name' property='*'>` tags.
class OtherParser with BaseMetaInfo {
  OtherParser(this._document);

  final Document? _document;

  @override
  String? get title =>
      getProperty(_document, attribute: 'name', property: 'title');

  @override
  String? get desc =>
      getProperty(_document, attribute: 'name', property: 'description');

  @override
  String? get image =>
      getProperty(_document, attribute: 'name', property: 'image');

  @override
  String? get siteName =>
      getProperty(_document, attribute: 'name', property: 'site_name');
}
