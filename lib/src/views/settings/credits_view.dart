import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlListTitle extends StatelessWidget {
  final String title;
  final String url;
  final String? subtitle;

  const UrlListTitle(
      {super.key, required this.title, required this.url, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: () {
        launchUrl(Uri.parse(url));
      },
      trailing: FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 15),
    );
  }
}

class CreditsView extends StatelessWidget {
  const CreditsView({super.key});

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
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
          ),
          UrlListTitle(
            title: "Free selfie fast Animation",
            subtitle: "Brandon Ambuila",
            url:
                "https://lottiefiles.com/free-animation/selfie-fast-JZx4Ftrg1E",
          ),
          UrlListTitle(
            title: "Free Security status - Safe Animation",
            subtitle: "Yogesh Pal",
            url:
                "https://lottiefiles.com/free-animation/security-status-safe-CePJPAwLVx",
          ),
          UrlListTitle(
            title: "Free send mail Animation",
            subtitle: "jignesh gajjar",
            url: "https://lottiefiles.com/free-animation/send-mail-3pvzm2kmNq",
          ),
          UrlListTitle(
            title: "Free Present for you Animation",
            subtitle: "Tatsiana Melnikova",
            url:
                "https://lottiefiles.com/free-animation/present-for-you-QalWyuNptY",
          ),
          UrlListTitle(
            title: "Free Take a photo Animation",
            subtitle: "Nguyễn Như Lân",
            url:
                "https://lottiefiles.com/free-animation/take-a-photo-CzOUerxwPP?color-palette=true",
          ),
          UrlListTitle(
            title: "Kostenlose Valentine's Day-Animation",
            subtitle: "Strezha",
            url:
                "https://lottiefiles.com/de/free-animation/valentines-day-1UiMkPHnPK?color-palette=true",
          ),
          const Divider(),
          ListTile(
            title: Center(
                child: Text(
              "Filters",
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
          ),
          UrlListTitle(
            title: "Germany",
            subtitle: "by GDJ",
            url:
                "https://pixabay.com/vectors/republic-germany-deutschland-map-1220652/",
          ),
          UrlListTitle(
            title: "Frankfurt am Main",
            subtitle: "by GDJ",
            url:
                "https://pixabay.com/vectors/frankfurt-germany-skyline-cityscape-3166262/",
          ),
          UrlListTitle(
            title: "Avo Cardio",
            subtitle: "by RalfDesign",
            url:
                "https://pixabay.com/illustrations/avocado-cartoon-funny-cardio-gym-4570642/",
          ),
          UrlListTitle(
            title: "Sloth",
            subtitle: "by RalfDesign",
            url:
                "https://pixabay.com/illustrations/sloth-swimming-summer-pool-cartoon-4575121/",
          ),
          UrlListTitle(
            title: "Sloth",
            subtitle: "by RalfDesign",
            url:
                "https://pixabay.com/illustrations/sloth-swimming-summer-pool-cartoon-4575121/",
          ),
          UrlListTitle(
            title: "Duck",
            subtitle: "by lachkegeetanjali",
            url:
                "https://pixabay.com/de/vectors/ente-gans-meme-lustig-k%C3%A4mpfen-8409656/",
          ),
          UrlListTitle(
            title: "Lol",
            subtitle: "TheDigitalArtist",
            url:
                "https://pixabay.com/de/illustrations/lachen-lustig-l%C3%A4cheln-spa%C3%9F-meme-7820654/",
          ),
          UrlListTitle(
            title: "Yolo",
            subtitle: "TheDigitalArtist",
            url:
                "https://pixabay.com/illustrations/yolo-meme-modern-live-once-phrase-7820660/",
          ),
          UrlListTitle(
            title: "Hide The Pain Arold",
            url: "https://hidethepainharold.com/",
          ),
        ],
      ),
    );
  }
}
