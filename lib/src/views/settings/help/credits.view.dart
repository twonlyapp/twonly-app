import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/image_editor/layers/filters/location_filter.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlListTitle extends StatelessWidget {
  final String? title;
  final String url;
  final String? subtitle;
  final Widget? leading;

  const UrlListTitle({
    super.key,
    required this.title,
    required this.url,
    this.leading,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: (title != null) ? Text(title!) : null,
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: () {
        launchUrl(Uri.parse(url));
      },
      trailing: FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 15),
    );
  }
}

class CreditsView extends StatefulWidget {
  const CreditsView({super.key});

  @override
  State<CreditsView> createState() => _CreditsViewState();
}

class _CreditsViewState extends State<CreditsView> {
  List<Sticker> sticker = [];

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    sticker = (await getStickerIndex()).where((x) => x.source != "").toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsHelpCredits),
      ),
      body: ListView(
        children: [
          UrlListTitle(
            title: "twonly Logo",
            subtitle: "by Font Awesome (modified)",
            url: "https://fontawesome.com/icons/link?f=classic&s=solid",
          ),
          UrlListTitle(
            title: "Most Icons",
            subtitle: "by Font Awesome",
            url: "https://github.com/FortAwesome/Font-Awesome",
          ),
          UrlListTitle(
            title: "Animated Emoji",
            subtitle: "CC BY 4.0",
            url: "https://googlefonts.github.io/noto-emoji-animation/",
          ),
          UrlListTitle(
            title: "Avatar Icons",
            url: "https://github.com/RoadTripMoustache/avatar_maker",
          ),
          const Divider(),
          ListTile(
            title: Center(
                child: Text(
              "Animations",
              style: const TextStyle(fontWeight: FontWeight.bold),
            )),
          ),
          UrlListTitle(
            title: "selfie fast Animation",
            subtitle: "Brandon Ambuila",
            url:
                "https://lottiefiles.com/free-animation/selfie-fast-JZx4Ftrg1E",
          ),
          UrlListTitle(
            title: "Security status - Safe Animation",
            subtitle: "Yogesh Pal",
            url:
                "https://lottiefiles.com/free-animation/security-status-safe-CePJPAwLVx",
          ),
          UrlListTitle(
            title: "send mail Animation",
            subtitle: "jignesh gajjar",
            url: "https://lottiefiles.com/free-animation/send-mail-3pvzm2kmNq",
          ),
          UrlListTitle(
            title: "Present for you Animation",
            subtitle: "Tatsiana Melnikova",
            url:
                "https://lottiefiles.com/free-animation/present-for-you-QalWyuNptY",
          ),
          UrlListTitle(
            title: "Take a photo Animation",
            subtitle: "Nguyễn Như Lân",
            url:
                "https://lottiefiles.com/free-animation/take-a-photo-CzOUerxwPP?color-palette=true",
          ),
          UrlListTitle(
            title: "Valentine's Day-Animation",
            subtitle: "Strezha",
            url:
                "https://lottiefiles.com/de/free-animation/valentines-day-1UiMkPHnPK?color-palette=true",
          ),
          UrlListTitle(
            title: "success-Animation",
            subtitle: "Aman Awasthy",
            url:
                "https://lottiefiles.com/de/free-animation/success-tick-cuwjLHAR7g",
          ),
          UrlListTitle(
            title: "Failed-Animation",
            subtitle: "Ahmed Shami أحمد شامي",
            url: "https://lottiefiles.com/de/free-animation/failed-e5cQFDEtLv",
          ),
          const Divider(),
          if (sticker.isNotEmpty)
            ListTile(
              title: Center(
                  child: Text(
                "Filters",
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
            ),
          ...sticker.map(
            (x) => UrlListTitle(
              leading: SizedBox(
                height: 50,
                width: 50,
                child: CachedNetworkImage(
                    imageUrl: "https://twonly.eu/${x.imageSrc}"),
              ),
              title: "",
              url: x.source,
            ),
          ),
        ],
      ),
    );
  }
}
