mixin BaseMetaInfo {
  String? title;
  String? desc;
  String? image;
  String? url;
  String? siteName;

  /// Returns `true` if any parameter other than [url] is filled.
  bool get hasData =>
      ((title?.isNotEmpty ?? false) && title != 'null') ||
      ((desc?.isNotEmpty ?? false) && desc != 'null') ||
      ((image?.isNotEmpty ?? false) && image != 'null');

  Metadata parse() {
    return Metadata()
      ..title = title
      ..desc = desc
      ..image = image
      ..url = url
      ..siteName = siteName;
  }
}

/// Container class for Metadata.
class Metadata with BaseMetaInfo {
  bool get hasAllMetadata {
    return title != null && desc != null && image != null && url != null;
  }
}
