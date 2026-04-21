enum Vendor { mastodonSocialMediaPosting, youtubeVideo, twitterPosting }

mixin BaseMetaInfo {
  late String url;
  String? title;
  String? desc;
  String? image;
  String? siteName;

  Vendor? vendor;

  DateTime? publishDate;
  int? likeAction; // https://schema.org/LikeAction
  int? shareAction; // https://schema.org/ShareAction

  /// Returns `true` if any parameter other than [url] is filled.
  bool get hasData =>
      ((title?.isNotEmpty ?? false) && title != 'null') ||
      ((desc?.isNotEmpty ?? false) && desc != 'null') ||
      ((image?.isNotEmpty ?? false) && image != 'null');
}

/// Container class for Metadata.
class Metadata with BaseMetaInfo {
  Metadata();
  bool get hasAllMetadata {
    return title != null && desc != null && image != null;
  }
}
