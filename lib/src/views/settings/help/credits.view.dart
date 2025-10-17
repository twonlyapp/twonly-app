import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/image_editor/layers/filters/location_filter.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlListTitle extends StatelessWidget {
  const UrlListTitle({
    required this.title,
    required this.url,
    super.key,
    this.leading,
    this.subtitle,
  });
  final String? title;
  final String url;
  final String? subtitle;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: (title != null) ? Text(title!) : null,
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: () async {
        await launchUrl(Uri.parse(url));
      },
      trailing: const FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 15),
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
    unawaited(initAsync());
  }

  Future<void> initAsync() async {
    sticker = (await getStickerIndex()).where((x) => x.source != '').toList();
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
          const UrlListTitle(
            title: 'twonly Logo',
            subtitle: 'by Font Awesome (modified)',
            url: 'https://fontawesome.com/icons/link?f=classic&s=solid',
          ),
          const UrlListTitle(
            title: 'Most Icons',
            subtitle: 'by Font Awesome',
            url: 'https://github.com/FortAwesome/Font-Awesome',
          ),
          const UrlListTitle(
            title: 'Animated Emoji',
            subtitle: 'CC BY 4.0',
            url: 'https://googlefonts.github.io/noto-emoji-animation/',
          ),
          const UrlListTitle(
            title: 'Avatar Icons',
            url: 'https://github.com/RoadTripMoustache/avatar_maker',
          ),
          const Divider(),
          const ListTile(
            title: Center(
              child: Text(
                'Animations',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const UrlListTitle(
            title: 'selfie fast Animation',
            subtitle: 'Brandon Ambuila',
            url:
                'https://lottiefiles.com/free-animation/selfie-fast-JZx4Ftrg1E',
          ),
          const UrlListTitle(
            title: 'Security status - Safe Animation',
            subtitle: 'Yogesh Pal',
            url:
                'https://lottiefiles.com/free-animation/security-status-safe-CePJPAwLVx',
          ),
          const UrlListTitle(
            title: 'send mail Animation',
            subtitle: 'jignesh gajjar',
            url: 'https://lottiefiles.com/free-animation/send-mail-3pvzm2kmNq',
          ),
          const UrlListTitle(
            title: 'Present for you Animation',
            subtitle: 'Tatsiana Melnikova',
            url:
                'https://lottiefiles.com/free-animation/present-for-you-QalWyuNptY',
          ),
          const UrlListTitle(
            title: 'Take a photo Animation',
            subtitle: 'Nguyễn Như Lân',
            url:
                'https://lottiefiles.com/free-animation/take-a-photo-CzOUerxwPP?color-palette=true',
          ),
          const UrlListTitle(
            title: "Valentine's Day-Animation",
            subtitle: 'Strezha',
            url:
                'https://lottiefiles.com/de/free-animation/valentines-day-1UiMkPHnPK?color-palette=true',
          ),
          const UrlListTitle(
            title: 'success-Animation',
            subtitle: 'Aman Awasthy',
            url:
                'https://lottiefiles.com/de/free-animation/success-tick-cuwjLHAR7g',
          ),
          const UrlListTitle(
            title: 'Donation-Animation',
            subtitle: 'Abdul Latif',
            url:
                'https://lottiefiles.com/free-animation/international-day-of-charity-NBAKAkCcBr',
          ),
          const UrlListTitle(
            title: 'Failed-Animation',
            subtitle: 'Ahmed Shami أحمد شامي',
            url: 'https://lottiefiles.com/de/free-animation/failed-e5cQFDEtLv',
          ),
          const Divider(),
          if (sticker.isNotEmpty)
            const ListTile(
              title: Center(
                child: Text(
                  'Filters',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ...sticker.map(
            (x) => UrlListTitle(
              leading: SizedBox(
                height: 50,
                width: 50,
                child: CachedNetworkImage(
                  imageUrl: 'https://twonly.eu/${x.imageSrc}',
                ),
              ),
              title: '',
              url: x.source,
            ),
          ),
        ],
      ),
    );
  }
}
